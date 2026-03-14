import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';

part 'barcode_assignment_service.g.dart';

@riverpod
BarcodeAssignmentService barcodeAssignmentService(
    BarcodeAssignmentServiceRef ref) {
  return BarcodeAssignmentService(ref.watch(appDatabaseProvider));
}

class BarcodeAssignmentService {
  final AppDatabase _db;
  BarcodeAssignmentService(this._db);

  Future<BarcodeAssignmentResult> assignBarcode({
    required int productId,
    required String barcode,
  }) async {
    final existing = await (_db.select(_db.products)
          ..where(
              (p) => p.barcode.equals(barcode) & p.id.equals(productId).not()))
        .getSingleOrNull();

    if (existing != null) {
      return BarcodeAssignmentResult.conflict(existing);
    }

    final current = await (_db.select(_db.products)
          ..where((p) => p.id.equals(productId)))
        .getSingleOrNull();

    if (current?.barcode == barcode) {
      return BarcodeAssignmentResult.alreadyAssigned();
    }

    await (_db.update(_db.products)..where((p) => p.id.equals(productId)))
        .write(ProductsCompanion(barcode: Value(barcode)));

    return BarcodeAssignmentResult.success();
  }

  Future<void> removeBarcode(int productId) async {
    await (_db.update(_db.products)..where((p) => p.id.equals(productId)))
        .write(const ProductsCompanion(barcode: Value(null)));
  }
}

enum BarcodeAssignmentStatus {
  success,
  alreadyAssigned,
  conflict,
}

class BarcodeAssignmentResult {
  final BarcodeAssignmentStatus status;
  final Product? conflictingProduct;

  const BarcodeAssignmentResult.success()
      : status = BarcodeAssignmentStatus.success,
        conflictingProduct = null;

  const BarcodeAssignmentResult.alreadyAssigned()
      : status = BarcodeAssignmentStatus.alreadyAssigned,
        conflictingProduct = null;

  const BarcodeAssignmentResult.conflict(Product product)
      : status = BarcodeAssignmentStatus.conflict,
        conflictingProduct = product;
}
