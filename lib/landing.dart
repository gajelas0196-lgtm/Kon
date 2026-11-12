import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart';
import 'update_checker.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  // ─── WARNA ORANGE + HITAM ──────────────────────────────────────────────
  static const Color primaryOrange = Color(0xFFFF6D00);
  static const Color primaryOrangeLight = Color(0xFFFF9100);
  static const Color accentGold = Color(0xFFFFB300);
  static const Color darkBackground = Color(0xFF050505);
  static const Color surfaceColor = Color(0xFF181818);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFFFFB300);
  static const Color dividerColor = Color(0xFF3D1F00);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _logoScale;
  late Animation<Offset> _titleSlide;
  late Animation<double> _cardOpacity;
  late Animation<double> _buttonSlide;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateChecker.checkAndPromptUpdate(context);
    });

    _videoController = VideoPlayerController.asset("assets/videos/banner.mp4")
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController.setLooping(true);
        _videoController.setVolume(0);
        _videoController.play();
      });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.5, curve: Curves.elasticOut),
      ),
    );

    _titleSlide = Tween<Offset>(begin: const Offset(0, 30), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
          ),
        );

    _cardOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeInOut),
      ),
    );

    _buttonSlide = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _videoController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: LandingPage.darkBackground,
      body: Container(
        height: screenHeight,
        child: Stack(
          children: [
            // ─── BACKGROUND HITAM ──────────────────────────────────────
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF050505),
                      Color(0xFF0A0A0A),
                      Color(0xFF050505),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // ─── GLOW ORANGE ────────────────────────────────────────────
            Positioned(
              top: -100,
              left: 0,
              right: 0,
              child: Container(
                height: 350,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.0,
                    colors: [
                      const Color(0xFFFF6D00).withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ─── GRID ──────────────────────────────────────────────────
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),

            // ─── KONTEN ──────────────────────────────────────────────────
            SafeArea(
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 600,
                    maxHeight: screenHeight * 0.9,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ─── VIDEO BANNER ──────────────────────────────────
                      ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          width: 320,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: dividerColor, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.6),
                                blurRadius: 40,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: const Color(0xFFFF6D00).withOpacity(0.08),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _isVideoInitialized
                                ? VideoPlayer(_videoController)
                                : Center(
                                    child: CircularProgressIndicator(
                                      color: const Color(0xFFFF6D00),
                                      strokeWidth: 1.5,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ─── TITLE ──────────────────────────────────────────
                      SlideTransition(
                        position: _titleSlide,
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFFE6EDF3),
                                  Color(0xFFFF6D00),
                                  Color(0xFFFFB300),
                                  Color(0xFFE6EDF3),
                                ],
                                stops: [0.05, 0.35, 0.65, 0.95],
                              ).createShader(bounds),
                              child: const Text(
                                "MANTA'X",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 52,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 6,
                                  height: 0.9,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: 120,
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    const Color(0xFFFF6D00).withOpacity(0.6),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              "GACOR · TERUPDATE · STABIL",
                              style: TextStyle(
                                color: const Color(0xFFFF6D00).withOpacity(0.6),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ─── CARD ────────────────────────────────────────────
                      FadeTransition(
                        opacity: _cardOpacity,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF3D1F00),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.45),
                                blurRadius: 40,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6D00).withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFFF6D00).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.shield_outlined,
                                  color: Color(0xFFFF6D00),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "MANTA BUG",
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Aplikasi dengan design elegant dan fitur terbaru. Pengembangan langsung oleh TEAM MANTA.",
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 13,
                                  height: 1.7,
                                  fontWeight: FontWeight.w300,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ─── BUTTONS ─────────────────────────────────────────
                      AnimatedBuilder(
                        animation: _buttonSlide,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _buttonSlide.value),
                            child: child,
                          );
                        },
                        child: Column(
                          children: [
                            _ElevatedButton(
                              onPressed: () async {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                if (baseUrl.isEmpty) {
                                  await loadConfig();
                                }

                                Navigator.pop(context);

                                if (baseUrl.isEmpty) {
                                  _showError("Server belum siap. Coba lagi.");
                                  return;
                                }

                                Navigator.pushNamed(context, "/login");
                              },
                              label: "LOGIN TO MANTA",
                              icon: Icons.rocket_launch_rounded,
                              isPrimary: true,
                            ),
                            const SizedBox(height: 16),
                            _OutlinedButton(
                              onPressed: () =>
                                  _openUrl("https://t.me/AveraEnv"),
                              label: "CONTACT SUPPORT",
                              icon: Icons.support_agent_rounded,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ─── FOOTER ──────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF3D1F00),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "HUBUNGI KAMI",
                              style: TextStyle(
                                color: const Color(0xFF7D8590).withOpacity(0.6),
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _SocialButton(
                                  icon: Icons.telegram,
                                  color: const Color(0xFF0088CC),
                                  url: "https://t.me/AveraEnv",
                                  label: "Telegram AVERA",
                                ),
                                const SizedBox(width: 20),
                                _SocialButton(
                                  icon: Icons.telegram,
                                  color: const Color(0xFF0088CC),
                                  url: "https://t.me/Babehmodss",
                                  label: "Telegram Babehmodss",
                                ),
                                const SizedBox(width: 20),
                                _SocialButton(
                                  icon: Icons.music_note_rounded,
                                  color: const Color(0xFF7D8590),
                                  url: "https://tiktok.com/@iwan_tek_tek",
                                  label: "TikTok",
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Divider(
                              color: dividerColor.withOpacity(0.3),
                              height: 1,
                              thickness: 1,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "© 2026 MANTA BUG. By @AveraEnv",
                              style: TextStyle(
                                color: textSecondary.withOpacity(0.5),
                                fontSize: 11,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Color get primaryColor => LandingPage.primaryOrange;
  Color get accentGold => LandingPage.accentGold;
  Color get darkBackground => LandingPage.darkBackground;
  Color get surfaceColor => LandingPage.surfaceColor;
  Color get cardColor => LandingPage.cardColor;
  Color get textPrimary => LandingPage.textPrimary;
  Color get textSecondary => LandingPage.textSecondary;
  Color get dividerColor => LandingPage.dividerColor;
}

// ─── GRID PAINTER ────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3D1F00).withOpacity(0.25)
      ..style = PaintingStyle.fill;

    const double spacing = 36;
    const double radius = 1.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── ELEVATED BUTTON ────────────────────────────────────────────────────────
class _ElevatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final bool isPrimary;

  const _ElevatedButton({
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.isPrimary,
  });

  @override
  State<_ElevatedButton> createState() => _ElevatedButtonState();
}

class _ElevatedButtonState extends State<_ElevatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _glow = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTapDown: (_) => _controller.reverse(),
        onTapUp: (_) {
          _controller.forward();
          widget.onPressed();
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scale.value,
              child: Container(
                height: 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF6D00),
                      const Color(0xFFFF9100),
                      const Color(0xFFFFB300),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF6D00).withOpacity(0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6D00).withOpacity(0.3 + _glow.value * 0.2),
                      blurRadius: 25,
                      spreadRadius: 3,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFFB300).withOpacity(0.15 + _glow.value * 0.15),
                      blurRadius: 50,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: Colors.white, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── OUTLINED BUTTON ────────────────────────────────────────────────────────
class _OutlinedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  const _OutlinedButton({
    required this.onPressed,
    required this.label,
    required this.icon,
  });

  @override
  State<_OutlinedButton> createState() => _OutlinedButtonState();
}

class _OutlinedButtonState extends State<_OutlinedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTapDown: (_) => _controller.reverse(),
        onTapUp: (_) {
          _controller.forward();
          widget.onPressed();
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scale.value,
              child: Container(
                height: 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: LandingPage.surfaceColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF6D00).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      color: const Color(0xFFFF6D00),
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Color(0xFFFF6D00),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── SOCIAL BUTTON ──────────────────────────────────────────────────────────
class _SocialButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String url;
  final String label;

  const _SocialButton({
    required this.icon,
    required this.color,
    required this.url,
    required this.label,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _rotation = Tween<double>(
      begin: 0,
      end: 0.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchURL() async {
    final Uri uri = Uri.parse(widget.url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch ${widget.url}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTap: _launchURL,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scale.value,
              child: Transform.rotate(
                angle: _rotation.value,
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            widget.color.withOpacity(0.2),
                            widget.color.withOpacity(0.1),
                          ],
                        ),
                        border: Border.all(
                          color: widget.color.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: LandingPage.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}