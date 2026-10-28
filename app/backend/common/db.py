

import os
import ssl
import pg8000.dbapi

_conn = None


def get_conn():
    global _conn

    # Comprobar si la conexión existente sigue funcionando.
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

    # Leer la ruta del certificado CA de RDS.
    ca_path = os.environ["DB_SSL_CA"]
    ssl_context = ssl.create_default_context(cafile=ca_path)

    # Crear la conexión segura a PostgreSQL.
    _conn = pg8000.dbapi.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ.get("DB_PORT", "5432")),
        database=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        timeout=10,
        ssl_context=ssl_context
    )

    # Las consultas normales no dejan transacciones abiertas.
    _conn.autocommit = True

    return _conn

