
import 'dart:async';
import 'dart:ui';


import 'package:flutter/material.dart';


void showSnackBarSucceed(BuildContext context, String msg,
    {Color textColor = Colors.white,
      Color backgroundColor = Colors.green,
      int duration = 3,
      double elevation = 4.0,
      bool showCloseIcon = true}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("$msg!", style: TextStyle(color: textColor)),
      duration: Duration(seconds: duration),
      backgroundColor: backgroundColor,
      elevation: elevation,
      showCloseIcon: showCloseIcon));
}

void showSnackBarFailed(BuildContext context, String msg,
    {Color textColor = Colors.white,
      Color backgroundColor = Colors.red,
      int duration = 3,
      double elevation = 4.0,
      bool showCloseIcon = true}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("$msg!", style: TextStyle(color: textColor)),
      duration: Duration(seconds: duration),
      backgroundColor: backgroundColor,
      elevation: elevation,
      showCloseIcon: showCloseIcon));
}

void showSnackBarWarning(BuildContext context, String msg,
    {Color textColor = Colors.white,
      Color backgroundColor = Colors.yellow,
      int duration = 3,
      double elevation = 4.0,
      bool showCloseIcon = true}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("$msg!", style: TextStyle(color: textColor)),
      duration: Duration(seconds: duration),
      backgroundColor: backgroundColor,
      elevation: elevation,
      showCloseIcon: showCloseIcon));
}


void showGlassyModalBottomSheet(
    BuildContext context,
    String? message, {
      bool isError = true,
      // Widget? child,
      Color textColor = Colors.white,
      int duration = 4, // المدة بالثواني
      double elevation = 4.0,
      bool showCloseIcon = true,
    }) {
  Timer? autoCloseTimer;

  showModalBottomSheet(
    backgroundColor: Colors.transparent,
    elevation: elevation,
    isDismissible: showCloseIcon,
    context: context,
    builder: (BuildContext context) {
      // تشغيل المؤقت
      autoCloseTimer = Timer(Duration(seconds: duration), () {
        if (showCloseIcon && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });

      return Padding(
        padding: const EdgeInsets.only(bottom: 10.0, right: 15, left: 15),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            alignment: Alignment(0, 0),
            height: 100,
            child: Stack(
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isError
                          ? [
                        Colors.red.withValues(alpha: 0.5),
                        Colors.redAccent.withValues(alpha: 0.5),
                      ]
                          : [
                        Colors.green.withValues(alpha: 0.8),
                        Colors.greenAccent.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "$message",
                      style: TextStyle(
                        color: textColor,
                        //fontFamily: "Rubik",
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: showCloseIcon
                      ? IconButton(
                    onPressed: () {
                      // إلغاء المؤقت قبل الإغلاق اليدوي
                      autoCloseTimer?.cancel();
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.close, color: textColor),
                  )
                      : Container(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  ).whenComplete(() {
    // عند إغلاق الـ BottomSheet بأي طريقة، نلغي المؤقت
    autoCloseTimer?.cancel();
  });
}




// void showGlassyModalBottomSheet(BuildContext context,String? message,
// {
//   bool isError = true,
//   Color textColor = Colors.white,
//   int duration = 4,
//   double elevation = 4.0,
//   bool showCloseIcon = true
// }) {
//   showModalBottomSheet(
//     backgroundColor: Colors.transparent,
//     elevation: elevation,
//     isDismissible: showCloseIcon,
//     context: context,
//     builder: (BuildContext context) {
//       // إضافة مؤقت لإغلاق الـ BottomSheet بعد انتهاء المدة
//       // Future.delayed(Duration(seconds: duration), () {
//       //   //Navigator.canPop(context)
//       //   if (!showCloseIcon && Navigator.canPop(context) && Navigator.of(context).mounted) {
//       //     Navigator.of(context).pop();
//       //   }
//       // });
//       return StatefulBuilder(
//         builder: (BuildContext context, StateSetter setState) {
//           return Padding(
//             padding: const EdgeInsets.only(bottom: 10.0,right: 15,left: 15),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(20),
//               child: Container(
//                 alignment: Alignment(0, 0),
//                 // width:size.width * 0.9 ,
//                 height: 150,
//                 // color: Colors.white,
//                 child: Stack(
//                   children: [
//                     BackdropFilter(
//                       filter: ImageFilter.blur(
//                           sigmaX: 10,
//                           sigmaY: 10),
//                       child: Container(
//                         // color: Colors.transparent,
//                       ),
//                     ),
//
//                     Container(
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
//                         borderRadius: BorderRadius.circular(20),
//                         gradient: LinearGradient(
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                             colors: isError
//                                 ?[
//                               Colors.red.withValues(alpha: 0.5),
//                               Colors.redAccent.withValues(alpha: 0.5),
//                             ]
//                                 :[
//                               Colors.green.withValues(alpha: 0.5),
//                               Colors.greenAccent.withValues(alpha: 0.5),
//                             ]),
//                       ),
//                       child: Center(
//                         child: Text("$message",style: TextStyle(
//                           color: textColor,
//                           fontFamily: "Rubik",
//                           fontSize: 15,
//                           fontWeight: FontWeight.w500
//                         ),),
//                       ),
//                     ),
//                     Padding(padding: EdgeInsets.all(10),
//                       child:showCloseIcon
//                           ? IconButton(
//                           onPressed: (){
//                             Navigator.pop(context);
//                           },
//                           icon: Icon(Icons.close,color: textColor,))
//                       :Container(),
//                     )
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//     },
//   );
// }
