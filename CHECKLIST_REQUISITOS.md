# Conferência das quatro fotos da atividade

Revisão de 16/09/2026. As fotos são critérios da atividade; instruções de entrega
nelas não autorizam publicação ou envio do projeto.

## Resultado por requisito

| Requisito | Implementação e evidência |
|---|---|
| Tema e ferramentas | Catálogo do Cleveland Museum of Art, em Flutter/Dart. `http`, `provider` e `shared_preferences` utilizados. API pública com listagem (`skip`/`limit`), busca livre (`q`) ou por título e artista (`title`/`artists`), e detalhe por ID. |
| RF01 — catálogo | Login protege a tela; lista inicial pela API; `GridView.builder` com imagem, título e artista. A imagem do cartão usa `BoxFit.contain`, preservando a proporção sem recortar a composição, com fundo creme nas margens. `ElevatedButton` “Carregar Mais” ao fim da página acrescenta itens sem duplicar IDs. Imagem ausente ou falha de carregamento têm placeholder. |
| RF02 — navegação | Cartão abre detalhes por `Navigator.push`/`MaterialPageRoute`; favorito é uma ação independente. |
| RF03 — detalhes | Requisição por ID, `FutureBuilder`, imagem maior, título, artista, data, tipo, técnica, dimensões, origem e descrição. Há nova tentativa em falhas. |
| RF04 — Provider | Favoritar/desfavoritar nos detalhes e cartões; estado global em `ProvedorColecao`, observado com `context.watch`. |
| RF05 — favoritos | Aba própria; remoção atualiza a lista automaticamente. Teste de widget. |
| RF06 — persistência local | Favoritos e vistas no `shared_preferences`, por usuário. Testes recriam provedores e verificam recuperação. |
| RF06 — bônus +10% | Firestore em `usuarios/{uid}/favoritos` e `usuarios/{uid}/vistos`. Escrita e recuperação em nova sessão verificadas no Firebase real. Pendências offline persistidas; testes de remoção offline e alterações concorrentes. |
| RF07 — login e consumidos | Catálogo protegido pelo `PortalAutenticacao`; ação “Marcar vista” nos detalhes e aba “Vistas”. Login/cadastro local e restauração de sessão testados. |
| RF07 — bônus +10% | Firebase Auth por e-mail/senha, listas vinculadas ao UID e sincronizadas no Firestore. Cadastro, login, recuperação em outra sessão e isolamento entre usuários verificados no serviço real. Depende do bônus RF06, também verificado. |
| RF08 — busca | `TextField`, `TextEditingController`, botão Buscar e tecla de envio consultam a API; apenas digitar não dispara requisição. Termos livres usam `q`; o formato `Título — Artista` usa os filtros `title` e `artists`. A primeira obra retornada pela API abre diretamente nos detalhes. A ausência de resultados gera um aviso amigável. |
| RF09 — feedback | Indicadores circulares no início, paginação, busca, detalhes e autenticação. Erros amigáveis e nova tentativa. Busca vazia e resultados antigos tratados. Busca sem resultados é um aviso, não uma falha da API; teste confirma que não aparece “Acervo indisponível” nesse caso. |
| RF10 — semântica | Português brasileiro no Material/Cupertino/Widgets. “Voltar” traduzido; abas com nome, posição e seleção. Cartão é um único botão com título/artista e indicação de abrir detalhes; coração independente com estado. Imagem e ficha técnica acessíveis nos detalhes. Campos preservam nome e papel de edição; senha tem ação mostrar/ocultar. |
| RF10 — fonte e layout | Fonte respeitada sem limitar escala. Campos com rótulos que quebram linha; grade mede os textos; detalhes empilham em telas estreitas; conteúdo e cabeçalho podem rolar. Abas permitem rolagem horizontal quando os nomes ampliados não cabem. Menu fica oculto enquanto o teclado está aberto. |
| RF10 — contraste e toque | Testes das diretrizes Flutter para contraste de texto e nomes/áreas de toque em cartões, catálogo e login. Coração 56×56 e controles com alvos mínimos adequados. Não equivalem a uma auditoria visual exaustiva de todos os estados. |
| RF10 — VoiceOver real | **Validação auditiva manual ainda pendente.** Testes verificam a árvore e as ações semânticas, mas não escutam o VoiceOver. |

