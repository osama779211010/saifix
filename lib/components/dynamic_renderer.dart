import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../screens/recharge_and_payment_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class DynamicScreenRenderer extends StatelessWidget {
  final Map<String, dynamic> config;
  final bool isDarkMode;

  const DynamicScreenRenderer({
    super.key,
    required this.config,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> widgets = config['widgets'] ?? [];
    final String? backgroundColorHex = config['background_color'];
    
    return Container(
      color: backgroundColorHex != null 
        ? _parseColor(backgroundColorHex) 
        : (isDarkMode ? AppColors.scaffoldDark : Colors.white),
      child: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: widgets.length,
          itemBuilder: (context, index) {
            return _buildWidget(context, widgets[index]);
          },
        ),
      ),
    );
  }

  Widget _buildWidget(BuildContext context, Map<String, dynamic> data) {
    final String type = data['type'] ?? 'unknown';
    // Use 'props' as primary, fallback to 'properties' for backward compatibility
    final Map<String, dynamic> props = data['props'] ?? data['properties'] ?? {};

    switch (type) {
      case 'text':
        return _buildText(props);
      case 'button':
        return _buildButton(context, props);
      case 'image':
        return _buildImage(props);
      case 'spacer':
        return SizedBox(height: (props['height'] ?? 20).toDouble());
      case 'container':
        return _buildContainer(context, props);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildText(Map<String, dynamic> props) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        props['text'] ?? '',
        textAlign: _parseTextAlign(props['textAlign']),
        style: GoogleFonts.cairo(
          fontSize: (props['fontSize'] ?? 16).toDouble(),
          color: _parseColor(props['color'] ?? '#000000'),
          fontWeight: _parseFontWeight(props['fontWeight']),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, Map<String, dynamic> props) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ElevatedButton(
        onPressed: () => _handleAction(context, props['action']),
        style: ElevatedButton.styleFrom(
          backgroundColor: _parseColor(props['backgroundColor'] ?? '#004B87'),
          foregroundColor: _parseColor(props['textColor'] ?? '#FFFFFF'),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular((props['borderRadius'] ?? 8).toDouble()),
          ),
          elevation: 2,
        ),
        child: Text(
          props['text'] ?? props['label'] ?? '',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: (props['fontSize'] ?? 16).toDouble(),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Map<String, dynamic> props) {
    final String src = props['src'] ?? '';
    if (src.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _isUrl(src)
            ? Image.network(
                src,
                height: (props['height'] ?? 200).toDouble(),
                width: double.infinity,
                fit: _parseBoxFit(props['fit']),
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.broken_image, size: 50, color: Colors.grey),
              )
            : Image.asset(
                src,
                height: (props['height'] ?? 200).toDouble(),
                width: double.infinity,
                fit: _parseBoxFit(props['fit']),
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.broken_image, size: 50, color: Colors.grey),
              ),
      ),
    );
  }

  Widget _buildContainer(BuildContext context, Map<String, dynamic> props) {
    return Container(
      padding: EdgeInsets.all((props['padding'] ?? 10).toDouble()),
      constraints: BoxConstraints(minHeight: (props['minHeight'] ?? 50).toDouble()),
      decoration: BoxDecoration(
        color: _parseColor(props['backgroundColor'] ?? '#00000000'),
        borderRadius: BorderRadius.circular((props['borderRadius'] ?? 0).toDouble()),
      ),
      child: const SizedBox.shrink(), // Flat structure revert: No children mapping
    );
  }

  // --- Helpers ---

  void _handleAction(BuildContext context, Map<String, dynamic>? action) {
    if (action == null) return;
    
    final String type = action['type'] ?? 'none';
    final String target = action['target'] ?? '';

    switch (type) {
      case 'navigate':
        _handleNavigation(context, target);
        break;
      case 'url':
        _launchUrl(target);
        break;
      default:
        break;
    }
  }

  void _handleNavigation(BuildContext context, String target) {
    if (target == 'recharge_payment') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RechargeAndPaymentScreen(isDarkMode: isDarkMode),
        ),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex == 'transparent' || hex == '#00000000') return Colors.transparent;
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.black;
    }
  }

  TextAlign _parseTextAlign(String? align) {
    switch (align) {
      case 'left': return TextAlign.left;
      case 'center': return TextAlign.center;
      case 'right': return TextAlign.right;
      default: return TextAlign.right;
    }
  }

  FontWeight _parseFontWeight(String? weight) {
    switch (weight) {
      case 'bold': return FontWeight.bold;
      case 'w600': return FontWeight.w600;
      default: return FontWeight.normal;
    }
  }

  BoxFit _parseBoxFit(String? fit) {
    switch (fit) {
      case 'contain': return BoxFit.contain;
      case 'cover': return BoxFit.cover;
      case 'fill': return BoxFit.fill;
      default: return BoxFit.cover;
    }
  }

  bool _isUrl(String path) {
    return path.startsWith('http') || path.startsWith('https');
  }
}
