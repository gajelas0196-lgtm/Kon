
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'splash.dart';
import 'main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  final userController = TextEditingController();
  final passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool _obscurePassword = true;
  String? androidId;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  // Animation for barcode charging effect
  late AnimationController _chargeController;
  late Animation<double> _chargeAnim;

  // Login success state
  bool _loginSuccess = false;
  String _loginMessage = "";

  static const Color primaryOrange = Color(0xFFFF7A00);
  static const Color darkOrange = Color(0xFFFFA040);
  static const Color accentOrange = Color(0xFFFFA040);
  static const Color backgroundColor = Color(0xFF0D1117);
  static const Color cardColor = Color(0xFF161B22);
  static const Color surfaceColor = Color(0xFF1C2333);
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF7D8590);
  static const Color dividerColor = Color(0xFF30363D);

  String appVersion = "2.0.2";

  @override
  void initState() {
    super.initState();
    _initAnim();
    _initChargeAnim();
    _initAndLoad();
  }

  void _initChargeAnim() {
    _chargeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _chargeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _chargeController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initAndLoad() async {
    androidId = await getAndroidId();
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => appVersion = info.version);
    } catch (_) {}
    await initLogin();
  }

  void _initAnim() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _slideAnim = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  Future<void> initLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey = prefs.getString("key");

    if (savedUser != null && savedPass != null && savedKey != null) {
      final uri = Uri.parse(
        "$baseUrl/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey",
      );

      try {
        final res = await http.get(uri);
        final data = jsonDecode(res.body);

        if (data['valid'] == true && data['expired'] != true) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => SplashScreen(
                username: savedUser,
                password: savedPass,
                role: data['role'],
                sessionKey: data['key'],
                expiredDate: data['expiredDate'],
                listBug: (data['listBug'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                listDoos: (data['listDDoS'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                news: (data['news'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
              ),
              transitionDuration: const Duration(milliseconds: 400),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          );
        } else if (data['reason'] == 'device') {
          if (!mounted) return;
          _showPopup(
            title: "Login Gagal",
            message: "akun telah diloginkan di device lain",
            color: accentOrange,
          );
        }
      } catch (_) {}
    }
  }

  Future<String> getAndroidId() async {
    if (kIsWeb) {
      return "web_client";
    }
    try {
      final deviceInfo = DeviceInfoPlugin();
      final android = await deviceInfo.androidInfo;
      return android.id;
    } catch (_) {
      return "unknown_device";
    }
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    final username = userController.text.trim();
    final password = passController.text.trim();

    setState(() => isLoading = true);

    try {
      androidId ??= await getAndroidId();

      final validate = await http.post(
        Uri.parse("$baseUrl/validate"),
        body: {
          "username": username,
          "password": password,
          "androidId": androidId!,
          "version": appVersion,
        },
      );

      final validData = jsonDecode(validate.body);

      if (!mounted) return;

      if (validData['expired'] == true) {
        _showPopup(
          title: "Access Expired",
          message: "Your access has expired.\nPlease renew it.",
          color: Colors.orange,
          showContact: true,
        );
      } else if (validData['valid'] != true) {
        if (validData['reason'] == 'device') {
          _showPopup(
            title: "Login Gagal",
            message: "akun telah diloginkan di device lain",
            color: accentOrange,
          );
        } else {
          _showPopup(
            title: "Login Failed",
            message: "Invalid username or password.",
            color: accentOrange,
          );
        }
      } else {
        // Login success - trigger charging animation
        setState(() {
          _loginSuccess = true;
          _loginMessage = "Login Success";
        });
        _chargeController.forward();

        // Wait for animation then proceed
        await Future.delayed(const Duration(milliseconds: 1800));

        final prefs = await SharedPreferences.getInstance();
        prefs.setString("username", username);
        prefs.setString("password", password);
        prefs.setString("key", validData['key']);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => SplashScreen(
              username: username,
              password: password,
              role: validData['role'],
              sessionKey: validData['key'],
              expiredDate: validData['expiredDate'],
              listBug: (validData['listBug'] as List? ?? [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList(),
              listDoos: (validData['listDDoS'] as List? ?? [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList(),
              news: (validData['news'] as List? ?? [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList(),
            ),
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showPopup(
        title: "Connection Error",
        message:
            "Failed to connect to the server.\nPlease check your internet connection.",
        color: accentOrange,
      );
    }

    if (mounted) setState(() => isLoading = false);
  }

  void _showPopup({
    required String title,
    required String message,
    Color color = primaryOrange,
    bool showContact = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: dividerColor, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                    border: Border.all(color: color.withOpacity(0.3), width: 1),
                  ),
                  child: Icon(
                    color == Colors.orange ? Icons.warning : Icons.error,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (showContact)
                      OutlinedButton(
                        onPressed: () async {
                          final uri = Uri.parse("https://t.me/AveraEnv");
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textSecondary,
                          side: BorderSide(color: dividerColor),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          "Contact Admin",
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: surfaceColor,
                        foregroundColor: textPrimary,
                        side: BorderSide(color: dividerColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        elevation: 0,
                      ),
                      child: const Text("Close"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _chargeController.dispose();
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background image from assets
          Positioned.fill(
            child: Image.asset(
              'assets/images/xo_device_hero_poster.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0D1117),
                      Color(0xFF111820),
                      Color(0xFF0A0E14),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Dark overlay for readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          // Orange glow effect top
          Positioned(
            top: -120,
            left: 0,
            right: 0,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.0,
                  colors: [
                    primaryOrange.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Dots pattern
          Positioned.fill(child: CustomPaint(painter: _DotsPatternPainter())),
          // Hex outlines
          Positioned(
            top: -40,
            right: -40,
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(
                size: const Size(200, 200),
                painter: _HexOutlinePainter(),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Opacity(
              opacity: 0.04,
              child: CustomPaint(
                size: const Size(160, 160),
                painter: _HexOutlinePainter(),
              ),
            ),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: Opacity(opacity: _fadeAnim.value, child: child),
                );
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 40),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Main Card
                            Container(
                              width: MediaQuery.of(context).size.width * 0.92,
                              constraints:
                                  const BoxConstraints(maxWidth: 420),
                              decoration: BoxDecoration(
                                color: cardColor.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: primaryOrange.withOpacity(0.4),
                                    width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryOrange.withOpacity(0.15),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.6),
                                    blurRadius: 40,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 8, sigmaY: 8),
                                  child: Column(
                                    children: [
                                      // Header bar
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: primaryOrange,
                                          borderRadius:
                                              const BorderRadius.only(
                                            topLeft: Radius.circular(24),
                                            topRight: Radius.circular(24),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white
                                                    .withOpacity(0.2),
                                                border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.4),
                                                    width: 1),
                                              ),
                                              child: ClipOval(
                                                child: Image.asset(
                                                  'assets/images/logo.jpg',
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (_, __, ___) =>
                                                          const Icon(
                                                    Icons.shield_outlined,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    "MANTA'X",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing: 1.5,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Secure Access to MANTA",
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.85),
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.3),
                                                    width: 1),
                                              ),
                                              child: const Icon(
                                                Icons.qr_code_2,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Body content
                                      Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          children: [
                                            // Logo and title section
                                            Row(
                                              children: [
                                                Container(
                                                  width: 64,
                                                  height: 64,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: cardColor,
                                                    border: Border.all(
                                                        color: primaryOrange,
                                                        width: 2),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: primaryOrange
                                                            .withOpacity(0.3),
                                                        blurRadius: 12,
                                                        spreadRadius: 1,
                                                      ),
                                                    ],
                                                  ),
                                                  child: ClipOval(
                                                    child: Image.asset(
                                                      'assets/images/logo.jpg',
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (_, __, ___) =>
                                                              const Icon(
                                                        Icons.shield_outlined,
                                                        color: primaryOrange,
                                                        size: 28,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text(
                                                        "MANTA'X",
                                                        style: TextStyle(
                                                          color: textPrimary,
                                                          fontSize: 24,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          letterSpacing: 3,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 4),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 10,
                                                                vertical: 3),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: primaryOrange
                                                              .withOpacity(
                                                                  0.15),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                          border: Border.all(
                                                              color:
                                                                  primaryOrange
                                                                      .withOpacity(
                                                                          0.5),
                                                              width: 1),
                                                        ),
                                                        child: const Text(
                                                          "Secure Access to MANTA",
                                                          style: TextStyle(
                                                            color:
                                                                primaryOrange,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 6),
                                                      Row(
                                                        children: [
                                                          Container(
                                                            width: 8,
                                                            height: 8,
                                                            decoration:
                                                                const BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color:
                                                                  Colors.green,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 5),
                                                          const Text(
                                                            "Online",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.green,
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 12),
                                                          Icon(
                                                            Icons
                                                                .shield_outlined,
                                                            color: textSecondary
                                                                .withOpacity(
                                                                    0.7),
                                                            size: 12,
                                                          ),
                                                          const SizedBox(
                                                              width: 3),
                                                          Text(
                                                            "Secure Access",
                                                            style: TextStyle(
                                                              color: textSecondary
                                                                  .withOpacity(
                                                                      0.7),
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 28),
                                            // Form
                                            Form(
                                              key: _formKey,
                                              child: Column(
                                                children: [
                                                  // Username field
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: surfaceColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14),
                                                      border: Border.all(
                                                          color: dividerColor,
                                                          width: 1),
                                                    ),
                                                    child: TextFormField(
                                                      controller:
                                                          userController,
                                                      style: const TextStyle(
                                                        color: textPrimary,
                                                        fontSize: 14,
                                                      ),
                                                      decoration:
                                                          InputDecoration(
                                                        hintText: "Username",
                                                        hintStyle: TextStyle(
                                                          color: textSecondary
                                                              .withOpacity(
                                                                  0.6),
                                                          fontSize: 14,
                                                        ),
                                                        prefixIcon: const Icon(
                                                          Icons
                                                              .person_outline,
                                                          color: textSecondary,
                                                          size: 20,
                                                        ),
                                                        border:
                                                            InputBorder.none,
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 16,
                                                                vertical: 16),
                                                      ),
                                                      validator: (v) =>
                                                          v == null ||
                                                                  v.isEmpty
                                                              ? "Please enter username"
                                                              : null,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 14),
                                                  // Password field
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: surfaceColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14),
                                                      border: Border.all(
                                                          color: dividerColor,
                                                          width: 1),
                                                    ),
                                                    child: TextFormField(
                                                      controller:
                                                          passController,
                                                      obscureText:
                                                          _obscurePassword,
                                                      style: const TextStyle(
                                                        color: textPrimary,
                                                        fontSize: 14,
                                                      ),
                                                      decoration:
                                                          InputDecoration(
                                                        hintText: "Password",
                                                        hintStyle: TextStyle(
                                                          color: textSecondary
                                                              .withOpacity(
                                                                  0.6),
                                                          fontSize: 14,
                                                        ),
                                                        prefixIcon: const Icon(
                                                          Icons.lock_outline,
                                                          color: textSecondary,
                                                          size: 20,
                                                        ),
                                                        suffixIcon: IconButton(
                                                          icon: Icon(
                                                            _obscurePassword
                                                                ? Icons
                                                                    .visibility_off_outlined
                                                                : Icons
                                                                    .visibility_outlined,
                                                            color:
                                                                textSecondary,
                                                            size: 20,
                                                          ),
                                                          onPressed: () =>
                                                              setState(() =>
                                                                  _obscurePassword =
                                                                      !_obscurePassword),
                                                        ),
                                                        border:
                                                            InputBorder.none,
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 16,
                                                                vertical: 16),
                                                      ),
                                                      validator: (v) =>
                                                          v == null ||
                                                                  v.isEmpty
                                                              ? "Please enter password"
                                                              : null,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 24),
                                                  // Sign In Button
                                                  SizedBox(
                                                    width: double.infinity,
                                                    height: 50,
                                                    child: ElevatedButton(
                                                      onPressed: isLoading
                                                          ? null
                                                          : login,
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            primaryOrange,
                                                        foregroundColor:
                                                            Colors.white,
                                                        disabledBackgroundColor:
                                                            primaryOrange
                                                                .withOpacity(
                                                                    0.5),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(14),
                                                        ),
                                                        elevation: 4,
                                                        shadowColor:
                                                            primaryOrange
                                                                .withOpacity(
                                                                    0.4),
                                                      ),
                                                      child: isLoading
                                                          ? const SizedBox(
                                                              width: 20,
                                                              height: 20,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                strokeWidth:
                                                                    2,
                                                                valueColor:
                                                                    AlwaysStoppedAnimation<
                                                                        Color>(
                                                                  Colors.white,
                                                                ),
                                                              ),
                                                            )
                                                          : const Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Icon(
                                                                    Icons
                                                                        .login,
                                                                    size: 18),
                                                                SizedBox(
                                                                    width: 8),
                                                                Text(
                                                                  "SIGN IN",
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    letterSpacing:
                                                                        2,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            // Barcode rectangle with charging animation
                                            AnimatedBuilder(
                                              animation: _chargeController,
                                              builder: (context, child) {
                                                return Column(
                                                  children: [
                                                    Container(
                                                      width: double.infinity,
                                                      height: 50,
                                                      decoration: BoxDecoration(
                                                        color: surfaceColor,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        border: Border.all(
                                                            color: dividerColor,
                                                            width: 1),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        child:
                                                            CustomPaint(
                                                          painter:
                                                              _BarcodeChargingPainter(
                                                            progress:
                                                                _chargeAnim
                                                                    .value,
                                                            isCharging:
                                                                _loginSuccess,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    if (_loginMessage
                                                        .isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 8),
                                                        child: Text(
                                                          _loginMessage,
                                                          style:
                                                              const TextStyle(
                                                            color:
                                                                primaryOrange,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            letterSpacing: 1,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Footer
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 1,
                                      color: dividerColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "MANTA APLIKASI",
                                      style: TextStyle(
                                        color:
                                            textSecondary.withOpacity(0.5),
                                        fontSize: 9,
                                        letterSpacing: 3,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 40,
                                      height: 1,
                                      color: dividerColor,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "v$appVersion  ·  © 2026",
                                  style: TextStyle(
                                    color: textSecondary.withOpacity(0.35),
                                    fontSize: 10,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Barcode painter with charging animation (Red -> Yellow -> Orange)
class _BarcodeChargingPainter extends CustomPainter {
  final double progress;
  final bool isCharging;

  _BarcodeChargingPainter({
    required this.progress,
    required this.isCharging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw static barcode lines (gray when not charging)
    final linePaint = Paint()
      ..color = const Color(0xFF30363D)
      ..style = PaintingStyle.fill;

    final random = Random(42); // Fixed seed for consistent pattern
    double x = 8;
    while (x < size.width - 8) {
      final lineWidth = 2 + random.nextInt(4).toDouble();
      if (x + lineWidth > size.width - 8) break;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 8, lineWidth, size.height - 16),
          const Radius.circular(1),
        ),
        linePaint,
      );
      x += lineWidth + 2 + random.nextInt(4);
    }

    // If charging, overlay the charging gradient
    if (isCharging && progress > 0) {
      final chargeWidth = size.width * progress;

      // Create gradient: Red -> Yellow -> Orange
      final gradient = const LinearGradient(
        colors: [
          Color(0xFFE53935), // Red
          Color(0xFFFDD835), // Yellow
          Color(0xFFFF7A00), // Orange
        ],
        stops: [0.0, 0.5, 1.0],
      );

      final chargePaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(0, 0, chargeWidth, size.height),
        )
        ..style = PaintingStyle.fill;

      // Clip to rounded rectangle
      final clipPath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, chargeWidth, size.height),
            const Radius.circular(8),
          ),
        );

      canvas.save();
      canvas.clipPath(clipPath);

      // Redraw barcode lines with gradient color within the charged area
      final random2 = Random(42);
      double x2 = 8;
      while (x2 < size.width - 8) {
        final lineWidth = 2 + random2.nextInt(4).toDouble();
        if (x2 + lineWidth > chargeWidth - 8) {
          // Partial line at the edge
          if (x2 < chargeWidth) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(x2, 8, chargeWidth - x2, size.height - 16),
                const Radius.circular(1),
              ),
              chargePaint,
            );
          }
          break;
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x2, 8, lineWidth, size.height - 16),
            const Radius.circular(1),
          ),
          chargePaint,
        );
        x2 += lineWidth + 2 + random2.nextInt(4);
      }

      canvas.restore();

      // Glow effect at the charging edge
      if (progress < 1.0) {
        final glowPaint = Paint()
          ..color = const Color(0xFFFF7A00).withOpacity(0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(
          Offset(chargeWidth, size.height / 2),
          6,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodeChargingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isCharging != isCharging;
  }
}

class _DotsPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF30363D).withOpacity(0.35)
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

class _HexOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (final entry in [
      [1.0, 0.18],
      [0.6, 0.10],
      [0.3, 0.06],
    ]) {
      final scale = entry[0];
      final opacity = entry[1];
      final paint = Paint()
        ..color = const Color(0xFFFF7A00).withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      final r = (size.width / 2) * scale;
      final path = Path();
      for (int i = 0; i < 6; i++) {
        final angle = (pi / 3) * i - pi / 6;
        final x = cx + r * cos(angle);
        final y = cy + r * sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}