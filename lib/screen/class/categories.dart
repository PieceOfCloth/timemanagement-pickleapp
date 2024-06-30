class Category {
  int id;
  String title;
  int colorA;
  int colorR;
  int colorG;
  int colorB;

  Category({
    required this.id,
    required this.title,
    required this.colorA,
    required this.colorR,
    required this.colorG,
    required this.colorB,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json["id"],
      title: json["title"],
      colorA: json["colorA"],
      colorR: json["colorR"],
      colorG: json["colorG"],
      colorB: json["colorB"],
    );
  }
}
