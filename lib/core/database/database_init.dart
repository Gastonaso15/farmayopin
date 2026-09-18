export 'database_init_io.dart'
    if (dart.library.js_interop) 'database_init_web.dart'
    if (dart.library.html) 'database_init_web.dart';
