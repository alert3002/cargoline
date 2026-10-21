enum AppLocale { ru, tj }

class AppStrings {
  AppStrings(this.locale);

  final AppLocale locale;
  bool get isRu => locale == AppLocale.ru;

  String get appName => 'CargoLine.Tj';

  // Auth
  String get welcome => isRu ? 'Добро пожаловать' : 'Хуш омадед';
  String get enterPhone =>
      isRu ? 'Введите номер телефона' : 'Рақами телефонро ворид кунед';
  String get phoneHint => '+992 XX XXX XXXX';
  String get continueBtn => isRu ? 'Продолжить' : 'Идома додан';
  String get smsTitle => isRu ? 'Подтверждение SMS' : 'Тасдиқи SMS';
  String get smsSubtitle => isRu
      ? 'Введите код из SMS-сообщения'
      : 'Рамзи SMS-ро ворид кунед';
  String get verify => isRu ? 'Подтвердить' : 'Тасдиқ кардан';
  String get resendCode =>
      isRu ? 'Отправить код повторно' : 'Рамзро дубора фиристед';

  // Nav
  String get navHome => isRu ? 'Главная' : 'Асосӣ';
  String get navOrders => isRu ? 'Заказы' : 'Фармоишҳо';
  String get navTrack => isRu ? 'Трек' : 'Трек';
  String get navBook => isRu ? 'Заказ' : 'Фармоиш';
  String get navMessages => isRu ? 'Сообщения' : 'Паёмҳо';
  String get navProfile => isRu ? 'Профиль' : 'Профил';
  String get navSettings => isRu ? 'Ещё' : 'Бештар';
  String get navQr => 'QR Code';

  String get trackShipment =>
      isRu ? 'Отследить посылку' : 'Пайгирии бор';
  String get services => isRu ? 'Сервисы' : 'Хизматҳо';
  String get bookNow => isRu ? 'Новая отправка' : 'Фиристодани нав';
  String get createShipment => isRu ? 'СОЗДАТЬ →' : 'СОХТАН →';
  String get activeOrders => isRu ? 'Активные заказы' : 'Фармоишҳои фаъол';
  String get support247 => isRu ? 'Поддержка 24/7' : 'Дастгирӣ 24/7';
  String get welcomeUser => isRu ? 'Welcome' : 'Хуш омадед';
  String get tagline => 'Fast. Reliable. Global.';
  String get connectionError => isRu
      ? 'Нет связи с сервером. Проверьте сеть и backend.'
      : 'Пайваст бо сервер нест. Шабакаро санҷед.';
  String get themeDark => isRu ? 'Тёмная тема' : 'Мавзӯи торик';
  String get themeLight => isRu ? 'Светлая тема' : 'Мавзӯи равшан';

  // Home
  String get supportBanner =>
      isRu ? 'Возникли вопросы? Мы поможем вам!' : 'Саволҳое доред? Мо кӯмак мекунем!';
  String get supportPhone => 'Служба поддержки: 555 33 22 11';
  String get workHours =>
      isRu ? 'Работаем ежедневно с 9:00 до 19:00' : 'Ҳар рӯз аз 9:00 то 19:00';
  String get downloadMarketplace =>
      isRu ? 'Скачайте маркетплейс' : 'Бозорро боргирӣ кунед';
  String get chinaWarehouse =>
      isRu ? 'Адрес доставки' : 'Суроғаи расонидан';
  String get copyAll => isRu ? 'Скопировать все' : 'Ҳамаашро нусха бардоред';
  String get copied => isRu ? 'Скопировано!' : 'Нусха бардошта шуд!';
  String get howEnterAddress =>
      isRu ? 'Как мне ввести адрес?' : 'Чӣ гуна суроғаро ворид кунам?';
  String get videoGuide => isRu
      ? 'Видеоинструкция по вводу адреса в Pinduoduo/1688'
      : 'Видео дастур оиди вориди суроға дар Pinduoduo/1688';
  String get addTrackCode =>
      isRu ? 'Добавить трек-код' : 'Трек-код илова кунед';
  String get trackCodeHint =>
      isRu ? 'Введите ваш трек-код' : 'Трек-коди худро ворид кунед';
  String get selectMarketplace =>
      isRu ? 'Выберите маркетплейс' : 'Бозорро интихоб кунед';
  String get yourId => isRu ? 'Ваш ID' : 'ID-и шумо';
  String get warehousePhone => isRu ? 'Телефон склада' : 'Телефони анбор';
  String get address => isRu ? 'Адрес' : 'Суроға';

