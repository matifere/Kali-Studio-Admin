import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:argrity/theme/kali_colors_extension.dart';
import 'package:argrity/services/profile_cache.dart';
import 'package:file_picker/file_picker.dart';

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

  Uint8List? _selectedImageBytes;
  String? _currentLogoUrl; // To be implemented for fetching logo from DB

  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadInstitutionData();
  }

  Future<void> _loadInstitutionData() async {
    final instId = ProfileCache.institutionId;
    if (instId == null) {
      setState(() => _isLoadingData = false);
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('institutions')
          .select('name, address, phone, payment_alias, logo_url')
          .eq('id', instId)
          .single();

      if (mounted) {
        setState(() {
          _nameController.text = data['name'] ?? '';
          _addressController.text = data['address'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _paymentAliasController.text = data['payment_alias'] ?? '';
          _currentLogoUrl = data['logo_url'];
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading institution: $e');
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _paymentAliasController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, // Importante para web
      );
      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.first.bytes;
        if (bytes != null) {
          setState(() {
            _selectedImageBytes = bytes;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    final instId = ProfileCache.institutionId;
    if (instId == null) return;

    setState(() => _isLoading = true);
    final kaliColors = Theme.of(context).extension<KaliColorsExtension>()!;
    
    try {
      String? logoUrl = _currentLogoUrl;
      
      if (_selectedImageBytes != null) {
        final path = '$instId/logo_${DateTime.now().millisecondsSinceEpoch}.png';
        
        await Supabase.instance.client.storage
            .from('institutions_logos')
            .uploadBinary(
              path,
              _selectedImageBytes!,
              fileOptions: const FileOptions(upsert: true, contentType: 'image/png'),
            );
            
        logoUrl = Supabase.instance.client.storage
            .from('institutions_logos')
            .getPublicUrl(path);
      }

      await Supabase.instance.client
          .from('institutions')
          .update({
            'name': _nameController.text.trim(),
            'address': _addressController.text.trim(),
            'phone': _phoneController.text.trim(),
            'payment_alias': _paymentAliasController.text.trim(),
            if (logoUrl != null) 'logo_url': logoUrl,
          })
          .eq('id', instId);

      if (!mounted) return;
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Datos de la institución actualizados exitosamente.'),
          backgroundColor: kaliColors.espresso,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error updating institution: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al actualizar los datos. Intente nuevamente.'),
          backgroundColor: Colors.red.shade400,
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
                  
                  if (_isLoadingData)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: CircularProgressIndicator(color: kaliColors.espresso),
                      ),
                    )
                  else
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
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: kaliColors.sand.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: kaliColors.espresso.withValues(alpha: 0.2),
                                      width: 2,
                                    ),
                                    image: _selectedImageBytes != null
                                        ? DecorationImage(
                                            image: MemoryImage(_selectedImageBytes!),
                                            fit: BoxFit.cover,
                                          )
                                        : _currentLogoUrl != null
                                            ? DecorationImage(
                                                image: NetworkImage(_currentLogoUrl!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                  ),
                                  child: (_selectedImageBytes == null && _currentLogoUrl == null)
                                      ? Icon(
                                          Icons.add_a_photo_rounded,
                                          size: 40,
                                          color: kaliColors.espresso.withValues(alpha: 0.5),
                                        )
                                      : null,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: kaliColors.espresso,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: kaliColors.warmWhite,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    size: 16,
                                    color: kaliColors.warmWhite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
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
                          validator: (value) => value == null || value.isEmpty ? 'La dirección es requerida' : null,
                        ),
                        const SizedBox(height: 20),
                        
                        _buildTextField(
                          label: 'Teléfono',
                          controller: _phoneController,
                          icon: Icons.phone_rounded,
                          kaliColors: kaliColors,
                          validator: (value) => value == null || value.isEmpty ? 'El teléfono es requerido' : null,
                        ),
                        const SizedBox(height: 20),
                        
                        _buildTextField(
                          label: 'Alias de pago (MercadoPago / Transferencia)',
                          controller: _paymentAliasController,
                          icon: Icons.payment_rounded,
                          kaliColors: kaliColors,
                          validator: (value) => value == null || value.isEmpty ? 'El alias de pago es requerido' : null,
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
