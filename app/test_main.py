# app/test_main.py
from main import app

def get_client():
    app.config['TESTING'] = True
    return app.test_client()

def test_home_endpoint():
    """Ana sayfa (/) 200 donmeli ve version icermeli"""
    client = get_client()
    response = client.get('/')
    assert response.status_code == 200
    data = response.get_json()
    assert data['version'] == '1.0'

def test_health_endpoint():
    """Saglik kontrolu (/health) 200 donmeli ve status ok olmali"""
    client = get_client()
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'ok'