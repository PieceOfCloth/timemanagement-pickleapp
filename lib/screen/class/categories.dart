class Category {
  int id;
  String title;
  int color_a;
  int color_r;
  int color_g;
  int color_b;

  Category({
    required this.id,
    required this.title,
    required this.color_a,
    required this.color_r,
    required this.color_g,
    required this.color_b,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json["id"],
      title: json["title"],
      color_a: json["color_a"],
      color_r: json["color_r"],
      color_g: json["color_g"],
      color_b: json["color_b"],
    );
  }
}
