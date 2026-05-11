from flask import Blueprint, request, jsonify, send_from_directory
from werkzeug.utils import secure_filename
import os
import shutil
import subprocess
from db import get_db_connection

user_bp = Blueprint('users', __name__)

UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), '..', 'dataset')
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# ===============================
# BANTUAN: Update embeddings & retrain SVM otomatis
# ===============================
def update_embeddings_and_svm():
    try:
        # Jalankan extract_embedding.py
        subprocess.run(['python', 'extract_embedding.py'], check=True)
        # Jalankan training_svm.py
        subprocess.run(['python', 'training_svm.py'], check=True)
        print("Embeddings and SVM updated successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error updating embeddings/SVM: {e}")

# ===============================
# GET USERS + INCLUDE USER FACES
# ===============================
@user_bp.route('/users', methods=['GET'])
def get_users():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT id, kode, nama, face_label, role,
               nim, nip, prodi, kelas,
               email, status
        FROM users
        ORDER BY id DESC
    """)
    users = cursor.fetchall()

    for user in users:
        cursor.execute("SELECT image_name FROM user_faces WHERE user_id=%s", (user['id'],))
        faces = cursor.fetchall()
        user['user_faces'] = faces

    cursor.close()
    conn.close()
    return jsonify(users)

# ===============================
# GENERATE KODE OTOMATIS
# ===============================
def generate_user_code(role, cursor):
    prefix_map = {
        'kepala_lab': 'KL',
        'teknisi': 'TK',
        'sarpras': 'SP',
        'mahasiswa': 'MH'
    }
    prefix = prefix_map.get(role)
    if not prefix:
        raise ValueError("Role tidak valid untuk generate kode")

    cursor.execute("SELECT kode FROM users WHERE role=%s ORDER BY id DESC LIMIT 1", (role,))
    last = cursor.fetchone()
    if last and last[0]:
        last_num = int(last[0][2:])
        new_num = last_num + 1
    else:
        new_num = 1

    kode = f"{prefix}{str(new_num).zfill(4)}"
    return kode

# ===============================
# API Generate kode berdasarkan role
# ===============================
@user_bp.route('/users/generate_kode', methods=['GET'])
def api_generate_kode():
    role = request.args.get('role')
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        kode = generate_user_code(role, cursor)
    finally:
        cursor.close()
        conn.close()
    return jsonify({"kode": kode})

# ===============================
# Fungsi bantu generate face_label otomatis
# ===============================
def generate_face_label(nama):
    if not nama:
        return "user"
    label = nama.strip().lower().replace(" ", "_")
    return label

# ===============================
# CREATE USER
# ===============================
@user_bp.route('/users', methods=['POST'])
def create_user():
    if request.content_type.startswith('multipart/form-data'):
        nama = request.form.get('nama')
        role = request.form.get('role')
        nim = request.form.get('nim')
        nip = request.form.get('nip')
        prodi = request.form.get('prodi')
        kelas = request.form.get('kelas')
        email = request.form.get('email')
        password = request.form.get('password')
        status = request.form.get('status', 'aktif')
        files = request.files.getlist('files')
    else:
        data = request.get_json()
        nama = data.get('nama')
        role = data.get('role')
        nim = data.get('nim')
        nip = data.get('nip')
        prodi = data.get('prodi')
        kelas = data.get('kelas')
        email = data.get('email')
        password = data.get('password')
        status = data.get('status', 'aktif')
        files = []

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        if role != 'mahasiswa' and email:
            cursor.execute("SELECT id FROM users WHERE email=%s", (email,))
            if cursor.fetchone():
                return jsonify({"message": f"Email '{email}' sudah terdaftar"}), 400

        kode = generate_user_code(role, cursor)
        face_label = generate_face_label(nama)

        sql_user = """
            INSERT INTO users
            (kode, nama, face_label, role, nim, nip, prodi, kelas, email, password, status)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
        """

        if role == 'mahasiswa':
            email = None
            password = None

        cursor.execute(sql_user, (
            kode, nama, face_label, role,
            nim, nip, prodi, kelas, email, password, status
        ))
        user_id = cursor.lastrowid
        conn.commit()

        if files:
            user_folder = os.path.join(UPLOAD_FOLDER, face_label)
            os.makedirs(user_folder, exist_ok=True)
            for file in files:
                if file and allowed_file(file.filename):
                    filename = secure_filename(file.filename)
                    file_path = os.path.join(user_folder, filename)
                    file.save(file_path)
                    cursor.execute(
                        "INSERT INTO user_faces (user_id, image_path, image_name) VALUES (%s,%s,%s)",
                        (user_id, file_path, filename)
                    )
            conn.commit()

        # ===============================
        # Update embeddings & retrain SVM otomatis
        # ===============================
        update_embeddings_and_svm()

    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Gagal membuat user: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()

    return jsonify({
        "message": "User berhasil dibuat",
        "user_id": user_id,
        "kode": kode,
        "face_label": face_label,
        "files_uploaded": [f.filename for f in files] if files else []
    }), 201

# ===============================
# UPLOAD USER FACES
# ===============================
@user_bp.route('/users/<int:user_id>/upload_faces', methods=['POST'])
def upload_user_faces(user_id):
    if 'files' not in request.files:
        return jsonify({"message": "No files part"}), 400

    files = request.files.getlist('files')
    if not files:
        return jsonify({"message": "No selected files"}), 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT face_label FROM users WHERE id=%s", (user_id,))
    user = cursor.fetchone()
    if not user:
        cursor.close()
        conn.close()
        return jsonify({"message": "User not found"}), 404

    face_label = user['face_label']
    user_folder = os.path.join(UPLOAD_FOLDER, face_label)
    os.makedirs(user_folder, exist_ok=True)

    uploaded_files = []
    for file in files:
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            file.save(os.path.join(user_folder, filename))
            cursor.execute(
                "INSERT INTO user_faces (user_id, image_path, image_name) VALUES (%s, %s, %s)",
                (user_id, filename, filename)
            )
            uploaded_files.append(filename)

    conn.commit()
    cursor.close()
    conn.close()

    # ===============================
    # Update embeddings & retrain SVM otomatis
    # ===============================
    update_embeddings_and_svm()

    return jsonify({"message": "Files uploaded successfully", "files": uploaded_files}), 201

# ===============================
# ROUTE UNTUK PREVIEW FILE
# ===============================
@user_bp.route('/uploads/<face_label>/<filename>')
def uploaded_file(face_label, filename):
    folder = os.path.join(UPLOAD_FOLDER, face_label)
    file_path = os.path.join(folder, filename)
    print("Looking for file:", file_path)
    if not os.path.exists(file_path):
        return jsonify({"message": f"File not found: {file_path}"}), 404
    return send_from_directory(folder, filename)

# ===============================
# UPDATE USER
# ===============================
@user_bp.route('/users/<int:user_id>', methods=['PUT'])
def update_user(user_id):
    data = request.get_json()
    nama = data.get('nama')
    role = data.get('role')
    nim = data.get('nim')
    nip = data.get('nip')
    prodi = data.get('prodi')
    kelas = data.get('kelas')
    email = data.get('email')
    password = data.get('password')
    status = data.get('status')

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("SELECT * FROM users WHERE id=%s", (user_id,))
        user = cursor.fetchone()
        if not user:
            return jsonify({"message": "User tidak ditemukan"}), 404

        if role is None:
            role = user.get('role')
        if nim is None:
            nim = user.get('nim')
        if nip is None:
            nip = user.get('nip')
        if prodi is None:
            prodi = user.get('prodi')
        if kelas is None:
            kelas = user.get('kelas')
        if email is None:
            email = user.get('email')
        if password is None:
            password = user.get('password')
        if status is None:
            status = user.get('status')

        if role == 'mahasiswa':
            email = None
            password = None

        sql = """
            UPDATE users SET
            nama=%s, role=%s, nim=%s, nip=%s,
            prodi=%s, kelas=%s, email=%s, password=%s, status=%s
            WHERE id=%s
        """
        cursor.execute(sql, (
            nama, role, nim, nip,
            prodi, kelas, email, password, status,
            user_id
        ))
        conn.commit()

        cursor.execute(
            "SELECT id, nama, role, nim, prodi, kelas, email FROM users WHERE id=%s",
            (user_id,)
        )
        updated_user = cursor.fetchone()
    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Gagal update user: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()

    return jsonify({
        'id': updated_user['id'],
        'nama': updated_user['nama'],
        'role': updated_user['role'],
        'nim': updated_user['nim'],
        'prodi': updated_user['prodi'],
        'kelas': updated_user['kelas'],
        'email': updated_user['email'],
    }), 200

# ===============================
# DELETE USER
# ===============================
@user_bp.route('/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT face_label FROM users WHERE id=%s", (user_id,))
        user = cursor.fetchone()
        if not user:
            return jsonify({"message": "User tidak ditemukan"}), 404
        face_label = user[0]

        cursor.execute("DELETE FROM user_faces WHERE user_id=%s", (user_id,))

        folder = os.path.join(UPLOAD_FOLDER, face_label)
        if os.path.exists(folder) and os.path.isdir(folder):
            try:
                shutil.rmtree(folder, ignore_errors=True)
            except Exception as e:
                print(f"Gagal hapus folder {folder}: {e}")

        cursor.execute("DELETE FROM users WHERE id=%s", (user_id,))
        conn.commit()
    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Gagal hapus user: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()

    return jsonify({"message": "User berhasil dihapus"}), 200