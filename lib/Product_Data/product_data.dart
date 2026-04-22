import 'package:flutter/services.dart';
import '../database_helper.dart';

class ProductData {
  static final List<Map<String, dynamic>> defaultProducts = [
    {
      'name': 'Brake Pad',
      'description': 'High-performance ceramic brake pads for smooth stopping power.',
      'image_path': 'lib/Product_Data/brake_pad.jpeg',
      'type': 'Sedan',
      'brand': 'Brembo',
      'model': '2020-2023',
      'price': 25.500,
      'available': 50,
    },
    {
      'name': 'Oil Filter',
      'description': 'Premium engine oil filter for maximum filtration and engine protection.',
      'image_path': 'lib/Product_Data/oil_filter.jpeg',
      'type': 'SUV',
      'brand': 'Bosch',
      'model': '2018-2022',
      'price': 5.800,
      'available': 100,
    },
    {
      'name': 'Spark Plug',
      'description': 'Iridium spark plugs for better fuel efficiency and reliable starts.',
      'image_path': 'lib/Product_Data/spark_plug.jpg',
      'type': 'Coupe',
      'brand': 'NGK',
      'model': 'All Models',
      'price': 3.200,
      'available': 200,
    },
    {
      'name': 'Air Filter',
      'description': 'High-flow air filter to improve engine performance and longevity.',
      'image_path': 'lib/Product_Data/air_filter.jpeg',
      'type': 'Truck',
      'brand': 'K&N',
      'model': '2015-2021',
      'price': 12.000,
      'available': 30,
    },
    {
      'name': 'Wiper Blades',
      'description': 'All-weather silicone wiper blades for crystal clear visibility.',
      'image_path': 'lib/Product_Data/wiper_blades.jpg',
      'type': 'Hatchback',
      'brand': 'Rain-X',
      'model': 'Universal',
      'price': 8.500,
      'available': 75,
    },
  ];

  static Future<void> seedDatabase() async {
    final db = DatabaseHelper.instance;
    // Check if products already exist to avoid duplicates
    final existingProducts = await db.getProducts();
    if (existingProducts.isEmpty) {
      for (var product in defaultProducts) {
        Uint8List? imageBytes;
        try {
          final ByteData data = await rootBundle.load(product['image_path']);
          imageBytes = data.buffer.asUint8List();
        } catch (e) {
          print('Error loading image ${product['image_path']}: $e');
        }

        final productToInsert = Map<String, dynamic>.from(product);
        productToInsert.remove('image_path');
        productToInsert['image'] = imageBytes;
        
        await db.insertProduct(productToInsert);
      }
    }
  }
}
