import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.dense = false,
    this.minQuantity = 1,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool dense;
  final int minQuantity;

  @override
  Widget build(BuildContext context) {
    final double buttonSize = dense ? 40 : 48;
    final double iconSize = dense ? 20 : 24;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E0DC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _StepButton(
            icon: Icons.remove_rounded,
            size: buttonSize,
            iconSize: iconSize,
            enabled: quantity > minQuantity,
            onTap: onDecrement,
          ),
          SizedBox(
            width: dense ? 36 : 44,
            height: buttonSize,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: FittedBox(
                  key: ValueKey<int>(quantity),
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$quantity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            size: buttonSize,
            iconSize: iconSize,
            enabled: true,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          icon,
          size: iconSize,
          color: enabled ? AppColors.primary : const Color(0xFFBDBDBD),
        ),
      ),
    );
  }
}
