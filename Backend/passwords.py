"""Política compartilhada, preservando espaços e evitando truncamento do bcrypt."""
import bcrypt


def validate_new_password(value: str) -> str:
    if len(value) < 8 or len(value.encode("utf-8")) > 72:
        raise ValueError("A senha deve ter pelo menos 8 caracteres e no máximo 72 bytes UTF-8.")
    return value


def hash_password(value: str) -> str:
    validate_new_password(value)
    return bcrypt.hashpw(value.encode("utf-8"), bcrypt.gensalt(rounds=12)).decode("utf-8")
