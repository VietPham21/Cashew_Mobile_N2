import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';

const _forest = Color(0xFF174F43);
const _green = Color(0xFF187E68);
const _ink = Color(0xFF1B2923);
const _muted = Color(0xFF78847D);

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  String? _friendlyError(String? error) {
    if (error == null) return null;
    final value = error.toLowerCase();
    if (value.contains('popup-blocked')) {
      return 'Trình duyệt đã chặn cửa sổ đăng nhập. Hãy mở trang bằng Chrome và cho phép pop-up cho website này.';
    }
    if (value.contains('unauthorized-domain')) {
      return 'Tên miền này chưa được thêm vào Firebase Authentication → Authorized domains.';
    }
    if (value.contains('api_exception: 10') ||
        value.contains('developer_error')) {
      return 'Cấu hình Google Sign-In chưa khớp với ứng dụng Android. Hãy kiểm tra package name và SHA-1 trong Firebase.';
    }
    return 'Đăng nhập chưa thành công. Hãy kiểm tra kết nối rồi thử lại.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4EF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final desktop = viewport.maxWidth >= 860;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: desktop ? 28 : 20,
                vertical: desktop ? 30 : 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: desktop
                      ? SizedBox(
                          height: viewport.maxHeight - 60,
                          child: Row(
                            children: [
                              const Expanded(flex: 6, child: _WelcomePanel()),
                              const SizedBox(width: 22),
                              Expanded(
                                flex: 4,
                                child: _LoginCard(errorText: _friendlyError),
                              ),
                            ],
                          ),
                        )
                      : _LoginCard(errorText: _friendlyError),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF123E35), Color(0xFF21856D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            right: -120,
            top: -120,
            child: _ring(390, Colors.white.withValues(alpha: .07)),
          ),
          Positioned(
            right: -15,
            bottom: -155,
            child: _ring(350, const Color(0xFFD8E982).withValues(alpha: .10)),
          ),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _brandMark(size: 58),
                const SizedBox(height: 42),
                const Text(
                  'Học tập có tổ chức.\nChia sẻ có chọn lọc.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.8,
                  ),
                ),
                const SizedBox(height: 17),
                Text(
                  'Giữ tài liệu, ý tưởng và nguồn tham khảo của bạn trong cùng một thư viện học tập.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .75),
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 35),
                const _FeatureLine(
                  icon: Icons.sell_outlined,
                  text: 'Phân loại nhanh bằng môn học và tags',
                ),
                const SizedBox(height: 15),
                const _FeatureLine(
                  icon: Icons.location_on_outlined,
                  text: 'Gắn vị trí cho tài liệu vật lý',
                ),
                const SizedBox(height: 15),
                const _FeatureLine(
                  icon: Icons.verified_user_outlined,
                  text: 'Chia sẻ quyền xem và chỉnh sửa',
                ),
              ],
            ),
          ),
          const Positioned(
            left: 48,
            bottom: 28,
            child: Text(
              'STUDY DOCS CLOUD  ·  YOUR LEARNING LIBRARY',
              style: TextStyle(
                color: Color(0xBFFFFFFF),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: color, width: 32),
    ),
  );
}

class _LoginCard extends StatelessWidget {
  final String? Function(String?) errorText;

  const _LoginCard({required this.errorText});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        final mobile = MediaQuery.sizeOf(context).width < 600;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 25 : 34,
            vertical: mobile ? 34 : 42,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFE5EAE3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF203A2B).withValues(alpha: .07),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mobile) ...[_brandMark(size: 50), const SizedBox(height: 28)],
              const Text(
                'Chào mừng trở lại',
                style: TextStyle(
                  color: _ink,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Đăng nhập để mở thư viện học tập của bạn.',
                style: TextStyle(color: _muted, height: 1.5, fontSize: 14),
              ),
              const SizedBox(height: 30),
              if (vm.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2EB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF6D7C8)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 19,
                        color: Color(0xFFB65535),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          errorText(vm.errorMessage) ?? '',
                          style: const TextStyle(
                            color: Color(0xFF8F452D),
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              if (vm.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: _green),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: vm.signIn,
                    icon: const Text(
                      'G',
                      style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    label: const Text('Tiếp tục với Google'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ink,
                      side: const BorderSide(color: Color(0xFFDDE3DC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFEBEFEB)),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: _green,
                    size: 17,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Tài liệu riêng tư chỉ hiển thị với bạn và người được cấp quyền.',
                      style: TextStyle(
                        color: Colors.blueGrey.shade600,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget _brandMark({required double size}) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    color: _green,
    borderRadius: BorderRadius.circular(size * .28),
    boxShadow: [
      BoxShadow(
        color: _green.withValues(alpha: .22),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  ),
  child: Icon(
    Icons.local_library_rounded,
    color: Colors.white,
    size: size * .53,
  ),
);

class _FeatureLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: const Color(0xFFD8E982), size: 20),
      const SizedBox(width: 12),
      Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
