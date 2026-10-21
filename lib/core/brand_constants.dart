/// Brand phones, links and marketplace URLs.
class BrandConstants {
  static const adminPhone = '992926277667';
  static const adminPhoneDisplay = '+992 92 627 7667';
  static const deliveryPhone = '992926277667';
  static const deliveryPhoneDisplay = '+992 92 627 7667';
  static const bankPhone = '926277667';
  static const developerPhone = '+992 97 285 0100';

  static const warehousePhoneCn = '13311198266';
  static const warehouseRegionCn = '浙江省金华市义乌市 北苑街道';
  static const warehouseStreetCn =
      '浙江省金华市义乌市 北苑街道凌云三区9栋2单元扎娜供应链Z178仓库';

  static const lessonsTelegram = 'https://t.me/+Shm4RFQQoOEyYjJi';
  static const apiBaseUrl = 'https://cargoline.tj';
  static const cityDeliverySomoni = 10;
  static const dcWallet = '987059515';

  static Uri telAdmin() => Uri.parse('tel:$adminPhone');
  static Uri whatsAppAdmin() =>
      Uri.parse('https://wa.me/$adminPhone');
  static Uri telegramAdmin() =>
      Uri.parse('https://t.me/+$adminPhone');
  static Uri whatsAppDelivery() =>
      Uri.parse('https://wa.me/$deliveryPhone');

  static const marketplaceUrls = {
    'pinduoduo': 'https://mobile.yangkeduo.com',
    '1688': 'https://m.1688.com',
    'taobao': 'https://m.taobao.com',
    'poizon': 'https://www.poizon.com',
  };

  /// Android package ids (for intent / queries).
  static const marketplacePackages = {
    'pinduoduo': 'com.xunmeng.pinduoduo',
    '1688': 'com.alibaba.wireless',
    'taobao': 'com.taobao.taobao',
    'poizon': 'com.dewu.buyer',
  };

  /// Try native apps first, then store.
  static const marketplaceAppSchemes = {
    'pinduoduo': [
      'pinduoduo://home',
      'pinduoduo://',
      'pddopen://',
      'yangkeduo://',
    ],
    '1688': [
      'wireless1688://',
      'alibaba://',
      '1688://',
    ],
    'taobao': [
      'taobao://',
      'tbopen://m.taobao.com/tbopen/index.html',
      'tmall://',
    ],
    'poizon': [
      'dewuapp://home',
      'dewuapp://',
      'poizon://',
      'duapp://',
    ],
  };

  static const marketplaceStoreUrls = {
    'pinduoduo':
        'https://play.google.com/store/apps/details?id=com.xunmeng.pinduoduo',
    '1688':
        'https://play.google.com/store/apps/details?id=com.alibaba.wireless',
    'taobao':
        'https://play.google.com/store/apps/details?id=com.taobao.taobao',
    'poizon':
        'https://play.google.com/store/apps/details?id=com.dewu.buyer',
  };

  static const marketplaceIosStoreUrls = {
    'pinduoduo': 'https://apps.apple.com/app/id1048766978',
    '1688': 'https://apps.apple.com/app/id507397273',
    'taobao': 'https://apps.apple.com/app/id387682726',
    'poizon': 'https://apps.apple.com/app/id1044250891',
  };

  static const bankLinks = {
    'alif': 'https://alif.tj',
    'dushanbe': 'https://dc.tj',
    'eskhata': 'https://eskhata.com',
  };

  static const bankPackages = {
    'alif': 'tj.alif.mobi',
    'dushanbe': 'tj.dc.next1',
    'eskhata': 'tj.eskhata.online',
  };

  static const bankStoreUrls = {
    'alif':
        'https://play.google.com/store/apps/details?id=tj.alif.mobi',
    'dushanbe':
        'https://play.google.com/store/apps/details?id=tj.dc.next1',
    'eskhata':
        'https://play.google.com/store/apps/details?id=tj.eskhata.online',
  };

  static const bankIosStoreUrls = {
    'alif': 'https://apps.apple.com/app/id1490428589',
    'dushanbe': 'https://apps.apple.com/app/id6443701539',
    'eskhata': 'https://apps.apple.com/app/id1473440427',
  };

  /// Deep links to pay / transfer by phone inside bank apps (try before store).
  static List<String> bankPaymentUris(String key, {String? phone}) {
    final p = phone ?? dcWallet;
    switch (key) {
      case 'alif':
        return [
          'alifmobi://external/transfers?phone=$p',
          'alifmobi://transfer?phone=$p',
          'alifmobi://pay?phoneNumber=$p',
          'alifmobi://',
        ];
      case 'dushanbe':
        return [
          'dcnext://transfer?phone=$p',
          'dcnext://pay?phone=$p',
          'dushanbecity://transfer?phone=$p',
          'dcnext://',
        ];
      case 'eskhata':
        return [
          'eskhata://transfer?phone=$p',
          'eskhataonline://pay?phone=$p',
          'eskhata://payment?phone=$p',
          'eskhata://',
        ];
      default:
        return const [];
    }
  }
}
