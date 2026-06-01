from flask import Blueprint, request, jsonify, send_from_directory
from werkzeug.utils import secure_filename
import os
from db import get_db_connection

user_faces_bp = Blueprint('user_faces', __name__)

UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), '..', 'dataset')
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@user_faces_bp.route('/user_faces/upload/<int:user_id>', methods=['POST'])
def upload_user_face(user_id):
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
            file_path = os.path.join(user_folder, filename)

            file.save(file_path)

            cursor.execute(
                "INSERT INTO user_faces (user_id, image_path, image_name) VALUES (%s,%s,%s)",
                (user_id, filename, filename)
            )

            uploaded_files.append(filename)

    conn.commit()
    cursor.close()
    conn.close()

    return jsonify({
        "message": "Files uploaded successfully",
        "files": uploaded_files
    }), 201

@user_faces_bp.route('/uploads/<face_label>/<filename>')
def uploaded_file(face_label, filename):
    folder = os.path.join(UPLOAD_FOLDER, face_label)
    file_path = os.path.join(folder, filename)

    if not os.path.exists(file_path):
        return jsonify({"message": f"File not found: {file_path}"}), 404

    return send_from_directory(folder, filename)