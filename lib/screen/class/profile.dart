class ProfileClass {
  String name;
  String path;
  String email;
  List? activity;

  ProfileClass({
    required this.email,
    required this.name,
    required this.path,
    this.activity,
  });

  factory ProfileClass.fromJson(Map<String, dynamic> json) {
    return ProfileClass(
      name: json['name'] as String,
      path: json['path'] as String,
      email: json['email'] as String,
      activity: json['activities'],
    );
  }

  @override
  String toString() {
    return 'Profile: [{name: $name, path: $path, email: $email, activities: $activity,}]';
  }
}
