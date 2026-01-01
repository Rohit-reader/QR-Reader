import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/yarn_service.dart';

class AddYarnPage extends StatefulWidget {
  final String qr;
  const AddYarnPage({super.key, required this.qr});

  @override
  State<AddYarnPage> createState() => _AddYarnPageState();
}

class _AddYarnPageState extends State<AddYarnPage> {
  final _formKey = GlobalKey<FormState>();
  final materialCtrl = TextEditingController();
  final typeCtrl = TextEditingController();
  final binCtrl = TextEditingController();
  final rackCtrl = TextEditingController();
  bool isLoading = false;

  void _saveYarn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final yarnService = YarnService();
      await yarnService.addYarn(widget.qr, {
        'material': materialCtrl.text.trim(),
        'type': typeCtrl.text.trim(),
        'bin': binCtrl.text.trim(),
        'rack': rackCtrl.text.trim(),
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yarn added to inventory successfully')),
      );
      Navigator.pop(context); // Go back to scanner
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving yarn: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Add New Yarn'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildQRHeader(),
              const SizedBox(height: 32),
              _buildTextField(
                controller: materialCtrl,
                label: 'Material',
                hint: 'e.g. Silk, Cotton',
                icon: Icons.inventory_2,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: typeCtrl,
                label: 'Type',
                hint: 'e.g. 2nd Grade, Premium',
                icon: Icons.category,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: binCtrl,
                label: 'Bin Number',
                hint: 'e.g. B-102',
                icon: Icons.grid_view,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: rackCtrl,
                label: 'Rack Number',
                hint: 'e.g. R-05',
                icon: Icons.layers,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: isLoading ? null : _saveYarn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add to Inventory'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_2, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scanned QR Code',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.qr,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}
