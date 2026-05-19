// ============================================================
// database_helper.dart — Central Database Manager
// ============================================================
// This file handles ALL communication with the local SQLite
// database stored on the device.
//
// Key concepts for beginners:
//   • SQLite is a small database that lives in a file on the phone.
//   • A "singleton" means only ONE instance of DatabaseHelper ever
//     exists. Every part of the app shares the same connection.
//   • Every public method here is async (returns a Future) because
//     reading/writing to disk takes time.
//   • CRUD = Create, Read, Update, Delete — the four basic operations.
// ============================================================

import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// DatabaseHelper provides CRUD operations for every table in alis_grandson.db.
/// Access it anywhere with: `DatabaseHelper.instance`
class DatabaseHelper {
  // ── Singleton Setup ──────────────────────────────────────────
  // The single shared instance of this class.
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // The single open database connection (null until first use).
  static Database? _database;

  // Private constructor — prevents creating more than one instance.
  DatabaseHelper._privateConstructor();

  // ── Database Connection ──────────────────────────────────────

  /// Returns the open database, opening it first if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!; // Already open, reuse it.
    _database = await _initDatabase();
    return _database!;
  }

  /// Opens (or creates) the database file at the default system path.
  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    return await openDatabase(
      join(path, 'alis_grandson.db'), // File name on the device
      version: 10,                    // Increment this when the schema changes
      onCreate: _onCreate,            // Called the very first time
      onUpgrade: _onUpgrade,          // Called when version number increases
    );
  }

  // ── Schema Creation ──────────────────────────────────────────

  /// Creates all tables when the app is installed for the first time.
  Future<void> _onCreate(Database db, int version) async {
    // --- users table: stores customer accounts ---
    await db.execute('''
      CREATE TABLE users(
        username TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT NOT NULL,
        password TEXT NOT NULL,
        dob TEXT NOT NULL
      )
    ''');

    // --- admins table: stores admin login credentials ---
    await db.execute('''
      CREATE TABLE admins(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    // --- spare_part_products table: the product catalogue ---
    // `image` is stored as a BLOB (raw bytes) so no file paths are needed.
    await db.execute('''
      CREATE TABLE spare_part_products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        image BLOB,
        type TEXT,
        brand TEXT,
        model TEXT,
        price REAL NOT NULL,
        available INTEGER NOT NULL
      )
    ''');

    // --- cart table: items the user has added but not yet ordered ---
    await db.execute('''
      CREATE TABLE cart(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_username TEXT NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (user_username) REFERENCES users (username),
        FOREIGN KEY (product_id) REFERENCES spare_part_products (id)
      )
    ''');

    // --- orders table: confirmed purchases ---
    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_username TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT NOT NULL,
        special_instructions TEXT,
        payment_mode TEXT NOT NULL,
        total_price REAL NOT NULL,
        status TEXT NOT NULL,
        order_date TEXT NOT NULL,
        completion_date TEXT,
        FOREIGN KEY (user_username) REFERENCES users (username)
      )
    ''');

    // --- order_items table: individual products inside each order ---
    await db.execute('''
      CREATE TABLE order_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id),
        FOREIGN KEY (product_id) REFERENCES spare_part_products (id)
      )
    ''');

    // --- faqs table: help questions and answers shown in the Support screen ---
    await db.execute('''
      CREATE TABLE faqs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question TEXT NOT NULL,
        answer TEXT NOT NULL
      )
    ''');

    // Seed the FAQ table with default questions on first install.
    await seedFAQs(db);

    // Create the default admin account (email: admin, password: admin123).
    await db.insert('admins', {'email': 'admin', 'password': 'admin123'});
  }

  // ── Schema Migration ─────────────────────────────────────────

  /// Called when the database version number increases.
  /// Each `if` block handles one version upgrade step.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      // Added phone column to users.
      await db.execute('ALTER TABLE users ADD COLUMN phone TEXT NOT NULL DEFAULT ""');
    }
    if (oldVersion < 6) {
      // Added the cart table.
      await db.execute('''
        CREATE TABLE cart(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_username TEXT NOT NULL,
          product_id INTEGER NOT NULL,
          quantity INTEGER NOT NULL,
          FOREIGN KEY (user_username) REFERENCES users (username),
          FOREIGN KEY (product_id) REFERENCES spare_part_products (id)
        )
      ''');
    }
    if (oldVersion < 7) {
      // Added orders and order_items tables.
      await db.execute('''
        CREATE TABLE orders(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_username TEXT NOT NULL,
          address TEXT NOT NULL,
          phone TEXT NOT NULL,
          payment_mode TEXT NOT NULL,
          total_price REAL NOT NULL,
          status TEXT NOT NULL,
          order_date TEXT NOT NULL,
          FOREIGN KEY (user_username) REFERENCES users (username)
        )
      ''');
      await db.execute('''
        CREATE TABLE order_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_id INTEGER NOT NULL,
          product_id INTEGER NOT NULL,
          quantity INTEGER NOT NULL,
          price REAL NOT NULL,
          FOREIGN KEY (order_id) REFERENCES orders (id),
          FOREIGN KEY (product_id) REFERENCES spare_part_products (id)
        )
      ''');
    }
    if (oldVersion < 8) {
      // Added special_instructions column to orders.
      await db.execute('ALTER TABLE orders ADD COLUMN special_instructions TEXT');
    }
    if (oldVersion < 9) {
      // Added completion_date column to orders.
      await db.execute('ALTER TABLE orders ADD COLUMN completion_date TEXT');
    }
    if (oldVersion < 10) {
      // Added the faqs table.
      await db.execute('''
        CREATE TABLE faqs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          question TEXT NOT NULL,
          answer TEXT NOT NULL
        )
      ''');
      await seedFAQs(db);
    }
  }

  // ── FAQ Seeding ───────────────────────────────────────────────

  /// Inserts the default FAQ questions and answers.
  /// Can be called with an existing [db] connection (during onCreate/onUpgrade)
  /// or without one (it will open its own connection).
  Future<void> seedFAQs([Database? db]) async {
    final database = db ?? await instance.database;
    // Answers are intentionally empty — the AI chatbot answers these
    // questions live when a customer taps them in the Support screen.
    final List<Map<String, String>> defaultFaqs = [
      {
        'question': 'How do I place an order?',
        'answer': '',
      },
      {
        'question': 'Where are your store locations?',
        'answer': '',
      },
      {
        'question': 'What is your WhatsApp number for support?',
        'answer': '',
      },
      {
        'question': 'What payment methods do you accept?',
        'answer': '',
      },
      {
        'question': 'Is my payment information secure?',
        'answer': '',
      },
      {
        'question': 'How long does delivery take?',
        'answer': '',
      },
      {
        'question': 'What is your return policy?',
        'answer': '',
      },
      {
        'question': 'How do I track my order?',
        'answer': '',
      },
    ];

    for (var faq in defaultFaqs) {
      await database.insert('faqs', faq);
    }
  }

  // ── User Operations (CRUD) ────────────────────────────────────

  /// Saves a new user row. Returns the new row id, or 0 if the username already exists.
  Future<int> insertUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('users', row, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Returns true if the given [username] is already registered.
  Future<bool> isUsernameTaken(String username) async {
    final db = await instance.database;
    final result = await db.query('users', where: 'username = ?', whereArgs: [username]);
    return result.isNotEmpty;
  }

  /// Returns true if [email] is already linked to another account.
  /// Optionally pass [currentUsername] to exclude the current user when updating their own profile.
  Future<bool> isEmailTaken(String email, [String? currentUsername]) async {
    final db = await instance.database;
    final result = await db.query('users', where: 'email = ? AND username != ?', whereArgs: [email, currentUsername]);
    return result.isNotEmpty;
  }

  /// Returns all registered users sorted alphabetically by username.
  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await instance.database;
    return await db.query('users', orderBy: 'username ASC');
  }

  /// Returns a single user map matching [username], or null if not found.
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  /// Updates all fields of an existing user. Uses `username` as the primary key.
  Future<int> updateUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'users',
      row,
      where: 'username = ?',
      whereArgs: [row['username']],
    );
  }

  /// Changes only the password for the given [username].
  Future<int> updateUserPassword(String username, String newPassword) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'password': newPassword},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  /// Permanently deletes a user account by [username].
  Future<int> deleteUser(String username) async {
    final db = await instance.database;
    return await db.delete(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  // ── Product Operations (CRUD) ─────────────────────────────────

  /// Saves a new product and returns the new row id.
  Future<int> insertProduct(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('spare_part_products', row);
  }

  /// Returns a list of products.
  /// Pass [filter] = 'out_of_stock' or 'low_stock' to narrow results.
  /// Images are NOT included here to keep the list fast; use [getProductImage] separately.
  Future<List<Map<String, dynamic>>> getProducts({String? filter}) async {
    final db = await instance.database;
    if (filter == 'out_of_stock') {
      return await db.query('spare_part_products',
          columns: ['id', 'name', 'description', 'type', 'brand', 'model', 'price', 'available'],
          where: 'available = 0', orderBy: 'id DESC');
    } else if (filter == 'low_stock') {
      return await db.query('spare_part_products',
          columns: ['id', 'name', 'description', 'type', 'brand', 'model', 'price', 'available'],
          where: 'available > 0 AND available < 10', orderBy: 'id DESC');
    }
    return await db.query('spare_part_products',
        columns: ['id', 'name', 'description', 'type', 'brand', 'model', 'price', 'available'],
        orderBy: 'id DESC');
  }

  /// Returns all fields (except image) for a single product by [id].
  Future<Map<String, dynamic>?> getProduct(int id) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'spare_part_products',
      columns: ['id', 'name', 'description', 'type', 'brand', 'model', 'price', 'available'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  /// Fetches only the image bytes for a product.
  /// Kept separate from getProduct() so the list screen stays fast.
  Future<Uint8List?> getProductImage(int id) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'spare_part_products',
      columns: ['image'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return maps.first['image'] as Uint8List?;
    }
    return null;
  }

  /// Updates all fields of an existing product. Uses `id` as the primary key.
  Future<int> updateProduct(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'spare_part_products',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  /// Permanently removes a product from the catalogue.
  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete(
      'spare_part_products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Searches products by name or description containing [keyword].
  Future<List<Map<String, dynamic>>> searchProducts(String keyword) async {
    final db = await instance.database;
    return await db.query(
      'spare_part_products',
      columns: ['id', 'name', 'description', 'type', 'brand', 'model', 'price', 'available'],
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'id DESC',
    );
  }

  // ── Auth Operations ───────────────────────────────────────────

  /// Looks up a customer by email + password for login.
  /// Returns the user map if credentials match, or null if they do not.
  Future<Map<String, dynamic>?> getUser(String email, String password) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  /// Looks up an admin by email + password for login.
  Future<Map<String, dynamic>?> getAdmin(String email, String password) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'admins',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // ── Dashboard Statistics ──────────────────────────────────────

  /// Returns the total number of registered customers.
  Future<int> getUsersCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM users');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Returns the total number of products in the catalogue.
  Future<int> getProductsCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM spare_part_products');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Returns how many products have zero stock.
  Future<int> getOutOfStockCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM spare_part_products WHERE available = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Returns how many products have low stock (1–9 units).
  Future<int> getLowStockCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM spare_part_products WHERE available > 0 AND available < 10');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Returns orders that have not yet been delivered or cancelled.
  Future<int> getPendingOrdersCount() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT COUNT(*) FROM orders WHERE status NOT IN ('Delivered', 'Cancelled')");
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Returns the number of orders with status "Delivered".
  Future<int> getCompletedOrdersCount() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT COUNT(*) FROM orders WHERE status = 'Delivered'");
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Returns the sum of all delivered order totals (all-time revenue).
  Future<double> getTotalRevenue() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT SUM(total_price) FROM orders WHERE status = 'Delivered'");
    return (result.first.values.first as num?)?.toDouble() ?? 0.0;
  }

  /// Returns the revenue earned from delivered orders in the current calendar month.
  Future<double> getCurrentMonthRevenue() async {
    final db = await instance.database;
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1).toString();
    final result = await db.rawQuery(
      "SELECT SUM(total_price) FROM orders WHERE status = 'Delivered' AND order_date >= ?",
      [firstDayOfMonth]
    );
    return (result.first.values.first as num?)?.toDouble() ?? 0.0;
  }

  // ── Revenue Analytics ─────────────────────────────────────────

  /// Returns lightweight revenue rows (date + amount) for chart plotting
  /// between [start] and [end] dates.
  Future<List<Map<String, dynamic>>> getRevenueData(DateTime start, DateTime end) async {
    final db = await instance.database;
    return await db.query(
      'orders',
      columns: ['order_date', 'total_price'],
      where: "status = 'Delivered' AND order_date BETWEEN ? AND ?",
      whereArgs: [start.toString(), end.toString()],
      orderBy: 'order_date ASC'
    );
  }

  /// Returns full order rows for CSV export between [start] and [end].
  Future<List<Map<String, dynamic>>> getDetailedOrdersForRevenue(DateTime start, DateTime end) async {
    final db = await instance.database;
    return await db.query(
      'orders',
      where: "status = 'Delivered' AND order_date BETWEEN ? AND ?",
      whereArgs: [start.toString(), end.toString()],
      orderBy: 'order_date DESC'
    );
  }

  // ── Cart Operations ───────────────────────────────────────────

  /// Adds a product to the user's cart.
  /// If the product is already in the cart, its quantity is increased instead.
  Future<int> addToCart(String userUsername, int productId, int quantity) async {
    final db = await instance.database;

    // Check whether this product is already in the user's cart.
    final existingCartItem = await db.query(
      'cart',
      where: 'user_username = ? AND product_id = ?',
      whereArgs: [userUsername, productId],
    );

    if (existingCartItem.isNotEmpty) {
      // Product is already there — just add to the existing quantity.
      final newQuantity = (existingCartItem.first['quantity'] as int) + quantity;
      return await db.update(
        'cart',
        {'quantity': newQuantity},
        where: 'id = ?',
        whereArgs: [existingCartItem.first['id']],
      );
    } else {
      // New item — insert a fresh row.
      return await db.insert('cart', {
        'user_username': userUsername,
        'product_id': productId,
        'quantity': quantity,
      });
    }
  }

  /// Returns cart items for a user, with product details merged in.
  /// Each item map contains both cart fields (cart_id, quantity) and
  /// product fields (name, price, etc.).
  Future<List<Map<String, dynamic>>> getCartItems(String userUsername) async {
    final db = await instance.database;
    final cartItems = await db.query(
      'cart',
      where: 'user_username = ?',
      whereArgs: [userUsername],
    );

    final products = <Map<String, dynamic>>[];
    for (var item in cartItems) {
      final productDetails = await getProduct(item['product_id'] as int);
      if (productDetails != null) {
        final product = Map<String, dynamic>.from(productDetails);
        product['cart_id'] = item['id'];
        product['quantity'] = item['quantity'];
        products.add(product);
      }
    }
    return products;
  }

  /// Changes the quantity of a cart item identified by [cartId].
  Future<int> updateCartItem(int cartId, int quantity) async {
    final db = await instance.database;
    return await db.update(
      'cart',
      {'quantity': quantity},
      where: 'id = ?',
      whereArgs: [cartId],
    );
  }

  /// Removes a single item from the cart by its cart row [cartId].
  Future<int> deleteCartItem(int cartId) async {
    final db = await instance.database;
    return await db.delete(
      'cart',
      where: 'id = ?',
      whereArgs: [cartId],
    );
  }

  /// Removes all cart items for a given user (called after order is placed).
  Future<int> clearCart(String userUsername) async {
    final db = await instance.database;
    return await db.delete(
      'cart',
      where: 'user_username = ?',
      whereArgs: [userUsername],
    );
  }

  // ── Order Operations ──────────────────────────────────────────

  /// Places an order in a single database transaction so that:
  ///   1. The order header row is inserted.
  ///   2. Each order_item row is inserted.
  ///   3. Stock is decremented for each purchased product.
  ///   4. The user's cart is cleared.
  /// If any step fails, the entire transaction is rolled back.
  Future<int> placeOrder(Map<String, dynamic> order, List<Map<String, dynamic>> items) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final orderId = await txn.insert('orders', order);
      for (var item in items) {
        await txn.insert('order_items', {
          'order_id': orderId,
          'product_id': item['id'],
          'quantity': item['quantity'],
          'price': item['price'],
        });
        // Reduce stock count by the purchased quantity.
        await txn.rawUpdate(
          'UPDATE spare_part_products SET available = available - ? WHERE id = ?',
          [item['quantity'], item['id']],
        );
      }
      // Clear the cart once the order is confirmed.
      await txn.delete('cart', where: 'user_username = ?', whereArgs: [order['user_username']]);
      return orderId;
    });
  }

  /// Returns all orders placed by [userUsername], newest first.
  Future<List<Map<String, dynamic>>> getUserOrders(String userUsername) async {
    final db = await instance.database;
    return await db.query(
      'orders',
      where: 'user_username = ?',
      whereArgs: [userUsername],
      orderBy: 'id DESC',
    );
  }

  /// Returns all orders. Pass [filter] = 'pending' or 'completed' to narrow results.
  Future<List<Map<String, dynamic>>> getAllOrders({String? filter}) async {
    final db = await instance.database;
    if (filter == 'pending') {
      return await db.query('orders', where: "status NOT IN ('Delivered', 'Cancelled')", orderBy: 'id DESC');
    } else if (filter == 'completed') {
      return await db.query('orders', where: "status = 'Delivered'", orderBy: 'id DESC');
    }
    return await db.query('orders', orderBy: 'id DESC');
  }

  /// Updates the status of an order.
  /// If the new status is "Delivered" or "Cancelled", completion_date is also saved.
  Future<int> updateOrderStatus(int orderId, String status) async {
    final db = await instance.database;
    final Map<String, dynamic> values = {'status': status};
    if (status == 'Delivered' || status == 'Cancelled') {
      values['completion_date'] = DateTime.now().toString();
    }
    return await db.update(
      'orders',
      values,
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  /// Returns all items inside a specific order, with product names merged in.
  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    final db = await instance.database;
    final items = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );

    final detailedItems = <Map<String, dynamic>>[];
    for (var item in items) {
      final product = await getProduct(item['product_id'] as int);
      if (product != null) {
        final detailedItem = Map<String, dynamic>.from(item);
        detailedItem['product_name'] = product['name'];
        detailedItems.add(detailedItem);
      }
    }
    return detailedItems;
  }

  // ── FAQ Operations ────────────────────────────────────────────

  /// Inserts a new FAQ question and answer row.
  Future<int> insertFAQ(Map<String, dynamic> faq) async {
    final db = await instance.database;
    return await db.insert('faqs', faq);
  }

  /// Returns all FAQs ordered from oldest to newest.
  Future<List<Map<String, dynamic>>> getAllFAQs() async {
    final db = await instance.database;
    return await db.query('faqs', orderBy: 'id ASC');
  }

  /// Updates an existing FAQ row. Uses `id` as the primary key.
  Future<int> updateFAQ(Map<String, dynamic> faq) async {
    final db = await instance.database;
    return await db.update(
      'faqs',
      faq,
      where: 'id = ?',
      whereArgs: [faq['id']],
    );
  }

  /// Permanently deletes an FAQ by [id].
  Future<int> deleteFAQ(int id) async {
    final db = await instance.database;
    return await db.delete(
      'faqs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
