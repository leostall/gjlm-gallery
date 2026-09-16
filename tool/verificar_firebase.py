"""Verifica Auth e Firestore reais com conta temporária; remove dados ao terminar."""
import json
import re
import secrets
import ssl
import urllib.error
import urllib.request
from pathlib import Path

options = Path('lib/firebase_options.dart').read_text()
api_key = re.search(r"web = FirebaseOptions\(\s*apiKey: '([^']+)'", options)[1]
project = re.search(r"projectId: '([^']+)'", options)[1]
email = f'auditoria-{secrets.token_hex(8)}@example.invalid'
password = secrets.token_urlsafe(24)
base = f'https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents'
token = None
uid = None
saved = []

def request(url, data=None, method=None, bearer=None):
    headers = {'Content-Type': 'application/json'}
    if bearer:
        headers['Authorization'] = f'Bearer {bearer}'
    req = urllib.request.Request(url, data=None if data is None else json.dumps(data).encode(), headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=25, context=ssl.create_default_context(cafile='/etc/ssl/cert.pem')) as response:
            content = response.read()
            return json.loads(content) if content else {}
    except urllib.error.HTTPError as error:
        content = json.loads(error.read())
        # Não imprime tokens, senha, e-mail nem documentos de usuários reais.
        detail = content.get('error', {})
        raise RuntimeError(f'HTTP {error.code}: {detail.get("message", "falha de comunicação")}') from None

def auth(action, data):
    return request(f'https://identitytoolkit.googleapis.com/v1/accounts:{action}?key={api_key}', data)

try:
    account = auth('signUp', {'email': email, 'password': password, 'returnSecureToken': True})
    token, uid = account['idToken'], account['localId']
    print('PASS: cadastro real com Firebase Auth')
    account = auth('signInWithPassword', {'email': email, 'password': password, 'returnSecureToken': True})
    token = account['idToken']
    assert account['localId'] == uid
    print('PASS: login com e-mail/senha mantém UID')
    for collection in ['favoritos', 'vistos']:
        url = f'{base}/usuarios/{uid}/{collection}/999999999'
        request(url, {'fields': {'id': {'integerValue': '999999999'}, 'titulo': {'stringValue': 'Auditoria temporária'}}}, method='PATCH', bearer=token)
        saved.append(url)
        doc = request(url, bearer=token)
        assert doc['fields']['id']['integerValue'] == '999999999'
        # Uma nova sessão deve recuperar o mesmo documento.
        second = auth('signInWithPassword', {'email': email, 'password': password, 'returnSecureToken': True})
        assert request(url, bearer=second['idToken'])['fields'] == doc['fields']
        try:
            request(url)
        except RuntimeError as error:
            assert 'HTTP 403' in str(error)
        else:
            raise AssertionError('Documento acessível sem autenticação')
        print(f'PASS: {collection} grava, lê em nova sessão e bloqueia acesso anônimo')
    try:
        request(f'{base}/usuarios/outro-usuario-auditoria/favoritos/999999999', bearer=token)
    except RuntimeError as error:
        assert 'HTTP 403' in str(error)
    else:
        raise AssertionError('Acesso de outro usuário não foi bloqueado')
    print('PASS: isolamento entre usuários')
finally:
    for url in saved:
        request(url, method='DELETE', bearer=token)
    if token:
        auth('delete', {'idToken': token})
        print('PASS: documentos e conta temporários removidos')
