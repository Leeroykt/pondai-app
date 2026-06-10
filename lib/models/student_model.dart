class StudentModel {
  final int? id;
  final String fullName;
  final String phone;
  final String email;
  final String university;
  final String course;
  final String nationalId;
  final String? createdAt;
  final bool isSynced;
  final String? localId;

  StudentModel({
    this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    this.university = '',
    this.course = '',
    this.nationalId = '',
    this.createdAt,
    this.isSynced = true,
    this.localId,
  });

  factory StudentModel.fromJson(Map<String, dynamic> j) => StudentModel(
    id: j['id'],
    fullName: j['full_name'] ?? '',
    phone: j['phone'] ?? '',
    email: j['email'] ?? '',
    university: j['university'] ?? '',
    course: j['course'] ?? '',
    nationalId: j['national_id'] ?? '',
    createdAt: j['created_at'],
    isSynced: true,
  );

  factory StudentModel.fromLocal(Map<String, dynamic> j) => StudentModel(
    id: j['server_id'],
    localId: j['local_id'],
    fullName: j['full_name'] ?? '',
    phone: j['phone'] ?? '',
    email: j['email'] ?? '',
    university: j['university'] ?? '',
    course: j['course'] ?? '',
    nationalId: j['national_id'] ?? '',
    isSynced: j['is_synced'] == 1,
  );

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'phone': phone,
    'email': email,
    'university': university,
    'course': course,
    'national_id': nationalId,
  };

  Map<String, dynamic> toLocal(String localId) => {
    'local_id': localId,
    'server_id': id,
    'full_name': fullName,
    'phone': phone,
    'email': email,
    'university': university,
    'course': course,
    'national_id': nationalId,
    'is_synced': isSynced ? 1 : 0,
  };
  
  StudentModel copyWith({
    int? id,
    String? fullName,
    String? phone,
    String? email,
    String? university,
    String? course,
    String? nationalId,
    String? createdAt,
    bool? isSynced,
    String? localId,
  }) {
    return StudentModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      university: university ?? this.university,
      course: course ?? this.course,
      nationalId: nationalId ?? this.nationalId,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      localId: localId ?? this.localId,
    );
  }
}