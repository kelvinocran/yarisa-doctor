import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/yarisa_enums.dart';
import '../constants/yarisa_strings.dart';
import '../constants/yarisa_widgets.dart';

class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const YarisaText(
          text: AppStrings.more,
          type: TextType.appbar,
        ),
      ),
    );
  }
}
