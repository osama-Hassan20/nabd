import '../../core/network/mony_helper.dart';
import '../../core/utils/theme/app_colors.dart';
import '../../core/utils/theme/custom_app_font_styles.dart';
import 'package:flutter/material.dart';

class CustomPriceAfterAndBefore extends StatelessWidget {
  const CustomPriceAfterAndBefore({
    super.key,
    this.priceStyle,
    this.beforePriceFontSize,
    this.symbolCurrencyStyle,
    this.priceAfter,
    this.priceBefore,
    this.enableDiscount = false,
  });
  final TextStyle? priceStyle;
  final double? beforePriceFontSize;
  final TextStyle? symbolCurrencyStyle;
  final num? priceBefore;
  final num? priceAfter;
  final bool enableDiscount;
  @override
  Widget build(BuildContext context) {
    if (!enableDiscount) {
      return Row(
        children: [
          FittedBox(
            child: Text.rich(
              TextSpan(
                text: MonyHelper.formatMoney(priceAfter?.toDouble() ?? 20000),
                style:
                    priceStyle ??
                    CustomAppFontStyle.bold14.copyWith(color: AppColors.gray334155),
                children: [
                  TextSpan(
                    text: " د.ع",
                    style:
                        symbolCurrencyStyle ??
                        CustomAppFontStyle.light12.copyWith(
                          color: AppColors.gray334155,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Text(
          MonyHelper.formatMoney(priceBefore?.toDouble() ?? 405697),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CustomAppFontStyle.light12.copyWith(
            color: AppColors.gray334155,
            fontSize: beforePriceFontSize,
            decoration: TextDecoration.lineThrough,
            decorationColor: AppColors.gray334155,
          ),
        ),
        const SizedBox(width: 4),
        FittedBox(
          child: Text.rich(
            TextSpan(
              text: MonyHelper.formatMoney(priceAfter?.toDouble() ?? 20000),
              style:
                  priceStyle ??
                  CustomAppFontStyle.bold14.copyWith(color: AppColors.gray334155),
              children: [
                TextSpan(
                  text: " د.ع",
                  style:
                      symbolCurrencyStyle ??
                      CustomAppFontStyle.light12.copyWith(
                        color: AppColors.gray334155,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
