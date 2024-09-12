import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yarisa_doctor/extensions/yarisa_extensions.dart';

import '../../constants/yarisa_enums.dart';
import '../../constants/yarisa_strings.dart';
import '../../constants/yarisa_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: yarisaAppBar(context,
          autoShowBackButton: false,
          title: AppStrings.home,
          titleWidget: Row(
            children: [
              const CircleAvatar(),
              15.wgap,
              const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    YarisaText(
                      text: AppStrings.night,
                      type: TextType.bodySmall,
                      // spacing: 0,
                      color: Colors.grey,
                    ),
                    YarisaText(
                      text: "Dr. Michael",
                      type: TextType.bodyBig,
                      weight: FontWeight.w600,
                    ),
                  ]),
            ],
          )),
    );
  }
}
