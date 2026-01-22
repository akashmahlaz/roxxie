/// 🎭 SKELETON SCREENS
///
/// 2026 Design Trend: Premium Loading States
/// Shimmer-animated skeleton screens that match the actual UI structure
/// for smooth loading transitions (perceived performance)
///
/// Usage:
/// ```dart
/// if (isLoading)
///   HomeSkeletonScreen()
/// else
///   actualContent
/// ```
library;

import 'package:flutter/material.dart';
import '../core/theme/theme.dart';
import 'animated_micro_interactions.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🏠 HOME SCREEN SKELETON
// ═══════════════════════════════════════════════════════════════════════════

class HomeSkeletonScreen extends StatelessWidget {
  const HomeSkeletonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return ShimmerLoading(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App bar skeleton
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 100, height: 14),
                      const SizedBox(height: 8),
                      SkeletonBox(width: 150, height: 28),
                    ],
                  ),
                  const SkeletonCircle(size: 44),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Stats row skeleton
              Row(
                children: [
                  Expanded(child: _StatCardSkeleton()),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCardSkeleton()),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCardSkeleton()),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Section title
              SkeletonBox(width: 120, height: 18),
              const SizedBox(height: 12),
              
              // Action cards skeleton
              Row(
                children: [
                  Expanded(child: _ActionCardSkeleton()),
                  const SizedBox(width: 12),
                  Expanded(child: _ActionCardSkeleton()),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Recent matches section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 130, height: 18),
                  SkeletonBox(width: 60, height: 16),
                ],
              ),
              const SizedBox(height: 16),
              
              // Match previews
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, __) => const _MatchPreviewSkeleton(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          SkeletonCircle(size: 40),
          SizedBox(height: 12),
          SkeletonBox(width: 40, height: 22),
          SizedBox(height: 6),
          SkeletonBox(width: 60, height: 12),
        ],
      ),
    );
  }
}

class _ActionCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 130,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonCircle(size: 44),
          SizedBox(height: 16),
          SkeletonBox(width: 80, height: 18),
          SizedBox(height: 6),
          SkeletonBox(width: 100, height: 13),
        ],
      ),
    );
  }
}

class _MatchPreviewSkeleton extends StatelessWidget {
  const _MatchPreviewSkeleton();
  
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 80,
      child: Column(
        children: [
          SkeletonCircle(size: 64),
          SizedBox(height: 8),
          SkeletonBox(width: 50, height: 12),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔍 DISCOVERY SCREEN SKELETON
// ═══════════════════════════════════════════════════════════════════════════

class DiscoverySkeletonScreen extends StatelessWidget {
  const DiscoverySkeletonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 100, height: 28),
                  Row(
                    children: [
                      const SkeletonCircle(size: 44),
                      const SizedBox(width: 8),
                      const SkeletonCircle(size: 44),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Main card skeleton
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(width: 180, height: 28),
                            SizedBox(height: 8),
                            SkeletonBox(width: 140, height: 16),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                SkeletonBox(width: 80, height: 32, borderRadius: 16),
                                SizedBox(width: 8),
                                SkeletonBox(width: 80, height: 32, borderRadius: 16),
                                SizedBox(width: 8),
                                SkeletonBox(width: 80, height: 32, borderRadius: 16),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons skeleton
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SkeletonCircle(size: 56),
                  SkeletonCircle(size: 72),
                  SkeletonCircle(size: 56),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 💬 CHAT LIST SKELETON
// ═══════════════════════════════════════════════════════════════════════════

class ChatListSkeletonScreen extends StatelessWidget {
  const ChatListSkeletonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const _ChatItemSkeleton(),
      ),
    );
  }
}

class _ChatItemSkeleton extends StatelessWidget {
  const _ChatItemSkeleton();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          SkeletonCircle(size: 56),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBox(width: 120, height: 16),
                    SkeletonBox(width: 40, height: 12),
                  ],
                ),
                SizedBox(height: 8),
                SkeletonBox(width: double.infinity, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 👤 PROFILE SKELETON
// ═══════════════════════════════════════════════════════════════════════════

class ProfileSkeletonScreen extends StatelessWidget {
  const ProfileSkeletonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar
              const SkeletonCircle(size: 100),
              const SizedBox(height: 16),
              
              // Name
              SkeletonBox(width: 150, height: 24),
              const SizedBox(height: 8),
              
              // Role badge
              SkeletonBox(width: 60, height: 24, borderRadius: 12),
              const SizedBox(height: 24),
              
              // Stats
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.shimmerBase,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItemSkeleton(),
                    _StatItemSkeleton(),
                    _StatItemSkeleton(),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Menu items
              ...List.generate(5, (_) => const _MenuItemSkeleton()),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItemSkeleton extends StatelessWidget {
  const _StatItemSkeleton();
  
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SkeletonCircle(size: 40),
        SizedBox(height: 8),
        SkeletonBox(width: 30, height: 20),
        SizedBox(height: 4),
        SkeletonBox(width: 50, height: 12),
      ],
    );
  }
}

class _MenuItemSkeleton extends StatelessWidget {
  const _MenuItemSkeleton();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          SkeletonCircle(size: 40),
          SizedBox(width: 16),
          Expanded(child: SkeletonBox(width: double.infinity, height: 16)),
          SkeletonBox(width: 24, height: 24),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 📅 CALENDAR/GIGS SKELETON
// ═══════════════════════════════════════════════════════════════════════════

class CalendarSkeletonScreen extends StatelessWidget {
  const CalendarSkeletonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 120, height: 28),
                  const SkeletonCircle(size: 44),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Calendar header
              Center(child: SkeletonBox(width: 140, height: 20)),
              const SizedBox(height: 16),
              
              // Calendar grid
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.shimmerBase,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Week days
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SkeletonBox(width: 24, height: 14),
                        SkeletonBox(width: 24, height: 14),
                        SkeletonBox(width: 24, height: 14),
                        SkeletonBox(width: 24, height: 14),
                        SkeletonBox(width: 24, height: 14),
                        SkeletonBox(width: 24, height: 14),
                        SkeletonBox(width: 24, height: 14),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Calendar days
                    ...List.generate(5, (_) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SkeletonCircle(size: 32),
                          SkeletonCircle(size: 32),
                          SkeletonCircle(size: 32),
                          SkeletonCircle(size: 32),
                          SkeletonCircle(size: 32),
                          SkeletonCircle(size: 32),
                          SkeletonCircle(size: 32),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Upcoming section
              SkeletonBox(width: 100, height: 18),
              const SizedBox(height: 12),
              
              // Gig cards
              ...List.generate(3, (_) => const _GigCardSkeleton()),
            ],
          ),
        ),
      ),
    );
  }
}

class _GigCardSkeleton extends StatelessWidget {
  const _GigCardSkeleton();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 60, height: 60, borderRadius: 12),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140, height: 16),
                SizedBox(height: 6),
                SkeletonBox(width: 100, height: 14),
                SizedBox(height: 6),
                SkeletonBox(width: 80, height: 12),
              ],
            ),
          ),
          SkeletonBox(width: 60, height: 28, borderRadius: 14),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🎯 MATCH GRID SKELETON
// ═══════════════════════════════════════════════════════════════════════════

class MatchGridSkeletonScreen extends StatelessWidget {
  const MatchGridSkeletonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: 8,
        itemBuilder: (_, __) => const _MatchCardSkeleton(),
      ),
    );
  }
}

class _MatchCardSkeleton extends StatelessWidget {
  const _MatchCardSkeleton();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 100, height: 18),
                SizedBox(height: 6),
                SkeletonBox(width: 80, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
