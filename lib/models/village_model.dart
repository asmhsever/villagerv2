class VillageModel {
  final int villageId;
  final int provinceId;
  final String? name;
  final String? address;
  final String? salePhone;
  final String? zipCode;
  final String? logoImg;
  final String? ruleImgs;

  VillageModel({
    required this.villageId,
    required this.provinceId,
    this.name,
    this.address,
    this.salePhone,
    this.zipCode,
    this.logoImg,
    this.ruleImgs,
  });

  factory VillageModel.fromJson(Map<String, dynamic> json) {
    return VillageModel(
      villageId: json['village_id'] ?? 0,
      provinceId: json['province_id'] ?? 0,
      name: json['name'] ?? "",
      address: json['address'] ?? "",
      salePhone: json['sale_phone'] ?? "",
      zipCode: json['zip_code'] ?? "",
      logoImg: json['logo_img'] ?? "",
      ruleImgs: json['rule_imgs'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'village_ud': villageId,
      'province_id': provinceId,
      'name': name,
      'address': address,
      'sale_phone': salePhone,
      'zip_code': zipCode,
      'logo_img': logoImg,
      'rule_imgs': ruleImgs,
    };
  }
}
