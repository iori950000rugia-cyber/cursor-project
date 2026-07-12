import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/hoyolab/complete_hoyolab_web_login_use_case.dart';
import '../config/feature_flags.dart';
import '../data/hoyolab/hoyolab_cookie_service.dart';
import '../data/hoyolab/models/daily_note.dart';
import '../data/repositories/hoyolab_repository.dart';
import '../data/secure/secure_storage_service.dart';
import 'app_providers.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final hoyolabCookieServiceProvider = Provider<HoyolabCookieService>((ref) {
  return const HoyolabCookieService();
});

final featureFlagsProvider = FutureProvider<FeatureFlags>((ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  final raw = await db.getSetting(FeatureFlags.hoyolabLinkEnabledKey);
  final enabled = raw == null
      ? FeatureFlags.defaultHoyolabLinkEnabled
      : raw == 'true';
  return FeatureFlags(hoyolabLinkEnabled: enabled);
});

final hoyolabRepositoryProvider = FutureProvider<HoyolabRepository>((ref) async {
  final secure = ref.watch(secureStorageProvider);
  final flags = await ref.watch(featureFlagsProvider.future);
  return HoyolabRepository(
    secureStorage: secure,
    featureFlags: flags,
    cookieService: ref.watch(hoyolabCookieServiceProvider),
  );
});

final completeHoyolabWebLoginUseCaseProvider =
    FutureProvider<CompleteHoyolabWebLoginUseCase>((ref) async {
  final repo = await ref.watch(hoyolabRepositoryProvider.future);
  return CompleteHoyolabWebLoginUseCase(
    cookieService: ref.watch(hoyolabCookieServiceProvider),
    repository: repo,
  );
});

final hoyolabSessionProvider = FutureProvider<HoyolabSession>((ref) async {
  final flags = await ref.watch(featureFlagsProvider.future);
  if (!flags.hoyolabLinkEnabled) {
    return HoyolabSession.unlinked;
  }
  final repo = await ref.watch(hoyolabRepositoryProvider.future);
  return repo.loadSession();
});

final hoyolabRolesProvider = FutureProvider<List<HoyolabGameRole>>((ref) async {
  final session = await ref.watch(hoyolabSessionProvider.future);
  if (!session.isLinked) return [];
  final repo = await ref.watch(hoyolabRepositoryProvider.future);
  return repo.fetchAvailableRoles();
});