A busca segue a redação do RF08: digitar no campo não inicia uma requisição;
o botão Buscar ou a tecla de envio consultam a API e navegam diretamente para
os detalhes da primeira obra retornada, respeitando a ordem do endpoint. Termos
livres usam o parâmetro `q`. O formato `Título — Artista` também aceita hífen,
meia-risca ou barra vertical com espaços e usa os filtros `title` e `artists`.
Não há comparação exata no aplicativo nem verificação de resultado único. Se a
API não retornar obras, o aplicativo apresenta um aviso; limpar a busca restaura
o catálogo inicial. Os filtros utilizados são documentados pelo
[Cleveland Museum of Art](https://openaccess-api.clevelandart.org/).

Os bônus só funcionam quando o Firebase inicializa e a conta é autenticada nele.
O modo local continua atendendo ao baseline, mas não demonstra os bônus.
Os testes de nuvem confirmam o backend e sessões independentes; não substituem
uma demonstração completa em dois aparelhos nem a validação do SDK nativo em iOS.

## Verificações desta revisão

- `flutter analyze`: sem problemas.
- `flutter test`: 41 casos de teste, incluindo autenticação, persistência, HTTP, busca,
  ações semânticas, traduções, áreas de toque e contraste.
- Teste adicional do fluxo do leitor: a ação semântica do cartão abre a rota de
  detalhes, consulta a API por ID e não favorita a obra; a ação de “Voltar” retorna
  ao catálogo. O cartão mantém um único foco, título/artista, papel de botão e dica.
- Layout em 100%, 200% e 300%: 320×568, 568×320, 320×740 e 1024×768.
- Cenário adicional a 300%: cadastro com erros, teclado aberto, busca,
  favoritos/vistas preenchidos e diálogo de saída; controles alcançáveis por rolagem.
- `flutter build web`: build de produção concluído na revisão anterior; os
  ajustes posteriores da imagem e do fluxo que abre o primeiro resultado da busca
  foram verificados com análise estática e testes Flutter.
- `python3 tool/verificar_firebase.py`: cadastro e login reais; favoritos/vistas
  recuperados em nova sessão; acesso anônimo e de outro UID negados.
  Documentos e conta temporários removidos ao terminar.
  A verificação real foi executada novamente nesta reconferência e passou.

## Roteiro manual de VoiceOver

1. Reinicie o app após atualizar as dependências. Na web, recarregue a versão nova;
   no iOS, alterações do `Info.plist` precisam de uma nova compilação.
2. Ative o VoiceOver no dispositivo usado na apresentação. No macOS: Command + F5.
3. No login/cadastro, percorra nome, e-mail, senha, mostrar/ocultar, confirmação
   e envio. Provoque erros e verifique leitura dos rótulos e mensagens.
4. Entre e percorra a busca e as abas. Devem informar nome, posição e seleção
   em português. Com fonte grande, teste também rolagem horizontal das abas.
5. O cartão deve anunciar algo equivalente a “Nenúfares, de Claude Monet, botão”,
   com dica de abrir detalhes. Imagem e textos não devem ser focos repetidos.
   O coração deve ser outro controle, identificando a obra e o estado.
6. Acione os dois controles pelo VoiceOver: cartão abre detalhes; coração somente
   favorita/desfavorita. Teste “Voltar”, imagem, ficha técnica e “Marcar vista”.
7. Busque `Título — Artista`, um termo livre e um termo inexistente. Confirme que
   as duas primeiras consultas abrem diretamente os detalhes da primeira obra
   retornada e que a última exibe a mensagem de ausência. Volte, limpe a busca e
   confirme que o catálogo inicial é restaurado.
8. Abra Favoritos e Vistas, remova itens, saia e entre para conferir persistência.
9. Repita com fonte máxima do sistema e orientação horizontal. Na web, teste zoom
   de 200% e 300%. Confirme acesso a conteúdo, rodapé, diálogo e teclado aberto.

A ordem exata da fala e o anúncio de papéis como “botão” dependem das opções,
idioma e verbosidade do VoiceOver. Textos do acervo permanecem no idioma da API;
o app não inventa descrições visuais nem traduz automaticamente as obras.

Referências: [localização no Flutter](https://docs.flutter.dev/ui/internationalization),
[acessibilidade](https://docs.flutter.dev/ui/accessibility) e
[limites de escala da NavigationBar padrão](https://api.flutter.dev/flutter/material/NavigationBar-class.html).
