part of 'navigation_bloc.dart';

abstract class NavigationEvent {}

/// El usuario presionó un ítem en la sidebar del dashboard.
class NavigationPageChanged extends NavigationEvent {
  final String page;

  NavigationPageChanged(this.page);
}
