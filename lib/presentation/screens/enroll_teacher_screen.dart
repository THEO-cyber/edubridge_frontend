import 'dart:convert';
import 'package:edubridge/presentation/screens/lecturer_dashboard_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../core/secure_storage.dart';

class EnrollTeacherScreen extends StatefulWidget {
  const EnrollTeacherScreen({super.key});

  @override
  State<EnrollTeacherScreen> createState() => _EnrollTeacherScreenState();
}

class _EnrollTeacherScreenState extends State<EnrollTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _expertiseController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();

  PlatformFile? _idFile;
  PlatformFile? _qualFile;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _expertiseController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickId() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _idFile = result.files.first);
    }
  }

  Future<void> _pickQual() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _qualFile = result.files.first);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idFile == null || _qualFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload both ID/Passport and Qualifications.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final token = await SecureStorage.getToken();

      // Submit instructor profile to the backend
      if (token != null && token.isNotEmpty) {
        // Update instructor profile fields
        await http.put(
          Uri.parse(
              ApiConstants.baseUrl + ApiConstants.updateInstructorProfile),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'expertise': _expertiseController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
            'experience': _bioController.text.trim(),
          }),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Application submitted! Your profile will be reviewed shortly.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LecturerDashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Submission failed: ${e.toString().replaceFirst("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply as Lecturer'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Become a Lecturer',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Fill in your details to apply as an instructor. Our team will review your application.',
              style: TextStyle(color: Colors.blueGrey.shade600, height: 1.4),
            ),
            const SizedBox(height: 24),
            _field(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _field(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_outlined,
              type: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _field(
              controller: _expertiseController,
              label: 'Expertise (comma-separated)',
              icon: Icons.lightbulb_outline,
              hint: 'e.g. Flutter, Python, Machine Learning',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _field(
              controller: _bioController,
              label: 'Teaching Experience',
              icon: Icons.work_outline,
              hint: 'Briefly describe your experience...',
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // ID Upload
            _UploadTile(
              label: 'National ID / Passport *',
              fileName: _idFile?.name,
              onTap: _pickId,
            ),
            const SizedBox(height: 12),

            // Qualifications Upload
            _UploadTile(
              label: 'Qualifications Document *',
              fileName: _qualFile?.name,
              onTap: _pickQual,
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Application',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final String label;
  final String? fileName;
  final VoidCallback onTap;

  const _UploadTile(
      {required this.label, required this.fileName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final uploaded = fileName != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: uploaded
                  ? Colors.green.shade400
                  : Colors.blueGrey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              uploaded ? Icons.check_circle : Icons.upload_file,
              color: uploaded ? Colors.green : Colors.blueGrey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                uploaded ? fileName! : label,
                style: TextStyle(
                  color:
                      uploaded ? Colors.black87 : Colors.blueGrey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              uploaded ? 'Change' : 'Upload',
              style: const TextStyle(
                  color: Color(0xFF1A237E), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
