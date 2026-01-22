/// 🎨 ADAPTIVE UI COMPONENTS
///
/// 2026 Design Trend: Contextual & Adaptive UI
/// Components that adapt based on:
/// - Screen size (responsive navigation)
/// - Time of day (auto dark mode enhancements)
/// - User behavior (predictive layouts)
/// - Device orientation
///
/// Implements Material 3 responsive navigation patterns:
/// - Bottom Navigation Bar (compact)
/// - Navigation Rail (medium)
/// - Navigation Drawer (expanded)
library;

import 'package:flutter/material.dart';
import '../core/theme/theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 📐 WINDOW SIZE CLASSES
// ═══════════════════════════════════════════════════════════════════════════

/// Material 3 Window Size Classes for responsive design
enum WindowSizeClass {
  compact,   // < 600dp (phones)
  medium,    // 600-839dp (tablets, foldables)
  expanded,  // >= 840dp (large tablets, desktop)
}

/// Get current window size class
WindowSizeClass getWindowSizeClass(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < 600) return WindowSizeClass.compact;
  if (width < 840) return WindowSizeClass.medium;
  return WindowSizeClass.expanded;
}

/// Extension for easy access
extension WindowSizeClassExtension on BuildContext {
  WindowSizeClass get windowSizeClass => getWindowSizeClass(this);
  bool get isCompact => windowSizeClass == WindowSizeClass.compact;
  bool get isMedium => windowSizeClass == WindowSizeClass.medium;
  bool get isExpanded => windowSizeClass == WindowSizeClass.expanded;
}

// ═══════════════════════════════════════════════════════════════════════════
// 🧭 ADAPTIVE NAVIGATION SCAFFOLD
// ═══════════════════════════════════════════════════════════════════════════

/// Automatically switches between bottom bar, rail, and drawer
/// based on screen size - Material 3 responsive navigation pattern
class AdaptiveNavigationScaffold extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final List<Widget> children;
  final Widget? floatingActionButton;
  final bool showLabelsOnRail;

  const AdaptiveNavigationScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.children,
    this.floatingActionButton,
    this.showLabelsOnRail = true,
  });

  @override
  Widget build(BuildContext context) {
    final sizeClass = context.windowSizeClass;
    final brightness = Theme.of(context).brightness;

    switch (sizeClass) {
      case WindowSizeClass.compact:
        return _buildCompactLayout(context, brightness);
      case WindowSizeClass.medium:
        return _buildMediumLayout(context, brightness);
      case WindowSizeClass.expanded:
        return _buildExpandedLayout(context, brightness);
    }
  }

  /// Compact: Bottom Navigation Bar
  Widget _buildCompactLayout(BuildContext context, Brightness brightness) {
    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: IndexedStack(
        index: selectedIndex,
        children: children,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        backgroundColor: AppColors.surface(brightness),
        indicatorColor: AppColors.crimson.withValues(alpha: 0.15),
        destinations: destinations,
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  /// Medium: Navigation Rail
  Widget _buildMediumLayout(BuildContext context, Brightness brightness) {
    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            backgroundColor: AppColors.surface(brightness),
            indicatorColor: AppColors.crimson.withValues(alpha: 0.15),
            labelType: showLabelsOnRail
                ? NavigationRailLabelType.all
                : NavigationRailLabelType.selected,
            leading: floatingActionButton != null
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: floatingActionButton,
                  )
                : null,
            destinations: destinations.map((d) => NavigationRailDestination(
              icon: d.icon,
              selectedIcon: d.selectedIcon,
              label: Text(d.label),
            )).toList(),
          ),
          VerticalDivider(
            width: 1,
            color: AppColors.border(brightness),
          ),
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  /// Expanded: Permanent Navigation Drawer
  Widget _buildExpandedLayout(BuildContext context, Brightness brightness) {
    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            backgroundColor: AppColors.surface(brightness),
            indicatorColor: AppColors.crimson.withValues(alpha: 0.15),
            children: [
              const SizedBox(height: 12),
              // App logo/header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.music_note_rounded,
                      color: AppColors.crimson,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'GigMatch',
                      style: TextStyle(
                        color: AppColors.text(brightness),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(indent: 28, endIndent: 28),
              ...destinations.asMap().entries.map((entry) {
                final i = entry.key;
                final d = entry.value;
                return NavigationDrawerDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: Text(d.label),
                );
              }),
              if (floatingActionButton != null) ...[
                const Divider(indent: 28, endIndent: 28),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: floatingActionButton,
                ),
              ],
            ],
          ),
          VerticalDivider(
            width: 1,
            color: AppColors.border(brightness),
          ),
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📊 ADAPTIVE GRID
// ═══════════════════════════════════════════════════════════════════════════

