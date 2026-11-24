"""Fronteira Firestore em memória: nunca importa credenciais nem toca a rede."""
import copy
import sys
import types
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))


class Snapshot:
    def __init__(self, reference):
        self.reference = reference
        self.id = reference.id
        self.exists = reference.key in reference.db.data
        self.data = copy.deepcopy(reference.db.data.get(reference.key, {}))

    def to_dict(self):
        return copy.deepcopy(self.data)


class Reference:
    def __init__(self, db, collection, identifier):
        self.db, self.collection, self.id = db, collection, identifier
        self.key = (collection, identifier)

    def get(self, **kwargs):
        return Snapshot(self)

    def set(self, data):
        self.db.data[self.key] = copy.deepcopy(data)

    def update(self, data):
        self.db.data[self.key].update(data)

    def delete(self):
        self.db.data.pop(self.key, None)


class Query:
    def __init__(self, db, collection, filters=(), count=None):
        self.db, self.collection, self.filters, self.count = db, collection, filters, count

    def document(self, identifier=None):
        if identifier is None:
            identifier = 'generated-' + str(len(self.db.data))
        return Reference(self.db, self.collection, identifier)

    def where(self, field=None, operator=None, value=None, *, filter=None):
        if filter is not None:
            field, value = filter.field_path, filter.value
            operator = getattr(filter, 'op_string', '==')
        return Query(self.db, self.collection, self.filters + ((field, operator or '==', value),), self.count)

    def limit(self, count):
        return Query(self.db, self.collection, self.filters, count)

    def stream(self):
        docs = [Reference(self.db, collection, identifier).get()
                for (collection, identifier), data in list(self.db.data.items())
                if collection == self.collection and all(
                    data.get(field) in value if operator == 'in' else data.get(field) == value
                    for field, operator, value in self.filters)]
        return iter(docs[:self.count] if self.count else docs)

    def get(self):
        return list(self.stream())


class Batch:
    def __init__(self):
        self.operations = []

    def delete(self, reference):
        self.operations.append(reference.delete)

    def commit(self):
        for operation in self.operations:
            operation()

    def set(self, reference, data):
        self.operations.append(lambda: reference.set(data))

    def update(self, reference, data):
        self.operations.append(lambda: reference.update(data))


class FakeDB:
    def __init__(self):
        self.data = {}

    def collection(self, name):
        return Query(self, name)

    def batch(self):
        return Batch()

    def transaction(self):
        return Batch()


@pytest.fixture
def db(monkeypatch):
    database = FakeDB()
    monkeypatch.setitem(sys.modules, 'firebase_config', types.SimpleNamespace(db=database))
    return database


@pytest.fixture
def transactions(monkeypatch):
    from google.cloud import firestore

    def decorate(function):
        def wrapped(transaction, *args, **kwargs):
            result = function(transaction, *args, **kwargs)
            transaction.commit()
            return result
        return wrapped
    monkeypatch.setattr(firestore, 'transactional', decorate)
