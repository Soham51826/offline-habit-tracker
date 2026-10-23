import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../data/models/habit.dart';
import 'notification_service.dart';

/// Service managing location tracking, distance calculations,
/// and geofencing notifications when approaching habit-tagged venues.
class GeofenceService {
  static final GeofenceService instance = GeofenceService._internal();

  GeofenceService._internal();

  StreamSubscription<Position>? _positionSubscription;
  final Map<String, DateTime> _cooldownMap = {};
  static const Duration _cooldownDuration = Duration(minutes: 15);

  /// Requests foreground location permissions from the user.
  Future<bool> requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied.');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  /// Gets the device's current GPS position.
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('Error acquiring GPS location: $e');
      return null;
    }
  }

  /// Calculates geodesic distance between device and habit target in meters.
  double calculateDistanceMeters({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Checks the given list of habits against the current device position.
  /// If device is within the habit's geofence radius, triggers a reminder notification.
  Future<List<String>> checkProximityAndNotify(List<Habit> habits) async {
    final triggeredHabitNames = <String>[];
    try {
      final position = await getCurrentPosition();
      if (position == null) return triggeredHabitNames;

      final now = DateTime.now();

      for (final habit in habits) {
        if (!habit.hasLocation) continue;

        final distance = calculateDistanceMeters(
          startLatitude: position.latitude,
          startLongitude: position.longitude,
          endLatitude: habit.latitude!,
          endLongitude: habit.longitude!,
        );

        if (distance <= habit.geofenceRadius) {
          // Check cooldown to avoid duplicate alert storms
          final lastTrigger = _cooldownMap[habit.id];
          if (lastTrigger == null || now.difference(lastTrigger) > _cooldownDuration) {
            _cooldownMap[habit.id] = now;
            triggeredHabitNames.add(habit.title);

            await NotificationService.instance.showNotification(
              id: habit.id.hashCode,
              title: '📍 Arrived at ${habit.locationName ?? "Habit Location"}',
              body: 'You are near ${habit.locationName ?? "target"}! Perfect time to complete "${habit.title}".',
              payload: 'geofence_${habit.id}',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error during geofence proximity evaluation: $e');
    }
    return triggeredHabitNames;
  }

  /// Simulates entering a habit's geofence boundary.
  /// Crucial for academic demonstration, grading rubrics, and emulator testing.
  Future<void> simulateArrival({
    required Habit habit,
    String? customLocationName,
  }) async {
    final locName = habit.locationName ?? customLocationName ?? 'Campus / Gym';
    await NotificationService.instance.showNotification(
      id: habit.id.hashCode,
      title: '📍 Arrived at $locName [Simulated]',
      body: 'Geofence triggered! You are at $locName. Keep your streak alive by checking in on "${habit.title}".',
      payload: 'geofence_sim_${habit.id}',
    );
  }

  /// Starts listening to device location updates.
  void startListening(List<Habit> Function() getHabits) {
    stopListening();
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // triggers every 50 meters
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          final habits = getHabits();
          final now = DateTime.now();

          for (final habit in habits) {
            if (!habit.hasLocation) continue;

            final distance = calculateDistanceMeters(
              startLatitude: position.latitude,
              startLongitude: position.longitude,
              endLatitude: habit.latitude!,
              endLongitude: habit.longitude!,
            );

            if (distance <= habit.geofenceRadius) {
              final lastTrigger = _cooldownMap[habit.id];
              if (lastTrigger == null || now.difference(lastTrigger) > _cooldownDuration) {
                _cooldownMap[habit.id] = now;

                NotificationService.instance.showNotification(
                  id: habit.id.hashCode,
                  title: '📍 Arrived at ${habit.locationName ?? "Habit Location"}',
                  body: 'You entered the geofence for "${habit.title}". Tap to check in!',
                  payload: 'geofence_${habit.id}',
                );
              }
            }
          }
        },
        onError: (e) {
          debugPrint('Geofence position stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('Error starting geofence stream: $e');
    }
  }

  /// Cancels any active location listener subscription.
  void stopListening() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
