import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/artifact_score/artifact_score_type_override_loader.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureArtifactScoreTypeOverrideLoader();
  runApp(const ProviderScope(child: GenshinBuilderApp()));
}
