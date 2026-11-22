

MAPA_CENTRO = [-19.9208, -43.9378]
HORARIOS = ["08:00", "09:00", "10:00", "11:00", "13:00", "14:00", "15:00", "16:00", "17:00"]
CATALOGO = {   # mao_de_obra (R$) é cobrada à parte; "pecas" = kit previsto: (código da peça, quantidade)
    "oleo": {"nome": "Troca de óleo", "icone": "🛢️", "duracao": "45 min", "mao_de_obra": 60, "pecas": [("FIL-005", 4), ("FIL-001", 1)]},
    "alinhamento": {"nome": "Alinhamento e balanceamento", "icone": "⚙️", "duracao": "1h 30min", "mao_de_obra": 150, "pecas": []},
    "bateria": {"nome": "Troca de bateria", "icone": "🔋", "duracao": "30 min", "mao_de_obra": 60, "pecas": [("ELE-001", 1)]},
    "revisao": {"nome": "Revisão geral", "icone": "🔧", "duracao": "3h", "mao_de_obra": 280,
                "pecas": [("FIL-001", 1), ("FIL-002", 1), ("FIL-003", 1), ("FIL-004", 1), ("FIL-005", 4), ("MOT-010", 4)]},
}
LEGADO_VALOR = {"oleo": 280, "alinhamento": 150, "bateria": 480, "revisao": 620}  # valores antigos (só usados para migrar bancos antigos)
SOS_TEL = "(31) 3000-0000"      # telefone da central de socorro
SOS_WHATS = "5531930000000"     # WhatsApp da central (DDI+DDD+número)
SOS_TIPOS = {
    "guincho": {"nome": "Guincho", "icone": "🚛", "desc": "Reboque até a oficina", "prazo": "30 a 60 min"},
    "pneu": {"nome": "Troca de pneu", "icone": "🛞", "desc": "Pneu furado ou estourado", "prazo": "20 a 40 min"},
    "bateria": {"nome": "Bateria", "icone": "🔋", "desc": "Carro não liga / pane elétrica", "prazo": "20 a 40 min"},
}

# ---- dados iniciais (inseridos só quando o banco está vazio) ----
USUARIO_DEMO = {"email": "joao@email.com", "nome": "João Fernandes", "senha": "12345678", "telefone": "(31) 99999-1234",
                "cpf": "123.456.789-00", "nascimento": "1990-05-14", "cidade": "Belo Horizonte - MG", "desde": "2023-03-10"}
VEICULOS_SEED = [
    {"chave": 1, "modelo": "Volkswagen Polo", "ano": 2024, "placa": "ABC-1234", "cor": "Prata", "principal": 1, "emoji": "🚙"},
    {"chave": 2, "modelo": "Toyota Corolla", "ano": 2022, "placa": "DEF-5678", "cor": "Branco", "principal": 0, "emoji": "🚘"},
]
SERVICOS_SEED = [
    {"servico": "oleo", "veiculo": 1, "data": "2026-06-15", "status": "Concluído"},
    {"servico": "alinhamento", "veiculo": 1, "data": "2026-04-20", "status": "Concluído"},
    {"servico": "bateria", "veiculo": 1, "data": "2026-01-10", "status": "Concluído"},
    {"servico": "revisao", "veiculo": 2, "data": "2026-08-02", "status": "Concluído"},
    {"servico": "oleo", "veiculo": 1, "data": "2026-09-28", "hora": "14:00", "status": "Agendado"},
]
# EXEMPLOS: troque pelos postos parceiros reais
POSTOS_SEED = [
    ("Posto Parceiro Centro", "Praça Sete de Setembro, Centro", -19.9208, -43.9378, 1, "Calibragem,Conveniência"),
    ("Posto Parceiro Savassi", "Av. do Contorno, Savassi", -19.9391, -43.9340, 0, "Calibragem,Lava-rápido"),
    ("Posto Parceiro Pampulha", "Av. Otacílio Negrão de Lima, Pampulha", -19.8517, -43.9667, 1, "Conveniência,Troca de óleo"),
    ("Posto Parceiro Buritis", "Av. Professor Mário Werneck, Buritis", -19.9744, -43.9602, 0, "Calibragem"),
    ("Posto Parceiro Barro Preto", "Av. Augusto de Lima, Barro Preto", -19.9261, -43.9505, 1, "Calibragem,Conveniência,Lava-rápido"),
]


