// lib/core/location/location_controller.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';

class LocationState {
  final String city; // "Не определено" или реальный город
  final bool isLoading;

  const LocationState({
    required this.city,
    required this.isLoading,
  });

  LocationState copyWith({String? city, bool? isLoading}) => LocationState(
        city: city ?? this.city,
        isLoading: isLoading ?? this.isLoading,
      );

  static const LocationState initial =
      LocationState(city: 'Не определено', isLoading: false);
}

final locationControllerProvider =
    StateNotifierProvider<LocationController, LocationState>(
  (ref) => LocationController(),
);

class LocationController extends StateNotifier<LocationState> {
  LocationController() : super(LocationState.initial);

  bool _initialized = false;

  /// Вариант B:
  /// - если permission уже выдан: просто получаем координаты
  /// - если не выдан: запрашиваем один раз (системный диалог)
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _resolveCity();
  }

  Future<void> refresh() async {
    await _resolveCity();
  }

  Future<void> _resolveCity() async {
    state = state.copyWith(isLoading: true);

    try {
      // 0) сервис геолокации включён?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = const LocationState(city: 'Не определено', isLoading: false);
        return;
      }

      // 1) permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        state = const LocationState(city: 'Не определено', isLoading: false);
        return;
      }

      // 2) координаты
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 7),
      );

      // 3) reverse geocoding -> город
      final city = await _reverseToCity(pos.latitude, pos.longitude);
      state = LocationState(city: city ?? 'Не определено', isLoading: false);
    } on TimeoutException {
      state = const LocationState(city: 'Не определено', isLoading: false);
    } catch (_) {
      state = const LocationState(city: 'Не определено', isLoading: false);
    }
  }

  Future<String?> _reverseToCity(double lat, double lng) async {
    final placemarks = await geocoding.placemarkFromCoordinates(lat, lng);

    if (placemarks.isEmpty) return null;
    final p = placemarks.first;

    // Правило (как мы утвердили):
    // 1) locality (город)
    // 2) subAdministrativeArea / administrativeArea (область/регион)
    final city = _clean(p.locality);
    if (city != null) return city;

    final subAdmin = _clean(p.subAdministrativeArea);
    if (subAdmin != null) return subAdmin;

    final admin = _clean(p.administrativeArea);
    if (admin != null) return admin;

    return null;
  }

  String? _clean(String? s) {
    final v = (s ?? '').trim();
    return v.isEmpty ? null : v;
  }
}
