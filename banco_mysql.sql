-- =====================================================================
-- Felivel Center - banco de dados (versão MySQL 8+ / MariaDB)
-- Como usar: abra no MySQL Workbench (ou phpMyAdmin > Importar) e execute tudo.
-- =====================================================================
DROP DATABASE IF EXISTS felivel;
CREATE DATABASE felivel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE felivel;

CREATE TABLE usuarios (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  email       VARCHAR(120) NOT NULL UNIQUE,
  nome        VARCHAR(120) NOT NULL,
  senha_hash  VARCHAR(255) NOT NULL,
  telefone    VARCHAR(20),
  cpf         VARCHAR(14),
  nascimento  DATE,
  cidade      VARCHAR(80),
  desde       DATE NOT NULL DEFAULT (CURRENT_DATE)
) ENGINE=InnoDB;

CREATE TABLE veiculos (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id  INT NOT NULL,
  modelo      VARCHAR(80) NOT NULL,
  ano         SMALLINT NOT NULL,
  placa       VARCHAR(8) NOT NULL,
  cor         VARCHAR(30),
  principal   TINYINT(1) NOT NULL DEFAULT 0,
  emoji       VARCHAR(8) DEFAULT '🚗',
  CONSTRAINT fk_veic_user FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE servicos (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id  INT NOT NULL,
  veiculo_id  INT NOT NULL,
  servico     ENUM('oleo','alinhamento','bateria','revisao') NOT NULL,
  data        DATE NOT NULL,
  hora        TIME NULL,
  status      ENUM('Agendado','Concluído') NOT NULL DEFAULT 'Agendado',
  UNIQUE KEY ux_agenda (data, hora),            -- impede 2 agendamentos no mesmo dia e horário
  CONSTRAINT fk_serv_user FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
  CONSTRAINT fk_serv_veic FOREIGN KEY (veiculo_id) REFERENCES veiculos(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE postos (
  id        INT AUTO_INCREMENT PRIMARY KEY,
  nome      VARCHAR(100) NOT NULL,
  endereco  VARCHAR(160) NOT NULL,
  lat       DECIMAL(9,6) NOT NULL,
  lng       DECIMAL(9,6) NOT NULL,
  h24       TINYINT(1) NOT NULL DEFAULT 0,
  servicos  VARCHAR(200)
) ENGINE=InnoDB;

CREATE TABLE sos_chamados (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id  INT NOT NULL,
  protocolo   VARCHAR(20) NOT NULL UNIQUE,
  tipo        ENUM('guincho','pneu','bateria') NOT NULL,
  veiculo     VARCHAR(120) NOT NULL,
  lat         DECIMAL(9,6),
  lng         DECIMAL(9,6),
  referencia  VARCHAR(200),
  telefone    VARCHAR(20) NOT NULL,
  status      VARCHAR(40) NOT NULL DEFAULT 'Aguardando atendimento',
  criado      DATETIME NOT NULL,
  CONSTRAINT fk_sos_user FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------- dados iniciais -------------------------------
INSERT INTO usuarios (id, email, nome, senha_hash, telefone, cpf, nascimento, cidade, desde) VALUES
  (1, 'joao@email.com', 'João Fernandes', 'scrypt:32768:8:1$VpnPr5SrAhZI329K$27d7b154f5da083fc379941914bb2b8f998eb0e1a7659690aaee0399b3d39f958f26c94c8aacce17f1ed965d128c396582c8d6fd18dd37267067312b2d6c0f53', '(31) 99999-1234', '123.456.789-00', '1990-05-14', 'Belo Horizonte - MG', '2023-03-10');

INSERT INTO veiculos (id, usuario_id, modelo, ano, placa, cor, principal, emoji) VALUES
  (1, 1, 'Volkswagen Polo', 2024, 'ABC-1234', 'Prata', 1, '🚙'),
  (2, 1, 'Toyota Corolla', 2022, 'DEF-5678', 'Branco', 0, '🚘');

INSERT INTO servicos (id, usuario_id, veiculo_id, servico, data, hora, status) VALUES
  (1, 1, 1, 'oleo', '2026-06-15', NULL, 'Concluído'),
  (2, 1, 1, 'alinhamento', '2026-04-20', NULL, 'Concluído'),
  (3, 1, 1, 'bateria', '2026-01-10', NULL, 'Concluído'),
  (4, 1, 2, 'revisao', '2026-08-02', NULL, 'Concluído'),
  (5, 1, 1, 'oleo', '2026-09-28', '14:00', 'Agendado');

INSERT INTO postos (id, nome, endereco, lat, lng, h24, servicos) VALUES
  (1, 'Posto Parceiro Centro', 'Praça Sete de Setembro, Centro', -19.9208, -43.9378, 1, 'Calibragem,Conveniência'),
  (2, 'Posto Parceiro Savassi', 'Av. do Contorno, Savassi', -19.9391, -43.934, 0, 'Calibragem,Lava-rápido'),
  (3, 'Posto Parceiro Pampulha', 'Av. Otacílio Negrão de Lima, Pampulha', -19.8517, -43.9667, 1, 'Conveniência,Troca de óleo'),
  (4, 'Posto Parceiro Buritis', 'Av. Professor Mário Werneck, Buritis', -19.9744, -43.9602, 0, 'Calibragem'),
  (5, 'Posto Parceiro Barro Preto', 'Av. Augusto de Lima, Barro Preto', -19.9261, -43.9505, 1, 'Calibragem,Conveniência,Lava-rápido');

-- ------------------------------- consultas de exemplo -------------------------------
-- 1) Serviços de cada cliente, com o veículo
SELECT u.nome AS cliente, v.modelo, v.placa, s.servico, s.data, s.hora, s.status
FROM servicos s
JOIN usuarios u ON u.id = s.usuario_id
JOIN veiculos v ON v.id = s.veiculo_id
ORDER BY s.data DESC;

-- 2) Quantidade de serviços por status
SELECT status, COUNT(*) AS total FROM servicos GROUP BY status;

-- 3) Próximos agendamentos
SELECT u.nome, v.modelo, s.servico, s.data, s.hora
FROM servicos s JOIN usuarios u ON u.id = s.usuario_id JOIN veiculos v ON v.id = s.veiculo_id
WHERE s.status = 'Agendado' AND s.data >= CURRENT_DATE ORDER BY s.data, s.hora;

-- 4) Quantos veículos cada cliente tem
SELECT u.nome, COUNT(v.id) AS veiculos FROM usuarios u LEFT JOIN veiculos v ON v.usuario_id = u.id GROUP BY u.id, u.nome;

