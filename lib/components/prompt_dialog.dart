// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';

// import '../theme/colors.dart';
// import '../utilities/app_strings.dart';
// import '../utilities/assets.dart';
// import '../utilities/global.dart';

// class PromptDialog extends StatelessWidget {
//   const PromptDialog({
//     super.key,
//     this.title,
//     this.icon,
//     this.message,
//     this.buttonText,
//     required this.onPressed,
//     this.singleOption,
//   });

//   final String? title, icon, message, buttonText;
//   final void Function() onPressed;
//   final bool? singleOption;

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shadowColor: Colors.grey.withOpacity(.2),
//       surfaceTintColor: Get.isDarkMode ? const Color(0xFF222222) : white,
//       backgroundColor: Get.isDarkMode ? const Color(0xFF222222) : white,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
//       child: Padding(
//         padding: EdgeInsets.all(Get.width > 800 ? 15.sp : 20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (icon != null) svg(icon!),
//             SizedBox(height: 10.h),
//             Text(
//               title!,
//               textAlign: TextAlign.center,
//               style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   fontSize: Get.width > 800 ? 12.sp : 16.sp),
//             ),
//             SizedBox(height: 3.h),
//             Flexible(
//               child: SingleChildScrollView(
//                 child: Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 10.w),
//                   child: Text(
//                     message ?? AppStrings.sorrysomething,
//                     textAlign: TextAlign.center,
//                     style: Theme.of(context)
//                         .textTheme
//                         .bodySmall
//                         ?.copyWith(fontSize: Get.width > 800 ? 8.sp : 14.sp),
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(height: 15.h),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Flexible(
//                   child: Visibility(
//                     visible: !singleOption!,
//                     child: OutlinedButton(
//                         style: OutlinedButton.styleFrom(
//                             elevation: 0,
//                             minimumSize: const Size(double.infinity, 50),
//                             foregroundColor: Get.isDarkMode ? white : black,
//                             shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(15)),
//                             side:
//                                 BorderSide(color: Colors.grey.withOpacity(.3)),
//                             backgroundColor: Colors.grey.withOpacity(0)),
//                         onPressed: () {
//                           goBack();
//                         },
//                         child: const Text(AppStrings.cancel)),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Flexible(
//                   child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                           elevation: 0,
//                           minimumSize: const Size(double.infinity, 50),
//                           foregroundColor: Get.isDarkMode ? white : black,
//                           backgroundColor: primary.withOpacity(.3)),
//                       onPressed: () {
//                         goBack();
//                         onPressed();
//                       },
//                       child: Text(
//                         "$buttonText",
//                         style:
//                             Get.width > 800 ? TextStyle(fontSize: 8.sp) : null,
//                       )),
//                 ),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
