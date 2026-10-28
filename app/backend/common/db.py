
import os
import ssl
from pathlib import Path

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

    # Obtener la ruta del certificado desde la carpeta common.
    ca_path = Path(__file__).parent / "certs" / "global-bundle.pem"
    ssl_context = ssl.create_default_context(cafile=str(ca_path))

    # Crear una conexión segura a PostgreSQL.
    _conn = pg8000.dbapi.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ.get("DB_PORT", "5432")),
        database=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        timeout=10,
        ssl_context=ssl_context
    )

    # Evitar transacciones abiertas en consultas normales.
    _conn.autocommit = True

    return _conn
