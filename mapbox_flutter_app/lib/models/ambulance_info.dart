class AmbulanceInfo {
  final int id;
  final String driverName;
  final double latitude;
  final double longitude;
  final bool available;
  final String? status;

  AmbulanceInfo({
    required this.id,
    required this.driverName,
    required this.latitude,
    required this.longitude,
    required this.available,
    this.status,
  });

  factory AmbulanceInfo.fromJson(Map<String, dynamic> json) {
    return AmbulanceInfo(
      id: json['id'] as int? ?? 0,
      driverName: json['driverName'] as String? ?? 'Unknown Driver',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      available: json['available'] as bool? ?? true,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverName': driverName,
      'latitude': latitude,
      'longitude': longitude,
      'available': available,
      if (status != null) 'status': status,
    };
  }
}
