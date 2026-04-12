import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:inflabasket/features/ai_scanner/data/ai_client.dart';
import 'package:inflabasket/features/ai_scanner/data/gemini_client.dart';
import 'package:inflabasket/features/ai_scanner/data/openai_client.dart';
import 'package:inflabasket/features/settings/data/api_keys_repository.dart';
import 'package:inflabasket/core/database/database.dart';

part 'ai_client_provider.g.dart';

@riverpod
AiClient? aiClient(AiClientRef ref) {
  final activeKey = ref.watch(activeApiKeyProvider).valueOrNull;
  if (activeKey == null || activeKey.key.isEmpty) return null;

  return activeKey.provider == 'gemini'
      ? GeminiClient(activeKey.key)
      : OpenAiClient(activeKey.key);
}

@riverpod
Stream<ApiKey?> activeApiKey(ActiveApiKeyRef ref) {
  final repo = ref.watch(apiKeysRepositoryProvider);
  return repo.watchActiveKey();
}
