from flask import Blueprint, request, jsonify
from db import get_db_connection

peminjaman_bp = Blueprint('peminjaman', __name__)


# =========================
# HELPER
# =========================
def format_peminjaman_row(row):
    if row.get('tanggal'):
        row['tanggal'] = row['tanggal'].isoformat()
    if row.get('jam_mulai'):
        row['jam_mulai'] = str(row['jam_mulai'])
    if row.get('jam_selesai'):
        row['jam_selesai'] = str(row['jam_selesai'])
    return row


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
        return jsonify({
            "message": "user_id, tanggal, jam_mulai, dan jam_selesai wajib diisi"
        }), 400

    if jam_mulai >= jam_selesai:
        return jsonify({
            "message": "jam_mulai harus lebih kecil dari jam_selesai"
        }), 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT id, nama, nim, prodi, kelas, role, status
            FROM users
            WHERE id = %s
        """, (user_id,))
        user = cursor.fetchone()

        if not user:
            return jsonify({"message": "User tidak ditemukan"}), 404

        if user['status'] != 'aktif':
            return jsonify({"message": "User tidak aktif"}), 403

        if user['role'] != 'mahasiswa':
            return jsonify({"message": "Hanya mahasiswa yang dapat mengajukan peminjaman"}), 403

        cursor.execute("""
            SELECT id
            FROM peminjaman_lab
            WHERE tanggal = %s
              AND status IN ('menunggu', 'disetujui')
              AND (%s < jam_selesai AND %s > jam_mulai)
        """, (tanggal, jam_mulai, jam_selesai))
        bentrok = cursor.fetchone()

        if bentrok:
            return jsonify({"message": "Jadwal peminjaman bentrok dengan jadwal lain"}), 409

        cursor.execute("""
            INSERT INTO peminjaman_lab
            (user_id, nama, nim, prodi, kelas, tanggal, jam_mulai, jam_selesai, keterangan, status)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 'menunggu')
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

        return jsonify({
            "message": "Peminjaman berhasil ditambahkan dan menunggu konfirmasi admin"
        }), 201

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
                   tanggal, jam_mulai, jam_selesai, keterangan, status,
                   created_at, updated_at
            FROM peminjaman_lab
            WHERE user_id = %s
            ORDER BY tanggal DESC, jam_mulai DESC
        """, (user_id,))
        data = cursor.fetchall()

        data = [format_peminjaman_row(row) for row in data]

        return jsonify(data), 200

    except Exception as e:
        return jsonify({"message": f"Gagal mengambil data peminjaman: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()


# =========================
# UPDATE PEMINJAMAN
# hanya bisa update kalau status masih menunggu
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
        return jsonify({
            "message": "user_id, tanggal, jam_mulai, dan jam_selesai wajib diisi"
        }), 400

    if jam_mulai >= jam_selesai:
        return jsonify({
            "message": "jam_mulai harus lebih kecil dari jam_selesai"
        }), 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT id, status
            FROM peminjaman_lab
            WHERE id = %s AND user_id = %s
        """, (peminjaman_id, user_id))
        existing = cursor.fetchone()

        if not existing:
            return jsonify({"message": "Data peminjaman tidak ditemukan"}), 404

        if existing['status'] != 'menunggu':
            return jsonify({
                "message": "Peminjaman hanya bisa diubah saat status masih menunggu"
            }), 400

        cursor.execute("""
            SELECT id
            FROM peminjaman_lab
            WHERE tanggal = %s
              AND status IN ('menunggu', 'disetujui')
              AND id != %s
              AND (%s < jam_selesai AND %s > jam_mulai)
        """, (tanggal, peminjaman_id, jam_mulai, jam_selesai))
        bentrok = cursor.fetchone()

        if bentrok:
            return jsonify({"message": "Jadwal peminjaman bentrok dengan jadwal lain"}), 409

        cursor.execute("""
            UPDATE peminjaman_lab
            SET tanggal = %s,
                jam_mulai = %s,
                jam_selesai = %s,
                keterangan = %s,
                updated_at = CURRENT_TIMESTAMP
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
# hanya bisa hapus kalau status masih menunggu
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
            SELECT id, status
            FROM peminjaman_lab
            WHERE id = %s AND user_id = %s
        """, (peminjaman_id, user_id))
        existing = cursor.fetchone()

        if not existing:
            return jsonify({"message": "Data peminjaman tidak ditemukan"}), 404

        if existing['status'] != 'menunggu':
            return jsonify({
                "message": "Peminjaman hanya bisa dihapus saat status masih menunggu"
            }), 400

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


