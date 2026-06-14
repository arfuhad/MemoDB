import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'models.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final healthProvider = FutureProvider<bool>((ref) async {
  return ref.watch(apiClientProvider).health();
});

final notesProvider = FutureProvider<List<NoteItem>>((ref) async {
  return ref.watch(apiClientProvider).documents();
});
