import 'package:flutter/material.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/ui/screen/collection_page.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
import 'package:rpmlauncher/util/launcher_info.dart';

class RPMLDialog extends StatelessWidget {
  final String title;
  final Widget icon;
  final Widget child;
  final List<Widget> actions;
  final EdgeInsets insetPadding;

  const RPMLDialog(
      {super.key,
      required this.title,
      required this.icon,
      required this.child,
      this.actions = const [],
      this.insetPadding =
          const EdgeInsets.symmetric(vertical: 80, horizontal: 150)});

  @override
  Widget build(BuildContext context) {
    const iconSize = 50.0;

    return Dialog(
      insetPadding: insetPadding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge,
      child: Container(
        decoration: BoxDecoration(
            color: context.theme.dialogBackgroundColor,
            border: Border.all(color: context.theme.backgroundColor, width: 2)),
        child: Column(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: Container(
                color: context.theme.backgroundColor,
                constraints: const BoxConstraints(minHeight: 75),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        children: [
                          SizedBox(
                              height: iconSize,
                              child: IconTheme.merge(
                                  data: const IconThemeData(size: iconSize),
                                  child: icon)),
                          const SizedBox(width: 20),
                          Text(title, style: const TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        ...actions,
                        IconButton(
                            onPressed: () {
                              Navigator.of(context).popUntil((route) =>
                                  route.settings.name == LauncherInfo.route);
                            },
                            tooltip: I18n.format('gui.close'),
                            icon: const Icon(Icons.close_rounded, size: 30)),
                        const SizedBox(width: 12),
                      ],
                    )
                  ],
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