# =========================
# GET PEMINJAMAN UNTUK HALAMAN ACC/TOLAK
# hanya data menunggu
# =========================
@peminjaman_bp.route('/admin/peminjaman', methods=['GET'])
def get_all_peminjaman():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT id, user_id, nama, nim, prodi, kelas,
                   tanggal, jam_mulai, jam_selesai, keterangan, status,
                   created_at, updated_at
            FROM peminjaman_lab
            WHERE status = 'menunggu'
            ORDER BY tanggal DESC, jam_mulai DESC
        """)
        data = cursor.fetchall()

        data = [format_peminjaman_row(row) for row in data]

        return jsonify(data), 200

    except Exception as e:
        return jsonify({"message": f"Gagal mengambil data peminjaman: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()


# =========================
# DETAIL PEMINJAMAN
# =========================
@peminjaman_bp.route('/admin/peminjaman/<int:peminjaman_id>', methods=['GET'])
def get_detail_peminjaman(peminjaman_id):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT id, user_id, nama, nim, prodi, kelas,
                   tanggal, jam_mulai, jam_selesai, keterangan, status,
                   created_at, updated_at
            FROM peminjaman_lab
            WHERE id = %s
        """, (peminjaman_id,))
        row = cursor.fetchone()

        if not row:
            return jsonify({"message": "Data peminjaman tidak ditemukan"}), 404

        row = format_peminjaman_row(row)

        return jsonify(row), 200

    except Exception as e:
        return jsonify({"message": f"Gagal mengambil detail peminjaman: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()


# =========================
# UPDATE STATUS PEMINJAMAN
# =========================
@peminjaman_bp.route('/admin/peminjaman/<int:peminjaman_id>/status', methods=['PUT'])
def update_status_peminjaman(peminjaman_id):
    data = request.get_json()

    status_baru = data.get('status')

    if not status_baru:
        return jsonify({"message": "status wajib diisi"}), 400

    if status_baru not in ['disetujui', 'ditolak']:
        return jsonify({"message": "Status harus 'disetujui' atau 'ditolak'"}), 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT id, tanggal, jam_mulai, jam_selesai, status
            FROM peminjaman_lab
            WHERE id = %s
        """, (peminjaman_id,))
        peminjaman = cursor.fetchone()

        if not peminjaman:
            return jsonify({"message": "Data peminjaman tidak ditemukan"}), 404

        if peminjaman['status'] != 'menunggu':
            return jsonify({"message": "Hanya peminjaman dengan status menunggu yang bisa dikonfirmasi"}), 400

        if status_baru == 'disetujui':
            cursor.execute("""
                SELECT id
                FROM peminjaman_lab
                WHERE tanggal = %s
                  AND status = 'disetujui'
                  AND id != %s
                  AND (%s < jam_selesai AND %s > jam_mulai)
            """, (
                peminjaman['tanggal'],
                peminjaman_id,
                peminjaman['jam_mulai'],
                peminjaman['jam_selesai']
            ))
            bentrok = cursor.fetchone()

            if bentrok:
                return jsonify({
                    "message": "Peminjaman tidak bisa disetujui karena bentrok dengan jadwal yang sudah disetujui"
                }), 409

        cursor.execute("""
            UPDATE peminjaman_lab
            SET status = %s,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = %s
        """, (status_baru, peminjaman_id))
        conn.commit()

        return jsonify({
            "message": f"Status peminjaman berhasil diubah menjadi {status_baru}"
        }), 200

    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Gagal update status peminjaman: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()