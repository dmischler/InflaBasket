import 'package:image_picker/image_picker.dart' show ImageSource, XFile;
import 'package:inflabasket/core/api/openfoodfacts_client.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';

sealed class NavigationExtras {
  const NavigationExtras();
}

final class AddEntryExtras extends NavigationExtras {
  final EntryWithDetails? entryToEdit;
  final ProductInfo? productInfo;
  final bool lockSharedFields;

  const AddEntryExtras.edit({required EntryWithDetails entry})
      : entryToEdit = entry,
        productInfo = null,
        lockSharedFields = false;

  const AddEntryExtras.fromBarcode({required ProductInfo info})
      : entryToEdit = null,
        productInfo = info,
        lockSharedFields = false;

  const AddEntryExtras.fromEditRequest({
    required EntryWithDetails entry,
    this.lockSharedFields = true,
  })  : entryToEdit = entry,
        productInfo = null;
}

final class ScannerExtras extends NavigationExtras {
  final ImageSource? source;
  final XFile? file;

  const ScannerExtras.source(this.source) : file = null;
  const ScannerExtras.file(this.file) : source = null;
}
