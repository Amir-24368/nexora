class GoodsInfoRecord {
  String id;
  String forField;
  String fromField;
  DateTime startDate;
  DateTime endDate;
  double volumeBuying;
  double volumeSelling;
  double price;

  GoodsInfoRecord({
    required this.id,
    required this.forField,
    required this.fromField,
    required this.startDate,
    required this.endDate,
    required this.volumeBuying,
    required this.volumeSelling,
    required this.price,
  });

  factory GoodsInfoRecord.fromJson(Map<String, dynamic> json) => GoodsInfoRecord(
    id: json['id'].toString(),
    forField: json['for_field'],
    fromField: json['from_field'],
    startDate: DateTime.parse(json['start_date']),
    endDate: DateTime.parse(json['end_date']),
    volumeBuying: double.parse(json['volume_buying'].toString()),
    volumeSelling: double.parse(json['volume_selling'].toString()),
    price: double.parse(json['price'].toString()),
  );
}