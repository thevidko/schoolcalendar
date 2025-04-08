import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String stagCallbackUrlScheme = "schoolcalendarapp";
const String stagCallbackUrlHost = "stag-login-callback";
const String stagCallbackUrl = "$stagCallbackUrlScheme://$stagCallbackUrlHost";

// STAG login URL
const String stagLoginBaseUrl =
    "https://stagws.uhk.cz/ws/login"; // UNIVERZITA HRADEC KRÁLOVÉ

class StagLoginScreen extends StatefulWidget {
  const StagLoginScreen({super.key});

  @override
  State<StagLoginScreen> createState() => _StagLoginScreenState();
}

class _StagLoginScreenState extends State<StagLoginScreen> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? _webViewController;
  final CookieManager _cookieManager = CookieManager.instance();
  final _secureStorage = const FlutterSecureStorage();
  bool _isLoading = true;
  double _progress = 0;

  // URL pro webview
  late Uri _stagLoginUrl;

  @override
  void initState() {
    super.initState();
    // Sestavení URL pro přihlášení STAG
    _stagLoginUrl = Uri.parse("$stagLoginBaseUrl?originalURL=$stagCallbackUrl");
    print("Navigating to STAG login: $_stagLoginUrl");
  }

  Future<void> _storeCredentials(
    String ticket,
    String? osCislo,
    String? userName,
  ) async {
    await _secureStorage.write(key: 'stag_user_ticket', value: ticket);

    // Preferujeme osCislo, pokud existuje, jinak userName
    final studentIdentifier = osCislo ?? userName;
    if (studentIdentifier != null) {
      await _secureStorage.write(
        key: 'stag_student_identifier',
        value: studentIdentifier,
      );
      print(
        "STAG Ticket and Identifier ($studentIdentifier) stored successfully.",
      );
    } else {
      print(
        "STAG Ticket stored, but student identifier (osCislo/userName) not found in userInfo.",
      );
      // Můžete zde případně smazat jen identifikátor, pokud už tam byl
      await _secureStorage.delete(key: 'stag_student_identifier');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Přihlášení IS/STAG'),
        // Volitelně tlačítko pro zavření, pokud by se uživatel zasekl
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed:
              () => Navigator.of(
                context,
              ).pop(false), // Vrací false = neúspěch/zrušeno
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            key: webViewKey,
            initialUrlRequest: URLRequest(url: WebUri.uri(_stagLoginUrl)),
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading: true, // Povolí zachytávání navigace
              mediaPlaybackRequiresUserGesture: false,
              javaScriptEnabled: true,
              transparentBackground: true,
              //clearCache: true, //Mazání cache, v případě vyžádání opětovného přihlášení každý import
            ),
            onWebViewCreated: (controller) async {
              _webViewController = controller;
              await controller.loadUrl(
                urlRequest: URLRequest(url: WebUri.uri(_stagLoginUrl)),
              );
            },
            // Zachytávání pokusů o navigaci
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url;
              if (uri != null &&
                  uri.scheme == stagCallbackUrlScheme &&
                  uri.host == stagCallbackUrlHost) {
                print("Callback URL intercepted!");
                final ticket = uri.queryParameters['stagUserTicket'];
                final userInfoBase64 = uri.queryParameters['stagUserInfo'];
                String? osCislo;
                String? userName;

                // Dekódování a parsování userInfo pro získání osCislo/userName
                if (userInfoBase64 != null) {
                  try {
                    final userInfoJson = utf8.decode(
                      base64Url.decode(userInfoBase64),
                    );
                    final userInfo = jsonDecode(userInfoJson);
                    print("User Info Decoded: $userInfo");
                    // Získání osCislo nebo userName z první položky pole stagUserInfo
                    if (userInfo != null &&
                        userInfo['stagUserInfo'] is List &&
                        (userInfo['stagUserInfo'] as List).isNotEmpty) {
                      final stagInfo = (userInfo['stagUserInfo'] as List).first;
                      osCislo = stagInfo['osCislo']; // nullable
                      userName = stagInfo['userName']; // nullable
                    }
                  } catch (e) {
                    print("Error decoding or parsing stagUserInfo: $e");
                  }
                }

                if (ticket != null && ticket.isNotEmpty) {
                  print("Ticket found: $ticket");
                  // Uložíme ticket A identifikátor studenta
                  await _storeCredentials(ticket, osCislo, userName);
                  if (mounted) Navigator.of(context).pop(true); // úspěch
                  return NavigationActionPolicy.CANCEL;
                } else {
                  print("Callback received, but ticket is null or empty.");
                  // Pokud ticket není, nemá smysl ukládat ani identifikátor
                  await _secureStorage.delete(key: 'stag_user_ticket');
                  await _secureStorage.delete(key: 'stag_student_identifier');
                  if (mounted) Navigator.of(context).pop(false);
                  return NavigationActionPolicy.CANCEL;
                }
              }
              return NavigationActionPolicy.ALLOW;
            },

            onLoadStart: (controller, url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
              }
            },
            onLoadStop: (controller, url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onProgressChanged: (controller, progress) {
              if (mounted) {
                setState(() {
                  _progress = progress / 100;
                });
              }
            },
            onLoadError: (controller, request, errorType, description) {
              print("WebView Load Error: $description");
              // Můžete zobrazit chybovou zprávu uživateli
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Chyba načítání: $description')),
                );
                // Možná zavřít obrazovku po chybě
                // Navigator.of(context).pop(false);
              }
            },
          ),
          // Zobrazení indikátoru načítání
          if (_isLoading)
            LinearProgressIndicator(value: _progress > 0 ? _progress : null),
        ],
      ),
    );
  }
}