-- 5) Postos abertos 24h
SELECT nome, endereco FROM postos WHERE h24 = 1;

-- 6) Chamados de SOS por tipo
SELECT tipo, COUNT(*) AS chamados FROM sos_chamados GROUP BY tipo;


-- =====================================================================
-- MÓDULO DE ESTOQUE DE PEÇAS (execute depois do script acima)
-- =====================================================================
USE felivel;
ALTER TABLE usuarios ADD COLUMN papel ENUM('cliente','admin') NOT NULL DEFAULT 'cliente';

CREATE TABLE categorias_peca (
  id     INT AUTO_INCREMENT PRIMARY KEY,
  nome   VARCHAR(60) NOT NULL UNIQUE,
  icone  VARCHAR(8),
  ordem  INT NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE pecas (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  codigo          VARCHAR(20) NOT NULL UNIQUE,
  nome            VARCHAR(120) NOT NULL,
  categoria_id    INT NOT NULL,
  descricao       TEXT,
  unidade         VARCHAR(10) NOT NULL DEFAULT 'un',
  quantidade      INT NOT NULL DEFAULT 0,
  estoque_minimo  INT NOT NULL DEFAULT 0,
  custo           DECIMAL(10,2) NOT NULL DEFAULT 0,
  preco           DECIMAL(10,2) NOT NULL DEFAULT 0,
  fornecedor      VARCHAR(120),
  localizacao     VARCHAR(30),
  CONSTRAINT ck_qtd CHECK (quantidade >= 0),
  CONSTRAINT fk_peca_cat FOREIGN KEY (categoria_id) REFERENCES categorias_peca(id)
) ENGINE=InnoDB;

CREATE TABLE movimentacoes (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  peca_id     INT NOT NULL,
  usuario_id  INT NULL,
  tipo        ENUM('ENTRADA','SAIDA','AJUSTE') NOT NULL,
  quantidade  INT NOT NULL,            -- ENTRADA positiva, SAIDA negativa, AJUSTE com sinal
  saldo_apos  INT NOT NULL,
  motivo      VARCHAR(200),
  criado      DATETIME NOT NULL,
  CONSTRAINT fk_mov_peca FOREIGN KEY (peca_id) REFERENCES pecas(id) ON DELETE CASCADE,
  CONSTRAINT fk_mov_user FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- usuário da oficina (e-mail admin@felivel.com / senha admin123 no app: troque depois)
INSERT INTO usuarios (email, nome, senha_hash, papel) VALUES ('admin@felivel.com', 'Equipe Felivel', 'scrypt:32768:8:1$qfYv6RPhxiE5w5ZX$f0e35bc573e8b02f1bdd0607ac7068e6bc65f4f35bfcabfadc699e8af6a498aa5ce393e125cc16e120bd74d3797719f92689f48d85c7bd1bfb64c6f898fee4cb', 'admin');

INSERT INTO categorias_peca (id, nome, icone, ordem) VALUES
  (1, 'Chassi e estrutura', '🏗️', 1),
  (2, 'Motor', '⚙️', 2),
  (3, 'Filtros e fluidos', '🛢️', 3),
  (4, 'Transmissão', '🕹️', 4),
  (5, 'Suspensão', '🔧', 5),
  (6, 'Freios', '🛑', 6),
  (7, 'Direção', '🎛️', 7),
  (8, 'Sistema elétrico', '⚡', 8),
  (9, 'Arrefecimento', '❄️', 9),
  (10, 'Combustível e escape', '💨', 10),
  (11, 'Rodas e pneus', '🛞', 11),
  (12, 'Carroceria e vidros', '🚪', 12),
  (13, 'Interior e segurança', '💺', 13);

INSERT INTO pecas (id, codigo, nome, categoria_id, unidade, quantidade, estoque_minimo, custo, preco, fornecedor, localizacao) VALUES
  (1, 'EST-001', 'Monobloco (carroceria base)', 1, 'un', 10, 1, 9800.0, 15190.0, 'Distribuidora Forte', 'EST-A2-P2'),
  (2, 'EST-002', 'Longarina', 1, 'un', 14, 1, 620.0, 961.0, 'Importadora Veloz', 'EST-A3-P3'),
  (3, 'EST-003', 'Subchassi dianteiro', 1, 'un', 7, 1, 1500.0, 2325.0, 'Fábrica Original', 'EST-A4-P1'),
  (4, 'EST-004', 'Reforço de assoalho', 1, 'un', 2, 1, 380.0, 589.0, 'Auto Peças Minas Ltda', 'EST-A1-P2'),
  (5, 'MOT-001', 'Bloco do motor', 2, 'un', 2, 1, 3200.0, 4960.0, 'Distribuidora Forte', 'MOT-A2-P3'),
  (6, 'MOT-002', 'Cabeçote', 2, 'un', 0, 1, 1800.0, 2790.0, 'Importadora Veloz', 'MOT-A3-P1'),
  (7, 'MOT-003', 'Junta do cabeçote', 2, 'un', 11, 4, 120.0, 186.0, 'Fábrica Original', 'MOT-A4-P2'),
  (8, 'MOT-004', 'Jogo de pistões', 2, 'jogo', 7, 2, 650.0, 1007.5, 'Auto Peças Minas Ltda', 'MOT-A1-P3'),
  (9, 'MOT-005', 'Jogo de anéis', 2, 'jogo', 0, 3, 180.0, 279.0, 'Distribuidora Forte', 'MOT-A2-P1'),
  (10, 'MOT-006', 'Virabrequim', 2, 'un', 12, 1, 1400.0, 2170.0, 'Importadora Veloz', 'MOT-A3-P2'),
  (11, 'MOT-007', 'Comando de válvulas', 2, 'un', 4, 2, 520.0, 806.0, 'Fábrica Original', 'MOT-A4-P3'),
  (12, 'MOT-008', 'Kit correia dentada', 2, 'jogo', 3, 4, 340.0, 527.0, 'Auto Peças Minas Ltda', 'MOT-A1-P1'),
  (13, 'MOT-009', 'Bomba de óleo', 2, 'un', 10, 3, 210.0, 325.5, 'Distribuidora Forte', 'MOT-A2-P2'),
  (14, 'MOT-010', 'Vela de ignição', 2, 'un', 27, 16, 35.0, 54.25, 'Importadora Veloz', 'MOT-A3-P3'),
  (15, 'FIL-001', 'Filtro de óleo', 3, 'un', 30, 20, 28.0, 43.4, 'Fábrica Original', 'FIL-A4-P1'),
  (16, 'FIL-002', 'Filtro de ar', 3, 'un', 23, 15, 45.0, 69.75, 'Auto Peças Minas Ltda', 'FIL-A1-P2'),
  (17, 'FIL-003', 'Filtro de combustível', 3, 'un', 18, 12, 52.0, 80.6, 'Distribuidora Forte', 'FIL-A2-P3'),
  (18, 'FIL-004', 'Filtro de cabine', 3, 'un', 0, 12, 38.0, 58.9, 'Importadora Veloz', 'FIL-A3-P1'),
  (19, 'FIL-005', 'Óleo de motor 5W30 (litro)', 3, 'litro', 53, 40, 42.0, 65.1, 'Fábrica Original', 'FIL-A4-P2'),
  (20, 'FIL-006', 'Fluido de freio DOT4 (500 ml)', 3, 'un', 24, 15, 26.0, 40.3, 'Auto Peças Minas Ltda', 'FIL-A1-P3'),
  (21, 'FIL-007', 'Aditivo de radiador (litro)', 3, 'litro', 32, 20, 22.0, 34.1, 'Distribuidora Forte', 'FIL-A2-P1'),
  (22, 'FIL-008', 'Fluido de direção (litro)', 3, 'litro', 22, 10, 30.0, 46.5, 'Importadora Veloz', 'FIL-A3-P2'),
  (23, 'TRA-001', 'Caixa de câmbio', 4, 'un', 2, 1, 4800.0, 7440.0, 'Fábrica Original', 'TRA-A4-P3'),
  (24, 'TRA-002', 'Kit de embreagem', 4, 'jogo', 2, 3, 680.0, 1054.0, 'Auto Peças Minas Ltda', 'TRA-A1-P1'),
  (25, 'TRA-003', 'Cabo de embreagem', 4, 'un', 7, 4, 65.0, 100.75, 'Distribuidora Forte', 'TRA-A2-P2'),
  (26, 'TRA-004', 'Semieixo', 4, 'un', 11, 2, 420.0, 651.0, 'Importadora Veloz', 'TRA-A3-P3'),
  (27, 'TRA-005', 'Junta homocinética', 4, 'un', 0, 4, 190.0, 294.5, 'Fábrica Original', 'TRA-A4-P1'),
  (28, 'TRA-006', 'Diferencial', 4, 'un', 5, 1, 1900.0, 2945.0, 'Auto Peças Minas Ltda', 'TRA-A1-P2'),
  (29, 'TRA-007', 'Óleo de câmbio (litro)', 4, 'litro', 25, 12, 55.0, 85.25, 'Distribuidora Forte', 'TRA-A2-P3'),
  (30, 'TRA-008', 'Alavanca de câmbio', 4, 'un', 1, 2, 210.0, 325.5, 'Importadora Veloz', 'TRA-A3-P1'),
  (31, 'SUS-001', 'Amortecedor dianteiro', 5, 'un', 10, 6, 290.0, 449.5, 'Fábrica Original', 'SUS-A4-P2'),
  (32, 'SUS-002', 'Amortecedor traseiro', 5, 'un', 8, 6, 240.0, 372.0, 'Auto Peças Minas Ltda', 'SUS-A1-P3'),
  (33, 'SUS-003', 'Mola helicoidal', 5, 'un', 13, 6, 180.0, 279.0, 'Distribuidora Forte', 'SUS-A2-P1'),
  (34, 'SUS-004', 'Bandeja de suspensão', 5, 'un', 11, 4, 260.0, 403.0, 'Importadora Veloz', 'SUS-A3-P2'),
  (35, 'SUS-005', 'Pivô de suspensão', 5, 'un', 11, 8, 75.0, 116.25, 'Fábrica Original', 'SUS-A4-P3'),
  (36, 'SUS-006', 'Barra estabilizadora', 5, 'un', 0, 2, 220.0, 341.0, 'Auto Peças Minas Ltda', 'SUS-A1-P1'),
  (37, 'SUS-007', 'Bucha da bandeja', 5, 'un', 27, 16, 35.0, 54.25, 'Distribuidora Forte', 'SUS-A2-P2'),
  (38, 'SUS-008', 'Coxim do amortecedor', 5, 'un', 8, 8, 90.0, 139.5, 'Importadora Veloz', 'SUS-A3-P3'),
  (39, 'FRE-001', 'Pastilha de freio dianteira', 6, 'un', 17, 10, 95.0, 147.25, 'Fábrica Original', 'FRE-A4-P1'),
  (40, 'FRE-002', 'Pastilha de freio traseira', 6, 'un', 15, 10, 80.0, 124.0, 'Auto Peças Minas Ltda', 'FRE-A1-P2'),
  (41, 'FRE-003', 'Disco de freio dianteiro', 6, 'un', 11, 6, 210.0, 325.5, 'Distribuidora Forte', 'FRE-A2-P3'),
  (42, 'FRE-004', 'Tambor de freio', 6, 'un', 3, 4, 190.0, 294.5, 'Importadora Veloz', 'FRE-A3-P1'),
  (43, 'FRE-005', 'Sapata de freio', 6, 'un', 6, 6, 110.0, 170.5, 'Fábrica Original', 'FRE-A4-P2'),
  (44, 'FRE-006', 'Cilindro mestre', 6, 'un', 12, 2, 320.0, 496.0, 'Auto Peças Minas Ltda', 'FRE-A1-P3'),
  (45, 'FRE-007', 'Pinça de freio', 6, 'un', 0, 4, 340.0, 527.0, 'Distribuidora Forte', 'FRE-A2-P1'),
  (46, 'FRE-008', 'Flexível de freio', 6, 'un', 21, 10, 45.0, 69.75, 'Importadora Veloz', 'FRE-A3-P2'),
  (47, 'FRE-009', 'Servo-freio (hidrovácuo)', 6, 'un', 2, 2, 520.0, 806.0, 'Fábrica Original', 'FRE-A4-P3'),
  (48, 'FRE-010', 'Cabo do freio de mão', 6, 'un', 3, 4, 70.0, 108.5, 'Auto Peças Minas Ltda', 'FRE-A1-P1'),
  (49, 'DIR-001', 'Caixa de direção', 7, 'un', 5, 1, 1200.0, 1860.0, 'Distribuidora Forte', 'DIR-A2-P2'),
  (50, 'DIR-002', 'Barra axial', 7, 'un', 17, 6, 95.0, 147.25, 'Importadora Veloz', 'DIR-A3-P3'),
  (51, 'DIR-003', 'Terminal de direção', 7, 'un', 18, 8, 80.0, 124.0, 'Fábrica Original', 'DIR-A4-P1'),
  (52, 'DIR-004', 'Bomba de direção hidráulica', 7, 'un', 3, 2, 680.0, 1054.0, 'Auto Peças Minas Ltda', 'DIR-A1-P2'),
  (53, 'DIR-005', 'Volante de direção', 7, 'un', 11, 2, 380.0, 589.0, 'Distribuidora Forte', 'DIR-A2-P3'),
  (54, 'DIR-006', 'Coluna de direção', 7, 'un', 0, 1, 520.0, 806.0, 'Importadora Veloz', 'DIR-A3-P1'),
  (55, 'ELE-001', 'Bateria 60Ah', 8, 'un', 11, 6, 480.0, 744.0, 'Fábrica Original', 'ELE-A4-P2'),
  (56, 'ELE-002', 'Alternador', 8, 'un', 2, 2, 780.0, 1209.0, 'Auto Peças Minas Ltda', 'ELE-A1-P3'),
  (57, 'ELE-003', 'Motor de partida', 8, 'un', 11, 2, 690.0, 1069.5, 'Distribuidora Forte', 'ELE-A2-P1'),
  (58, 'ELE-004', 'Módulo de injeção (ECU)', 8, 'un', 9, 1, 1900.0, 2945.0, 'Importadora Veloz', 'ELE-A3-P2'),
  (59, 'ELE-005', 'Chicote elétrico principal', 8, 'un', 1, 1, 950.0, 1472.5, 'Fábrica Original', 'ELE-A4-P3'),
  (60, 'ELE-006', 'Sonda lambda', 8, 'un', 3, 4, 210.0, 325.5, 'Auto Peças Minas Ltda', 'ELE-A1-P1'),
  (61, 'ELE-007', 'Sensor de temperatura', 8, 'un', 13, 6, 55.0, 85.25, 'Distribuidora Forte', 'ELE-A2-P2'),
  (62, 'ELE-008', 'Sensor de rotação', 8, 'un', 6, 4, 90.0, 139.5, 'Importadora Veloz', 'ELE-A3-P3'),
  (63, 'ELE-009', 'Relé automotivo', 8, 'un', 0, 20, 18.0, 27.9, 'Fábrica Original', 'ELE-A4-P1'),
  (64, 'ELE-010', 'Caixa de fusíveis (10 un)', 8, 'un', 24, 20, 12.0, 18.6, 'Auto Peças Minas Ltda', 'ELE-A1-P2'),
  (65, 'ELE-011', 'Farol dianteiro', 8, 'un', 9, 2, 520.0, 806.0, 'Distribuidora Forte', 'ELE-A2-P3'),
  (66, 'ELE-012', 'Lanterna traseira', 8, 'un', 1, 2, 310.0, 480.5, 'Importadora Veloz', 'ELE-A3-P1'),
  (67, 'ELE-013', 'Lâmpada H4', 8, 'un', 31, 24, 28.0, 43.4, 'Fábrica Original', 'ELE-A4-P2'),
  (68, 'ARR-001', 'Radiador', 9, 'un', 10, 2, 620.0, 961.0, 'Auto Peças Minas Ltda', 'ARR-A1-P3'),
  (69, 'ARR-002', 'Bomba d''água', 9, 'un', 8, 4, 180.0, 279.0, 'Distribuidora Forte', 'ARR-A2-P1'),
  (70, 'ARR-003', 'Válvula termostática', 9, 'un', 11, 6, 60.0, 93.0, 'Importadora Veloz', 'ARR-A3-P2'),
  (71, 'ARR-004', 'Ventoinha', 9, 'un', 4, 2, 340.0, 527.0, 'Fábrica Original', 'ARR-A4-P3'),
  (72, 'ARR-005', 'Reservatório de expansão', 9, 'un', 0, 3, 85.0, 131.75, 'Auto Peças Minas Ltda', 'ARR-A1-P1'),
  (73, 'ARR-006', 'Mangueira superior do radiador', 9, 'un', 7, 6, 45.0, 69.75, 'Distribuidora Forte', 'ARR-A2-P2'),
  (74, 'ARR-007', 'Tampa do radiador', 9, 'un', 10, 8, 25.0, 38.75, 'Importadora Veloz', 'ARR-A3-P3'),
  (75, 'COM-001', 'Tanque de combustível', 10, 'un', 5, 1, 760.0, 1178.0, 'Fábrica Original', 'COM-A4-P1'),
  (76, 'COM-002', 'Bomba de combustível', 10, 'un', 6, 3, 290.0, 449.5, 'Auto Peças Minas Ltda', 'COM-A1-P2'),
  (77, 'COM-003', 'Bico injetor', 10, 'un', 8, 8, 130.0, 201.5, 'Distribuidora Forte', 'COM-A2-P3'),
  (78, 'COM-004', 'Catalisador', 10, 'un', 1, 2, 1100.0, 1705.0, 'Importadora Veloz', 'COM-A3-P1'),
  (79, 'COM-005', 'Silencioso traseiro', 10, 'un', 10, 3, 240.0, 372.0, 'Fábrica Original', 'COM-A4-P2'),
  (80, 'COM-006', 'Tubo intermediário', 10, 'un', 15, 3, 180.0, 279.0, 'Auto Peças Minas Ltda', 'COM-A1-P3'),
  (81, 'COM-007', 'Coletor de escape', 10, 'un', 0, 2, 420.0, 651.0, 'Distribuidora Forte', 'COM-A2-P1'),
  (82, 'COM-008', 'Mangueira de combustível (metro)', 10, 'un', 21, 20, 18.0, 27.9, 'Importadora Veloz', 'COM-A3-P2'),
  (83, 'ROD-001', 'Pneu 195/55 R15', 11, 'un', 14, 12, 420.0, 651.0, 'Fábrica Original', 'ROD-A4-P3'),
  (84, 'ROD-002', 'Roda de liga 15"', 11, 'un', 3, 4, 580.0, 899.0, 'Auto Peças Minas Ltda', 'ROD-A1-P1'),
  (85, 'ROD-003', 'Parafuso de roda', 11, 'un', 48, 40, 9.0, 13.95, 'Distribuidora Forte', 'ROD-A2-P2'),
  (86, 'ROD-004', 'Estepe completo', 11, 'un', 3, 2, 380.0, 589.0, 'Importadora Veloz', 'ROD-A3-P3'),
  (87, 'ROD-005', 'Válvula de pneu (bico)', 11, 'un', 44, 40, 6.0, 9.3, 'Fábrica Original', 'ROD-A4-P1'),
  (88, 'ROD-006', 'Cubo de roda', 11, 'un', 6, 4, 260.0, 403.0, 'Auto Peças Minas Ltda', 'ROD-A1-P2'),
  (89, 'ROD-007', 'Rolamento de roda', 11, 'un', 16, 8, 120.0, 186.0, 'Distribuidora Forte', 'ROD-A2-P3'),
  (90, 'CAR-001', 'Capô', 12, 'un', 0, 1, 650.0, 1007.5, 'Importadora Veloz', 'CAR-A3-P1'),
  (91, 'CAR-002', 'Para-choque dianteiro', 12, 'un', 13, 2, 480.0, 744.0, 'Fábrica Original', 'CAR-A4-P2'),
  (92, 'CAR-003', 'Para-choque traseiro', 12, 'un', 11, 2, 450.0, 697.5, 'Auto Peças Minas Ltda', 'CAR-A1-P3'),
  (93, 'CAR-004', 'Porta dianteira', 12, 'un', 13, 2, 1100.0, 1705.0, 'Distribuidora Forte', 'CAR-A2-P1'),
  (94, 'CAR-005', 'Porta traseira', 12, 'un', 11, 2, 1000.0, 1550.0, 'Importadora Veloz', 'CAR-A3-P2'),
  (95, 'CAR-006', 'Para-brisa', 12, 'un', 12, 2, 720.0, 1116.0, 'Fábrica Original', 'CAR-A4-P3'),
  (96, 'CAR-007', 'Vidro lateral', 12, 'un', 3, 4, 280.0, 434.0, 'Auto Peças Minas Ltda', 'CAR-A1-P1'),
  (97, 'CAR-008', 'Retrovisor externo', 12, 'un', 6, 4, 190.0, 294.5, 'Distribuidora Forte', 'CAR-A2-P2'),
  (98, 'CAR-009', 'Paralama', 12, 'un', 3, 2, 340.0, 527.0, 'Importadora Veloz', 'CAR-A3-P3'),
  (99, 'CAR-010', 'Tampa do porta-malas', 12, 'un', 0, 1, 620.0, 961.0, 'Fábrica Original', 'CAR-A4-P1'),
  (100, 'CAR-011', 'Palheta de limpador (par)', 12, 'un', 18, 12, 45.0, 69.75, 'Auto Peças Minas Ltda', 'CAR-A1-P2'),
  (101, 'CAR-012', 'Motor do limpador', 12, 'un', 10, 2, 210.0, 325.5, 'Distribuidora Forte', 'CAR-A2-P3'),
  (102, 'INT-001', 'Banco dianteiro', 13, 'un', 1, 2, 900.0, 1395.0, 'Importadora Veloz', 'INT-A3-P1'),
  (103, 'INT-002', 'Banco traseiro', 13, 'un', 3, 1, 1100.0, 1705.0, 'Fábrica Original', 'INT-A4-P2'),
  (104, 'INT-003', 'Cinto de segurança', 13, 'un', 17, 6, 180.0, 279.0, 'Auto Peças Minas Ltda', 'INT-A1-P3'),
  (105, 'INT-004', 'Airbag do motorista', 13, 'un', 4, 1, 1500.0, 2325.0, 'Distribuidora Forte', 'INT-A2-P1'),
  (106, 'INT-005', 'Painel de instrumentos', 13, 'un', 8, 1, 1400.0, 2170.0, 'Importadora Veloz', 'INT-A3-P2'),
  (107, 'INT-006', 'Compressor do ar-condicionado', 13, 'un', 3, 1, 1300.0, 2015.0, 'Fábrica Original', 'INT-A4-P3'),
  (108, 'INT-007', 'Condensador do ar-condicionado', 13, 'un', 0, 1, 520.0, 806.0, 'Auto Peças Minas Ltda', 'INT-A1-P1'),
  (109, 'INT-008', 'Carpete', 13, 'un', 9, 1, 380.0, 589.0, 'Distribuidora Forte', 'INT-A2-P2'),
  (110, 'INT-009', 'Jogo de tapetes', 13, 'jogo', 14, 6, 90.0, 139.5, 'Importadora Veloz', 'INT-A3-P3'),
  (111, 'INT-010', 'Central multimídia', 13, 'un', 4, 2, 900.0, 1395.0, 'Fábrica Original', 'INT-A4-P1'),
  (112, 'INT-011', 'Chave com controle', 13, 'un', 7, 3, 260.0, 403.0, 'Auto Peças Minas Ltda', 'INT-A1-P2');

INSERT INTO movimentacoes (id, peca_id, usuario_id, tipo, quantidade, saldo_apos, motivo, criado) VALUES
  (1, 1, NULL, 'ENTRADA', 10, 10, 'Estoque inicial', '2026-11-21 23:57'),
  (2, 2, NULL, 'ENTRADA', 14, 14, 'Estoque inicial', '2026-11-21 23:57'),
  (3, 3, NULL, 'ENTRADA', 7, 7, 'Estoque inicial', '2026-11-21 23:57'),
  (4, 4, NULL, 'ENTRADA', 2, 2, 'Estoque inicial', '2026-11-21 23:57'),
  (5, 5, NULL, 'ENTRADA', 2, 2, 'Estoque inicial', '2026-11-21 23:57'),
  (6, 7, NULL, 'ENTRADA', 11, 11, 'Estoque inicial', '2026-11-21 23:57'),
  (7, 8, NULL, 'ENTRADA', 7, 7, 'Estoque inicial', '2026-11-21 23:57'),
  (8, 10, NULL, 'ENTRADA', 12, 12, 'Estoque inicial', '2026-11-21 23:57'),
  (9, 11, NULL, 'ENTRADA', 4, 4, 'Estoque inicial', '2026-11-21 23:57'),
  (10, 12, NULL, 'ENTRADA', 3, 3, 'Estoque inicial', '2026-11-21 23:57'),
  (11, 13, NULL, 'ENTRADA', 10, 10, 'Estoque inicial', '2026-11-21 23:57'),
  (12, 14, NULL, 'ENTRADA', 27, 27, 'Estoque inicial', '2026-11-21 23:57'),
  (13, 15, NULL, 'ENTRADA', 30, 30, 'Estoque inicial', '2026-11-21 23:57'),
  (14, 16, NULL, 'ENTRADA', 23, 23, 'Estoque inicial', '2026-11-21 23:57'),
  (15, 17, NULL, 'ENTRADA', 18, 18, 'Estoque inicial', '2026-11-21 23:57'),
  (16, 19, NULL, 'ENTRADA', 53, 53, 'Estoque inicial', '2026-11-21 23:57'),
  (17, 20, NULL, 'ENTRADA', 24, 24, 'Estoque inicial', '2026-11-21 23:57'),
  (18, 21, NULL, 'ENTRADA', 32, 32, 'Estoque inicial', '2026-11-21 23:57'),
  (19, 22, NULL, 'ENTRADA', 22, 22, 'Estoque inicial', '2026-11-21 23:57'),
  (20, 23, NULL, 'ENTRADA', 2, 2, 'Estoque inicial', '2026-11-21 23:57'),
  (21, 24, NULL, 'ENTRADA', 2, 2, 'Estoque inicial', '2026-11-21 23:57'),
  (22, 25, NULL, 'ENTRADA', 7, 7, 'Estoque inicial', '2026-11-21 23:57'),
  (23, 26, NULL, 'ENTRADA', 11, 11, 'Estoque inicial', '2026-11-21 23:57'),
  (24, 28, NULL, 'ENTRADA', 5, 5, 'Estoque inicial', '2026-11-21 23:57'),
  (25, 29, NULL, 'ENTRADA', 25, 25, 'Estoque inicial', '2026-11-21 23:57'),
  (26, 30, NULL, 'ENTRADA', 1, 1, 'Estoque inicial', '2026-11-21 23:57'),
  (27, 31, NULL, 'ENTRADA', 10, 10, 'Estoque inicial', '2026-11-21 23:57'),
  (28, 32, NULL, 'ENTRADA', 8, 8, 'Estoque inicial', '2026-11-21 23:57'),
  (29, 33, NULL, 'ENTRADA', 13, 13, 'Estoque inicial', '2026-11-21 23:57'),
  (30, 34, NULL, 'ENTRADA', 11, 11, 'Estoque inicial', '2026-11-21 23:57'),
  (31, 35, NULL, 'ENTRADA', 11, 11, 'Estoque inicial', '2026-11-21 23:57'),
  (32, 37, NULL, 'ENTRADA', 27, 27, 'Estoque inicial', '2026-11-21 23:57'),
  (33, 38, NULL, 'ENTRADA', 8, 8, 'Estoque inicial', '2026-11-21 23:57'),
  (34, 39, NULL, 'ENTRADA', 17, 17, 'Estoque inicial', '2026-11-21 23:57'),
  (35, 40, NULL, 'ENTRADA', 15, 15, 'Estoque inicial', '2026-11-21 23:57'),
  (36, 41, NULL, 'ENTRADA', 11, 11, 'Estoque inicial', '2026-11-21 23:57'),
  (37, 42, NULL, 'ENTRADA', 3, 3, 'Estoque inicial', '2026-11-21 23:57'),
  (38, 43, NULL, 'ENTRADA', 6, 6, 'Estoque inicial', '2026-11-21 23:57'),
  (39, 44, NULL, 'ENTRADA', 12, 12, 'Estoque inicial', '2026-11-21 23:57'),
  (40, 46, NULL, 'ENTRADA', 21, 21, 'Estoque inicial', '2026-11-21 23:57'),
  (41, 47, NULL, 'ENTRADA', 2, 2, 'Estoque inicial', '2026-11-21 23:57'),
  (42, 48, NULL, 'ENTRADA', 3, 3, 'Estoque inicial', '2026-11-21 23:57'),
  (43, 49, NULL, 'ENTRADA', 5, 5, 'Estoque inicial', '2026-11-21 23:57'),
  (44, 50, NULL, 'ENTRADA', 17, 17, 'Estoque inicial', '2026-11-21 23:57'),
  (45, 51, NULL, 'ENTRADA', 18, 18, 'Estoque inicial', '2026-11-21 23:57'),
  (46, 52, NULL, 'ENTRADA', 3, 3, 'Estoque inicial', '2026-11-21 23:57'),
  (47, 53, NULL, 'ENTRADA', 11, 11, 'Estoque inicial', '2026-11-21 23:57'),
  (48, 55, NULL, 'ENTRADA', 11, 11, 'Estoque inicial', '2026-11-21 23:57'),
  (49, 56, NULL, 'ENTRADA', 2, 2, 'Estoque inicial', '2026-11-21 23:57'),
  (50, 57, NULL, 'ENTRADA', 11, 11, 'Estoque inicial', '2026-11-21 23:57'),
  (51, 58, NULL, 'ENTRADA', 9, 9, 'Estoque inicial', '2026-11-21 23:57'),
  (52, 59, NULL, 'ENTRADA', 1, 1, 'Estoque inicial', '2026-11-21 23:57'),
  (53, 60, NULL, 'ENTRADA', 3, 3, 'Estoque inicial', '2026-11-21 23:57'),
  (54, 61, NULL, 'ENTRADA', 13, 13, 'Estoque inicial', '2026-11-21 23:57'),
  (55, 62, NULL, 'ENTRADA', 6, 6, 'Estoque inicial', '2026-11-21 23:57'),
  (56, 64, NULL, 'ENTRADA', 24, 24, 'Estoque inicial', '2026-11-21 23:57'),
  (57, 65, NULL, 'ENTRADA', 9, 9, 'Estoque inicial', '2026-11-21 23:57'),
  (58, 66, NULL, 'ENTRADA', 1, 1, 'Estoque inicial', '2026-11-21 23:57'),
  (59, 67, NULL, 'ENTRADA', 31, 31, 'Estoque inicial', '2026-11-21 23:57'),
  (60, 68, NULL, 'ENTRADA', 10, 10, 'Estoque inicial', '2026-11-21 23:57'),
  (61, 69, NULL, 'ENTRADA', 8, 8, 'Estoque inicial', '2026-11-21 23:57'),
  (62, 70, NULL, 'ENTRADA', 11, 11, 'Estoque inicial', '2026-11-21 23:57'),
  (63, 71, NULL, 'ENTRADA', 4, 4, 'Estoque inicial', '2026-11-21 23:57'),
  (64, 73, NULL, 'ENTRADA', 7, 7, 'Estoque inicial', '2026-11-21 23:57'),
  (65, 74, NULL, 'ENTRADA', 10, 10, 'Estoque inicial', '2026-11-21 23:57'),
  (66, 75, NULL, 'ENTRADA', 5, 5, 'Estoque inicial', '2026-11-21 23:57'),
  (67, 76, NULL, 'ENTRADA', 6, 6, 'Estoque inicial', '2026-11-21 23:57'),
  (68, 77, NULL, 'ENTRADA', 8, 8, 'Estoque inicial', '2026-11-21 23:57'),
  (69, 78, NULL, 'ENTRADA', 1, 1, 'Estoque inicial', '2026-11-21 23:57'),
  (70, 79, NULL, 'ENTRADA', 10, 10, 'Estoque inicial', '2026-11-21 23:57'),
  (71, 80, NULL, 'ENTRADA', 15, 15, 'Estoque inicial', '2026-11-21 23:57'),
  (72, 82, NULL, 'ENTRADA', 21, 21, 'Estoque inicial', '2026-11-21 23:57'),
  (73, 83, NULL, 'ENTRADA', 14, 14, 'Estoque inicial', '2026-11-21 23:57'),
  (74, 84, NULL, 'ENTRADA', 3, 3, 'Estoque inicial', '2026-11-21 23:57'),
  (75, 85, NULL, 'ENTRADA', 48, 48, 'Estoque inicial', '2026-11-21 23:57'),
  (76, 86, NULL, 'ENTRADA', 3, 3, 'Estoque inicial', '2026-11-21 23:57'),
  (77, 87, NULL, 'ENTRADA', 44, 44, 'Estoque inicial', '2026-11-21 23:57'),
  (78, 88, NULL, 'ENTRADA', 6, 6, 'Estoque inicial', '2026-11-21 23:57'),
  (79, 89, NULL, 'ENTRADA', 16, 16, 'Estoque inicial', '2026-11-21 23:57'),
  (80, 91, NULL, 'ENTRADA', 13, 13, 'Estoque inicial', '2026-11-21 23:57'),
  (81, 92, NULL, 'ENTRADA', 11, 11, 'Estoque inicial', '2026-11-21 23:57'),
  (82, 93, NULL, 'ENTRADA', 13, 13, 'Estoque inicial', '2026-11-21 23:57'),
  (83, 94, NULL, 'ENTRADA', 11, 11, 'Estoque inicial', '2026-11-21 23:57'),
  (84, 95, NULL, 'ENTRADA', 12, 12, 'Estoque inicial', '2026-11-21 23:57'),
  (85, 96, NULL, 'ENTRADA', 3, 3, 'Estoque inicial', '2026-11-21 23:57'),
  (86, 97, NULL, 'ENTRADA', 6, 6, 'Estoque inicial', '2026-11-21 23:57'),
  (87, 98, NULL, 'ENTRADA', 3, 3, 'Estoque inicial', '2026-11-21 23:57'),
  (88, 100, NULL, 'ENTRADA', 18, 18, 'Estoque inicial', '2026-11-21 23:57'),
  (89, 101, NULL, 'ENTRADA', 10, 10, 'Estoque inicial', '2026-11-21 23:57'),
  (90, 102, NULL, 'ENTRADA', 1, 1, 'Estoque inicial', '2026-11-21 23:57'),
  (91, 103, NULL, 'ENTRADA', 3, 3, 'Estoque inicial', '2026-11-21 23:57'),
  (92, 104, NULL, 'ENTRADA', 17, 17, 'Estoque inicial', '2026-11-21 23:57'),
  (93, 105, NULL, 'ENTRADA', 4, 4, 'Estoque inicial', '2026-11-21 23:57'),
  (94, 106, NULL, 'ENTRADA', 8, 8, 'Estoque inicial', '2026-11-21 23:57'),
  (95, 107, NULL, 'ENTRADA', 3, 3, 'Estoque inicial', '2026-11-21 23:57'),
  (96, 109, NULL, 'ENTRADA', 9, 9, 'Estoque inicial', '2026-11-21 23:57'),
  (97, 110, NULL, 'ENTRADA', 14, 14, 'Estoque inicial', '2026-11-21 23:57'),
  (98, 111, NULL, 'ENTRADA', 4, 4, 'Estoque inicial', '2026-11-21 23:57'),
  (99, 112, NULL, 'ENTRADA', 7, 7, 'Estoque inicial', '2026-11-21 23:57');

-- ------------------------------- consultas do estoque -------------------------------
-- 7) Peças abaixo do estoque mínimo (lista de compra)
SELECT p.codigo, p.nome, c.nome AS sistema, p.quantidade, p.estoque_minimo, (p.estoque_minimo - p.quantidade) AS faltam
FROM pecas p JOIN categorias_peca c ON c.id = p.categoria_id
WHERE p.quantidade < p.estoque_minimo ORDER BY faltam DESC;

-- 8) Valor em estoque por sistema do carro
SELECT c.nome AS sistema, COUNT(*) AS pecas, SUM(p.quantidade) AS unidades, SUM(p.quantidade * p.custo) AS valor_custo
FROM categorias_peca c JOIN pecas p ON p.categoria_id = c.id
GROUP BY c.id, c.nome ORDER BY valor_custo DESC;

