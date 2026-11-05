import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/ai_service.dart';
import 'services/document_service.dart';
import 'storage/local_store.dart';

final localStoreProvider = Provider<LocalStore>((ref) {
  throw UnimplementedError('localStoreProvider must be overridden in main()');
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final aiServiceProvider = Provider<AiService>((ref) => AiService());

final documentServiceProvider = Provider<DocumentService>(
  (ref) => const DocumentService(),
);
