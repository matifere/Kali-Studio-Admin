import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
class _Student {
  final String initials;
  final Color avatarColor;
  final String? avatarImage;
  final String name;
  final String email;
  final String plan;
  final bool isActive;
  final String nextShift;
  final String shiftClass;
  final bool reactivate;

  const _Student({
    required this.initials,
    required this.avatarColor,
    this.avatarImage,
    required this.name,
    required this.email,
    required this.plan,
    required this.isActive,
    required this.nextShift,
    required this.shiftClass,
    this.reactivate = false,
  });
}

// ─── Widget ───────────────────────────────────────────────────────────────────
class StudentDirectory extends StatefulWidget {
  const StudentDirectory({super.key});

  @override
  State<StudentDirectory> createState() => _StudentDirectoryState();
}

class _StudentDirectoryState extends State<StudentDirectory> {
  int _currentPage = 1;
  final int _totalPages = 3;

  final List<_Student> _students = const [
    _Student(
      initials: 'LV',
      avatarColor: Color(0xFFB5C9B0),
      name: 'Lucía Valenzuela',
      email: 'lucia.v@email.com',
      plan: 'PREMIUM ANUAL',
      isActive: true,
      nextShift: 'Mañana, 09:00',
      shiftClass: 'YOGA FLOW',
    ),
    _Student(
      initials: 'MR',
      avatarColor: Color(0xFFD4B896),
      avatarImage: 'https://i.pravatar.cc/150?img=12',
      name: 'Mateo Rodriguez',
      email: 'mateo.r@email.com',
      plan: 'BÁSICO X8',
      isActive: true,
      nextShift: 'Jueves, 18:30',
      shiftClass: 'PILATES MAT',
    ),
    _Student(
      initials: 'CP',
      avatarColor: Color(0xFFE8C4A0),
      name: 'Camila Paredes',
      email: 'cami.paredes@email.com',
      plan: 'PREMIUM ANUAL',
      isActive: false,
      nextShift: 'Sin turnos',
      shiftClass: 'REACTIVAR',
      reactivate: true,
    ),
    _Student(
      initials: 'JS',
      avatarColor: Color(0xFF9EAFC2),
      avatarImage: 'https://i.pravatar.cc/150?img=8',
      name: 'Julián Soto',
      email: 'j.soto@email.com',
      plan: 'INTERMEDIO X12',
      isActive: true,
      nextShift: 'Hoy, 20:00',
      shiftClass: 'FUNCTIONAL',
    ),
  ];

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
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTableHeader(),
          _buildColumnHeaders(),
          ..._students.map((s) => _buildStudentRow(s)),
          _buildTableFooter(),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Directorio de Alumnos',
            style: KaliText.headingItalic(KaliColors.espresso, size: 22),
          ),
          const Row(
            children: [
              _IconBtn(Icons.tune_rounded, tooltip: 'Filtrar'),
              SizedBox(width: 8),
              _IconBtn(Icons.download_rounded, tooltip: 'Exportar'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeaders() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text('NOMBRE',
                style: KaliText.label(
                    KaliColors.espresso.withValues(alpha: 0.45))),
          ),
          Expanded(
            flex: 3,
            child: Text('PLAN',
                style: KaliText.label(
                    KaliColors.espresso.withValues(alpha: 0.45))),
          ),
          Expanded(
            flex: 2,
            child: Text('ESTADO',
                style: KaliText.label(
                    KaliColors.espresso.withValues(alpha: 0.45))),
          ),
          Expanded(
            flex: 3,
            child: Text('PRÓXIMO TURNO',
                style: KaliText.label(
                    KaliColors.espresso.withValues(alpha: 0.45))),
          ),
          Expanded(
            flex: 2,
            child: Text('ACCIONES',
                style: KaliText.label(
                    KaliColors.espresso.withValues(alpha: 0.45))),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(_Student s) {
    return _StudentRow(student: s);
  }

  Widget _buildTableFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'MOSTRANDO 4 DE 124 ALUMNOS',
            style: KaliText.label(KaliColors.espresso.withValues(alpha: 0.4)),
          ),
          Row(
            children: [
              // Prev
              _PageBtn(
                icon: Icons.chevron_left,
                enabled: _currentPage > 1,
                onTap: () {
                  if (_currentPage > 1) setState(() => _currentPage--);
                },
              ),
              const SizedBox(width: 4),
              // Page numbers
              ...List.generate(_totalPages, (i) {
                final page = i + 1;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _PageNumberBtn(
                    page: page,
                    isActive: page == _currentPage,
                    onTap: () => setState(() => _currentPage = page),
                  ),
                );
              }),
              const SizedBox(width: 4),
              // Next
              _PageBtn(
                icon: Icons.chevron_right,
                enabled: _currentPage < _totalPages,
                onTap: () {
                  if (_currentPage < _totalPages) {
                    setState(() => _currentPage++);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Student Row ──────────────────────────────────────────────────────────────
class _StudentRow extends StatefulWidget {
  final _Student student;
  const _StudentRow({required this.student});

  @override
  State<_StudentRow> createState() => _StudentRowState();
}

class _StudentRowState extends State<_StudentRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    final isPremium = s.plan.toUpperCase().contains('PREMIUM') ||
        s.plan.toUpperCase().contains('ANUAL');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _hovered
            ? KaliColors.sand.withValues(alpha: 0.4)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        child: Row(
          children: [
            // Name + avatar
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  _Avatar(student: s),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: KaliText.body(KaliColors.espresso,
                            weight: FontWeight.w600, size: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(s.email,
                          style: KaliText.body(
                              KaliColors.espresso.withValues(alpha: 0.5))),
                    ],
                  ),
                ],
              ),
            ),

            // Plan badge
            Expanded(
              flex: 3,
              child: _PlanBadge(plan: s.plan, isPremium: isPremium),
            ),

            // Estado
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: s.isActive
                          ? const Color(0xFF5C9E6C)
                          : const Color(0xFFD4685C),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.isActive ? 'Activo' : 'Inactivo',
                    style: KaliText.body(
                      s.isActive
                          ? const Color(0xFF5C9E6C)
                          : const Color(0xFFD4685C),
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Próximo turno
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.nextShift,
                    style: KaliText.body(
                      s.reactivate
                          ? KaliColors.espresso.withValues(alpha: 0.4)
                          : KaliColors.espresso,
                      weight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.shiftClass,
                    style: KaliText.label(
                      s.reactivate
                          ? const Color(0xFFD4685C)
                          : KaliColors.espresso.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),

            // Acciones
            const Expanded(
              flex: 2,
              child: Row(
                children: [
                  _ActionIconBtn(Icons.visibility_outlined,
                      tooltip: 'Ver perfil'),
                  SizedBox(width: 4),
                  _ActionIconBtn(Icons.edit_outlined, tooltip: 'Editar'),
                  SizedBox(width: 4),
                  _ActionIconBtn(Icons.more_horiz, tooltip: 'Más opciones'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final _Student student;
  const _Avatar({required this.student});

  @override
  Widget build(BuildContext context) {
    if (student.avatarImage != null) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: student.avatarColor,
        backgroundImage: NetworkImage(student.avatarImage!),
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: student.avatarColor,
      child: Text(
        student.initials,
        style: KaliText.body(KaliColors.espresso,
            weight: FontWeight.w700, size: 12),
      ),
    );
  }
}

// ─── Plan Badge ───────────────────────────────────────────────────────────────
class _PlanBadge extends StatelessWidget {
  final String plan;
  final bool isPremium;
  const _PlanBadge({required this.plan, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isPremium ? const Color(0xFFF5D9B8) : KaliColors.sand2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        plan,
        style: KaliText.label(KaliColors.espresso.withValues(alpha: 0.75)),
      ),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  const _IconBtn(this.icon, {required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon,
              size: 20, color: KaliColors.espresso.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

class _ActionIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  const _ActionIconBtn(this.icon, {required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(6),
          child:
              Icon(icon, size: 16, color: KaliColors.espresso.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _PageBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? KaliColors.espresso.withValues(alpha: 0.6)
              : KaliColors.espresso.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

class _PageNumberBtn extends StatefulWidget {
  final int page;
  final bool isActive;
  final VoidCallback onTap;
  const _PageNumberBtn(
      {required this.page, required this.isActive, required this.onTap});

  @override
  State<_PageNumberBtn> createState() => _PageNumberBtnState();
}

class _PageNumberBtnState extends State<_PageNumberBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: widget.isActive
                ? KaliColors.espresso
                : (_hovered ? KaliColors.sand2 : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '${widget.page}',
            style: KaliText.body(
              widget.isActive
                  ? KaliColors.warmWhite
                  : KaliColors.espresso.withValues(alpha: 0.6),
              weight: widget.isActive ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
