import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'widgets/challenges_list.dart';
import 'widgets/leaderboard_list.dart';
import 'widgets/social_feed.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'Challenges'),
                Tab(text: 'Leaderboard'),
                Tab(text: 'Feed'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                ChallengesList(),
                LeaderboardList(),
                SocialFeed(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