  // Orders
  String get ordersTitle => isRu ? 'Заказы' : 'Фармоишҳо';
  String get lostItemSearch =>
      isRu ? 'Поиск потерянного товара' : 'Ҷустуҷӯи молҳои гумшуда';
  String get trackCode => isRu ? 'Трек-код' : 'Трек-код';
  String get search => isRu ? 'Найти' : 'Ҷустуҷӯ';
  String get noOrders => isRu ? 'Нет заказов' : 'Фармоиш нест';

  String statusLabel(ParcelStatusKey key) {
    switch (key) {
      case ParcelStatusKey.pendingMatch:
        return isRu ? 'Ожидает скана' : 'Интизори скан';
      case ParcelStatusKey.chinaWarehouse:
        return isRu ? 'Склад Китай' : 'Анбори Чин';
      case ParcelStatusKey.inTransit:
        return isRu ? 'В пути' : 'Дар роҳ';
      case ParcelStatusKey.sorting:
        return isRu ? 'Сортировка' : 'Ҷудокунӣ';
      case ParcelStatusKey.tajikistanWarehouse:
        return isRu ? 'Склад Таджикистан' : 'Анбори Тоҷикистон';
      case ParcelStatusKey.delivery:
        return isRu ? 'Доставка' : 'Расонидан';
      case ParcelStatusKey.received:
        return isRu ? 'Получен' : 'Гирифта шуд';
    }
  }

  // Profile
  String get clientCode => isRu ? 'Код клиента' : 'Рамзи мизоҷ';
  String get deliveryCalculator =>
      isRu ? 'Калькулятор' : 'Ҳисобкунак';
  String get weight => isRu ? 'Вес (кг)' : 'Вазн (кг)';
  String get volume => isRu ? 'Объём (м³)' : 'Ҳаҷм (м³)';
  String get calculate => isRu ? 'Рассчитать' : 'Ҳисоб кардан';
  String get prohibitedItems =>
      isRu ? 'Список запрещённых предметов' : 'Рӯйхати молҳои манъшуда';
  String get statistics => isRu ? 'Статистика' : 'Омор';
  String get lessons => isRu ? 'Уроки' : 'Дарсҳо';
  String get freeCourse => isRu ? 'бесплатный курс' : 'курси ройгон';
  String get pickupPoint => isRu ? 'Ваш пункт выдачи' : 'Нуқтаи додани шумо';
  String get deliveryTerms => isRu ? 'Условия доставки' : 'Шартҳои расонидан';
  String get tariffs => isRu ? 'Тарифы' : 'Тарифҳо';
  String get aiAddressCheck =>
      isRu ? 'AI - для проверка адреса' : 'AI - санҷиши суроға';
  String get support => isRu ? 'Техподдержка' : 'Дастгирии техникӣ';
  String get logout => isRu ? 'Выйти' : 'Баромадан';
  String get activeUser => isRu ? 'Активный клиент' : 'Мизоҷи фаъол';
  String get settings => isRu ? 'Настройки' : 'Танзимот';
  String get khujand => isRu ? 'Шаҳри Хуҷанд' : 'Шаҳри Хуҷанд';

