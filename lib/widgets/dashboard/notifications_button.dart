import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/notifications/notifications_cubit.dart';
import 'package:argrity/theme/kali_colors_extension.dart';

class NotificationsButton extends StatelessWidget {
  const NotificationsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final unreadCount = state.unreadCount;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.notifications,
                  color: kaliColors.espresso.withValues(alpha: 0.6)),
              onPressed: () {
                _showNotificationsMenu(context, state.notifications);
                context.read<NotificationsCubit>().markAllAsRead();
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4685C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: TextStyle(
                      color: kaliColors.warmWhite,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showNotificationsMenu(
      BuildContext context, List<NotificationItem> notifications) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final Offset position =
        button.localToGlobal(Offset.zero, ancestor: overlay);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx - 250,
        position.dy + button.size.height,
        position.dx + button.size.width,
        position.dy + button.size.height,
      ),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: kaliColors.warmWhite,
      constraints: const BoxConstraints(maxWidth: 320, maxHeight: 400),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notificaciones',
                style: kaliColors.body(kaliColors.espresso,
                    weight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Divider(color: kaliColors.sand2, height: 1),
            ],
          ),
        ),
        if (notifications.isEmpty)
          PopupMenuItem(
            enabled: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('No hay notificaciones',
                    style: kaliColors
                        .body(kaliColors.espresso.withValues(alpha: 0.65))),
              ),
            ),
          )
        else
          ...notifications.map((n) => PopupMenuItem(
                value: n.id,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title,
                        style: kaliColors.body(kaliColors.espresso,
                            weight: FontWeight.w600, size: 14)),
                    const SizedBox(height: 4),
                    Text(n.message,
                        style: kaliColors.body(kaliColors.espresso, size: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      '${n.timestamp.hour.toString().padLeft(2, '0')}:${n.timestamp.minute.toString().padLeft(2, '0')}',
                      style: kaliColors
                          .caption(kaliColors.espresso.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}
