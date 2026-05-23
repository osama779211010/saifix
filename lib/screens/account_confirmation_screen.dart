import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saifix/helper/custom_print_helper.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import 'id_camera_screen.dart';
import '../components/qr_scanner_screen.dart';

class AccountConfirmationScreen extends StatefulWidget {
  final bool isDarkMode;
  final bool isUpdating;
  final String? rejectionReason;
  const AccountConfirmationScreen({
    super.key,
    required this.isDarkMode,
    this.isUpdating = false,
    this.rejectionReason,
  });

  @override
  State<AccountConfirmationScreen> createState() =>
      _AccountConfirmationScreenState();
}

class _AccountConfirmationScreenState extends State<AccountConfirmationScreen> {
  // Page Controller
  final PageController _pageController = PageController();
  int _currentStep = 1;

  // Identity Data Controllers
  final _idNumberController = TextEditingController();
  final _issuerController = TextEditingController();
  final _placeOfBirthController = TextEditingController();

  // Residence Data Controllers
  final _districtController = TextEditingController();
  final _areaController = TextEditingController();
  final _addressController = TextEditingController();

  // Date Controllers for manual numeric entry
  final _issueDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _dobController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String _selectedIdType = 'id_card'.tr();
  String _selectedNationality = 'yemeni_nationality'.tr();
  String _selectedCountry = 'yemen_country'.tr();
  String _selectedCity = 'sanaa_city'.tr();

  // جميع الدول العربية مع محافظاتها
  final Map<String, List<String>> _arabCountries = {
    'yemen_country'.tr(): [
      'sanaa_city'.tr(),
      'aden_city'.tr(),
      'taiz_city'.tr(),
      'hodeidah_city'.tr(),
      'ib_city'.tr(),
      'hadramout_city'.tr(),
      'lahj_city'.tr(),
      'abyan_city'.tr(),
      'shabwa_city'.tr(),
      'albayda_city'.tr(),
      'marib_city'.tr(),
      'aljawf_city'.tr(),
      'amran_city'.tr(),
      'hajjah_city'.tr(),
      'saada_city'.tr(),
      'almahweet_city'.tr(),
      'dhammar_city'.tr(),
      'raymah_city'.tr(),
      'socotra_city'.tr(),
      'almahra_city'.tr(),
      'aldhale_city'.tr(),
    ],
    'saudi_arabia_country'.tr(): [
      'riyadh_city'.tr(),
      'jeddah_city'.tr(),
      'mecca_city'.tr(),
      'medina_city'.tr(),
      'dammam_city'.tr(),
      'taif_city'.tr(),
      'tabuk_city'.tr(),
      'abha_city'.tr(),
      'khamees_mushait_city'.tr(),
      'buraydah_city'.tr(),
      'hail_city'.tr(),
      'najran_city'.tr(),
      'jazan_city'.tr(),
      'asir_city'.tr(),
      'sakaka_city'.tr(),
    ],
    'egypt_country'.tr(): [
      'cairo_city'.tr(),
      'alexandria_city'.tr(),
      'giza_city'.tr(),
      'sinai_region'.tr(),
      'sharqia_city'.tr(),
      'gharbia_city'.tr(),
      'sohag_city'.tr(),
      'damietta_city'.tr(),
      'dakahlia_city'.tr(),
      'fayoum_city'.tr(),
      'beni_suef_city'.tr(),
      'minya_city'.tr(),
      'assiut_city'.tr(),
      'sohag_city'.tr(),
      'qena_city'.tr(),
    ],
    'uae_country'.tr(): [
      'abu_dhabi_city'.tr(),
      'dubai_city'.tr(),
      'sharjah_city'.tr(),
      'ajman_city'.tr(),
      'ras_al_khaimah_city'.tr(),
      'fujairah_city'.tr(),
      'umm_al_quwain_city'.tr(),
    ],
    'kuwait_country'.tr(): [
      'kuwait_city'.tr(),
      'hawalli_city'.tr(),
      'mubarak_al_kabeer_city'.tr(),
      'farwaniya_city'.tr(),
      'jahra_city'.tr(),
      'ahmadi_city'.tr(),
    ],
    'oman_country'.tr(): [
      'muscat_city'.tr(),
      'salalah_city'.tr(),
      'al_batina_region'.tr(),
      'al_dhahirah_region'.tr(),
      'al_dakhiliyah_region'.tr(),
      'al_sharqiyah_region'.tr(),
      'musandam_region'.tr(),
    ],
    'bahrain_country'.tr(): [
      'manama_city'.tr(),
      'muharraq_city'.tr(),
      'al_luwayah_city'.tr(),
      'jad_hafs_city'.tr(),
      'sitra_city'.tr(),
    ],
    'qatar_country'.tr(): [
      'doha_city'.tr(),
      'wakra_city'.tr(),
      'al_khor_city'.tr(),
      'al_rayyan_city'.tr(),
      'al_shahaniya_city'.tr(),
      'um_sallal_city'.tr(),
    ],
    'jordan_country'.tr(): [
      'amman_city'.tr(),
      'irbid_city'.tr(),
      'zarqa_city'.tr(),
      'aqaba_city'.tr(),
      'karak_city'.tr(),
      'maan_city'.tr(),
      'mafraq_city'.tr(),
    ],
    'syria_country'.tr(): [
      'damascus_city'.tr(),
      'aleppo_city'.tr(),
      'homs_city'.tr(),
      'latakia_city'.tr(),
      'deir_ez_zor_city'.tr(),
      'daraa_city'.tr(),
      'as_suwayda_city'.tr(),
      'raqqa_city'.tr(),
    ],
    'iraq_country'.tr(): [
      'baghdad_city'.tr(),
      'basra_city'.tr(),
      'mosul_city'.tr(),
      'erbil_city'.tr(),
      'kirkuk_city'.tr(),
      'najaf_city'.tr(),
      'karbala_city'.tr(),
    ],
    'lebanon_country'.tr(): [
      'beirut_city'.tr(),
      'tripoli_city'.tr(),
      'sidon_city'.tr(),
      'zahle_city'.tr(),
      'bekaa_city'.tr(),
    ],
    'sudan_country'.tr(): [
      'khartoum_city'.tr(),
      'omedurman_city'.tr(),
      'port_sudan_city'.tr(),
      'kasala_city'.tr(),
      'wad_medani_city'.tr(),
    ],
    'libya_country'.tr(): [
      'tripoli_libya_city'.tr(),
      'benghazi_city'.tr(),
      'misrata_city'.tr(),
      ' Sabha_city'.tr(), // keep original spacing/formatting if present
      'derna_city'.tr(),
    ],
    'tunisia_country'.tr(): [
      'tunis_city'.tr(),
      'sfax_city'.tr(),
      'sousse_city'.tr(),
      'sfax_city_duplicate'.tr(),
      'gafsa_city'.tr(),
      'gabes_city'.tr(),
    ],
    'algeria_country'.tr(): [
      'algiers_city'.tr(),
      'oran_city'.tr(),
      'constantine_city'.tr(),
      'batna_city'.tr(),
      'setif_city'.tr(),
      'annaba_city'.tr(),
    ],
    'morocco_country'.tr(): [
      'rabat_city'.tr(),
      'casablanca_city'.tr(),
      'fes_city'.tr(),
      'marrakesh_city'.tr(),
      'tangier_city'.tr(),
      'agadir_city'.tr(),
    ],
    'mauritania_country'.tr(): [
      'nouakchott_city'.tr(),
      'nouadhibou_city'.tr(),
      'tidjikja_city'.tr(),
      'ross_o_city'.tr(),
    ],
    'somalia_country'.tr(): [
      'mogadishu_city'.tr(),
      'hargeisa_city'.tr(),
      'kismayo_city'.tr(),
    ],
    'djibouti_country'.tr(): ['djibouti_city'.tr()],
    'comoros_country'.tr(): ['moroni_city'.tr()],
    'palestine_country'.tr(): [
      'gaza_city'.tr(),
      'ramallah_city'.tr(),
      'hebron_city'.tr(),
      'nablus_city'.tr(),
      'tulkarm_city'.tr(),
    ],
  };

