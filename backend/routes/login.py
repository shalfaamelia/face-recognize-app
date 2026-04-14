from flask import Blueprint, request, jsonify
from db import get_db_connection

login_bp = Blueprint('login', __name__)

@login_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    nama = data.get('nama')
    nim = data.get('nim')

    if not nama or not nim:
        return jsonify({"message": "Nama dan NIM wajib diisi"}), 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT id, nama, role, nim, prodi, kelas
        FROM users
        WHERE nama = %s AND nim = %s
    """, (nama, nim))

    user = cursor.fetchone()

    cursor.close()
    conn.close()

    if not user:
        return jsonify({"message": "User tidak ditemukan"}), 404

    return jsonify({
        "message": "Login berhasil",
        "user": {
            "id": user['id'],
            "nama": user['nama'],
            "role": user['role'],
            "nim": user['nim'],
            "prodi": user['prodi'],
            "kelas": user['kelas']
        }
    }), 200