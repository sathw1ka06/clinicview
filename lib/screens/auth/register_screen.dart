import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../providers/app_provider.dart';
import '../../widgets/auth_frame.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      // 1. Temporarily save the data to the provider
      context.read<AppProvider>().setTempRegistration(
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      // 2. Safely navigate to the security questions screen
      context.go('/security-questions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      title: 'Create Account',
      subtitle: 'Join Cliniview Workspace today.',
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
                decorationThickness: 2
              ),
              recognizer: TapGestureRecognizer()..onTap = () => context.go('/login'),
            ),
          ],
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _firstNameController,
                    hint: 'First Name',
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _lastNameController,
                    hint: 'Last Name',
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _emailController,
              hint: 'Email Address',
              validator: (val) {
                if (val == null || val.isEmpty) return 'Required';
                if (!val.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _passwordController,
              hint: 'Password',
              isPassword: true,
              validator: (val) => val == null || val.length < 6 ? 'Minimum 6 characters' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _confirmPasswordController,
              hint: 'Confirm Password',
              isPassword: true,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Required';
                if (val != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Next',
              onPressed: _handleNext,
            ),
          ],
        ),
      ),
    );
  }
}