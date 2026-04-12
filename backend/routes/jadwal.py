from flask import Blueprint, request, jsonify
from db import get_db_connection

jadwal_bp = Blueprint('jadwal', __name__)

# ===============================
# GET JADWAL PRAKTIKUM
# ===============================
@jadwal_bp.route('/', methods=['GET'])
def get_jadwal():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT id, kode, nama, dosen, kelas, hari,
               TIME_FORMAT(jam_mulai, '%H:%i') AS jam_mulai,
               TIME_FORMAT(jam_selesai, '%H:%i') AS jam_selesai
        FROM jadwal_praktikum
        ORDER BY hari, jam_mulai
    """)
    jadwal = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify(jadwal)

# ===============================
# CREATE JADWAL PRAKTIKUM
# ===============================
@jadwal_bp.route('/', methods=['POST'])
def create_jadwal():
    data = request.get_json()
    kode = data.get('kode')  # input manual
    nama = data.get('nama')
    dosen = data.get('dosen')
    kelas = data.get('kelas')
    hari = data.get('hari')
    jam_mulai = data.get('jam_mulai')
    jam_selesai = data.get('jam_selesai')

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("""
            INSERT INTO jadwal_praktikum
            (kode, nama, dosen, kelas, hari, jam_mulai, jam_selesai)
            VALUES (%s,%s,%s,%s,%s,%s,%s)
        """, (kode, nama, dosen, kelas, hari, jam_mulai, jam_selesai))
        jadwal_id = cursor.lastrowid
        conn.commit()
    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Gagal membuat jadwal: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()

    return jsonify({"message": "Jadwal berhasil dibuat", "id": jadwal_id}), 201

# ===============================
# UPDATE JADWAL PRAKTIKUM
# ===============================
@jadwal_bp.route('/<int:jadwal_id>', methods=['PUT'])
def update_jadwal(jadwal_id):
    data = request.get_json()
    kode = data.get('kode')
    nama = data.get('nama')
    dosen = data.get('dosen')
    kelas = data.get('kelas')
    hari = data.get('hari')
    jam_mulai = data.get('jam_mulai')
    jam_selesai = data.get('jam_selesai')

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT * FROM jadwal_praktikum WHERE id=%s", (jadwal_id,))
        if not cursor.fetchone():
            return jsonify({"message": "Jadwal tidak ditemukan"}), 404

        cursor.execute("""
            UPDATE jadwal_praktikum SET
            kode=%s, nama=%s, dosen=%s, kelas=%s, hari=%s, jam_mulai=%s, jam_selesai=%s
            WHERE id=%s
        """, (kode, nama, dosen, kelas, hari, jam_mulai, jam_selesai, jadwal_id))
        conn.commit()
    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Gagal update jadwal: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()

    return jsonify({"message": "Jadwal berhasil diupdate"}), 200

# ===============================
# DELETE JADWAL PRAKTIKUM
# ===============================
@jadwal_bp.route('/<int:jadwal_id>', methods=['DELETE'])
def delete_jadwal(jadwal_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT * FROM jadwal_praktikum WHERE id=%s", (jadwal_id,))
        if not cursor.fetchone():
            return jsonify({"message": "Jadwal tidak ditemukan"}), 404

        cursor.execute("DELETE FROM jadwal_praktikum WHERE id=%s", (jadwal_id,))
        conn.commit()
    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Gagal hapus jadwal: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()

    return jsonify({"message": "Jadwal berhasil dihapus"}), 200