# Ekstraksi embedding wajah menggunakan model TensorFlow Lite
import numpy as np
import tensorflow.lite as tflite

# Kelas untuk mengekstraksi embedding wajah menggunakan model TensorFlow Lite
class FaceEmbedder:
    # Konstruktor untuk objek baru
    def __init__(self, model_path):
        self.interpreter = tflite.Interpreter(model_path) # Memuat model TensorFlow Lite
        self.interpreter.allocate_tensors() # Mengalokasikan tensor
        self.input = self.interpreter.get_input_details()[0]["index"] # Mendapatkan indeks input
        self.output = self.interpreter.get_output_details()[0]["index"] # Mendapatkan indeks output

    # Metode untuk mengekstraksi embedding dari wajah yang diberikan
    def embed(self, face):
        face = face.astype("float32") / 255.0 # Normalisasi piksel wajah
        face = np.expand_dims(face, axis=0) # Menambahkan dimensi batch
        self.interpreter.set_tensor(self.input, face) # Menetapkan tensor input
        self.interpreter.invoke() # Menjalankan inferensi CNN
        emb = self.interpreter.get_tensor(self.output)[0] # Mendapatkan embedding dari output
        return emb / np.linalg.norm(emb) # Mengembalikan embedding yang dinormalisasi
