
import json
from datetime import datetime

from common.db import get_conn
from common.http import response


def lambda_handler(event, context):
    try:
        path = event.get("rawPath") or event.get("path", "")

        # Ruta para listar las sedes.
        if path.endswith("/api/sedes"):
            conn = get_conn()
            cursor = conn.cursor()

            cursor.execute(
                "SELECT id, nombre, distrito, capacidad "
                "FROM sedes ORDER BY id"
            )

            rows = cursor.fetchall()
            cursor.close()

            sedes = [
                {
                    "id": row[0],
                    "nombre": row[1],
                    "distrito": row[2],
                    "capacidad": row[3]
                }
                for row in rows
            ]

            return response(200, {"sedes": sedes})

        # Ruta para consultar disponibilidad.
        if path.endswith("/api/disponibilidad"):
            params = event.get("queryStringParameters") or {}

            sede_id = params.get("sede_id")
            inicio = params.get("inicio")
            fin = params.get("fin")

            if not sede_id or not inicio or not fin:
                return response(400, {
                    "error": "Se requieren sede_id, inicio y fin"
                })

            try:
                sede_id = int(sede_id)
                inicio_dt = datetime.fromisoformat(
                    inicio.replace("Z", "+00:00")
                )
                fin_dt = datetime.fromisoformat(
                    fin.replace("Z", "+00:00")
                )
            except (ValueError, TypeError):
                return response(400, {
                    "error": "Los parámetros tienen un formato inválido"
                })

            if fin_dt <= inicio_dt:
                return response(400, {
                    "error": "fin debe ser posterior a inicio"
                })

            conn = get_conn()
            cursor = conn.cursor()

            cursor.execute(
                "SELECT capacidad FROM sedes WHERE id = %s",
                (sede_id,)
            )
            sede = cursor.fetchone()

            if sede is None:
                cursor.close()
                return response(404, {
                    "error": "La sede no existe"
                })

            capacidad = sede[0]

            cursor.execute(
                """
                SELECT COUNT(*)
                FROM reservas
                WHERE sede_id = %s
                  AND estado = 'activa'
                  AND inicio < %s
                  AND fin > %s
                """,
                (sede_id, fin_dt, inicio_dt)
            )

            ocupados = cursor.fetchone()[0]
            cursor.close()

            disponibles = max(0, capacidad - ocupados)

            return response(200, {
                "disponibles": disponibles
            })

        return response(404, {
            "error": "Ruta no encontrada"
        })

    except Exception:
        return response(500, {
            "error": "Error interno del servidor"
        })
