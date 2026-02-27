class NetworkInterfaceState {
  final String name;
  final String macAddress;
  final bool isUp;
  final int speedDrops; // if available
  final int bytesReceivedPerSec;
  final int bytesSentPerSec;

  NetworkInterfaceState({
    required this.name,
    required this.macAddress,
    required this.isUp,
    this.speedDrops = 0,
    this.bytesReceivedPerSec = 0,
    this.bytesSentPerSec = 0,
  });
}

class SystemNetworkState {
  final List<NetworkInterfaceState> interfaces;

  SystemNetworkState({required this.interfaces});
}
