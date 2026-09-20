import 'package:flutter/material.dart';

import '../models/shop_pack.dart';
import '../services/ad_service.dart';
import '../services/game_store.dart';
import '../services/purchase_service.dart';
import '../widgets/game_widgets.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final store = GameStore.instance;
  final purchases = PurchaseService.instance;

  @override
  void initState() {
    super.initState();
    store.addListener(_refresh);
    purchases.addListener(_refresh);
    purchases.refreshProducts();
  }

  @override
  void dispose() {
    store.removeListener(_refresh);
    purchases.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('SHOP'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CoinBadge(coins: store.coins),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            NeonCard(
              child: Row(
                children: [
                  Image.asset('assets/images/ui/coin.png', width: 58),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FREE COINS',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                        Text(
                          'Watch Ad',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  GradientButton(
                    label: '+500',
                    compact: true,
                    onPressed: () async {
                      final earned = await AdService.instance.showRewarded();
                      if (earned) {
                        await store.addCoins(500);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('500 coins added')),
                          );
                        }
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ad is not ready yet')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'COIN PACKS',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 10),
            for (final pack in coinPacks)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: NeonCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Image.asset('assets/images/ui/coin.png', width: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${pack.coins} Coins',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      GradientButton(
                        label: purchases.products[pack.productId]?.price ?? 'BUY',
                        compact: true,
                        onPressed: () => purchases.buyCoinPack(pack.productId),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 6),
            NeonCard(
              child: Row(
                children: [
                  const Icon(Icons.block_rounded, color: Color(0xFF93C5FD), size: 42),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'REMOVE ADS',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  GradientButton(
                    label: store.removeAds
                        ? 'OWNED'
                        : (purchases.products[removeAdsProductId]?.price ?? 'BUY'),
                    compact: true,
                    onPressed: store.removeAds ? null : () => purchases.buyRemoveAds(),
                  ),
                ],
              ),
            ),
            if (purchases.lastError != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  purchases.lastError!,
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                ),
              ),
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: Text(
                'Google Play displays the final local price and applies eligible Play Points coupons at checkout. Coin purchases are consumable.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
          ],
        ),
      );
}
