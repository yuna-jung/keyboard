import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @paywallUpgradeTitle.
  ///
  /// In ko, this message translates to:
  /// **'프리미엄으로 업그레이드'**
  String get paywallUpgradeTitle;

  /// No description provided for @paywallUpgradeSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'모든 기능을 제한 없이 사용하세요'**
  String get paywallUpgradeSubtitle;

  /// No description provided for @paywallFeatureFonts.
  ///
  /// In ko, this message translates to:
  /// **'모든 폰트 스타일'**
  String get paywallFeatureFonts;

  /// No description provided for @paywallFeatureTranslate.
  ///
  /// In ko, this message translates to:
  /// **'번역 무제한'**
  String get paywallFeatureTranslate;

  /// No description provided for @paywallFeatureEmoticon.
  ///
  /// In ko, this message translates to:
  /// **'이모티콘/특수문자 전체'**
  String get paywallFeatureEmoticon;

  /// No description provided for @paywallFeatureGif.
  ///
  /// In ko, this message translates to:
  /// **'GIF 무제한'**
  String get paywallFeatureGif;

  /// No description provided for @paywallFeatureFavorite.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기'**
  String get paywallFeatureFavorite;

  /// No description provided for @paywallPlanWeekly.
  ///
  /// In ko, this message translates to:
  /// **'주간'**
  String get paywallPlanWeekly;

  /// No description provided for @paywallPlanYearly.
  ///
  /// In ko, this message translates to:
  /// **'연간'**
  String get paywallPlanYearly;

  /// No description provided for @paywallLaunchBadge.
  ///
  /// In ko, this message translates to:
  /// **'출시 이벤트'**
  String get paywallLaunchBadge;

  /// No description provided for @paywallStartTrial.
  ///
  /// In ko, this message translates to:
  /// **'1주 무료체험 시작'**
  String get paywallStartTrial;

  /// No description provided for @paywallTrialNote.
  ///
  /// In ko, this message translates to:
  /// **'무료체험 후 자동 결제 · 언제든 해지 가능'**
  String get paywallTrialNote;

  /// No description provided for @paywallRestore.
  ///
  /// In ko, this message translates to:
  /// **'구매 복원'**
  String get paywallRestore;

  /// No description provided for @paywallLater.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get paywallLater;

  /// No description provided for @paywallErrorPurchase.
  ///
  /// In ko, this message translates to:
  /// **'구매 처리 중 오류가 발생했습니다'**
  String get paywallErrorPurchase;

  /// No description provided for @paywallErrorRestore.
  ///
  /// In ko, this message translates to:
  /// **'복원 중 오류가 발생했습니다'**
  String get paywallErrorRestore;

  /// No description provided for @paywallErrorNoSub.
  ///
  /// In ko, this message translates to:
  /// **'복원할 구독이 없습니다'**
  String get paywallErrorNoSub;

  /// No description provided for @paywallPerWeek.
  ///
  /// In ko, this message translates to:
  /// **'/주'**
  String get paywallPerWeek;

  /// No description provided for @paywallPerYear.
  ///
  /// In ko, this message translates to:
  /// **'/년'**
  String get paywallPerYear;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In ko, this message translates to:
  /// **'환영해요!'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'당신만의 특별한 키보드를 만나보세요'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingStart.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get onboardingStart;

  /// No description provided for @onboardingNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get onboardingNext;

  /// No description provided for @onboardingTermsPre.
  ///
  /// In ko, this message translates to:
  /// **'당사의 '**
  String get onboardingTermsPre;

  /// No description provided for @onboardingTermsLink.
  ///
  /// In ko, this message translates to:
  /// **'서비스 이용약관'**
  String get onboardingTermsLink;

  /// No description provided for @onboardingTermsMid.
  ///
  /// In ko, this message translates to:
  /// **'을 수락하고 '**
  String get onboardingTermsMid;

  /// No description provided for @onboardingPrivacyLink.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 방침'**
  String get onboardingPrivacyLink;

  /// No description provided for @onboardingTermsPost.
  ///
  /// In ko, this message translates to:
  /// **'에 대해\n고지받으신 것으로 간주됩니다.'**
  String get onboardingTermsPost;

  /// No description provided for @onboardingTermsUrl.
  ///
  /// In ko, this message translates to:
  /// **'https://fonkii-keyboard.github.io/Fonkii/terms-of-service-ko.html'**
  String get onboardingTermsUrl;

  /// No description provided for @onboardingPrivacyUrl.
  ///
  /// In ko, this message translates to:
  /// **'https://fonkii-keyboard.github.io/Fonkii/privacy-policy-ko.html'**
  String get onboardingPrivacyUrl;

  /// No description provided for @onboarding2Title.
  ///
  /// In ko, this message translates to:
  /// **'Fonkii 키보드 켜볼까요? 🎉'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Subtitle.
  ///
  /// In ko, this message translates to:
  /// **'딱 30초면 설정 끝!'**
  String get onboarding2Subtitle;

  /// No description provided for @onboarding2GoSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정하러 가기'**
  String get onboarding2GoSettings;

  /// No description provided for @onboarding2SnackError.
  ///
  /// In ko, this message translates to:
  /// **'아직 설정이 완료되지 않았어요 😢\n키보드를 추가하고 전체 접근을 허용해주세요'**
  String get onboarding2SnackError;

  /// No description provided for @onboarding2MockFont.
  ///
  /// In ko, this message translates to:
  /// **'서체'**
  String get onboarding2MockFont;

  /// No description provided for @onboarding2MockLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어 및 지역'**
  String get onboarding2MockLanguage;

  /// No description provided for @onboarding2MockPassword.
  ///
  /// In ko, this message translates to:
  /// **'자동 완성 및 암호'**
  String get onboarding2MockPassword;

  /// No description provided for @onboarding2MockKeyboard.
  ///
  /// In ko, this message translates to:
  /// **'키보드'**
  String get onboarding2MockKeyboard;

  /// No description provided for @onboarding2MockFullAccess.
  ///
  /// In ko, this message translates to:
  /// **'전체 접근 허용'**
  String get onboarding2MockFullAccess;

  /// No description provided for @onboarding3Title.
  ///
  /// In ko, this message translates to:
  /// **'이제 Fonkii 키보드를 사용해봐요! ⌨️'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Subtitle.
  ///
  /// In ko, this message translates to:
  /// **'지구본 버튼을 꾹 누르면 Fonkii를 선택할 수 있어요'**
  String get onboarding3Subtitle;

  /// No description provided for @onboarding3LongPress.
  ///
  /// In ko, this message translates to:
  /// **'꾹 누르기 →'**
  String get onboarding3LongPress;

  /// No description provided for @onboarding4FontTitle.
  ///
  /// In ko, this message translates to:
  /// **'46가지의 폰트 변환'**
  String get onboarding4FontTitle;

  /// No description provided for @onboarding4FontDesc.
  ///
  /// In ko, this message translates to:
  /// **'채팅을 더 특별하게! 나만의 개성 폰트'**
  String get onboarding4FontDesc;

  /// No description provided for @onboarding4TranslateTitle.
  ///
  /// In ko, this message translates to:
  /// **'실시간 번역'**
  String get onboarding4TranslateTitle;

  /// No description provided for @onboarding4TranslateDesc.
  ///
  /// In ko, this message translates to:
  /// **'9개 언어로 바로 번역!\n외국 친구와도 자유롭게 소통해요'**
  String get onboarding4TranslateDesc;

  /// No description provided for @onboarding4InstaTitle.
  ///
  /// In ko, this message translates to:
  /// **'인스타에서도 써봐요! 📸'**
  String get onboarding4InstaTitle;

  /// No description provided for @onboarding4InstaDesc.
  ///
  /// In ko, this message translates to:
  /// **'Fonkii 폰트로 인스타 스토리, 게시물을 더 특별하게!'**
  String get onboarding4InstaDesc;

  /// No description provided for @onboarding4InstaCategory.
  ///
  /// In ko, this message translates to:
  /// **'키보드 앱'**
  String get onboarding4InstaCategory;

  /// No description provided for @onboarding4TagEnglish.
  ///
  /// In ko, this message translates to:
  /// **'🇺🇸 영어'**
  String get onboarding4TagEnglish;

  /// No description provided for @onboarding4TagJapanese.
  ///
  /// In ko, this message translates to:
  /// **'🇯🇵 일본어'**
  String get onboarding4TagJapanese;

  /// No description provided for @onboarding4TagChinese.
  ///
  /// In ko, this message translates to:
  /// **'🇨🇳 중국어'**
  String get onboarding4TagChinese;

  /// No description provided for @homeTabTrial.
  ///
  /// In ko, this message translates to:
  /// **'체험하기'**
  String get homeTabTrial;

  /// No description provided for @homeTabStickerMaker.
  ///
  /// In ko, this message translates to:
  /// **'내 스티커'**
  String get homeTabStickerMaker;

  /// No description provided for @homeTabGuide.
  ///
  /// In ko, this message translates to:
  /// **'가이드'**
  String get homeTabGuide;

  /// No description provided for @homeTabSubscription.
  ///
  /// In ko, this message translates to:
  /// **'구독'**
  String get homeTabSubscription;

  /// No description provided for @homeMyListTooltip.
  ///
  /// In ko, this message translates to:
  /// **'내 목록 관리'**
  String get homeMyListTooltip;

  /// No description provided for @homeChatSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'Fonkii 키보드 체험하기'**
  String get homeChatSectionTitle;

  /// No description provided for @homeChatHint.
  ///
  /// In ko, this message translates to:
  /// **'메시지 입력...'**
  String get homeChatHint;

  /// No description provided for @homeChatMsg1.
  ///
  /// In ko, this message translates to:
  /// **'안녕! 새로운 키보드 써봤어? 😊'**
  String get homeChatMsg1;

  /// No description provided for @homeChatMsg2.
  ///
  /// In ko, this message translates to:
  /// **'응! Fonkii 키보드인데 폰트도 바꿀 수 있어'**
  String get homeChatMsg2;

  /// No description provided for @homeChatMsg3.
  ///
  /// In ko, this message translates to:
  /// **'진짜? 어떻게 생겼어? 보여줘!'**
  String get homeChatMsg3;

  /// No description provided for @homePremiumCta.
  ///
  /// In ko, this message translates to:
  /// **'✨ 프리미엄 시작하기'**
  String get homePremiumCta;

  /// No description provided for @homePremiumActive.
  ///
  /// In ko, this message translates to:
  /// **'✓ 프리미엄 이용 중'**
  String get homePremiumActive;

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @settingsSectionSocial.
  ///
  /// In ko, this message translates to:
  /// **'소셜'**
  String get settingsSectionSocial;

  /// No description provided for @settingsShareApp.
  ///
  /// In ko, this message translates to:
  /// **'앱 공유'**
  String get settingsShareApp;

  /// No description provided for @settingsShareMessage.
  ///
  /// In ko, this message translates to:
  /// **'Fonkii 키보드로 더 재밌게 소통해요! 🎨\nhttps://apps.apple.com/app/fonkii/id6762085484'**
  String get settingsShareMessage;

  /// No description provided for @settingsSectionHelp.
  ///
  /// In ko, this message translates to:
  /// **'도움말'**
  String get settingsSectionHelp;

  /// No description provided for @settingsSupport.
  ///
  /// In ko, this message translates to:
  /// **'고객 지원'**
  String get settingsSupport;

  /// No description provided for @settingsSectionLegal.
  ///
  /// In ko, this message translates to:
  /// **'법적 고지'**
  String get settingsSectionLegal;

  /// No description provided for @settingsTerms.
  ///
  /// In ko, this message translates to:
  /// **'서비스 약관'**
  String get settingsTerms;

  /// No description provided for @settingsPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보처리방침'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacySettings.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 보호 설정'**
  String get settingsPrivacySettings;

  /// No description provided for @guideSection1Title.
  ///
  /// In ko, this message translates to:
  /// **'키보드 추가하는 방법'**
  String get guideSection1Title;

  /// No description provided for @guideSection1Step1.
  ///
  /// In ko, this message translates to:
  /// **'설정 → 일반 → 키보드 → 키보드 추가'**
  String get guideSection1Step1;

  /// No description provided for @guideSection1Step2.
  ///
  /// In ko, this message translates to:
  /// **'Fonkii 선택'**
  String get guideSection1Step2;

  /// No description provided for @guideSection1Step3.
  ///
  /// In ko, this message translates to:
  /// **'전체 접근 허용 (GIF / 즐겨찾기 동기화에 필요해요)'**
  String get guideSection1Step3;

  /// No description provided for @guideSection2Title.
  ///
  /// In ko, this message translates to:
  /// **'폰트 변경하는 방법'**
  String get guideSection2Title;

  /// No description provided for @guideSection2Step1.
  ///
  /// In ko, this message translates to:
  /// **'Fonkii 키보드로 전환 후 Aa 탭 선택'**
  String get guideSection2Step1;

  /// No description provided for @guideSection2Step2.
  ///
  /// In ko, this message translates to:
  /// **'원하는 폰트 카테고리를 고르고 폰트 알약을 탭'**
  String get guideSection2Step2;

  /// No description provided for @guideSection2Step3.
  ///
  /// In ko, this message translates to:
  /// **'선택한 폰트로 그대로 타이핑됩니다'**
  String get guideSection2Step3;

  /// No description provided for @guideSection2Step4.
  ///
  /// In ko, this message translates to:
  /// **'이미 입력한 텍스트 위에 커서를 놓고 폰트를 선택하면\n해당 텍스트가 선택한 폰트로 변환됩니다'**
  String get guideSection2Step4;

  /// No description provided for @guideSection3Title.
  ///
  /// In ko, this message translates to:
  /// **'폰트 즐겨찾기'**
  String get guideSection3Title;

  /// No description provided for @guideSection3Step1.
  ///
  /// In ko, this message translates to:
  /// **'Aa 탭에서 원하는 폰트 알약을 꾹 누르면 즐겨찾기에 추가'**
  String get guideSection3Step1;

  /// No description provided for @guideSection3Step2.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 탭(♥)에서 모아 볼 수 있어요'**
  String get guideSection3Step2;

  /// No description provided for @guideSection4Title.
  ///
  /// In ko, this message translates to:
  /// **'번역 기능 사용하기'**
  String get guideSection4Title;

  /// No description provided for @guideSection4Step1.
  ///
  /// In ko, this message translates to:
  /// **'번역 탭 선택'**
  String get guideSection4Step1;

  /// No description provided for @guideSection4Step2.
  ///
  /// In ko, this message translates to:
  /// **'원본 / 도착 언어를 고르고 텍스트 입력'**
  String get guideSection4Step2;

  /// No description provided for @guideSection4Step3.
  ///
  /// In ko, this message translates to:
  /// **'번역 버튼을 탭하면 결과가 나타납니다'**
  String get guideSection4Step3;

  /// No description provided for @guideSection4Step4.
  ///
  /// In ko, this message translates to:
  /// **'\"삽입\" 버튼으로 호스트 앱에 결과를 바로 붙여넣을 수 있어요'**
  String get guideSection4Step4;

  /// No description provided for @guideSection5Title.
  ///
  /// In ko, this message translates to:
  /// **'키보드 컬러 변경'**
  String get guideSection5Title;

  /// No description provided for @guideSection5Step1.
  ///
  /// In ko, this message translates to:
  /// **'팔레트 탭(🎨) 선택'**
  String get guideSection5Step1;

  /// No description provided for @guideSection5Step2.
  ///
  /// In ko, this message translates to:
  /// **'6가지 프리셋 색상을 고르거나, RGB 슬라이더로 직접 만드세요'**
  String get guideSection5Step2;

  /// No description provided for @trialNotificationTitle.
  ///
  /// In ko, this message translates to:
  /// **'무료 체험이 곧 끝나가요'**
  String get trialNotificationTitle;

  /// No description provided for @trialNotificationBody.
  ///
  /// In ko, this message translates to:
  /// **'2일 후 자동으로 구독이 시작돼요! 계속 함께 하실 거죠…? 🩵'**
  String get trialNotificationBody;

  /// No description provided for @trialPrimerTitle.
  ///
  /// In ko, this message translates to:
  /// **'체험 끝나기 전에 알려드릴게요 🩵'**
  String get trialPrimerTitle;

  /// No description provided for @trialPrimerBody.
  ///
  /// In ko, this message translates to:
  /// **'무료 체험 종료 2일 전에 알림을 보내드려요\n알림을 허용해 주세요'**
  String get trialPrimerBody;

  /// No description provided for @trialPrimerConfirmButton.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get trialPrimerConfirmButton;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @stickerAddImage.
  ///
  /// In ko, this message translates to:
  /// **'이미지 추가하기'**
  String get stickerAddImage;

  /// No description provided for @stickerPickFailed.
  ///
  /// In ko, this message translates to:
  /// **'이미지를 가져오지 못했어요: {error}'**
  String stickerPickFailed(String error);

  /// No description provided for @stickerBatchSavedAll.
  ///
  /// In ko, this message translates to:
  /// **'{count}개의 스티커를 저장했어요'**
  String stickerBatchSavedAll(int count);

  /// No description provided for @stickerBatchFailedAll.
  ///
  /// In ko, this message translates to:
  /// **'스티커 저장에 실패했어요 ({count}개)'**
  String stickerBatchFailedAll(int count);

  /// No description provided for @stickerBatchPartial.
  ///
  /// In ko, this message translates to:
  /// **'{saved}개 저장 완료, {failed}개 실패'**
  String stickerBatchPartial(int saved, int failed);

  /// No description provided for @stickerSaved.
  ///
  /// In ko, this message translates to:
  /// **'스티커를 저장했어요'**
  String get stickerSaved;

  /// No description provided for @stickerSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장에 실패했어요: {error}'**
  String stickerSaveFailed(String error);

  /// No description provided for @stickerSaveButton.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get stickerSaveButton;

  /// No description provided for @stickerDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'스티커 삭제'**
  String get stickerDeleteTitle;

  /// No description provided for @stickerDeleteConfirmSingle.
  ///
  /// In ko, this message translates to:
  /// **'이 스티커를 삭제할까요?\n이 동작은 되돌릴 수 없어요.'**
  String get stickerDeleteConfirmSingle;

  /// No description provided for @stickerDeleteConfirmMultiple.
  ///
  /// In ko, this message translates to:
  /// **'선택한 {count}개의 스티커를 삭제할까요?\n이 동작은 되돌릴 수 없어요.'**
  String stickerDeleteConfirmMultiple(int count);

  /// No description provided for @stickerDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제하지 못했어요'**
  String get stickerDeleteFailed;

  /// No description provided for @stickerDeletedAll.
  ///
  /// In ko, this message translates to:
  /// **'{count}개를 삭제했어요'**
  String stickerDeletedAll(int count);

  /// No description provided for @stickerDeletedPartial.
  ///
  /// In ko, this message translates to:
  /// **'{deleted}개 삭제 완료, {failed}개 실패'**
  String stickerDeletedPartial(int deleted, int failed);

  /// No description provided for @stickerEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 저장한 스티커가 없어요'**
  String get stickerEmptyTitle;

  /// No description provided for @stickerSelectedCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 선택'**
  String stickerSelectedCount(int count);

  /// No description provided for @stickerDeleteWithCount.
  ///
  /// In ko, this message translates to:
  /// **'삭제({count})'**
  String stickerDeleteWithCount(int count);

  /// No description provided for @stickerSelectButton.
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get stickerSelectButton;

  /// No description provided for @stickerTourAddDesc.
  ///
  /// In ko, this message translates to:
  /// **'여기를 눌러 원하는 짤을 스티커로 만들어보세요\n한 번에 여러 장도 선택할 수 있어요'**
  String get stickerTourAddDesc;

  /// No description provided for @stickerTourGridDesc.
  ///
  /// In ko, this message translates to:
  /// **'추가한 스티커가 여기에 모여요'**
  String get stickerTourGridDesc;

  /// No description provided for @stickerTourSelectDesc.
  ///
  /// In ko, this message translates to:
  /// **'여러 개를 한 번에 정리하고 싶다면\n여기를 눌러보세요'**
  String get stickerTourSelectDesc;

  /// No description provided for @stickerHelpTooltip.
  ///
  /// In ko, this message translates to:
  /// **'튜토리얼 다시 보기'**
  String get stickerHelpTooltip;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
