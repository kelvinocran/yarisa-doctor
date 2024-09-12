import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/yarisa_strings.dart';
import '../../constants/yarisa_widgets.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: yarisaAppBar(context,
        title: AppStrings.patients,
      ),
    );
  }
}
