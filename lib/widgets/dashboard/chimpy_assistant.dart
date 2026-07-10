import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:argrity/bloc/dashboard/dashboard_bloc.dart';
import 'package:argrity/services/chimpy_service.dart';
import 'package:argrity/services/profile_cache.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/widgets/dashboard/chimpy_face.dart';

/// Chimpy: el mono asistente del dashboard.
///
/// Botón flotante con la cara de Chimpy abajo a la derecha; al tocarlo se
/// abre el chat (y aparece el mono colgado del saludo). Responde con las
/// métricas reales del día (asistencias, clases, pagos, reservas,
/// cancelaciones y novedades).
class ChimpyAssistant extends StatelessWidget {
  final bool open;
  final VoidCallback onToggle;

  const ChimpyAssistant({
    super.key,
    required this.open,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation,
              alignment: Alignment.bottomRight,
              child: child,
            ),
          ),
          child: open
              ? _ChimpyChatPanel(onClose: onToggle)
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onToggle,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Material(
              color: kaliColors.espresso,
              shape: const CircleBorder(),
              elevation: 6,
              shadowColor: kaliColors.espresso.withValues(alpha: 0.3),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: open
                        ? Icon(
                            Icons.close,
                            key: const ValueKey('close'),
                            color: kaliColors.warmWhite,
                            size: 24,
                          )
                        : const ChimpyFace(
                            key: ValueKey('chimpy'),
                            size: 48,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Msg {
  final String text;
  final bool fromUser;
  const _Msg(this.text, {required this.fromUser});
}

class _QuickAction {
  final String label;
  final FutureOr<String> Function() reply;
  const _QuickAction(this.label, this.reply);
}

class _ChimpyChatPanel extends StatefulWidget {
  final VoidCallback onClose;
  const _ChimpyChatPanel({required this.onClose});

  @override
  State<_ChimpyChatPanel> createState() => _ChimpyChatPanelState();
}

class _ChimpyChatPanelState extends State<_ChimpyChatPanel> {
  final List<_Msg> _messages = [];
  final ScrollController _scroll = ScrollController();
  bool _typing = false;
  ChimpyDailyStats? _stats;
  ChimpyMonthlyStats? _monthStats;

  static final _money = NumberFormat('#,###', 'es_ES');

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    await _botSays(_saludo());
    try {
      final stats = await ChimpyService.fetchToday();
      if (!mounted) return;
      _stats = stats;
      await _botSays(_resumen());
    } catch (_) {
      if (!mounted) return;
      await _botSays(
          'Ups, no pude traer los números del día 🙈 Probá cerrarme y abrirme de nuevo.');
    }
  }

  Future<void> _botSays(String text) async {
    setState(() => _typing = true);
    _scrollToEnd();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _typing = false;
      _messages.add(_Msg(text, fromUser: false));
    });
    _scrollToEnd();
  }

