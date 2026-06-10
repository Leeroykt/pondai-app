class HouseModel {
  final int? id;
  final int? landlordId;
  final String landlord;
  final String address;
  final int totalRooms;
  final double rentPerRoom;
  final String status;
  final double? latitude;
  final double? longitude;
  final String? createdAt;
  final bool isSynced;
  final String? localId;

  HouseModel({
    this.id,
    this.landlordId,
    this.landlord = '',
    required this.address,
    this.totalRooms = 1,
    this.rentPerRoom = 0,
    this.status = 'available',
    this.latitude,
    this.longitude,
    this.createdAt,
    this.isSynced = true,
    this.localId,
  });

  factory HouseModel.fromJson(Map<String, dynamic> j) => HouseModel(
    id: j['id'],
    landlordId: j['landlord_id'],
    landlord: j['landlord'] ?? '',
    address: j['address'] ?? '',
    totalRooms: j['total_rooms'] ?? 1,
    rentPerRoom: (j['rent_per_room'] ?? 0).toDouble(),
    status: j['status'] ?? 'available',
    latitude: j['latitude']?.toDouble(),
    longitude: j['longitude']?.toDouble(),
    createdAt: j['created_at'],
    isSynced: true,
  );

  factory HouseModel.fromLocal(Map<String, dynamic> j) => HouseModel(
    id: j['server_id'],
    localId: j['local_id'],
    landlordId: j['landlord_id'],
    landlord: j['landlord'] ?? '',
    address: j['address'] ?? '',
    totalRooms: j['total_rooms'] ?? 1,
    rentPerRoom: (j['rent_per_room'] ?? 0).toDouble(),
    status: j['status'] ?? 'available',
    latitude: j['latitude']?.toDouble(),
    longitude: j['longitude']?.toDouble(),
    isSynced: j['is_synced'] == 1,
  );

  Map<String, dynamic> toJson() => {
    'landlord_id': landlordId,
    'address': address,
    'total_rooms': totalRooms,
    'rent_per_room': rentPerRoom,
    'status': status,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };

  Map<String, dynamic> toLocal(String localId) => {
    'local_id': localId,
    'server_id': id,
    'landlord_id': landlordId,
    'landlord': landlord,
    'address': address,
    'total_rooms': totalRooms,
    'rent_per_room': rentPerRoom,
    'status': status,
    'latitude': latitude,
    'longitude': longitude,
    'is_synced': isSynced ? 1 : 0,
  };
  
  HouseModel copyWith({
    int? id,
    int? landlordId,
    String? landlord,
    String? address,
    int? totalRooms,
    double? rentPerRoom,
    String? status,
    double? latitude,
    double? longitude,
    String? createdAt,
    bool? isSynced,
    String? localId,
  }) {
    return HouseModel(
      id: id ?? this.id,
      landlordId: landlordId ?? this.landlordId,
      landlord: landlord ?? this.landlord,
      address: address ?? this.address,
      totalRooms: totalRooms ?? this.totalRooms,
      rentPerRoom: rentPerRoom ?? this.rentPerRoom,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      localId: localId ?? this.localId,
    );
  }
}