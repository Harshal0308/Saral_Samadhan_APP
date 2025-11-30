import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DatabaseService {
  // Singleton instance
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database == null) {
      await _initDatabase();
    }
    return _database!;
  }

  Future<void> _initDatabase() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDocumentDir.path, 'saral_app.db');
    _database = await databaseFactoryIo.openDatabase(dbPath);
  }

  Future<void> clearAllStores() async {
    final db = await database;
    // Iterate over all stores and clear them
    // This is a simplified approach, in a real app you might want to clear specific stores
    // or re-initialize the database
    await db.transaction((txn) async {
      await intMapStoreFactory.store('students').delete(txn);
      await intMapStoreFactory.store('attendance').delete(txn);
      await intMapStoreFactory.store('volunteer_reports').delete(txn);
      await intMapStoreFactory.store('user_settings').delete(txn);
      await intMapStoreFactory.store('notifications').delete(txn);
      await intMapStoreFactory.store('events').delete(txn);
      await intMapStoreFactory.store('schedules').delete(txn); // New: Clear schedules store
    });
  }
}
