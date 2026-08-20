import 'dart:io';

class ApiConfig {
  // Backend dev server's address on the LAN, port 5050 (5000 collides with
  // macOS AirPlay Receiver). This must match the machine running `npm run dev`.
  // - Physical Android device: the machine's LAN IP (below) — phone and
  //   machine must be on the same Wi-Fi network.
  // - Android emulator over USB: use 127.0.0.1 with `adb reverse`.
  static const String _host = '127.0.0.1';
  static const int _port = 5050;

  static String get baseUrl {
    if (Platform.isAndroid) return 'http://$_host:$_port/api';
    return 'http://localhost:$_port/api';
  }

  static String get mediaBaseUrl {
    if (Platform.isAndroid) return 'http://$_host:$_port';
    return 'http://localhost:$_port';
  }
}
