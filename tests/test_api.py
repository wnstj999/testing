import json
import pathlib
import sys

import os
import tempfile
import threading
import urllib.request

sys.path.append(str(pathlib.Path(__file__).resolve().parents[1]))
from server import run_server


def start_server():
    fd, db_path = tempfile.mkstemp()
    os.close(fd)
    os.environ['DB_PATH'] = db_path
    httpd = run_server(port=0)
    port = httpd.server_address[1]
    thread = threading.Thread(target=httpd.serve_forever)
    thread.daemon = True
    thread.start()
    return httpd, port, db_path


def stop_server(httpd, db_path):
    httpd.shutdown()
    httpd.server_close()
    os.remove(db_path)


def request(method, url, data=None):
    req = urllib.request.Request(url, data=data, method=method)
    if data is not None:
        req.add_header('Content-Type', 'application/json')
    with urllib.request.urlopen(req) as resp:
        return resp.status, resp.read()


def test_inventory_and_suppliers():
    httpd, port, db_path = start_server()
    base = f'http://localhost:{port}'
    try:
        status, body = request('GET', base + '/api/inventory')
        assert status == 200 and json.loads(body) == []

        status, body = request(
            'POST',
            base + '/api/inventory',
            json.dumps({'name': '철근', 'quantity': '100'}).encode(),
        )
        assert status == 201
        item_id = json.loads(body)['id']

        status, body = request('GET', base + '/api/inventory')
        items = json.loads(body)
        assert len(items) == 1 and items[0]['id'] == item_id

        status, _ = request(
            'PUT',
            base + f'/api/inventory/{item_id}',
            json.dumps({'quantity': '200'}).encode(),
        )
        assert status == 200

        status, body = request('GET', base + '/api/inventory')
        items = json.loads(body)
        assert items[0]['quantity'] == '200'

        status, _ = request('DELETE', base + f'/api/inventory/{item_id}')
        assert status == 200

        status, body = request(
            'POST',
            base + '/api/suppliers',
            json.dumps({'name': 'ABC', 'note': 'steel'}).encode(),
        )
        assert status == 201
        sup_id = json.loads(body)['id']

        status, body = request('GET', base + '/api/suppliers')
        sups = json.loads(body)
        assert len(sups) == 1 and sups[0]['id'] == sup_id

        status, _ = request(
            'PUT',
            base + f'/api/suppliers/{sup_id}',
            json.dumps({'note': 'updated'}).encode(),
        )
        assert status == 200

        status, body = request('GET', base + '/api/suppliers')
        sups = json.loads(body)
        assert sups[0]['note'] == 'updated'

        status, _ = request('DELETE', base + f'/api/suppliers/{sup_id}')
        assert status == 200

    finally:
        stop_server(httpd, db_path)
