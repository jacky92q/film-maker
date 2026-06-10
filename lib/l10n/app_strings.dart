import 'package:flutter/widgets.dart';

/// Supported app languages.
enum AppLanguage {
  en,
  ko;

  /// The Flutter [Locale] for this language.
  Locale get locale => switch (this) {
        AppLanguage.en => const Locale('en'),
        AppLanguage.ko => const Locale('ko'),
      };

  /// Persisted string code.
  String get code => name;

  /// Name shown in the language picker (always in its own language).
  String get nativeName => switch (this) {
        AppLanguage.en => 'English',
        AppLanguage.ko => '한국어',
      };

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.en,
    );
  }
}

/// Global access point for the currently-active translations.
///
/// [current] is updated by `LocaleController`; widgets that read [s] inside
/// their `build` will reflect the active language once they rebuild.
class L10n {
  L10n._();

  static AppLanguage current = AppLanguage.en;

  static AppStrings get s =>
      current == AppLanguage.ko ? const _KoStrings() : const _EnStrings();
}

/// All user-facing strings in the app. Implemented by [_EnStrings] and
/// [_KoStrings].
abstract class AppStrings {
  const AppStrings();

  // ── Common ────────────────────────────────────────────────────────────────
  String get cancel;
  String get save;
  String get delete;
  String get done;
  String get create;
  String get remove;
  String get reset;
  String get tryAgain;
  String get discard;
  String get share;

  // ── App / splash ────────────────────────────────────────────────────────
  String get appTagline;

  // ── Login ─────────────────────────────────────────────────────────────────
  String get loginHeroTitle;
  String get loginHeroSubtitle;
  String get email;
  String get password;
  String get signIn;
  String get orDivider;
  String get signInWithGoogle;
  String get dontHaveAccount;
  String get register;

  // ── Register ────────────────────────────────────────────────────────────
  String get createAccountTitle;
  String get registerSubtitle;
  String get passwordHintRegister;
  String get confirmPassword;
  String get createAccountButton;
  String get passwordsDoNotMatch;
  String get alreadyHaveAccount;

  // ── Auth errors ───────────────────────────────────────────────────────────
  String get errIncorrectCredentials;
  String get errEmailInUse;
  String get errWeakPassword;
  String get errInvalidEmail;
  String get errNetwork;
  String get errTooManyRequests;
  String get errOperationNotAllowed;
  String get errGoogleSignIn;
  String get errUnauthorizedDomain;
  String get errGeneric;

  // ── Home ──────────────────────────────────────────────────────────────────
  String get welcomeBack;
  String get newFilm;
  String get quickActions;
  String get tipsTitle;
  String get signOut;
  String get settings;
  String get myFilms;
  String get myFilmsSub;
  String get newFilmSub;
  String get statFilms;
  String get statSlides;
  String get tip1;
  String get tip2;
  String get tip3;
  String get newWeddingFilm;
  String get filmTitlePrompt;
  String get filmTitleHint;
  String get videoFormat;
  String get formatLandscape;
  String get formatPortrait;
  String get formatLandscapeDesc;
  String get formatPortraitDesc;

  // ── Projects ──────────────────────────────────────────────────────────────
  String get myWeddingFilms;
  String get noFilmsYet;
  String get noFilmsSub;
  String get deleteFilmTitle;
  String deleteFilmConfirm(String title);
  String get deleteSlideTitle;
  String get deleteSlideConfirm;
  String get today;
  String get yesterday;
  String daysAgo(int n);
  String get musicBadge;
  String slidesCount(int n);

  // ── Export ────────────────────────────────────────────────────────────────
  String get exportFilm;
  String get readyToExport;
  String get outputQuality;
  String get outputQualitySub;
  String get recommended;
  String get resHdDesc;
  String get resFullHdDesc;
  String get res4kDesc;
  String get exportToMp4;
  String get exportSlideImages;
  String get webExportNote;
  String estimatedTime(int seconds);
  String get savedToGallery;
  String get renderingTitle;
  String get phaseCapturing;
  String get phaseCompositing;
  String get phaseEncoding;
  String get phaseSaving;
  String get doneLabel;
  String get cancelExport;
  String get exportComplete;
  String get exportCompleteSub;
  String get doneButton;
  String get exportAgain;
  String get exportFailed;
  String get exportFailedDefault;
  String get noSlidesToExport;
  String get shareError;
  String durationLabel(int seconds);

  // ── Editor ────────────────────────────────────────────────────────────────
  String get untitledFilm;
  String get unsavedChanges;
  String get saveBeforeLeaving;
  String get preview;
  String get export;
  String get noSlides;
  String get tabSlide;
  String get tabPhoto;
  String get tabText;
  String get tabSticker;
  String get tabMusic;
  String get noPhotoSelected;
  String get tapPhotoHint;
  String get addPhotoBtn;
  String get noTextSelected;
  String get tapTextHint;
  String get addTitleBtn;
  String get addSubtitleBtn;
  String get chooseTemplate;
  String get templateSub;
  String get saveTooltip;
  String get enterText;
  String get tapAddText;
  String get dragPinchZoom;
  String get dragPanPinchZoom;

  // Section headers / labels
  String get secBackground;
  String get secDim;
  String get secPhotoZoom;
  String get secFilter;
  String get secOverlay;
  String get secPhotoShape;
  String get secPhotoFrame;
  String get secTransition;
  String get secDuration;
  String get secShape;
  String get secFrame;
  String get secPhotoLayer;
  String get secMainLayer;
  String get secSubtitleLayer;
  String get secType;
  String get secFont;
  String get secSize;
  String get secTextColor;
  String get secBarColor;
  String get secTextBg;
  String get secOutline;
  String get secShadow;
  String get secSpacing;
  String get secRotation;
  String get secAnimation;
  String get secWidth;
  String get secHeight;

