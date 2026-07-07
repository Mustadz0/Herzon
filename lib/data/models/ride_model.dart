// â”€â”€â”€ RideModel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Represents a ride-sharing offer created by a driver.
class RideModel {
  final String    id;
  final String    driverId;
  final double    originLat;
  final double    originLng;
  final String    originName;
  final double    destinationLat;
  final double    destinationLng;
  final String    destinationName;
  final DateTime  departureTime;
  final int       seatsAvailable;
  final double    pricePerSeat;
  final String?   description;
  final String    status;            // e.g. 'open', 'full', 'completed', 'cancelled'
  final DateTime  createdAt;

  const RideModel({
    required this.id,
    required this.driverId,
    required this.originLat,
    required this.originLng,
    required this.originName,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationName,
    required this.departureTime,
    required this.seatsAvailable,
    required this.pricePerSeat,
    this.description,
    required this.status,
    required this.createdAt,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) => RideModel(
    id:              json['id']               as String,
    driverId:        json['driver_id']        as String,
    originLat:       (json['origin_lat']      as num).toDouble(),
    originLng:       (json['origin_lng']      as num).toDouble(),
    originName:      json['origin_name']      as String,
    destinationLat:  (json['destination_lat'] as num).toDouble(),
    destinationLng:  (json['destination_lng'] as num).toDouble(),
    destinationName: json['destination_name'] as String,
    departureTime:   DateTime.parse(json['departure_time'] as String),
    seatsAvailable:  json['seats_available']  as int,
    pricePerSeat:    (json['price_per_seat']  as num).toDouble(),
    description:     json['description']      as String?,
    status:          json['status']           as String,
    createdAt:       DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id':               id,
    'driver_id':        driverId,
    'origin_lat':       originLat,
    'origin_lng':       originLng,
    'origin_name':      originName,
    'destination_lat':  destinationLat,
    'destination_lng':  destinationLng,
    'destination_name': destinationName,
    'departure_time':   departureTime.toIso8601String(),
    'seats_available':  seatsAvailable,
    'price_per_seat':   pricePerSeat,
    'description':      description,
    'status':           status,
    'created_at':       createdAt.toIso8601String(),
  };
}

// â”€â”€â”€ RidePassengerModel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Represents a passenger's booking on a ride.
class RidePassengerModel {
  final String    id;
  final String    rideId;
  final String    passengerId;
  final int       seatsBooked;
  final String    status;     // e.g. 'pending', 'confirmed', 'cancelled'
  final DateTime  createdAt;

  const RidePassengerModel({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.seatsBooked,
    required this.status,
    required this.createdAt,
  });

  factory RidePassengerModel.fromJson(Map<String, dynamic> json) => RidePassengerModel(
    id:           json['id']           as String,
    rideId:       json['ride_id']      as String,
    passengerId:  json['passenger_id'] as String,
    seatsBooked:  json['seats_booked'] as int,
    status:       json['status']       as String,
    createdAt:    DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id':            id,
    'ride_id':       rideId,
    'passenger_id':  passengerId,
    'seats_booked':  seatsBooked,
    'status':        status,
    'created_at':    createdAt.toIso8601String(),
  };
}
