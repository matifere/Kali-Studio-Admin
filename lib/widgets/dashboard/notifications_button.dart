import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:argrity/bloc/notifications/notifications_cubit.dart';
import 'package:argrity/theme/kali_theme.dart';

class NotificationsButton extends StatelessWidget {
  const NotificationsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final unreadCount = state.unreadCount;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.notifications,
                  color: KaliColors.espresso.withValues(alpha: 0.6)),
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
                    style: const TextStyle(
                      color: KaliColors.warmWhite,
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
      color: KaliColors.warmWhite,
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
                style:
                    KaliText.body(KaliColors.espresso, weight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Divider(color: KaliColors.sand2, height: 1),
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
                    style: KaliText.body(
                        KaliColors.espresso.withValues(alpha: 0.5))),
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
                        style: KaliText.body(KaliColors.espresso,
                            weight: FontWeight.w600, size: 14)),
                    const SizedBox(height: 4),
                    Text(n.message,
                        style: KaliText.body(KaliColors.espresso, size: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      '${n.timestamp.hour.toString().padLeft(2, '0')}:${n.timestamp.minute.toString().padLeft(2, '0')}',
                      style: KaliText.caption(
                          KaliColors.espresso.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}
