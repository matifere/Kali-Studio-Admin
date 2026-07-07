import 'package:flutter/material.dart';
import 'package:argrity/theme/kali_colors_extension.dart';

class SettingsInstitutionScreen extends StatefulWidget {
  const SettingsInstitutionScreen({super.key});

  @override
  State<SettingsInstitutionScreen> createState() =>
      _SettingsInstitutionScreenState();
}

class _SettingsInstitutionScreenState extends State<SettingsInstitutionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _paymentAliasController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _paymentAliasController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // TODO: Implementar la actualización en la base de datos Supabase
    await Future.delayed(const Duration(seconds: 1)); // Simulación de carga

    if (!mounted) return;
    setState(() => _isLoading = false);

    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            const Text('Datos de la institución actualizados exitosamente.'),
        backgroundColor: kaliColors.espresso,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    final bool isSmall = MediaQuery.of(context).size.width < 600;

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
              left: 24.0, right: 24.0, bottom: 24.0, top: 48.0),
          child: Form(
            key: _formKey,
            child: SizedBox(
              width: isSmall ? double.infinity : 600,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Institución',
                    style: kaliColors.heading(kaliColors.espresso, size: 36),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Administrá los datos principales de tu establecimiento.',
                    style: kaliColors
                        .body(kaliColors.espresso.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: kaliColors.warmWhite,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: kaliColors.espresso.withValues(alpha: 0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          label: 'Nombre de la institución',
                          controller: _nameController,
                          icon: Icons.business_rounded,
                          kaliColors: kaliColors,
                          validator: (value) => value == null || value.isEmpty
                              ? 'El nombre es requerido'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          label: 'Dirección',
                          controller: _addressController,
                          icon: Icons.location_on_rounded,
                          kaliColors: kaliColors,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          label: 'Teléfono',
                          controller: _phoneController,
                          icon: Icons.phone_rounded,
                          kaliColors: kaliColors,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          label: 'Alias de pago (MercadoPago / Transferencia)',
                          controller: _paymentAliasController,
                          icon: Icons.payment_rounded,
                          kaliColors: kaliColors,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kaliColors.espresso,
                              foregroundColor: kaliColors.warmWhite,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: kaliColors.warmWhite,
                                    ),
                                  )
                                : Text(
                                    'Guardar Cambios',
                                    style: kaliColors.body(kaliColors.warmWhite,
                                        weight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required KaliColorsExtension kaliColors,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: kaliColors.label(kaliColors.espresso.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: kaliColors.body(kaliColors.espresso),
          decoration: InputDecoration(
            prefixIcon:
                Icon(icon, color: kaliColors.espresso.withValues(alpha: 0.5)),
            filled: true,
            fillColor: kaliColors.sand.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: kaliColors.espresso.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: kaliColors.espresso),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
          ),
        ),
      ],
    );
  }
}
