import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/responsive_helper.dart';
import '../services/text_size_service.dart';
import '../config/app_colors.dart';
import '../widgets/back_button_widget.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.getPureAppBarBackground(Theme.of(context).brightness == Brightness.dark),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const BackButtonWidget(),
        title: Text(
          'Parents Responsable - Écran Test',
          style: TextStyle(
            fontSize: TextSizeService().getScaledFontSize(20),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveHelper.getPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeviceInfo(context),
            SizedBox(height: 20.h),
            _buildResponsiveCards(context),
            SizedBox(height: 20.h),
            _buildGridSection(context),
            SizedBox(height: 20.h),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfo(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations sur l\'appareil',
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Type: ${_getDeviceType(context)}',
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(context, 14),
              ),
            ),
            Text(
              'Largeur: ${ResponsiveHelper.getWidth(context).toInt()}px',
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(context, 14),
              ),
            ),
            Text(
              'Hauteur: ${ResponsiveHelper.getHeight(context).toInt()}px',
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(context, 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveCards(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cartes responsives',
          style: TextStyle(
            fontSize: ResponsiveHelper.getFontSize(context, 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10.h),
        if (isMobile) ...[
          _buildCard('Carte 1', 'Contenu pour mobile', Colors.red),
          SizedBox(height: 10.h),
          _buildCard('Carte 2', 'Contenu pour mobile', Colors.green),
          SizedBox(height: 10.h),
          _buildCard('Carte 3', 'Contenu pour mobile', Colors.blue),
        ] else if (isTablet) ...[
          Row(
            children: [
              Expanded(child: _buildCard('Carte 1', 'Contenu pour tablette', Colors.red)),
              SizedBox(width: 10.w),
              Expanded(child: _buildCard('Carte 2', 'Contenu pour tablette', Colors.green)),
            ],
          ),
          SizedBox(height: 10.h),
          _buildCard('Carte 3', 'Contenu pour tablette', Colors.blue),
        ] else ...[
          Row(
            children: [
              Expanded(child: _buildCard('Carte 1', 'Contenu pour desktop', Colors.red)),
              SizedBox(width: 10.w),
              Expanded(child: _buildCard('Carte 2', 'Contenu pour desktop', Colors.green)),
              SizedBox(width: 10.w),
              Expanded(child: _buildCard('Carte 3', 'Contenu pour desktop', Colors.blue)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCard(String title, String content, Color color) {
    return Builder(
      builder: (context) => Card(
        elevation: 4,
        color: color.withOpacity(0.1),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(context, 16),
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                content,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(context, 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grille responsivé',
          style: TextStyle(
            fontSize: ResponsiveHelper.getFontSize(context, 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveHelper.getCrossAxisCount(context),
            crossAxisSpacing: 10.w,
            mainAxisSpacing: 10.h,
            childAspectRatio: 1.0,
          ),
          itemCount: 8,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.primaries[index % Colors.primaries.length],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Text(
                  'Item ${index + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.getFontSize(context, 14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Boutons d\'action',
          style: TextStyle(
            fontSize: ResponsiveHelper.getFontSize(context, 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10.h),
        if (isMobile) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h),
              ),
              child: Text(
                'Bouton principal',
                style: TextStyle(fontSize: ResponsiveHelper.getFontSize(context, 16)),
              ),
            ),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                  ),
                  child: Text(
                    'Bouton principal',
                    style: TextStyle(fontSize: ResponsiveHelper.getFontSize(context, 16)),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                  ),
                  child: Text(
                    'Bouton secondaire',
                    style: TextStyle(fontSize: ResponsiveHelper.getFontSize(context, 16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _getDeviceType(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) {
      return 'Mobile';
    } else if (ResponsiveHelper.isTablet(context)) {
      return 'Tablette';
    } else {
      return 'Desktop';
    }
  }
}
