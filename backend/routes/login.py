from flask import Blueprint, request, jsonify
from db import get_db_connection

login_bp = Blueprint('login', __name__)

@login_bp.route('/login', methods=['POST'])
def login():
    conn = None
    cursor = None

    try:
        data = request.get_json(silent=True)

        if not data:
            return jsonify({"message": "Request harus berupa JSON"}), 400

        nama = data.get('nama')
        nim = data.get('nim')

        if isinstance(nama, str):
            nama = nama.strip()
        if isinstance(nim, str):
            nim = nim.strip()

        if not nama or not nim:
            return jsonify({"message": "Nama dan NIM wajib diisi"}), 400

        if not isinstance(nim, str):
            nim = str(nim)

        if len(nim) != 9:
            return jsonify({"message": "NIM harus 9 karakter"}), 400

        if not nim.isdigit():
            return jsonify({"message": "NIM harus berupa angka"}), 400

        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("""
            SELECT id, nama, role, nim, prodi, kelas
            FROM users
            WHERE nama = %s AND nim = %s
            LIMIT 1
        """, (nama, nim))

        user = cursor.fetchone()

        if not user:
            return jsonify({"message": "User tidak ditemukan"}), 404

        return jsonify({
            "message": "Login berhasil",
            "user": {
                "id": user["id"],
                "nama": user["nama"],
                "role": user["role"],
                "nim": user["nim"],
                "prodi": user["prodi"],
                "kelas": user["kelas"]
            }
        }), 200

    except Exception as e:
        return jsonify({
            "message": f"Gagal login: {str(e)}"
        }), 500

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()