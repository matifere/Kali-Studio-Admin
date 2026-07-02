// ignore_for_file: avoid_print
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  try {
    await dotenv.load(fileName: "non_existent.env");
  } catch (e) {
    print("Caught load error: $e");
  }

  try {
    print("Trying to access URL");
    final url = dotenv.env['URL'] ?? '';
    print("URL is: $url");
  } catch (e) {
    print("Caught env error: $e");
  }
}
