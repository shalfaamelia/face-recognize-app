from flask import Blueprint, request, jsonify
from db import get_db_connection

laporan_barang_bp = Blueprint('laporan_barang', __name__)

def format_laporan_barang_row(row):
    if row.get('tanggal'):
        row['tanggal'] = row['tanggal'].isoformat()
    if row.get('diterima_pada'):
        row['diterima_pada'] = row['diterima_pada'].isoformat()
    return row

def append_date_filter(query, params):
    start_date = request.args.get('startDate')
    end_date = request.args.get('endDate')
    if start_date:
        query += " AND tanggal >= %s"
        params.append(start_date)
    if end_date:
        query += " AND tanggal <= %s"
        params.append(end_date)
    return query, params

# =========================
# GET LAPORAN BARANG FINAL
# hanya status diterima
# =========================
@laporan_barang_bp.route('/laporan/barang', methods=['GET'])
def get_laporan_barang():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        query = """
            SELECT id, user_id, nama, nim, kelas, prodi, tanggal,
                   keterangan, deskripsi, foto, status,
                   diterima_oleh, diterima_pada,
                   created_at, updated_at
            FROM laporan_barang
            WHERE status = 'diterima'
        """
        params = []
        query, params = append_date_filter(query, params)
        query += " ORDER BY diterima_pada DESC, tanggal DESC, id DESC"
        cursor.execute(query, tuple(params))
        rows = cursor.fetchall()
        rows = [format_laporan_barang_row(row) for row in rows]
        return jsonify(rows), 200
    finally:
        cursor.close()
        conn.close()

# =========================
# DETAIL LAPORAN BARANG FINAL
# =========================
@laporan_barang_bp.route('/laporan/barang/<int:laporan_id>', methods=['GET'])
def get_detail_laporan_barang(laporan_id):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("""
            SELECT id, user_id, nama, nim, kelas, prodi, tanggal,
                   keterangan, deskripsi, foto, status,
                   diterima_oleh, diterima_pada,
                   created_at, updated_at
            FROM laporan_barang
            WHERE id = %s
              AND status = 'diterima'
        """, (laporan_id,))
        row = cursor.fetchone()
        if not row:
            return jsonify({"message": "Data laporan barang tidak ditemukan"}), 404
        row = format_laporan_barang_row(row)
        return jsonify(row), 200
    finally:
        cursor.close()
        conn.close()