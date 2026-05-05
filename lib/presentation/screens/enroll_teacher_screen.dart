import 'package:edubridge/presentation/screens/lecturer_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class EnrollTeacherScreen extends StatelessWidget {
  const EnrollTeacherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _expertiseController = TextEditingController();
    final _emailController = TextEditingController();
    // File pickers
    String? idFileName;
    String? qualFileName;
    PlatformFile? idFile;
    PlatformFile? qualFile;

    return Scaffold(
      appBar: AppBar(title: const Text('Enroll as Lecturer'),),
      body: StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text(
                  'Become a Lecturer',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Fill in your details to enroll as a lecturer. All fields are required.',
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Full Name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                // National ID/Passport upload
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        idFileName == null
                            ? 'Upload National ID / Passport *'
                            : 'ID/Passport: $idFileName',
                        style: TextStyle(
                          fontSize: 16,
                          color: idFileName == null ? Colors.red : Colors.black,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload'),
                      onPressed: () async {
                        final result = await FilePicker.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                        );
                        if (result != null && result.files.isNotEmpty) {
                          setState(() {
                            idFile = result.files.first;
                            idFileName = idFile!.name;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Qualifications upload
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        qualFileName == null
                            ? 'Upload Qualifications Document *'
                            : 'Qualifications: $qualFileName',
                        style: TextStyle(
                          fontSize: 16,
                          color: qualFileName == null
                              ? Colors.red
                              : Colors.black,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload'),
                      onPressed: () async {
                        final result = await FilePicker.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                        );
                        if (result != null && result.files.isNotEmpty) {
                          setState(() {
                            qualFile = result.files.first;
                            qualFileName = qualFile!.name;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _expertiseController,
                  decoration: const InputDecoration(labelText: 'Expertise'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Expertise is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Email is required';
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(v)) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    final valid = _formKey.currentState!.validate();
                    if (!valid) return;
                    if (idFile == null || qualFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please upload both ID/Passport and Qualifications documents.',
                          ),
                        ),
                      );
                      return;
                    }
                    // Mock: Go to teacher dashboard
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const LecturerDashboardScreen(),
                      ),
                    );
                  },
                  child: const Text('Submit & Go to Lecturer Dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---
// Remove _TeacherDashboardMock, now using LecturerDashboardScreen


