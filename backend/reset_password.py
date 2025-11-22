#!/usr/bin/env python3
"""
Reset user password for Halext Org backend.
Usage: python reset_password.py <username> <new_password>
"""

import sys
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

from app.database import SessionLocal
from app import crud
from app.auth import get_password_hash

def reset_password(username: str, new_password: str):
    """Reset a user's password"""
    db = SessionLocal()
    try:
        # Get user by username
        user = crud.get_user_by_username(db, username=username)
        
        if not user:
            print(f"❌ User '{username}' not found!")
            print("\nAvailable users:")
            users = crud.get_users(db, limit=100)
            for u in users:
                admin_badge = " (admin)" if u.is_admin else ""
                print(f"  - {u.username} ({u.email}){admin_badge}")
            return False
        
        # Hash the new password
        hashed_password = get_password_hash(new_password)
        
        # Update user's password
        user.hashed_password = hashed_password
        db.commit()
        
        admin_badge = " (admin)" if user.is_admin else ""
        print(f"✅ Password reset successfully for user: {user.username}{admin_badge}")
        print(f"   Email: {user.email}")
        print(f"\n🔐 You can now login with:")
        print(f"   Username: {username}")
        print(f"   Password: {new_password}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error resetting password: {e}")
        db.rollback()
        return False
    finally:
        db.close()

def list_users():
    """List all users in the database"""
    db = SessionLocal()
    try:
        users = crud.get_users(db, limit=100)
        print(f"\n📋 Total users: {len(users)}\n")
        for user in users:
            admin_badge = " 👑 ADMIN" if user.is_admin else ""
            print(f"  {user.id}. {user.username} ({user.email}){admin_badge}")
    finally:
        db.close()

if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "--list":
        list_users()
    elif len(sys.argv) != 3:
        print("Usage:")
        print("  List users:     python reset_password.py --list")
        print("  Reset password: python reset_password.py <username> <new_password>")
        print("\nExample:")
        print("  python reset_password.py dev NewPassword123!")
        sys.exit(1)
    else:
        username = sys.argv[1]
        new_password = sys.argv[2]
        
        if len(new_password) < 8:
            print("❌ Password must be at least 8 characters long!")
            sys.exit(1)
        
        success = reset_password(username, new_password)
        sys.exit(0 if success else 1)

