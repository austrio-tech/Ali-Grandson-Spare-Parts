import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'database_helper.dart';

// EditProductPage is used by the administrator to update existing spare part information.
class EditProductPage extends StatefulWidget {
  // We need the ID of the product to know which one we are editing.
  final int productId;

  const EditProductPage({super.key, required this.productId});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  // GlobalKey is used to identify and validate the form fields.
  final _formKey = GlobalKey<FormState>();
  
  // Controllers to manage the text inside each input field.
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _typeController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _priceController = TextEditingController();
  final _availableController = TextEditingController();
  
  // Stores the image data (bytes) for the product.
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    // Load the product's current information as soon as the admin opens the page.
    _loadProduct();
  }

  // Fetches existing product data from the database and fills the form fields.
  Future<void> _loadProduct() async {
    final product = await DatabaseHelper.instance.getProduct(widget.productId);
    if (product != null) {
      _nameController.text = product['name'] ?? '';
      _descriptionController.text = product['description'] ?? '';
      _typeController.text = product['type'] ?? '';
      _brandController.text = product['brand'] ?? '';
      _modelController.text = product['model'] ?? '';
      _priceController.text = product['price'].toString();
      _availableController.text = product['available'].toString();
      
      // Also fetch the product image separately.
      final image = await DatabaseHelper.instance.getProductImage(widget.productId);
      setState(() {
        _imageBytes = image;
      });
    }
  }

  // Opens the phone gallery to allow the admin to change the product photo.
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Picks an image and reduces quality/size slightly to keep the database small.
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  // Saves the modified product information back to the database.
  Future<void> _updateProduct() async {
    // 1. Check if all mandatory text fields are filled out.
    if (_formKey.currentState!.validate()) {
      // 2. Prepare the updated data in a Map format.
      final product = {
        'id': widget.productId,
        'name': _nameController.text,
        'description': _descriptionController.text,
        'image': _imageBytes,
        'type': _typeController.text,
        'brand': _brandController.text,
        'model': _modelController.text,
        'price': double.parse(_priceController.text),
        'available': int.parse(_availableController.text),
      };
      
      // 3. Save the changes to the database.
      await DatabaseHelper.instance.updateProduct(product);

      // 4. Notify the admin and go back to the previous screen.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Area to view and tap to change the product image.
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
              // Input field for Name.
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
              // Input field for Type (e.g., Sedan).
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 20),
              // Input field for Brand (e.g., Bosch).
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
              // Input field for available Stock.
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
              // Update and Cancel buttons.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _updateProduct,
                    child: const Text('Update'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text('Cancel'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
