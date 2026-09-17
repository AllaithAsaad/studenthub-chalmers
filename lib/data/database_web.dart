import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<Database> openPlatformDatabase(OpenDatabaseOptions options) =>
    databaseFactoryFfiWeb.openDatabase('studenthub_v1.db', options: options);
