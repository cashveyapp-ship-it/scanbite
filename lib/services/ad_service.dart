import '../utils/constants.dart';

// AD SERVICE DISABLED - Placeholder for future implementation
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  Future<void> initialize() async {
    // Ads disabled
    print('AdService: Ads are currently disabled');
  }

  void loadBannerAd({
    required Function() onAdLoaded,
    required Function(String) onAdFailedToLoad,
  }) {
    // Ads disabled
    onAdFailedToLoad('Ads are disabled');
  }

  void loadInterstitialAd() {
    // Ads disabled
  }

  void showInterstitialAd() {
    // Ads disabled
  }

  dynamic get bannerAd => null;

  void dispose() {
    // Nothing to dispose
  }
}