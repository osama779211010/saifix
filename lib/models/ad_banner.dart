import '../services/api_service.dart';

class AdBanner {
  final int id;
  final String title;
  final String? subtitle;
  final String image;
  final bool isActive;
  final bool isImage;
  final DateTime createdAt;

  AdBanner({
    required this.id,
    required this.title,
    this.subtitle,
    required this.image,
    required this.isActive,
    this.isImage = true,
    required this.createdAt,
  });

  factory AdBanner.fromJson(Map<String, dynamic> json) {
    String imageUrl = json['image'] ?? '';
    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('/')) {
        imageUrl =
            '${ApiService.baseUrl.endsWith('/') ? ApiService.baseUrl.substring(0, ApiService.baseUrl.length - 1) : ApiService.baseUrl}$imageUrl';
      } else {
        // imageUrl = ApiService.baseUrl + imageUrl;
        imageUrl = imageUrl.replaceAll(
          "http://wallet.alsaifiex.com/media/",
          "${ApiService.baseUrl}media/",
        );
      }
    }

    return AdBanner(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      image: imageUrl,
      isActive: json['is_active'],
      isImage: json['is_image'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// import '../services/api_service.dart';

// class AdBanner {
//   final int id;
//   final String title;
//   final String? subtitle;
//   final String image;
//   final bool isActive;
//   final bool isImage;
//   final DateTime createdAt;

//   AdBanner({
//     required this.id,
//     required this.title,
//     this.subtitle,
//     required this.image,
//     required this.isActive,
//     this.isImage = true,
//     required this.createdAt,
//   });

//   factory AdBanner.fromJson(Map<String, dynamic> json) {
//     String imageUrl = json['image'] ?? '';
//     String finalImageUrl = getImageUrl(imageUrl);
//     // if (imageUrl.startsWith('/')) {
//     //   imageUrl =
//     //       '${ApiService.baseUrl.endsWith('/') ? ApiService.baseUrl.substring(0, ApiService.baseUrl.length - 1) : ApiService.baseUrl}$imageUrl';
//     // }
//     return AdBanner(
//       id: json['id'],
//       title: json['title'],
//       subtitle: json['subtitle'],
//       image: json['image'], //imageUrl,
//       isActive: json['is_active'],
//       isImage: json['is_image'] ?? true,
//       createdAt: DateTime.parse(json['created_at']),
//     );
//   }

//   String getImageUrl(String imageUrl) {
//     if (imageUrl.startsWith("http") &&
//         imageUrl.contains("/media/") &&
//         !imageUrl.contains(":7460/media/")) {
//       return imageUrl.replaceAll("/media/", ":7460/media/");
//     } else if (!imageUrl.startsWith("http")) {
//       // إذا كان المسار نسبياً، نستخدم Session.BaseUrl لاستخراج العنوان الأساسي وإضافة المنفذ
//       try {
//         var uri = Uri.parse(ApiService.baseUrl);
//         String rootUrl = "${uri.scheme}://${uri.host}:7460";
//         String cleanPath = imageUrl.trimLeft();
//         if (cleanPath.startsWith("media/")) {
//           imageUrl = rootUrl + "/" + cleanPath;
//         } else {
//           imageUrl = rootUrl + "/media/" + cleanPath;
//         }
//       } catch (e) {
//         return "https://wallet.alsaifiex.com:7460/media/" + imageUrl.trimLeft();
//       }
//     }
//     return image;
//   }
// }

// // // import '../services/api_service.dart';

// // // class AdBanner {
// // //   final int id;
// // //   final String title;
// // //   final String? subtitle;
// // //   final String image;
// // //   final bool isActive;
// // //   final DateTime createdAt;

// // //   AdBanner({
// // //     required this.id,
// // //     required this.title,
// // //     this.subtitle,
// // //     required this.image,
// // //     required this.isActive,
// // //     required this.createdAt,
// // //   });

// // //   factory AdBanner.fromJson(Map<String, dynamic> json) {
// // //     String imageUrl = json['image'] ?? '';
// // //     if (imageUrl.startsWith('/')) {
// // //       imageUrl = '${ApiService.baseUrl.endsWith('/') ? ApiService.baseUrl.substring(0, ApiService.baseUrl.length - 1) : ApiService.baseUrl}$imageUrl';
// // //     }
// // //     return AdBanner(
// // //       id: json['id'],
// // //       title: json['title'],
// // //       subtitle: json['subtitle'],
// // //       image: imageUrl,
// // //       isActive: json['is_active'],
// // //       createdAt: DateTime.parse(json['created_at']),
// // //     );
// // //   }
// // // }
