import '../models/auth_models.dart';
import 'api_client.dart';
import 'api_exception.dart';

class AuthService {
  AuthService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<AuthSession> login(AuthCredentials credentials) async {
    final response = await _client.post(
      '/auth/login',
      body: <String, dynamic>{
        'username': credentials.username, // 使用用户名登录
        'password': credentials.password,
      },
    );

    final token = response['token']?.toString();
    final userJson = response['user'];
    if (token == null || userJson is! Map<String, dynamic>) {
      throw ApiException('登录返回格式不正确');
    }

    return AuthSession(token: token, user: AuthUser.fromJson(userJson));
  }

  Future<void> register(RegistrationPayload payload) async {
    if (payload.password != payload.confirmPassword) {
      throw ApiException('两次输入的密码不一致');
    }
    await _client.post('/auth/register', body: payload.toJson());
  }
}
