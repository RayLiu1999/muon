import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:muon/presentation/providers/settings_provider.dart';

part 'search_history_provider.g.dart';

const _kSearchHistoryKey = 'muon_search_history';

@riverpod
class SearchHistoryNotifier extends _$SearchHistoryNotifier {
  @override
  List<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getStringList(_kSearchHistoryKey) ?? [];
  }

  Future<void> addRecord(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final history = prefs.getStringList(_kSearchHistoryKey) ?? [];

    // 如果已經存在，先移除再加到最前面
    history.remove(trimmed);
    history.insert(0, trimmed);

    // 最多保留 15 筆
    if (history.length > 15) {
      history.removeRange(15, history.length);
    }

    await prefs.setStringList(_kSearchHistoryKey, history);
    state = history;
  }

  Future<void> removeRecord(String query) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final history = prefs.getStringList(_kSearchHistoryKey) ?? [];

    if (history.remove(query)) {
      await prefs.setStringList(_kSearchHistoryKey, history);
      state = history;
    }
  }

  Future<void> clearAll() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_kSearchHistoryKey);
    state = [];
  }
}
