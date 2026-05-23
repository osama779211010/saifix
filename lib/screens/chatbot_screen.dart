import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';

class ChatBotScreen extends StatefulWidget {
  final bool isDarkMode;
  final String? userName;
  final String? userPhoneNumber;
  const ChatBotScreen({
    super.key,
    this.isDarkMode = false,
    this.userName,
    this.userPhoneNumber,
  });

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text':
          'أهلاً بك يا ${widget.userName ?? "نجم صيفي"}! ✨ وجهك المشرق يضيف رونقاً خاصاً للتطبيق اليوم.. كيف يمكنني أن أضع خدماتي بين يديك الكريمتين؟',
      'time': DateTime.now(),
    },
  ];

  void _sendMessage({String? customMessage}) {
    final text = customMessage ?? _messageController.text;
    if (text.trim().isEmpty) return;

    final userMessage = text;
    setState(() {
      _messages.add({
        'isUser': true,
        'text': userMessage,
        'time': DateTime.now(),
      });
      if (customMessage == null) _messageController.clear();
    });

    _scrollToBottom();

    // Simulate Bot Response
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': _getBotResponse(userMessage),
            'time': DateTime.now(),
          });
        });
        _scrollToBottom();
      }
    });
  }

  /// تطبيع النص العربي: يزيل الهمزات والتاء المربوطة والتشكيل
  /// حتى لا يفرّق البوت بين "أسامة" و"اسامه" و"اسامة"
  String _normalizeArabic(String text) {
    return text
        .toLowerCase()
        // توحيد الهمزات لألف بدون همزة
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        // التاء المربوطة → هاء
        .replaceAll('ة', 'ه')
        // الألف المقصورة → ياء
        .replaceAll('ى', 'ي')
        // حذف التشكيل (الحركات)
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        // حذف التطويل (الشده والمد)
        .replaceAll(RegExp(r'[\u0640]'), '');
  }

  String _getBotResponse(String message) {
    // ===== تطبيع النص قبل أي مطابقة =====
    message = _normalizeArabic(message);
    final name = widget.userName ?? "صديقي";
    final List<String> flatteryPrefixes = [
      'أهلاً بك يا أغلى الناس، $name.. تفضل طلبك:\n',
      'من عيوني يا $name، يسعدني خدمتك:\n',
      'يا هلا بالذوق كله، يا $name.. أبشر:\n',
      'حاضر ولبيه يا $name، هاك الجواب:\n',
      'أنت تطلب وإحنا ننفذ يا $name المتألق:\n',
      'يا صديقي الصدوق $name، تفضل:\n',
      'حياك الله يا نجم صيفي المضيء $name:\n',
      'مرحباً بك يا غالي على قلوبنا $name:\n',
      'تدلل يا $name، إليك ما طلبت:\n',
      'بكل حب وسرور يا $name، خذ طلبك:\n',
      'يا فخر صيفي يا $name، تفضل الإجابة:\n',
      'أهلاً بك يا وجه الخير $name، أبشر:\n',
      'يا حبيب الكل $name، من عيوني:\n',
      'تسلم ويدوم عزك يا $name، تفضل:\n',
    ];
    final String prefix =
        flatteryPrefixes[DateTime.now().millisecond % flatteryPrefixes.length];

    // ==================== ساعات الدوام والتواصل ====================
    if (message.contains('دوام') ||
        message.contains('وقت') ||
        message.contains('متى') ||
        message.contains('ساعه')) {
      return '$prefixنحن معك دائماً! تطبيق صيفي يعمل على مدار الساعة 24/7 لإتمام عملياتك المالية. أما فروعنا ووكلاؤنا فيعملون عادةً من الساعة 8 صباحاً وحتى 8 مساءً، وبعضهم يتواجد لساعات متأخرة لخدمتك في حالات الطوارئ. ⏰✨';
    }

    if (message.contains('تواصل') ||
        message.contains('رقم') ||
        message.contains('اتصل') ||
        message.contains('دعم') ||
        message.contains('فني') ||
        message.contains('مشكله') ||
        message.contains('مساعده') ||
        message.contains('شكوى')) {
      return '$prefixفريق الدعم الفني في صيفي جاهز لخدمتك في أي وقت! يمكنك التواصل معنا مباشرة عبر:\n• الرقم المجاني: 8000002\n• واتساب الدعم: 778555555\n• أو عبر مراسلتنا في صفحاتنا على مواقع التواصل. نحن هنا لنسمعك! 📞💬';
    }

    if (message.contains('من انت') || message.contains('انت من')) {
      return 'أنا رفيقك الذكي من "صيفي"، صُممت خصيصاً لأكون مساعدك المخلص والذكي في إدارة أموالك بكل سهولة وأمان.';
    }

    if (message.contains('كيف حالك') ||
        message.contains('اخبارك') ||
        message.contains('كيفك ') ||
        message.contains('شلونك')) {
      return 'بأفضل حال لأنني أتحدث معك يا $name المتألق! كيف يمكنني أن أجعل يومك أفضل اليوم؟';
    }

    if (message.contains('اهلا') ||
        message.contains('مرحبا') ||
        message.contains('سلام')) {
      return '$prefixيسعدني جداً تواجدي معك، أخبرني ماذا يدور في ذهنك؟';
    }

    if (widget.userName != null && message.contains(widget.userName!)) {
      return '$name.. أنت لست مجرد عميل لدينا، بل أنت شريك نجاحنا ونقدر جداً ثقتك واهتمامك بصيفي.';
    }

    if (message.contains('رصيد') ||
        message.contains('رصيدي') ||
        message.contains('بقية') ||
        message.contains('كم عندي') ||
        message.contains('المتبقي')) {
      return '$prefixلمعرفة رصيدك وتفاصيله بدقة، اتبع الخطوات التالية:\n1️⃣ من الشاشة الرئيسية اختر "الشحن والسداد "\n2️⃣ اختر "شحن الرصيد "\n3️⃣  ثم ادخل الرقم والخاص بك وستظهر لك كافه الحقول لاتمام العملية 💰✨';
    }

    if (message.contains('رقم') && message.contains('هات')) {
      return '$prefixرقم هاتفك المسجل هو: ${widget.userPhoneNumber ?? "غير متوفر حالياً"}.';
    }

    if (message.contains('رقم') && message.contains('بديل')) {
      return '$prefixالرقم البديل هو سر صيفي للحماية؛ يمنحك سرية تامة حيث يمكنك استلام الأموال دون كشف اسمك أو رقمك الحقيقي، لتكون عملياتك دائماً في أمان تام.';
    }

    final List<String> competitorWallets = [
      'كاش',
      'سبأكاش',
      'فلوسك',
      'المتكاملة',
      'جوالي',
      'ون كاش',
      'شامل موني',
      'ايزي',
      'جيب',
      'موبايل موني',
      'كريمي',
      'ام فلوس',
      'حاسب',
      'يمن والت',
    ];
    final List<String> competitorNetworks = [
      'النجم',
      'الامتياز',
      'الحزمي',
      'الشبكة اليمنية',
      'الأكوع',
      'اتش بي',
      'الحوشبي',
      'يمن اكسبرس',
      'البرق',
      'مال موني',
      'الهتار',
      'المميز',
      'العامري',
      'المحيط',
      'الناصر',
      'السريع',
      'ياه موني',
    ];

    // === كشف المنافسين بأساليب عامية متنوعة ===
    if ((message.contains('تعرف') ||
            message.contains('سمعت') ||
            message.contains('عارف')) &&
        competitorWallets.any((w) => message.contains(w))) {
      final wallet = competitorWallets.firstWhere((w) => message.contains(w));
      return 'نعم يا $name، أعرف "$wallet" جيداً.. ولكن بيننا وبينك، صيفي باي تتفوق عليها بالسرعة، الأمان، السرية وأقل العمولات. أنت مع الأفضل ؟😉';
    }
    if ((message.contains('كيف') ||
            message.contains('شلون') ||
            message.contains('رأيك') ||
            message.contains('ايش')) &&
        competitorWallets.any((w) => message.contains(w))) {
      return '$prefixهي خدمة من خدمات كثيرة، لكن لو جربت صيفي باي ستجد فرقاً رهيباً! الجمال، السرعة، والسرية التامة بالرقم البديل – هذا ما تجده في صيفي فقط 😊';
    }
    if ((message.contains('كيف') ||
            message.contains('شلون') ||
            message.contains('رأيك') ||
            message.contains('ايش')) &&
        competitorNetworks.any((n) => message.contains(n))) {
      final network = competitorNetworks.firstWhere((n) => message.contains(n));
      return '$prefixشبكة "$network" معروفة، ولكن صيفي كاش هي الشبكة الأسبق والأكثر انتشاراً في اليمن، بتاريخ عريق وثقة راسخة لا تزعزعها الرياح! 💪';
    }
    if ((message.contains('تعرف') ||
            message.contains('سمعت') ||
            message.contains('عارف')) &&
        competitorNetworks.any((n) => message.contains(n))) {
      final network = competitorNetworks.firstWhere((n) => message.contains(n));
      return 'نعم أعرف "$network"! ولكن اعرف إنك لما تجرب صيفي كاش لن تفكر بغيرها ، سرعة، أمان، وانتشار واسع يجعلك دائماً في المقدمة 🏆';
    }

    if (competitorWallets.any((w) => message.contains(w))) {
      return '$prefixصيفي باي هي المحفظة الأرقى والأكثر سرية في اليمن، نحن نقدم لك الأمان والسرعة التي تتجاوز التوقعات، متفوقين بفارق شاسع عن أي محفظة أخرى.';
    }

    if (competitorNetworks.any((n) => message.contains(n)) ||
        (message.contains('تحويل') && message.contains('حزمي'))) {
      return '$prefixصيفي كاش هي أول وأقوى وأقدم شبكة حوالات في اليمن، تاريخنا العريق يضمن لك الثقة والانتشار الأوسع والأمان المطلق الذي لا يضاهى.';
    }

    // ==================== الأمان والسرية ====================
    if (message.contains('امان') ||
        message.contains('حماي') ||
        message.contains('سري') ||
        message.contains('خصوصي') ||
        message.contains('حمايه') ||
        message.contains('مشفر') ||
        message.contains('امن') ||
        message.contains('تشفير')) {
      return '$prefixالأمان في صيفي لا يساوم عليه! نستخدم أحدث أنظمة التشفير لتكون أموالك وبياناتك في أمان تام، مع ميزة الرقم البديل للسرية المطلقة. 🔐';
    }

    // ==================== مميزات صيفي ====================
    if (message.contains('امتياز') ||
        message.contains('ميزه') ||
        message.contains('مميزات') ||
        message.contains('نقاط') ||
        message.contains('جوائز') ||
        message.contains('هدايا') ||
        message.contains('مكافات') ||
        message.contains('عروض') ||
        message.contains('افضل') ||
        message.contains('تميز') ||
        message.contains('ليش') ||
        message.contains('ليه') ||
        message.contains('لماذا') ||
        message.contains('لم') ||
        message.contains('سبب')) {
      return '$prefixصيفي يمنحك امتيازات مذهلة! نظام نقاط سخي، جوائز دورية، سحوبات كبرى، عمولات هي الأقل في اليمن، دعم فني VIP، وسرعة تنفيذ خارقة تجعل وقتك أثمن مع صيفي. 🏆';
    }

    // ==================== مواقع الوكلاء والفروع ====================
    if (message.contains('مبيعات') || message.contains('نقاط مبيعات')) {
      return '$prefixنقاط المبيعات هي المحلات والمراكز التي تقبل الدفع عبر صيفي! 🏪\n📍 للعثور عليها: اذهب إلى "حسابي" ← "نقاط الخدمة" أو استخدم خريطة الوكلاء.\n💳 للدفع فيها: استخدم "دفع المشتريات" أو امسح كود QR الخاص بالتاجر مباشرة من الشاشة الرئيسية. سرعة وأمان! ✨';
    }

    if (message.contains('وكلاء') ||
        message.contains('وكيل') ||
        message.contains('فروع') ||
        message.contains('فرع') ||
        message.contains('قريب') ||
        message.contains('اقرب') ||
        message.contains('مكان') ||
        message.contains('فين') ||
        message.contains('وين') ||
        message.contains('عنوان') ||
        message.contains('موقع') ||
        message.contains('احداثيات') ||
        message.contains('خريطه')) {
      return '$prefixوكلاؤنا منتشرون في كل مكان! اضغط على "نقاط الخدمة" في قسم حسابي أو زر شاشة "مواقع الوكلاء" من السحب النقدي لتجد أقرب وكيل إليك مع الخريطة ورقم الهاتف. 📍';
    }

    // ==================== التحويل لمشترك ====================
    if ((message.contains('تحويل') ||
            message.contains('احول') ||
            message.contains('أحول') ||
            message.contains('ابعت') ||
            message.contains('بعت') ||
            message.contains('ارسل') ||
            message.contains('أرسل') ||
            message.contains('اعطني') ||
            message.contains('حول')) &&
        (message.contains('مشترك') ||
            message.contains('شخص') ||
            message.contains('احد') ||
            message.contains('أحد') ||
            message.contains('واحد') ||
            message.contains('صديق') ||
            message.contains('صاحب') ||
            message.contains('زميل') ||
            message.contains('قريب') ||
            message.contains('اهل') ||
            message.contains('نمر') ||
            message.contains('رقم'))) {
      return '$prefixللتحويل إلى مشترك صيفي، اتبع الخطوات التالية:\n1️⃣ من الشاشة الرئيسية اختر "تحويلات مالية"\n2️⃣ اختر "التحويل إلى مشترك"\n3️⃣ أدخل رقم هاتف المشترك أو الرقم البديل الخاص به\n4️⃣ حدد العملة المراد تحويلها\n5️⃣ أدخل المبلغ والملاحظات (اختياري)\n6️⃣ اضغط على "تأكيد العملية" وسيتم التحويل فوراً! 💸';
    }
    if ((message.contains('تحويل') ||
            message.contains('احول') ||
            message.contains('أحول') ||
            message.contains('ابعت') ||
            message.contains('ارسل') ||
            message.contains('حول')) &&
        (message.contains('كيف') ||
            message.contains('طريقة') ||
            message.contains('خطوات') ||
            message.contains('شلون') ||
            message.contains('وين') ||
            message.contains('فين'))) {
      return '$prefixمن الشاشة الرئيسية، اختر "تحويلات مالية" ثم حدد نوع التحويل المناسب لك (مشترك، بنك، محفظة..).';
    }
    if (message.contains('تحويل') ||
        message.contains('احول') ||
        message.contains('أحول') ||
        message.contains('ابعت') ||
        message.contains('ارسل') ||
        message.contains('حول')) {
      return '$prefixاستخدم قسم "التحويلات المالية" من الشاشة الرئيسية. تشمل: مشترك صيفي، بنوك، محافظ، وشبكة صيفي كاش.';
    }

    // ==================== يمن موبايل ====================
    if (message.contains('يمن موبايل') ||
        message.contains('يمن موبيل') ||
        message.contains('يمن موب')) {
      if (message.contains('كيف') ||
          message.contains('طريقه') ||
          message.contains('شحن') ||
          message.contains('اشحن') ||
          message.contains('سداد')) {
        return '$prefixادخل قسم "يمن موبايل فوري" من الواجهة، أدخل الرقم والمبلغ واضغط شحن — فوري وبلا تعقيد! ✅';
      }
      return '$prefixخدمة يمن موبايل متوفرة في قسم "الشحن والسداد" من الرئيسية.';
    }

    // ==================== سبأفون ====================
    if (message.contains('سبأفون') ||
        message.contains('سبافون') ||
        message.contains('سباء')) {
      if (message.contains('شحن') ||
          message.contains('كيف') ||
          message.contains('طريقة')) {
        return '$prefixمن قسم "الشحن والسداد"، اختر "سبأفون"، أدخل الرقم والمبلغ ثم أكد. ⚡';
      }
      return '$prefixشحن سبأفون متاح من قسم "الشحن والسداد".';
    }
    // ==================== شبكة يو YOU ====================
    if (message.contains('باقات يو') ||
        message.contains('you') ||
        (message.contains('يو') &&
            (message.contains('باقة') ||
                message.contains('شحن') ||
                message.contains('نت')))) {
      return '$prefixمن قسم "الشحن والسداد"، اختر "YOU"، اختر الباقة المناسبة وأكد. فوري 100%. 📶';
    }

    // ==================== واي ====================
    if (message.contains('واي موبايل') ||
        message.contains('واي نت') ||
        (message.contains('واي') &&
            (message.contains('شحن') || message.contains('باقة')))) {
      return '$prefixشحن واي (Y) متاح من "الشحن والسداد"، اختر "واي"، أدخل الرقم والمبلغ. ⚡';
    }

    // ==================== إرسال واستلام الحوالات ====================
    if (message.contains('ارسل حواله') ||
        message.contains('بعت حواله') ||
        message.contains('رسلت حواله') ||
        message.contains('حول حواله') ||
        message.contains('حواله خارج') ||
        (message.contains('حواله') &&
            (message.contains('ارسال') ||
                message.contains('بعت') ||
                message.contains('تصدير')))) {
      return '$prefixلإرسال حوالة عبر شبكة محلية، اتبع الخطوات:\n1️⃣ من الشاشة الرئيسية اختر "حوالة شبكة محلية"\n2️⃣ اختر "إرسال حوالة"\n3️⃣ حدد الشبكة المطلوبة (مثل صيفي كاش)\n4️⃣ قم بتعبئة بيانات المستلم والمبلغ المطلوب\n5️⃣ اضغط "إرسال" وستصل الحوالة للمستلم في أسرع وقت! 📤';
    }

    if (message.contains('حاله حواله') ||
        message.contains('بحث عن حواله') ||
        message.contains('استعلم عن حواله') ||
        message.contains('مصير حواله') ||
        message.contains('اين الحواله') ||
        message.contains('وين الحواله') ||
        message.contains('الغاء حواله') ||
        message.contains('توقيف حواله') ||
        message.contains('استرجاع حواله') ||
        ((message.contains('استلام') ||
                message.contains('بحث') ||
                message.contains('حاله')) &&
            message.contains('حواله'))) {
      return '$prefixللبحث عن حالة حوالة، أو استلامها، أو إلغائها عبر الشبكة المحلية:\n1️⃣ من الرئيسية اختر "تحويلات مالية ثم حوالة شبكة محلية "\n2️⃣ اختر "حالة حوالة شبكة محلية" (أو استلام/إلغاء حسب رغبتك)\n3️⃣ أدخل رقم الحوالة المطلوب\n4️⃣ أكمل البيانات المطلوبة وسيظهر لك الرد فوراً! 📋';
    }

    if (message.contains('طلب استلام') ||
        message.contains('استلام حواله') ||
        message.contains('اصرف حواله') ||
        message.contains('قبض حواله')) {
      if (message.contains('محلي') || message.contains('شبكه')) {
        return '$prefixلتقديم طلب استلام حوالة محلية:\n1️⃣ من الرئيسية اختر "تحويلات مالية" ثم "طلب استلام حوالة"\n2️⃣ اختر "طلب استلام حوالة محلية"\n3️⃣ حدد الشبكة أو خدمة التحويل\n4️⃣ أدخل رقم الحوالة والملاحظات (اختياري)\n5️⃣ اضغط "تأكيد" وسيتم مراجعة طلبك والرد عليك في أقرب وقت ممكن! ✅';
      }
      return '$prefixلطلب استلام حوالة (محلية أو دولية)، اتبع الخطوات:\n1️⃣ من الشاشة الرئيسية اختر "تحويلات مالية"\n2️⃣ اختر "طلب استلام حوالة"\n3️⃣ حدد نوع الحوالة (محلية أو دولية) أو استعرض "تقرير طلبات الاستلام" لمتابعة طلباتك السابقة. 📥';
    }

    if (message.contains('حوالة') ||
        message.contains('هاوالة') ||
        message.contains('حواله')) {
      return '$prefixحالياً تتوفر شبكة "صيفي باي" و"صيفي كاش" للحوالات. إرسال، استلام، أم طلب استلام حوالة؟ أخبرني!';
    }

    // ==================== الإنترنت والهاتف الثابت ====================
    if ((message.contains('adsl') ||
            message.contains('ادسل') ||
            message.contains('ثابت') ||
            message.contains('هاتف ثابت') ||
            message.contains('خط ثابت')) &&
        (message.contains('سداد') ||
            message.contains('دفع') ||
            message.contains('كيف') ||
            message.contains('شحن'))) {
      return '$prefixمن قسم "الشحن والسداد "، اختر "هاتف ثابت" أو "ADSL إنترنت"، أدخل رقمك والاشتراك واضغط سداد. 🖥️';
    }
    if (message.contains('نت') ||
        message.contains('انترنت') ||
        message.contains('إنترنت') ||
        message.contains('اشتراك')) {
      return '$prefixسداد الإنترنت الثابت والمنزلي متاح من قسم "الشحن والسداد " في الرئيسية.';
    }

    // ==================== الباقات ====================
    if (message.contains('باقة') ||
        message.contains('باقات') ||
        message.contains('باقه') ||
        message.contains('اشتري باقة') ||
        message.contains('بيانات')) {
      if (message.contains('كيف') ||
          message.contains('تفعيل') ||
          message.contains('اشتري')) {
        return '$prefixتوجه لقسم "الشحن والسداد" ← "باقات"، استخدم خانة البحث وستجد جميع الباقات. اختر وأكد الشراء. 📦';
      }
      return '$prefixباقات الإنترنت والاتصال متوفرة من قسم "الشحن والسداد".';
    }

    // ==================== خدمات 4G ====================
    if (message.contains('4g') ||
        message.contains('فور جي') ||
        message.contains('فورجي') ||
        message.contains('مودم') ||
        message.contains('راوتر') ||
        message.contains('لت') ||
        message.contains('4 جي')) {
      if (message.contains('رصيد') ||
          message.contains('استعلام') ||
          message.contains('كم')) {
        return '$prefixيمكنك الاستعلام عن رصيد المودم أو الفورجي من قسم "الباقات" أو عبر خدمة "صيفي كاش". 📊';
      }
      if (message.contains('شحن') ||
          message.contains('اشحن') ||
          message.contains('تعبأ') ||
          message.contains('تعبة')) {
        return '$prefixمن قسم "الشحن والسداد " اختر "شحن 4G"، أدخل الرقم وحدد الباقة أو المبلغ وأكد. ⚡';
      }
      return '$prefixخدمات 4G (شحن + استعلام + باقات) متوفرة في قسم "الشحن والسداد" و"الباقات". 📡';
    }

    // ==================== سداد المشتريات ====================
    if (message.contains('مشتري') ||
        message.contains('اسدد') ||
        message.contains('سداد مشتري') ||
        message.contains('دفع مشتري') ||
        message.contains('ادفع مبلغ') ||
        message.contains('ادفع ثمن') ||
        (message.contains('سداد') &&
            (message.contains('شراء') ||
                message.contains('بضاعه') ||
                message.contains('فاتوره'))) ||
        (message.contains('دفع') &&
            (message.contains('شراء') ||
                message.contains('بضاعه') ||
                message.contains('ثمن')))) {
      return '$prefixلسداد مشترياتك بكل سهولة، اتبع هذه الخطوات في الواجهة:\n1️⃣ من الرئيسية اختر "دفع المشتريات"\n2️⃣ اختر طريقة الدفع: "وي نت WeNet" أو "صيفي باي"\n3️⃣ أدخل "رقم نقطة البيع" (POS ID) الخاص بالتاجر\n4️⃣ أدخل "المبلغ" و "الملاحظات" (اختياري)\n5️⃣ اضغط "تأكيد العملية" وسيتم الخصم فوراً وإشعار التاجر. 🛒💳';
    }

    // ==================== تقارير PDF والكشف المالي ====================
    if (message.contains('pdf') ||
        message.contains('بي دي اف') ||
        message.contains('تقرير') ||
        message.contains('كشف حساب') ||
        message.contains('كشف') ||
        message.contains('سجل') ||
        message.contains('عمليات') ||
        message.contains('سجلات') ||
        message.contains('history') ||
        message.contains('سجل مالي')) {
      return '$prefixلتصدير كشف حساب PDF، ادخل "السجل المالي" وفي الأعلى ستجد أيقونة ⬇️ لتحميل تقريرك فوراً. ';
    }

    // ==================== التسوق الإلكتروني ====================
    if (message.contains('تسوق') ||
        message.contains('امازون') ||
        message.contains('أمازون') ||
        message.contains('علي اكسبريس') ||
        message.contains('اونلاين') ||
        message.contains('أونلاين') ||
        message.contains('شراء اون') ||
        message.contains('متجر') ||
        message.contains('طلبية')) {
      return '$prefixخدمة "تسوّق أونلاين" تتيح لك الشراء من أمازون، علي إكسبريس، وغيرها. اختر المتجر، أضف الرابط أو المنتج وسنتولى الباقي بكل أمان. 🛍️';
    }

    // ==================== مصروف الجيب ====================
    if (message.contains('مصروف الجيب') ||
        message.contains('مصروف يومي') ||
        message.contains('ميزانية') ||
        message.contains('ميزانيتي') ||
        message.contains('انفاق') ||
        message.contains('إنفاق') ||
        message.contains('سقف')) {
      return '$prefixخدمة "مصروف الجيب" تتيح لك تحديد سقف إنفاق يومي وأسبوعي وإدارة ميزانيتك بذكاء. ابحث عنها في الإعدادات. 💰';
    }

    // ==================== إدارة الأجهزة ====================
    if (message.contains('جهاز') ||
        message.contains('أجهزة') ||
        message.contains('اجهزه') ||
        message.contains('هاتف اخر') ||
        message.contains('دخول غير') ||
        message.contains('منع دخول') ||
        (message.contains('ادارة') && !message.contains('ادارة الحساب'))) {
      return '$prefixمن "الحساب" في الأسفل، ادخل "إعدادات الأمان" ← "إدارة الأجهزة" لعرض ومنع أي جهاز غير مصرح به. 🔐';
    }

    // ==================== توثيق الحساب ====================
    if (message.contains('توثيق') ||
        message.contains('تحقق هويه') ||
        message.contains('هويه') ||
        message.contains('kyc') ||
        message.contains('رفع هويه') ||
        message.contains('بطاقه') ||
        message.contains('سقف عمليات') ||
        message.contains('رفع سقف') ||
        message.contains('توثيق حساب')) {
      return '$prefixلرفع سقف عملياتك، ادخل قسم "الحساب" ← "توثيق الحساب" وارفع صورة واضحة من الهوية الشخصية. ✅';
    }

    // ==================== الرصيد والحساب ====================
    if (message.contains('رصيد') ||
        message.contains('رصيدي') ||
        message.contains('فلوس') ||
        message.contains('فلوسي') ||
        message.contains('حسابي') ||
        message.contains('بقية') ||
        message.contains('كم عندي') ||
        message.contains('كم باقي') ||
        message.contains('المتبقي')) {
      return '$prefixبسيطة جداً! لمعرفة رصيدك وتفاصيله:\n1️⃣ من الشاشة الرئيسية  ستظهر لك عين بجانب الرصيد لإظهار الرصيد او الضغط على البطاقه في الاعلى نفسها  "\n2️⃣ اختر أيقونة " "\n✅ هناك ستجد كل تفاصيل أرصدتك بالريال، الدولار، والريال السعودي. 💵💹';
    }

    // ==================== السحب النقدي ====================
    if (message.contains('سحب') ||
        message.contains('نقد') ||
        message.contains('نقود') ||
        message.contains('استلم نقد') ||
        message.contains('صرف نقد') ||
        message.contains('سحب نقدي') ||
        message.contains('ساحب')) {
      return '$prefixمن الرئيسية اختر "طلب سحب نقدي"، حدد المبلغ والعملة وأقرب وكيل، وسيتم تجهيز الطلب فوراً. 💵';
    }

    // ==================== الرقم البديل ====================
    if (message.contains('رقم بديل') ||
        message.contains('الرقم البديل') ||
        message.contains('بديل') ||
        message.contains('رقم سري') ||
        message.contains('استلام بسر')) {
      return '$prefixالرقم البديل يمنحك سرية تامة — يمكن للآخرين إرسال المال إليك بدون معرفة رقمك أو اسمك الحقيقي. جد أيقونته في ملف حسابك. 🤫';
    }

    // ==================== كلمة السر والرمز ====================
    if (message.contains('كلمة السر') ||
        message.contains('رمز السر') ||
        message.contains('باسورد') ||
        message.contains('password') ||
        message.contains('غير رمز') ||
        message.contains('نسيت رمز') ||
        message.contains('نسيت كلمة') ||
        message.contains('تغيير رمز') ||
        (message.contains('رمز') && message.contains('سر'))) {
      return '$prefixلتغيير رمز الدخول، ادخل "الإعدادات" ← "الخصوصية والأمان" ← "تغيير كلمة السر". وإذا نسيتها اضغط "نسيت كلمة السر" في شاشة الدخول. 🔑';
    }

    // ==================== البصمة ووجه ====================
    if (message.contains('بصمة') ||
        message.contains('بصمه') ||
        message.contains('face id') ||
        message.contains('وجه') ||
        message.contains('بيومتري') ||
        message.contains('مسح وجه') ||
        message.contains('تفعيل بصمة')) {
      return '$prefixلتفعيل البصمة أو Face ID، ادخل "الإعدادات" ← "الخصوصية والأمان" ← "تفعيل البصمة". قبولها يجعل دخولك للتطبيق أسرع وأآمن. 👆';
    }

    // ==================== QR Code ====================
    if (message.contains('qr') ||
        message.contains('كيو ار') ||
        message.contains('كود qr') ||
        message.contains('مسح') ||
        message.contains('ماسح') ||
        message.contains('بار كود')) {
      return '$prefixاضغط أيقونة QR في صفحة الحساب لإظهار كودك الشخصي، أو استخدم ماسح QR في الرئيسية لدفع أو استلام بلمحة. 📲';
    }

    // ==================== المحفظة الرقمية - موضوعات شاملة ====================
    if ((message.contains('ما هي') ||
            message.contains('ما هو') ||
            message.contains('شو هي') ||
            message.contains('شو هو') ||
            message.contains('وش هي') ||
            message.contains('ايش هي') ||
            message.contains('يعني ايش') ||
            message.contains('يعني') ||
            message.contains('ما معني')) &&
        (message.contains('محفظه') ||
            message.contains('صيفي') ||
            message.contains('التطبيق') ||
            message.contains('البرنامج'))) {
      return '$prefixالمحفظة الرقمية هي حساب مالي إلكتروني آمن يُمكّنك من:\n💸 إرسال الأموال واستقبالها فورياً\n📱 شحن رصيد هاتفك وبياناتك\n🧾 الشحن والسداد  (كهرباء، مياه، إنترنت..)\n💱 مصارفة العملات بأفضل الأسعار\n🏧 سحب نقدي من أقرب وكيل\nكل هذا من هاتفك دون طوابير ودون مصرف تقليدي! 📱💰';
    }

    // كيف أفتح / أنشئ محفظة جديدة
    if ((message.contains('كيف') ||
            message.contains('طريقه') ||
            message.contains('اريد') ||
            message.contains('احتاج') ||
            message.contains('افتح') ||
            message.contains('فتح') ||
            message.contains('انشئ') ||
            message.contains('عمل')) &&
        (message.contains('محفظه') ||
            message.contains('حساب') ||
            message.contains('تسجيل') ||
            message.contains('اشتراك') ||
            message.contains('اسجل'))) {
      return '$prefixلفتح محفظة صيفي سهل جداً! 😊\n1️⃣ حمّل التطبيق من المتجر\n2️⃣ اضغط "تسجيل جديد"\n3️⃣ أدخل رقم هاتفك واسمك الكامل\n4️⃣ أدخل رمز التحقق الواصل لهاتفك\n5️⃣ اختر كلمة سر قوية\n✅ محفظتك جاهزة خلال دقيقتين فقط!';
    }

    // التوثيق / رفع الهوية / KYC
    if (message.contains('توثيق') ||
        message.contains('هويه') ||
        message.contains('بطاقه') ||
        message.contains('kyc') ||
        (message.contains('رفع') && message.contains('صوره')) ||
        (message.contains('رفع') && message.contains('هويه'))) {
      return '$prefixلتوثيق حسابك ورفع حدود التحويل:\n1️⃣ ادخل "حسابي" من الشريط السفلي\n2️⃣ اضغط "توثيق الهوية"\n3️⃣ ارفع صورة واضحة من الهوية الوطنية أو الجواز\n4️⃣ انتظر الموافقة (عادةً خلال 24 ساعة)\n🔐 التوثيق يرفع حدودك من 500 ألف إلى 5 مليون ريال يومياً!';
    }

    // إغلاق / إلغاء المحفظة
    if ((message.contains('اغلق') ||
            message.contains('الغي') ||
            message.contains('احذف') ||
            message.contains('اقفل') ||
            message.contains('حذف')) &&
        (message.contains('محفظه') || message.contains('حسابي'))) {
      return '$prefixلإغلاق محفظتك:\n📌 يرجى التأكد من إفراغ رصيدك أولاً\n📞 ثم تواصل مع خدمة العملاء:\n• واتساب: 778555555\n• الرقم المجاني: 8000002\nوسيتم تنفيذ الطلب فوراً 🤝';
    }

    // تجميد / حظر / قفل الحساب
    if (message.contains('مجمد') ||
        message.contains('محجوب') ||
        message.contains('مقفل') ||
        message.contains('موقوف') ||
        message.contains('محظور') ||
        message.contains('مسدود')) {
      return '$prefixإذا كان حسابك مجمداً أو محظوراً! 🚫\n🔹 تواصل فوراً مع خدمة العملاء:\n  • واتساب: 778555555\n  • الرقم المجاني: 8000002\n🔹 جهّز صورة هويتك لتسريع الإجراء\n🔹 عادةً تُحل المشكلة خلال ساعات قليلة ✅';
    }

    // نسيان كلمة السر
    if ((message.contains('نسيت') ||
            message.contains('ناسي') ||
            message.contains('فقدت')) &&
        (message.contains('رمز') ||
            message.contains('باسورد') ||
            message.contains('السر'))) {
      return '$prefixإذا نسيت كلمة السر لا تقلق! 😊\n1️⃣ في شاشة الدخول اضغط "نسيت كلمة السر"\n2️⃣ أدخل رقم هاتفك المسجل\n3️⃣ ستصلك رسالة رمز تحقق\n4️⃣ أدخل الرمز وأنشئ كلمة سر جديدة\n✅ الوصول لمحفظتك يعود فوراً! 🔑';
    }

    // الإيصال / وصل العملية
    if (message.contains('ايصال') ||
        message.contains('وصل') ||
        message.contains('اثبات تحويل') ||
        message.contains('screenshot') ||
        message.contains('سكرين شوت')) {
      return '$prefixلاستخراج إيصال العملية:\n1️⃣ ادخل "سجل العمليات" من الشاشة الرئيسية\n2️⃣ اضغط على العملية المطلوبة\n3️⃣ اضغط أيقونة المشاركة 📤\n✅ يمكنك مشاركة الإيصال مباشرة عبر واتساب أو حفظه كصورة!';
    }

    // تحويل خاطئ / استرداد الأموال
    if ((message.contains('حولت') ||
            message.contains('ارسلت') ||
            message.contains('دفعت')) &&
        (message.contains('غلط') ||
            message.contains('خطا') ||
            message.contains('بالغلط'))) {
      return '$prefixإذا أرسلت الأموال لحساب خاطئ، تصرف بسرعة! ⚡\n📱 واتساب خدمة العملاء: 778555555\n📞 الرقم المجاني: 8000002\n⚠️ كلما أسرعت زادت فرصة الاسترداد!\n📌 جهّز بيانات العملية (المبلغ، الرقم، الوقت)';
    }

    // الاستعلام عن وصول حوالة
    if ((message.contains('وصلت') ||
            message.contains('وصل') ||
            message.contains('تاكد') ||
            message.contains('استعلام')) &&
        (message.contains('حواله') ||
            message.contains('التحويل') ||
            message.contains('الفلوس'))) {
      return '$prefixلمتابعة أي عملية:\n1️⃣ ادخل "سجل العمليات" من الرئيسية\n2️⃣ ستجد حالة كل عملية:\n  ✅ ناجحة\n  ⏳ قيد المعالجة\n  ❌ فاشلة\n3️⃣ إذا لم تجد ما تبحث عنه تواصل معنا 📋';
    }

    // الحد الأقصى للتحويل اليومي
    if (message.contains('حد') ||
        message.contains('يومي') ||
        message.contains('سقف') ||
        message.contains('اعلى مبلغ')) {
      return '$prefixحدود التحويل اليومي في صيفي:\n🔹 حساب غير موثق: 500,000 ريال / يوم\n🔹 حساب موثق: 5,000,000 ريال / يوم\n🔹 الحد للتحويل الواحد: 2,000,000 ريال\n💡 وثّق حسابك لرفع الحدود ومضاعفة مميزاتك!';
    }

    // فوائد المحفظة
    if (message.contains('ليش') ||
        message.contains('مميزات صيفي') ||
        message.contains('ليه صيفي')) {
      return '$prefixفوائد محفظة صيفي لا تُحصى! 🌟\n✅ تحويلات فورية 24/7 طوال الأسبوع\n✅ الشحن والسداد  والشحن من مكانك\n✅ الرقم البديل للسرية التامة\n✅ أقل عمولات في اليمن\n✅ مصارفة بأفضل الأسعار اللحظية\n✅ تشفير بنكي عالي المستوى\n✅ 3 عملات: ريال / دولار / ر.س\n✅ سحب نقدي من آلاف الوكلاء\n🏆 كل ما تحتاجه في جيبك!';
    }

    // عملات المحفظة
    if (message.contains('عملات') ||
        message.contains('sar') ||
        message.contains('usd') ||
        message.contains('yer') ||
        message.contains('دولار')) {
      return '$prefixمحفظتك في صيفي تدعم 3 عملات متكاملة! 💰\n💵 دولار (USD)\n💴 ر.ي (YER)\n💶 ر.س (SAR)\nيمكنك التبديل بينها ومصارفتها في أي وقت بأفضل سعر! 💱';
    }

    // حماية الحساب
    if (message.contains('كيف') &&
        (message.contains('احمي') ||
            message.contains('حمايه') ||
            message.contains('امان'))) {
      return '$prefixلحماية محفظتك:\n🔐 لا تشارك كلمة السر مع أي شخص\n🔐 فعّل البصمة من الإعدادات\n🔐 تأكد دائماً من رقم المستلم قبل التحويل\n🔐 لا تدخل بياناتك في روابط مشبوهة\n✅ صيفي تستخدم تشفيراً بنكياً عالمياً لحماية أموالك!';
    }

    // المحفظة الإلكترونية - رد عام شامل
    if (message.contains('محفظه الكترونيه') ||
        message.contains('صيفي باي') ||
        message.contains('wallet') ||
        (message.contains('محفظه') && !message.contains('نسيت'))) {
      return '$prefixمحفظة صيفي هي محفظتك الرقمية الأولى في اليمن! 🏆\nتستطيع من خلالها:\n• إرسال واستقبال الأموال فورياً\n• مصارفة العملات والدفع الإلكتروني\n• شحن الهاتف والشحن والسداد \n• سحب نقدي من آلاف الوكلاء\nماذا تريد أن تعرف عنها تحديداً؟ 😊';
    }

    // ==================== الشحن العام ====================
    if (message.contains('اشحن') ||
        message.contains('شحن') ||
        message.contains('رصيد')) {
      return '$prefixمن الرئيسية اختر "الشحن والسداد"، ثم اختر مشغل الاتصالات (يمن موبايل، سبأفون، يو، واي..) وأدخل الرقم والمبلغ. ⚡';
    }

    // ==================== الشحن والسداد  عموماً ====================
    if (message.contains('سداد') ||
        message.contains('فاتورة') ||
        message.contains('تسديد')) {
      return '$prefixمن الرئيسية اختر "الشحن والسداد "، ثم اختر نوع الفاتورة (كهرباء، مياه، هاتف، إنترنت..) وأدخل البيانات. 📋';
    }

    // ==================== الكهرباء والمياه ====================
    if (message.contains('كهرباء') || message.contains('مياه')) {
      return '$prefixسدد فواتير الكهرباء والمياه من قسم "الشحن والسداد " ← "ماء وكهرباء". أدخل رقم العداد واضغط سداد. 💡';
    }

    // ==================== الألعاب والترفيه ====================
    if (message.contains('العاب') ||
        message.contains('ببجي') ||
        message.contains('فري فاير')) {
      return '$prefixشحن الجواهر والألعاب متاح من قسم "الشحن والسداد" ← "ألعاب وترفيه". اختر اللعبة وأدخل الـ ID وشحّن فوراً. 🎮';
    }

    // ==================== تقارير ومصارفة ====================
    if (message.contains('مصارفه') ||
        message.contains('صرافه') ||
        message.contains('تحويل بين حساباتي') ||
        message.contains('تبديل عمله') ||
        message.contains('تغيير عمله') ||
        message.contains('بين حساباتي') ||
        message.contains('تحويل عمله')) {
      return '$prefixللمصارفة أو التحويل بين حساباتك، اتبع الآتي:\n1️⃣ من الشاشة الرئيسية اختر "تحويلات مالية"\n2️⃣ اختر "تحويل بين حساباتي"\n3️⃣ اختر العملة التي ستحول منها، ثم العملة التي ستحول إليها\n4️⃣ أدخل المبلغ المراد مصارفتة\n5️⃣ اضغط "تأكيد" وسيتم تبديل العملة في محفظتك فوراً بأفضل سعر! 💱';
    }
    if (message.contains('سعر الصرف') || message.contains('اسعار الصرف')) {
      return '$prefixأسعار الصرف اللحظية متاحة في قسم "مصارفة" من الرئيسية. 📈';
    }

    // ==================== العمولات والحدود ====================
    if (message.contains('عمولة') || message.contains('رسوم')) {
      return '$prefixصيفي تتميز بأقل عمولات في اليمن! يمكنك مراجعة تفاصيل العمولات من قسم "الشروط والأحكام" أو عند إجراء أي عملية ستظهر لك العمولة قبل التأكيد. 💚';
    }

    // ==================== إيداع وتغذية الحساب ====================
    if (message.contains('تغذية') ||
        message.contains('إيداع') ||
        message.contains('ايداع')) {
      return '$prefixلتغذية حسابك، زر أقرب وكيل أو فرع صيفي وقدم المبلغ، وسيُضاف فوراً لمحفظتك. 🏦';
    }

    // ==================== العمليات الفاشلة ====================
    if (message.contains('فاشلة') ||
        message.contains('فشلت') ||
        message.contains('خطأ')) {
      return '$prefixإذا كانت عملية بها مشكلة، تواصل فوراً مع خدمة العملاء على 8000002 أو راجع "السجل المالي" لتفاصيل العملية وحالتها. نحن نحل المشاكل فوراً! 🆘';
    }

    // ==================== ربط الحساب بصيفي كاش ====================
    if (message.contains('ربط') || message.contains('صيفي كاش')) {
      return '$prefixلربط حساب "صيفي كاش" بمحفظتك، اذهب لـ"التحويلات المالية" ← "ربط حساب صيفي" واتبع الخطوات. يُتيح لك الاستفادة من شبكة الحوالات. 🔗';
    }

    // ==================== إلغاء الحوالات ====================
    if (message.contains('إلغاء') || message.contains('استرجاع')) {
      return '$prefixلإلغاء حوالة صادرة، ادخل "السجل المالي" وابحث عن الحوالة ← اضغط عليها ← اختر إلغاء (متاحة خلال فترة محددة). ↩️';
    }

    // ==================== البنوك والمحافظ الأخرى ====================
    if (message.contains('بنك') || message.contains('بنوك')) {
      return '$prefixحوّل لأي بنك أو محفظة يمنية من قسم "بنوك ومحافظ" في التحويلات المالية بسهولة وأمان. 🏦';
    }

    // ==================== الدعم والتواصل ====================
    if (message.contains('تواصل') ||
        message.contains('دعم') ||
        message.contains('خدمة عملاء')) {
      return '$prefixيسعدنا مساعدتك يا $name! 📞 الرقم المجاني: 8000002 أو واتساب: 778555555. نعمل من الأحد إلى الخميس 8ص-8م، والتطبيق بخدمتك 24/7.';
    }

    if (message.contains('واتساب') || message.contains('واتس')) {
      return '$prefixيمكنك التواصل معنا عبر واتساب على الرقم 778555555 للحصول على مساعدة سريعة! 💬';
    }

    // ==================== ساعات العمل ====================
    if (message.contains('دوار') ||
        message.contains('ساعة') ||
        message.contains('وقت العمل')) {
      return '$prefixفروع صيفي مفتوحة من الأحد إلى الخميس، من 8 صباحاً حتى 8 مساءً. أما التطبيق فمتاح لك 24 ساعة يومياً! 🕗';
    }

    // ==================== الشكاوى والاقتراحات ====================
    if (message.contains('شكوى') ||
        message.contains('اقتراح') ||
        message.contains('مشكلة')) {
      return '$prefixصوتك مسموع يا $name! لتقديم شكوى أو اقتراح، تواصل مع خدمة العملاء على 8000002 أو ارسل لنا عبر واتساب. نقدّر رأيك جداً. 🌟';
    }

    // ==================== التواصل الاجتماعي ====================
    if (message.contains('فيسبوك') || message.contains('سوشيال')) {
      return '$prefixتابعنا على حساباتنا الرسمية:\n📘 فيسبوك: SaifiPay\n📷 إنستغرام: SaifiPay\n🐦 تويتر: @SaifiPay\nلأحدث أخبارنا وعروضنا الحصرية! 💙';
    }

    // ==================== الشروط والأحكام ====================
    if (message.contains('شروط') || message.contains('قوانين')) {
      return '$prefixيمكنك مراجعة "الشروط والأحكام" من قسم الحساب لمعرفة كافة حقوقك وواجباتك ضمن أسرة صيفي. 📄';
    }

    // ==================== تسجيل الدخول والتسجيل ====================
    if (message.contains('تسجيل دخول') || message.contains('دخول')) {
      return '$prefixلتسجيل الدخول، افتح التطبيق وأدخل رقم هاتفك ورمز المرور. يمكنك أيضاً استخدام البصمة أو Face ID لدخول أسرع وأأمن. 🔑';
    }
    if (message.contains('تسجيل') ||
        message.contains('اشتراك') ||
        message.contains('اسجل')) {
      return '$prefixلفتح حساب جديد في صيفي، حمّل التطبيق واضغط "تسجيل جديد"، أدخل رقم هاتفك وأكمل الخطوات. مرحباً بك في عائلة صيفي! 🎉';
    }

    // ==================== رقم الهاتف المسجل ====================
    if (message.contains('رقم هاتف') || message.contains('رقمي')) {
      return '$prefixرقمك المسجل في صيفي هو: ${widget.userPhoneNumber ?? "غير متوفر حالياً"}. إذا أردت تغييره تواصل مع الدعم على 8000002. 📱';
    }

    // ==================== اسم المستخدم والملف الشخصي ====================
    if (message.contains('اسم مستخدم') || message.contains('ملف شخصي')) {
      return '$prefixيمكنك مراجعة وتعديل ملفك الشخصي (الاسم، الصورة، المعلومات) من قسم "الحساب" في أسفل الشاشة. 👤';
    }

    // ==================== تحديث التطبيق ====================
    if (message.contains('تحديث') || message.contains('update')) {
      return '$prefixيمكنك تحديث التطبيق من متجر Play Store أو App Store. دائماً نُصدر تحديثات بمزايا جديدة تجعل تجربتك أفضل! 🚀';
    }

    // ==================== الوضع الليلي / المظهر ====================
    if (message.contains('وضع ليلي') ||
        message.contains('dark mode') ||
        message.contains('ثيم')) {
      return '$prefixلتغيير مظهر التطبيق (فاتح/داكن)، ادخل "الإعدادات" ← "تخصيص التطبيق" واختر المظهر الذي يناسبك. 🌙';
    }

    // ==================== الحوالة الخارجية ====================
    if (message.contains('خارج') &&
        (message.contains('حوالة') || message.contains('تحويل'))) {
      return '$prefixللحوالات الخارجية والدولية، تواصل مع خدمة العملاء على 8000002 للحصول على معلومات دقيقة حول الشبكات والعمولة المتاحة. 🌍';
    }

    // ==================== نقاط المكافآت ====================
    if (message.contains('نقطة') ||
        message.contains('نقاطي') ||
        message.contains('مكافأة')) {
      return '$prefixنظام نقاط صيفي يكافئك على كل عملية! راجع نقاطك من قسم "المكافآت والنقاط" في الحساب، ويمكنك استبدالها بخدمات وهدايا رائعة. 🏆';
    }

    // ==================== التحقق برمز OTP ====================
    if (message.contains('otp') || message.contains('رمز التحقق')) {
      return '$prefixإذا لم يصلك رمز التحقق (OTP)، تأكد أن الرقم صحيح واضغط "إعادة الإرسال". إذا استمرت المشكلة تواصل مع الدعم على 8000002. 📲';
    }

    // ==================== سرعة التحويل ====================
    if (message.contains('كم وقت') || message.contains('متى يوصل')) {
      return '$prefixالتحويلات في صيفي فورية أو خلال دقائق معدودة! صيفي تفخر بأسرع وقت تنفيذ في اليمن. ⚡';
    }

    // ==================== الوداع ====================
    if (message.contains('مع السلامة') ||
        message.contains('باي') ||
        message.contains('وداعاً')) {
      return 'وداعاً يا $name وأهلاً بك دائماً! 👋 صيفي ترافقك أينما ذهبت. إذا احتجت مساعدة، أنا هنا. 💙';
    }

    // ==================== المساعدة العامة ====================
    if (message.contains('مساعدة') ||
        message.contains('ساعدني') ||
        message.contains('help')) {
      return '$prefixأنا هنا لمساعدتك في كل شيء! يمكنني مساعدتك في:\n💸 تحويل الأموال\n📞 شحن الاتصالات\n💱 مصارفة العملات\n📄 كشف الحساب\n🏦 الحوالات\nوأكثر.. فقط أخبرني ماذا تريد! 😊';
    }

    // ==================== الرد الافتراضي الذكي ====================
    if (message.length <= 3) {
      return 'يا $name.. يبدو إن رسالتك قصيرة جداً! 😄 بإمكانك السؤال عن: رصيد، تحويل، شحن، فواتير، حوالة، أو أي خدمة أخرى.';
    }

    return 'يا $name، سؤالك يهمني جداً. 🤔 هل تقصد: تحويل، شحن، حوالة، رصيد، مصارفة، أم خدمة أخرى؟ وضّح لي أكثر وسأكون سعيداً بمساعدتك فوراً! أو تواصل مع الدعم على 8000002.';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      body: Stack(
        children: [
          _buildPremiumBackground(),
          Directionality(
            textDirection: TextDirection.rtl,
            child: SafeArea(
              child: Column(
                children: [
                  _buildPremiumHeader(
                        'المساعد الذكي',
                        () => Navigator.pop(context),
                      )
                      .animate()
                      .fade(duration: 400.ms)
                      .slideY(begin: -0.1, end: 0),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return _buildChatBubble(msg, isDark);
                      },
                    ),
                  ),
                  _buildQuickActions(isDark),
                  _buildMessageInput(isDark),
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
              borderRadius: BorderRadius.circular(10),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg, bool isDark) {
    final bool isUser = msg['isUser'];
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color:
              isUser
                  ? AppColors.primaryBlue
                  : (isDark ? AppColors.cardDark : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg['text'],
              style: GoogleFonts.cairo(
                color:
                    isUser
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black87),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                _formatTime(msg['time']),
                style: TextStyle(
                  color: isUser ? Colors.white70 : Colors.grey,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fade().slideX(begin: isUser ? 0.1 : -0.1, end: 0);
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildQuickActions(bool isDark) {
    final List<String> actions = [
      'الرصيد',
      'تواصل معنا',
      'ساعات الدوام',
      'امتيازات صيفي',
      'نظام النقاط',
      'الجوائز والهدايا',
      '4G شحن',
      'باقات الإنترنت',
      'سداد المشتريات',
      'إرسال حوالة',
      'استلام حوالة',
      'تحويل لمشترك',
      'مصارفة عملات',
      'يمن موبايل',
      'سبأفون',
      'باقات يو',
      'عمولات الخدمة',
      'حدود التحويل',
      'تغذية الحساب',
      'تقرير PDF',
      'أسعار الصرف',
      'سحب نقدي',
      'توثيق الحساب',
      'QR ماسح',
      'تفعيل البصمة',
      'نقاط مبيعات',
      'مواقع الوكلاء',
      'شحن ألعاب',
      'الدعم الفني',
    ];
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ActionChip(
              label: Text(
                actions[index],
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textBlack,
                ),
              ),
              backgroundColor: isDark ? AppColors.cardDark : Colors.white,
              elevation: 2,
              onPressed: () => _sendMessage(customMessage: actions[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: _messageController,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textBlack,
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك هنا...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.accentBlue],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
