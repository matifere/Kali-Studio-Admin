import 'package:flutter/material.dart';
import 'package:argrity/theme/kali_colors_extension.dart';

class KaliTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData? suffixIcon;
  final bool obscureText;
  final TextEditingController? controller;
  final bool readOnly;
  final VoidCallback? onSuffixTap;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;

  const KaliTextField({
    super.key,
    required this.label,
    required this.hint,
    this.suffixIcon,
    this.obscureText = false,
    this.controller,
    this.readOnly = false,
    this.onSuffixTap,
    this.actionLabel,
    this.onActionTap,
    this.validator,
    this.autovalidateMode,
  });

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: kaliColors.label(kaliColors.espresso),
            ),
            if (actionLabel != null)
              InkWell(
                onTap: onActionTap,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    actionLabel!,
                    style: kaliColors.caption(kaliColors.clayDark),
                  ),
                ),
              ),
          ],
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          readOnly: readOnly,
          validator: validator,
          autovalidateMode: autovalidateMode,
          style: kaliColors.body(kaliColors.espresso, size: 14),
          cursorColor: kaliColors.clay,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: kaliColors.body(kaliColors.clay, size: 14),

            filled: true,
            fillColor: kaliColors.sand,

            // Icono derecho
            suffixIcon: suffixIcon != null
                ? GestureDetector(
                    onTap: onSuffixTap,
                    child: Icon(
                      suffixIcon,
                      color: kaliColors.clayDark,
                      size: 18,
                    ),
                  )
                : null,

            border: _border(kaliColors.sand2),
            enabledBorder: _border(kaliColors.sand2),
            focusedBorder: _border(kaliColors.clay),
            errorBorder: _border(Colors.red.shade300),
            focusedErrorBorder: _border(Colors.red.shade400),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: 1.2),
      );
}
