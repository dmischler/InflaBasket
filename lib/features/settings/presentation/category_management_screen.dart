import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inflabasket/core/database/database.dart';
import 'package:inflabasket/core/localization/category_localization.dart';
import 'package:inflabasket/features/entry_management/application/entry_providers.dart';
import 'package:inflabasket/features/entry_management/data/entry_repository.dart';
import 'package:inflabasket/l10n/app_localizations.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsManageCategories)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(child: Text(l10n.categoryManagementEmpty));
          }

          return ListView.separated(
            itemCount: categories.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isCustom = category.isCustom;
              final categoryName = CategoryLocalization.displayNameForContext(
                context,
                category.name,
              );
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    categoryName.isNotEmpty
                        ? categoryName[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(categoryName),
                subtitle: Text(isCustom
                    ? l10n.categoryManagementCustomBadge
                    : l10n.categoryManagementDefaultBadge),
                trailing: isCustom
                    ? IconButton(
                        tooltip: l10n.delete,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDeleteCategory(
                          context,
                          ref,
                          category,
                        ),
                      )
                    : null,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Text(l10n.categoryManagementError(e.toString()));
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showAddCategoryDialog(
      BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.addCategoryTitle),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: l10n.addCategoryHint,
                border: const OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? l10n.fieldRequired : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await ref
                      .read(entryRepositoryProvider)
                      .addCategory(controller.text.trim());
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final repo = ref.read(entryRepositoryProvider);
    final hasProducts = await repo.hasProductsForCategory(category.id);

    if (hasProducts) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.deleteCategoryHasProducts),
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        final dl10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(dl10n.deleteCategoryConfirm(
            CategoryLocalization.displayNameForContext(context, category.name),
          )),
          content: Text(
            CategoryLocalization.displayNameForContext(context, category.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(dl10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(dl10n.delete),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await repo.deleteCategory(category.id);
    }
  }
}
