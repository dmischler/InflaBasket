import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';

part 'api_keys_repository.g.dart';

@Riverpod(keepAlive: true)
ApiKeysRepository apiKeysRepository(ApiKeysRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return ApiKeysRepository(db);
}

class ApiKeysRepository {
  final AppDatabase _db;

  ApiKeysRepository(this._db);

  Stream<List<ApiKey>> watchAllKeys() {
    return (_db.select(_db.apiKeys)
          ..orderBy([
            (t) => OrderingTerm.asc(t.provider),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .watch();
  }

  Stream<ApiKey?> watchActiveKey() {
    return (_db.select(_db.apiKeys)
          ..where((t) => t.isActive.equals(true))
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<ApiKey?> getActiveKey() {
    return (_db.select(_db.apiKeys)
          ..where((t) => t.isActive.equals(true))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<ApiKey> addKey({
    required String provider,
    required String name,
    required String key,
  }) async {
    final id = await _db.into(_db.apiKeys).insert(
          ApiKeysCompanion.insert(
            provider: provider,
            name: name,
            key: key,
          ),
        );
    final inserted = await (_db.select(_db.apiKeys)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    return inserted;
  }

  Future<void> deleteKey(int id) async {
    final keyToDelete = await (_db.select(_db.apiKeys)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (keyToDelete == null) return;
    final wasActive = keyToDelete.isActive;
    await (_db.delete(_db.apiKeys)..where((t) => t.id.equals(id))).go();
    if (wasActive) {
      final remaining = await _db.select(_db.apiKeys).get();
      if (remaining.isNotEmpty) {
        await setActiveKey(remaining.first.id);
      }
    }
  }

  Future<void> setActiveKey(int id) async {
    await _db.transaction(() async {
      await (_db.update(_db.apiKeys)..where((t) => t.isActive.equals(true)))
          .write(const ApiKeysCompanion(isActive: Value(false)));
      await (_db.update(_db.apiKeys)..where((t) => t.id.equals(id))).write(
        const ApiKeysCompanion(isActive: Value(true)),
      );
    });

    final provider = await (_db.select(_db.apiKeys)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (provider != null) {
      final providerName = provider.provider;
      await _db.into(_db.settings).insertOnConflictUpdate(
            SettingsCompanion.insert(
              key: 'ai_provider',
              value: providerName,
            ),
          );
    }
  }
}
