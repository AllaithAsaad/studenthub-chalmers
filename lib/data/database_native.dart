import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

Future<Database> openPlatformDatabase(OpenDatabaseOptions options) async =>
    databaseFactory.openDatabase(
      p.join(await getDatabasesPath(), 'studenthub_v1.db'),
      options: options,
    );
