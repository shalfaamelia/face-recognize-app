# monitoring.py
from flask import Blueprint, request, jsonify
from datetime import datetime
from db import get_db_connection

monitoring_bp = Blueprint('monitoring', __name__)

@monitoring_bp.route('/log_attendance', methods=['POST'])
def log_attendance():
    """
    Mencatat kehadiran user berdasarkan user_id yang dikirim.
    Semua kolom (kode, nama, nim, prodi, kelas) terisi sesuai data user.
    """
    data = request.get_json()
    user_id = data.get('user_id')
    timestamp = data.get('timestamp', datetime.now().isoformat())

    if not user_id:
        return jsonify({"message": "user_id is required"}), 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        # Ambil data lengkap user
        cursor.execute("""
            SELECT kode, nama, nim, prodi, kelas
            FROM users
            WHERE id=%s
        """, (user_id,))
        user = cursor.fetchone()

        if not user:
            return jsonify({"message": "User not found"}), 404

        # Insert ke log_masuk
        cursor.execute("""
            INSERT INTO log_masuk (kode, nama, nim, prodi, kelas, masuk)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (
            user['kode'],
            user['nama'],
            user['nim'],
            user['prodi'],
            user['kelas'],
            timestamp
        ))
        conn.commit()

    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Failed to log attendance: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()

    return jsonify({"message": f"Attendance logged for {user['nama']}"}), 201

# =========================
# Monitoring / GET log
# =========================
@monitoring_bp.route('/monitoring', methods=['GET'])
def get_monitoring():
    """
    Menampilkan semua log kehadiran lengkap
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT id, kode, nama, nim, prodi, kelas, masuk
            FROM log_masuk
            ORDER BY masuk DESC
        """)
        logs = cursor.fetchall()
    except Exception as e:
        return jsonify({"message": f"Failed to fetch logs: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()

    return jsonify(logs)