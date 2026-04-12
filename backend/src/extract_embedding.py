# Extract embeddings dari dataset yang sudah ditambahkan secara dinamis
import os
import cv2
import numpy as np
from detector import FaceDetector
from aligner import align_face
from embedder import FaceEmbedder

DATASET = "dataset"  # ambil dari folder dataset
OUT_FILE = "data/embeddings.npz"

detector = FaceDetector("models/haarcascade_frontalface_default.xml")
embedder = FaceEmbedder("models/facenet.tflite")

X = []
y = []

# Loop setiap folder user (face_label)
for person in os.listdir(DATASET):
    person_dir = os.path.join(DATASET, person)
    if not os.path.isdir(person_dir):
        continue

    for img_name in os.listdir(person_dir):
        img_path = os.path.join(person_dir, img_name)
        img = cv2.imread(img_path)
        if img is None:
            continue

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        faces = detector.detect(gray)
        if len(faces) == 0:
            continue

        face = align_face(img, faces[0])
        emb = embedder.embed(face)

        X.append(emb)
        y.append(person)

X = np.array(X)
y = np.array(y)

np.savez(OUT_FILE, X=X, y=y)
print(f"Saved {len(X)} embeddings to {OUT_FILE}")