import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'services/auth_service.dart';
import 'models/project.dart';

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({super.key});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final _authService = AuthService();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  List<Project> _projects = [];
  int? _selectedProjectId;
  bool _isLoadingProjects = true;
  bool _isSubmitting = false;
  File? _attachment;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _attachment = File(result.files.single.path!);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    final projects = await _authService.getProjects();
    if (mounted) {
      setState(() {
        _projects = projects;
        _isLoadingProjects = false;
        if (_projects.isNotEmpty) {
          _selectedProjectId = _projects.first.id;
        }
      });
    }
  }

  Future<void> _submitTicket() async {
    if (_selectedProjectId == null || 
        _titleController.text.trim().isEmpty || 
        _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (mounted) setState(() => _isSubmitting = true);
    final success = await _authService.createTicket(
      projectId: _selectedProjectId!,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      attachment: _attachment,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create ticket')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Image.asset(
          'assets/img/logo-wealiens-copyright.png',
          height: 30,
        ),
        centerTitle: true,
      ),
      body: _isLoadingProjects
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('SELECT PROJECT'),
                  _buildProjectDropdown(),
                  const SizedBox(height: 24),
                  _buildLabel('SUBJECT'),
                  _buildTextField(_titleController, 'Brief subject of your issue'),
                  const SizedBox(height: 24),
                  _buildTextField(_descController, 'Detailed explanation...', maxLines: 5),
                  const SizedBox(height: 24),
                  _buildLabel('ATTACHMENT (OPTIONAL)'),
                  _buildFilePicker(),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitTicket,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('SUBMIT TICKET',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text,
          style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildProjectDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A33),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedProjectId,
          dropdownColor: const Color(0xFF131A33),
          isExpanded: true,
          style: const TextStyle(color: Colors.white),
          items: _projects.map((Project project) {
            return DropdownMenuItem<int>(
              value: project.id,
              child: Text(project.title),
            );
          }).toList(),
          onChanged: (int? newValue) {
            setState(() {
              _selectedProjectId = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF131A33),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildFilePicker() {
    return InkWell(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF131A33),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(Icons.attach_file, color: _attachment != null ? const Color(0xFF00E5FF) : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _attachment != null 
                    ? _attachment!.path.split('/').last 
                    : 'Select a file to attach',
                style: TextStyle(
                  color: _attachment != null ? Colors.white : Colors.grey,
                  fontSize: 14
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_attachment != null)
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.redAccent),
                onPressed: () => setState(() => _attachment = null),
              ),
          ],
        ),
      ),
    );
  }
}
