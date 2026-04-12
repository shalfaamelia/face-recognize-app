# Deteksi wajah menggunakan Haar Cascade 
import cv2

class FaceDetector:
    # Konstruktor untuk inisialisasi detektor Haar Cascade
    def __init__(self, model_path):
        self.detector = cv2.CascadeClassifier(model_path)

    # Metode untuk mendeteksi wajah dalam frame grayscale
    def detect(self, gray):
        return self.detector.detectMultiScale(
            gray,
            scaleFactor=1.2, # Semakin kecil nilai, semakin akurat
            minNeighbors=5,  # Semakin tinggi nilai, semakin ketat kriteria wajah
            minSize=(80, 80) # Ukuran minimum wajah yang dideteksi
        )
