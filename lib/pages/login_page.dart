import 'package:flutter/material.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/role.dart';
import 'package:msw_eplant/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  UserRole? _selectedRole;
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = CurvedAnimation(parent: _slideController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _selectRole(UserRole role) {
    setState(() {
      _selectedRole = role;
      _errorMessage = null;
      if (role.requiresPassword) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    });
  }

  Future<void> _handleLogin() async {
    if (_selectedRole == null) return;
    if (_selectedRole!.requiresPassword && _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Masukkan password');
      return;
    }
    setState(() => _isLoading = true);

    final valid = await AuthService.verifyPassword(_selectedRole!, _passwordController.text);

    if (!mounted) return;

    if (valid) {
      await AuthService.saveSession(_selectedRole!);
      setState(() => _isLoading = false);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        _errorMessage = 'Password salah. Coba lagi.';
        _isLoading = false;
      });
    }
  }

  Color get _selectedColor {
    if (_selectedRole == null) return AppColors.primary;
    return AppColors.roleColor(_selectedRole!.label);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('asset/msw.png'),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.75),
            BlendMode.darken,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const SizedBox(height: 18),
                _buildLogo(),
                const SizedBox(height: 12),
                const Text(
                  'MSW ePlant',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text),
                ),
                const SizedBox(height: 4),
                Text(
                  'PT Makmur Sejahtera Wisesa\n2\u00D730 MW CFPP + Solar PV',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: AppColors.textSub, height: 1.5),
                ),
                const SizedBox(height: 36),
                _buildSectionLabel('Masuk sebagai'),
                const SizedBox(height: 10),
                _buildRoleCards(),
                const SizedBox(height: 16),
                if (_selectedRole != null && _selectedRole!.requiresPassword)
                  _buildPasswordSection(),
                const SizedBox(height: 20),
                _buildLoginButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        child: Image.asset('asset/logo_login.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textSub,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildRoleCards() {
    return Column(
      children: UserRole.values.map((role) {
        final selected = _selectedRole == role;
        final color = AppColors.roleColor(role.label);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => _selectRole(role),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(0.08) : Colors.black.withOpacity(0.65),
                border: Border.all(
                  color: selected ? color : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: color.withOpacity(0.14),
                    ),
                    child: Center(
                      child: Text(role.icon, style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          role.description,
                          style: const TextStyle(fontSize: 14, color: AppColors.textSub),
                        ),
                      ],
                    ),
                  ),
          
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPasswordSection() {
    return SizeTransition(
      sizeFactor: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Password ${_selectedRole!.label}'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              border: Border.all(
                color: _errorMessage != null ? AppColors.danger : AppColors.border,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('\uD83D\uDD11', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    style: const TextStyle(color: AppColors.text, fontSize: 14),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Input Password',
                      hintStyle: TextStyle(color: AppColors.textDim),
                    ),
                    onChanged: (_) => setState(() => _errorMessage = null),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showPassword = !_showPassword),
                  child: Text(
                    _showPassword ? '\uD83D\uDC41' : '\uD83D\uDC41',
                    style: const TextStyle(fontSize: 14, color: AppColors.textDim),
                  ),
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('\u26A0\uFE0F', style: TextStyle(fontSize: 14, color: AppColors.danger)),
                const SizedBox(width: 4),
                Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 14, color: AppColors.danger),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    final enabled = _selectedRole != null &&
        (!_selectedRole!.requiresPassword || _passwordController.text.isNotEmpty);
    final color = _selectedColor;

    return GestureDetector(
      onTap: enabled && !_isLoading ? _handleLogin : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  colors: [color, color == AppColors.general ? const Color(0xFF00A878) : const Color(0xFF0072FF)],
                )
              : null,
          color: enabled ? null : Colors.black.withOpacity(0.65),
          borderRadius: BorderRadius.circular(13),
          boxShadow: enabled
              ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 6))]
              : null,
        ),
        child: _isLoading
            ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                ),
              )
            : Text(
                _selectedRole != null
                    ? 'Masuk sebagai ${_selectedRole!.label} \u2192'
                    : 'Pilih role untuk masuk',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: enabled ? Colors.black : AppColors.textDim,
                ),
              ),
      ),
    );
  }
}
