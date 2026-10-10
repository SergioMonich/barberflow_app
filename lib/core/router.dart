import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_page.dart';
import '../features/clientes/cliente.dart';
import '../features/clientes/cliente_form_page.dart';
import '../features/clientes/clientes_page.dart';
import '../features/servicos/servico.dart';
import '../features/servicos/servico_form_page.dart';
import '../features/servicos/servicos_page.dart';
import '../features/agenda/agenda_page.dart';
import '../features/agenda/agendamento_form_page.dart';
import 'api_client.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Avisa o go_router sempre que o token muda (login ou logout).
  final tokenAvisador = ValueNotifier<String?>(ref.read(tokenProvider));
  ref.listen<String?>(tokenProvider, (anterior, novo) {
    tokenAvisador.value = novo;
  });
  ref.onDispose(tokenAvisador.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: tokenAvisador,
    redirect: (context, state) {
      final logado = ref.read(tokenProvider) != null;
      final noLogin = state.matchedLocation == '/login';

      if (!logado) return noLogin ? null : '/login';
      if (noLogin) return '/agenda';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const AuthPage()),
      GoRoute(
        path: '/clientes',
        builder: (context, state) => const ClientesPage(),
      ),
      GoRoute(
        path: '/clientes/novo',
        builder: (context, state) => const ClienteFormPage(),
      ),
      GoRoute(
        path: '/clientes/editar',
        builder: (context, state) =>
            ClienteFormPage(cliente: state.extra as Cliente?),
      ),
      GoRoute(
        path: '/servicos',
        builder: (context, state) => const ServicosPage(),
      ),
      GoRoute(
        path: '/servicos/novo',
        builder: (context, state) => const ServicoFormPage(),
      ),
      GoRoute(
        path: '/servicos/editar',
        builder: (context, state) =>
            ServicoFormPage(servico: state.extra as Servico?),
      ),
            GoRoute(
        path: '/agenda',
        builder: (context, state) => const AgendaPage(),
      ),
      GoRoute(
        path: '/agenda/novo',
        builder: (context, state) => const AgendamentoFormPage(),
      ),
    ],
  );
});
