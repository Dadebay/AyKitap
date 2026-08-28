import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/models/topup_product.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/revenue_cat_api_service.dart';
import '../../../core/services/revenue_cat_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/payment_strings.dart';

/// One row this sheet can actually sell: a backend [TopupProduct] catalog
/// entry paired with the RevenueCat [Package] that resolves it to a real,
/// store-localized price. A [TopupProduct] with no matching package (not
/// yet mapped in the RevenueCat offering) is left out of the list entirely
/// — same "never show what can't actually be bought" rule the rest of the
/// RevenueCat integration follows.
class _StoreTopUpOption {
  final TopupProduct product;
  final Package package;
  const _StoreTopUpOption(this.product, this.package);
}

/// The store-billed step of a balance top-up — [PaymentMethodSheet]'s
/// `store` choice leads here instead of [TopUpAmountSheet] +
/// [BankSelectSheet], since there's no separate amount to type in: each
/// denomination is its own store product with a fixed, store-localized
/// price. Pops the selected [Package] so `startBalanceTopUp` can hand it
/// straight to [RevenueCatService.purchasePackage].
class StoreTopUpSheet extends StatefulWidget {
  const StoreTopUpSheet({super.key});

  static Future<Package?> show(BuildContext context) {
    return showModalBottomSheet<Package>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const StoreTopUpSheet(),
    );
  }

  @override
  State<StoreTopUpSheet> createState() => _StoreTopUpSheetState();
}

class _StoreTopUpSheetState extends State<StoreTopUpSheet> {
  List<_StoreTopUpOption>? _options;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      final products = await RevenueCatApiService.getTopupProducts(platform);
      final offerings = await RevenueCatService.instance.getOfferings();
      final packages = offerings?.current?.availablePackages ?? const [];
      final options = <_StoreTopUpOption>[];
      for (final product in products) {
        for (final package in packages) {
          if (package.storeProduct.identifier == product.productId) {
            options.add(_StoreTopUpOption(product, package));
            break;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _options = options;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.grey3,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 18),
              Text(PaymentStrings.storeTopUpTitle,
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(PaymentStrings.storeTopUpLoadError,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey2, fontSize: 14)),
            const SizedBox(height: 8),
            TextButton(
                onPressed: _load,
                child: Text(PaymentStrings.retry,
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700))),
          ],
        ),
      );
    }
    final options = _options ?? const [];
    if (options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(PaymentStrings.storeTopUpUnavailable,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey2, fontSize: 14)),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: options.map((option) {
        return InkWell(
          onTap: () => Navigator.pop(context, option.package),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle),
                  child: Center(
                      child: HugeIcon(
                          icon: HugeIcons.strokeRoundedStore01,
                          color: AppColors.primary,
                          size: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                    child: Text(
                        PaymentStrings.manat(option.product.topupAmount),
                        style: TextStyle(
                            color: AppColors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600))),
                Text(option.package.storeProduct.priceString,
                    style: TextStyle(
                        color: AppColors.grey1,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
