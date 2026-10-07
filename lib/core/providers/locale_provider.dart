import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LocaleProvider();

  static Future<LocaleProvider> create() async {
    final provider = LocaleProvider();
    await provider._loadLanguage();
    return provider;
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? langCode = prefs.getString('language_code');
    if (langCode != null) {
      _locale = Locale(langCode);
      notifyListeners();
    }
  }

  Future<void> toggleLanguage() async {
    if (_locale.languageCode == 'en') {
      _locale = const Locale('ar');
    } else {
      _locale = const Locale('en');
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', _locale.languageCode);
    
    notifyListeners();
  }

  String translate(String key) {
    return _localizedStrings[_locale.languageCode]?[key] ?? key;
  }

  static const Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'HOME': 'HOME',
      'MATCHES': 'MATCHES',
      'HISTORY': 'HISTORY',
      'PROFILE': 'PROFILE',
      'LIVE MATCHES': 'LIVE MATCHES',
      'UPCOMING MATCHES': 'UPCOMING MATCHES',
      'JOIN GAME': 'JOIN GAME',
      'PLAYERS PER ROOM': 'PLAYERS PER ROOM',
      'ENTRY FEE': 'ENTRY FEE',
      'TOTAL POINTS': 'TOTAL POINTS',
      'GAMES': 'GAMES',
      'WINS': 'WINS',
      'POINTS': 'Ranking Points (RP)',
      'Total Coins Earned': 'Total Coins Earned',
      'Global Rank': 'Global Rank',
      'GLOBAL RANKING': 'GLOBAL RANKING',
      'YOUR RANK': 'YOUR RANK',
      'RANKING': 'RANKING',
      'CONFIRM_ENTRY': 'Confirm Match Entry',
      'CONFIRM_ENTRY_DESC': '500 Coins will be deducted to enter the match draft and compete for rewards:\n\n🥇 1st Place: +1000 Coins\n🥈 2nd Place: +500 Coins\n\nDo you want to confirm and join?',
      'CONFIRM & JOIN': 'CONFIRM & JOIN',
      'CANCEL': 'CANCEL',
      'WALLET': 'WALLET',
      'COINS': 'COINS',
      'WATCH AD FOR +500 COINS': 'WATCH AD FOR +500 COINS',
      'TRANSACTION HISTORY': 'TRANSACTION HISTORY',
      "You're out of Coins": "You're out of Coins",
      'Watch a short video and get 500 Coins to play your next game.': 'Watch a short video and get 500 Coins to play your next game.',
      'REWARD': 'REWARD',
      'WATCH 30s AD': 'WATCH 30s AD',
      'Watching ad...': 'Watching ad...',
      'Reward Added!': 'Reward Added!',
      '+500 COINS\n\nYou are ready for your next game!': '+500 COINS\n\nYou are ready for your next game!',
      'AWESOME': 'AWESOME',
      'MATCH DETAILS': 'MATCH DETAILS',
      'LIVE': 'LIVE',
      'VS': 'VS',
      'PLAYERS PER ROOM: 4': 'PLAYERS PER ROOM: 4',
      'ENTRY FEE: 500 COINS': 'ENTRY FEE: 500 COINS',
      'Failed to join game:': 'Failed to join game:',
      'Out of Coins': 'Out of Coins',
      '500 COINS REWARD': '500 COINS REWARD',
      'Maybe Later': 'Maybe Later',
      '+500 Coins added! You can now join the game.': '+500 Coins added! You can now join the game.',
      'Failed to claim reward:': 'Failed to claim reward:',
      'LIVE FEED': 'LIVE FEED',
      'VIEW LIVE RANKING': 'VIEW LIVE RANKING',
      'LIVE RANKING': 'LIVE RANKING',
      'PTS': 'PTS',
      'FULL TIME': 'FULL TIME',
      'FINAL RANKING': 'FINAL RANKING',
      'POINTS ': 'POINTS ',
      '+ COINS': '+ COINS',
      '+ RANKING': '+ RANKING',
      'RETURN TO HOME': 'RETURN TO HOME',
      'GAME ROOM': 'GAME ROOM',
      'Waiting for players...': 'Waiting for players...',
      'SNAKE DRAFT': 'SNAKE DRAFT',
      'TURN': 'TURN',
      'Waiting...': 'Waiting...',
      'SELECT': 'SELECT',
      'Welcome to UFL!': 'Welcome to UFL!',
      'You received your welcome bonus:': 'You received your welcome bonus:',
      '500 COINS': '500 COINS',
      'START PLAYING': 'START PLAYING',
      'Passwords do not match': 'Passwords do not match',
      'Please fill all fields': 'Please fill all fields',
      'Please enter email and password': 'Please enter email and password',
      'No transactions yet': 'No transactions yet',
      'WELCOME_BONUS': 'Welcome Bonus',
      'REWARDED_AD': 'Ad Reward',
      'GAME_ENTRY': 'Game Entry Fee',
      'GAME_REWARD': 'Game Reward',
      'GAME_REFUND': 'Game Refund',
      'AD_REWARD': 'Ad Reward',
      'Current Balance': 'Available Balance',
      'COINS BREAKDOWN': 'Coins History',
    },
    'ar': {
      'HOME': 'الرئيسية',
      'MATCHES': 'المباريات',
      'HISTORY': 'السجل',
      'PROFILE': 'الملف الشخصي',
      'LIVE MATCHES': 'المباريات المباشرة',
      'UPCOMING MATCHES': 'المباريات القادمة',
      'JOIN GAME': 'انضم للعبة',
      'PLAYERS PER ROOM': 'اللاعبين في الغرفة',
      'ENTRY FEE': 'رسوم الدخول',
      'TOTAL POINTS': 'إجمالي النقاط',
      'GAMES': 'المباريات',
      'WINS': 'الانتصارات',
      'POINTS': 'نقاط التصنيف (RP)',
      'Total Coins Earned': 'إجمالي العملات المكتسبة',
      'Global Rank': 'التصنيف العالمي',
      'GLOBAL RANKING': 'التصنيف العالمي',
      'YOUR RANK': 'تصنيفك',
      'RANKING': 'التصنيف',
      'CONFIRM_ENTRY': 'تأكيد دخول المباراة',
      'CONFIRM_ENTRY_DESC': 'سيتم خصم ٥٠٠ عملة كرسوم دخول لبدء درافت المباراة والمنافسة على الجوائز:\n\n🥇 المركز الأول: +١٠٠٠ عملة\n🥈 المركز الثاني: +٥٠٠ عملة\n\nهل تود تأكيد الانضمام؟',
      'CONFIRM & JOIN': 'تأكيد ودخول',
      'CANCEL': 'إلغاء',
      'WALLET': 'المحفظة',
      'COINS': 'عملة',
      'WATCH AD FOR +500 COINS': 'شاهد إعلاناً للحصول على +٥٠٠ عملة',
      'TRANSACTION HISTORY': 'سجل العمليات',
      "You're out of Coins": "لقد نفدت عملاتك",
      'Watch a short video and get 500 Coins to play your next game.': 'شاهد فيديو قصير واحصل على ٥٠٠ عملة للعب مباراتك القادمة.',
      'REWARD': 'مكافأة',
      'WATCH 30s AD': 'شاهد إعلان ٣٠ ثانية',
      'Watching ad...': 'جاري عرض الإعلان...',
      'Reward Added!': 'تمت إضافة المكافأة!',
      '+500 COINS\n\nYou are ready for your next game!': '+٥٠٠ عملة\n\nأنت جاهز لمباراتك القادمة!',
      'AWESOME': 'رائع',
      'MATCH DETAILS': 'تفاصيل المباراة',
      'LIVE': 'مباشر',
      'VS': 'ضد',
      'PLAYERS PER ROOM: 4': 'سعة الغرفة: ٤ لاعبين',
      'ENTRY FEE: 500 COINS': 'رسوم الدخول: ٥٠٠ عملة',
      'Failed to join game:': 'فشل الانضمام للعبة:',
      'Out of Coins': 'لا يوجد عملات كافية',
      '500 COINS REWARD': 'مكافأة ٥٠٠ عملة',
      'Maybe Later': 'ربما لاحقاً',
      '+500 Coins added! You can now join the game.': 'تم إضافة ٥٠٠ عملة! يمكنك الآن الانضمام.',
      'Failed to claim reward:': 'فشل الحصول على المكافأة:',
      'LIVE FEED': 'البث المباشر',
      'VIEW LIVE RANKING': 'عرض الترتيب المباشر',
      'LIVE RANKING': 'الترتيب المباشر',
      'PTS': 'نقطة',
      'FULL TIME': 'نهاية المباراة',
      'FINAL RANKING': 'الترتيب النهائي',
      'POINTS ': 'النقاط ',
      '+ COINS': '+ عملات',
      '+ RANKING': '+ تصنيف',
      'RETURN TO HOME': 'العودة للرئيسية',
      'GAME ROOM': 'غرفة اللعبة',
      'Waiting for players...': 'بانتظار اللاعبين...',
      'SNAKE DRAFT': 'اختيار اللاعبين',
      'TURN': 'دور',
      'Waiting...': 'انتظار...',
      'SELECT': 'اختيار',
      'Welcome to UFL!': 'أهلاً بك في UFL!',
      'You received your welcome bonus:': 'لقد حصلت على مكافأة الترحيب:',
      '500 COINS': '٥٠٠ عملة',
      'START PLAYING': 'ابدأ اللعب',
      'Passwords do not match': 'كلمات المرور غير متطابقة',
      'Please fill all fields': 'يرجى ملء جميع الحقول',
      'Please enter email and password': 'يرجى إدخال البريد الإلكتروني وكلمة المرور',
      'No transactions yet': 'لا توجد عمليات بعد',
      'LIVE NOW': 'مباشر الآن',
      'VIEW ALL': 'عرض الكل',
      'UPCOMING DRAFTS': 'درفتات قادمة',
      'No matches right now': 'لا توجد مباريات الآن',
      'Check back soon for upcoming drafts': 'تحقق لاحقاً لدرفتات قادمة',
      'Welcome back': 'مرحباً بعودتك',
      'Your squad is ready for matchday.': 'فريقك جاهز ليوم المباراة.',
      'JOIN GAME ROOM': 'دخول للغرفة',
      'VIEW DRAFT': 'عرض درفت',
      'DRAFT': 'درفت',
      'All': 'الكل',
      'Premier League': 'الدوري الإنجليزي',
      'La Liga': 'الدوري الإسباني',
      'Saudi Pro League': 'دوري روشن السعودي',
      'WELCOME_BONUS': 'هدية تسجيل',
      'REWARDED_AD': 'مكافأة مشاهدة إعلان',
      'GAME_ENTRY': 'رسوم الدخول للمباراة',
      'GAME_REWARD': 'مكافأة الفوز بالمباراة',
      'GAME_REFUND': 'استرداد عملات المباراة',
      'AD_REWARD': 'مكافأة مشاهدة إعلان',
      'Current Balance': 'الرصيد المتاح',
      'COINS BREAKDOWN': 'سجل مصادر العملات',
    }
  };
}
