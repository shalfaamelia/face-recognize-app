from flask import Blueprint, request, jsonify, send_from_directory, url_for
from werkzeug.utils import secure_filename
import os, uuid
from db import get_db_connection

ajuan_barang_bp = Blueprint('ajuan_barang', __name__)

UPLOAD_FOLDER = os.path.join(
    os.path.dirname(__file__),
    '..',
    'uploads',
    'laporan_barang'
)
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# =========================
# Helper
# =========================
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def format_laporan_barang_row(row):
    if row.get('tanggal'):
        row['tanggal'] = row['tanggal'].isoformat()
    if row.get('foto'):
        row['foto_url'] = url_for('ajuan_barang.get_laporan_barang_upload', filename=row['foto'], _external=True)
    else:
        row['foto_url'] = None
    return row

def save_laporan_barang_photo(foto):
    if not foto or not foto.filename:
        return None
    if not allowed_file(foto.filename):
        raise ValueError("Format foto harus png/jpg/jpeg")
    ext = foto.filename.rsplit('.', 1)[1].lower()
    foto_filename = f"{uuid.uuid4().hex}.{ext}"
    safe_filename = secure_filename(foto_filename)
    file_path = os.path.join(UPLOAD_FOLDER, safe_filename)
    foto.save(file_path)
    if not os.path.exists(file_path) or os.path.getsize(file_path) == 0:
        raise ValueError("Foto gagal disimpan")
    return safe_filename

# =========================
# GET LAPORAN BARANG USER
# =========================
@ajuan_barang_bp.route('/laporan-barang/user/<int:user_id>', methods=['GET'])
def get_laporan_barang_by_user(user_id):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("""
            SELECT id, user_id, nama, nim, kelas, prodi, tanggal, ruang, no_hp,
                   keterangan, deskripsi, foto, status,
                   created_at, updated_at, diterima_oleh, diterima_pada
            FROM laporan_barang
            WHERE user_id = %s
            ORDER BY created_at DESC
        """, (user_id,))
        rows = cursor.fetchall()
        rows = [format_laporan_barang_row(row) for row in rows]
        return jsonify(rows), 200
    finally:
        cursor.close()
        conn.close()

# =========================
# GET SEMUA AJUAN BARANG (ADMIN)
# hanya status menunggu
# =========================
@ajuan_barang_bp.route('/admin/ajuan-barang', methods=['GET'])
def get_ajuan_barang():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("""
            SELECT id, user_id, nama, nim, kelas, prodi, tanggal, ruang, no_hp,
                   keterangan, deskripsi, foto, status,
                   created_at, updated_at
            FROM laporan_barang
            WHERE status = 'menunggu'
            ORDER BY tanggal DESC, id DESC
        """)
        rows = cursor.fetchall()
        rows = [format_laporan_barang_row(row) for row in rows]
        return jsonify(rows), 200
    finally:
        cursor.close()
        conn.close()

# =========================
# CREATE LAPORAN BARANG (MOBILE)
# =========================
@ajuan_barang_bp.route('/laporan-barang', methods=['POST'])
def create_laporan_barang():
    user_id = request.form.get('user_id')
    tanggal = request.form.get('tanggal')
    ruang = request.form.get('ruang', '')
    no_hp = request.form.get('no_hp', '')
    keterangan = request.form.get('keterangan')
    deskripsi = request.form.get('deskripsi', '')
    foto = request.files.get('foto')

    if not user_id or not tanggal or not keterangan:
        return jsonify({
            "message": "user_id, tanggal, dan keterangan wajib diisi"
        }), 400

    if keterangan not in ['temuan', 'hilang']:
        return jsonify({
            "message": "keterangan harus 'temuan' atau 'hilang'"
        }), 400

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
            return jsonify({
                "message": "User tidak ditemukan"
            }), 404

        foto_filename = None

        if foto and foto.filename:
            foto_filename = save_laporan_barang_photo(foto)

        cursor.execute("""
            INSERT INTO laporan_barang
            (
                user_id,
                nama,
                nim,
                kelas,
                prodi,
                tanggal,
                ruang,
                no_hp,
                keterangan,
                deskripsi,
                foto,
                status
            )
            VALUES
            (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 'menunggu'
            )
        """, (
            user['id'],
            user['nama'],
            user['nim'],
            user['kelas'],
            user['prodi'],
            tanggal,
            ruang,
            no_hp,
            keterangan,
            deskripsi,
            foto_filename
        ))

        conn.commit()

        return jsonify({
            "message": "Laporan barang berhasil ditambahkan",
            "foto": foto_filename
        }), 201

    except ValueError as e:
        conn.rollback()
        return jsonify({
            "message": str(e)
        }), 400

    except Exception as e:
        conn.rollback()
        return jsonify({
            "message": f"Gagal menambahkan laporan barang: {str(e)}"
        }), 500

    finally:
        cursor.close()
        conn.close()

# =========================
# DETAIL AJUAN BARANG
# =========================
@ajuan_barang_bp.route('/admin/ajuan-barang/<int:laporan_id>', methods=['GET'])
def get_detail_ajuan_barang(laporan_id):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("""
            SELECT id, user_id, nama, nim, kelas, prodi, tanggal, ruang, no_hp,
                   keterangan, deskripsi, foto, status,
                   created_at, updated_at
            FROM laporan_barang
            WHERE id = %s AND status = 'menunggu'
        """, (laporan_id,))
        row = cursor.fetchone()
        if not row:
            return jsonify({"message": "Data ajuan barang tidak ditemukan"}), 404
        row = format_laporan_barang_row(row)
        return jsonify(row), 200
    finally:
        cursor.close()
        conn.close()

