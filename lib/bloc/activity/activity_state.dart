part of 'activity_bloc.dart';

/// Una entrada individual en el feed de actividad reciente.
class ActivityEntry {
  final String title;
  final String subtitle;
  final ActivityCategory category;
  final DateTime timestamp;

  const ActivityEntry({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.timestamp,
  });
}

enum ActivityCategory { alumno, turno, pago, perfil }

class ActivityState {
  /// Máximo de entradas que se mantienen en memoria.
  static const int _maxEntries = 20;

  final List<ActivityEntry> entries;

  const ActivityState({this.entries = const []});

  ActivityState withNewEntry(ActivityEntry entry) {
    final updated = [entry, ...entries];
    return ActivityState(
      entries: updated.length > _maxEntries
          ? updated.sublist(0, _maxEntries)
          : updated,
    );
  }

  ActivityState cleared() => const ActivityState();
}
