
from datetime import datetime
from functools import wraps
from flask import flash, redirect, url_for, session
from db import one


def login_required(f):
    @wraps(f)
    def w(*a, **k):
        if "uid" not in session:
            return redirect(url_for("auth.login"))
        return f(*a, **k)
    return w


def br(iso):
    return datetime.strptime(iso, "%Y-%m-%d").strftime("%d/%m/%Y")


def moeda(v):
    return f"R$ {v:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")


def contexto():
    u = one("SELECT * FROM usuarios WHERE id=?", (session["uid"],)) if "uid" in session else None
    return {"usuario": u, "iniciais": "".join(p[0] for p in u["nome"].split()[:2]).upper() if u else ""}


def admin_required(f):
    """Só a equipe da oficina (papel 'admin') acessa o estoque."""
    @login_required
    @wraps(f)
    def w(*a, **k):
        u = one("SELECT papel FROM usuarios WHERE id=?", (session["uid"],))
        if not u or u["papel"] != "admin":
            flash("Acesso restrito à equipe da oficina.", "erro")
            return redirect(url_for("inicio.index"))
        return f(*a, **k)
    return w
