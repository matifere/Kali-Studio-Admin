import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';

/// Control de paginación reutilizable.
///
/// Muestra un texto de resumen a la izquierda y los controles de página
/// (anterior, números, siguiente) a la derecha.
class KaliPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int showingCount;
  final int totalCount;
  final String itemLabel;
  final ValueChanged<int> onPageChanged;

  const KaliPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.showingCount,
    required this.totalCount,
    this.itemLabel = 'ALUMNOS',
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'MOSTRANDO $showingCount DE $totalCount $itemLabel',
            style: KaliText.label(
              KaliColors.espresso.withValues(alpha: 0.4),
            ),
          ),
          Row(
            children: [
              _PageArrowBtn(
                icon: Icons.chevron_left,
                enabled: currentPage > 1,
                onTap: () => onPageChanged(currentPage - 1),
              ),
              const SizedBox(width: 4),
              ...List.generate(totalPages, (i) {
                final page = i + 1;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _PageNumberBtn(
                    page: page,
                    isActive: page == currentPage,
                    onTap: () => onPageChanged(page),
                  ),
                );
              }),
              const SizedBox(width: 4),
              _PageArrowBtn(
                icon: Icons.chevron_right,
                enabled: currentPage < totalPages,
                onTap: () => onPageChanged(currentPage + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Botón flecha ─────────────────────────────────────────────────────────────
class _PageArrowBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageArrowBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

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

// ─── Botón número de página ───────────────────────────────────────────────────
class _PageNumberBtn extends StatefulWidget {
  final int page;
  final bool isActive;
  final VoidCallback onTap;

  const _PageNumberBtn({
    required this.page,
    required this.isActive,
    required this.onTap,
  });

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
          curve: Curves.decelerate,
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
              widget.isActive ? KaliColors.warmWhite : KaliColors.sand,
              weight: widget.isActive ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
