//terms_and_conditions_screen.dart
// ============================================================================
// Terms & Conditions Screen
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/settings_provider.dart';
import 'main_menu_screen.dart';

class TermsAndConditionsScreen extends StatefulWidget
{
  static const routeName = '/terms';

  const TermsAndConditionsScreen({super.key});

  @override
  State<TermsAndConditionsScreen> createState() => _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen>
{
  final _authService = AuthService();
  bool _hasAgreed = false;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleContinue() async
  {
    final user = _authService.currentUser;

    setState(()
    {
      _isLoading = true;
      _errorMessage = null;
    });

    try
    {
      if (user != null) {
        await _authService.setTermsAccepted(user.uid);
      }

      if (mounted)
      {
        Navigator.of(context).pushReplacementNamed(MainMenuScreen.routeName);
      }
    }
    catch (e)
    {
      if (mounted)
      {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
    finally
    {
      if (mounted)
      {
        setState(()
        {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleReject() async
  {
    final bool? shouldReject = await showDialog<bool>(
      context: context,
      builder: (BuildContext context)
      {
        return AlertDialog(
          title: const Text('Reject Terms & Conditions?'),
          content: const Text(
            'If you reject the terms, you will be logged out and cannot use the app until you accept them.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Reject & Logout'),
            ),
          ],
        );
      },
    );

    if (shouldReject == true && mounted)
    {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth-wrapper');
      }
    }
  }

  @override
  Widget build(BuildContext context)
  {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: settings.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: settings.textOnCardColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome to Wonder Crayon!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: settings.textOnCardColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'By using Wonder Crayon, you agree to the following terms and conditions:',
                          style: TextStyle(
                            fontSize: 14,
                            color: settings.textOnCardColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          '1. Acceptance of Terms',
                          'By accessing and using Wonder Crayon, you accept and agree to be bound by the terms and provision of this agreement.',
                          settings,
                        ),
                        _buildSection(
                          '2. User Account',
                          'You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account.',
                          settings,
                        ),
                        _buildSection(
                          '3. Content Creation',
                          'Wonder Crayon allows you to create stories and illustrations. You retain ownership of your created content. However, you grant us the right to use, display, and store your content for the purpose of providing our services.',
                          settings,
                        ),
                        _buildSection(
                          '4. AI-Generated Content',
                          'Content generated using AI features may not be entirely original. We do not guarantee the uniqueness or copyright status of AI-generated content. It is your responsibility to ensure any published content complies with copyright laws.',
                          settings,
                        ),
                        _buildSection(
                          '5. Privacy',
                          'We respect your privacy and protect your personal information. Your data will be stored securely and will not be shared with third parties without your consent.',
                          settings,
                        ),
                        _buildSection(
                          '6. Prohibited Use',
                          'You agree not to use Wonder Crayon to create, store, or share content that is illegal, harmful, threatening, abusive, harassing, defamatory, vulgar, obscene, or otherwise objectionable.',
                          settings,
                        ),
                        _buildSection(
                          '7. Service Availability',
                          'We strive to provide uninterrupted service, but we do not guarantee that the service will be available at all times. We may suspend, withdraw, or restrict the availability of all or any part of our service.',
                          settings,
                        ),
                        _buildSection(
                          '8. Modifications to Terms',
                          'We reserve the right to modify these terms at any time. Continued use of the service after changes constitutes acceptance of the modified terms.',
                          settings,
                        ),
                        _buildSection(
                          '9. Limitation of Liability',
                          'Wonder Crayon is provided "as is" without warranties of any kind. We shall not be liable for any indirect, incidental, special, consequential, or punitive damages.',
                          settings,
                        ),
                        _buildSection(
                          '10. Contact',
                          'If you have any questions about these Terms & Conditions, please contact us through the app settings.',
                          settings,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Last Updated: December 3, 2025',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: settings.textOnCardColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorMessage != null) const SizedBox(height: 8),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _hasAgreed,
                      onChanged: _isLoading
                          ? null
                          : (value)
                            {
                              setState(()
                              {
                                _hasAgreed = value ?? false;
                              });
                            },
                      activeColor: settings.primaryGradientEnd,
                    ),
                    Expanded(
                      child: Text(
                        'I agree to the Terms & Conditions',
                        style: TextStyle(
                          fontSize: 16,
                          color: settings.textOnCardColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _handleReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Reject',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: (_hasAgreed && !_isLoading) ? _handleContinue : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: settings.primaryGradientEnd,
                          disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
                          disabledForegroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, SettingsProvider settings)
  {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: settings.textOnCardColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: settings.textOnCardColor.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
