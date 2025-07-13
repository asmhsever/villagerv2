// lib/views/juristic/house/car_model.dart

class Car {
  final int carId;
  final int houseId;
  final String? brand;
  final String? model;
  final String? number;
  final String? img;

  Car({
    required this.carId,
    required this.houseId,
    this.brand,
    this.model,
    this.number,
    this.img,
  });

  factory Car.fromMap(Map<String, dynamic> map) => Car(
    carId: map['car_id'],
    houseId: map['house_id'],
    brand: map['brand'],
    model: map['model'],
    number: map['number'],
    img: map['img'],
  );

  Map<String, dynamic> toMap() => {
    'car_id': carId,
    'house_id': houseId,
    'brand': brand,
    'model': model,
    'number': number,
    'img': img,
  };

  Map<String, dynamic> toInsertMap() => {
    'house_id': houseId,
    'brand': brand,
    'model': model,
    'number': number,
    'img': img,
  };

  Car copyWith({
    int? carId,
    int? houseId,
    String? brand,
    String? model,
    String? number,
    String? img,
  }) {
    return Car(
      carId: carId ?? this.carId,
      houseId: houseId ?? this.houseId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      number: number ?? this.number,
      img: img ?? this.img,
    );
  }
}