  // Tabs
  String get tabAdjust;
  String get tabStyle;
  String get tabMotion;
  String get tabCanvas;
  String get tabTiming;

  // Buttons / misc
  String get bringToFront;
  String get sendToBack;
  String get deleteLayer;
  String get changePhoto;
  String get crop;
  String get zoom;
  String get addPhotoShort;
  String get addTitleShort;
  String get addSubShort;
  String get typeMain;
  String get typeSubtitle;

  // Stroke labels
  String get strokeOff;
  String get strokeThin;
  String get strokeMed;
  String get strokeBold;

  // Shadow labels
  String get shadowNone;
  String get shadowSoft;
  String get shadowMedium;
  String get shadowStrong;

  // Spacing labels
  String get spacingNormal;
  String get spacingWide;
  String get spacingWider;
  String get spacingMax;

  // ── Settings ────────────────────────────────────────────────────────────
  String get settingsTitle;
  String get language;
  String get languageSubtitle;

  // ── Enum labels ───────────────────────────────────────────────────────────
  // Transition
  String get transitionFade;
  String get transitionSlideLeft;
  String get transitionSlideRight;
  String get transitionZoom;
  String get transitionKenBurns;
  String get transitionBlur;
  String get transitionWipeLeft;
  String get transitionWipeRight;
  String get transitionPushUp;
  String get transitionPushDown;
  String get transitionCircle;
  // Text color
  String get colorWhite;
  String get colorGold;
  String get colorCream;
  String get colorBlack;
  String get colorRose;
  String get colorSilver;
  String get colorChampagne;
  String get colorBlush;
  String get colorBlue;
  String get colorSage;
  String get colorLavender;
  String get colorGray;
  String get colorCoral;
  // Font style
  String get fontSerif;
  String get fontSans;
  String get fontScript;
  String get fontDisplay;
  String get fontElegant;
  String get fontModern;
  // Photo filter
  String get filterNone;
  String get filterWarm;
  String get filterCool;
  String get filterBw;
  String get filterVintage;
  String get filterDramatic;
  // Photo shape
  String get shapeNone;
  String get shapeRounded;
  String get shapeCircle;
  String get shapeHeart;
  String get shapeArch;
  // Photo frame
  String get frameNone;
  String get frameWhite;
  String get frameGold;
  String get framePolaroid;
  // Layout
  String get layoutSingle;
  String get layout2Photos;
  String get layout3Photos;
  // Content animation
  String get animNone;
  String get animTypewriter;
  String get animSlideUp;
  String get animSlideIn;
  String get animFadeIn;
  String get animFloat;
  String get animZoomPulse;
  String get animWipeReveal;
  String get animHandwriting;
  String get animShimmer;
  String get animDriftZoom;
  // Decorative frame
  String get secFrameStyle;
  String get frameStyleNone;
  String get frameStyleThin;
  String get frameStyleDouble;
  String get frameStyleBrackets;
  String get frameStyleEditorial;
  String get frameStyleInset;
  String get frameStyleDashed;
  String get frameStyleOrnate;
  // Ambient effects
  String get secAmbient;
  String get ambientNone;
  String get ambientPetalFall;
  String get ambientSparkle;
  String get ambientSnowFall;
  String get ambientHeartFloat;
  String get ambientGoldDust;
  String get ambientConfetti;
  String get ambientBokeh;
  String get ambientStars;
  String get ambientRibbon;
  String get ambientLightRays;
  // Stickers
  String get stickerPickPrompt;
  String get stickerKindLabel;
  String get stickerCatCharms;
  String get stickerCatHearts;
  String get stickerCatKeepsakes;
  String get stickerCatWedding;
  String get stickerStyle;
  String get stickerFilled;
  String get stickerLine;
  String get stickerOpacity;
  String get stickerHeart;
  String get stickerDoubleHeart;
  String get stickerRings;
  String get stickerRibbonBow;
  String get stickerBanner;
  String get stickerOliveBranch;
  String get stickerLeafSprig;
  String get stickerWreath;
  String get stickerRose;
  String get stickerSparkle;
  String get stickerStar;
  String get stickerFlourish;
  String get stickerCorner;
  String get stickerOval;
  String get stickerCrown;
  String get stickerChampagne;
  String get stickerDove;
  String get stickerArch;
  // Overlay
  String get overlayNone;
  String get overlayVignette;
  String get overlayGrain;
  String get overlayLightLeak;
  String get overlayBokeh;
  // Dim direction
  String get dimNone;
  String get dimBottom;
  String get dimTop;
  String get dimLeft;
  String get dimRight;
  String get dimRadial;
  // Text background
  String get textBgNone;
  String get textBgPill;
  String get textBgBox;
  // Templates
  String get templateBlank;
  String get templateOpening;
  String get templateMemory;
  String get templateLoveNote;
  String get templateClosing;
  String get templateBlankDesc;
  String get templateOpeningDesc;
  String get templateMemoryDesc;
  String get templateLoveNoteDesc;
  String get templateClosingDesc;
  // Template default content
  String get tplOurStory;
  String get tplAWeddingFilm;
  String get tplCherishedMoment;
  String get tplLoveQuote;
  String get tplForeverAlways;
}

// ════════════════════════════════════════════════════════════════════════════
// English
// ════════════════════════════════════════════════════════════════════════════

class _EnStrings extends AppStrings {
  const _EnStrings();

  @override String get cancel => 'Cancel';
  @override String get save => 'Save';
  @override String get delete => 'Delete';
  @override String get done => 'Done';
  @override String get create => 'Create';
  @override String get remove => 'Remove';
  @override String get reset => 'Reset';
  @override String get tryAgain => 'Try Again';
  @override String get discard => 'Discard';
  @override String get share => 'Share';

