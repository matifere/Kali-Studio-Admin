import 'dart:io';
import 'dart:convert';
void main() async {
  final url = '${Platform.environment['TEST_URL']}/auth/v1/signup';
  final key = Platform.environment['TEST_ANON']!;
  final request = await HttpClient().postUrl(Uri.parse(url));
  request.headers.add('apikey', key);
  request.headers.add('Content-Type', 'application/json');
  request.write(jsonEncode({
    'email': 'pitoduro6@gmail.com',
    'password': 'password1234',
    'data': {'full_name': 'Test User', 'role': 'client'}
  }));
  final response = await request.close();
  final respBody = await response.transform(utf8.decoder).join();
  print('STATUS: ${response.statusCode}');
  print('BODY: $respBody');
}
