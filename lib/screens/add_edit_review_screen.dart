import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Tambahkan dependency ini
import '../api_service.dart';

class AddEditReviewScreen extends StatefulWidget {
  final String username;
  final Map<String, dynamic>? review;

  const AddEditReviewScreen({Key? key, required this.username, this.review})
      : super(key: key);

  @override
  _AddEditReviewScreenState createState() => _AddEditReviewScreenState();
}

class _AddEditReviewScreenState extends State<AddEditReviewScreen> {
  final _titleController = TextEditingController();
  final _ratingController = TextEditingController();
  final _commentController = TextEditingController();
  final _apiService = ApiService();
  File? _selectedPhoto; // Variabel untuk menyimpan file foto

  @override
  void initState() {
    super.initState();
    if (widget.review != null) {
      _titleController.text = widget.review!['title'];
      _ratingController.text = widget.review!['rating'].toString();
      _commentController.text = widget.review!['comment'];
      if (widget.review!['photo'] != null) {
        _selectedPhoto = File(widget.review!['photo']); // Ambil path foto
      }
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedPhoto = File(pickedFile.path);
      });
    }
  }

  void _saveReview() async {
    final title = _titleController.text.trim();
    final rating = int.tryParse(_ratingController.text) ?? 0;
    final comment = _commentController.text.trim();
    final photoPath = _selectedPhoto?.path; // Ambil path foto

    // Validasi input
    if (title.isEmpty || rating < 1 || rating > 10 || comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Data tidak valid. Judul, komentar, dan rating (1-10) harus diisi.'),
        ),
      );
      return;
    }

    bool success;
    if (widget.review == null) {
      // Tambah review baru
      success = await _apiService.addReview(
          widget.username, title, rating, comment, photoPath);
    } else {
      // Edit review
      success = await _apiService.updateReview(
        widget.review!['id'] as int,
        title,
        rating,
        comment,
        photoPath,
      );
    }

    if (success) {
      Navigator.pop(context, true); // Berhasil, kembali ke layar sebelumnya
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan review')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.review != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditMode ? 'Edit Review' : 'Tambah Review')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Judul Film'),
              readOnly: isEditMode,
            ),
            TextField(
              controller: _ratingController,
              decoration: const InputDecoration(labelText: 'Rating (1-10)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(labelText: 'Komentar'),
            ),
            const SizedBox(height: 10),
            if (_selectedPhoto != null)
              Image.file(
                _selectedPhoto!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            TextButton.icon(
              icon: const Icon(Icons.photo),
              label: const Text('Pilih Foto'),
              onPressed: _pickPhoto,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveReview,
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