  @override String get appTagline => 'Capture your memories as film';

  @override String get loginHeroTitle => 'Create Beautiful\nMemory Films';
  @override String get loginHeroSubtitle => 'Sign in to start capturing memories.';
  @override String get email => 'Email';
  @override String get password => 'Password';
  @override String get signIn => 'Sign In';
  @override String get orDivider => 'or';
  @override String get signInWithGoogle => 'Sign in with Google';
  @override String get dontHaveAccount => "Don't have an account? ";
  @override String get register => 'Register';

  @override String get createAccountTitle => 'Create Your Account';
  @override String get registerSubtitle => 'Start capturing your memories today.';
  @override String get passwordHintRegister => 'At least 6 characters';
  @override String get confirmPassword => 'Confirm Password';
  @override String get createAccountButton => 'Create Account';
  @override String get passwordsDoNotMatch => 'Passwords do not match.';
  @override String get alreadyHaveAccount => 'Already have an account? ';

  @override String get errIncorrectCredentials => 'Incorrect email or password.';
  @override String get errEmailInUse => 'An account with this email already exists.';
  @override String get errWeakPassword => 'Password must be at least 6 characters.';
  @override String get errInvalidEmail => 'Please enter a valid email address.';
  @override String get errNetwork => 'Network error. Check your connection.';
  @override String get errTooManyRequests => 'Too many attempts. Please try again later.';
  @override String get errOperationNotAllowed => 'This sign-in method is not enabled. Contact the app admin.';
  @override String get errGoogleSignIn => 'Google Sign-In failed. Android SHA-1 fingerprint may need to be registered in Firebase Console.';
  @override String get errUnauthorizedDomain => 'This domain is not authorized for Google Sign-In. Add it in Firebase Console → Authentication → Authorized domains.';
  @override String get errGeneric => 'Something went wrong. Please try again.';

  @override String get welcomeBack => 'Welcome back';
  @override String get newFilm => 'New Film';
  @override String get quickActions => 'Quick Actions';
  @override String get tipsTitle => 'Tips for a Perfect Film';
  @override String get signOut => 'Sign Out';
  @override String get settings => 'Settings';
  @override String get myFilms => 'My Films';
  @override String get myFilmsSub => 'View & edit projects';
  @override String get newFilmSub => 'Start a new story';
  @override String get statFilms => 'Films';
  @override String get statSlides => 'Slides';
  @override String get tip1 => 'Choose photos that tell a story';
  @override String get tip2 => 'Add a meaningful song for emotion';
  @override String get tip3 => 'Use Ken Burns for cinematic feel';
  @override String get newWeddingFilm => 'New Memory Film';
  @override String get filmTitlePrompt => 'Give your film a title to remember';
  @override String get filmTitleHint => 'e.g. Summer Vacation 2024';
  @override String get videoFormat => 'Video format';
  @override String get formatLandscape => 'Landscape';
  @override String get formatPortrait => 'Portrait';
  @override String get formatLandscapeDesc => '16:9 · YouTube, TV';
  @override String get formatPortraitDesc => '9:16 · Reels, Shorts';

  @override String get myWeddingFilms => 'My Films';
  @override String get noFilmsYet => 'No films yet';
  @override String get noFilmsSub => 'Tap the button below to create\nyour first memory film';
  @override String get deleteFilmTitle => 'Delete Film?';
  @override String deleteFilmConfirm(String title) => '"$title" will be permanently deleted.';
  @override String get deleteSlideTitle => 'Delete Slide?';
  @override String get deleteSlideConfirm => 'This slide will be removed from your film.';
  @override String get today => 'Today';
  @override String get yesterday => 'Yesterday';
  @override String daysAgo(int n) => '$n days ago';
  @override String get musicBadge => 'Music';
  @override String slidesCount(int n) => '$n slides';

  @override String get exportFilm => 'Export Film';
  @override String get readyToExport => 'Ready to export';
  @override String get outputQuality => 'Output Quality';
  @override String get outputQualitySub => 'Choose the resolution for your exported video';
  @override String get recommended => 'Recommended';
  @override String get resHdDesc => 'Good for sharing on mobile';
  @override String get resFullHdDesc => 'Great for TV and displays';
  @override String get res4kDesc => 'Best for cinema-quality output';
  @override String get exportToMp4 => 'Export to MP4';
  @override String get exportSlideImages => 'Download Slide Images';
  @override String get webExportNote =>
      'Video is encoded in your browser — may take a few minutes.\nRequires Chrome 94+, Edge 94+, or Safari 16.4+.';
  @override String estimatedTime(int seconds) =>
      'Estimated time: about ${seconds}s\nReal-time rendering — same as your film length.';
  @override String get savedToGallery => 'Video will be saved to your device gallery';
  @override String get renderingTitle => 'Rendering your film';
  @override String get phaseCapturing => 'Capturing frames…';
  @override String get phaseCompositing => 'Compositing slides…';
  @override String get phaseEncoding => 'Encoding to MP4…';
  @override String get phaseSaving => 'Saving to gallery…';
  @override String get doneLabel => 'done';
  @override String get cancelExport => 'Cancel Export';
  @override String get exportComplete => 'Export Complete!';
  @override String get exportCompleteSub => 'Your film has been saved to your gallery';
  @override String get doneButton => 'Done';
  @override String get exportAgain => 'Export Again';
  @override String get exportFailed => 'Export Failed';
  @override String get exportFailedDefault => 'An unexpected error occurred.';
  @override String get noSlidesToExport => 'No slides to export.';
  @override String get shareError => 'Could not open the share sheet.';
  @override String durationLabel(int seconds) =>
      seconds >= 60 ? '${seconds ~/ 60}m ${seconds % 60}s' : '${seconds}s';

