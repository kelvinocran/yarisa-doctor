import 'package:flutter/material.dart';
import 'package:get/get.dart';

// import '../theme/colors.dart';

// import '../utilities/assets.dart';


class EmptyWidget extends StatelessWidget {
  const EmptyWidget({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title, message, icon;

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // svg(icon, size: 100),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Padding(
          padding:
              EdgeInsets.symmetric(horizontal: Get.width / 4.5, vertical: 5.0),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        )
      ],
    ));
  }
}

class EmptyWidgetWithButton extends StatelessWidget {
  const EmptyWidgetWithButton({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.buttonText,
    required this.onPressed,
  });

  final String title, buttonText, message, icon;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // svg(icon, size: 100),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),

          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 15),
ElevatedButton(
                      onPressed: () async {

                      },
                      style: ButtonStyle(
                          elevation: const WidgetStatePropertyAll(0),
                          foregroundColor: WidgetStatePropertyAll(
                              !Get.isDarkMode ? Colors.white : Colors.black),
                          backgroundColor:
                              WidgetStateColor.resolveWith((states) {
                            if (states.contains(WidgetState.pressed)) {
                              return Colors.grey.withOpacity(.5);
                            }
                            if (Get.isDarkMode) {
                              return Colors.white;
                            } else {
                              return Colors.black;
                            }
                          }),
                          minimumSize: const WidgetStatePropertyAll(
                              Size(double.infinity, 50))),

                      child:  Text(buttonText)),
      ],
    ));
  }
}
