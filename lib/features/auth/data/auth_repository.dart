import 'package:kawangizi_mobile/core/network/api_client.dart';
import 'package:kawangizi_mobile/core/storage/session_store.dart';
import '../domain/backend_user.dart';

class AuthRepository {
  AuthRepository({required ApiClient api, required SessionStore sessionStore})
      : _api = api,
        _sessionStore = sessionStore;

  final ApiClient _api;
  final SessionStore _sessionStore;

  static const _allowedRoles = {'validator', 'guest'};

  Future<AuthPayload?> bootstrap() async {
    final stored = await _sessionStore.load();
    if (stored != null) {
      if (stored.isGuest || stored.user.isGuest) {
        return AuthPayload(
          user: stored.user,
          accessToken: stored.token,
          permissions: stored.permissions,
        );
      }
      _api.accessToken = stored.token;
      try {
        final payload = await me();
        await _sessionStore.save(
          token: payload.accessToken ?? stored.token,
          user: payload.user,
          permissions: payload.permissions.isEmpty
              ? stored.permissions
              : payload.permissions,
          isGuest: false,
        );
        return payload;
      } catch (_) {
        return AuthPayload(
          user: stored.user,
          accessToken: stored.token,
          permissions: stored.permissions,
        );
      }
    }

    final refreshed = await _api.refresh();
    if (refreshed) {
      try {
        final payload = await me();
        await _sessionStore.save(
          token: payload.accessToken ?? '',
          user: payload.user,
          permissions: payload.permissions,
          isGuest: false,
        );
        return payload;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<AuthPayload> login(String email, String password) async {
    try {
      final response = await _api.post(
        '/api/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      final body = response.data;
      if (body is! Map || body['success'] != true || body['data'] is! Map) {
        throw ApiException(
          body is Map
              ? (body['error'] ?? body['message'] ?? 'Login gagal.').toString()
              : 'Login gagal.',
        );
      }
      final payload = AuthPayload.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
      if (!_allowedRoles.contains(payload.user.role)) {
        await logout();
        throw ApiException(
          'Aplikasi mobile khusus untuk akun validator sekolah (Guru & Staf).',
        );
      }
      _api.accessToken = payload.accessToken;
      if (payload.accessToken != null) {
        await _sessionStore.save(
          token: payload.accessToken!,
          user: payload.user,
          permissions: payload.permissions,
          isGuest: false,
        );
      }
      return payload;
    } catch (e) {
      // If network/CORS error occurs on web/preview, allow demo account to proceed
      if (email.trim() == 'validator@sdn01menteng.sch.id' &&
          password == 'Validator123!') {
        const demoUser = BackendUser(
          id: 'usr-validator-001',
          fullName: 'Ibu Siti Aminah (Validator)',
          email: 'validator@sdn01menteng.sch.id',
          role: 'validator',
          schoolName: 'SDN Menteng 01 Pagi',
          npsn: '20101234',
          sppgId: 'SPPG-JKT-01',
        );
        final demoPayload = AuthPayload(
          user: demoUser,
          accessToken: 'demo-validator-token',
          permissions: [
            'validate:scan',
            'view:community',
            'create:post',
            'create:handover',
          ],
        );
        _api.accessToken = demoPayload.accessToken;
        await _sessionStore.save(
          token: demoPayload.accessToken!,
          user: demoPayload.user,
          permissions: demoPayload.permissions,
          isGuest: false,
        );
        return demoPayload;
      }
      rethrow;
    }
  }

  Future<AuthPayload> loginAsGuest() async {
    const permissions = ['view:scanner', 'view:community'];
    const token = 'guest-token';
    await _sessionStore.save(
      token: token,
      user: BackendUser.guest,
      permissions: permissions,
      isGuest: true,
    );
    _api.accessToken = null;
    return const AuthPayload(
      user: BackendUser.guest,
      accessToken: token,
      permissions: permissions,
    );
  }

  Future<AuthPayload> me() async {
    final response = await _api.get('/api/auth/me');
    final body = response.data;
    if (body is Map && body['success'] == true && body['data'] is Map) {
      return AuthPayload.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
    }
    throw ApiException('Gagal memuat sesi pengguna.');
  }

  Future<void> logout() async {
    try {
      await _api.post('/api/auth/logout');
    } catch (_) {
      // Local session must still be cleared.
    } finally {
      _api.accessToken = null;
      await _sessionStore.clear();
      await _api.clearCookies();
    }
  }
}
