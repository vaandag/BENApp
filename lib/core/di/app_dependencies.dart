import '../network/api_client.dart';
import '../network/auth_token_store.dart';
import '../../features/memories/data/php_memory_repository.dart';
import '../../services/auth_service.dart';
import '../../services/memory_repository.dart';
import '../../services/memory_storage_service.dart';

/// Application composition root.
///
/// A single graph of long-lived services avoids creating a fresh HTTP client
/// or repository inside every screen and makes the app easier to test.
final class AppDependencies {
  AppDependencies._({
    required this.api,
    required this.auth,
    required this.memories,
    required this.localMemoryRepository,
  });

  factory AppDependencies.create() {
    final tokenStore = AuthTokenStore();
    final api = ApiClient(tokenStore: tokenStore);
    final auth = AuthService(api, tokenStore: tokenStore);
    return AppDependencies._(
      api: api,
      auth: auth,
      memories: PhpMemoryRepository(api),
      localMemoryRepository: MemoryRepository(
        storageService: MemoryStorageService(),
      ),
    );
  }

  final ApiClient api;
  final AuthService auth;
  final PhpMemoryRepository memories;
  final MemoryRepository localMemoryRepository;
}