# =========================
# UPDATE LAPORAN BARANG (MOBILE)
# hanya bisa update kalau status masih menunggu
# =========================
@ajuan_barang_bp.route('/laporan-barang/<int:laporan_id>', methods=['PUT'])
def update_laporan_barang(laporan_id):
    user_id = request.form.get('user_id')
    tanggal = request.form.get('tanggal')
    keterangan = request.form.get('keterangan')
    deskripsi = request.form.get('deskripsi', '')
    ruang = request.form.get('ruang', '')
    no_hp = request.form.get('no_hp', '')
    foto = request.files.get('foto')

    if not user_id or not tanggal or not keterangan:
        return jsonify({
            "message": "user_id, tanggal, dan keterangan wajib diisi"
        }), 400

    if keterangan not in ['temuan', 'hilang']:
        return jsonify({
            "message": "keterangan harus 'temuan' atau 'hilang'"
        }), 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT id, foto, status
            FROM laporan_barang
            WHERE id = %s AND user_id = %s
        """, (laporan_id, user_id))

        existing = cursor.fetchone()

        if not existing:
            return jsonify({
                "message": "Data laporan barang tidak ditemukan"
            }), 404

        if existing['status'] != 'menunggu':
            return jsonify({
                "message": "Laporan barang hanya bisa diubah saat status masih menunggu"
            }), 400

        foto_filename = existing['foto']

        if foto and foto.filename:
            if foto_filename:
                old_path = os.path.join(UPLOAD_FOLDER, foto_filename)

                if os.path.exists(old_path):
                    os.remove(old_path)

            foto_filename = save_laporan_barang_photo(foto)

        cursor.execute("""
            UPDATE laporan_barang
            SET tanggal = %s,
                keterangan = %s,
                deskripsi = %s,
                ruang = %s,
                no_hp = %s,
                foto = %s,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = %s AND user_id = %s
        """, (
            tanggal,
            keterangan,
            deskripsi,
            ruang,
            no_hp,
            foto_filename,
            laporan_id,
            user_id
        ))

        conn.commit()

        return jsonify({
            "message": "Laporan barang berhasil diperbarui",
            "foto": foto_filename
        }), 200

    except ValueError as e:
        conn.rollback()
        return jsonify({"message": str(e)}), 400

    except Exception as e:
        conn.rollback()
        return jsonify({
            "message": f"Gagal update laporan barang: {str(e)}"
        }), 500

    finally:
        cursor.close()
        conn.close()

# =========================
# DELETE LAPORAN BARANG (MOBILE)
# hanya bisa hapus kalau status masih menunggu
# =========================
@ajuan_barang_bp.route('/laporan-barang/<int:laporan_id>', methods=['DELETE'])
def delete_laporan_barang(laporan_id):
    user_id = request.args.get('user_id')

    if not user_id:
        return jsonify({
            "message": "user_id wajib dikirim"
        }), 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT id, foto, status
            FROM laporan_barang
            WHERE id = %s AND user_id = %s
        """, (laporan_id, user_id))

        existing = cursor.fetchone()

        if not existing:
            return jsonify({
                "message": "Data laporan barang tidak ditemukan"
            }), 404

        if existing['status'] != 'menunggu':
            return jsonify({
                "message": "Laporan barang hanya bisa dihapus saat status masih menunggu"
            }), 400

        if existing.get('foto'):
            foto_path = os.path.join(UPLOAD_FOLDER, existing['foto'])

            if os.path.exists(foto_path):
                os.remove(foto_path)

        cursor.execute("""
            DELETE FROM laporan_barang
            WHERE id = %s AND user_id = %s
        """, (laporan_id, user_id))

        conn.commit()

        return jsonify({
            "message": "Laporan barang berhasil dihapus"
        }), 200

    except Exception as e:
        conn.rollback()
        return jsonify({
            "message": f"Gagal menghapus laporan barang: {str(e)}"
        }), 500

    finally:
        cursor.close()
        conn.close()

# =========================
# TERIMA AJUAN BARANG
# =========================
@ajuan_barang_bp.route('/admin/ajuan-barang/<int:laporan_id>/terima', methods=['PUT'])
def terima_ajuan_barang(laporan_id):
    data = request.get_json(silent=True) or {}
    admin_id = data.get('admin_id')

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("SELECT id, status FROM laporan_barang WHERE id = %s", (laporan_id,))
        laporan = cursor.fetchone()
        if not laporan:
            return jsonify({"message": "Data ajuan barang tidak ditemukan"}), 404
        if laporan['status'] != 'menunggu':
            return jsonify({"message": "Hanya ajuan barang dengan status menunggu yang bisa diterima"}), 400

        if admin_id:
            cursor.execute("""
                UPDATE laporan_barang
                SET status = 'diterima',
                    diterima_oleh = %s,
                    diterima_pada = CURRENT_TIMESTAMP,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = %s
            """, (admin_id, laporan_id))
        else:
            cursor.execute("""
                UPDATE laporan_barang
                SET status = 'diterima',
                    diterima_pada = CURRENT_TIMESTAMP,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = %s
            """, (laporan_id,))
        conn.commit()
        return jsonify({"message": "Ajuan barang berhasil diterima"}), 200
    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Gagal menerima ajuan barang: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()

# =========================
# PREVIEW FOTO
# =========================
@ajuan_barang_bp.route('/uploads/laporan_barang/<filename>', methods=['GET'])
def get_laporan_barang_upload(filename):
    file_path = os.path.join(UPLOAD_FOLDER, filename)
    if not os.path.exists(file_path):
        return jsonify({"message": f"File tidak ditemukan: {filename}"}), 404
    return send_from_directory(UPLOAD_FOLDER, filename)