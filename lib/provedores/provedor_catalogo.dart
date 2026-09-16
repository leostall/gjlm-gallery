import 'package:flutter/foundation.dart';

import '../modelos/obra.dart';
import '../servicos/servico_museu_cleveland.dart';

class ProvedorCatalogo extends ChangeNotifier {
  ProvedorCatalogo(this._servico);
  final ServicoMuseuCleveland _servico;
  final List<Obra> _obras = [];
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

  List<Obra> get obras => List.unmodifiable(_obras);
  bool get temProximaPagina => _temProximaPagina;
  bool get carregandoInicial => _carregandoInicial;
  bool get carregandoMais => _carregandoMais;
  bool get buscando => _buscando;
  String get termo => _termo;
  String? get erro => _erro;
  String? get avisoBusca => _avisoBusca;

  Future<void> carregarInicial({bool forcar = false}) async {
    if (!forcar && (_carregandoInicial || _obras.isNotEmpty)) return;
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
      _paginaAtual = resultado.paginaAtual;
      _temProximaPagina = resultado.temProximaPagina;
    } catch (erro) {
      if (_descartado || versao != _versao) return;
      _erro = erro is ExcecaoApi
          ? erro.mensagem
          : 'Não foi possível carregar as obras. '
                'Verifique sua conexão e tente novamente.';
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
      // O RF08 determina que a busca abra diretamente o item encontrado.
      // Respeitamos a ordem entregue pelo endpoint do museu.
      return _obras.first;
    } finally {
      _buscando = false;
      if (!_descartado) notifyListeners();
    }
  }

  Future<void> limparBusca() async {
    if (_termo.isEmpty) {
      if (_avisoBusca != null) {
        _avisoBusca = null;
        notifyListeners();
      }
      return;
    }
    _termo = '';
    _avisoBusca = null;
    await carregarInicial(forcar: true);
  }

  Future<Obra> carregarDetalhes(int obraId) => _servico.buscarDetalhes(obraId);

  @override
  void dispose() {
    _descartado = true;
    _servico.fechar();
    super.dispose();
  }
}
