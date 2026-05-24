from flask import Blueprint, request, jsonify
from db import get_db_connection
from utils.auth_guard import create_access_token, get_current_user

auth_bp = Blueprint('auth', __name__)


def build_permissions(role):
    return {
        "can_manage_users": role == 'kepala_lab',
        "can_manage_jadwal": role in ['kepala_lab', 'teknisi'],
        "can_access_monitoring": role in ['kepala_lab', 'teknisi', 'sarpras'],
        "can_access_peminjaman": role in ['kepala_lab', 'teknisi', 'sarpras'],
        "can_access_laporan": role in ['kepala_lab', 'teknisi', 'sarpras'],
    }


@auth_bp.route('/auth/login', methods=['POST'])
def login():
    data = request.get_json()

    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({"message": "Email dan password wajib diisi"}), 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT id, kode, nama, role, email, password, status
            FROM users
            WHERE email = %s
            LIMIT 1
        """, (email,))
        user = cursor.fetchone()

        if not user:
            return jsonify({"message": "Email atau password salah"}), 401

        if user['role'] == 'mahasiswa':
            return jsonify({"message": "Mahasiswa tidak dapat login ke web"}), 403

        if user['status'] != 'aktif':
            return jsonify({"message": "Akun tidak aktif"}), 403

        # sementara cocok dengan struktur DB kamu saat ini (plaintext password)
        if user['password'] != password:
            return jsonify({"message": "Email atau password salah"}), 401

        token = create_access_token(user)

        return jsonify({
            "message": "Login berhasil",
            "token": token,
            "user": {
                "id": user['id'],
                "kode": user['kode'],
                "nama": user['nama'],
                "role": user['role'],
                "email": user['email'],
                "permissions": build_permissions(user['role'])
            }
        }), 200

    except Exception as e:
        return jsonify({"message": f"Gagal login: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()


@auth_bp.route('/auth/me', methods=['GET'])
def me():
    user, error = get_current_user()
    if error:
        return jsonify({"message": error}), 401

    return jsonify({
        "user": {
            "id": user['id'],
            "kode": user['kode'],
            "nama": user['nama'],
            "role": user['role'],
            "email": user['email'],
            "permissions": build_permissions(user['role'])
        }
    }), 200


@auth_bp.route('/auth/profile', methods=['GET'])
def get_profile():
    user, error = get_current_user()
    if error:
        return jsonify({"message": error}), 401

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT id, kode, nama, role, email, nip, status
            FROM users
            WHERE id = %s
        """, (user['id'],))
        profile = cursor.fetchone()

        if not profile:
            return jsonify({"message": "Profile tidak ditemukan"}), 404

        return jsonify({
            "profile": {
                "id": profile['id'],
                "kode": profile['kode'],
                "nama": profile['nama'],
                "role": profile['role'],
                "email": profile['email'],
                "nip": profile['nip'],
                "status": profile['status']
            }
        }), 200

    except Exception as e:
        return jsonify({"message": f"Gagal mengambil profile: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()


@auth_bp.route('/auth/profile', methods=['PUT'])
def update_profile():
    user, error = get_current_user()
    if error:
        return jsonify({"message": error}), 401

    data = request.get_json()
    nama = data.get('nama')
    email = data.get('email')
    password = data.get('password')

    if not nama or not email:
        return jsonify({"message": "Nama dan email wajib diisi"}), 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("SELECT id FROM users WHERE email=%s AND id != %s", (email, user['id']))
        if cursor.fetchone():
            return jsonify({"message": f"Email '{email}' sudah terdaftar"}), 400

        if password:
            cursor.execute("""
                UPDATE users
                SET nama=%s, email=%s, password=%s
                WHERE id=%s
            """, (nama, email, password, user['id']))
        else:
            cursor.execute("""
                UPDATE users
                SET nama=%s, email=%s
                WHERE id=%s
            """, (nama, email, user['id']))

        conn.commit()

        cursor.execute("""
            SELECT id, kode, nama, role, email, nip, status
            FROM users
            WHERE id = %s
        """, (user['id'],))
        updated_profile = cursor.fetchone()

        return jsonify({
            "message": "Profile berhasil diperbarui",
            "profile": {
                "id": updated_profile['id'],
                "kode": updated_profile['kode'],
                "nama": updated_profile['nama'],
                "role": updated_profile['role'],
                "email": updated_profile['email'],
                "nip": updated_profile['nip'],
                "status": updated_profile['status']
            }
        }), 200

    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Gagal update profile: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()


@auth_bp.route('/auth/logout', methods=['POST'])
def logout():
    return jsonify({"message": "Logout berhasil"}), 200