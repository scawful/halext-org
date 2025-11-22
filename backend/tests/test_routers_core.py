
import pytest

API_PREFIX = "/api"


def api(path: str) -> str:
    return f"{API_PREFIX}{path}"


def test_read_main(client):
    response = client.get(api("/health"))
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "version" in data

# --- Users & Auth Tests ---

def test_create_user(client):
    response = client.post(
        api("/users/"),
        json={
            "username": "newuser",
            "email": "new@example.com",
            "password": "newpassword",
            "full_name": "New User"
        },
        headers={"X-Halext-Code": "ignore-in-dev"}  # Mock header
    )
    assert response.status_code == 200
    data = response.json()
    assert data["username"] == "newuser"
    assert "id" in data

def test_login_user(client, test_user):
    response = client.post(
        api("/token"),
        data={"username": test_user.username, "password": "testpassword"}
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"

def test_read_users_me(client, auth_headers):
    response = client.get(api("/users/me/"), headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["username"] == "testuser"

# --- Tasks Tests ---

def test_create_task(client, auth_headers):
    response = client.post(
        api("/tasks/"),
        json={"title": "Test Task", "description": "Do something"},
        headers=auth_headers
    )
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "Test Task"
    assert data["description"] == "Do something"
    assert data["completed"] is False

def test_read_tasks(client, auth_headers):
    # Create a task first
    client.post(
        api("/tasks/"),
        json={"title": "Task 1"},
        headers=auth_headers
    )

    response = client.get(api("/tasks/"), headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1
    assert data[0]["title"] == "Task 1"

def test_update_task(client, auth_headers):
    # Create
    create_res = client.post(
        api("/tasks/"),
        json={"title": "Update Me"},
        headers=auth_headers
    )
    task_id = create_res.json()["id"]

    # Update
    response = client.put(
        api(f"/tasks/{task_id}"),
        json={"title": "Updated", "completed": True},
        headers=auth_headers
    )
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "Updated"
    assert data["completed"] is True

def test_delete_task(client, auth_headers):
    # Create
    create_res = client.post(
        api("/tasks/"),
        json={"title": "Delete Me"},
        headers=auth_headers
    )
    task_id = create_res.json()["id"]

    # Delete
    response = client.delete(api(f"/tasks/{task_id}"), headers=auth_headers)
    assert response.status_code == 204

    # Verify gone
    get_res = client.get(api("/tasks/"), headers=auth_headers)
    tasks = get_res.json()
    assert not any(t["id"] == task_id for t in tasks)

# --- Events Tests ---

def test_create_event(client, auth_headers):
    response = client.post(
        api("/events/"),
        json={
            "title": "Meeting",
            "start_time": "2025-10-27T10:00:00",
            "end_time": "2025-10-27T11:00:00",
            "location": "Office"
        },
        headers=auth_headers
    )
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "Meeting"
    assert "id" in data

def test_read_events(client, auth_headers):
    client.post(
        api("/events/"),
        json={
            "title": "Party",
            "start_time": "2025-10-31T20:00:00",
            "end_time": "2025-10-31T23:00:00"
        },
        headers=auth_headers
    )
    response = client.get(api("/events/"), headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 1
    assert data[0]["title"] == "Party"

# --- Pages/Layout Tests ---

def test_create_page(client, auth_headers):
    response = client.post(
        api("/pages/"),
        json={"title": "Dashboard", "visibility": "private"},
        headers=auth_headers
    )
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "Dashboard"
    assert data["layout"] == [] # Default empty layout or list

def test_read_pages(client, auth_headers):
    client.post(
        api("/pages/"),
        json={"title": "My Page"},
        headers=auth_headers
    )
    response = client.get(api("/pages/"), headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 1
    assert data[0]["title"] == "My Page"
