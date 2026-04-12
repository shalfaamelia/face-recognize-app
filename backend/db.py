import mysql.connector

DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': '',
    'database': 'db_face_recognition'
}

def get_db_connection():
    return mysql.connector.connect(**DB_CONFIG)