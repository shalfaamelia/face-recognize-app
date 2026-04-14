from flask import Blueprint, request, jsonify
from db import get_db_connection

peminjaman_bp = Blueprint('peminjaman', __name__)

# =========================
# CREATE PEMINJAMAN
# =========================
@peminjaman_bp.route('/peminjaman', methods=['POST'])
def create_peminjaman():
    data = request.get_json()

    user_id = data.get('user_id')
    tanggal = data.get('tanggal')
    jam_mulai = data.get('jam_mulai')
    jam_selesai = data.get('jam_selesai')
    keterangan = data.get('keterangan', '')

    if not user_id or not tanggal or not jam_mulai or not jam_selesai:
        return jsonify({"message": "user_id, tanggal, jam_mulai, dan jam_selesai wajib diisi"}), 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT id, nama, nim, prodi, kelas
            FROM users
            WHERE id = %s
        """, (user_id,))
        user = cursor.fetchone()

        if not user:
            return jsonify({"message": "User tidak ditemukan"}), 404

        cursor.execute("""
            INSERT INTO peminjaman_lab
            (user_id, nama, nim, prodi, kelas, tanggal, jam_mulai, jam_selesai, keterangan)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            user['id'],
            user['nama'],
            user['nim'],
            user['prodi'],
            user['kelas'],
            tanggal,
            jam_mulai,
            jam_selesai,
            keterangan
        ))
        conn.commit()

        return jsonify({"message": "Peminjaman berhasil ditambahkan"}), 201

    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Gagal menambahkan peminjaman: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()


# =========================
# GET PEMINJAMAN PER USER
# =========================
@peminjaman_bp.route('/peminjaman/user/<int:user_id>', methods=['GET'])
def get_peminjaman_by_user(user_id):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT id, user_id, nama, nim, prodi, kelas,
                   tanggal, jam_mulai, jam_selesai, keterangan, status
            FROM peminjaman_lab
            WHERE user_id = %s
            ORDER BY tanggal DESC, jam_mulai DESC
        """, (user_id,))
        data = cursor.fetchall()

        for row in data:
            if row.get('tanggal'):
                row['tanggal'] = row['tanggal'].isoformat()
            if row.get('jam_mulai'):
                row['jam_mulai'] = str(row['jam_mulai'])
            if row.get('jam_selesai'):
                row['jam_selesai'] = str(row['jam_selesai'])

        return jsonify(data), 200

    except Exception as e:
        return jsonify({"message": f"Gagal mengambil data peminjaman: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()


# =========================
# UPDATE PEMINJAMAN
# =========================
@peminjaman_bp.route('/peminjaman/<int:peminjaman_id>', methods=['PUT'])
def update_peminjaman(peminjaman_id):
    data = request.get_json()

    user_id = data.get('user_id')
    tanggal = data.get('tanggal')
    jam_mulai = data.get('jam_mulai')
    jam_selesai = data.get('jam_selesai')
    keterangan = data.get('keterangan', '')

    if not user_id or not tanggal or not jam_mulai or not jam_selesai:
        return jsonify({"message": "user_id, tanggal, jam_mulai, dan jam_selesai wajib diisi"}), 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT id FROM peminjaman_lab
            WHERE id = %s AND user_id = %s
        """, (peminjaman_id, user_id))
        existing = cursor.fetchone()

        if not existing:
            return jsonify({"message": "Data peminjaman tidak ditemukan"}), 404

        cursor.execute("""
            UPDATE peminjaman_lab
            SET tanggal = %s,
                jam_mulai = %s,
                jam_selesai = %s,
                keterangan = %s
            WHERE id = %s AND user_id = %s
        """, (
            tanggal,
            jam_mulai,
            jam_selesai,
            keterangan,
            peminjaman_id,
            user_id
        ))
        conn.commit()

        return jsonify({"message": "Peminjaman berhasil diperbarui"}), 200

    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Gagal update peminjaman: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()


# =========================
# DELETE PEMINJAMAN
# =========================
@peminjaman_bp.route('/peminjaman/<int:peminjaman_id>', methods=['DELETE'])
def delete_peminjaman(peminjaman_id):
    user_id = request.args.get('user_id')

    if not user_id:
        return jsonify({"message": "user_id wajib dikirim"}), 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT id FROM peminjaman_lab
            WHERE id = %s AND user_id = %s
        """, (peminjaman_id, user_id))
        existing = cursor.fetchone()

        if not existing:
            return jsonify({"message": "Data peminjaman tidak ditemukan"}), 404

        cursor.execute("""
            DELETE FROM peminjaman_lab
            WHERE id = %s AND user_id = %s
        """, (peminjaman_id, user_id))
        conn.commit()

        return jsonify({"message": "Peminjaman berhasil dihapus"}), 200

    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Gagal menghapus peminjaman: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()