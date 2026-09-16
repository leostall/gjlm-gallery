# GJLM Gallery

Aplicativo Flutter de catálogo interativo de obras de arte. O acervo é obtido
pela API pública do Cleveland Museum of Art. Favoritos e obras vistas são
salvos no aparelho e, quando o Firebase está configurado, sincronizados no
Cloud Firestore para cada usuário autenticado.

## Funcionalidades

- cadastro e login com e-mail e senha;
- catálogo paginado em `GridView`;
- imagem substituta quando uma obra não possui imagem;
- busca automática ao digitar; no formato `Título — Artista`, Buscar abre uma correspondência exata e única; buscas livres, parciais ou ambíguas permanecem na grade;
- detalhes completos obtidos em uma segunda requisição;
- favoritos e obras vistas gerenciados com Provider;
- persistência local com `shared_preferences`;
- sincronização por usuário com Cloud Firestore;
- feedback de carregamento e falhas de comunicação;
- rótulos semânticos, áreas de toque adequadas e layout adaptado à fonte.

## Executar pela primeira vez

```bash
flutter pub get
flutter run -d chrome
```

Sem configurar o Firebase, o aplicativo entra automaticamente em modo local.
Esse modo permite testar todas as funções obrigatórias, mas não concede os
bônus de autenticação e persistência em nuvem.

O projeto Firebase já está vinculado e os bônus foram testados no serviço real. Consulte [CONFIGURACAO_FIREBASE.md](CONFIGURACAO_FIREBASE.md).

## Organização

```text
lib/
├── configuracoes/  # tema e inicialização do Firebase
├── modelos/        # estruturas de dados do aplicativo
├── provedores/     # estados globais de autenticação, catálogo e coleção
├── servicos/       # API, autenticação, armazenamento local e nuvem
├── telas/          # login, catálogo, coleções e detalhes
└── widgets/        # componentes reutilizáveis
```

## Verificações

```bash
dart format .
flutter analyze
flutter test
```

A apresentação será no Chrome. A árvore semântica da versão web fica ativa
desde a abertura para leitores de tela. Consulte a conferência completa e o
roteiro manual de VoiceOver em [CHECKLIST_REQUISITOS.md](CHECKLIST_REQUISITOS.md).
Os testes automatizados não substituem a verificação auditiva com VoiceOver.

## API utilizada

- Documentação: https://openaccess-api.clevelandart.org/
- Listagem: `GET /api/artworks/?skip=...&limit=...`
- Detalhe: `GET /api/artworks/{id}`
- Busca: `GET /api/artworks/?q=...`
- Imagens: CDN Open Access do Cleveland Museum of Art
