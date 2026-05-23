import 'dart:async';

import 'package:flutter/material.dart';

// typedef AsyncVoidCallback = FutureOr<void> Function();

// class SelfieDialog {
//   /// يعيد Future<bool?> حيث true = تم اختيار التقاط السيلفي، false = إلغاء، null = إغلاق خارجي
//   static Future<bool?> show(
//     BuildContext context, {
//     required String message,
//     required String imagePath,
//     String cancelText = 'إلغاء',
//     String confirmText = 'موافق',
//     VoidCallback? onConfirm, // دالة تُنفّذ عند الضغط على زر التأكيد
//     VoidCallback? onCancel,  // دالة تُنفّذ عند الضغط على زر الإلغاء
//   }) {
//     return showDialog<bool>(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => Directionality(
//         textDirection: TextDirection.rtl,
//         child: Dialog(
//           backgroundColor: Colors.transparent,
//           insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
//           child: _DialogContent(
//             message: message,
//             imagePath: imagePath,
//             cancelText: cancelText,
//             confirmText: confirmText,
//             onConfirm: onConfirm,
//             onCancel: onCancel,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _DialogContent extends StatelessWidget {
//   final String message;
//   final String imagePath;
//   final String cancelText;
//   final String confirmText;
//   final VoidCallback? onConfirm;
//   final VoidCallback? onCancel;

//   const _DialogContent({
//     Key? key,
//     required this.message,
//     required this.imagePath,
//     required this.cancelText,
//     required this.confirmText,
//     this.onConfirm,
//     this.onCancel,
//   }) : super(key: key);

//   Widget _buildImage(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
//       return Image.network(imagePath, fit: BoxFit.contain, errorBuilder: (c, e, s) {
//         return _placeholder(isDark);
//       });
//     }

//     try {
//       return Image.asset(imagePath, fit: BoxFit.contain);
//     } catch (_) {
//       return _placeholder(isDark);
//     }
//   }

//   Widget _placeholder(bool isDark) {
//     return Container(
//       color: isDark ? Colors.grey[900] : Colors.grey[200],
//       child: const Center(child: Icon(Icons.person, size: 48, color: Colors.grey)),
//     );
//   }

//   // void _handleConfirm(BuildContext context)  {
//   //   try {
//   //     if (onConfirm != null) {
//   //        onConfirm!();
//   //     }
//   //   } catch (e) {
//   //     customPrint('SelfieDialog onConfirm error: $e');
//   //   } finally {
//   //     if (Navigator.of(context).canPop()) Navigator.of(context).pop(true);
//   //   }
//   // }

//   // void _handleCancel(BuildContext context)  {
//   //   try {
//   //     if (onCancel != null) {
//   //        onCancel!();
//   //     }
//   //   } catch (e) {
//   //     customPrint('SelfieDialog onCancel error: $e');
//   //   } finally {
//   //     if (Navigator.of(context).canPop()) Navigator.of(context).pop(false);
//   //   }
//   // }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Container(
//       decoration: BoxDecoration(
//         color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//         borderRadius: BorderRadius.circular(16.0),
//       ),
//       padding: const EdgeInsets.all(18.0),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // الصورة
//           Container(
//             padding: const EdgeInsets.all(8),
//             width: 140,
//             height: 140,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(16),
//               color: isDark ? Colors.grey[900] : Colors.grey[200],
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: _buildImage(context),
//             ),
//           ),

//           const SizedBox(height: 12),

//           // النص الممرّر
//           Text(
//             message,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               color: isDark ? Colors.white : Colors.black87,
//               fontSize: 15,
//               height: 1.4,
//               fontWeight: FontWeight.w500,
//             ),
//           ),

//           const SizedBox(height: 20),

//           // الأزرار مع نصوص ممرّرة
//           Row(
//             children: [
//               // إلغاء
//               Expanded(
//                 child: SizedBox(
//                   height: 44,
//                   child: TextButton(
//                     style: TextButton.styleFrom(
//                       backgroundColor:
//                           isDark ? Colors.grey[700] : Colors.grey[300],
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                     onPressed:onCancel, //() => _handleCancel(context),
//                     child: Text(
//                       cancelText,
//                       style: TextStyle(
//                         color: isDark ? Colors.white : Colors.black,
//                         fontSize: 15,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),