  @override String get untitledFilm => 'Untitled Film';
  @override String get unsavedChanges => 'Unsaved Changes';
  @override String get saveBeforeLeaving => 'Save your film before leaving?';
  @override String get preview => 'Preview';
  @override String get export => 'Export';
  @override String get noSlides => 'No slides';
  @override String get tabSlide => 'Slide';
  @override String get tabPhoto => 'Photo';
  @override String get tabText => 'Text';
  @override String get tabSticker => 'Sticker';
  @override String get tabMusic => 'Music';
  @override String get noPhotoSelected => 'No photo selected';
  @override String get tapPhotoHint => 'Tap a photo in the canvas above';
  @override String get addPhotoBtn => '+ Add Photo';
  @override String get noTextSelected => 'No text selected';
  @override String get tapTextHint => 'Tap a text layer in the canvas above';
  @override String get addTitleBtn => '+ Title';
  @override String get addSubtitleBtn => '+ Subtitle';
  @override String get chooseTemplate => 'Choose a Template';
  @override String get templateSub => 'Start with a pre-designed layout';
  @override String get saveTooltip => 'Save';
  @override String get enterText => 'Enter text…';
  @override String get tapAddText => 'Tap "+ Main" or "+ Sub" to add text';
  @override String get dragPinchZoom => 'drag · pinch to zoom';
  @override String get dragPanPinchZoom => 'Drag on photo to pan · Pinch to zoom';

  @override String get secBackground => 'Background';
  @override String get secDim => 'Dim';
  @override String get secPhotoZoom => 'Photo Zoom';
  @override String get secFilter => 'Filter';
  @override String get secOverlay => 'Overlay';
  @override String get secPhotoShape => 'Photo Shape';
  @override String get secPhotoFrame => 'Photo Frame';
  @override String get secTransition => 'Transition';
  @override String get secDuration => 'Duration';
  @override String get secShape => 'Shape';
  @override String get secFrame => 'Frame';
  @override String get secPhotoLayer => 'Photo Layer';
  @override String get secMainLayer => 'Main Layer';
  @override String get secSubtitleLayer => 'Subtitle Layer';
  @override String get secType => 'Type';
  @override String get secFont => 'Font';
  @override String get secSize => 'Size';
  @override String get secTextColor => 'Text Color';
  @override String get secBarColor => 'Bar Color';
  @override String get secTextBg => 'Text Bg';
  @override String get secOutline => 'Outline';
  @override String get secShadow => 'Shadow';
  @override String get secSpacing => 'Spacing';
  @override String get secRotation => 'Rotation';
  @override String get secAnimation => 'Animation';
  @override String get secWidth => 'Width';
  @override String get secHeight => 'Height';

  @override String get tabAdjust => 'Adjust';
  @override String get tabStyle => 'Style';
  @override String get tabMotion => 'Motion';
  @override String get tabCanvas => 'Canvas';
  @override String get tabTiming => 'Timing';

  @override String get bringToFront => 'Bring to front';
  @override String get sendToBack => 'Send to back';
  @override String get deleteLayer => 'Delete Layer';
  @override String get changePhoto => 'Change Photo';
  @override String get crop => 'Crop';
  @override String get zoom => 'Zoom';
  @override String get addPhotoShort => 'Photo';
  @override String get addTitleShort => 'Title';
  @override String get addSubShort => 'Sub';
  @override String get typeMain => 'Main';
  @override String get typeSubtitle => 'Subtitle';

  @override String get strokeOff => 'Off';
  @override String get strokeThin => 'Thin';
  @override String get strokeMed => 'Med';
  @override String get strokeBold => 'Bold';

  @override String get shadowNone => 'None';
  @override String get shadowSoft => 'Soft';
  @override String get shadowMedium => 'Medium';
  @override String get shadowStrong => 'Strong';

  @override String get spacingNormal => 'Normal';
  @override String get spacingWide => 'Wide';
  @override String get spacingWider => 'Wider';
  @override String get spacingMax => 'Max';

  @override String get settingsTitle => 'Settings';
  @override String get language => 'Language';
  @override String get languageSubtitle => 'Choose your preferred language';

  @override String get transitionFade => 'Fade';
  @override String get transitionSlideLeft => 'Slide ←';
  @override String get transitionSlideRight => 'Slide →';
  @override String get transitionZoom => 'Zoom';
  @override String get transitionKenBurns => 'Ken Burns';
  @override String get transitionBlur => 'Blur';
  @override String get transitionWipeLeft => 'Wipe ←';
  @override String get transitionWipeRight => 'Wipe →';
  @override String get transitionPushUp => 'Push ↑';
  @override String get transitionPushDown => 'Push ↓';
  @override String get transitionCircle => 'Circle';

  @override String get colorWhite => 'White';
  @override String get colorGold => 'Gold';
  @override String get colorCream => 'Cream';
  @override String get colorBlack => 'Black';
  @override String get colorRose => 'Rose';
  @override String get colorSilver => 'Silver';
  @override String get colorChampagne => 'Champagne';
  @override String get colorBlush => 'Blush';
  @override String get colorBlue => 'Blue';
  @override String get colorSage => 'Sage';
  @override String get colorLavender => 'Lavender';
  @override String get colorGray => 'Gray';
  @override String get colorCoral => 'Coral';

  @override String get fontSerif => 'Serif';
  @override String get fontSans => 'Sans';
  @override String get fontScript => 'Script';
  @override String get fontDisplay => 'Display';
  @override String get fontElegant => 'Elegant';
  @override String get fontModern => 'Modern';

  @override String get filterNone => 'None';
  @override String get filterWarm => 'Warm';
  @override String get filterCool => 'Cool';
  @override String get filterBw => 'B&W';
  @override String get filterVintage => 'Vintage';
  @override String get filterDramatic => 'Dramatic';

