# Firebase da atividade

O projeto **gjlm-gallery já está configurado** em `lib/firebase_options.dart`.
Firebase Auth por e-mail/senha e o Firestore `(default)` foram verificados
contra o serviço real. O banco está em `southamerica-east1`.

A versão a apresentar é a web, no Chrome:

```bash
flutter run -d chrome
```

Favoritos e obras vistas são armazenados localmente e sincronizados em
`usuarios/{uid}/favoritos` e `usuarios/{uid}/vistos`. Alterações que não chegam
à nuvem ficam pendentes no aparelho e são reenviadas na próxima entrada ou
reinicialização. As regras em `firestore.rules` restringem o acesso ao dono.

## Repetir a verificação real

```bash
python3 tool/verificar_firebase.py
```

O script cria uma conta temporária, autentica, grava e lê as duas coleções,
repete a leitura em uma nova sessão, verifica o bloqueio de acessos indevidos
e remove os documentos e a conta. Requer internet; não imprime credenciais.

## Se mudar de projeto

Use `flutterfire configure`, habilite E-mail/senha no Firebase Authentication,
crie o banco Firestore e publique as regras:

```bash
firebase deploy --only firestore:rules --project SEU_PROJETO
```

Para uma hospedagem web própria, confira também os domínios autorizados no
Firebase Authentication. Quando a inicialização do Firebase não é possível,
o app informa o modo local; **nesse modo os bônus não estão ativos**.

## Plataformas Apple nativas

O Chrome não depende de assinatura Apple. O aplicativo macOS nativo precisa
de Keychain Sharing e de assinatura de desenvolvimento configuradas no Xcode
para autenticação Firebase. O computador usado nesta revisão não possui
certificado válido; não foi certificada a execução nativa em macOS/iOS.
Os entitlements de debug e release permitem conexões de rede de saída.

Referência: [configuração oficial do Firebase para Flutter](https://firebase.google.com/docs/flutter/setup).
