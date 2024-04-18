class Locations {
  String address;
  double latitude;
  double longitude;

  Locations({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() {
    return '{"address": "$address", "latitude": $latitude, "longitude": $longitude}';
  }

  // factory Location.fromJSON(Map<String, dynamic> json) {
  //   return Location(
  //       name: json["id"] as String,
  //       latitude: json["address"] as String,
  //       longitude: json["address"] as String);
  // }
}