-- 9) Histórico de movimentações de uma peça
SELECT m.criado, m.tipo, m.quantidade, m.saldo_apos, m.motivo
FROM movimentacoes m JOIN pecas p ON p.id = m.peca_id WHERE p.codigo = 'MOT-003' ORDER BY m.id DESC;

-- 10) Peças zeradas
SELECT codigo, nome, fornecedor FROM pecas WHERE quantidade = 0;


-- =====================================================================
-- MÃO DE OBRA SEPARADA DAS PEÇAS (execute depois dos scripts acima)
-- =====================================================================
USE felivel;
ALTER TABLE servicos ADD COLUMN mao_de_obra DECIMAL(10,2) NOT NULL DEFAULT 0;

CREATE TABLE servico_pecas (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  servico_id  INT NOT NULL,
  peca_id     INT NOT NULL,
  quantidade  INT NOT NULL,
  preco_unit  DECIMAL(10,2) NOT NULL,          -- preço da peça no momento do serviço
  UNIQUE KEY ux_servico_peca (servico_id, peca_id),
  CONSTRAINT ck_sp_qtd CHECK (quantidade > 0),
  CONSTRAINT fk_sp_serv FOREIGN KEY (servico_id) REFERENCES servicos(id) ON DELETE CASCADE,
  CONSTRAINT fk_sp_peca FOREIGN KEY (peca_id) REFERENCES pecas(id)
) ENGINE=InnoDB;

