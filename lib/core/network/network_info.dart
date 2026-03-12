abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class DummyNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}

