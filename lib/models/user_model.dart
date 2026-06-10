class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String? role;
  final String? phone;
  final String? createdAt;
  final bool isSynced;
  final String? localId;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.role,
    this.phone,
    this.createdAt,
    this.isSynced = true,
    this.localId,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'],
    fullName: j['full_name'] ?? j['fullName'] ?? '',
    email: j['email'] ?? '',
    role: j['role'],
    phone: j['phone'],
    createdAt: j['created_at'],
    isSynced: true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'email': email,
    if (role != null) 'role': role,
    if (phone != null) 'phone': phone,
  };

  Map<String, dynamic> toLocal(String localId) => {
    'local_id': localId,
    'server_id': id,
    'full_name': fullName,
    'email': email,
    'role': role,
    'phone': phone,
    'created_at': createdAt,
    'is_synced': isSynced ? 1 : 0,
  };

  factory UserModel.fromLocal(Map<String, dynamic> j) => UserModel(
    id: j['server_id'],
    localId: j['local_id'],
    fullName: j['full_name'] ?? '',
    email: j['email'] ?? '',
    role: j['role'],
    phone: j['phone'],
    createdAt: j['created_at'],
    isSynced: j['is_synced'] == 1,
  );
  
  UserModel copyWith({
    int? id,
    String? fullName,
    String? email,
    String? role,
    String? phone,
    String? createdAt,
    bool? isSynced,
    String? localId,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      localId: localId ?? this.localId,
    );
  }
}