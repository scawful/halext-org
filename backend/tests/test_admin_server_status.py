"""Tests for the /admin/server/status endpoint"""


class TestAdminServerStatus:
    def test_requires_authentication(self, client):
        response = client.get("/admin/server/status")
        assert response.status_code == 401

    def test_requires_admin(self, client, auth_headers):
        response = client.get("/admin/server/status", headers=auth_headers)
        assert response.status_code == 403

    def test_returns_status_payload(self, client, admin_auth_headers):
        response = client.get("/admin/server/status", headers=admin_auth_headers)
        assert response.status_code == 200
        data = response.json()

        assert "hostname" in data
        assert "uptime_seconds" in data
        assert "uptime_human" in data
        assert "load_avg" in data
        assert "memory" in data
        assert "disk" in data
        assert "services" in data
        assert "git" in data

        assert isinstance(data["services"], list)
        if data["services"]:
            service = data["services"][0]
            assert "name" in service
            assert "status" in service
            assert "last_checked" in service
