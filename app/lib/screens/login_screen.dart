import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/google_logo.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _loading = false;
  bool _googleLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await ApiService().register(
          _emailController.text,
          _passwordController.text,
          name: _nameController.text.isNotEmpty ? _nameController.text : null,
        );
      } else {
        await ApiService().login(
          _emailController.text,
          _passwordController.text,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _submitGoogle() async {
    setState(() {
      _googleLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService().loginWithGoogle();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _googleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Icon / Logo
                  const Center(
                    child: AppLogo(size: 64, borderRadius: 18),
                  ),
                  const SizedBox(height: 20),

                  // Header title
                  Text(
                    _isSignUp ? 'Create TodoCat Account' : 'Welcome to TodoCat',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isSignUp
                        ? 'Sign up to sync your tasks with TodoCat'
                        : 'Sign in to access your tasks from any device',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFA3A3A3),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign In / Sign Up Selector Buttons
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF171717),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF262626)),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (_isSignUp) {
                                setState(() {
                                  _isSignUp = false;
                                  _errorMessage = null;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isSignUp ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  color: !_isSignUp
                                      ? const Color(0xFF0A0A0A)
                                      : const Color(0xFFA3A3A3),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (!_isSignUp) {
                                setState(() {
                                  _isSignUp = true;
                                  _errorMessage = null;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isSignUp ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: _isSignUp
                                      ? const Color(0xFF0A0A0A)
                                      : const Color(0xFFA3A3A3),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Error banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFF43F5E).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 18,
                            color: Color(0xFFFB7185),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFB7185),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Name Field (only if Sign Up)
                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: _inputDecoration(
                        labelText: 'Name (Optional)',
                        hintText: 'Your nickname or name',
                        prefixIcon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: _inputDecoration(
                      labelText: 'Email',
                      hintText: 'name@example.com',
                      prefixIcon: Icons.mail_outline,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!val.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: _inputDecoration(
                      labelText: 'Password',
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_outline,
                    ),
                    validator: (val) {
                      if (val == null || val.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: (_loading || _googleLoading) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0A0A0A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF0A0A0A),
                            ),
                          )
                        : Text(
                            _isSignUp ? 'Sign Up' : 'Sign In',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  const Row(
                    children: [
                      Expanded(
                        child: Divider(color: Color(0xFF262626), thickness: 1),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Color(0xFF737373),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Color(0xFF262626), thickness: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Continue with Google Button
                  OutlinedButton(
                    onPressed: (_loading || _googleLoading) ? null : _submitGoogle,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF171717),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF262626)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _googleLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GoogleLogo(size: 18),
                              SizedBox(width: 10),
                              Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Toggle mode button
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Sign In'
                          : 'Need an account? Sign Up',
                      style: const TextStyle(
                        color: Color(0xFFA3A3A3),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: const TextStyle(color: Color(0xFFA3A3A3), fontSize: 13),
      hintStyle: const TextStyle(color: Color(0xFF525252), fontSize: 13),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFFA3A3A3), size: 18),
      filled: true,
      fillColor: const Color(0xFF171717),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF262626)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF262626)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF525252)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF43F5E)),
      ),
    );
  }
}
