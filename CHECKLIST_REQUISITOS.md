# Checklist dos requisitos

| RF | Implementação | Arquivo principal |
|---|---|---|
| RF01 | Catálogo em GridView, paginação e placeholder | `lib/telas/tela_catalogo.dart` |
| RF02 | Navegação com Navigator e MaterialPageRoute | `lib/telas/tela_catalogo.dart` |
| RF03 | Requisição de detalhes e exibição completa | `lib/telas/tela_detalhes_obra.dart` |
| RF04 | Favoritar/desfavoritar com Provider | `lib/provedores/provedor_colecao.dart` |
| RF05 | Aba de favoritos reativa | `lib/telas/tela_colecao.dart` |
| RF06 | SharedPreferences e Cloud Firestore | `lib/servicos/servico_persistencia_local.dart` |
| RF07 | Login e aba de obras vistas | `lib/telas/tela_autenticacao.dart` |
| RF08 | TextField, controller, botão e busca | `lib/telas/tela_catalogo.dart` |
| RF09 | Indicadores de progresso e mensagens de erro | `lib/widgets/indicador_carregamento.dart` |
| RF10 | Semantics, contraste, toque e escala da fonte | `lib/widgets/cartao_obra.dart` |

## Teste manual antes da gravação

- [ ] cadastro e login funcionam;
- [ ] usuário sem sessão sempre vê a tela de login;
- [ ] catálogo exibe imagem e título em grade;
- [ ] obra sem imagem mostra placeholder;
- [ ] Carregar mais adiciona itens sem apagar os anteriores;
- [ ] toque no card abre os detalhes;
- [ ] busca abre diretamente os detalhes do primeiro resultado;
- [ ] favorito aparece e desaparece da aba automaticamente;
- [ ] obra vista aparece e desaparece da aba automaticamente;
- [ ] favoritos e vistos permanecem após reiniciar o app;
- [ ] sincronização funciona com a mesma conta em outro aparelho;
- [ ] falha de rede exibe mensagem amigável;
- [ ] telas principais foram verificadas com fonte ampliada;
- [ ] telas principais foram verificadas com TalkBack ou VoiceOver.

## Sugestão para a explicação técnica

O tema mais alinhado ao código é **Provider vs. setState**:

- `setState` controla somente detalhes internos de uma tela, como mostrar senha;
- `ProvedorColecao` compartilha favoritos e vistos entre detalhes e abas;
- `notifyListeners()` atualiza automaticamente todas as telas interessadas;
- armazenamento e sincronização ficam fora dos widgets.
