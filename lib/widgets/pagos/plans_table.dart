import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/common/kali_icon_button.dart';
import 'package:kali_studio/widgets/pagos/edit_plan_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Directorio/Tabla de planes de pago.
class PlansTable extends StatefulWidget {
  const PlansTable({super.key});

  @override
  State<PlansTable> createState() => _PlansTableState();
}

class _PlansTableState extends State<PlansTable> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('plans')
          .select()
          .order('name', ascending: true);
      if (mounted) {
        setState(() {
          _plans = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar planes: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePlan(Map<String, dynamic> plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Plan',
            style: KaliText.heading(KaliColors.espresso, size: 20)),
        content: Text(
            '¿Estás seguro de que deseas eliminar el plan "${plan['name']}"?',
            style: KaliText.body(KaliColors.espresso)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar',
                style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar',
                style: TextStyle(color: Color(0xFFD4685C), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client
            .from('plans')
            .delete()
            .eq('id', plan['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plan eliminado con éxito')),
          );
        }
        _loadPlans();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar plan: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(child: LinearProgressIndicator()),
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Text(
                  _error!,
                  style: KaliText.body(KaliColors.espresso),
                ),
              ),
            )
          else if (_plans.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Text(
                  'Aún no hay planes creados.',
                  style: KaliText.body(KaliColors.espresso.withValues(alpha: 0.5)),
                ),
              ),
            )
          else ...[
            _buildColumnHeaders(),
            ..._plans.map((p) => _PlanRow(
                  plan: p,
                  onEdit: () {
                    showDialog(
                      context: context,
                      builder: (context) => EditPlanDialog(
                        plan: p,
                        onRefresh: _loadPlans,
                      ),
                    );
                  },
                  onDelete: () => _deletePlan(p),
                )),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Planes del Estudio',
            style: KaliText.headingItalic(KaliColors.espresso, size: 22),
          ),
          KaliIconButton(
            Icons.refresh_rounded,
            tooltip: 'Refrescar planes',
            onTap: _loadPlans,
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeaders() {
    final style = KaliText.label(KaliColors.espresso.withValues(alpha: 0.45));

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('PLAN', style: style)),
          Expanded(flex: 3, child: Text('PRECIO', style: style)),
          Expanded(flex: 3, child: Text('RESERVAS', style: style)),
          Expanded(flex: 2, child: Text('ESTADO', style: style)),
          Expanded(flex: 2, child: Text('ACCIONES', style: style)),
        ],
      ),
    );
  }
}

class _PlanRow extends StatefulWidget {
  final Map<String, dynamic> plan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlanRow({
    required this.plan,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_PlanRow> createState() => _PlanRowState();
}

class _PlanRowState extends State<_PlanRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.plan;
    final String name = p['name'] ?? '';
    final String? description = p['description'];
    final double price = (p['price'] as num?)?.toDouble() ?? 0.0;
    final String currency = p['currency'] ?? 'ARS';
    final int maxReservations =
        (p['max_reservations_per_week'] as num?)?.toInt() ?? 2;
    final bool isActive = p['is_active'] ?? true;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeIn,
        color: _hovered ? KaliColors.warmWhite : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Row(
          children: [
            // Plan name + description
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: KaliText.body(
                      KaliColors.espresso,
                      weight: FontWeight.w600,
                      size: 14,
                    ),
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: KaliText.body(
                        KaliColors.espresso.withValues(alpha: 0.5),
                        size: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Price & Currency
            Expanded(
              flex: 3,
              child: Text(
                '\$${price.toStringAsFixed(2)} $currency',
                style: KaliText.body(
                  KaliColors.espresso,
                  weight: FontWeight.w500,
                ),
              ),
            ),

            // Reservations
            Expanded(
              flex: 3,
              child: Text(
                '$maxReservations clases / sem',
                style: KaliText.body(
                  KaliColors.espresso,
                  weight: FontWeight.w400,
                ),
              ),
            ),

            // Status indicator
            Expanded(
              flex: 2,
              child: _StatusIndicator(isActive: isActive),
            ),

            // Actions
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  KaliIconButton.action(
                    Icons.edit_outlined,
                    tooltip: 'Editar',
                    onTap: widget.onEdit,
                  ),
                  const SizedBox(width: 8),
                  KaliIconButton.action(
                    Icons.delete_outline_rounded,
                    tooltip: 'Eliminar',
                    color: const Color(0xFFD4685C),
                    onTap: widget.onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final bool isActive;
  const _StatusIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF5C9E6C) : const Color(0xFFD4685C);

    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          isActive ? 'Activo' : 'Inactivo',
          style: KaliText.body(color, weight: FontWeight.w500),
        ),
      ],
    );
  }
}
