import os
from functools import wraps
from flask import request, jsonify, g
from itsdangerous import URLSafeTimedSerializer, BadSignature, SignatureExpired
from db import get_db_connection

SECRET_KEY = os.getenv('SECRET_KEY', 'smartaccess-secret-key')
TOKEN_SALT = 'smartaccess-auth'
TOKEN_MAX_AGE = 60 * 60 * 24  # 1 hari

serializer = URLSafeTimedSerializer(SECRET_KEY)


def create_access_token(user):
    payload = {
        'id': user['id'],
        'kode': user['kode'],
        'nama': user['nama'],
        'role': user['role'],
        'email': user['email']
    }
    return serializer.dumps(payload, salt=TOKEN_SALT)


def decode_access_token(token):
    try:
        payload = serializer.loads(token, salt=TOKEN_SALT, max_age=TOKEN_MAX_AGE)
        return payload, None
    except SignatureExpired:
        return None, 'Token expired'
    except BadSignature:
        return None, 'Token invalid'


def get_token_from_header():
    auth_header = request.headers.get('Authorization', '')
    if auth_header.startswith('Bearer '):
        return auth_header.split(' ', 1)[1].strip()
    return None


def get_current_user():
    token = get_token_from_header()
    if not token:
        return None, 'Token tidak ditemukan'

    payload, error = decode_access_token(token)
    if error:
        return None, error

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT id, kode, nama, role, email
            FROM users
            WHERE id = %s
        """, (payload['id'],))
        user = cursor.fetchone()

        if not user:
            return None, 'User tidak ditemukan'

        if user['role'] == 'mahasiswa':
            return None, 'Mahasiswa tidak dapat login ke web'

        return user, None
    finally:
        cursor.close()
        conn.close()


def auth_required(allowed_roles=None):
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            if request.method == 'OPTIONS':
                return '', 204

            user, error = get_current_user()
            if error:
                return jsonify({"message": error}), 401

            if allowed_roles and user['role'] not in allowed_roles:
                return jsonify({"message": "Akses ditolak"}), 403

            g.current_user = user
            return fn(*args, **kwargs)
        return wrapper
    return decorator
