import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Web (Chrome): o backend esta no proprio PC -> 127.0.0.1
// Emulador Android: o PC e visto como 10.0.2.2
final String baseUrl = kIsWeb
    ? 'http://127.0.0.1:8000'
    : 'http://10.0.2.2:8000';

/// Guarda o token JWT em memoria (some ao fechar o app).
class TokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void definir(String? token) => state = token;
}

final tokenProvider = NotifierProvider<TokenNotifier, String?>(
  TokenNotifier.new,
);

/// Dio configurado: toda requisicao leva o token, se existir.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(tokenProvider);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        handler.next(options);
      },
    ),
  );

  return dio;
});

/// Transforma um erro do Dio em uma mensagem legivel para o usuario.
String mensagemDeErro(Object erro) {
  if (erro is DioException) {
    final dados = erro.response?.data;
    if (dados is Map && dados['detail'] is String) {
      return dados['detail'] as String;
    }

    if (erro.response?.statusCode == 422) {
      return 'Dados invalidos. Confira os campos.';
    }

    if (erro.type == DioExceptionType.connectionError ||
        erro.type == DioExceptionType.connectionTimeout) {
      return 'Nao foi possivel conectar ao servidor.';
    }
  }

  return 'Ocorreu um erro inesperado.';
}
