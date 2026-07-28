# app.py — API REST + servidor de templates
# Flask + MySQL · Desplegado con Apache (mod_proxy) + Gunicorn
# Si MySQL no está disponible, funciona en MODO DEMO (datos en memoria).
import os
import sys
from datetime import datetime
from flask import Flask, jsonify, request, render_template
from dotenv import load_dotenv

load_dotenv()
app = Flask(__name__)

# ── Intentar conexión a MySQL ───────────────────────────────────────────────
DEMO_MODE = False
try:
    import pymysql
    pymysql.install_as_MySQLdb()
    DB_CONFIG = {
        "host":     os.getenv("DB_HOST", "localhost"),
        "port":     int(os.getenv("DB_PORT", 3306)),
        "user":     os.getenv("DB_USER", "gestor_user"),
        "password": os.getenv("DB_PASSWORD", "CambiameYa2024!"),
        "database": os.getenv("DB_NAME", "gestor_db"),
        "charset":  "utf8mb4",
        "cursorclass": pymysql.cursors.DictCursor,
    }
    # Verificar conectividad al arrancar
    test = pymysql.connect(**DB_CONFIG)
    test.ping()
    test.close()
    print("  [OK] MySQL conectado")
except Exception:
    DEMO_MODE = True
    print("  [!] MySQL no disponible -> MODO DEMO (datos en memoria)")

def db():
    return pymysql.connect(**DB_CONFIG)

# ── Datos en memoria (modo demo) ───────────────────────────────────────────
_next_id = 4
_tareas = [
    {"id": 1, "titulo": "Provisionar el VPS con Ubuntu",
     "descripcion": "Contratar servidor, instalar y actualizar paquetes", "completada": True,
     "creado": "2026-07-20 10:00:00"},
    {"id": 2, "titulo": "Instalar Apache y MySQL en el servidor",
     "descripcion": "Configurar el stack LAMP para la aplicación Flask", "completada": True,
     "creado": "2026-07-21 14:30:00"},
    {"id": 3, "titulo": "Configurar pipeline CI/CD",
     "descripcion": "GitHub Actions con SSH + rsync para deploy automático", "completada": False,
     "creado": "2026-07-22 09:15:00"},
]

# ── Página principal ────────────────────────────────────────────────────────
@app.route("/")
def index():
    return render_template("home.html")

# ── Healthcheck ─────────────────────────────────────────────────────────────
@app.route("/api/health")
def health():
    if DEMO_MODE:
        return jsonify(status="ok", db="demo-mode", mode="memoria")
    try:
        c = db(); c.ping(); c.close()
        return jsonify(status="ok", db="connected")
    except Exception:
        return jsonify(status="error", db="disconnected"), 500

# ══════════════════════════════════════════════════════════════════════════════
# MODO DEMO (sin MySQL)
# ══════════════════════════════════════════════════════════════════════════════
if DEMO_MODE:

    @app.route("/api/tareas")
    def listar():
        q = request.args.get("q", "").strip().lower()
        items = sorted(_tareas, key=lambda t: t["creado"], reverse=True)
        if q:
            items = [t for t in items if q in t["titulo"].lower() or (t["descripcion"] and q in t["descripcion"].lower())]
        return jsonify(items)

    @app.route("/api/tareas/<int:tid>")
    def obtener(tid):
        t = next((x for x in _tareas if x["id"] == tid), None)
        return jsonify(t) if t else (jsonify(error="No encontrada"), 404)

    @app.route("/api/tareas", methods=["POST"])
    def crear():
        global _next_id
        d = request.get_json()
        titulo = (d.get("titulo") or "").strip()
        if not titulo:
            return jsonify(error="Título requerido"), 400
        t = {"id": _next_id, "titulo": titulo,
             "descripcion": (d.get("descripcion") or "").strip() or None,
             "completada": False, "creado": datetime.now().strftime("%Y-%m-%d %H:%M:%S")}
        _next_id += 1
        _tareas.insert(0, t)
        return jsonify(t), 201

    @app.route("/api/tareas/<int:tid>", methods=["PUT"])
    def actualizar(tid):
        d = request.get_json()
        t = next((x for x in _tareas if x["id"] == tid), None)
        if not t:
            return jsonify(error="No encontrada"), 404
        t["titulo"] = d.get("titulo", t["titulo"])
        t["descripcion"] = d.get("descripcion", t["descripcion"])
        t["completada"] = d.get("completada", t["completada"])
        return jsonify(t)

    @app.route("/api/tareas/<int:tid>", methods=["DELETE"])
    def eliminar(tid):
        idx = next((i for i, x in enumerate(_tareas) if x["id"] == tid), None)
        if idx is None:
            return jsonify(error="No encontrada"), 404
        _tareas.pop(idx)
        return jsonify(ok=True)

