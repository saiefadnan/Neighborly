import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/pages/authPage.dart';

void initPageVal(WidgetRef ref) {
  ref.read(pageNumberProvider.notifier).state = 0;
}
