class Locations {
  String name;
  String district;
  String region;
  String state;

  Locations(this.name, this.district, this.region, this.state);

  factory Locations.fromJson(Map<String, dynamic> json) {
    return Locations(
        json['Name'], json['District'], json['Region'], json['State']);
  }
}
