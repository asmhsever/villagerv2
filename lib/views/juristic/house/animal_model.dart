// lib/views/juristic/house/animal_model.dart

class Animal {
  final int animalId;
  final int houseId;
  final String? type;
  final String? name;
  final String? img;

  Animal({
    required this.animalId,
    required this.houseId,
    this.type,
    this.name,
    this.img,
  });

  factory Animal.fromMap(Map<String, dynamic> map) => Animal(
    animalId: map['animal_id'],
    houseId: map['house_id'],
    type: map['type'],
    name: map['name'],
    img: map['img'],
  );

  Map<String, dynamic> toMap() => {
    'animal_id': animalId,
    'house_id': houseId,
    'type': type,
    'name': name,
    'img': img,
  };

  Map<String, dynamic> toInsertMap() => {
    'house_id': houseId,
    'type': type,
    'name': name,
    'img': img,
  };

  Animal copyWith({
    int? animalId,
    int? houseId,
    String? type,
    String? name,
    String? img,
  }) {
    return Animal(
      animalId: animalId ?? this.animalId,
      houseId: houseId ?? this.houseId,
      type: type ?? this.type,
      name: name ?? this.name,
      img: img ?? this.img,
    );
  }
}
