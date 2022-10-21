import 'package:eip55/eip55.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

import '../../utils/constants.dart';
import '../app/models/app_info.dart';
import 'wallet_connect_service.dart';

class Web3Service {
  late Web3Client web3client;
  late WalletConnectService walletConnectService;
  late Client httpClient;
  late String? publicWalletAddress;

  void connectWallet(context) async {
    walletConnectService = WalletConnectService(
      bridge: GlobalConstants.bridge,
      appInfo: AppInfo(
        name: GlobalConstants.name,
        description: GlobalConstants.name,
        url: GlobalConstants.url,
      ),
    );

    httpClient = Client();
    web3client = Web3Client(
      kDebugMode ? GlobalConstants.testnetApiUrl : GlobalConstants.apiUrl,
      httpClient,
    );

    final isConnectWallet =
        await walletConnectService.initSession(context, chainId: 42220);
    if (isConnectWallet) {
      publicWalletAddress = walletConnectService
          .getEthereumCredentials()
          .getEthereumAddress()
          .toString();
      publicWalletAddress = toEIP55Address(publicWalletAddress!);
    }
  }

  Future getBalance() async {
    var address =
        await walletConnectService.getEthereumCredentials().extractAddress();
    await web3client.getBalance(address);
  }
}