  // Dates
  DateTime? _issueDate;
  DateTime? _expiryDate;
  DateTime? _dob;

  // Image Selection State
  final ImagePicker _picker = ImagePicker();
  XFile? _idFrontImage;
  XFile? _idBackImage;
  XFile? _selfieImage;
  bool _isLoading = false;
  bool _isOCRProcessing = false;
  String? _rejectionReason;

  // Latin recognizer: reads digits, dates accurately
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  // Arabic recognizer: Default (Latin) as Arabic script constant is missing in this version
  final TextRecognizer _arabicRecognizer = TextRecognizer();

  @override
  void initState() {
    super.initState();
    _rejectionReason = widget.rejectionReason;
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoading = true);
    try {
      final user = await ApiService.getMe();
      if (!user.containsKey('error')) {
        setState(() {
          // Identity Fields
          _idNumberController.text = user['id_number'] ?? '';
          _issuerController.text = user['issuer'] ?? '';
          _placeOfBirthController.text = user['place_of_birth'] ?? '';
          _selectedIdType = user['id_type'] ?? 'بطاقة شخصية';
          _selectedNationality = user['nationality'] ?? 'يمني';

          // Address Fields
          _selectedCountry = user['country'] ?? 'اليمن';
          _selectedCity = user['city'] ?? 'صنعاء';
          _districtController.text = user['district'] ?? '';
          _areaController.text = user['area'] ?? '';
          _addressController.text = user['address'] ?? '';

          // Dates
          if (user['issue_date'] != null) {
            _issueDate = DateTime.tryParse(user['issue_date']);
            if (_issueDate != null) {
              _issueDateController.text = user['issue_date'];
            }
          }
          if (user['expiry_date'] != null) {
            _expiryDate = DateTime.tryParse(user['expiry_date']);
            if (_expiryDate != null) {
              _expiryDateController.text = user['expiry_date'];
            }
          }
          if (user['date_of_birth'] != null) {
            _dob = DateTime.tryParse(user['date_of_birth']);
            if (_dob != null) {
              _dobController.text = user['date_of_birth'];
            }
          }
        });
      }
    } catch (e) {
      customPrint('Error loading existing data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _arabicRecognizer.close();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final labels = {
      'front': 'id_front_label'.tr(),
      'back': 'id_back_label'.tr(),
      'selfie': 'selfie_with_id_label'.tr(),
    };

    final bool isSelfie = type == 'selfie';

    // For selfie, show special dialog with instructions
    if (isSelfie) {
      final bool? takeSelfie = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildSelfieDialog(context),
      );

      if (takeSelfie != true) return;

      // Open camera with front facing for selfie
      try {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1500,
          maxHeight: 1500,
          preferredCameraDevice: CameraDevice.front,
        );

        if (image != null) {
          setState(() => _selfieImage = image);
        }
      } catch (e) {
        customPrint('Error taking selfie: $e');
      }
      return;
    }

    // For ID front/back, show standard image source dialog
    final source = await showDialog<ImageSource>(
      context: context,
      builder:
          (context) => _buildImageSourceDialog(context, labels[type] ?? ''),
    );
    if (!mounted) return;

    if (source == null) return;

    try {
      XFile? image;

      if (source == ImageSource.camera) {
        // Use custom camera with card frame overlay for ID cards
        final path = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder:
                (_) =>
                    IdCameraScreen(title: labels[type] ?? 'capture_title'.tr()),
            fullscreenDialog: true,
          ),
        );
        if (path != null) image = XFile(path);
      } else {
        image = await _picker.pickImage(
          source: source,
          imageQuality: 70,
          maxWidth: 1200,
          maxHeight: 1200,
        );
      }

      if (image != null) {
        setState(() {
          if (type == 'front') _idFrontImage = image;
          if (type == 'back') _idBackImage = image;
        });

        // Start OCR processing for front and back images
        if (type == 'front' || type == 'back') {
          await _processImageForOCR(image, type);
        }
      }
    } catch (e) {
      customPrint('Error picking image: $e');
    }
  }

  // Premium Selfie Dialog with improved design
  Widget _buildSelfieDialog(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue,
                    AppColors.primaryBlue.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_front_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'selfie_instruction_title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Example image container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryBlue.withValues(alpha: 0.1),
                          AppColors.accentBlue.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/pers.png',
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Instructions text
                  Text(
                    'selfie_instruction_desc'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          widget.isDarkMode ? Colors.white70 : Colors.black87,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tips list
                  _buildTipItem(
                    Icons.lightbulb_outline,
                    'good_lighting_tip'.tr(),
                  ),
                  _buildTipItem(
                    Icons.visibility_off_outlined,
                    'no_coverings_tip'.tr(),
                  ),
                  _buildTipItem(Icons.credit_card, 'hold_card_tip'.tr()),
                ],
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            widget.isDarkMode
                                ? Colors.white70
                                : Colors.grey[700],
                        side: BorderSide(
                          color:
                              widget.isDarkMode
                                  ? Colors.white24
                                  : Colors.grey[300]!,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'take_selfie_button'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white60 : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Standard Image Source Dialog for ID cards
  Widget _buildImageSourceDialog(BuildContext context, String label) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'choose_image_for'.tr(args: [label]),
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    Icons.camera_alt_rounded,
                    'camera_option'.tr(),
                    AppColors.primaryBlue,
                    () => Navigator.pop(context, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    Icons.photo_library_rounded,
                    'gallery_option'.tr(),
                    AppColors.accentBlue,
                    () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processImageForOCR(XFile image, String side) async {
    setState(() => _isOCRProcessing = true);

    try {
      final inputImage = InputImage.fromFilePath(image.path);

      // Run both recognizers in parallel
      final results = await Future.wait([
        _textRecognizer.processImage(inputImage), // Latin (digits/dates)
        _arabicRecognizer.processImage(inputImage), // Default (Arabic text)
      ]);

      final RecognizedText latinResult = results[0];
      final RecognizedText arabicResult = results[1];

      String fullText = latinResult.blocks.map((b) => b.text).join('\n');
      String arabicText = arabicResult.blocks.map((b) => b.text).join('\n');

      customPrint('=== OCR LATIN ($side) ===\n$fullText\n===');
      customPrint('=== OCR ARABIC ($side) ===\n$arabicText\n===');

      // Numeric patterns
      final idPattern = RegExp(r'\b(0\d{10})\b');
      final datePattern = RegExp(
        r'(\d{1,4})\s*[./\-]\s*(\d{1,2})\s*[./\-]\s*(\d{1,4})',
      );

      // Arabic keyword patterns for issuer and place of birth
      // جهة الإصدار: يسبقها كلمة "مركز" أو "مديرية" أو "دائرة" أو "الأحوال المدنية"
      final issuerPattern = RegExp(
        r'(مركز|مديرية|دائرة|مكتب|الأحوال\s+المدنية)[^\n]*',
        unicode: true,
      );
      // مكان الميلاد: عادةً سطر عربي بعد التاريخ أو يحتوي مدينة/محافظة يمنية
      final yemenPlaces = [
        'amanat_al_asimah_place'.tr(),
        'sanaa_place'.tr(),
        'aden_place'.tr(),
        'taiz_place'.tr(),
        'hodeidah_place'.tr(),
        'ibb_place'.tr(),
        'hadramout_place'.tr(),
        'lahj_place'.tr(),
        'abyan_place'.tr(),
        'shabwa_place'.tr(),
        'albayda_place'.tr(),
        'marib_place'.tr(),
        'aljawf_place'.tr(),
        'amran_place'.tr(),
        'hajjah_place'.tr(),
        'saada_place'.tr(),
        'almahweet_place'.tr(),
        'dhammar_place'.tr(),
        'raymah_place'.tr(),
        'socotra_place'.tr(),
        'almahra_place'.tr(),
        'aldhale_place'.tr(),
        'radaa_place'.tr(),
        'dhibin_place'.tr(),
        'bani_hashish_place'.tr(),
        'hamdan_place'.tr(),
        'cairo_place'.tr(),
        'almokha_place'.tr(),
        'zabid_place'.tr(),
        'yarim_place'.tr(),
        'seiyun_place'.tr(),
        'tarim_place'.tr(),
        'alshahr_place'.tr(),
      ];

      if (side == 'front') {
        // 1. ID number (Latin)
        final idMatch = idPattern.firstMatch(fullText);
        if (idMatch != null) {
          setState(() => _idNumberController.text = idMatch.group(1)!);
          customPrint('✅ ID: ${idMatch.group(1)}');
        }

        // 2. Birth Date ── search ALL available text with flexible patterns
        // The date on Yemeni ID front appears as: "امانة العاصمة - التحرير - 2004/07/22"
        // We look for both YYYY/MM/DD and DD/MM/YYYY to handle OCR interpretation variances.
        // We allow optional spaces around separators.
        final dobRegex = RegExp(
          r'(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})|(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})',
        );
        final combinedForDob = '$fullText\n$arabicText';
        DateTime? dobCandidate;

        // Special check for lines containing Yemeni Place names + Date
        for (final line in combinedForDob.split('\n')) {
          final trimmed = line.trim();
          bool hasYemenPlace = yemenPlaces.any((p) => trimmed.contains(p));
          final match = dobRegex.firstMatch(trimmed);

          if (match != null) {
            try {
              int y, mo, d;
              if (match.group(1) != null) {
                // YYYY/MM/DD
                y = int.parse(match.group(1)!);
                mo = int.parse(match.group(2)!);
                d = int.parse(match.group(3)!);
              } else {
                // DD/MM/YYYY
                d = int.parse(match.group(4)!);
                mo = int.parse(match.group(5)!);
                y = int.parse(match.group(6)!);
              }

              if (y >= 1940 &&
                  y <= 2012 &&
                  mo >= 1 &&
                  mo <= 12 &&
                  d >= 1 &&
                  d <= 31) {
                final candidate = DateTime(y, mo, d);
                // If it has a Yemen place in the same line, it's highly likely the DOB
                if (hasYemenPlace) {
                  dobCandidate = candidate;
                  break;
                }
                dobCandidate ??= candidate;
              }
            } catch (_) {}
          }
        }

        if (dobCandidate != null) {
          setState(() {
            _dob = dobCandidate;
            _dobController.text =
                "${dobCandidate!.year}-${dobCandidate.month.toString().padLeft(2, '0')}-${dobCandidate.day.toString().padLeft(2, '0')}";
          });
          customPrint('✅ DOB Found: $dobCandidate');
        } else {
          customPrint('⚠️ No valid DOB candidate found in front scan');
        }

        // 3. Place of birth (Arabic)
        if (_placeOfBirthController.text.isEmpty) {
          String? bestPlace;
          // Look for Yemen city names in arabicText
          for (final line in arabicText.split('\n')) {
            final trimmed = line.trim();
            final containsCity = yemenPlaces.any(
              (city) => trimmed.contains(city),
            );
            if (containsCity) {
              bestPlace = trimmed;
              break;
            }
          }
          for (final line in arabicText.split('\n')) {
            final trimmed = line.trim();
            // Check if any known Yemen place name is in this line
            final containsCity = yemenPlaces.any(
              (city) => trimmed.contains(city),
            );

            if (containsCity) {
              bestPlace = trimmed;
              break;
            }
          }

          // Fallback: any Arabic-dominant line that is 3-30 chars (not a number)
          if (bestPlace == null) {
            for (final line in arabicText.split('\n')) {
              final trimmed = line.trim();
              if (trimmed.length >= 3 &&
                  trimmed.length <= 30 &&
                  RegExp(r'[\u0600-\u06FF]').hasMatch(trimmed) &&
                  !RegExp(r'^\d+$').hasMatch(trimmed)) {
                bestPlace = trimmed;
                break;
              }
            }
          }

          if (bestPlace != null) {
            // Remove any detected dates from the place of birth string
            String cleanedPlace = bestPlace.replaceAll(dobRegex, '').trim();
            // Remove dashes or extra spaces from ends
            cleanedPlace =
                cleanedPlace
                    .replaceAll(RegExp(r'^[\s\-]+|[\s\-]+$'), '')
                    .trim();

            if (cleanedPlace.isNotEmpty) {
              setState(() => _placeOfBirthController.text = cleanedPlace);
              customPrint('✅ Place of Birth cleaned: $cleanedPlace');
            }
          }
        }
      } else if (side == 'back') {
        // 1. Issue & Expiry Dates (Latin)
        final allDates = datePattern.allMatches(fullText).toList();
        List<DateTime> validDates = [];

        for (final m in allDates) {
          try {
            int g1 = int.parse(m.group(1)!);
            int g2 = int.parse(m.group(2)!);
            int g3 = int.parse(m.group(3)!);

            int? y, mo, d;
            if (g1 > 1950 && g1 < 2050) {
              y = g1;
              mo = g2;
              d = g3;
            } else if (g3 > 1950 && g3 < 2050) {
              y = g3;
              mo = g2;
              d = g1;
            }

            if (y != null && mo! >= 1 && mo <= 12 && d! >= 1 && d <= 31) {
              validDates.add(DateTime(y, mo, d));
            }
          } catch (_) {}
        }

        if (validDates.isNotEmpty) {
          validDates.sort();

          if (validDates.length >= 2) {
            setState(() {
              _issueDate = validDates.first;
              _expiryDate =
                  validDates.last.isAfter(validDates.first)
                      ? validDates.last
                      : DateTime(
                        validDates.first.year + 10,
                        validDates.first.month,
                        validDates.first.day,
                      );
              _issueDateController.text =
                  "${_issueDate!.year}-${_issueDate!.month.toString().padLeft(2, '0')}-${_issueDate!.day.toString().padLeft(2, '0')}";
              _expiryDateController.text =
                  "${_expiryDate!.year}-${_expiryDate!.month.toString().padLeft(2, '0')}-${_expiryDate!.day.toString().padLeft(2, '0')}";
            });
            customPrint('✅ Issue: $_issueDate  Expiry: $_expiryDate');
          } else {
            setState(() {
              _issueDate = validDates.first;
              _expiryDate = DateTime(
                validDates.first.year + 10,
                validDates.first.month,
                validDates.first.day - 1,
              );
              _issueDateController.text =
                  "${_issueDate!.year}-${_issueDate!.month.toString().padLeft(2, '0')}-${_issueDate!.day.toString().padLeft(2, '0')}";
              _expiryDateController.text =
                  "${_expiryDate!.year}-${_expiryDate!.month.toString().padLeft(2, '0')}-${_expiryDate!.day.toString().padLeft(2, '0')}";
            });
            customPrint('✅ Issue only: $_issueDate — expiry auto-calculated');
          }
        }

        // 2. Issuer (Arabic) — مركز / مديرية / دائرة
        if (_issuerController.text.isEmpty) {
          final issuerMatch = issuerPattern.firstMatch(arabicText);
          if (issuerMatch != null) {
            setState(
              () => _issuerController.text = issuerMatch.group(0)!.trim(),
            );
            customPrint('✅ Issuer (pattern): ${issuerMatch.group(0)}');
          } else {
            // Fallback: look for "مركز" in any line
            for (final line in arabicText.split('\n')) {
              final trimmed = line.trim();
              if (trimmed.contains('مركز') || trimmed.contains('مديرية')) {
                setState(() => _issuerController.text = trimmed);
                customPrint('✅ Issuer (fallback): $trimmed');
                break;
              }
            }
          }
        }

        // 3. ID from barcode on back (Latin)
        final idMatch = idPattern.firstMatch(fullText);
        if (idMatch != null && _idNumberController.text.isEmpty) {
          setState(() => _idNumberController.text = idMatch.group(1)!);
          customPrint('✅ ID from back: ${idMatch.group(1)}');
        }
      }
      // No SnackBar — user can see fields filled automatically
    } catch (e) {
      customPrint('OCR Error: $e');
      // SnackBar hidden by user request
    } finally {
      if (mounted) setState(() => _isOCRProcessing = false);
    }
  }

  // Removed _uploadImages as its logic is now consolidated in _handleSubmit

  void _handleSubmit({bool onlyImages = false}) async {
    if (_isLoading) return;

    final Map<String, dynamic> kycData = {};

    if (!onlyImages) {
      // 1. Validate Form Fields
      if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى تصحيح الأخطاء في الحقول المميزة باللون الأحمر'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // 2. Parse Dates from controllers (Safe parsing)
      DateTime? dob = DateTime.tryParse(_dobController.text);
      DateTime? issue = DateTime.tryParse(_issueDateController.text);
      DateTime? expiry = DateTime.tryParse(_expiryDateController.text);

      if (dob == null || issue == null || expiry == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى التأكد من صحة التواريخ المدخلة (YYYY-MM-DD)'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // 3. Logic Validation (Expiry > Issue)
      if (expiry.isBefore(issue)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تاريخ الانتهاء لا يمكن أن يكون قبل تاريخ الإصدار'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Map dates to ISO string
      String dateStr(DateTime d) => d.toIso8601String().split('T')[0];

      kycData.addAll({
        'id_type': _selectedIdType,
        'id_number': _idNumberController.text,
        'issuer': _issuerController.text,
        'nationality': _selectedNationality,
        'place_of_birth': _placeOfBirthController.text,
        'date_of_birth': dateStr(dob),
        'issue_date': dateStr(issue),
        'expiry_date': dateStr(expiry),
        'city': _selectedCity,
        'district': _districtController.text,
        'area': _areaController.text,
        'address': _addressController.text,
      });
    }

    setState(() => _isLoading = true);

    try {
      // Collect Images
      if (_idFrontImage != null) {
        kycData['id_front_bytes'] = await _idFrontImage!.readAsBytes();
        kycData['id_front_path'] = _idFrontImage!.path;
      }
      if (_idBackImage != null) {
        kycData['id_back_bytes'] = await _idBackImage!.readAsBytes();
        kycData['id_back_path'] = _idBackImage!.path;
      }
      if (_selfieImage != null) {
        kycData['selfie_bytes'] = await _selfieImage!.readAsBytes();
        kycData['selfie_path'] = _selfieImage!.path;
      }

      final Map<String, dynamic> result = await ApiService.submitKYC(kycData);

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success'] == true) {
          _showSuccessDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['error'] ?? 'فشل إرسال الطلب. يرجى المحاولة لاحقاً.',
                style: const TextStyle(),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _validateFormAndContinue() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تصحيح الأخطاء في الحقول المميزة باللون الأحمر'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Basic date validation
    DateTime? dob = DateTime.tryParse(_dobController.text);
    DateTime? issue = DateTime.tryParse(_issueDateController.text);
    DateTime? expiry = DateTime.tryParse(_expiryDateController.text);

    if (dob == null || issue == null || expiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى التأكد من صحة التواريخ المدخلة (YYYY-MM-DD)'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
    setState(() => _currentStep = 2);
  }

  void _validateImagesAndSubmit() {
    if (_idFrontImage == null || _idBackImage == null || _selfieImage == null) {
      String missing = '';
      if (_idFrontImage == null) missing += 'id_front_label'.tr();
      if (_idBackImage == null) missing += 'id_back_label'.tr();
      if (_selfieImage == null) missing += 'selfie_with_id_label'.tr();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى إكمال جميع الصور: $missing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    _handleSubmit();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : AppColors.textBlack;

    return Scaffold(
      backgroundColor:
          widget.isDarkMode ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      body: Stack(
        children: [
          _buildPremiumBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildPremiumHeader('account_confirmation_title'.tr(), () {
                  if (_currentStep == 2) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.ease,
                    );
                    setState(() => _currentStep = 1);
                  } else {
                    Navigator.pop(context);
                  }
                }).animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0),
                if (_currentStep == 1)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 5,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accentBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: AppColors.accentBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'auto_fill_instruction'.tr(),
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade().slideX(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildFormStep(textColor),
                      _buildImageStep(textColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isOCRProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    Text(
                      'ocr_processing_message'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentBlue.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(String title, VoidCallback onBack) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.isDarkMode ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
                  size: 18,
                ),
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : AppColors.textBlack,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ================= STEP 2: Personal Data =================
  Widget _buildFormStep(Color textColor) {
    final cardColor = widget.isDarkMode ? AppColors.cardDark : Colors.white;
    final borderColor = widget.isDarkMode ? Colors.white12 : Colors.black12;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'step_final_title'.tr(),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'step_final_subtitle'.tr(),
                    style: TextStyle(
                      // ignore: deprecated_member_use
                      color: textColor.withValues(alpha: 0.6),
                      fontSize: 13,

                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'step_counter_1_2'.tr(),
                  style: TextStyle(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          // Rejection reason box — shown immediately when data was rejected
          if (_rejectionReason != null && _rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? const Color(0xFF2A1B1B) : const Color(0xFFFDE8E8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isDarkMode
                      ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                      : const Color(0xFFF8B4B4),
                  width: 1.5,
                ),
              ),
              child: Text(
                _rejectionReason!,
                style: TextStyle(
                  color: widget.isDarkMode ? const Color(0xFFF87171) : const Color(0xFFC81E1E),
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          // ── Identity Section Card ──
          // ── Combined Form Sections ──
          Form(
            key: _formKey,
            child: Column(
              children: [
                _buildSectionCard(
                  icon: Icons.badge_rounded,
                  iconColor: const Color(0xFF1A56DB),
                  title: 'identity_section_title'.tr(),
                  textColor: textColor,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  children: [
                    _buildDropdown(
                      'id_type_label'.tr(),
                      ['id_option_id_card'.tr(), 'id_option_passport'.tr()],
                      _selectedIdType,
                      (v) => setState(() => _selectedIdType = v!),
                      cardColor,
                      borderColor,
                      textColor,
                    ),
                    _buildDropdown(
                      'nationality_label'.tr(),
                      [
                        'nationality_option_yemeni'.tr(),
                        'nationality_option_non_yemeni'.tr(),
                      ],
                      _selectedNationality,
                      (v) => setState(() => _selectedNationality = v!),
                      cardColor,
                      borderColor,
                      textColor,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: _buildTextField(
                        'id_number_label'.tr(),
                        _idNumberController,
                        cardColor,
                        borderColor,
                        textColor,
                        hint: 'id_number_hint'.tr(),
                        maxLength: 11,
                        keyboardType: TextInputType.number,
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: AppColors.primaryBlue,
                          ),
                          onPressed: () async {
                            final result = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => QRScannerScreen(
                                      isDarkMode: widget.isDarkMode,
                                      mode: ScannerMode.barcode,
                                    ),
                              ),
                            );
                            if (result != null && result.isNotEmpty) {
                              setState(() {
                                _idNumberController.text = result;
                              });
                            }
                          },
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'id_number_required'.tr();
                          }
                          if (v.length != 11) {
                            return 'id_number_length_error'.tr();
                          }
                          return null;
                        },
                      ),
                    ),
                    _buildTextField(
                      'issuer_label'.tr(),
                      _issuerController,
                      cardColor,
                      borderColor,
                      textColor,
                      hint: 'issuer_hint'.tr(),
                      validator:
                          (v) =>
                              (v == null || v.isEmpty)
                                  ? 'issuer_required'.tr()
                                  : null,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            'issue_date_label'.tr(),
                            _issueDateController,
                            (d) {
                              setState(() {
                                _issueDate = d;
                                _issueDateController.text =
                                    "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
                                // Auto-set expiry to 10 years later
                                _expiryDate = DateTime(
                                  d.year + 10,
                                  d.month,
                                  d.day - 1,
                                );
                                _expiryDateController.text =
                                    "${_expiryDate!.year}-${_expiryDate!.month.toString().padLeft(2, '0')}-${_expiryDate!.day.toString().padLeft(2, '0')}";
                              });
                            },
                            cardColor,
                            borderColor,
                            textColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateField(
                            'expiry_date_label'.tr(),
                            _expiryDateController,
                            (d) {
                              setState(() {
                                _expiryDate = d;
                                _expiryDateController.text =
                                    "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
                              });
                            },
                            cardColor,
                            borderColor,
                            textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'place_of_birth_label'.tr(),
                            _placeOfBirthController,
                            cardColor,
                            borderColor,
                            textColor,
                            hint: 'place_of_birth_hint'.tr(),
                            validator:
                                (v) =>
                                    (v == null || v.isEmpty)
                                        ? 'place_of_birth_required'.tr()
                                        : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateField(
                            'dob_label'.tr(),
                            _dobController,
                            (d) {
                              setState(() {
                                _dob = d;
                                _dobController.text =
                                    "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
                              });
                            },
                            cardColor,
                            borderColor,
                            textColor,
                            initialDate: DateTime(2000),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionCard(
                  icon: Icons.home_rounded,
                  iconColor: const Color(0xFF0E9F6E),
                  title: 'residence_section_title'.tr(),
                  textColor: textColor,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  children: [
                    _buildDropdown(
                      'country_label'.tr(),
                      _arabCountries.keys.toList().map((k) => k).toList(),
                      _selectedCountry,
                      (v) => setState(() {
                        _selectedCountry = v!;
                        final govs = _arabCountries[v] ?? [];
                        _selectedCity =
                            govs.isNotEmpty ? govs.first : 'unspecified'.tr();
                      }),
                      cardColor,
                      borderColor,
                      textColor,
                    ),
                    _buildDropdown(
                      'city_label'.tr(),
                      _arabCountries[_selectedCountry] ?? ['unspecified'.tr()],
                      _selectedCity,
                      (v) => setState(() => _selectedCity = v!),
                      cardColor,
                      borderColor,
                      textColor,
                    ),
                    _buildTextField(
                      'district_label'.tr(),
                      _districtController,
                      cardColor,
                      borderColor,
                      textColor,
                      hint: 'district_hint'.tr(),
                      validator:
                          (v) =>
                              (v == null || v.isEmpty)
                                  ? 'district_required'.tr()
                                  : null,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      'area_label'.tr(),
                      _areaController,
                      cardColor,
                      borderColor,
                      textColor,
                      hint: 'area_hint'.tr(),
                      validator:
                          (v) =>
                              (v == null || v.isEmpty)
                                  ? 'area_required'.tr()
                                  : null,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      'address_label'.tr(),
                      _addressController,
                      cardColor,
                      borderColor,
                      textColor,
                      hint: 'address_hint'.tr(),
                      validator:
                          (v) =>
                              (v == null || v.isEmpty)
                                  ? 'address_required'.tr()
                                  : null,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _validateFormAndContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        'continue_button'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 15),

          // Back Button
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                );
                setState(() => _currentStep = 1);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: widget.isDarkMode ? Colors.white24 : Colors.black12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'back_button'.tr(),
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  /// Premium section card with colored icon header
  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color textColor,
    required Color cardColor,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withValues(alpha: 0.12),
                  iconColor.withValues(alpha: 0.03),
                ],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // ================= STEP 1: Images Upload & Confirmation =================
  Widget _buildImageStep(Color textColor) {
    final cardColor = widget.isDarkMode ? AppColors.cardDark : Colors.white;
    final borderColor = widget.isDarkMode ? Colors.white12 : Colors.black12;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'step_first_title'.tr(),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'step_first_subtitle'.tr(),
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.6),
                      fontSize: 13,

                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'step_counter_2_2'.tr(),
                  style: TextStyle(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // ID Images
          Text(
            'id_images_title'.tr(),
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildRefinedUploadCard(
                  'id_front_card_title'.tr(),
                  Icons.badge_outlined,
                  _idFrontImage,
                  () => _pickImage('front'),
                  cardColor,
                  borderColor,
                  textColor,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildRefinedUploadCard(
                  'id_back_card_title'.tr(),
                  Icons.featured_video_outlined,
                  _idBackImage,
                  () => _pickImage('back'),
                  cardColor,
                  borderColor,
                  textColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Selfie
          Text(
            'selfie_title'.tr(),
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'selfie_note'.tr(),
            style: TextStyle(
              color: textColor.withValues(alpha: 0.5),
              fontSize: 12,

              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _buildRefinedUploadCard(
            'selfie_card_title'.tr(),
            Icons.camera_front_outlined,
            _selfieImage,
            // ()=> SelfieDialog.show(context,
            // 'قم بالتقاط صورة سيلفي وانت رافع بطاقتك تحت الذقن كما هو موضح في النموذج وفي مكان تتوفر فيه إضاءة جيدة وعدم وجود غطاء (شال - قبعة - نظارة)',
            //  'assets/images/pers.png',
            //   'choose_image_source'.tr(),
            //    'camera_option'.tr(),
            //     () => Navigator.pop(context, ImageSource.gallery),
            //     () => Navigator.pop(context, ImageSource.camera)),
            () => _pickImage('selfie'),
            cardColor,
            borderColor,
            textColor,
            isWide: true,
          ),

          const SizedBox(height: 40),

          // Next Button
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _validateImagesAndSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        'confirm_account_button'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),

          if (widget.isUpdating) ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed:
                    _isLoading ? null : () => _handleSubmit(onlyImages: true),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          'update_images_only_button'.tr(),
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildRefinedUploadCard(
    String label,
    IconData icon,
    XFile? image,
    VoidCallback onTap,
    Color bgColor,
    Color borderColor,
    Color textColor, {
    bool isWide = false,
  }) {
    final isSelected = image != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: isWide ? 150 : 120,
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (image != null)
                kIsWeb
                    ? Image.network(
                      image.path,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    )
                    : Image.network(
                      image.path,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Icon(Icons.broken_image),
                    ),
              if (isSelected)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 40,
                    )
                  else
                    Icon(
                      icon,
                      color: textColor.withValues(alpha: 0.5),
                      size: 35,
                    ),
                  const SizedBox(height: 10),
                  Text(
                    isSelected ? 'selected_success'.tr() : label,
                    style: TextStyle(
                      color:
                          isSelected
                              ? Colors.white
                              : textColor.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Container الرئيسي للدايلوج
                Container(
                  margin: const EdgeInsets.only(top: 45),
                  padding: const EdgeInsets.only(
                    top: 65,
                    left: 24,
                    right: 24,
                    bottom: 28,
                  ),
                  decoration: BoxDecoration(
                    color:
                        widget.isDarkMode ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'طلبك تحت المراجعة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              widget.isDarkMode
                                  ? Colors.white
                                  : AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'سيتم تأكيد محفظتك في اقرب وقت',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.bold,
                          color:
                              widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // زر الرجوع للقائمة الرئيسية
                      InkWell(
                        onTap: () {
                          Navigator.pop(context); // إغلاق الدايلوج
                          Navigator.pop(context, false); // الرجوع للرئيسية
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            'الرجوع للقائمة الرئيسية',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // دائرة الشعار العائمة
                Positioned(
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color:
                          widget.isDarkMode
                              ? AppColors.scaffoldDark
                              : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        gradient: AppColors.logoGradientDay,
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage: AssetImage('logo_circle.png'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    Color bgColor,
    Color borderColor,
    Color textColor, {
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? hint,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: GoogleFonts.cairo(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: textColor.withValues(alpha: 0.3),
              fontSize: 12,
            ),
            filled: true,
            fillColor: bgColor,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            errorStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _showWheelDatePicker(
    String title,
    TextEditingController controller,
    Function(DateTime) onSelect, {
    DateTime? initialDate,
  }) {
    final firstDate = DateTime(1950);
    final lastDate = DateTime(2045);

    DateTime selectedDate =
        initialDate ??
        DateTime.tryParse(controller.text) ??
        DateTime(2000, 1, 1);
    // Ensure selected date is within bounds
    if (selectedDate.isBefore(firstDate)) selectedDate = firstDate;
    if (selectedDate.isAfter(lastDate)) selectedDate = lastDate;

    // Controllers
    final yearController = FixedExtentScrollController(
      initialItem: selectedDate.year - firstDate.year,
    );
    final monthController = FixedExtentScrollController(
      initialItem: selectedDate.month - 1,
    );
    final dayController = FixedExtentScrollController(
      initialItem: selectedDate.day - 1,
    );

    final dialogBg = widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
    final dialogTextColor =
        widget.isDarkMode ? Colors.white : AppColors.textBlack;
    final dialogSubTextColor =
        widget.isDarkMode ? Colors.white70 : Colors.black54;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with X
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color: dialogSubTextColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox.shrink(),
                        ],
                      ),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          color: dialogTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // The 3 Wheels
                      SizedBox(
                        height: 180,
                        child: Stack(
                          children: [
                            // Highlight overlay (Red border box)
                            Center(
                              child: Container(
                                height: 45,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.accentBlue,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                // Year
                                Expanded(
                                  flex: 2,
                                  child: _buildWheel(
                                    count: lastDate.year - firstDate.year + 1,
                                    controller: yearController,
                                    onChanged: (val) {
                                      final y = firstDate.year + val;
                                      final dCount = _daysInMonth(
                                        y,
                                        selectedDate.month,
                                      );
                                      if (selectedDate.day > dCount) {
                                        dayController.jumpToItem(dCount - 1);
                                      }
                                      setDialogState(
                                        () =>
                                            selectedDate = DateTime(
                                              y,
                                              selectedDate.month,
                                              selectedDate.day > dCount
                                                  ? dCount
                                                  : selectedDate.day,
                                            ),
                                      );
                                    },
                                    itemBuilder: (context, index) {
                                      final y = firstDate.year + index;
                                      final isSelected = selectedDate.year == y;
                                      return _buildWheelItem(
                                        y.toString(),
                                        isSelected,
                                        dialogSubTextColor,
                                      );
                                    },
                                  ),
                                ),
                                // Month
                                Expanded(
                                  flex: 1,
                                  child: _buildWheel(
                                    count: 12,
                                    controller: monthController,
                                    onChanged: (val) {
                                      final m = val + 1;
                                      final dCount = _daysInMonth(
                                        selectedDate.year,
                                        m,
                                      );
                                      if (selectedDate.day > dCount) {
                                        dayController.jumpToItem(dCount - 1);
                                      }
                                      setDialogState(
                                        () =>
                                            selectedDate = DateTime(
                                              selectedDate.year,
                                              m,
                                              selectedDate.day > dCount
                                                  ? dCount
                                                  : selectedDate.day,
                                            ),
                                      );
                                    },
                                    itemBuilder: (context, index) {
                                      final m = index + 1;
                                      final isSelected =
                                          selectedDate.month == m;
                                      return _buildWheelItem(
                                        m.toString(),
                                        isSelected,
                                        dialogSubTextColor,
                                      );
                                    },
                                  ),
                                ),
                                // Day
                                Expanded(
                                  flex: 1,
                                  child: _buildWheel(
                                    count: _daysInMonth(
                                      selectedDate.year,
                                      selectedDate.month,
                                    ),
                                    controller: dayController,
                                    onChanged: (val) {
                                      setDialogState(
                                        () =>
                                            selectedDate = DateTime(
                                              selectedDate.year,
                                              selectedDate.month,
                                              val + 1,
                                            ),
                                      );
                                    },
                                    itemBuilder: (context, index) {
                                      final d = index + 1;
                                      final isSelected = selectedDate.day == d;
                                      return _buildWheelItem(
                                        d.toString(),
                                        isSelected,
                                        dialogSubTextColor,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Big Blue Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            onSelect(selectedDate);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'حسنًا',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _daysInMonth(int year, int month) {
    if (month == 2) {
      if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) return 29;
      return 28;
    }
    const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[month - 1];
  }

  Widget _buildWheel({
    required int count,
    required FixedExtentScrollController controller,
    required ValueChanged<int> onChanged,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 40,
      perspective: 0.005,
      diameterRatio: 1.2,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: itemBuilder,
      ),
    );
  }

  Widget _buildWheelItem(String label, bool isSelected, Color subTextColor) {
    return Center(
      child: Text(
        label,
        style: GoogleFonts.cairo(
          color: isSelected ? AppColors.accentBlue : subTextColor,
          fontSize: isSelected ? 20 : 18,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildDateField(
    String label,
    TextEditingController controller,
    Function(DateTime) onSelect,
    Color bgColor,
    Color borderColor,
    Color textColor, {
    DateTime? initialDate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly:
              true, // Prevents manual keyboard typing to force wheel usage
          onTap: () {
            _showWheelDatePicker(
              label,
              controller,
              onSelect,
              initialDate: initialDate,
            );
          },
          validator: (v) {
            if (v == null || v.isEmpty) return 'field_required'.tr();
            final parts = v.split('-');
            if (parts.length != 3) return 'date_format_hint'.tr();
            try {
              DateTime.parse(v);
            } catch (e) {
              return 'invalid_date'.tr();
            }
            return null;
          },
          style: GoogleFonts.cairo(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: 'date_hint'.tr(),
            hintStyle: TextStyle(
              color: textColor.withValues(alpha: 0.2),
              fontSize: 12,
            ),
            filled: true,
            fillColor: bgColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
            suffixIcon: Icon(
              Icons.calendar_today_outlined,
              color: Colors.grey[600],
              size: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            errorStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String selected,
    Function(String?) onChanged,
    Color bgColor,
    Color borderColor,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: (items.contains(selected)) ? selected : items.first,
                isExpanded: true,
                dropdownColor: bgColor,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: textColor.withValues(alpha: 0.6),
                  size: 20,
                ),
                style: GoogleFonts.cairo(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                items:
                    items
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
