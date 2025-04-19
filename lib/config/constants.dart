class AppConstants {
  // Callback URL Scheme
  static const String stagCallbackUrlScheme = "schoolcalendarapp";
  static const String stagCallbackUrlHost = "stag-login-callback";
  static const String stagCallbackUrl =
      "$stagCallbackUrlScheme://$stagCallbackUrlHost";

  // STAG login URL
  static const String stagLoginBaseUrl =
      "https://stagws.uhk.cz/ws/login"; // UNIVERZITA HRADEC KRÁLOVÉ
  static const String baseUrl = "stagws.uhk.cz"; //UNIVERZITA HRADEC KRÁLOVÉ
  static const String basePath = "/ws/services/rest2";
}
