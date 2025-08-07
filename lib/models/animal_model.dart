class AnimalModel {
  final int animalId;
  final int houseId;
  final String? type;
  final String? name;
  final String? img;

  AnimalModel({
    required this.animalId,
    required this.houseId,
    this.type,
    this.name,
    this.img,
  });

  factory AnimalModel.fromJson(Map<String, dynamic> json) {
    return AnimalModel(
      animalId: json['animal_id'],
      houseId: json['house_id'],
      type: json['type'],
      name: json['name'],
      img: json['img'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'animal_id': animalId,
      'house_id': houseId,
      'type': type,
      'name': name,
      'img': img,
    };
  }
}
