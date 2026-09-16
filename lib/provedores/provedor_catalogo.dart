import 'dart:async';

import 'package:flutter/foundation.dart';

import '../modelos/obra.dart';
import '../modelos/consulta_obras.dart';
import '../servicos/servico_museu_cleveland.dart';

class ProvedorCatalogo extends ChangeNotifier {
  ProvedorCatalogo(this._servico);
  final ServicoMuseuCleveland _servico;
  final List<Obra> _obras = [];
  final Map<int, Obra> _cache = {};
  int _paginaAtual = 0;
  int _versao = 0;
  bool _descartado = false;
  bool _temProximaPagina = true;
  bool _carregandoInicial = false;
  bool _carregandoMais = false;
  bool _buscando = false;
  String _termo = '';
  String? _erro;
  String? _avisoBusca;
  Timer? _debounce;

  List<Obra> get obras => List.unmodifiable(_obras);
  bool get temProximaPagina => _temProximaPagina;
  bool get carregandoInicial => _carregandoInicial;
  bool get carregandoMais => _carregandoMais;
  bool get buscando => _buscando;
  String get termo => _termo;
  String? get erro => _erro;
  String? get avisoBusca => _avisoBusca;

  void filtrar(String texto) {
    final termo = texto.trim();
    if (termo == _termo) return;
    _termo = termo;
    _avisoBusca = null;
    _debounce?.cancel();
    final versao = ++_versao;
    _erro = null;
    _carregandoMais = false;
    _carregandoInicial = true;
    _temProximaPagina = false;
    final busca = ConsultaObras(termo);
    _obras
      ..clear()
      ..addAll(_cache.values.where(busca.correspondeAoFiltro));
    notifyListeners();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _carregar(1, versao),
    );
  }

  Future<void> carregarInicial({bool forcar = false}) async {
    if (!forcar && (_carregandoInicial || _obras.isNotEmpty)) return;
    _debounce?.cancel();
    final versao = ++_versao;
    _carregandoInicial = true;
    _carregandoMais = false;
    _erro = null;
    notifyListeners();
    await _carregar(1, versao);
  }

  Future<void> carregarMais() async {
    if (_buscando ||
        _carregandoInicial ||
        _carregandoMais ||
        !_temProximaPagina) {
      return;
    }
    _carregandoMais = true;
    _erro = null;
    notifyListeners();
    await _carregar(_paginaAtual + 1, _versao);
  }

  Future<void> _carregar(int pagina, int versao) async {
    try {
      final resultado = await _servico.listarObras(
        pagina: pagina,
        termo: _termo,
      );
      if (_descartado || versao != _versao) return;
      if (pagina == 1) _obras.clear();
      final ids = _obras.map((obra) => obra.id).toSet();
      _obras.addAll(resultado.obras.where((obra) => ids.add(obra.id)));
      _cache.addEntries(resultado.obras.map((obra) => MapEntry(obra.id, obra)));
      _paginaAtual = resultado.paginaAtual;
      _temProximaPagina = resultado.temProximaPagina;
    } catch (erro) {
      if (_descartado || versao != _versao) return;
      _erro = erro is ExcecaoApi ? erro.mensagem : 'Não foi possível carregar as obras. Verifique sua conexão e tente novamente.';
    } finally {
      if (!_descartado && versao == _versao) {
        _carregandoInicial = false;
        _carregandoMais = false;
        notifyListeners();
      }
    }
  }

  Future<Obra?> buscar(String termo) async {
    if (_buscando) return null;
    _avisoBusca = null;
    _debounce?.cancel();
    final busca = termo.trim();
    if (busca.isEmpty) {
      ++_versao;
      _carregandoInicial = false;
      _carregandoMais = false;
      _erro = null;
      _avisoBusca = 'Digite o nome de uma obra ou artista.';
      notifyListeners();
      return null;
    }
    _termo = busca;
    final versao = ++_versao;
    _carregandoInicial = true;
    _carregandoMais = false;
    _buscando = true;
    _erro = null;
    _obras.clear();
    _temProximaPagina = false;
    notifyListeners();
    try {
      await _carregar(1, versao);
      if (_descartado || versao != _versao || _erro != null) return null;
      if (_obras.isEmpty) {
        _avisoBusca = 'Nenhuma obra encontrada para “$busca”.';
        return null;
      }
      final consulta = ConsultaObras(busca);
      if (consulta.temTituloEArtista) {
        // Os filtros remotos podem retornar correspondências parciais. Confere
        // as próximas páginas antes de decidir que a combinação é única.
        var exatas = _obras.where(consulta.correspondeExatamente).toList();
        while (_temProximaPagina && exatas.length < 2) {
          _carregandoMais = true;
          notifyListeners();
          await _carregar(_paginaAtual + 1, versao);
          if (_descartado || versao != _versao || _erro != null) return null;
          exatas = _obras.where(consulta.correspondeExatamente).toList();
        }
        if (exatas.length == 1 && !_temProximaPagina) return exatas.single;
        _avisoBusca = exatas.length > 1
            ? 'Há mais de uma obra com esse título e artista. Selecione a obra desejada nos resultados.'
            : 'Não encontramos uma correspondência exata de título e artista. Selecione uma obra nos resultados ou refine a busca.';
      } else {
        _avisoBusca = _obras.length > 1 || _temProximaPagina
            ? 'Encontramos várias obras. Selecione a obra desejada ou busque no formato Título — Artista.'
            : 'Selecione a obra encontrada ou busque no formato Título — Artista para abrir os detalhes diretamente.';
      }
      return null;
    } finally {
      _buscando = false;
      if (!_descartado) notifyListeners();
    }
  }

  Future<Obra> carregarDetalhes(int obraId) => _servico.buscarDetalhes(obraId);

  @override
  void dispose() {
    _descartado = true;
    _debounce?.cancel();
    _servico.fechar();
    super.dispose();
  }
}
