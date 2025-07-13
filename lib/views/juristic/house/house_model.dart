// lib/views/juristic/house/house_model.dart

class House {
  final int houseId;
  final String? username;
  final int villageId;
  final String? size;
  final String? password;
  final String? houseNumber;
  final String? phone;
  final String? owner;
  final String? status;

  House({
    required this.houseId,
    required this.villageId,
    this.username,
    this.size,
    this.password,
    this.houseNumber,
    this.phone,
    this.owner,
    this.status,
  });

  factory House.fromMap(Map<String, dynamic> map) => House(
    houseId: map['house_id'],
    username: map['username'],
    villageId: map['village_id'],
    size: map['size'],
    password: map['password'],
    houseNumber: map['house_number'],
    phone: map['phone'],
    owner: map['owner'],
    status: map['status'],
  );

  Map<String, dynamic> toMap() => {
    'house_id': houseId,
    'username': username,
    'village_id': villageId,
    'size': size,
    'password': password,
    'house_number': houseNumber,
    'phone': phone,
    'owner': owner,
    'status': status,
  };

  Map<String, dynamic> toInsertMap() => {
    'username': username,
    'village_id': villageId,
    'size': size,
    'password': password,
    'house_number': houseNumber,
    'phone': phone,
    'owner': owner,
    'status': status,
  };

  House copyWith({
    int? houseId,
    String? username,
    int? villageId,
    String? size,
    String? password,
    String? houseNumber,
    String? phone,
    String? owner,
    String? status,
  }) {
    return House(
      houseId: houseId ?? this.houseId,
      username: username ?? this.username,
      villageId: villageId ?? this.villageId,
      size: size ?? this.size,
      password: password ?? this.password,
      houseNumber: houseNumber ?? this.houseNumber,
      phone: phone ?? this.phone,
      owner: owner ?? this.owner,
      status: status ?? this.status,
    );
  }
}