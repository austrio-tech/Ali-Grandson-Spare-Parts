import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'database_helper.dart';

// AddProductPage allows the administrator to add new spare parts to the store catalog.
class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  // GlobalKey is used to identify and validate the form fields.
  final _formKey = GlobalKey<FormState>();
  
  // Controllers to capture the information typed by the admin for the new product.
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _typeController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _priceController = TextEditingController();
  final _availableController = TextEditingController();
  
  // Stores the raw data of the product image selected from the gallery.
  Uint8List? _imageBytes;

  // This function opens the phone's gallery so the admin can pick a photo for the product.
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Picks an image and reduces its quality/size to save space.
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _imageBytes = bytes; // Update the UI to show the selected image.
      });
    }
  }

  // This function saves the new product to the database.
  Future<void> _addProduct() async {
    // 1. Check if all text fields are valid.
    if (_formKey.currentState!.validate()) {
      // 2. Ensure an image has been chosen.
      if (_imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image.')),
        );
        return;
      }
      
      // 3. Collect all data into a Map format for the database.
      final product = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'image': _imageBytes,
        'type': _typeController.text,
        'brand': _brandController.text,
        'model': _modelController.text,
        'price': double.parse(_priceController.text),
        'available': int.parse(_availableController.text),
      };
      
      // 4. Insert the new product into the database table.
      await DatabaseHelper.instance.insertProduct(product);

      // 5. Notify the admin and close the page.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Image selection area.
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _imageBytes != null
                      ? Image.memory(
                          _imageBytes!,
                          fit: BoxFit.cover,
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                              SizedBox(height: 10),
                              Text('Tap to select an image', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              // Input field for Product Name.
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Input field for Description.
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 20),
              // Input field for Type (e.g., Sedan, SUV).
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 20),
              // Input field for Brand (e.g., Toyota, Nissan).
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Brand'),
              ),
              const SizedBox(height: 20),
              // Input field for Model or Year.
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Model/Year'),
              ),
              const SizedBox(height: 20),
              // Input field for Price.
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Input field for current Stock levels.
              TextFormField(
                controller: _availableController,
                decoration: const InputDecoration(labelText: 'Available Items'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the number of available items';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              // Button to confirm and add the product.
              ElevatedButton(
                onPressed: _addProduct,
                child: const Text('Add Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
