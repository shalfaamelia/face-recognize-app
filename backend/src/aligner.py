# Align wajah menggunakan OpenCV untuk memotong dan mengubah ukuran wajah
import cv2

# Fungsi untuk memotong dan mengubah ukuran wajah dari frame
def align_face(frame, box, size=160): # size default 160x160 FaceNet input
    # Memotong wajah dari frame menggunakan bounding box
    x, y, w, h = box
    # Memotong wajah dari frame
    face = frame[y:y+h, x:x+w]
    # Mengubah ukuran wajah menjadi size x size
    return cv2.resize(face, (size, size))
