
import os
import sqlite3
from datetime import datetime
from pathlib import Path
from flask import g
from werkzeug.security import generate_password_hash
import data

BASE = Path(__file__).parent
DB_PATH = Path(os.environ.get("FELIVEL_DB", BASE / "felivel.db"))


def conn():
    if "db" not in g:
        g.db = sqlite3.connect(DB_PATH)
        g.db.row_factory = sqlite3.Row
        g.db.execute("PRAGMA foreign_keys = ON")
    return g.db


def fechar(_erro=None):
    db = g.pop("db", None)
    if db:
        db.close()


def q(sql, args=()):      # várias linhas -> lista de dict
    return [dict(r) for r in conn().execute(sql, args).fetchall()]


def one(sql, args=()):    # uma linha -> dict ou None
    r = conn().execute(sql, args).fetchone()
    return dict(r) if r else None


def ex(sql, args=()):     # INSERT/UPDATE/DELETE -> id da linha criada
    c = conn()
    cur = c.execute(sql, args)
    c.commit()
    return cur.lastrowid


def veiculos_do(uid):
    return q("SELECT * FROM veiculos WHERE usuario_id=? ORDER BY principal DESC, id", (uid,))


def _detalhes_catalogo(chave):
    c = data.CATALOGO[chave]
    return {"nome": c["nome"], "icone": c["icone"], "duracao": c["duracao"]}


def servicos_do(uid):
    """Serviços do cliente; valor = mão de obra + peças (cada parte guardada separadamente)."""
    linhas = q("""SELECT s.*, v.modelo AS veiculo_nome,
                  COALESCE((SELECT SUM(sp.quantidade*sp.preco_unit) FROM servico_pecas sp WHERE sp.servico_id=s.id),0) AS pecas_total
                  FROM servicos s JOIN veiculos v ON v.id=s.veiculo_id WHERE s.usuario_id=? ORDER BY s.id""", (uid,))
    return [{**s, **_detalhes_catalogo(s["servico"]), "pecas_total": round(s["pecas_total"], 2),
             "valor": round(s["mao_de_obra"] + s["pecas_total"], 2)} for s in linhas]


def servico_detalhe(sid, uid=None):
    """Um serviço com a lista de peças usadas. Se uid for informado, só devolve se for do cliente."""
    sql, args = ("SELECT s.*, v.modelo AS veiculo_nome, v.placa, u.nome AS cliente FROM servicos s "
                 "JOIN veiculos v ON v.id=s.veiculo_id JOIN usuarios u ON u.id=s.usuario_id WHERE s.id=?"), [sid]
    if uid:
        sql += " AND s.usuario_id=?"
        args.append(uid)
    s = one(sql, args)
    if not s:
        return None
    s["pecas"] = q("""SELECT sp.id, sp.peca_id, sp.quantidade, sp.preco_unit, sp.quantidade*sp.preco_unit AS subtotal,
                      p.nome, p.codigo, p.quantidade AS estoque FROM servico_pecas sp JOIN pecas p ON p.id=sp.peca_id
                      WHERE sp.servico_id=? ORDER BY sp.id""", (sid,))
    s.update(_detalhes_catalogo(s["servico"]))
    s["pecas_total"] = round(sum(p["subtotal"] for p in s["pecas"]), 2)
    s["valor"] = round(s["mao_de_obra"] + s["pecas_total"], 2)
    return s


def receita(chave):
    """Peças previstas para um tipo de serviço, com o preço atual do estoque."""
    out = []
    for codigo, qtd in data.CATALOGO[chave]["pecas"]:
        p = one("SELECT id, nome, preco, quantidade FROM pecas WHERE codigo=?", (codigo,))
        if p:
            out.append({**p, "qtd": qtd})
    return out


def estimativa(chave):
    return round(sum(p["preco"] * p["qtd"] for p in receita(chave)), 2)


