import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../providers/app_provider.dart';
import '../../widgets/auth_frame.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class SecurityQuestionsScreen extends StatefulWidget {
  const SecurityQuestionsScreen({super.key});

  @override
  State<SecurityQuestionsScreen> createState() =>
      _SecurityQuestionsScreenState();
}

class _SecurityQuestionsScreenState extends State<SecurityQuestionsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _answer1Controller = TextEditingController();
  final _answer2Controller = TextEditingController();
  final _answer3Controller = TextEditingController();

  // Initial states strictly matched to PDF requirements
  String _q1 = 'What is your favourite fruit?';
  String _q2 = 'What is your birth place?';
  String _q3 = 'What is your first job?';

  @override
  void dispose() {
    _answer1Controller.dispose();
    _answer2Controller.dispose();
    _answer3Controller.dispose();
    super.dispose();
  }

  // FIX: This now captures the dynamic error message and displays it!
  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final errorMessage = await context.read<AppProvider>().completeRegistration(
        _q1,
        _answer1Controller.text.trim(),
        _q2,
        _answer2Controller.text.trim(),
        _q3,
        _answer3Controller.text.trim(),
      );

      if (errorMessage == null && mounted) {
        // Success!
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please log in.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/login');
      } else if (mounted) {
        // Failed! Show the exact error message from the backend
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Registration failed. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildDropdown(
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      items: options.map((String option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option, style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AppProvider>().isLoading;

    return AuthFrame(
      title: 'Security Question',
      subtitle: 'Add security answers for account recovery.',
      bottomText: RichText(
        text: TextSpan(
          text: "Already have an account? ",
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          children: [
            TextSpan(
              text: 'Login',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.focusBorder,
                decorationThickness: 2,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => context.go('/login'),
            ),
          ],
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildDropdown(_q1, [
              'What is your favourite fruit?',
            ], (v) => setState(() => _q1 = v!)),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _answer1Controller,
              hint: 'Answer',
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            _buildDropdown(_q2, [
              'What is your birth place?',
            ], (v) => setState(() => _q2 = v!)),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _answer2Controller,
              hint: 'Answer',
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            _buildDropdown(_q3, [
              'What is your first job?',
            ], (v) => setState(() => _q3 = v!)),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _answer3Controller,
              hint: 'Answer',
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Back',
                    isOutlined: true,
                    onPressed: () => context.go('/register'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Register',
                    isLoading: isLoading,
                    onPressed: _handleRegister,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}