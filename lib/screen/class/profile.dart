class Profiles {
  String name;
  String path;
  String email;
  List? activity;

  Profiles({
    required this.email,
    required this.name,
    required this.path,
    this.activity,
  });

  factory Profiles.fromJson(Map<String, dynamic> json) {
    return Profiles(
      name: json['name'] as String,
      path: json['path'] as String,
      email: json['email'] as String,
      activity: json['activities'],
    );
  }
}
