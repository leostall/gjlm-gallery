import 'obra.dart';

class ResultadoPaginadoObras {
  const ResultadoPaginadoObras({
    required this.obras,
    required this.paginaAtual,
    required this.totalPaginas,
  });

  final List<Obra> obras;
  final int paginaAtual;
  final int totalPaginas;

  bool get temProximaPagina => paginaAtual < totalPaginas;
}
