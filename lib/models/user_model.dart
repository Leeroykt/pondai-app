class UserModel {
  final int    id;
  final String fullName;
  final String email;

  UserModel({ required this.id, required this.fullName, required this.email });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:       j['id'],
    fullName: j['full_name'],
    email:    j['email'],
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'full_name': fullName, 'email': email
  };
}