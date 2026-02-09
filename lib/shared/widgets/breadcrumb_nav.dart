import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BreadcrumbItem {
  const BreadcrumbItem({required this.label, this.route});
  final String label;
  final String? route;
}

/// Breadcrumb navigation bar for web admin pages.
class BreadcrumbNav extends StatelessWidget {
  const BreadcrumbNav({super.key, required this.items});

  final List<BreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.chevron_right,
                    size: 16, color: Colors.grey.shade400),
              ),
            if (i < items.length - 1 && items[i].route != null)
              InkWell(
                onTap: () => context.go(items[i].route!),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    items[i].label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              )
            else
              Text(
                items[i].label,
                style: TextStyle(
                  fontSize: 12,
                  color: i == items.length - 1
                      ? Colors.grey.shade700
                      : Colors.grey.shade500,
                  fontWeight: i == items.length - 1
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
