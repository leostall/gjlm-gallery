import 'package:flutter/foundation.dart';

import '../modelos/obra.dart';
import '../servicos/servico_art_institute.dart';

class ProvedorCatalogo extends ChangeNotifier {
  ProvedorCatalogo(this._servico);

  final ServicoArtInstitute _servico;

  final List<Obra> _obras = [];
  int _paginaAtual = 0;
  bool _temProximaPagina = true;
  bool _carregandoInicial = false;
  bool _carregandoMais = false;
  bool _buscando = false;
  String? _erro;

  List<Obra> get obras => List.unmodifiable(_obras);
  bool get temProximaPagina => _temProximaPagina;
  bool get carregandoInicial => _carregandoInicial;
  bool get carregandoMais => _carregandoMais;
  bool get buscando => _buscando;
  String? get erro => _erro;

  Future<void> carregarInicial({bool forcar = false}) async {
    if (_carregandoInicial || (_obras.isNotEmpty && !forcar)) return;

    _carregandoInicial = true;
    _erro = null;
    if (forcar) _obras.clear();
    notifyListeners();

    try {
      final resultado = await _servico.listarObras(pagina: 1);
      _obras
        ..clear()
        ..addAll(resultado.obras);
      _paginaAtual = resultado.paginaAtual;
      _temProximaPagina = resultado.temProximaPagina;
    } on ExcecaoApi catch (erro) {
      _erro = erro.mensagem;
    } catch (_) {
      _erro = 'Não foi possível carregar o catálogo. Verifique sua conexão.';
    } finally {
      _carregandoInicial = false;
      notifyListeners();
    }
  }

  Future<void> carregarMais() async {
    if (_carregandoMais || !_temProximaPagina) return;

    _carregandoMais = true;
    _erro = null;
    notifyListeners();

    try {
      final resultado = await _servico.listarObras(
        pagina: _paginaAtual + 1,
      );
      final idsExistentes = _obras.map((obra) => obra.id).toSet();
      _obras.addAll(
        resultado.obras.where((obra) => !idsExistentes.contains(obra.id)),
      );
      _paginaAtual = resultado.paginaAtual;
      _temProximaPagina = resultado.temProximaPagina;
    } on ExcecaoApi catch (erro) {
      _erro = erro.mensagem;
    } catch (_) {
      _erro = 'Não foi possível carregar mais obras.';
    } finally {
      _carregandoMais = false;
      notifyListeners();
    }
  }

  Future<Obra?> buscar(String termo) async {
    if (_buscando) return null;

    _buscando = true;
    _erro = null;
    notifyListeners();

    try {
      return await _servico.buscarPrimeiraObra(termo);
    } on ExcecaoApi catch (erro) {
      _erro = erro.mensagem;
      return null;
    } catch (_) {
      _erro = 'Não foi possível realizar a busca. Tente novamente.';
      return null;
    } finally {
      _buscando = false;
      notifyListeners();
    }
  }

  Future<Obra> carregarDetalhes(int obraId) {
    return _servico.buscarDetalhes(obraId);
  }

  void limparErro() {
    if (_erro == null) return;
    _erro = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _servico.fechar();
    super.dispose();
  }
}
