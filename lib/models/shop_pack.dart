class CoinPack {
  const CoinPack({required this.productId, required this.coins});
  final String productId;
  final int coins;
}

const coinPacks = <CoinPack>[
  CoinPack(productId: 'coins_50000', coins: 50000),
  CoinPack(productId: 'coins_110000', coins: 110000),
  CoinPack(productId: 'coins_180000', coins: 180000),
  CoinPack(productId: 'coins_260000', coins: 260000),
  CoinPack(productId: 'coins_350000', coins: 350000),
  CoinPack(productId: 'coins_450000', coins: 450000),
  CoinPack(productId: 'coins_570000', coins: 570000),
  CoinPack(productId: 'coins_710000', coins: 710000),
  CoinPack(productId: 'coins_860000', coins: 860000),
  CoinPack(productId: 'coins_1050000', coins: 1050000),
];

const removeAdsProductId = 'remove_ads';
