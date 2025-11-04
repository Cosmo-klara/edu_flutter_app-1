class AuthUser {
  const AuthUser({
    required this.userId,
    required this.username,
    this.province,
    this.schoolId,
  });

  final String userId;
  final String username;
  final String? province;
  final int? schoolId;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      province: json['province'] as String?,
      schoolId: json['schoolId'] == null ? null : int.tryParse(json['schoolId'].toString()),
    );
  }
}

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AuthUser user;
}

class AuthCredentials {
  const AuthCredentials({required this.username, required this.password});

  final String username;
  final String password;
}

class RegistrationPayload {
  RegistrationPayload({
    required this.username,
    required this.password,
    required this.confirmPassword,
    this.province,
    this.schoolId,
  }) : generatedId = _generateUniqueId();

  final String username;
  final String password;
  final String confirmPassword;
  final String? province;
  final String? schoolId;
  
  /// 注册时生成的唯一ID，注册成功后用于登录
  final String generatedId;

  /// 生成9位数字ID
  /// 格式: 年份后2位(2位) + 月日(4位) + 微秒取模(3位)
  /// 例如: 25 + 1104 + 523 = 251104523
  /// 范围: 100000000 - 999999999
  static String _generateUniqueId() {
    final now = DateTime.now();
    final year = now.year % 100; // 取年份后两位 (00-99)
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    
    // 使用微秒时间戳取模生成3位数字 (000-999)
    final microPart = (now.microsecondsSinceEpoch % 1000).toString().padLeft(3, '0');
    
    return '$year$month$day$microPart';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': generatedId, // 使用生成的唯一ID
      'username': username,
      'password': password,
      if (province != null && province!.isNotEmpty) 'province': province,
      if (schoolId != null && schoolId!.isNotEmpty) 'school_id': schoolId,
    };
  }
}
