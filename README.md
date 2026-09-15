# GJLM Gallery

Aplicativo Flutter de catálogo interativo de obras de arte. O acervo é obtido
pela API pública do Art Institute of Chicago. Favoritos e obras vistas são
salvos no aparelho e, quando o Firebase está configurado, sincronizados no
Cloud Firestore para cada usuário autenticado.

## Funcionalidades

- cadastro e login com e-mail e senha;
- catálogo paginado em `GridView`;
- imagem substituta quando uma obra não possui imagem;
- busca que abre diretamente os detalhes do primeiro resultado;
- detalhes completos obtidos em uma segunda requisição;
- favoritos e obras vistas gerenciados com Provider;
- persistência local com `shared_preferences`;
- sincronização por usuário com Cloud Firestore;
- feedback de carregamento e falhas de comunicação;
- rótulos semânticos, áreas de toque adequadas e layout adaptado à fonte.

## Executar pela primeira vez

```bash
flutter pub get
flutter run
```

Sem configurar o Firebase, o aplicativo entra automaticamente em modo local.
Esse modo permite testar todas as funções obrigatórias, mas não concede os
bônus de autenticação e persistência em nuvem.

Para habilitar os bônus, siga [CONFIGURACAO_FIREBASE.md](CONFIGURACAO_FIREBASE.md).

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

O aplicativo foi preparado para Android e iOS. A compilação e execução para
iOS exigem macOS com Xcode.

## API utilizada

- Documentação: https://api.artic.edu/docs/
- Listagem: `GET /api/v1/artworks`
- Detalhe: `GET /api/v1/artworks/{id}`
- Busca: `GET /api/v1/artworks/search?q=...`
- Imagens: serviço IIIF do Art Institute of Chicago
