import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:inflabasket/features/ai_scanner/data/ai_client.dart';
import 'package:inflabasket/features/ai_scanner/data/gemini_client.dart';
import 'package:inflabasket/features/ai_scanner/data/openai_client.dart';
import 'package:inflabasket/features/settings/application/settings_provider.dart';

part 'ai_client_provider.g.dart';

@riverpod
AiClient? aiClient(AiClientRef ref) {
  final settings = ref.watch(settingsControllerProvider);
  final provider = settings.aiProvider;
  final apiKey = provider == AiProvider.gemini
      ? settings.geminiApiKey
      : settings.openaiApiKey;

  if (apiKey.isEmpty) return null;

  return provider == AiProvider.gemini
      ? GeminiClient(apiKey)
      : OpenAiClient(apiKey);
}
