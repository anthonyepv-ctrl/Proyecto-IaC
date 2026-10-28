
import json

from common.db import get_conn
from common.http import response


def lambda_handler(event, context):
    conn = None
    cursor = None

    try:
        path_params = event.get("pathParameters") or {}
        reserva_id = path_params.get("id")

        if not reserva_id:
            return response(400, {"error": "Falta el id de la reserva"})

        try:
            reserva_id = int(reserva_id)
        except (ValueError, TypeError):
            return response(400, {"error": "El id no es valido"})

        body = event.get("body") or "{}"
        if isinstance(body, str):
            body = json.loads(body)

        if not isinstance(body, dict):
            return response(400, {"error": "El body debe ser un JSON objeto"})

        minutos = body.get("minutos")
        if isinstance(minutos, bool) or not isinstance(minutos, int) or minutos <= 0:
            return response(400, {"error": "minutos debe ser un entero positivo"})

        conn = get_conn()
        conn.autocommit = False
        cursor = conn.cursor()

        # Obtener la sede de la reserva.
        cursor.execute(
            "SELECT sede_id FROM reservas WHERE id = %s AND estado = 'activa'",
            (reserva_id,)
        )
        fila = cursor.fetchone()

        if fila is None:
            conn.rollback()
            return response(404, {"error": "Reserva activa no encontrada"})

        sede_id = fila[0]

        # Usar el mismo bloqueo que el registro de reservas.
        cursor.execute(
            "SELECT capacidad FROM sedes WHERE id = %s FOR UPDATE",
            (sede_id,)
        )
        sede = cursor.fetchone()

        if sede is None:
            conn.rollback()
            return response(404, {"error": "Sede no encontrada"})

        capacidad = sede[0]

        # Bloquear y leer la reserva que se va a ampliar.
        cursor.execute(
            """
            SELECT inicio, fin
            FROM reservas
            WHERE id = %s AND sede_id = %s AND estado = 'activa'
            FOR UPDATE
            """,
            (reserva_id, sede_id)
        )
        reserva = cursor.fetchone()

        if reserva is None:
            conn.rollback()
            return response(404, {"error": "Reserva activa no encontrada"})

        inicio_actual, fin_actual = reserva

        # Calcular el nuevo horario sin modificar todavía la reserva.
        cursor.execute(
            "SELECT %s::timestamptz + (%s * INTERVAL '1 minute')",
            (fin_actual, minutos)
        )
        nueva_fin = cursor.fetchone()[0]

        # Contar las otras reservas que se cruzarían con el horario ampliado.
        cursor.execute(
            """
            SELECT COUNT(*)
            FROM reservas
            WHERE sede_id = %s
              AND estado = 'activa'
              AND id <> %s
              AND inicio < %s
              AND fin > %s
            """,
            (sede_id, reserva_id, nueva_fin, inicio_actual)
        )
        ocupados = cursor.fetchone()[0]

        if ocupados >= capacidad:
            conn.rollback()
            return response(409, {
                "error": "No hay capacidad para ampliar la reserva"
            })

        cursor.execute(
            """
            UPDATE reservas
            SET fin = %s
            WHERE id = %s
            RETURNING fin
            """,
            (nueva_fin, reserva_id)
        )

        nueva_fin = cursor.fetchone()[0]
        conn.commit()

        return response(200, {
            "id": reserva_id,
            "fin": nueva_fin.isoformat()
        })

    except json.JSONDecodeError:
        if conn is not None:
            conn.rollback()
        return response(400, {"error": "El body no contiene JSON valido"})

    except Exception:
        if conn is not None:
            try:
                conn.rollback()
            except Exception:
                pass
        return response(500, {"error": "Error interno del servidor"})

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
