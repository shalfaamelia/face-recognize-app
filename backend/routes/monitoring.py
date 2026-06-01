from flask import Blueprint, request, jsonify
from datetime import datetime
from db import get_db_connection

monitoring_bp = Blueprint('monitoring', __name__)


def append_date_filter(query, params, column):
    start_date = request.args.get('startDate')
    end_date = request.args.get('endDate')

    if start_date:
        query += f" AND DATE({column}) >= %s"
        params.append(start_date)

    if end_date:
        query += f" AND DATE({column}) <= %s"
        params.append(end_date)

    return query, params


# ===============================
# GET ALL MONITORING LOGS
# type=masuk      -> log_masuk
# type=terlambat  -> log_terlambat
# ===============================
@monitoring_bp.route('/monitoring', methods=['GET'])
def get_monitoring():
    tipe = request.args.get('type', 'masuk')

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        if tipe == 'terlambat':
            query = """
                SELECT 
                    id, 
                    kode, 
                    nama, 
                    nim, 
                    prodi, 
                    kelas, 
                    masuk,
                    terlambat_menit
                FROM log_terlambat
                WHERE 1=1
            """
        else:
            query = """
                SELECT 
                    id, 
                    kode, 
                    nama, 
                    nim, 
                    prodi, 
                    kelas, 
                    masuk
                FROM log_masuk
                WHERE 1=1
            """

        params = []
        query, params = append_date_filter(query, params, 'masuk')
        query += " ORDER BY masuk DESC"

        cursor.execute(query, tuple(params))
        logs = cursor.fetchall()

        for log in logs:
            if log.get('masuk'):
                log['masuk'] = log['masuk'].strftime('%Y/%m/%d %H:%M:%S')

            if tipe == 'terlambat':
                menit = log.get('terlambat_menit')
                log['terlambat'] = f"{menit} menit" if menit is not None else "-"

    except Exception as e:
        return jsonify({"message": f"Failed to fetch logs: {str(e)}"}), 500

    finally:
        cursor.close()
        conn.close()

    return jsonify(logs)


# ===============================
# GET ALL LOGS ALIAS UNTUK LAPORAN AKSES LAB
# ===============================
@monitoring_bp.route('/laporan/akses', methods=['GET'])
def get_laporan_akses_lab():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        query = """
            SELECT id, kode, nama, nim, prodi, kelas, masuk, terlambat_menit
            FROM (
                SELECT id, kode, nama, nim, prodi, kelas, masuk, NULL AS terlambat_menit
                FROM log_masuk
                UNION ALL
                SELECT id, kode, nama, nim, prodi, kelas, masuk, terlambat_menit
                FROM log_terlambat
            ) AS combined
            WHERE 1=1
        """

        params = []
        query, params = append_date_filter(query, params, 'masuk')
        query += " ORDER BY masuk DESC"

        cursor.execute(query, tuple(params))
        logs = cursor.fetchall()

        for log in logs:
            if log.get('masuk'):
                log['masuk'] = log['masuk'].strftime('%Y/%m/%d %H:%M:%S')

            menit = log.get('terlambat_menit')
            log['terlambat'] = f"{menit} menit" if menit is not None else "-"

    except Exception as e:
        return jsonify({"message": f"Failed to fetch laporan akses logs: {str(e)}"}), 500

    finally:
        cursor.close()
        conn.close()

    return jsonify(logs)


@monitoring_bp.route('/monitoring_user', methods=['GET'])
def monitoring_user_query():
    user_id = request.args.get('user_id', type=int)

    if not user_id:
        return jsonify({"message": "user_id required"}), 400

    return get_user_monitoring(user_id)


# ===============================
# INTERNAL FUNCTION: GET LOGS BY USER_ID
# ===============================
def get_user_monitoring(user_id):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT lm.id, lm.kode, lm.nama, lm.nim, lm.prodi, lm.kelas, lm.masuk
            FROM log_masuk lm
            INNER JOIN users u ON lm.kode = u.kode
            WHERE u.id = %s
            ORDER BY lm.masuk DESC
        """, (user_id,))

        logs = cursor.fetchall()

        for log in logs:
            if log.get('masuk'):
                log['masuk'] = log['masuk'].strftime('%Y/%m/%d %H:%M:%S')

    except Exception as e:
        return jsonify({"message": f"Failed to fetch logs: {str(e)}"}), 500

    finally:
        cursor.close()
        conn.close()

    return jsonify(logs)


# ===============================
# LOG USER ATTENDANCE
# ===============================
@monitoring_bp.route('/log_attendance', methods=['POST'])
def log_attendance():
    data = request.get_json()
    user_id = data.get('user_id')
    timestamp = data.get('timestamp', datetime.now().isoformat())

    if not user_id:
        return jsonify({"message": "user_id is required"}), 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT id, kode, nama, nim, prodi, kelas
            FROM users
            WHERE id=%s
        """, (user_id,))

        user = cursor.fetchone()

        if not user:
            return jsonify({"message": "User not found"}), 404

        cursor.execute("""
            INSERT INTO log_masuk (kode, nama, nim, prodi, kelas, masuk)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (
            user['kode'],
            user['nama'],
            user['nim'],
            user['prodi'],
            user['kelas'],
            timestamp
        ))

        conn.commit()

    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Failed to log attendance: {str(e)}"}), 500

    finally:
        cursor.close()
        conn.close()

    return jsonify({"message": f"Attendance logged for {user['nama']}"}), 201