class Infor {
  final num? adjustValue;
  final String info;
  final num? pmv;
  final String state;
  final num? temperature;
  final num? tmplow;
  final num? tmpup;
  final num? timestamp;

  const Infor({
    required this.adjustValue,
    required this.info,
    required this.pmv,
    required this.state,
    required this.temperature,
    required this.tmplow,
    required this.tmpup,
    required this.timestamp,
  });

  factory Infor.fromJson(Map<String, dynamic> json) {
    return Infor(
      adjustValue: json['adjustValue'],
      info: json['info'],
      pmv: json['pmv'],
      state: json['state'],
      temperature: json['temperature'],
      tmplow: json['tmp_low'],
      tmpup: json['tmp_up'],
      timestamp: json['timestamp'],
    );
  }
}