  @override String get shapeNone => 'None';
  @override String get shapeRounded => 'Rounded';
  @override String get shapeCircle => 'Circle';
  @override String get shapeHeart => 'Heart';
  @override String get shapeArch => 'Arch';

  @override String get frameNone => 'None';
  @override String get frameWhite => 'White';
  @override String get frameGold => 'Gold';
  @override String get framePolaroid => 'Polaroid';

  @override String get layoutSingle => 'Single';
  @override String get layout2Photos => '2 Photos';
  @override String get layout3Photos => '3 Photos';

  @override String get animNone => 'None';
  @override String get animTypewriter => 'Typewriter';
  @override String get animSlideUp => 'Slide Up';
  @override String get animSlideIn => 'Slide In';
  @override String get animFadeIn => 'Fade In';
  @override String get animFloat => 'Float';
  @override String get animZoomPulse => 'Zoom Pulse';
  @override String get animWipeReveal => 'Wipe Reveal';
  @override String get animHandwriting => 'Handwriting';
  @override String get animShimmer => 'Shimmer';
  @override String get animDriftZoom => 'Drift Zoom';
  @override String get secFrameStyle => 'Frame';
  @override String get frameStyleNone => 'None';
  @override String get frameStyleThin => 'Thin';
  @override String get frameStyleDouble => 'Double';
  @override String get frameStyleBrackets => 'Brackets';
  @override String get frameStyleEditorial => 'Editorial';
  @override String get frameStyleInset => 'Inset';
  @override String get frameStyleDashed => 'Dashed';
  @override String get frameStyleOrnate => 'Ornate';
  @override String get secAmbient => 'Ambient FX';
  @override String get ambientNone => 'None';
  @override String get ambientPetalFall => 'Petals';
  @override String get ambientSparkle => 'Sparkle';
  @override String get ambientSnowFall => 'Snow';
  @override String get ambientHeartFloat => 'Hearts';
  @override String get ambientGoldDust => 'Gold Dust';
  @override String get ambientConfetti => 'Confetti';
  @override String get ambientBokeh => 'Bokeh';
  @override String get ambientStars => 'Stars';
  @override String get ambientRibbon => 'Ribbons';
  @override String get ambientLightRays => 'Light Rays';

  @override String get stickerPickPrompt => 'Choose a sticker';
  @override String get stickerKindLabel => 'Sticker';
  @override String get stickerCatCharms => 'Charms';
  @override String get stickerCatHearts => 'Hearts';
  @override String get stickerCatKeepsakes => 'Keepsakes';
  @override String get stickerCatWedding => 'Wedding';
  @override String get stickerStyle => 'Style';
  @override String get stickerFilled => 'Filled';
  @override String get stickerLine => 'Line art';
  @override String get stickerOpacity => 'Opacity';
  @override String get stickerHeart => 'Heart';
  @override String get stickerDoubleHeart => 'Two Hearts';
  @override String get stickerRings => 'Rings';
  @override String get stickerRibbonBow => 'Bow';
  @override String get stickerBanner => 'Banner';
  @override String get stickerOliveBranch => 'Olive Branch';
  @override String get stickerLeafSprig => 'Leaf Sprig';
  @override String get stickerWreath => 'Wreath';
  @override String get stickerRose => 'Rose';
  @override String get stickerSparkle => 'Sparkle';
  @override String get stickerStar => 'Star';
  @override String get stickerFlourish => 'Flourish';
  @override String get stickerCorner => 'Corner';
  @override String get stickerOval => 'Oval Frame';
  @override String get stickerCrown => 'Crown';
  @override String get stickerChampagne => 'Champagne';
  @override String get stickerDove => 'Dove';
  @override String get stickerArch => 'Arch';

  @override String get overlayNone => 'None';
  @override String get overlayVignette => 'Vignette';
  @override String get overlayGrain => 'Grain';
  @override String get overlayLightLeak => 'Light Leak';
  @override String get overlayBokeh => 'Bokeh';

  @override String get dimNone => 'None';
  @override String get dimBottom => 'Bottom';
  @override String get dimTop => 'Top';
  @override String get dimLeft => 'Left';
  @override String get dimRight => 'Right';
  @override String get dimRadial => 'Radial';

  @override String get textBgNone => 'None';
  @override String get textBgPill => 'Pill';
  @override String get textBgBox => 'Box';

  @override String get templateBlank => 'Blank';
  @override String get templateOpening => 'Opening';
  @override String get templateMemory => 'Memory';
  @override String get templateLoveNote => 'Love Note';
  @override String get templateClosing => 'Closing';
  @override String get templateBlankDesc => 'Start from scratch';
  @override String get templateOpeningDesc => 'Bold title card';
  @override String get templateMemoryDesc => 'Photo with caption';
  @override String get templateLoveNoteDesc => 'Centered quote';
  @override String get templateClosingDesc => 'Elegant ending card';

  @override String get tplOurStory => 'Our Story';
  @override String get tplAWeddingFilm => 'A Memory Film';
  @override String get tplCherishedMoment => 'A cherished moment';
  @override String get tplLoveQuote => '"You are my greatest adventure"';
  @override String get tplForeverAlways => 'Forever & Always';
}

// ════════════════════════════════════════════════════════════════════════════
// Korean
// ════════════════════════════════════════════════════════════════════════════

class _KoStrings extends AppStrings {
  const _KoStrings();

  @override String get cancel => '취소';
  @override String get save => '저장';
  @override String get delete => '삭제';
  @override String get done => '완료';
  @override String get create => '만들기';
  @override String get remove => '제거';
  @override String get reset => '초기화';
  @override String get tryAgain => '다시 시도';
  @override String get discard => '저장 안 함';
  @override String get share => '공유';

  @override String get appTagline => '당신의 추억을 영상으로 담아보세요';

