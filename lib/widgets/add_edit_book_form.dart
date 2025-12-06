/*add_edit_book_form.dart*/
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/category.dart';
import '../services/api_service.dart';
class AddEditBookForm extends StatefulWidget {
  final Book? book; // Si null, c'est pour ajouter un nouveau livre

  const AddEditBookForm({super.key, this.book});

  @override
  _AddEditBookFormState createState() => _AddEditBookFormState();
}
class _AddEditBookFormState extends State<AddEditBookForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _yearController;
  late TextEditingController _isbnController;
  late TextEditingController _descriptionController;
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book?.title ?? '');
    _authorController = TextEditingController(text: widget.book?.author ?? '');
    _yearController = TextEditingController(text: widget.book?.year ?? '');
    _isbnController = TextEditingController(text: widget.book?.isbn ?? '');
    _descriptionController = TextEditingController(text: widget.book?.description ?? '');
    _selectedCategory = widget.book?.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _yearController.dispose();
    _isbnController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final newBook = Book(
        id: widget.book?.id ?? '',
        title: _titleController.text,
        author: _authorController.text,
        year: _yearController.text,
        isbn: _isbnController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        available: widget.book?.available ?? true,
        copies: widget.book?.copies ?? 1,
        createdAt: widget.book?.createdAt,
        updatedAt: DateTime.now(),
      );
      if (widget.book == null) {
        await ApiService().createBook(newBook);
      } else {
        await ApiService().updateBook(newBook);
      }
      Navigator.of(context).pop(true); // Retourner true pour indiquer le succès
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book == null ? 'Ajouter un livre' : 'Modifier le livre'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Titre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le titre';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _authorController,
                decoration: InputDecoration(labelText: 'Auteur'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer l\'auteur';
                  }
                  return null;
                },
              ),
              // Ajoutez d'autres champs de formulaire ici (année, ISBN, description, catégorie, etc.)
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