  Future<void> _ask(_QuickAction action) async {
    if (_typing || _stats == null) return;
    setState(() {
      _messages.add(_Msg(action.label, fromUser: true));
      // Muestra los puntitos también mientras se consulta Supabase (las
      // respuestas del mes se cargan on-demand).
      _typing = true;
    });
    _scrollToEnd();
    String text;
    try {
      text = await action.reply();
    } catch (_) {
      text =
          'Ups, no pude traer esos números 🙈 Probá de nuevo en un ratito.';
    }
    if (!mounted) return;
    await _botSays(text);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ─── Respuestas (datos reales del día) ────────────────────────────────────

  String _saludo() {
    final hour = DateTime.now().hour;
    final nombre = ProfileCache.fullName?.trim().split(' ').first;
    final base = hour < 12
        ? '¡Buen día'
        : hour < 19
            ? '¡Buenas tardes'
            : '¡Buenas noches';
    final saludo =
        nombre != null && nombre.isNotEmpty ? '$base, $nombre!' : '$base!';
    return '$saludo Soy Chimpy 🐵 Dejame contarte cómo viene el día...';
  }

  String _plural(int n, String singular, String plural) =>
      n == 1 ? '$n $singular' : '$n $plural';

  String _resumen() {
    final s = _stats!;
    final lines = <String>[
      '🏋️ ${_plural(s.sesiones.length, 'clase programada', 'clases programadas')}',
      '✅ ${_plural(s.totalPresentes, 'asistencia', 'asistencias')} (${(s.ocupacion * 100).toInt()}% de la capacidad del día)',
      '📆 ${_plural(s.totalReservas, 'reserva activa', 'reservas activas')} para hoy',
      '❌ ${_plural(s.cancelacionesHoy, 'cancelación', 'cancelaciones')}',
      if (ProfileCache.isSudo)
        '💰 ${_plural(s.pagosHoy, 'pago recibido', 'pagos recibidos')}${s.pagosHoy > 0 ? ' por \$${_money.format(s.montoPagosHoy)}' : ''}',
      if (s.alumnosNuevosHoy > 0)
        '🐣 ${_plural(s.alumnosNuevosHoy, 'alumno nuevo', 'alumnos nuevos')}',
    ];
    final venc = context.read<DashboardBloc>().state.vencimientosProximos;
    if (venc > 0) {
      lines.add(
          '⚠️ ${_plural(venc, 'suscripción vence', 'suscripciones vencen')} en los próximos 7 días');
    }
    return 'Así viene el día:\n\n${lines.join('\n')}\n\nTocá una opción para ver el detalle 👇';
  }

  Future<String> _resumenMes() async {
    final m = _monthStats ??= await ChimpyService.fetchMonth();
    final mes = DateFormat('MMMM', 'es_ES').format(DateTime.now());
    final lines = <String>[
      '🏋️ ${_plural(m.clases, 'clase dictada', 'clases dictadas')}',
      '✅ ${_plural(m.presentes, 'asistencia', 'asistencias')} (${(m.ocupacion * 100).toInt()}% de la capacidad del mes)',
      '📆 ${_plural(m.reservas, 'reserva activa', 'reservas activas')}${m.reservas > 0 ? ' (${(m.presentismo * 100).toInt()}% de presentismo)' : ''}',
      '❌ ${_plural(m.cancelaciones, 'cancelación', 'cancelaciones')}',
      if (m.noShows > 0)
        '👻 ${_plural(m.noShows, 'no-show', 'no-shows')}',
      if (ProfileCache.isSudo)
        '💰 ${_plural(m.pagos, 'pago recibido', 'pagos recibidos')}${m.pagos > 0 ? ' por \$${_money.format(m.montoPagos)}' : ''}',
      if (m.alumnosNuevos > 0)
        '🐣 ${_plural(m.alumnosNuevos, 'alumno nuevo', 'alumnos nuevos')}',
    ];
    return 'Así viene $mes (del 1° hasta hoy):\n\n${lines.join('\n')}';
  }

  String _clasesHoy() {
    final s = _stats!;
    if (s.sesiones.isEmpty) {
      return 'Hoy no hay clases programadas 🧘 Buen momento para planificar la semana.';
    }
    final lines = s.sesiones
        .map((c) =>
            '• ${c.startTime} · ${c.name} — ${c.reservas}/${c.capacity} reservas, ${_plural(c.presentes, 'presente', 'presentes')}')
        .join('\n');
    final top = s.turnoMasLleno;
    final extra = top != null && top.reservas > 0
        ? '\n\nLa más llena es ${top.name} de las ${top.startTime} (${(top.ocupacion * 100).toInt()}% del cupo).'
        : '';
    return 'Estas son las clases de hoy:\n\n$lines$extra';
  }

  String _asistencias() {
    final s = _stats!;
    if (s.sesiones.isEmpty) {
      return 'Sin clases hoy, así que no hay asistencias para contar 🙊';
    }
    if (s.totalReservas == 0) {
      return 'Las clases de hoy todavía no tienen reservas, así que no hay asistencias registradas.';
    }
    final pct = ((s.totalPresentes / s.totalReservas) * 100).toInt();
    var msg =
        'Hoy se registraron ${_plural(s.totalPresentes, 'asistencia', 'asistencias')} sobre ${_plural(s.totalReservas, 'reserva activa', 'reservas activas')} ($pct% de presentismo hasta ahora).';
    msg +=
        '\n\nLa capacidad total del día es de ${s.totalCapacidad} lugares: alcanzaste el ${(s.ocupacion * 100).toInt()}%.';
    if (s.totalNoShows > 0) {
      msg +=
          '\n\n👻 ${_plural(s.totalNoShows, 'alumno no se presentó', 'alumnos no se presentaron')} (no-show).';
    }
    return msg;
  }

  String _reservas() {
    final s = _stats!;
    var msg = s.totalCapacidad > 0
        ? 'Las clases de hoy tienen ${_plural(s.totalReservas, 'reserva activa', 'reservas activas')} sobre ${s.totalCapacidad} lugares (${((s.totalReservas / s.totalCapacidad) * 100).toInt()}% del cupo).'
        : 'Hoy no hay cupos abiertos, así que no hay reservas para las clases de hoy.';
    final hechas = s.reservasHechasHoy;
    if (hechas != null) {
      msg += hechas > 0
          ? '\n\nAdemás, hoy se ${hechas == 1 ? 'hizo 1 reserva nueva' : 'hicieron $hechas reservas nuevas'} (contando clases futuras).'
          : '\n\nHoy todavía no se hicieron reservas nuevas.';
    }
    return msg;
  }

  String _cancelaciones() {
    final s = _stats!;
    if (s.cancelacionesHoy == 0) {
      return 'Nadie canceló hoy 🎉 Cero bajas por ahora.';
    }
    return 'Hoy se ${s.cancelacionesHoy == 1 ? 'canceló 1 reserva' : 'cancelaron ${s.cancelacionesHoy} reservas'}. Se liberó el cupo para otros alumnos.';
  }

  String _pagos() {
    final s = _stats!;
    final ingresos = context.read<DashboardBloc>().state.ingresosMensuales;
    var msg = s.pagosHoy > 0
        ? 'Hoy se ${s.pagosHoy == 1 ? 'registró 1 pago' : 'registraron ${s.pagosHoy} pagos'} por \$${_money.format(s.montoPagosHoy)} 💸'
        : 'Hoy todavía no se registraron pagos.';
    msg +=
        '\n\nLos ingresos del mes van en \$${_money.format(ingresos)} (suscripciones activas).';
    return msg;
  }

  String _novedades() {
    final s = _stats!;
    final venc = context.read<DashboardBloc>().state.vencimientosProximos;
    final lines = <String>[
      if (s.alumnosNuevosHoy > 0)
        '🐣 Hoy se ${s.alumnosNuevosHoy == 1 ? 'sumó 1 alumno nuevo' : 'sumaron ${s.alumnosNuevosHoy} alumnos nuevos'}. ¡Dale la bienvenida!',
      if (venc > 0)
        '⚠️ ${_plural(venc, 'suscripción vence', 'suscripciones vencen')} en los próximos 7 días. Conviene avisarles a los alumnos.',
    ];
    final top = _stats!.turnoMasLleno;
    if (top != null && top.ocupacion >= 0.85) {
      lines.add(
          '🔥 ${top.name} de las ${top.startTime} está casi llena (${top.reservas}/${top.capacity}). Considerá abrir otro turno.');
    }
    if (lines.isEmpty) {
      return 'Sin novedades por ahora, todo tranquilo por la selva 🌴';
    }
    return lines.join('\n\n');
  }

  List<_QuickAction> get _actions => [
        _QuickAction('🏋️ Clases de hoy', _clasesHoy),
        _QuickAction('✅ Asistencias', _asistencias),
        _QuickAction('📆 Reservas', _reservas),
        _QuickAction('❌ Cancelaciones', _cancelaciones),
        if (ProfileCache.isSudo) _QuickAction('💰 Pagos', _pagos),
        _QuickAction('✨ Novedades', _novedades),
        _QuickAction('📋 Resumen', _resumen),
        _QuickAction('🗓️ Resumen del mes', _resumenMes),
      ];

  // ─── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final size = MediaQuery.of(context).size;
    final width = math.min(380.0, size.width - 32);
    final height = math.min(500.0, size.height - 180);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: kaliColors.warmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kaliColors.espresso.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: kaliColors.espresso.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(kaliColors),
          Divider(
            height: 1,
            color: kaliColors.espresso.withValues(alpha: 0.06),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_typing ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildBotRow(
                    kaliColors,
                    _TypingDots(color: kaliColors.espresso),
                  );
                }
                final msg = _messages[index];
                return msg.fromUser
                    ? _buildUserBubble(kaliColors, msg.text)
                    : _buildBotRow(
                        kaliColors,
                        _buildBotBubble(kaliColors, msg.text),
                      );
              },
            ),
          ),
          if (_stats != null) _buildQuickActions(kaliColors),
        ],
      ),
    );
  }

  Widget _buildHeader(KaliColorsExtension kaliColors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          const ChimpyFace(size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chimpy',
                  style: kaliColors
                      .heading(kaliColors.espresso, size: 16)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Las métricas de hoy, al toque',
                  style: kaliColors.caption(
                    kaliColors.espresso.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: Icon(
              Icons.close,
              size: 20,
              color: kaliColors.espresso.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotRow(KaliColorsExtension kaliColors, Widget bubble) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const ChimpyFace(size: 26),
          const SizedBox(width: 8),
          Flexible(child: bubble),
        ],
      ),
    );
  }

  Widget _buildBotBubble(KaliColorsExtension kaliColors, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kaliColors.sand,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(14),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Text(
        text,
        style: kaliColors.body(kaliColors.espresso, size: 13.5),
      ),
    );
  }

  Widget _buildUserBubble(KaliColorsExtension kaliColors, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: kaliColors.espresso,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            text,
            style: kaliColors.body(kaliColors.warmWhite, size: 13.5),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(KaliColorsExtension kaliColors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: kaliColors.espresso.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _actions.map((action) {
          final enabled = !_typing;
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: enabled ? () => _ask(action) : null,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: kaliColors.espresso
                      .withValues(alpha: enabled ? 0.15 : 0.06),
                ),
              ),
              child: Text(
                action.label,
                style: kaliColors.body(
                  kaliColors.espresso.withValues(alpha: enabled ? 0.85 : 0.35),
                  size: 12.5,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Tres puntitos animados mientras Chimpy "escribe".
class _TypingDots extends StatefulWidget {
  final Color color;
  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kaliColors.sand,
        borderRadius: BorderRadius.circular(14),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (_controller.value * 3 - i).clamp(0.0, 1.0);
              final opacity =
                  (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.25, 1.0);
              return Padding(
                padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
