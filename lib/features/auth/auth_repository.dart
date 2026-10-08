import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  /// Retorna o token JWT.
  Future<String> login(String email, String senha) async {
    final resposta = await _dio.post(
      '/auth/login',
      // O backend usa OAuth2PasswordRequestForm: exige form-urlencoded e os nomes de campo "username" e "password".
      data: {'username': email, 'password': senha},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    return resposta.data['access_token'] as String;
  }

  Future<void> registrar({
    required String nome,
    required String email,
    required String senha,
    required String nomeBarbearia,
  }) async {
    await _dio.post(
      '/auth/registro',
      data: {
        'nome': nome,
        'email': email,
        'senha': senha,
        'nome_barbearia': nomeBarbearia,
      },
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});