  @override String get loginHeroTitle => '아름다운\n추억 영상 만들기';
  @override String get loginHeroSubtitle => '로그인하고 소중한 추억을 기록하세요.';
  @override String get email => '이메일';
  @override String get password => '비밀번호';
  @override String get signIn => '로그인';
  @override String get orDivider => '또는';
  @override String get signInWithGoogle => 'Google로 로그인';
  @override String get dontHaveAccount => '계정이 없으신가요? ';
  @override String get register => '회원가입';

  @override String get createAccountTitle => '계정 만들기';
  @override String get registerSubtitle => '오늘부터 소중한 추억을 기록해보세요.';
  @override String get passwordHintRegister => '6자 이상';
  @override String get confirmPassword => '비밀번호 확인';
  @override String get createAccountButton => '계정 만들기';
  @override String get passwordsDoNotMatch => '비밀번호가 일치하지 않습니다.';
  @override String get alreadyHaveAccount => '이미 계정이 있으신가요? ';

  @override String get errIncorrectCredentials => '이메일 또는 비밀번호가 올바르지 않습니다.';
  @override String get errEmailInUse => '이미 이 이메일로 가입된 계정이 있습니다.';
  @override String get errWeakPassword => '비밀번호는 6자 이상이어야 합니다.';
  @override String get errInvalidEmail => '올바른 이메일 주소를 입력해 주세요.';
  @override String get errNetwork => '네트워크 오류입니다. 연결을 확인해 주세요.';
  @override String get errTooManyRequests => '시도가 너무 많습니다. 잠시 후 다시 시도해 주세요.';
  @override String get errOperationNotAllowed => '이 로그인 방식은 사용할 수 없습니다. 관리자에게 문의하세요.';
  @override String get errGoogleSignIn => 'Google 로그인에 실패했습니다. Firebase Console에 Android SHA-1 지문 등록이 필요할 수 있습니다.';
  @override String get errUnauthorizedDomain => '이 도메인은 Google 로그인이 허용되지 않습니다. Firebase Console → Authentication → 승인된 도메인에 추가해 주세요.';
  @override String get errGeneric => '문제가 발생했습니다. 다시 시도해 주세요.';

  @override String get welcomeBack => '다시 오신 걸 환영해요';
  @override String get newFilm => '새 영상';
  @override String get quickActions => '빠른 작업';
  @override String get tipsTitle => '완벽한 영상을 위한 팁';
  @override String get signOut => '로그아웃';
  @override String get settings => '설정';
  @override String get myFilms => '내 영상';
  @override String get myFilmsSub => '프로젝트 보기 및 편집';
  @override String get newFilmSub => '새로운 이야기 시작';
  @override String get statFilms => '영상';
  @override String get statSlides => '슬라이드';
  @override String get tip1 => '이야기가 담긴 사진을 골라보세요';
  @override String get tip2 => '감동을 더할 의미 있는 음악을 넣어보세요';
  @override String get tip3 => '켄 번스 효과로 영화 같은 느낌을 더하세요';
  @override String get newWeddingFilm => '새 추억 영상';
  @override String get filmTitlePrompt => '기억하기 좋은 영상 제목을 지어주세요';
  @override String get filmTitleHint => '예: 2024 여름 휴가';
  @override String get videoFormat => '영상 형식';
  @override String get formatLandscape => '가로';
  @override String get formatPortrait => '세로';
  @override String get formatLandscapeDesc => '16:9 · 유튜브, TV';
  @override String get formatPortraitDesc => '9:16 · 릴스, 쇼츠';

  @override String get myWeddingFilms => '내 영상';
  @override String get noFilmsYet => '아직 영상이 없어요';
  @override String get noFilmsSub => '아래 버튼을 눌러\n첫 번째 추억 영상을 만들어보세요';
  @override String get deleteFilmTitle => '영상을 삭제할까요?';
  @override String deleteFilmConfirm(String title) => '"$title"이(가) 영구적으로 삭제됩니다.';
  @override String get deleteSlideTitle => '슬라이드를 삭제할까요?';
  @override String get deleteSlideConfirm => '이 슬라이드가 영상에서 제거됩니다.';
  @override String get today => '오늘';
  @override String get yesterday => '어제';
  @override String daysAgo(int n) => '$n일 전';
  @override String get musicBadge => '음악';
  @override String slidesCount(int n) => '슬라이드 $n개';

  @override String get exportFilm => '영상 내보내기';
  @override String get readyToExport => '내보낼 준비 완료';
  @override String get outputQuality => '출력 화질';
  @override String get outputQualitySub => '내보낼 영상의 해상도를 선택하세요';
  @override String get recommended => '추천';
  @override String get resHdDesc => '모바일 공유에 적합';
  @override String get resFullHdDesc => 'TV와 디스플레이에 적합';
  @override String get res4kDesc => '영화급 화질에 최적';
  @override String get exportToMp4 => 'MP4로 내보내기';
  @override String get exportSlideImages => '슬라이드 이미지 다운로드';
  @override String get webExportNote =>
      '브라우저에서 직접 영상을 인코딩합니다 — 몇 분 정도 소요될 수 있습니다.\nChrome 94+, Edge 94+, Safari 16.4+ 이상 필요합니다.';
  @override String estimatedTime(int seconds) =>
      '예상 소요 시간: 약 $seconds초\n실시간 렌더링으로 영상 길이와 동일합니다.';
  @override String get savedToGallery => '영상이 기기 갤러리에 저장됩니다';
  @override String get renderingTitle => '영상을 렌더링하는 중';
  @override String get phaseCapturing => '프레임 캡처 중…';
  @override String get phaseCompositing => '슬라이드 합성 중…';
  @override String get phaseEncoding => 'MP4로 인코딩 중…';
  @override String get phaseSaving => '갤러리에 저장 중…';
  @override String get doneLabel => '완료';
  @override String get cancelExport => '내보내기 취소';
  @override String get exportComplete => '내보내기 완료!';
  @override String get exportCompleteSub => '영상이 갤러리에 저장되었습니다';
  @override String get doneButton => '완료';
  @override String get exportAgain => '다시 내보내기';
  @override String get exportFailed => '내보내기 실패';
  @override String get exportFailedDefault => '예기치 않은 오류가 발생했습니다.';
  @override String get noSlidesToExport => '내보낼 슬라이드가 없습니다.';
  @override String get shareError => '공유 시트를 열 수 없습니다.';
  @override String durationLabel(int seconds) =>
      seconds >= 60 ? '${seconds ~/ 60}분 ${seconds % 60}초' : '$seconds초';

