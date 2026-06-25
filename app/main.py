# app/main.py
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({
        "message": "Merhaba! DevOps Tutorial App çalışıyor 🚀 - CI/CD ile guncellendi!",
        "version": "2.0"
    })

@app.route('/health')
def health():
    return jsonify({
        "status": "ok"
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)