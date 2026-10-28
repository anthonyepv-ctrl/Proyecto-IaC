
from pathlib import Path

from common.db import get_conn
from common.http import response


def ejecutar_sql(cursor, contenido):
    # Ejecutar cada sentencia SQL por separado.
    for sentencia in contenido.split(";"):
        sentencia = sentencia.strip()

        if sentencia:
            cursor.execute(sentencia)


def lambda_handler(event, context):
    conn = None
    cursor = None

    try:
        carpeta = Path(__file__).resolve().parent

        schema_path = carpeta / "schema.sql"
        seed_path = carpeta / "seed.sql"

        if not schema_path.exists() or not seed_path.exists():
            return response(500, {
                "error": "No se encontraron schema.sql o seed.sql"
            })

        schema_sql = schema_path.read_text(encoding="utf-8")
        seed_sql = seed_path.read_text(encoding="utf-8")

        conn = get_conn()
        cursor = conn.cursor()
        conn.autocommit = False

        ejecutar_sql(cursor, schema_sql)
        ejecutar_sql(cursor, seed_sql)

        conn.commit()

        return response(200, {
            "ok": True
        })

    except Exception:
        if conn is not None:
            try:
                conn.rollback()
            except Exception:
                pass

        return response(500, {
            "error": "No se pudo inicializar la base de datos"
        })

    finally:
        if cursor is not None:
            try:
                cursor.close()
            except Exception:
                pass

        if conn is not None:
            try:
                conn.autocommit = True
            except Exception:
                pass
