import 'package:flutter_bloc/flutter_bloc.dart';

part 'activity_event.dart';
part 'activity_state.dart';

/// BLoC que actúa como logger de actividad de sesión en memoria.
///
/// No persiste en DB — vive mientras la app está abierta.
/// Otros BLoCs (Alumnos, Turnos, Auth) disparan [ActivityLogged]
/// para registrar acciones del usuario. El Dashboard las consume
/// para mostrar el feed de "Actividad Reciente".
class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  ActivityBloc() : super(const ActivityState()) {
    on<ActivityLogged>((event, emit) => emit(state.withNewEntry(event.entry)));
    on<ActivityCleared>((event, emit) => emit(state.cleared()));
  }
}