# ══════════════════════════════════════════════════════════════════════════════
# MODO PRODUCCIÓN (con MySQL)
# ══════════════════════════════════════════════════════════════════════════════
else:

    @app.route("/api/tareas")
    def listar():
        q = request.args.get("q", "").strip()
        conn = db(); cur = conn.cursor()
        if q:
            cur.execute(
                "SELECT * FROM tareas WHERE titulo LIKE %s OR descripcion LIKE %s ORDER BY creado DESC",
                (f"%{q}%", f"%{q}%"),
            )
        else:
            cur.execute("SELECT * FROM tareas ORDER BY creado DESC")
        rows = cur.fetchall()
        for r in rows:
            r["completada"] = bool(r["completada"])
            r["creado"] = str(r["creado"])
        cur.close(); conn.close()
        return jsonify(rows)

    @app.route("/api/tareas/<int:tid>")
    def obtener(tid):
        conn = db(); cur = conn.cursor()
        cur.execute("SELECT * FROM tareas WHERE id=%s", (tid,))
        row = cur.fetchone()
        cur.close(); conn.close()
        if not row:
            return jsonify(error="No encontrada"), 404
        row["completada"] = bool(row["completada"])
        row["creado"] = str(row["creado"])
        return jsonify(row)

    @app.route("/api/tareas", methods=["POST"])
    def crear():
        d = request.get_json()
        titulo = (d.get("titulo") or "").strip()
        if not titulo:
            return jsonify(error="Título requerido"), 400
        desc = (d.get("descripcion") or "").strip() or None
        conn = db(); cur = conn.cursor()
        cur.execute("INSERT INTO tareas (titulo, descripcion) VALUES (%s,%s)", (titulo, desc))
        new_id = cur.lastrowid
        conn.commit()
        cur.execute("SELECT * FROM tareas WHERE id=%s", (new_id,))
        row = cur.fetchone()
        row["completada"] = bool(row["completada"])
        row["creado"] = str(row["creado"])
        cur.close(); conn.close()
        return jsonify(row), 201

    @app.route("/api/tareas/<int:tid>", methods=["PUT"])
    def actualizar(tid):
        d = request.get_json()
        conn = db(); cur = conn.cursor()
        cur.execute("SELECT * FROM tareas WHERE id=%s", (tid,))
        actual = cur.fetchone()
        if not actual:
            cur.close(); conn.close()
            return jsonify(error="No encontrada"), 404
        t = d.get("titulo", actual["titulo"])
        desc = d.get("descripcion", actual["descripcion"])
        comp = d.get("completada", bool(actual["completada"]))
        cur.execute(
            "UPDATE tareas SET titulo=%s, descripcion=%s, completada=%s WHERE id=%s",
            (t, desc, int(comp), tid),
        )
        conn.commit()
        cur.execute("SELECT * FROM tareas WHERE id=%s", (tid,))
        row = cur.fetchone()
        row["completada"] = bool(row["completada"])
        row["creado"] = str(row["creado"])
        cur.close(); conn.close()
        return jsonify(row)

    @app.route("/api/tareas/<int:tid>", methods=["DELETE"])
    def eliminar(tid):
        conn = db(); cur = conn.cursor()
        cur.execute("SELECT * FROM tareas WHERE id=%s", (tid,))
        row = cur.fetchone()
        if not row:
            cur.close(); conn.close()
            return jsonify(error="No encontrada"), 404
        cur.execute("DELETE FROM tareas WHERE id=%s", (tid,))
        conn.commit(); cur.close(); conn.close()
        return jsonify(ok=True)

# ── Arranque local ──────────────────────────────────────────────────────────
if __name__ == "__main__":
    modo = "DEMO (memoria)" if DEMO_MODE else "PRODUCCIÓN (MySQL)"
    print(f"""
-----------------------------------------------
   Gestor de Actividades - {modo:<20s}
   http://localhost:5000
-----------------------------------------------
""")
    app.run(host="0.0.0.0", port=5000, debug=True)
