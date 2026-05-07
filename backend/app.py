from flask import Flask
from flask_cors import CORS

from routes.monitoring import monitoring_bp
from routes.user import user_bp
from routes.user_faces import user_faces_bp
from routes.jadwal import jadwal_bp
from routes.login import login_bp
from routes.peminjaman import peminjaman_bp
from routes.laporan_barang import laporan_barang_bp
            
app = Flask(__name__)
CORS(app)

# Mobile login tanpa prefix
app.register_blueprint(login_bp)

# Tambahkan /api prefix supaya endpoint sesuai Flutter
app.register_blueprint(monitoring_bp, url_prefix='/api')
app.register_blueprint(peminjaman_bp, url_prefix='/api')
app.register_blueprint(laporan_barang_bp, url_prefix='/api')
app.register_blueprint(user_bp, url_prefix='/api')
app.register_blueprint(user_faces_bp, url_prefix='/api/user_faces') 
app.register_blueprint(jadwal_bp, url_prefix='/api/jadwal')

print("Registered routes:")
for rule in app.url_map.iter_rules():
    print(rule)

@app.route('/')
def index():
    return "Backend Aktif 🚀"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)