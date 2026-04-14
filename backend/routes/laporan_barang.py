import os
import uuid
from flask import Blueprint, request, jsonify, send_from_directory
from werkzeug.utils import secure_filename
from db import get_db_connection

laporan_barang_bp = Blueprint('laporan_barang', __name__)

UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), '..', 'uploads', 'laporan_barang')
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# =========================
# CREATE LAPORAN BARANG
# =========================
@laporan_barang_bp.route('/laporan-barang', methods=['POST'])
def create_laporan_barang():
    user_id = request.form.get('user_id')
    tanggal = request.form.get('tanggal')
    keterangan = request.form.get('keterangan')
    deskripsi = request.form.get('deskripsi', '')
    foto = request.files.get('foto')

    if not user_id or not tanggal or not keterangan:
        return jsonify({"message": "user_id, tanggal, dan keterangan wajib diisi"}), 400

    if keterangan not in ['temuan', 'hilang']:
        return jsonify({"message": "keterangan harus 'temuan' atau 'hilang'"}), 400

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

        foto_filename = None

        if foto and foto.filename:
            if not allowed_file(foto.filename):
                return jsonify({"message": "Format foto harus png/jpg/jpeg"}), 400

            ext = foto.filename.rsplit('.', 1)[1].lower()
            foto_filename = f"{uuid.uuid4().hex}.{ext}"
            foto.save(os.path.join(UPLOAD_FOLDER, secure_filename(foto_filename)))

        cursor.execute("""
            INSERT INTO laporan_barang
            (user_id, nama, nim, kelas, prodi, tanggal, keterangan, deskripsi, foto)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            user['id'],
            user['nama'],
            user['nim'],
            user['kelas'],
            user['prodi'],
            tanggal,
            keterangan,
            deskripsi,
            foto_filename
        ))

        conn.commit()
        return jsonify({"message": "Laporan barang berhasil ditambahkan"}), 201

    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Gagal menambahkan laporan barang: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()

# =========================
# GET LAPORAN BARANG PER USER
# =========================
@laporan_barang_bp.route('/laporan-barang/user/<int:user_id>', methods=['GET'])
def get_laporan_barang_by_user(user_id):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT id, user_id, nama, nim, kelas, prodi, tanggal,
                   keterangan, deskripsi, foto, status
            FROM laporan_barang
            WHERE user_id = %s
            ORDER BY tanggal DESC, id DESC
        """, (user_id,))
        rows = cursor.fetchall()

        for row in rows:
            if row.get('tanggal'):
                row['tanggal'] = row['tanggal'].isoformat()

            if row.get('foto'):
                row['foto_url'] = f"{request.host_url.rstrip('/')}/laporan-barang/uploads/{row['foto']}"
            else:
                row['foto_url'] = None

        return jsonify(rows), 200

    except Exception as e:
        return jsonify({"message": f"Gagal mengambil laporan barang: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()

# =========================
# UPDATE LAPORAN BARANG
# =========================
@laporan_barang_bp.route('/laporan-barang/<int:laporan_id>', methods=['PUT'])
def update_laporan_barang(laporan_id):
    user_id = request.form.get('user_id')
    tanggal = request.form.get('tanggal')
    keterangan = request.form.get('keterangan')
    deskripsi = request.form.get('deskripsi', '')
    foto = request.files.get('foto')

    if not user_id or not tanggal or not keterangan:
        return jsonify({"message": "user_id, tanggal, dan keterangan wajib diisi"}), 400

    if keterangan not in ['temuan', 'hilang']:
        return jsonify({"message": "keterangan harus 'temuan' atau 'hilang'"}), 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT id, foto
            FROM laporan_barang
            WHERE id = %s AND user_id = %s
        """, (laporan_id, user_id))
        existing = cursor.fetchone()

        if not existing:
            return jsonify({"message": "Data laporan barang tidak ditemukan"}), 404

        foto_filename = existing['foto']

        if foto and foto.filename:
            if not allowed_file(foto.filename):
                return jsonify({"message": "Format foto harus png/jpg/jpeg"}), 400

            if foto_filename:
                old_path = os.path.join(UPLOAD_FOLDER, foto_filename)
                if os.path.exists(old_path):
                    os.remove(old_path)

            ext = foto.filename.rsplit('.', 1)[1].lower()
            foto_filename = f"{uuid.uuid4().hex}.{ext}"
            foto.save(os.path.join(UPLOAD_FOLDER, secure_filename(foto_filename)))

        cursor.execute("""
            UPDATE laporan_barang
            SET tanggal = %s,
                keterangan = %s,
                deskripsi = %s,
                foto = %s
            WHERE id = %s AND user_id = %s
        """, (
            tanggal,
            keterangan,
            deskripsi,
            foto_filename,
            laporan_id,
            user_id
        ))

        conn.commit()
        return jsonify({"message": "Laporan barang berhasil diperbarui"}), 200

    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Gagal update laporan barang: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()

# =========================
# DELETE LAPORAN BARANG
# =========================
@laporan_barang_bp.route('/laporan-barang/<int:laporan_id>', methods=['DELETE'])
def delete_laporan_barang(laporan_id):
    user_id = request.args.get('user_id')

    if not user_id:
        return jsonify({"message": "user_id wajib dikirim"}), 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT id, foto
            FROM laporan_barang
            WHERE id = %s AND user_id = %s
        """, (laporan_id, user_id))
        existing = cursor.fetchone()

        if not existing:
            return jsonify({"message": "Data laporan barang tidak ditemukan"}), 404

        if existing.get('foto'):
            foto_path = os.path.join(UPLOAD_FOLDER, existing['foto'])
            if os.path.exists(foto_path):
                os.remove(foto_path)

        cursor.execute("""
            DELETE FROM laporan_barang
            WHERE id = %s AND user_id = %s
        """, (laporan_id, user_id))

        conn.commit()
        return jsonify({"message": "Laporan barang berhasil dihapus"}), 200

    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Gagal menghapus laporan barang: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()

# =========================
# PREVIEW FOTO
# =========================
@laporan_barang_bp.route('/laporan-barang/uploads/<filename>', methods=['GET'])
def get_laporan_barang_file(filename):
    return send_from_directory(UPLOAD_FOLDER, filename)