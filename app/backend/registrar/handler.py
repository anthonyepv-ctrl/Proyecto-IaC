
import json
from datetime import datetime

from common.db import get_conn
from common.http import response


def lambda_handler(event, context):
    conn = None
    cursor = None

    try:
        body = event.get("body") or "{}"

        if isinstance(body, str):
            body = json.loads(body)

        sede_id = body.get("sede_id")
        placa = body.get("placa")
        inicio = body.get("inicio")
        fin = body.get("fin")

        if not sede_id or not placa or not inicio or not fin:
            return response(400, {
                "error": "Se requieren sede_id, placa, inicio y fin"
            })

        placa = placa.strip().upper()

        if not placa:
            return response(400, {
                "error": "La placa no puede estar vacía"
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
                "error": "Los datos tienen un formato inválido"
            })

        if fin_dt <= inicio_dt:
            return response(400, {
                "error": "fin debe ser posterior a inicio"
            })

        conn = get_conn()
        cursor = conn.cursor()

        # Iniciar una transacción.
        conn.autocommit = False

        # Bloquear la fila de la sede para coordinar reservas simultáneas.
        cursor.execute(
            "SELECT capacidad FROM sedes WHERE id = %s FOR UPDATE",
            (sede_id,)
        )

        sede = cursor.fetchone()

        if sede is None:
            conn.rollback()
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

        if ocupados >= capacidad:
            conn.rollback()
            return response(409, {
                "error": "No hay espacios disponibles para ese horario"
            })

        cursor.execute(
            """
            INSERT INTO reservas (sede_id, placa, inicio, fin)
            VALUES (%s, %s, %s, %s)
            RETURNING id
            """,
            (sede_id, placa, inicio_dt, fin_dt)
        )

        reserva_id = cursor.fetchone()[0]
        conn.commit()

        return response(201, {
            "id": reserva_id,
            "mensaje": "Reserva registrada correctamente"
        })

    except json.JSONDecodeError:
        if conn is not None:
            conn.rollback()
        return response(400, {
            "error": "El body no contiene un JSON válido"
        })

    except Exception:
        if conn is not None:
            try:
                conn.rollback()
            except Exception:
                pass

        return response(500, {
            "error": "Error interno del servidor"
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
