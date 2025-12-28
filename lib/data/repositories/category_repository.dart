import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../database/database.dart';

/// カテゴリリポジトリプロバイダー
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(databaseProvider));
});

/// カテゴリリポジトリ
class CategoryRepository {
  final AppDatabase _db;

  CategoryRepository(this._db);

  /// 有効なカテゴリ一覧を取得
  Future<List<Category>> getActiveCategories() async {
    return await (_db.select(_db.categories)
          ..where((c) => c.isDeleted.equals(false))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
  }

  /// カテゴリをIDで取得
  Future<Category?> getCategoryById(int id) async {
    return await (_db.select(_db.categories)
          ..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }
}
