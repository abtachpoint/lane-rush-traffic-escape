class CoinPack {
  const CoinPack({required this.productId, required this.fallbackPrice, required this.coins});
  final String productId;
  final String fallbackPrice;
  final int coins;
}

const coinPacks = <CoinPack>[
  CoinPack(productId: 'coins_50000', fallbackPrice: r'$5.02', coins: 50000),
  CoinPack(productId: 'coins_110000', fallbackPrice: r'$10.02', coins: 110000),
  CoinPack(productId: 'coins_180000', fallbackPrice: r'$15.02', coins: 180000),
  CoinPack(productId: 'coins_260000', fallbackPrice: r'$20.02', coins: 260000),
  CoinPack(productId: 'coins_350000', fallbackPrice: r'$25.02', coins: 350000),
  CoinPack(productId: 'coins_450000', fallbackPrice: r'$30.02', coins: 450000),
  CoinPack(productId: 'coins_570000', fallbackPrice: r'$35.02', coins: 570000),
  CoinPack(productId: 'coins_710000', fallbackPrice: r'$40.02', coins: 710000),
  CoinPack(productId: 'coins_860000', fallbackPrice: r'$45.02', coins: 860000),
  CoinPack(productId: 'coins_1050000', fallbackPrice: r'$50.02', coins: 1050000),
];

const removeAdsProductId = 'remove_ads';