def _seed_estoque(db):
    if db.execute("SELECT 1 FROM categorias_peca LIMIT 1").fetchone():
        return
    agora, n = datetime.now().strftime("%Y-%m-%d %H:%M"), 0
    for ordem, (pre, sistema, icone, itens) in enumerate(data.SISTEMAS, 1):
        cid = db.execute("INSERT INTO categorias_peca (nome,icone,ordem) VALUES (?,?,?)", (sistema, icone, ordem)).lastrowid
        for i, linha in enumerate(itens, 1):
            n += 1
            nome, custo, minimo = linha.split("|")
            custo, minimo = float(custo), int(minimo)
            qtd = sum(map(ord, nome)) % 14 + minimo          # quantidades de exemplo
            if n % 9 == 0:
                qtd = 0                                      # alguns itens zerados e abaixo do mínimo, para demonstrar os alertas
            elif n % 6 == 0:
                qtd = max(minimo - 1, 0)
            baixo = nome.lower()
            un = "litro" if "litro" in baixo else "jogo" if baixo.startswith(("jogo", "kit")) else "un"
            pid = db.execute("INSERT INTO pecas (codigo,nome,categoria_id,unidade,quantidade,estoque_minimo,custo,preco,fornecedor,localizacao) VALUES (?,?,?,?,?,?,?,?,?,?)",
                             (f"{pre}-{i:03d}", nome, cid, un, qtd, minimo, custo, round(custo * 1.55, 2),
                              data.FORNECEDORES[n % len(data.FORNECEDORES)], f"{pre}-A{n % 4 + 1}-P{n % 3 + 1}")).lastrowid
            if qtd:
                db.execute("INSERT INTO movimentacoes (peca_id,usuario_id,tipo,quantidade,saldo_apos,motivo,criado) VALUES (?,NULL,'ENTRADA',?,?,'Estoque inicial',?)",
                           (pid, qtd, qtd, agora))


def init_db():
    """Cria as tabelas (schema.sql), migra bancos antigos e insere os dados iniciais se estiver vazio."""
    db = sqlite3.connect(DB_PATH)
    db.executescript((BASE / "schema.sql").read_text(encoding="utf-8"))
    if "papel" not in [r[1] for r in db.execute("PRAGMA table_info(usuarios)")]:        # migração: perfis de acesso
        db.execute("ALTER TABLE usuarios ADD COLUMN papel TEXT NOT NULL DEFAULT 'cliente'")
    if "mao_de_obra" not in [r[1] for r in db.execute("PRAGMA table_info(servicos)")]:  # migração: mão de obra separada
        db.execute("ALTER TABLE servicos ADD COLUMN mao_de_obra REAL NOT NULL DEFAULT 0")
        for chave, valor in data.LEGADO_VALOR.items():       # serviços antigos: o valor total vira mão de obra (as peças não foram registradas)
            db.execute("UPDATE servicos SET mao_de_obra=? WHERE servico=?", (valor, chave))
    novos = []
    if not db.execute("SELECT 1 FROM usuarios LIMIT 1").fetchone():
        u = data.USUARIO_DEMO
        uid = db.execute("INSERT INTO usuarios (email,nome,senha_hash,telefone,cpf,nascimento,cidade,desde) VALUES (?,?,?,?,?,?,?,?)",
                         (u["email"], u["nome"], generate_password_hash(u["senha"]), u["telefone"], u["cpf"],
                          u["nascimento"], u["cidade"], u["desde"])).lastrowid
        ids = {}
        for v in data.VEICULOS_SEED:
            ids[v["chave"]] = db.execute("INSERT INTO veiculos (usuario_id,modelo,ano,placa,cor,principal,emoji) VALUES (?,?,?,?,?,?,?)",
                                         (uid, v["modelo"], v["ano"], v["placa"], v["cor"], v["principal"], v["emoji"])).lastrowid
        for s in data.SERVICOS_SEED:
            sid = db.execute("INSERT INTO servicos (usuario_id,veiculo_id,servico,data,hora,status,mao_de_obra) VALUES (?,?,?,?,?,?,?)",
                             (uid, ids[s["veiculo"]], s["servico"], s["data"], s.get("hora"), s["status"],
                              data.CATALOGO[s["servico"]]["mao_de_obra"])).lastrowid
            novos.append((sid, s["servico"]))
        db.executemany("INSERT INTO postos (nome,endereco,lat,lng,h24,servicos) VALUES (?,?,?,?,?,?)", data.POSTOS_SEED)
    if not db.execute("SELECT 1 FROM usuarios WHERE papel='admin' LIMIT 1").fetchone():
        a = data.ADMIN_DEMO
        db.execute("INSERT INTO usuarios (email,nome,senha_hash,papel) VALUES (?,?,?,'admin')", (a["email"], a["nome"], generate_password_hash(a["senha"])))
    _seed_estoque(db)
    for sid, chave in novos:                                  # peças usadas nos serviços de exemplo
        for codigo, qtd in data.CATALOGO[chave]["pecas"]:
            p = db.execute("SELECT id, preco FROM pecas WHERE codigo=?", (codigo,)).fetchone()
            if p:
                db.execute("INSERT INTO servico_pecas (servico_id,peca_id,quantidade,preco_unit) VALUES (?,?,?,?)", (sid, p[0], qtd, p[1]))
    db.commit()
    db.close()
