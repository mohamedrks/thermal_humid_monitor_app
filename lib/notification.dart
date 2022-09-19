import 'package:thermal_humid_monitor_app/infor.dart';

class Notif {
  final List<Infor> information;

  Notif(this.information);

  Notif.fromJson(Map<String, dynamic> json) : information = json['timestamp'];

  Map<String, dynamic> toJson() => {
        'timestamp': information,
      };
}
