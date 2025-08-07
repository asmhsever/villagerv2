class VehicleModel {
  final int vehicleId;
  final int houseId;
  final String? brand;
  final String? model;
  final String? number;
  final String? img;

  VehicleModel({
    required this.vehicleId,
    required this.houseId,
    this.brand,
    this.model,
    this.number,
    this.img,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      vehicleId: json['vehicle_id'],
      houseId: json['house_id'],
      brand: json['brand'],
      model: json['model'],
      number: json['number'],
      img: json['img'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'house_id': houseId,
      'brand': brand,
      'model': model,
      'number': number,
      'img': img,
    };
  }
}
