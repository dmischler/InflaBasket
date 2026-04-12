import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' show ImageSource, XFile;
import 'package:inflabasket/core/api/openfoodfacts_client.dart';
import 'package:inflabasket/core/router/navigation_extras.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';

extension TypedNavigation on BuildContext {
  void pushAddEntry({required EntryWithDetails entryToEdit}) {
    GoRouter.of(this)
        .push('/home/add', extra: AddEntryExtras.edit(entry: entryToEdit));
  }

  void pushAddEntryFromBarcode(ProductInfo info) {
    GoRouter.of(this)
        .push('/home/add', extra: AddEntryExtras.fromBarcode(info: info));
  }

  void pushAddEntryFromEditRequest(EntryWithDetails entry,
      {bool lockSharedFields = true}) {
    GoRouter.of(this).push('/home/add',
        extra: AddEntryExtras.fromEditRequest(
          entry: entry,
          lockSharedFields: lockSharedFields,
        ));
  }

  void pushScanner({ImageSource? source, XFile? file}) {
    if (source != null) {
      GoRouter.of(this).push('/scanner', extra: ScannerExtras.source(source));
    } else if (file != null) {
      GoRouter.of(this).push('/scanner', extra: ScannerExtras.file(file));
    } else {
      GoRouter.of(this).push('/scanner');
    }
  }
}
