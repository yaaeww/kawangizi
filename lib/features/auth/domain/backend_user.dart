class BackendUser {
  const BackendUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.npsn,
    this.schoolName,
    this.sppgId,
    this.status,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? npsn;
  final String? schoolName;
  final String? sppgId;
  final String? status;

  bool get isGuest => role == 'guest';

  BackendUser copyWith({
    String? id,
    String? fullName,
    String? email,
    String? role,
    String? npsn,
    String? schoolName,
    String? sppgId,
    String? status,
  }) =>
      BackendUser(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        role: role ?? this.role,
        npsn: npsn ?? this.npsn,
        schoolName: schoolName ?? this.schoolName,
        sppgId: sppgId ?? this.sppgId,
        status: status ?? this.status,
      );

  factory BackendUser.fromJson(Map<String, dynamic> json) => BackendUser(
        id: (json['id'] ?? '').toString(),
        fullName: (json['fullName'] ?? json['full_name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        role: (json['role'] ?? '').toString(),
        npsn: json['npsn']?.toString(),
        schoolName: (json['schoolName'] ?? json['school_name'])?.toString(),
        sppgId: (json['sppgId'] ?? json['sppg_id'])?.toString(),
        status: json['status']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'role': role,
        if (npsn != null) 'npsn': npsn,
        if (schoolName != null) 'schoolName': schoolName,
        if (sppgId != null) 'sppgId': sppgId,
        if (status != null) 'status': status,
      };

  static const guest = BackendUser(
    id: 'guest-preview',
    fullName: 'Mode Tamu',
    email: 'tamu@kawangizi.id',
    role: 'guest',
    schoolName: 'Pratinjau Publik',
  );
}

class AuthPayload {
  const AuthPayload({
    required this.user,
    this.accessToken,
    this.expiresIn,
    this.permissions = const [],
  });

  final BackendUser user;
  final String? accessToken;
  final int? expiresIn;
  final List<String> permissions;

  factory AuthPayload.fromJson(Map<String, dynamic> json) => AuthPayload(
        user: BackendUser.fromJson(Map<String, dynamic>.from(json['user'] ?? {})),
        accessToken: json['accessToken']?.toString(),
        expiresIn: int.tryParse('${json['expiresIn'] ?? ''}'),
        permissions: (json['permissions'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

class StoredSession {
  const StoredSession({
    required this.token,
    required this.user,
    required this.permissions,
    required this.isGuest,
  });

  final String token;
  final BackendUser user;
  final List<String> permissions;
  final bool isGuest;
}
