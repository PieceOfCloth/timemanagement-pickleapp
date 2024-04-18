
class Files {
  String name;
  String path;

  Files({
    required this.name,
    required this.path,
  });

  @override
  String toString() {
    return '{"name": "$name", "path": "$path"}';
  }
}
