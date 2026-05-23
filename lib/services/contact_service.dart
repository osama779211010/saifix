import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../helper/custom_print_helper.dart';

class ContactService {
  static final ContactService _instance = ContactService._internal();
  factory ContactService() => _instance;
  ContactService._internal();

  List<Contact>? _cachedContacts;
  List<Contact>? get cachedContacts => _cachedContacts;
  bool _isLoading = false;

  Future<void> preLoadContacts({
    Duration delay = const Duration(seconds: 1),
    bool force = false,
  }) async {
    if ((_cachedContacts != null && !force) || _isLoading) return;
    _isLoading = true;

    // Delay to allow the app to finish its critical startup path (Splash/Login animations)
    if (delay != Duration.zero) {
      await Future.delayed(delay);
    }

    try {
      // Only pre-load if permission is already granted.
      // We don't want to trigger the permission dialog at startup.
      if (await Permission.contacts.isGranted) {
        customPrint("ContactService: Permission granted. Starting background fetch...");
        // Fetching with properties but without thumbnails/photos to save memory and time
        _cachedContacts = await FlutterContacts.getContacts(
          withProperties: true,
          withThumbnail: false,
          withPhoto: false,
        );
        customPrint(
          "ContactService: Pre-loaded ${_cachedContacts?.length} contacts",
        );
      } else {
        customPrint("ContactService: Permission not granted yet. Skipping pre-load.");
      }
    } catch (e) {
      customPrint("ContactService: Error pre-loading: $e");
    } finally {
      _isLoading = false;
    }
  }

  String getContactName(String phone) {
    if (_cachedContacts == null || _cachedContacts!.isEmpty) return phone;

    // Normalize input phone: keep only last 9 digits for matching
    String cleanInput = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanInput.length > 9) {
      cleanInput = cleanInput.substring(cleanInput.length - 9);
    }

    if (cleanInput.isEmpty) return phone;

    for (var contact in _cachedContacts!) {
      for (var p in contact.phones) {
        String cleanP = p.number.replaceAll(RegExp(r'\D'), '');
        if (cleanP.length > 9) {
          cleanP = cleanP.substring(cleanP.length - 9);
        }

        if (cleanP == cleanInput) {
          return contact.displayName;
        }
      }
    }
    return phone;
  }

  List<Contact> get allContacts => _cachedContacts ?? [];
}

final contactService = ContactService();
