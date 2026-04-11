import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkService {
  final InternetConnection _connection = InternetConnection();

  Future<bool> hasInternetAccess() {
    return _connection.hasInternetAccess;
  }
}
