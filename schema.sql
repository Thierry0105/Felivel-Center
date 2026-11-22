-- Felivel Center - estrutura do banco (SQLite). Pode ser aberto no DB Browser for SQLite.
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS usuarios (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    email       TEXT NOT NULL UNIQUE,
    nome        TEXT NOT NULL,
    senha_hash  TEXT NOT NULL,
    telefone    TEXT,
    cpf         TEXT,
    nascimento  TEXT,
    cidade      TEXT,
    desde       TEXT NOT NULL DEFAULT (date('now')),
    papel       TEXT NOT NULL DEFAULT 'cliente'   -- 'cliente' ou 'admin' (equipe da oficina)
);

CREATE TABLE IF NOT EXISTS veiculos (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    usuario_id  INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    modelo      TEXT NOT NULL,
    ano         INTEGER NOT NULL,
    placa       TEXT NOT NULL,
    cor         TEXT,
    principal   INTEGER NOT NULL DEFAULT 0,
    emoji       TEXT DEFAULT '🚗'
);

CREATE TABLE IF NOT EXISTS servicos (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    usuario_id  INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    veiculo_id  INTEGER NOT NULL REFERENCES veiculos(id) ON DELETE CASCADE,
    servico     TEXT NOT NULL,            -- oleo, alinhamento, bateria, revisao
    data        TEXT NOT NULL,            -- AAAA-MM-DD
    hora        TEXT,                     -- HH:MM
    status      TEXT NOT NULL DEFAULT 'Agendado' CHECK (status IN ('Agendado','Concluído')),
    mao_de_obra REAL NOT NULL DEFAULT 0       -- valor da mão de obra (separado das peças)
);
-- impede dois agendamentos no mesmo dia e horário
CREATE UNIQUE INDEX IF NOT EXISTS ux_agenda ON servicos(data, hora) WHERE status = 'Agendado';

CREATE TABLE IF NOT EXISTS postos (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    nome        TEXT NOT NULL,
    endereco    TEXT NOT NULL,
    lat         REAL NOT NULL,
    lng         REAL NOT NULL,
    h24         INTEGER NOT NULL DEFAULT 0,
    servicos    TEXT                      -- separados por vírgula
);

CREATE TABLE IF NOT EXISTS sos_chamados (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    usuario_id  INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    protocolo   TEXT NOT NULL UNIQUE,
    tipo        TEXT NOT NULL,            -- guincho, pneu, bateria
    veiculo     TEXT NOT NULL,
    lat         REAL,
    lng         REAL,
    referencia  TEXT,
    telefone    TEXT NOT NULL,
    status      TEXT NOT NULL DEFAULT 'Aguardando atendimento',
    criado      TEXT NOT NULL
);

-- ===== Módulo de estoque de peças =====
CREATE TABLE IF NOT EXISTS categorias_peca (      -- sistemas do carro (motor, freios...)
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    nome    TEXT NOT NULL UNIQUE,
    icone   TEXT,
    ordem   INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS pecas (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo          TEXT NOT NULL UNIQUE,
    nome            TEXT NOT NULL,
    categoria_id    INTEGER NOT NULL REFERENCES categorias_peca(id),
    descricao       TEXT,
    unidade         TEXT NOT NULL DEFAULT 'un',
    quantidade      INTEGER NOT NULL DEFAULT 0 CHECK (quantidade >= 0),
    estoque_minimo  INTEGER NOT NULL DEFAULT 0,
    custo           REAL NOT NULL DEFAULT 0,
    preco           REAL NOT NULL DEFAULT 0,
    fornecedor      TEXT,
    localizacao     TEXT
);

CREATE TABLE IF NOT EXISTS movimentacoes (        -- histórico de entradas, saídas e ajustes
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    peca_id     INTEGER NOT NULL REFERENCES pecas(id) ON DELETE CASCADE,
    usuario_id  INTEGER REFERENCES usuarios(id) ON DELETE SET NULL,
    tipo        TEXT NOT NULL CHECK (tipo IN ('ENTRADA','SAIDA','AJUSTE')),
    quantidade  INTEGER NOT NULL,                 -- ENTRADA positiva, SAIDA negativa, AJUSTE com sinal
    saldo_apos  INTEGER NOT NULL,
    motivo      TEXT,
    criado      TEXT NOT NULL
);

-- ===== Peças usadas em cada serviço (separadas da mão de obra) =====
CREATE TABLE IF NOT EXISTS servico_pecas (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    servico_id  INTEGER NOT NULL REFERENCES servicos(id) ON DELETE CASCADE,
    peca_id     INTEGER NOT NULL REFERENCES pecas(id),
    quantidade  INTEGER NOT NULL CHECK (quantidade > 0),
    preco_unit  REAL NOT NULL,                -- preço da peça no momento do serviço
    UNIQUE (servico_id, peca_id)
);
-- Valor do serviço = servicos.mao_de_obra + SUM(servico_pecas.quantidade * servico_pecas.preco_unit)