//               const SizedBox(width: 12),

//               // التقاط السيلفي
//               Expanded(
//                 child: SizedBox(
//                   height: 44,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF1F2D5D),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       elevation: 0,
//                     ),
//                     onPressed:onConfirm, //() => _handleConfirm(context),
//                     child: Text(
//                       confirmText,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 15,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

//2
class SelfieDialog {
  static Future<void> show(
    BuildContext context,
    String message,
    String imagePath,
    String cancelText,
    String confirmText,
    VoidCallback? onConfirm, // دالة تُنفّذ عند الضغط على زر التأكيد
    VoidCallback? onCancel,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _DialogContent(
                message: message,
                imagePath: imagePath,
                cancelText: cancelText,
                confirmText: confirmText,
                onConfirm: onConfirm,
                onCancel: onCancel,
              ),
            ),
          ),
    );
  }
}

class _DialogContent extends StatelessWidget {
  final String message;
  final String imagePath;
  final String cancelText;
  final String confirmText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const _DialogContent({
    required this.message,
    required this.imagePath,
    required this.cancelText,
    required this.confirmText,
    this.onConfirm,
    this.onCancel,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // الصورة
          Container(
            padding: const EdgeInsets.all(8),
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark ? Colors.grey[900] : Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
          ),

          const SizedBox(height: 12),

          // النص
          Text(
            message,
            // 'قم بالتقاط صورة سيلفي وانت رافع بطاقتك تحت الذقن كما هو موضح في النموذج وفي مكان تتوفر فيه إضاءة جيدة وعدم وجود غطاء (شال - قبعة - نظارة)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 20),

          // الأزرار
          Row(
            children: [
              // إلغاء
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.grey[700] : Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed:
                        onCancel, //() => Navigator.of(context).pop(false),
                    child: Text(
                      cancelText,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // التقاط السيلفي
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? Color(0xFF1F2D5D) : Color(0xFF1F2D5D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: onConfirm,
                    // () {
                    //   Navigator.of(context).pop(true);
                    // },
                    child: Text(
                      confirmText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';

// class SelfieDialog {
//   static Future<void> show(BuildContext context) {
//     return showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => Directionality(
//         textDirection: TextDirection.rtl,
//         child: Dialog(
//           backgroundColor: Colors.transparent,
//           insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
//           child: _DialogContent(),
//         ),
//       ),
//     );
//   }
// }

// class _DialogContent extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.black,
//         borderRadius: BorderRadius.circular(16.0),
//       ),
//       padding: const EdgeInsets.all(18.0),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // المحتوى العلوي: صورة + نص
//                  // رسم توضيحي
//               Container(
//                 padding: EdgeInsets.all(10),
//                 width: 84,
//                 height: 84,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(12),
//                   color: Colors.grey[900],
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(12),
//                   child: Image.asset(
//                     'logo_circle.png',
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
       
//               // النص
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: Text(
//                     'قم بالتقاط صورة سيلفي وانت رافع بطاقتك تحت الذقن كما هو موضح في النموذج وفي مكان تتوفر فيه إضاءة جيدة وعدم وجود غطاء (شال - قبعة - نظارة)',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 15,
//                       height: 1.4,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
    
//           const SizedBox(height: 20),
    
//           // الأزرار السفلية
//           Row(
//             children: [
//               // زر الإلغاء (رمادي)
//               Expanded(
//                 child: SizedBox(
//                   height: 44,
//                   child: TextButton(
//                     style: TextButton.styleFrom(
//                       backgroundColor: Colors.grey[700],
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                     onPressed: () => Navigator.of(context).pop(false),
//                     child: Text(
//                       'إلغاء',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 15,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               // زر التقط السيلفي (أحمر)
//               Expanded(
//                 child: SizedBox(
//                   height: 44,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue[600],
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       elevation: 0,
//                     ),
//                     onPressed: () {
//                       Navigator.of(context).pop(true);
//                       // ضع هنا منطق فتح الكاميرا أو الانتقال لصفحة التقاط السيلفي
//                     },
//                     child: Text(
//                       'التقط السيلفي',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 15,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