UPDATE servicos SET mao_de_obra = 60.0 WHERE id = 1;
UPDATE servicos SET mao_de_obra = 150.0 WHERE id = 2;
UPDATE servicos SET mao_de_obra = 60.0 WHERE id = 3;
UPDATE servicos SET mao_de_obra = 280.0 WHERE id = 4;
UPDATE servicos SET mao_de_obra = 60.0 WHERE id = 5;

INSERT INTO servico_pecas (id, servico_id, peca_id, quantidade, preco_unit) VALUES
  (1, 1, 19, 4, 65.1),
  (2, 1, 15, 1, 43.4),
  (3, 3, 55, 1, 744.0),
  (4, 4, 15, 1, 43.4),
  (5, 4, 16, 1, 69.75),
  (6, 4, 17, 1, 80.6),
  (7, 4, 18, 1, 58.9),
  (8, 4, 19, 4, 65.1),
  (9, 4, 14, 4, 54.25),
  (10, 5, 19, 4, 65.1),
  (11, 5, 15, 1, 43.4);

-- ------------------------------- consultas: mão de obra x peças -------------------------------
-- 11) Valor de cada serviço, separando mão de obra e peças
SELECT s.id, s.servico, s.data, s.status, s.mao_de_obra,
       COALESCE(SUM(sp.quantidade * sp.preco_unit), 0) AS total_pecas,
       s.mao_de_obra + COALESCE(SUM(sp.quantidade * sp.preco_unit), 0) AS total
FROM servicos s LEFT JOIN servico_pecas sp ON sp.servico_id = s.id
GROUP BY s.id, s.servico, s.data, s.status, s.mao_de_obra ORDER BY s.id;

-- 12) Peças usadas em um serviço
SELECT p.codigo, p.nome, sp.quantidade, sp.preco_unit, sp.quantidade * sp.preco_unit AS subtotal
FROM servico_pecas sp JOIN pecas p ON p.id = sp.peca_id WHERE sp.servico_id = 1;

-- 13) Faturamento dos serviços concluídos: mão de obra x peças
SELECT SUM(s.mao_de_obra) AS mao_de_obra,
       (SELECT SUM(sp.quantidade * sp.preco_unit) FROM servico_pecas sp JOIN servicos s2 ON s2.id = sp.servico_id WHERE s2.status = 'Concluído') AS pecas
FROM servicos s WHERE s.status = 'Concluído';

-- 14) Peças mais usadas nos serviços
SELECT p.nome, SUM(sp.quantidade) AS total_usado
FROM servico_pecas sp JOIN pecas p ON p.id = sp.peca_id GROUP BY p.id, p.nome ORDER BY total_usado DESC;
