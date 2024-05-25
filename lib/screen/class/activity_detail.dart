// ignore_for_file: non_constant_identifier_names

class DetailActivities {
  String id_act;
  String id_sch;
  String title;
  String imp_type;
  String urg_type;
  String rpt_freq;
  int? rpt_dur;
  String? cat_name;
  int? clr_a;
  int? clr_r;
  int? clr_g;
  int? clr_b;
  String str_time;
  String end_time;
  String? timezone;
  List? tasks;
  List? files;
  List? locations;
  List? notif;

  DetailActivities({
    required this.id_act,
    required this.id_sch,
    required this.title,
    required this.imp_type,
    required this.urg_type,
    required this.rpt_freq,
    this.rpt_dur,
    this.cat_name,
    this.clr_a,
    this.clr_r,
    this.clr_g,
    this.clr_b,
    required this.str_time,
    required this.end_time,
    this.timezone,
    this.tasks,
    this.files,
    this.locations,
    this.notif,
  });

  factory DetailActivities.fromJson(Map<String, dynamic> json) {
    return DetailActivities(
      id_act: json['activity_id'] as String,
      id_sch: json['scheduled_id'] as String,
      title: json['title'] as String,
      imp_type: json['important_type'] as String,
      urg_type: json['urgent_type'] as String,
      rpt_freq: json['repeat_frequency'] as String,
      rpt_dur: json['repeat_interval'] as int?,
      cat_name: json['category_name'] as String?,
      clr_a: json['color_a'] as int?,
      clr_r: json['color_r'] as int?,
      clr_g: json['color_g'] as int?,
      clr_b: json['color_b'] as int?,
      str_time: json['start_time'] as String,
      end_time: json['end_time'] as String,
      timezone: json['timezone'] as String,
      tasks: json['tasks'],
      files: json['files'],
      locations: json['address'],
      notif: json['notification'],
    );
  }

  @override
  String toString() {
    return 'DetailActivities(id_act: $id_act, id_sch: $id_sch, title: $title, imp_type: $imp_type, urg_type: $urg_type, rpt_freq: $rpt_freq, rpt_dur: $rpt_dur, cat_name: $cat_name, clr_a: $clr_a, clr_r: $clr_r, clr_g: $clr_g, clr_b: $clr_b, str_time: $str_time, end_time: $end_time, timezone: $timezone, tasks: $tasks, files: $files, locations: $locations, notif: $notif)';
  }
}
