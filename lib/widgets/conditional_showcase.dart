import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

class ConditionalShowcase extends StatelessWidget {
  final GlobalKey showcaseKey;
  final String description;
  final Widget child;
  final bool showShowcase;

  const ConditionalShowcase({
    super.key,
    required this.showcaseKey,
    required this.description,
    required this.child,
    this.showShowcase = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showShowcase) {
      return child;
    }
    
    return Showcase(
      key: showcaseKey,
      description: description,
      descTextStyle: const TextStyle(
        color: Colors.black87,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      targetShapeBorder: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      tooltipActionConfig: const TooltipActionConfig(
        position: TooltipActionPosition.outside,
        alignment: MainAxisAlignment.end,
        actionGap: 8,
      ),
      tooltipActions: [
        const TooltipActionButton(
          type: TooltipDefaultActionType.skip,
          name: 'Fermer',
          backgroundColor: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(20)),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          textStyle: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const TooltipActionButton(
          type: TooltipDefaultActionType.next,
          name: 'Suivant',
          backgroundColor: Color(0xFFFF7A3C),
          borderRadius: BorderRadius.all(Radius.circular(20)),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          textStyle: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
      child: child,
    );
  }
}
