// lib/views/juristic/house/villager_model.dart

class Villager {
  final int villagerId;
  final int houseId;
  final String? firstName;
  final String? lastName;
  final String? birthDate;
  final String? gender;
  final String? phone;
  final String? cardNumber;

  Villager({
    required this.villagerId,
    required this.houseId,
    this.firstName,
    this.lastName,
    this.birthDate,
    this.gender,
    this.phone,
    this.cardNumber,
  });

  factory Villager.fromMap(Map<String, dynamic> map) => Villager(
    villagerId: map['villager_id'],
    houseId: map['house_id'],
    firstName: map['first_name'],
    lastName: map['last_name'],
    birthDate: map['birth_date'],
    gender: map['gender'],
    phone: map['phone'],
    cardNumber: map['card_number'],
  );

  Map<String, dynamic> toMap() => {
    'villager_id': villagerId,
    'house_id': houseId,
    'first_name': firstName,
    'last_name': lastName,
    'birth_date': birthDate,
    'gender': gender,
    'phone': phone,
    'card_number': cardNumber,
  };

  Map<String, dynamic> toInsertMap() => {
    'house_id': houseId,
    'first_name': firstName,
    'last_name': lastName,
    'birth_date': birthDate,
    'gender': gender,
    'phone': phone,
    'card_number': cardNumber,
  };

  Villager copyWith({
    int? villagerId,
    int? houseId,
    String? firstName,
    String? lastName,
    String? birthDate,
    String? gender,
    String? phone,
    String? cardNumber,
  }) => Villager(
    villagerId: villagerId ?? this.villagerId,
    houseId: houseId ?? this.houseId,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    birthDate: birthDate ?? this.birthDate,
    gender: gender ?? this.gender,
    phone: phone ?? this.phone,
    cardNumber: cardNumber ?? this.cardNumber,
  );
}