  List<({String icon, String title})> get prohibitedList => isRu
      ? [
          (icon: '🚬', title: 'Электронные сигареты (вейпы, POD)'),
          (icon: '🧪', title: 'Химические товары (реагенты, кислоты)'),
          (icon: '🔪', title: 'Холодное оружие (ножи, кастеты)'),
          (icon: '💊', title: 'Медицинские препараты'),
          (icon: '🌱', title: 'Живые растения и семена'),
          (icon: '🥩', title: 'Скоропортящиеся продукты'),
          (icon: '💥', title: 'Взрывчатые вещества и пиротехника'),
        ]
      : [
          (icon: '🚬', title: 'Сигорҳои электронӣ (вейп, POD)'),
          (icon: '🧪', title: 'Молҳои химиявӣ (реактив, кислота)'),
          (icon: '🔪', title: 'Яроқи хунук (корд, кастет)'),
          (icon: '💊', title: 'Доруҳои тиббӣ'),
          (icon: '🌱', title: 'Растаниҳои зинда ва тухмӣ'),
          (icon: '🥩', title: 'Молҳои зудфосидашаванда'),
          (icon: '💥', title: 'Моддаҳои тарканда ва пиротехника'),
        ];

  // Messages / News
  String get messagesTitle => isRu ? 'Сообщения' : 'Паёмҳо';
  String get noMessages => isRu ? 'Нет сообщений' : 'Паём нест';
  String get readMore => isRu ? 'ещё' : 'бештар';

  // QR pickup
  String get qrTitle => 'QR Code';
  String get yourQr => isRu ? 'Ваш QR код' : 'QR коди шумо';
  String get done => isRu ? 'Готово' : 'Тайёр';
  String get noReadyItems => isRu
      ? 'Нет товаров, готовых к получению'
      : 'Молҳои тайёр ба гирифтан нестанд';
  String get noReadyItemsHint => isRu
      ? 'Когда у вас будут товары готовые к получению, здесь появятся QR Code'
      : 'Вақте молҳои тайёр ба гирифтан доред, ин ҷо QR Code пайдо мешавад';

  // Help
  String get helpTitle => isRu ? 'Как мне ввести адрес?' : 'Чӣ гуна суроғаро ворид кунам?';
  String get whatInHelp => isRu ? 'Что входит в помощь' : 'Чӣ дар кӯмак ҳаст';
  String get whatInHelpDesc => isRu
      ? 'Короткие и понятные советы по адресам, статусам посылок и шагам доставки.'
      : 'Маслиҳатҳои кӯтоҳ оиди суроға, статус ва қадамҳои расонидан.';
  String get popularQuestions =>
      isRu ? 'Популярные вопросы' : 'Саволҳои маъмул';
  String get popularQuestionsDesc => isRu
      ? 'Если вы впервые — начните с шагов ниже. Они закрывают 80% вопросов.'
      : 'Агар бори аввал — аз қадамҳои поён оғоз кунед.';
  String get quickStart => isRu ? 'Быстрый старт' : 'Оғози зуд';
  String get step1Title =>
      isRu ? 'Скопируйте адрес склада' : 'Суроғаи анборро нусха бардоред';
  String get step1Desc => isRu
      ? "Используйте кнопку «Скопировать все» в карточке на главной."
      : 'Тугмаи «Ҳамаашро нусха бардоред»-ро дар саҳифаи асосӣ истифода баред.';

  String marketplaceLabel(MarketplaceKey key) {
    switch (key) {
      case MarketplaceKey.pinduoduo:
        return 'Pinduoduo';
      case MarketplaceKey.taobao:
        return 'Taobao';
      case MarketplaceKey.alibaba1688:
        return '1688';
      case MarketplaceKey.poizon:
        return 'Poizon';
    }
  }
}

enum ParcelStatusKey {
  pendingMatch,
  chinaWarehouse,
  inTransit,
  sorting,
  tajikistanWarehouse,
  delivery,
  received,
}

enum MarketplaceKey { pinduoduo, taobao, alibaba1688, poizon }
