import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/shop_pack.dart';
import 'game_store.dart';

class PurchaseService extends ChangeNotifier {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool storeAvailable = false;
  bool loading = true;
  String? lastError;
  final Map<String, ProductDetails> products = {};

  Future<void> init() async {
    _subscription ??= _iap.purchaseStream.listen(_handlePurchaseUpdates, onError: (Object e) {
      lastError = e.toString();
      notifyListeners();
    });
    await refreshProducts();
  }

  Future<void> refreshProducts() async {
    loading = true;
    lastError = null;
    notifyListeners();
    storeAvailable = await _iap.isAvailable();
    if (!storeAvailable) {
      loading = false;
      notifyListeners();
      return;
    }
    final ids = <String>{...coinPacks.map((e) => e.productId), removeAdsProductId};
    final response = await _iap.queryProductDetails(ids);
    products
      ..clear()
      ..addEntries(response.productDetails.map((p) => MapEntry(p.id, p)));
    if (response.error != null) lastError = response.error!.message;
    loading = false;
    notifyListeners();
  }

  Future<void> buyCoinPack(String productId) async {
    final product = products[productId];
    if (product == null) {
      lastError = 'Product is not active on Google Play yet.';
      notifyListeners();
      return;
    }
    await _iap.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
      autoConsume: true,
    );
  }

  Future<void> buyRemoveAds() async {
    final product = products[removeAdsProductId];
    if (product == null) {
      lastError = 'Remove Ads product is not active on Google Play yet.';
      notifyListeners();
      return;
    }
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.error) {
        lastError = purchase.error?.message ?? 'Purchase failed';
      }
      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        await _grantPurchase(purchase);
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
    notifyListeners();
  }

  Future<void> _grantPurchase(PurchaseDetails purchase) async {
    if (purchase.productID == removeAdsProductId) {
      await GameStore.instance.setRemoveAds(true);
      return;
    }

    final pack = coinPacks.where((p) => p.productId == purchase.productID).firstOrNull;
    if (pack == null || purchase.status == PurchaseStatus.restored) return;

    final key = purchase.purchaseID ?? '${purchase.productID}:${purchase.transactionDate ?? ''}';
    if (GameStore.instance.isPurchaseProcessed(key)) return;
    await GameStore.instance.addCoins(pack.coins);
    await GameStore.instance.markPurchaseProcessed(key);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
