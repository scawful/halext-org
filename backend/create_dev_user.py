#!/usr/bin/env python3
"""
Create a development user account

Usage:
    python create_dev_user.py
    python create_dev_user.py --username alice --password mypass --email alice@example.com
"""

import argparse
import sys
from app.database import SessionLocal
from app import crud, schemas
from passlib.context import CryptContext

def create_user(username: str, password: str, email: str, full_name: str = None):
    """Create a new user account"""
    db = SessionLocal()
    try:
        # Check if user already exists
        existing_user = crud.get_user_by_username(db, username=username)
        if existing_user:
            print(f"❌ User '{username}' already exists")
            return False

        existing_email = crud.get_user_by_email(db, email=email)
        if existing_email:
            print(f"❌ Email '{email}' already registered")
            return False

        # Create user
        user_data = schemas.UserCreate(
            username=username,
            password=password,
            email=email,
            full_name=full_name
        )
        user = crud.create_user(db=db, user=user_data)

        print(f"✅ User created successfully!")
        print(f"   ID: {user.id}")
        print(f"   Username: {user.username}")
        print(f"   Email: {user.email}")
        print(f"   Full Name: {user.full_name or '(not set)'}")
        print(f"\n🔑 Login credentials:")
        print(f"   Username: {username}")
        print(f"   Password: {password}")
        return True

    except Exception as e:
        print(f"❌ Error creating user: {e}")
        return False
    finally:
        db.close()

def main():
    parser = argparse.ArgumentParser(description='Create a development user account')
    parser.add_argument('--username', default='dev', help='Username (default: dev)')
    parser.add_argument('--password', default='dev123', help='Password (default: dev123)')
    parser.add_argument('--email', default='dev@halext.org', help='Email (default: dev@halext.org)')
    parser.add_argument('--full-name', help='Full name (optional)')

    args = parser.parse_args()

    print("🚀 Creating development user...\n")
    success = create_user(
        username=args.username,
        password=args.password,
        email=args.email,
        full_name=args.full_name
    )

    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