  @override String get untitledFilm => '제목 없는 영상';
  @override String get unsavedChanges => '저장되지 않은 변경사항';
  @override String get saveBeforeLeaving => '나가기 전에 영상을 저장할까요?';
  @override String get preview => '미리보기';
  @override String get export => '내보내기';
  @override String get noSlides => '슬라이드 없음';
  @override String get tabSlide => '슬라이드';
  @override String get tabPhoto => '사진';
  @override String get tabText => '텍스트';
  @override String get tabSticker => '스티커';
  @override String get tabMusic => '음악';
  @override String get noPhotoSelected => '선택된 사진 없음';
  @override String get tapPhotoHint => '위 캔버스에서 사진을 탭하세요';
  @override String get addPhotoBtn => '+ 사진 추가';
  @override String get noTextSelected => '선택된 텍스트 없음';
  @override String get tapTextHint => '위 캔버스에서 텍스트를 탭하세요';
  @override String get addTitleBtn => '+ 제목';
  @override String get addSubtitleBtn => '+ 자막';
  @override String get chooseTemplate => '템플릿 선택';
  @override String get templateSub => '미리 디자인된 레이아웃으로 시작하세요';
  @override String get saveTooltip => '저장';
  @override String get enterText => '텍스트 입력…';
  @override String get tapAddText => '"+ 제목" 또는 "+ 자막"을 눌러 텍스트를 추가하세요';
  @override String get dragPinchZoom => '드래그·핀치로 확대';
  @override String get dragPanPinchZoom => '사진을 드래그해 이동 · 핀치로 확대';

  @override String get secBackground => '배경';
  @override String get secDim => '어둡게';
  @override String get secPhotoZoom => '사진 확대';
  @override String get secFilter => '필터';
  @override String get secOverlay => '오버레이';
  @override String get secPhotoShape => '사진 모양';
  @override String get secPhotoFrame => '사진 프레임';
  @override String get secTransition => '전환';
  @override String get secDuration => '길이';
  @override String get secShape => '모양';
  @override String get secFrame => '프레임';
  @override String get secPhotoLayer => '사진 레이어';
  @override String get secMainLayer => '메인 레이어';
  @override String get secSubtitleLayer => '자막 레이어';
  @override String get secType => '종류';
  @override String get secFont => '글꼴';
  @override String get secSize => '크기';
  @override String get secTextColor => '텍스트 색상';
  @override String get secBarColor => '바 색상';
  @override String get secTextBg => '텍스트 배경';
  @override String get secOutline => '외곽선';
  @override String get secShadow => '그림자';
  @override String get secSpacing => '자간';
  @override String get secRotation => '회전';
  @override String get secAnimation => '애니메이션';
  @override String get secWidth => '너비';
  @override String get secHeight => '높이';

  @override String get tabAdjust => '조정';
  @override String get tabStyle => '스타일';
  @override String get tabMotion => '모션';
  @override String get tabCanvas => '캔버스';
  @override String get tabTiming => '타이밍';

  @override String get bringToFront => '맨 앞으로';
  @override String get sendToBack => '맨 뒤로';
  @override String get deleteLayer => '레이어 삭제';
  @override String get changePhoto => '사진 변경';
  @override String get crop => '자르기';
  @override String get zoom => '확대';
  @override String get addPhotoShort => '사진';
  @override String get addTitleShort => '제목';
  @override String get addSubShort => '자막';
  @override String get typeMain => '제목';
  @override String get typeSubtitle => '자막';

  @override String get strokeOff => '없음';
  @override String get strokeThin => '얇게';
  @override String get strokeMed => '보통';
  @override String get strokeBold => '굵게';

  @override String get shadowNone => '없음';
  @override String get shadowSoft => '약하게';
  @override String get shadowMedium => '보통';
  @override String get shadowStrong => '강하게';

  @override String get spacingNormal => '기본';
  @override String get spacingWide => '넓게';
  @override String get spacingWider => '더 넓게';
  @override String get spacingMax => '최대';

  @override String get settingsTitle => '설정';
  @override String get language => '언어';
  @override String get languageSubtitle => '사용할 언어를 선택하세요';

  @override String get transitionFade => '페이드';
  @override String get transitionSlideLeft => '슬라이드 ←';
  @override String get transitionSlideRight => '슬라이드 →';
  @override String get transitionZoom => '줌';
  @override String get transitionKenBurns => '켄 번스';
  @override String get transitionBlur => '블러';
  @override String get transitionWipeLeft => '와이프 ←';
  @override String get transitionWipeRight => '와이프 →';
  @override String get transitionPushUp => '밀기 ↑';
  @override String get transitionPushDown => '밀기 ↓';
  @override String get transitionCircle => '원형';

  @override String get colorWhite => '화이트';
  @override String get colorGold => '골드';
  @override String get colorCream => '크림';
  @override String get colorBlack => '블랙';
  @override String get colorRose => '로즈';
  @override String get colorSilver => '실버';
  @override String get colorChampagne => '샴페인';
  @override String get colorBlush => '블러시';
  @override String get colorBlue => '블루';
  @override String get colorSage => '세이지';
  @override String get colorLavender => '라벤더';
  @override String get colorGray => '그레이';
  @override String get colorCoral => '코랄';

