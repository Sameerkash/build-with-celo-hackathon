import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

import '../../utils/deeplink_util.dart';
import '../../utils/wc_eth_credentials_util.dart';
import '../app/models/app_info.dart';
import '../app/models/crypto_wallet.dart';

class WalletConnectService {
  final String? bridge;
  final AppInfo appInfo;

  late WalletConnect connector;

  SessionStatus? sessionStatus;
  List<String> accounts = [];

  WalletConnectService({
    this.bridge,
    required this.appInfo,
  }) {
    connector = getWalletConnect();
  }

  WalletConnect getWalletConnect() {
    final WalletConnect connector = WalletConnect(
      bridge: bridge ?? 'https://bridge.walletconnect.org',
      clientMeta: PeerMeta(
        name: appInfo.name ?? 'WalletConnect',
        description: appInfo.description ?? 'WalletConnect Developer App',
        url: appInfo.url ?? 'https://walletconnect.org',
        icons: appInfo.icons ??
            [
              'https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
            ],
      ),
    );
    return connector;
  }

  Future<bool> initSession(context, {int? chainId}) async {
    try {
      return await initMobileSession(chainId: chainId);
    } catch (e) {
      return false;
    }
  }

  Future<bool> initMobileSession({int? chainId}) async {
    if (!connector.connected) {
      try {
        sessionStatus = await connector.createSession(
          chainId: chainId,
          onDisplayUri: (uri) async {
            await _connectWallet(displayUri: uri);
          },
        );

        accounts = sessionStatus?.accounts ?? [];

        return true;
      } catch (e) {
        debugPrint('createSession() - failure - $e');
        resetConnector();
        return false;
      }
    } else {
      return true;
    }
  }

  Future<void> _connectWallet({
    CryptoWallet wallet = CryptoWallet.metamask,
    required String displayUri,
  }) async {
    var deeplink = DeeplinkUtil.getDeeplink(wallet: wallet, uri: displayUri);
    bool isLaunch = await launchUrl(Uri.parse(deeplink),
        mode: LaunchMode.externalApplication);
    if (!isLaunch) {
      throw 'connectWallet() - failure - Could not open $deeplink.';
    }
  }

  WalletConnectEthereumCredentials getEthereumCredentials() {
    EthereumWalletConnectProvider provider =
        EthereumWalletConnectProvider(connector);
    WalletConnectEthereumCredentials credentials =
        WalletConnectEthereumCredentials(provider: provider);
    return credentials;
  }

  Future<void> dispose() async {
    connector.session.reset();
    await connector.killSession();
    await connector.close();

    sessionStatus = null;
    accounts = [];
    resetConnector();
  }

  void resetConnector() {
    connector = getWalletConnect();
  }
}
