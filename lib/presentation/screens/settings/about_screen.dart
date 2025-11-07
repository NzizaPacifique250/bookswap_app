import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// About screen showing app information and credits
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // App version - update manually or integrate package_info_plus later
  static const String _version = '1.0.0';
  static const String _buildNumber = '1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.accent,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'About',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.book,
                  size: 60,
                  color: AppColors.primaryBackground,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // App Name
            const Text(
              'BookSwap',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Version
            Text(
              'Version $_version (Build $_buildNumber)',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            
            // Description
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'BookSwap is a platform for book lovers to exchange their favorite reads with others. Discover new books, connect with fellow readers, and give your books a second life!',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            
            // Features
            _buildInfoSection(
              title: 'Features',
              items: [
                '📚 Browse available books',
                '🔄 Request book swaps',
                '💬 Chat with other users',
                '📖 Manage your listings',
                '🔔 Get notifications',
              ],
            ),
            const SizedBox(height: 24),
            
            // Credits
            _buildInfoSection(
              title: 'Credits',
              items: [
                'Developed with ❤️ using Flutter',
                'Firebase for backend services',
                'Icons from Material Design',
              ],
            ),
            const SizedBox(height: 24),
            
            // Contact
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Contact & Support',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactRow(
                    icon: Icons.email,
                    text: 'support@bookswap.com',
                  ),
                  const SizedBox(height: 12),
                  _buildContactRow(
                    icon: Icons.language,
                    text: 'www.bookswap.com',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Copyright
            Text(
              '© 2025 BookSwap. All rights reserved.',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<String> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  item,
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.accent,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

