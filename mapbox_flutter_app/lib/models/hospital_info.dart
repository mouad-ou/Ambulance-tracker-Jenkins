class HospitalInfo {
  final int id;
  final String name;
  final double latitude;
  final double longitude;

  HospitalInfo({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory HospitalInfo.fromJson(Map<String, dynamic> json) {
    return HospitalInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown Hospital',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
