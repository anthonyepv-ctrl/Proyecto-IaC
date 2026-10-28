
import os
import pg8000.dbapi

_conn = None


def get_conn():
    global _conn

    # Si existe una conexión, comprobamos que siga funcionando.
    if _conn is not None:
        try:
            cursor = _conn.cursor()
            cursor.execute("SELECT 1")
            cursor.close()
            return _conn
        except Exception:
            try:
                _conn.close()
            except Exception:
                pass
            _conn = None

    # Crear una nueva conexión usando variables de entorno.
    _conn = pg8000.dbapi.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ.get("DB_PORT", "5432")),
        database=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        timeout=10
    )

    return _conn
