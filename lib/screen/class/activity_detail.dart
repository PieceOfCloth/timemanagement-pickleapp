// ignore_for_file: non_constant_identifier_names

class DetailActivities {
  int id_act;
  int id_sch;
  String title;
  String imp_type;
  String urg_type;
  String rpt_freq;
  int? rpt_int;
  String? cat_name;
  int? clr_a;
  int? clr_r;
  int? clr_g;
  int? clr_b;
  String str_time;
  String end_time;
  List? tasks;
  List? files;
  List? locations;

  DetailActivities({
    required this.id_act,
    required this.id_sch,
    required this.title,
    required this.imp_type,
    required this.urg_type,
    required this.rpt_freq,
    this.rpt_int,
    this.cat_name,
    this.clr_a,
    this.clr_r,
    this.clr_g,
    this.clr_b,
    required this.str_time,
    required this.end_time,
    this.tasks,
    this.files,
    this.locations,
  });

  factory DetailActivities.fromJson(Map<String, dynamic> json) {
    return DetailActivities(
      id_act: json['activity_id'] as int,
      id_sch: json['scheduled_id'] as int,
      title: json['title'] as String,
      imp_type: json['important_type'] as String,
      urg_type: json['urgent_type'] as String,
      rpt_freq: json['repeat_frequency'] as String,
      rpt_int: json['repeat_interval'] as int?,
      cat_name: json['category_name'] as String?,
      clr_a: json['color_a'] as int?,
      clr_r: json['color_r'] as int?,
      clr_g: json['color_g'] as int?,
      clr_b: json['color_b'] as int?,
      str_time: json['start_time'] as String,
      end_time: json['end_time'] as String,
      tasks: json['tasks'],
      files: json['files'],
      locations: json['address'],
    );
  }
}