  @override String get fontSerif => '세리프';
  @override String get fontSans => '산세리프';
  @override String get fontScript => '필기체';
  @override String get fontDisplay => '디스플레이';
  @override String get fontElegant => '우아한';
  @override String get fontModern => '모던';

  @override String get filterNone => '없음';
  @override String get filterWarm => '따뜻하게';
  @override String get filterCool => '차갑게';
  @override String get filterBw => '흑백';
  @override String get filterVintage => '빈티지';
  @override String get filterDramatic => '드라마틱';

  @override String get shapeNone => '없음';
  @override String get shapeRounded => '둥글게';
  @override String get shapeCircle => '원형';
  @override String get shapeHeart => '하트';
  @override String get shapeArch => '아치';

  @override String get frameNone => '없음';
  @override String get frameWhite => '화이트';
  @override String get frameGold => '골드';
  @override String get framePolaroid => '폴라로이드';

  @override String get layoutSingle => '단일';
  @override String get layout2Photos => '사진 2장';
  @override String get layout3Photos => '사진 3장';

  @override String get animNone => '없음';
  @override String get animTypewriter => '타자기';
  @override String get animSlideUp => '위로 슬라이드';
  @override String get animSlideIn => '슬라이드 인';
  @override String get animFadeIn => '페이드 인';
  @override String get animFloat => '떠오르기';
  @override String get animZoomPulse => '줌 펄스';
  @override String get animWipeReveal => '와이프';
  @override String get animHandwriting => '필기 쓰기';
  @override String get animShimmer => '반짝임';
  @override String get animDriftZoom => '드리프트 줌';
  @override String get secFrameStyle => '프레임';
  @override String get frameStyleNone => '없음';
  @override String get frameStyleThin => '얇은 선';
  @override String get frameStyleDouble => '이중 선';
  @override String get frameStyleBrackets => '모서리';
  @override String get frameStyleEditorial => '에디토리얼';
  @override String get frameStyleInset => '안쪽 선';
  @override String get frameStyleDashed => '점선';
  @override String get frameStyleOrnate => '장식';
  @override String get secAmbient => '앰비언트 FX';
  @override String get ambientNone => '없음';
  @override String get ambientPetalFall => '꽃잎 낙하';
  @override String get ambientSparkle => '반짝임';
  @override String get ambientSnowFall => '눈송이';
  @override String get ambientHeartFloat => '하트';
  @override String get ambientGoldDust => '골드 더스트';
  @override String get ambientConfetti => '컨페티';
  @override String get ambientBokeh => '보케';
  @override String get ambientStars => '별 반짝임';
  @override String get ambientRibbon => '리본';
  @override String get ambientLightRays => '빛 줄기';

  @override String get stickerPickPrompt => '스티커 선택';
  @override String get stickerKindLabel => '스티커';
  @override String get stickerCatCharms => '참 & 오브제';
  @override String get stickerCatHearts => '하트';
  @override String get stickerCatKeepsakes => '소품';
  @override String get stickerCatWedding => '웨딩';
  @override String get stickerStyle => '스타일';
  @override String get stickerFilled => '채움';
  @override String get stickerLine => '선화';
  @override String get stickerOpacity => '투명도';
  @override String get stickerHeart => '하트';
  @override String get stickerDoubleHeart => '두 하트';
  @override String get stickerRings => '반지';
  @override String get stickerRibbonBow => '리본';
  @override String get stickerBanner => '배너';
  @override String get stickerOliveBranch => '올리브 가지';
  @override String get stickerLeafSprig => '잎사귀';
  @override String get stickerWreath => '화환';
  @override String get stickerRose => '장미';
  @override String get stickerSparkle => '반짝임';
  @override String get stickerStar => '별';
  @override String get stickerFlourish => '장식선';
  @override String get stickerCorner => '코너 장식';
  @override String get stickerOval => '타원 프레임';
  @override String get stickerCrown => '왕관';
  @override String get stickerChampagne => '샴페인';
  @override String get stickerDove => '비둘기';
  @override String get stickerArch => '아치';

  @override String get overlayNone => '없음';
  @override String get overlayVignette => '비네트';
  @override String get overlayGrain => '그레인';
  @override String get overlayLightLeak => '라이트 리크';
  @override String get overlayBokeh => '보케';

  @override String get dimNone => '없음';
  @override String get dimBottom => '아래';
  @override String get dimTop => '위';
  @override String get dimLeft => '왼쪽';
  @override String get dimRight => '오른쪽';
  @override String get dimRadial => '원형';

  @override String get textBgNone => '없음';
  @override String get textBgPill => '알약';
  @override String get textBgBox => '박스';

  @override String get templateBlank => '빈 슬라이드';
  @override String get templateOpening => '오프닝';
  @override String get templateMemory => '추억';
  @override String get templateLoveNote => '러브 노트';
  @override String get templateClosing => '엔딩';
  @override String get templateBlankDesc => '처음부터 시작';
  @override String get templateOpeningDesc => '강렬한 타이틀';
  @override String get templateMemoryDesc => '사진과 캡션';
  @override String get templateLoveNoteDesc => '가운데 정렬 문구';
  @override String get templateClosingDesc => '우아한 엔딩 카드';

  @override String get tplOurStory => '우리 이야기';
  @override String get tplAWeddingFilm => '추억 영상';
  @override String get tplCherishedMoment => '소중한 순간';
  @override String get tplLoveQuote => '"당신은 나의 가장 큰 모험"';
  @override String get tplForeverAlways => '영원히 함께';
}