/// Grid that adapts column count based on screen size
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry? padding;
  final int compactColumns;
  final int mediumColumns;
  final int expandedColumns;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.padding,
    this.compactColumns = 2,
    this.mediumColumns = 3,
    this.expandedColumns = 4,
  });

  @override
  Widget build(BuildContext context) {
    final sizeClass = context.windowSizeClass;
    final columns = switch (sizeClass) {
      WindowSizeClass.compact => compactColumns,
      WindowSizeClass.medium => mediumColumns,
      WindowSizeClass.expanded => expandedColumns,
    };

    return GridView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📱 ADAPTIVE LAYOUT
// ═══════════════════════════════════════════════════════════════════════════

/// Shows different layouts based on screen size
class AdaptiveLayout extends StatelessWidget {
  final Widget compact;
  final Widget? medium;
  final Widget? expanded;

  const AdaptiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final sizeClass = context.windowSizeClass;
    
    return switch (sizeClass) {
      WindowSizeClass.expanded => expanded ?? medium ?? compact,
      WindowSizeClass.medium => medium ?? compact,
      WindowSizeClass.compact => compact,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🃏 LIST-DETAIL LAYOUT (Canonical Layout)
// ═══════════════════════════════════════════════════════════════════════════

/// Material 3 List-Detail canonical layout
/// Shows list and detail side-by-side on large screens
class ListDetailLayout<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(T item, bool isSelected) listItemBuilder;
  final Widget Function(T item) detailBuilder;
  final Widget emptyListPlaceholder;
  final Widget emptyDetailPlaceholder;
  final double listWidth;
  final T? initialSelection;

  const ListDetailLayout({
    super.key,
    required this.items,
    required this.listItemBuilder,
    required this.detailBuilder,
    required this.emptyListPlaceholder,
    required this.emptyDetailPlaceholder,
    this.listWidth = 320,
    this.initialSelection,
  });

  @override
  State<ListDetailLayout<T>> createState() => _ListDetailLayoutState<T>();
}

class _ListDetailLayoutState<T> extends State<ListDetailLayout<T>> {
  T? _selectedItem;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final sizeClass = context.windowSizeClass;

    if (sizeClass == WindowSizeClass.compact) {
      return _buildCompactLayout(brightness);
    } else {
      return _buildExpandedLayout(brightness);
    }
  }

  Widget _buildCompactLayout(Brightness brightness) {
    // On compact: show list or detail based on selection
    if (_selectedItem != null) {
      return Scaffold(
        backgroundColor: AppColors.background(brightness),
        appBar: AppBar(
          backgroundColor: AppColors.surface(brightness),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: AppColors.text(brightness)),
            onPressed: () => setState(() => _selectedItem = null),
          ),
        ),
        body: widget.detailBuilder(_selectedItem as T),
      );
    }

    return _buildList(brightness, showDivider: false);
  }

  Widget _buildExpandedLayout(Brightness brightness) {
    // On expanded: show list and detail side by side
    return Row(
      children: [
        SizedBox(
          width: widget.listWidth,
          child: _buildList(brightness, showDivider: true),
        ),
        VerticalDivider(
          width: 1,
          color: AppColors.border(brightness),
        ),
        Expanded(
          child: _selectedItem != null
              ? widget.detailBuilder(_selectedItem as T)
              : widget.emptyDetailPlaceholder,
        ),
      ],
    );
  }

  Widget _buildList(Brightness brightness, {required bool showDivider}) {
    if (widget.items.isEmpty) {
      return widget.emptyListPlaceholder;
    }

    return ListView.separated(
      itemCount: widget.items.length,
      separatorBuilder: (context, index) => showDivider
          ? Divider(
              height: 1,
              color: AppColors.border(brightness),
              indent: 16,
              endIndent: 16,
            )
          : const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final isSelected = item == _selectedItem;
        
        return GestureDetector(
          onTap: () => setState(() => _selectedItem = item),
          child: widget.listItemBuilder(item, isSelected),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🌙 TIME-BASED THEME HELPERS
// ═══════════════════════════════════════════════════════════════════════════

/// Returns whether it's "night time" (after 8 PM or before 6 AM)
bool isNightTime() {
  final hour = DateTime.now().hour;
  return hour >= 20 || hour < 6;
}

/// Returns a color tint based on time of day for adaptive UI
Color getTimeBasedTint(Brightness brightness) {
  final hour = DateTime.now().hour;
  
  if (hour >= 6 && hour < 12) {
    // Morning - warm golden tint
    return brightness == Brightness.dark
        ? Colors.orange.withValues(alpha: 0.05)
        : Colors.orange.withValues(alpha: 0.03);
  } else if (hour >= 12 && hour < 17) {
    // Afternoon - neutral
    return Colors.transparent;
  } else if (hour >= 17 && hour < 20) {
    // Evening - warm sunset tint
    return brightness == Brightness.dark
        ? Colors.deepOrange.withValues(alpha: 0.05)
        : Colors.orange.withValues(alpha: 0.02);
  } else {
    // Night - cool blue tint
    return brightness == Brightness.dark
        ? Colors.blue.withValues(alpha: 0.03)
        : Colors.transparent;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📱 SAFE AREA PADDING HELPERS
// ═══════════════════════════════════════════════════════════════════════════

/// Get responsive horizontal padding based on screen size
double getResponsivePadding(BuildContext context) {
  final sizeClass = context.windowSizeClass;
  return switch (sizeClass) {
    WindowSizeClass.compact => 16,
    WindowSizeClass.medium => 24,
    WindowSizeClass.expanded => 32,
  };
}

/// Get responsive content max width
double getContentMaxWidth(BuildContext context) {
  final sizeClass = context.windowSizeClass;
  return switch (sizeClass) {
    WindowSizeClass.compact => double.infinity,
    WindowSizeClass.medium => 600,
    WindowSizeClass.expanded => 840,
  };
}
