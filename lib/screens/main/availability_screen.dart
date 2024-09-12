import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/yarisa_strings.dart';
import '../../constants/yarisa_widgets.dart';

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: yarisaAppBar(context,
        title: AppStrings.availability,
      ),
    );
  }
}
