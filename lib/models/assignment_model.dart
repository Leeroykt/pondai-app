class AssignmentModel {
  final int?   id;
  final int?   studentId;
  final int?   houseId;
  final String studentName;
  final String houseAddress;
  final String roomNumber;
  final String startDate;
  final String? endDate;
  final String status;
  final bool   isSynced;
  final String? localId;

  AssignmentModel({
    this.id, this.studentId, this.houseId,
    this.studentName = '', this.houseAddress = '',
    this.roomNumber = '', required this.startDate,
    this.endDate, this.status = 'active',
    this.isSynced = true, this.localId,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> j) => AssignmentModel(
    id:           j['id'],
    studentId:    j['student_id'],
    houseId:      j['house_id'],
    studentName:  j['student']?['full_name'] ?? '',
    houseAddress: j['house']?['address'] ?? '',
    roomNumber:   j['room_number'] ?? '',
    startDate:    j['start_date'] ?? '',
    endDate:      j['end_date'],
    status:       j['status'] ?? 'active',
    isSynced:     true,
  );

  factory AssignmentModel.fromLocal(Map<String, dynamic> j) => AssignmentModel(
    id:           j['server_id'],
    localId:      j['local_id'],
    studentId:    j['student_id'],
    houseId:      j['house_id'],
    studentName:  j['student_name'] ?? '',
    houseAddress: j['house_address'] ?? '',
    roomNumber:   j['room_number'] ?? '',
    startDate:    j['start_date'] ?? '',
    endDate:      j['end_date'],
    status:       j['status'] ?? 'active',
    isSynced:     j['is_synced'] == 1,
  );

  Map<String, dynamic> toJson() => {
    'student_id': studentId, 'house_id': houseId,
    'room_number': roomNumber, 'start_date': startDate,
    'end_date': endDate,
  };

  Map<String, dynamic> toLocal(String localId) => {
    'local_id':     localId,
    'server_id':    id,
    'student_id':   studentId,
    'house_id':     houseId,
    'student_name': studentName,
    'house_address':houseAddress,
    'room_number':  roomNumber,
    'start_date':   startDate,
    'end_date':     endDate,
    'status':       status,
    'is_synced':    isSynced ? 1 : 0,
  };
}