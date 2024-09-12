import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/yarisa_strings.dart';
import '../../constants/yarisa_widgets.dart';

class AppointmentScreen extends ConsumerStatefulWidget {
  const AppointmentScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AppointmentScreenState();
}

class _AppointmentScreenState extends ConsumerState<AppointmentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: yarisaAppBar(
        context,
        title: AppStrings.appointments,
      ),
    );
  }
}
