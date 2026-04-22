import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    return await openDatabase(
      join(path, 'alis_grandson.db'),
      version: 10,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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
    await db.execute('''
      CREATE TABLE admins(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        password TEXT NOT NULL
      )
    ''');
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
    await db.execute('''
      CREATE TABLE faqs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question TEXT NOT NULL,
        answer TEXT NOT NULL
      )
    ''');
    
    // Seed default FAQs
    await seedFAQs(db);

    // Insert default admin credentials.
    await db.insert('admins', {'email': 'admin', 'password': 'admin123'});
  }

  Future<void> seedFAQs([Database? db]) async {
    final database = db ?? await instance.database;
    final List<Map<String, String>> defaultFaqs = [
      {
        'question': 'How do I place an order?',
        'answer': 'To place an order, browse our products, select the item you need, choose the quantity, and add it to your cart. Once you are ready, go to your cart and click "Place Order" to provide your delivery details.'
      },
      {
        'question': 'Where is location for a company',
        'answer': 'Ali Grandson Spare Parts is located in Muscat, Oman. You can find our physical store in the industrial area for genuine spare parts.'
      },
      {
        'question': 'I need WhatsApp number to contact personaly',
        'answer': 'You can reach us on WhatsApp at +968 1234 5678. We are available from 8 AM to 8 PM to assist you with your queries.'
      },
      {
        'question': 'What payment methods are accepted?',
        'answer': 'We currently accept Cash on Delivery (COD) and all major Credit/Debit cards.'
      },
      {
        'question': 'Is my payment information secure?',
        'answer': 'Yes, your safety is our priority. We use encrypted payment gateways, and we do not store your full card details on our local database.'
      },
    ];

    for (var faq in defaultFaqs) {
      await database.insert('faqs', faq);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE users ADD COLUMN phone TEXT NOT NULL DEFAULT ""');
    }
    if (oldVersion < 6) {
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
      await db.execute('ALTER TABLE orders ADD COLUMN special_instructions TEXT');
    }
    if (oldVersion < 9) {
      await db.execute('ALTER TABLE orders ADD COLUMN completion_date TEXT');
    }
    if (oldVersion < 10) {
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

  Future<int> insertUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('users', row, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<bool> isUsernameTaken(String username) async {
    final db = await instance.database;
    final result = await db.query('users', where: 'username = ?', whereArgs: [username]);
    return result.isNotEmpty;
  }

  Future<bool> isEmailTaken(String email, [String? currentUsername]) async {
    final db = await instance.database;
    final result = await db.query('users', where: 'email = ? AND username != ?', whereArgs: [email, currentUsername]);
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await instance.database;
    return await db.query('users', orderBy: 'username ASC');
  }

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

  Future<int> updateUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'users',
      row,
      where: 'username = ?',
      whereArgs: [row['username']],
    );
  }

  Future<int> updateUserPassword(String username, String newPassword) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'password': newPassword},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  Future<int> deleteUser(String username) async {
    final db = await instance.database;
    return await db.delete(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  Future<int> insertProduct(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('spare_part_products', row);
  }

  Future<List<Map<String, dynamic>>> getProducts({String? filter}) async {
    final db = await instance.database;
    if (filter == 'out_of_stock') {
      return await db.query('spare_part_products', columns: ['id', 'name', 'description', 'type', 'brand', 'model', 'price', 'available'], where: 'available = 0', orderBy: 'id DESC');
    } else if (filter == 'low_stock') {
      return await db.query('spare_part_products', columns: ['id', 'name', 'description', 'type', 'brand', 'model', 'price', 'available'], where: 'available > 0 AND available < 10', orderBy: 'id DESC');
    }
    return await db.query('spare_part_products', columns: ['id', 'name', 'description', 'type', 'brand', 'model', 'price', 'available'], orderBy: 'id DESC');
  }

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

  Future<int> updateProduct(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'spare_part_products',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete(
      'spare_part_products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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

  Future<int> getUsersCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM users');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getProductsCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM spare_part_products');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getOutOfStockCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM spare_part_products WHERE available = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getLowStockCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM spare_part_products WHERE available > 0 AND available < 10');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getPendingOrdersCount() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT COUNT(*) FROM orders WHERE status NOT IN ('Delivered', 'Cancelled')");
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getCompletedOrdersCount() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT COUNT(*) FROM orders WHERE status = 'Delivered'");
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<double> getTotalRevenue() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT SUM(total_price) FROM orders WHERE status = 'Delivered'");
    return (result.first.values.first as num?)?.toDouble() ?? 0.0;
  }

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

  // Cart methods
  Future<int> addToCart(String userUsername, int productId, int quantity) async {
    final db = await instance.database;
    final existingCartItem = await db.query(
      'cart',
      where: 'user_username = ? AND product_id = ?',
      whereArgs: [userUsername, productId],
    );

    if (existingCartItem.isNotEmpty) {
      final newQuantity = (existingCartItem.first['quantity'] as int) + quantity;
      return await db.update(
        'cart',
        {'quantity': newQuantity},
        where: 'id = ?',
        whereArgs: [existingCartItem.first['id']],
      );
    } else {
      return await db.insert('cart', {
        'user_username': userUsername,
        'product_id': productId,
        'quantity': quantity,
      });
    }
  }

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

  Future<int> updateCartItem(int cartId, int quantity) async {
    final db = await instance.database;
    return await db.update(
      'cart',
      {'quantity': quantity},
      where: 'id = ?',
      whereArgs: [cartId],
    );
  }

  Future<int> deleteCartItem(int cartId) async {
    final db = await instance.database;
    return await db.delete(
      'cart',
      where: 'id = ?',
      whereArgs: [cartId],
    );
  }

  Future<int> clearCart(String userUsername) async {
    final db = await instance.database;
    return await db.delete(
      'cart',
      where: 'user_username = ?',
      whereArgs: [userUsername],
    );
  }

  // Order methods
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
        // Reduce quantity in stock
        await txn.rawUpdate(
          'UPDATE spare_part_products SET available = available - ? WHERE id = ?',
          [item['quantity'], item['id']],
        );
      }
      // Clear cart
      await txn.delete('cart', where: 'user_username = ?', whereArgs: [order['user_username']]);
      return orderId;
    });
  }

  Future<List<Map<String, dynamic>>> getUserOrders(String userUsername) async {
    final db = await instance.database;
    return await db.query(
      'orders',
      where: 'user_username = ?',
      whereArgs: [userUsername],
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllOrders({String? filter}) async {
    final db = await instance.database;
    if (filter == 'pending') {
      return await db.query('orders', where: "status NOT IN ('Delivered', 'Cancelled')", orderBy: 'id DESC');
    } else if (filter == 'completed') {
      return await db.query('orders', where: "status = 'Delivered'", orderBy: 'id DESC');
    }
    return await db.query('orders', orderBy: 'id DESC');
  }

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

  // FAQ methods
  Future<int> insertFAQ(Map<String, dynamic> faq) async {
    final db = await instance.database;
    return await db.insert('faqs', faq);
  }

  Future<List<Map<String, dynamic>>> getAllFAQs() async {
    final db = await instance.database;
    return await db.query('faqs', orderBy: 'id ASC');
  }

  Future<int> updateFAQ(Map<String, dynamic> faq) async {
    final db = await instance.database;
    return await db.update(
      'faqs',
      faq,
      where: 'id = ?',
      whereArgs: [faq['id']],
    );
  }

  Future<int> deleteFAQ(int id) async {
    final db = await instance.database;
    return await db.delete(
      'faqs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
