import json
import os
import sqlite3
from http.server import SimpleHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse


def db_path():
    return os.environ.get('DB_PATH', 'materials.db')


def init_db():
    conn = sqlite3.connect(db_path())
    cur = conn.cursor()
    cur.execute(
        'CREATE TABLE IF NOT EXISTS inventory (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, quantity TEXT NOT NULL)'
    )
    cur.execute(
        'CREATE TABLE IF NOT EXISTS suppliers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, note TEXT NOT NULL)'
    )
    conn.commit()
    conn.close()


class MaterialHandler(SimpleHTTPRequestHandler):
    def send_json(self, data, status=200):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == '/api/inventory':
            conn = sqlite3.connect(db_path())
            conn.row_factory = sqlite3.Row
            rows = conn.execute('SELECT * FROM inventory').fetchall()
            conn.close()
            self.send_json([dict(r) for r in rows])
        elif parsed.path == '/api/suppliers':
            conn = sqlite3.connect(db_path())
            conn.row_factory = sqlite3.Row
            rows = conn.execute('SELECT * FROM suppliers').fetchall()
            conn.close()
            self.send_json([dict(r) for r in rows])
        else:
            super().do_GET()

    def read_json(self):
        length = int(self.headers.get('Content-Length', '0'))
        if length:
            body = self.rfile.read(length)
            return json.loads(body.decode())
        return {}

    def do_POST(self):
        parsed = urlparse(self.path)
        if parsed.path == '/api/inventory':
            data = self.read_json()
            if 'name' not in data or 'quantity' not in data:
                self.send_json({'error': 'invalid data'}, 400)
                return
            conn = sqlite3.connect(db_path())
            cur = conn.cursor()
            cur.execute('INSERT INTO inventory (name, quantity) VALUES (?, ?)', (data['name'], data['quantity']))
            conn.commit()
            item_id = cur.lastrowid
            conn.close()
            self.send_json({'id': item_id}, 201)
        elif parsed.path == '/api/suppliers':
            data = self.read_json()
            if 'name' not in data or 'note' not in data:
                self.send_json({'error': 'invalid data'}, 400)
                return
            conn = sqlite3.connect(db_path())
            cur = conn.cursor()
            cur.execute('INSERT INTO suppliers (name, note) VALUES (?, ?)', (data['name'], data['note']))
            conn.commit()
            sup_id = cur.lastrowid
            conn.close()
            self.send_json({'id': sup_id}, 201)
        else:
            self.send_error(404)

    def do_PUT(self):
        parsed = urlparse(self.path)
        if parsed.path.startswith('/api/inventory/'):
            try:
                item_id = int(parsed.path.rsplit('/', 1)[1])
            except ValueError:
                self.send_json({'error': 'invalid id'}, 400)
                return
            data = self.read_json()
            if not any(k in data for k in ('name', 'quantity')):
                self.send_json({'error': 'invalid data'}, 400)
                return
            conn = sqlite3.connect(db_path())
            cur = conn.cursor()
            fields, values = [], []
            if 'name' in data:
                fields.append('name=?')
                values.append(data['name'])
            if 'quantity' in data:
                fields.append('quantity=?')
                values.append(data['quantity'])
            values.append(item_id)
            cur.execute(f"UPDATE inventory SET {', '.join(fields)} WHERE id=?", values)
            if cur.rowcount == 0:
                conn.close()
                self.send_json({'error': 'not found'}, 404)
                return
            conn.commit()
            conn.close()
            self.send_json({})
        elif parsed.path.startswith('/api/suppliers/'):
            try:
                sup_id = int(parsed.path.rsplit('/', 1)[1])
            except ValueError:
                self.send_json({'error': 'invalid id'}, 400)
                return
            data = self.read_json()
            if not any(k in data for k in ('name', 'note')):
                self.send_json({'error': 'invalid data'}, 400)
                return
            conn = sqlite3.connect(db_path())
            cur = conn.cursor()
            fields, values = [], []
            if 'name' in data:
                fields.append('name=?')
                values.append(data['name'])
            if 'note' in data:
                fields.append('note=?')
                values.append(data['note'])
            values.append(sup_id)
            cur.execute(f"UPDATE suppliers SET {', '.join(fields)} WHERE id=?", values)
            if cur.rowcount == 0:
                conn.close()
                self.send_json({'error': 'not found'}, 404)
                return
            conn.commit()
            conn.close()
            self.send_json({})
        else:
            self.send_error(404)

    def do_DELETE(self):
        parsed = urlparse(self.path)
        if parsed.path.startswith('/api/inventory/'):
            try:
                item_id = int(parsed.path.rsplit('/', 1)[1])
            except ValueError:
                self.send_json({'error': 'invalid id'}, 400)
                return
            conn = sqlite3.connect(db_path())
            cur = conn.cursor()
            cur.execute('DELETE FROM inventory WHERE id=?', (item_id,))
            conn.commit()
            conn.close()
            self.send_json({})
        elif parsed.path.startswith('/api/suppliers/'):
            try:
                sup_id = int(parsed.path.rsplit('/', 1)[1])
            except ValueError:
                self.send_json({'error': 'invalid id'}, 400)
                return
            conn = sqlite3.connect(db_path())
            cur = conn.cursor()
            cur.execute('DELETE FROM suppliers WHERE id=?', (sup_id,))
            conn.commit()
            conn.close()
            self.send_json({})
        else:
            self.send_error(404)


def run_server(port=8000):
    init_db()
    httpd = HTTPServer(('0.0.0.0', port), MaterialHandler)
    return httpd


if __name__ == '__main__':
    server = run_server()
    print('Serving on port 8000')
    server.serve_forever()
