"""Nenhuma suíte pode inicializar credenciais ou acessar o Firestore real."""
import sys
import types

sys.modules['firebase_config'] = types.SimpleNamespace(db=None)
