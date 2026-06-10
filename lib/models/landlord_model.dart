class LandlordModel {
  final int? id;
  final String fullName;
  final String phone;
  final String email;
  final String address;
  final int houseCount;
  final String? createdAt;
  final bool isSynced;
  final String? localId;

  LandlordModel({
    this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    this.address = '',
    this.houseCount = 0,
    this.createdAt,
    this.isSynced = true,
    this.localId,
  });

  factory LandlordModel.fromJson(Map<String, dynamic> j) => LandlordModel(
    id: j['id'],
    fullName: j['full_name'] ?? '',
    phone: j['phone'] ?? '',
    email: j['email'] ?? '',
    address: j['address'] ?? '',
    houseCount: j['house_count'] ?? 0,
    createdAt: j['created_at'],
    isSynced: true,
  );

  factory LandlordModel.fromLocal(Map<String, dynamic> j) => LandlordModel(
    id: j['server_id'],
    localId: j['local_id'],
    fullName: j['full_name'] ?? '',
    phone: j['phone'] ?? '',
    email: j['email'] ?? '',
    address: j['address'] ?? '',
    isSynced: j['is_synced'] == 1,
  );

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'phone': phone,
    'email': email,
    'address': address,
  };

  Map<String, dynamic> toLocal(String localId) => {
    'local_id': localId,
    'server_id': id,
    'full_name': fullName,
    'phone': phone,
    'email': email,
    'address': address,
    'is_synced': isSynced ? 1 : 0,
  };
  
  LandlordModel copyWith({
    int? id,
    String? fullName,
    String? phone,
    String? email,
    String? address,
    int? houseCount,
    String? createdAt,
    bool? isSynced,
    String? localId,
  }) {
    return LandlordModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      houseCount: houseCount ?? this.houseCount,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      localId: localId ?? this.localId,
    );
  }
}