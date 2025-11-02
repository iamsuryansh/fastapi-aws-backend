import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["message"] == "Welcome to FastAPI Backend"

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["message"] == "Service is running"

def test_get_items_empty():
    response = client.get("/items")
    assert response.status_code == 200
    assert response.json() == []

def test_create_item():
    item_data = {
        "name": "Test Item",
        "description": "A test item",
        "price": 29.99
    }
    response = client.post("/items", json=item_data)
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == item_data["name"]
    assert data["price"] == item_data["price"]
    assert "id" in data
    assert "created_at" in data

def test_get_item_by_id():
    # First create an item
    item_data = {
        "name": "Test Item 2",
        "description": "Another test item",
        "price": 39.99
    }
    create_response = client.post("/items", json=item_data)
    created_item = create_response.json()
    
    # Then get it by ID
    response = client.get(f"/items/{created_item['id']}")
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == item_data["name"]

def test_get_nonexistent_item():
    response = client.get("/items/999")
    assert response.status_code == 404

def test_update_item():
    # First create an item
    item_data = {
        "name": "Test Item 3",
        "description": "Yet another test item",
        "price": 49.99
    }
    create_response = client.post("/items", json=item_data)
    created_item = create_response.json()
    
    # Then update it
    update_data = {
        "name": "Updated Item",
        "description": "Updated description",
        "price": 59.99
    }
    response = client.put(f"/items/{created_item['id']}", json=update_data)
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == update_data["name"]
    assert data["price"] == update_data["price"]

def test_delete_item():
    # First create an item
    item_data = {
        "name": "Test Item 4",
        "description": "Item to be deleted",
        "price": 19.99
    }
    create_response = client.post("/items", json=item_data)
    created_item = create_response.json()
    
    # Then delete it
    response = client.delete(f"/items/{created_item['id']}")
    assert response.status_code == 200
    
    # Verify it's deleted
    get_response = client.get(f"/items/{created_item['id']}")
    assert get_response.status_code == 404