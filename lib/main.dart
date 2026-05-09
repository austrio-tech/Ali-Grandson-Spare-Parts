import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:alis_grandson_app/src/app.dart';
import 'package:alis_grandson_app/src/core/session/session_manager.dart';
import 'package:alis_grandson_app/src/features/catalog/data/product_data.dart';

void main() async {
  // Ensure Flutter engine is ready
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("Environment variables loaded successfully");
  } catch (e) {
    debugPrint("Error loading .env file: $e");
  }
  
  // Seed the database with initial spare parts if empty
  await ProductData.seedDatabase();

  // Retrieve current session state
  final isAdminLoggedIn = await SessionManager.isAdminLoggedIn();
  final isUserLoggedIn = await SessionManager.isUserLoggedIn();

  // Launch the main application
  runApp(MyApp(
    isAdminLoggedIn: isAdminLoggedIn, 
    isUserLoggedIn: isUserLoggedIn,
  ));
}
