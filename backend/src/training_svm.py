# Klasifikasi wajah menggunakan SVM 
import numpy as np # Memuat embeddings dan label
from sklearn.svm import SVC # Klasifikasi SVM
import joblib # Menyimpan model SVM

# Muat embeddings dan label dari file .npz
data = np.load("data/embeddings.npz")
X, y = data["X"], data["y"]

# Latih model SVM dengan kernel linear
svm = SVC(kernel="linear", probability=True)
svm.fit(X, y)

# Hitung centroid untuk setiap kelas
centroids = {}
for label in set(y):
    centroids[label] = X[y == label].mean(axis=0)

# Simpan model SVM dan centroid ke file menggunakan joblib
joblib.dump(
    {"svm": svm, "centroids": centroids},
    "models/face_model.pkl"
)

print("SVM + centroids saved.")