"""
Felivel Center - Premium Performance
Rodar:  pip install -r requirements.txt  &&  python app.py   ->  http://127.0.0.1:8030
Login de demonstração: joao@email.com / 12345678
"""
from flask import Flask
from routes import registrar
from db import fechar, init_db
from utils import br, moeda, contexto


def create_app():
    app = Flask(__name__)
    app.secret_key = "troque-esta-chave"
    app.add_template_filter(br, "br")
    app.add_template_filter(moeda, "moeda")
    app.context_processor(contexto)
    init_db()                          
    app.teardown_appcontext(fechar)
    registrar(app)  
    return app


app = create_app()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8030, debug=True) 