# ================= ESTOQUE DE PEÇAS =================
ADMIN_DEMO = {"email": "admin@felivel.com", "nome": "Equipe Felivel", "senha": "admin123"}  # troque a senha!
FORNECEDORES = ["Auto Peças Minas Ltda", "Distribuidora Forte", "Importadora Veloz", "Fábrica Original"]  # exemplos
# (prefixo do código, sistema, ícone, "peça|custo|estoque mínimo") - lista-base de um carro montado do zero.
# Custos e fornecedores são EXEMPLOS: ajuste para a realidade da oficina.
SISTEMAS = [
    ("EST", "Chassi e estrutura", "🏗️", """Monobloco (carroceria base)|9800|1
Longarina|620|1
Subchassi dianteiro|1500|1
Reforço de assoalho|380|1""".split("\n")),
    ("MOT", "Motor", "⚙️", """Bloco do motor|3200|1
Cabeçote|1800|1
Junta do cabeçote|120|4
Jogo de pistões|650|2
Jogo de anéis|180|3
Virabrequim|1400|1
Comando de válvulas|520|2
Kit correia dentada|340|4
Bomba de óleo|210|3
Vela de ignição|35|16""".split("\n")),
    ("FIL", "Filtros e fluidos", "🛢️", """Filtro de óleo|28|20
Filtro de ar|45|15
Filtro de combustível|52|12
Filtro de cabine|38|12
Óleo de motor 5W30 (litro)|42|40
Fluido de freio DOT4 (500 ml)|26|15
Aditivo de radiador (litro)|22|20
Fluido de direção (litro)|30|10""".split("\n")),
    ("TRA", "Transmissão", "🕹️", """Caixa de câmbio|4800|1
Kit de embreagem|680|3
Cabo de embreagem|65|4
Semieixo|420|2
Junta homocinética|190|4
Diferencial|1900|1
Óleo de câmbio (litro)|55|12
Alavanca de câmbio|210|2""".split("\n")),
    ("SUS", "Suspensão", "🔧", """Amortecedor dianteiro|290|6
Amortecedor traseiro|240|6
Mola helicoidal|180|6
Bandeja de suspensão|260|4
Pivô de suspensão|75|8
Barra estabilizadora|220|2
Bucha da bandeja|35|16
Coxim do amortecedor|90|8""".split("\n")),
    ("FRE", "Freios", "🛑", """Pastilha de freio dianteira|95|10
Pastilha de freio traseira|80|10
Disco de freio dianteiro|210|6
Tambor de freio|190|4
Sapata de freio|110|6
Cilindro mestre|320|2
Pinça de freio|340|4
Flexível de freio|45|10
Servo-freio (hidrovácuo)|520|2
Cabo do freio de mão|70|4""".split("\n")),
    ("DIR", "Direção", "🎛️", """Caixa de direção|1200|1
Barra axial|95|6
Terminal de direção|80|8
Bomba de direção hidráulica|680|2
Volante de direção|380|2
Coluna de direção|520|1""".split("\n")),
    ("ELE", "Sistema elétrico", "⚡", """Bateria 60Ah|480|6
Alternador|780|2
Motor de partida|690|2
Módulo de injeção (ECU)|1900|1
Chicote elétrico principal|950|1
Sonda lambda|210|4
Sensor de temperatura|55|6
Sensor de rotação|90|4
Relé automotivo|18|20
Caixa de fusíveis (10 un)|12|20
Farol dianteiro|520|2
Lanterna traseira|310|2
Lâmpada H4|28|24""".split("\n")),
    ("ARR", "Arrefecimento", "❄️", """Radiador|620|2
Bomba d'água|180|4
Válvula termostática|60|6
Ventoinha|340|2
Reservatório de expansão|85|3
Mangueira superior do radiador|45|6
Tampa do radiador|25|8""".split("\n")),
    ("COM", "Combustível e escape", "💨", """Tanque de combustível|760|1
Bomba de combustível|290|3
Bico injetor|130|8
Catalisador|1100|2
Silencioso traseiro|240|3
Tubo intermediário|180|3
Coletor de escape|420|2
Mangueira de combustível (metro)|18|20""".split("\n")),
    ("ROD", "Rodas e pneus", "🛞", """Pneu 195/55 R15|420|12
Roda de liga 15"|580|4
Parafuso de roda|9|40
Estepe completo|380|2
Válvula de pneu (bico)|6|40
Cubo de roda|260|4
Rolamento de roda|120|8""".split("\n")),
    ("CAR", "Carroceria e vidros", "🚪", """Capô|650|1
Para-choque dianteiro|480|2
Para-choque traseiro|450|2
Porta dianteira|1100|2
Porta traseira|1000|2
Para-brisa|720|2
Vidro lateral|280|4
Retrovisor externo|190|4
Paralama|340|2
Tampa do porta-malas|620|1
Palheta de limpador (par)|45|12
Motor do limpador|210|2""".split("\n")),
    ("INT", "Interior e segurança", "💺", """Banco dianteiro|900|2
Banco traseiro|1100|1
Cinto de segurança|180|6
Airbag do motorista|1500|1
Painel de instrumentos|1400|1
Compressor do ar-condicionado|1300|1
Condensador do ar-condicionado|520|1
Carpete|380|1
Jogo de tapetes|90|6
Central multimídia|900|2
Chave com controle|260|3""".split("\n")),
]
