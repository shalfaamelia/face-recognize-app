from datetime import datetime, time
import re
import zipfile
from xml.etree import ElementTree
from flask import Blueprint, request, jsonify
from db import get_db_connection
from utils.auth_guard import auth_required

jadwal_bp = Blueprint('jadwal', __name__)

REQUIRED_IMPORT_FIELDS = ['nama', 'dosen', 'kelas', 'hari', 'jam_mulai', 'jam_selesai']

HEADER_ALIASES = {
    'kode': 'kode',
    'code': 'kode',
    'nama': 'nama',
    'nama mata kuliah': 'nama',
    'mata kuliah': 'nama',
    'matakuliah': 'nama',
    'praktikum': 'nama',
    'dosen': 'dosen',
    'kelas': 'kelas',
    'hari': 'hari',
    'jam mulai': 'jam_mulai',
    'jam_mulai': 'jam_mulai',
    'mulai': 'jam_mulai',
    'jam selesai': 'jam_selesai',
    'jam_selesai': 'jam_selesai',
    'selesai': 'jam_selesai',
}

def normalize_header(value):
    return str(value or '').strip().lower().replace('\n', ' ')

def normalize_time_value(value):
    if value is None:
        return None

    if isinstance(value, (int, float)) and 0 <= value < 1:
        total_minutes = round(value * 24 * 60)
        hour = total_minutes // 60
        minute = total_minutes % 60
        return f"{hour:02d}:{minute:02d}"

    if isinstance(value, time):
        return value.strftime('%H:%M')

    if isinstance(value, datetime):
        return value.strftime('%H:%M')

    text = str(value).strip()
    if not text:
        return None

    for fmt in ('%H:%M', '%H:%M:%S'):
        try:
            return datetime.strptime(text, fmt).strftime('%H:%M')
        except ValueError:
            pass

    return text

def column_index(cell_reference):
    letters = ''.join(re.findall(r'[A-Z]+', cell_reference.upper()))
    index = 0
    for char in letters:
        index = index * 26 + (ord(char) - ord('A') + 1)
    return index - 1

def read_xlsx_rows_with_stdlib(stream):
    stream.seek(0)
    namespaces = {
        'main': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main',
        'rel': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
    }

    with zipfile.ZipFile(stream) as archive:
        shared_strings = []
        if 'xl/sharedStrings.xml' in archive.namelist():
            shared_tree = ElementTree.fromstring(archive.read('xl/sharedStrings.xml'))
            for item in shared_tree.findall('main:si', namespaces):
                texts = [node.text or '' for node in item.findall('.//main:t', namespaces)]
                shared_strings.append(''.join(texts))

        sheet_path = 'xl/worksheets/sheet1.xml'
        sheet_tree = ElementTree.fromstring(archive.read(sheet_path))
        parsed_rows = []

        for row in sheet_tree.findall('.//main:row', namespaces):
            values = []
            for cell in row.findall('main:c', namespaces):
                cell_ref = cell.attrib.get('r', '')
                index = column_index(cell_ref)
                while len(values) <= index:
                    values.append(None)

                cell_type = cell.attrib.get('t')
                value_node = cell.find('main:v', namespaces)
                inline_node = cell.find('main:is/main:t', namespaces)

                if cell_type == 's' and value_node is not None:
                    value = shared_strings[int(value_node.text)]
                elif cell_type == 'inlineStr' and inline_node is not None:
                    value = inline_node.text
                elif value_node is not None:
                    raw_value = value_node.text
                    try:
                        value = float(raw_value)
                        if value.is_integer():
                            value = int(value)
                    except (TypeError, ValueError):
                        value = raw_value
                else:
                    value = None

                values[index] = value

            parsed_rows.append(values)

    return parsed_rows

def read_jadwal_excel(file):
    try:
        from openpyxl import load_workbook
        workbook = load_workbook(file.stream, data_only=True)
        sheet = workbook.active
        rows = list(sheet.iter_rows(values_only=True))
    except ImportError:
        rows = read_xlsx_rows_with_stdlib(file.stream)

    if not rows:
        raise ValueError("File Excel kosong")

    header_map = {}
    for index, header in enumerate(rows[0]):
        field = HEADER_ALIASES.get(normalize_header(header))
        if field:
            header_map[field] = index

    missing_headers = [field for field in REQUIRED_IMPORT_FIELDS if field not in header_map]
    if missing_headers:
        raise ValueError(f"Kolom wajib belum ada: {', '.join(missing_headers)}")

    jadwal_rows = []
    for row_number, row in enumerate(rows[1:], start=2):
        if not row or all(value is None or str(value).strip() == '' for value in row):
            continue

        item = {}
        for field, index in header_map.items():
            value = row[index] if index < len(row) else None
            item[field] = normalize_time_value(value) if field in ['jam_mulai', 'jam_selesai'] else str(value or '').strip()

        missing_values = [field for field in REQUIRED_IMPORT_FIELDS if not item.get(field)]
        if missing_values:
            raise ValueError(f"Baris {row_number}: field wajib kosong ({', '.join(missing_values)})")

        if item['jam_mulai'] >= item['jam_selesai']:
            raise ValueError(f"Baris {row_number}: jam_mulai harus lebih kecil dari jam_selesai")

        jadwal_rows.append((
            item.get('kode') or None,
            item['nama'],
            item['dosen'],
            item['kelas'],
            item['hari'],
            item['jam_mulai'],
            item['jam_selesai'],
        ))

    if not jadwal_rows:
        raise ValueError("Tidak ada data jadwal yang bisa diimport")

    return jadwal_rows

