import os
import cv2
import requests
import time
from datetime import datetime
from src.detector import FaceDetector
from src.aligner import align_face
from src.embedder import FaceEmbedder
from src.recognizer import FaceRecognizer

# Load semua model
detector = FaceDetector("models/haarcascade_frontalface_default.xml")
embedder = FaceEmbedder("models/facenet.tflite")
recognizer = FaceRecognizer("models/face_model.pkl")

# Backend config
BACKEND_URL = "http://localhost:5000/log_attendance"
USERS_API = "http://localhost:5000/api/users"
LOG_COOLDOWN = 5
last_logged = {}

# =========================
# Ambil info user dari backend
# =========================
def get_user_info(face_label):
    try:
        res = requests.get(f"{USERS_API}?face_label={face_label}", timeout=2)
        if res.status_code == 200:
            users = res.json()
            if len(users) > 0:
                return users[0]  # ambil user pertama
    except requests.exceptions.RequestException as e:
        print(f"Error fetching user info: {e}")
    return None

# =========================
# Log attendance ke backend
# =========================
def log_to_backend(face_label):
    current_time = time.time()
    if face_label in last_logged and current_time - last_logged[face_label] < LOG_COOLDOWN:
        return

    user = get_user_info(face_label)
    if not user:
        print(f"User with face_label '{face_label}' not found")
        return

    payload = {
        "user_id": user['id'],
        "name": user['nama'],
        "timestamp": datetime.now().isoformat()
    }

    try:
        res = requests.post(BACKEND_URL, json=payload, timeout=2)
        if res.status_code == 201:
            print(f"Attendance logged for {user['nama']}")
            last_logged[face_label] = current_time
        else:
            print(f"Failed to log attendance: {res.text}")
    except requests.exceptions.RequestException as e:
        print(f"Error connecting to backend: {e}")

# =========================
# Fungsi untuk memproses frame (real-time / test folder)
# =========================
def process_frame(frame):
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    faces = detector.detect(gray)

    for (x, y, w, h) in faces:
        try:
            face = align_face(frame, (x, y, w, h))
            emb = embedder.embed(face)
            predicted_label = recognizer.predict(emb)  # face_label
            user = get_user_info(predicted_label)
            display_name = user['nama'] if user else "Unknown"

            # Tampilkan di frame
            cv2.rectangle(frame, (x, y), (x+w, y+h), (0, 255, 0), 2)
            cv2.putText(frame, display_name, (x, y-10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)

            # Log ke backend
            if user:
                log_to_backend(predicted_label)

        except Exception as e:
            print(f"Error processing face: {e}")
            continue

    return frame

# =========================
# Inisialisasi webcam
# =========================
cap = cv2.VideoCapture(0)

if cap.isOpened():
    print("Webcam detected. Starting real-time recognition...")
    while True:
        ret, frame = cap.read()
        if not ret:
            print("Failed to grab frame")
            break

        frame = process_frame(frame)

        cv2.imshow("Face Recognition (Webcam)", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()

else:
    print("Webcam not found. Reverting to test folder...")
    test_dir = "data/test"
    if os.path.exists(test_dir):
        for filename in os.listdir(test_dir):
            if not filename.lower().endswith((".jpg", ".jpeg", ".png")):
                continue

            img_path = os.path.join(test_dir, filename)
            frame = cv2.imread(img_path)
            if frame is None:
                continue

            frame = process_frame(frame)

            cv2.imshow("Face Recognition (Test Folder)", frame)
            print(f"Processed {filename}. Press any key for next image, 'q' to quit.")
            key = cv2.waitKey(0)
            if key == ord('q'):
                break
    else:
        print(f"Test directory '{test_dir}' not found.")

cv2.destroyAllWindows()