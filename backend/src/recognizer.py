# Pengenalan wajah menggunakan SVM 
import numpy as np # Menghitung jarak antar embedding
import joblib # Memuat model .pkl

# Kelas untuk mengenali wajah menggunakan model SVM dan centroid
class FaceRecognizer:
    # Konstruktor untuk inisialisasi pengenal wajah
    def __init__(self, model_path, threshold=0.5):
        data = joblib.load(model_path) # Memuat model SVM dan centroid
        self.svm = data["svm"] # Model SVM untuk klasifikasi wajah
        self.centroids = data["centroids"] # Embedding per label
        self.threshold = threshold # Ambang jarak untuk mengenali wajah

    # Metode untuk memprediksi label wajah berdasarkan embedding
    def predict(self, embedding): 
        label = self.svm.predict([embedding])[0] # Prediksi label menggunakan SVM
        centroid = self.centroids[label] # Dapatkan centroid untuk label yang diprediksi
        dist = np.linalg.norm(embedding - centroid) # Hitung jarak antara embedding dan centroid
        print(dist)
        if dist > self.threshold: # Jika jarak di atas ambang, kembalikan label
            return label

        return "Unknown" # Jika jarak di bawah ambang, kembalikan "Unknown"