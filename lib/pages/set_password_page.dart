import 'package:flutter/material.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/widgets/password_gate.dart';

class SetPasswordPage extends StatefulWidget {
  const SetPasswordPage({super.key});

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  bool _authenticated = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('asset/msw.png'),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.75), BlendMode.darken),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Set Password Login'),
        ),
        // body: _authenticated ? _buildPasswordList() : _buildGate(),
        body:  _buildPasswordList() 
      ),
    );
  }

  Widget _buildGate() {
    return SingleChildScrollView(
      child: PasswordGate(
        title: 'Set Password Login',
        subtitle: 'Menu ini memerlukan password Admin untuk\nmengubah password login semua role.',
        icon: '\uD83D\uDD11',
        color: AppColors.purple,
        roleLabel: 'Admin Password',
        roleIcon: '\uD83D\uDD11',
        roleDescription: 'Ubah password login semua role app',
        onUnlock: () => setState(() => _authenticated = true),
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildPasswordList() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Password login disimpan di Firestore dan berlaku untuk semua device. Perubahan langsung aktif tanpa perlu update app.',
              style: TextStyle(fontSize: 14, color: AppColors.textSub, height: 1.6),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              'PASSWORD PER ROLE',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSub, letterSpacing: 0.6),
            ),
          ),
          _buildRolePasswordCard(
            icon: '\u26A1',
            label: 'Operation',
            color: AppColors.primary,
            hint: 'Password ini dipakai saat login sebagai Operator Shift. Bagikan ke Kepala Shift dan Operator.',
            lastChanged: '3 Jan 2026',
          ),
          _buildRolePasswordCard(
            icon: '\uD83D\uDD27',
            label: 'Maintenance',
            color: AppColors.maintenance,
            hint: 'Password ini dipakai saat login sebagai Teknisi Maintenance. Bagikan ke tim maintenance.',
            lastChanged: '3 Jan 2026',
          ),
          _buildRolePasswordCard(
            icon: '\uD83C\uDFAF',
            label: 'OKR Editor',
            color: AppColors.general,
            hint: 'Password khusus untuk membuka OKR Editor di Setting. Terpisah dari password login role.',
            lastChanged: '3 Jan 2026',
          ),
          _buildRolePasswordCard(
            icon: '\uD83D\uDEE1',
            label: 'Admin Master',
            color: AppColors.purple,
            hint:
                'Password tertinggi \u2014 untuk membuka halaman Set Password ini. Simpan dengan aman, hanya untuk IC&IT Supervisor.',
            lastChanged: '3 Jan 2026',
            isMaster: true,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRolePasswordCard({
    required String icon,
    required String label,
    required Color color,
    required String hint,
    required String lastChanged,
    bool isMaster = false,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              border: Border(
                bottom: const BorderSide(color: AppColors.border),
                left: BorderSide(color: color, width: 3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: color.withOpacity(0.15)),
                  child: Center(child: Text(icon, style: const TextStyle(fontSize: 14))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isMaster ? AppColors.purple.withOpacity(0.1) : AppColors.general.withOpacity(0.1),
                    border: Border.all(
                      color: isMaster ? AppColors.purple.withOpacity(0.2) : AppColors.general.withOpacity(0.2),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isMaster ? '\uD83D\uDEE1 Master' : '\u2713 Sudah diset',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isMaster ? AppColors.purple : AppColors.general,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('\uD83D\uDD50', style: TextStyle(fontSize: 14, color: AppColors.textDim)),
                    const SizedBox(width: 4),
                    Text(
                      'Terakhir diubah: $lastChanged \u00B7 Admin',
                      style: const TextStyle(fontSize: 14, color: AppColors.textDim),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(hint, style: const TextStyle(fontSize: 14, color: AppColors.textSub, height: 1.4)),
                const SizedBox(height: 10),
                _buildInputGroup('Password Baru', 'Masukkan password baru'),
                const SizedBox(height: 10),
                _buildInputGroup('Konfirmasi Password', 'Ulangi password baru'),
                const SizedBox(height: 8),
                GestureDetector(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      border: Border.all(color: color.withOpacity(0.25)),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '\uD83D\uDCBE Simpan Password $label',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputGroup(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSub,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextField(
            obscureText: true,
            style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, letterSpacing: 2),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(
                letterSpacing: 0,
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: AppColors.textDim,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
