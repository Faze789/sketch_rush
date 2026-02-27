class AppConstants {
  AppConstants._();

  static const String appName = 'SketchRush';
  static const String appVersion = '1.0.0';

  // SharedPreferences keys
  static const String keyDisplayName = 'display_name';
  static const String keyAvatarIndex = 'avatar_index';
  static const String keyAvatarColor = 'avatar_color';

  // Avatar options
  static const int avatarCount = 12;
  static const List<String> defaultAvatarColors = [
    '#6C5CE7',
    '#00B894',
    '#FDCB6E',
    '#E17055',
    '#0984E3',
    '#E84393',
    '#00CEC9',
    '#FF7675',
    '#74B9FF',
    '#A29BFE',
    '#55EFC4',
    '#FAB1A0',
  ];
}
