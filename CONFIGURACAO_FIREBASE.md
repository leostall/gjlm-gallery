# Configuração do Firebase

O código já possui autenticação por e-mail/senha e sincronização com Firestore.
Falta vinculá-lo a um projeto Firebase pertencente ao grupo.

## 1. Criar o projeto

1. Acesse https://console.firebase.google.com/.
2. Crie um projeto, por exemplo `gjlm-gallery`.
3. Em **Authentication > Sign-in method**, habilite **E-mail/senha**.
4. Em **Firestore Database**, crie o banco. Para a entrega, escolha uma região
   próxima e use regras protegidas, não o modo de teste permanente.

## 2. Instalar as ferramentas

```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

Se o terminal não reconhecer `flutterfire`, adicione a pasta indicada pelo
comando anterior ao `PATH` e abra o terminal novamente.

## 3. Vincular Android e iOS

Na raiz do projeto, execute:

```bash
flutterfire configure
```

Selecione o projeto criado e marque Android e iOS. O comando substituirá
`lib/firebase_options.dart` pelos dados corretos e fará as configurações
necessárias nas plataformas.

Identificadores atuais do projeto:

- Android: `com.example.gjlm_gallery`
- iOS: `com.example.gjlmGallery`

## 4. Publicar as regras do Firestore

O arquivo `firestore.rules` permite que cada usuário acesse apenas suas próprias
coleções.

```bash
firebase use --add
firebase deploy --only firestore:rules
```

## 5. Validar

```bash
flutter clean
flutter pub get
flutter run
```

Na tela de autenticação, o aviso de modo local deve desaparecer. Depois:

1. crie uma conta;
2. favorite e marque uma obra como vista;
3. feche e reabra o aplicativo;
4. confirme que os dados permaneceram;
5. entre com a mesma conta em outro aparelho e confirme a sincronização.

## Login com Google depois da entrega principal

O login Google não está ativado nesta versão para não aumentar o risco da
entrega. Ele pode ser incluído depois com `google_sign_in`, habilitação do
provedor Google no Firebase e configuração de SHA-1/SHA-256 no Android.