# ===============================
# GET JADWAL PRAKTIKUM
# ===============================
@jadwal_bp.route('/', methods=['GET'])
@auth_required(['kepala_lab', 'teknisi'])
def get_jadwal():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT id, kode, nama, dosen, kelas, hari,
               TIME_FORMAT(jam_mulai, '%H:%i') AS jam_mulai,
               TIME_FORMAT(jam_selesai, '%H:%i') AS jam_selesai
        FROM jadwal_praktikum
        ORDER BY id DESC
    """)
    jadwal = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify(jadwal)

# ===============================
# CREATE JADWAL PRAKTIKUM
# ===============================
@jadwal_bp.route('/', methods=['POST'])
@auth_required(['kepala_lab', 'teknisi'])
def create_jadwal():
    data = request.get_json()
    kode = data.get('kode')  # input manual
    nama = data.get('nama')
    dosen = data.get('dosen')
    kelas = data.get('kelas')
    hari = data.get('hari')
    jam_mulai = data.get('jam_mulai')
    jam_selesai = data.get('jam_selesai')

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("""
            INSERT INTO jadwal_praktikum
            (kode, nama, dosen, kelas, hari, jam_mulai, jam_selesai)
            VALUES (%s,%s,%s,%s,%s,%s,%s)
        """, (kode, nama, dosen, kelas, hari, jam_mulai, jam_selesai))
        jadwal_id = cursor.lastrowid
        conn.commit()
    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Gagal membuat jadwal: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()

    return jsonify({"message": "Jadwal berhasil dibuat", "id": jadwal_id}), 201

# ===============================
# IMPORT JADWAL PRAKTIKUM DARI EXCEL
# ===============================
@jadwal_bp.route('/import', methods=['POST'])
@auth_required(['kepala_lab', 'teknisi'])
def import_jadwal():
    file = request.files.get('file')

    if not file or not file.filename:
        return jsonify({"message": "File Excel wajib diupload"}), 400

    if not file.filename.lower().endswith('.xlsx'):
        return jsonify({"message": "Format file harus .xlsx"}), 400

    try:
        rows = read_jadwal_excel(file)
    except ValueError as e:
        return jsonify({"message": str(e)}), 400

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.executemany("""
            INSERT INTO jadwal_praktikum
            (kode, nama, dosen, kelas, hari, jam_mulai, jam_selesai)
            VALUES (%s,%s,%s,%s,%s,%s,%s)
        """, rows)
        conn.commit()
    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Gagal import jadwal: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()

    return jsonify({
        "message": f"Berhasil import {len(rows)} jadwal praktikum",
        "imported": len(rows)
    }), 201

# ===============================
# UPDATE JADWAL PRAKTIKUM
# ===============================
@jadwal_bp.route('/<int:jadwal_id>', methods=['PUT'])
@auth_required(['kepala_lab', 'teknisi'])
def update_jadwal(jadwal_id):
    data = request.get_json()
    kode = data.get('kode')
    nama = data.get('nama')
    dosen = data.get('dosen')
    kelas = data.get('kelas')
    hari = data.get('hari')
    jam_mulai = data.get('jam_mulai')
    jam_selesai = data.get('jam_selesai')

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT * FROM jadwal_praktikum WHERE id=%s", (jadwal_id,))
        if not cursor.fetchone():
            return jsonify({"message": "Jadwal tidak ditemukan"}), 404

        cursor.execute("""
            UPDATE jadwal_praktikum SET
            kode=%s, nama=%s, dosen=%s, kelas=%s, hari=%s, jam_mulai=%s, jam_selesai=%s
            WHERE id=%s
        """, (kode, nama, dosen, kelas, hari, jam_mulai, jam_selesai, jadwal_id))
        conn.commit()
    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Gagal update jadwal: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()

    return jsonify({"message": "Jadwal berhasil diupdate"}), 200

# ===============================
# DELETE JADWAL PRAKTIKUM
# ===============================
@jadwal_bp.route('/<int:jadwal_id>', methods=['DELETE'])
@auth_required(['kepala_lab', 'teknisi'])
def delete_jadwal(jadwal_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT * FROM jadwal_praktikum WHERE id=%s", (jadwal_id,))
        if not cursor.fetchone():
            return jsonify({"message": "Jadwal tidak ditemukan"}), 404

        cursor.execute("DELETE FROM jadwal_praktikum WHERE id=%s", (jadwal_id,))
        conn.commit()
    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Gagal hapus jadwal: {str(e)}"}), 500
    finally:
        cursor.close()
        conn.close()

    return jsonify({"message": "Jadwal berhasil dihapus"}), 200
