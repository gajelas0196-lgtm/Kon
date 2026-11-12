import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:math';
import 'change_password.dart';
import 'bug_sender.dart';
import 'nik_check.dart';
import 'admin_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'tabunganku_module.dart';
import 'package:battery_plus/battery_plus.dart';
import 'profile_page.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'tools_gateway.dart';
import 'login_page.dart';
import 'bug_group_page.dart';
import 'notification_page.dart';
import 'chat_room_page.dart';
import 'telegram_report_system.dart';
import 'spotify_music_player.dart';
import 'custom_payload.dart';
import 'thanks_to_page.dart';
import 'spam_pair.dart';
import 'alquran.dart';
import 'send_notification_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'tes_func_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:open_filex/open_filex.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'dart:io';
import 'main.dart';
import 'controller.dart';
import 'weather_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ─── SHOLAT SERVICE ──────────────────────────────────────────────────────────
class SholatService {
  String _getTimeZone(double longitude) {
    if (longitude >= 105 && longitude < 120) return "WIB";
    else if (longitude >= 120 && longitude < 135) return "WITA";
    else if (longitude >= 135 && longitude <= 150) return "WIT";
    else return "WIB";
  }

  Future<Map<String, dynamic>> getJadwalSholat(String cityId) async {
    try {
      final now = DateTime.now();
      final date = "${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}";
      final response = await http.get(
        Uri.parse('https://api.myquran.com/v1/sholat/jadwal/$cityId/$date'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
    } catch (e) { print('Error fetching sholat schedule: $e'); }
    return {};
  }

  Future<List<dynamic>> searchKota(String query) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.myquran.com/v1/sholat/kota/cari/$query'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) { print('Error searching cities: $e'); }
    return [];
  }

  Future<List<dynamic>> getKotaList() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.myquran.com/v1/sholat/kota/cari/'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) { print('Error fetching cities: $e'); }
    return [];
  }

  Future<Map<String, dynamic>?> getCurrentLocationCity() async {
    try {
      final status = await Permission.location.request();
      if (status != PermissionStatus.granted) return null;
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final timeZone = _getTimeZone(position.longitude);
      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (places.isEmpty) return null;
      final place = places.first;
      String? cityName = place.locality ?? place.subLocality ?? place.subAdministrativeArea ?? place.administrativeArea;
      if (cityName == null) return null;
      String cleanName = cityName.toLowerCase()
          .replaceAll('kabupaten', '')
          .replaceAll('kab.', '')
          .replaceAll('kota', '')
          .replaceAll('kab', '')
          .replaceAll('kot', '')
          .replaceAll('administrative', '')
          .replaceAll('area', '')
          .trim();
      List<dynamic> searchResults = await searchKota(cleanName);
      if (searchResults.isEmpty && cleanName.contains(' ')) {
        final parts = cleanName.split(' ');
        for (var part in parts) {
          if (part.length > 3) {
            searchResults = await searchKota(part);
            if (searchResults.isNotEmpty) break;
          }
        }
      }
      if (searchResults.isEmpty && cleanName.contains(' ')) {
        final firstWord = cleanName.split(' ')[0];
        if (firstWord.length > 2) {
          searchResults = await searchKota(firstWord);
        }
      }
      if (searchResults.isEmpty) {
        final allCities = await getKotaList();
        Map<String, dynamic>? nearestCity;
        double minDistance = double.infinity;
        for (var city in allCities) {
          final cityLat = double.tryParse(city['lintang']?.toString() ?? '0') ?? 0;
          final cityLong = double.tryParse(city['bujur']?.toString() ?? '0') ?? 0;
          if (cityLat != 0 && cityLong != 0) {
            final distance = calculateDistance(
              position.latitude,
              position.longitude,
              cityLat,
              cityLong,
            );
            if (distance < minDistance) {
              minDistance = distance;
              nearestCity = city;
            }
          }
        }
        if (nearestCity != null) {
          return {
            'cityId': nearestCity['id'].toString(),
            'cityName': nearestCity['lokasi']?.toString() ?? cityName,
            'timeZone': timeZone,
            'latitude': position.latitude,
            'longitude': position.longitude,
          };
        }
      }
      if (searchResults.isNotEmpty) {
        final cityData = searchResults[0];
        return {
          'cityId': cityData['id'].toString(),
          'cityName': cityData['lokasi']?.toString() ?? cityName,
          'timeZone': timeZone,
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
      } else {
        return null;
      }
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) => degree * pi / 180;
}

// ─── DASHBOARD PAGE ──────────────────────────────────────────────────────────
class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listDoos,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

// ─── ANIMATED BACKGROUND ─────────────────────────────────────────────────────
class AnimatedBackground extends StatefulWidget {
  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -100, end: 100).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(_animation.value / 100, -0.5),
              radius: 1.5,
              colors: [
                Color(0xFF00B4D8).withOpacity(0.14),
                Color(0xFF4FC3F7).withOpacity(0.10),
                Colors.transparent,
              ],
              stops: [0.10, 0.42, 1.0],
            ),
          ),
        );
      },
    );
  }
}

// ─── VIDEO BANNER ────────────────────────────────────────────────────────────
class VideoBannerWidget extends StatefulWidget {
  final String videoPath;
  const VideoBannerWidget({super.key, required this.videoPath});

  @override
  State<VideoBannerWidget> createState() => __VideoBannerWidgetState();
}

class __VideoBannerWidgetState extends State<VideoBannerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        setState(() => _isInitialized = true);
        _controller.setVolume(0.0);
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF061225), Color(0xFF0B1E35)],
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF00B4D8), strokeWidth: 2),
        ),
      );
    }
    return Container(
      height: 200,
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}
// ─── DASHBOARD PAGE STATE ──────────────────────────────────────────────────
class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  // ─── COLORS ──────────────────────────────────────────────────────────────
  final Color bloodRed = const Color(0xFF00B4D8);
  final Color darkRed = const Color(0xFF0D1117);
  final Color lightRed = const Color(0xFFE6EDF3);
  final Color deepBlack = const Color(0xFF0D1117);
  final Color glassBlack = const Color(0xCC161B22);
  final Color primaryDark = const Color(0xFF161B22);
  final Color primaryPurple = const Color(0xFF1C2333);
  final Color accentPurple = const Color(0xFF4FC3F7);
  final Color lightPurple = const Color(0xFFE6EDF3);
  final Color primaryWhite = const Color(0xFFFFFFFF);
  final Color accentGold = const Color(0xFFA5E7FF);
  final Color accentPink = const Color(0xFFFFA726);
  final Color cardDark = const Color(0xFF161B22);
  final Color accentGrey = const Color(0xFF7D8590);

  // ─── STATE ────────────────────────────────────────────────────────────────
  Map<String, dynamic>? _jadwalSholat;
  List<dynamic> _cityList = [];
  String _selectedCityId = "1227";
  String _selectedCityName = "Jakarta";
  bool _isLoadingSholat = false;
  Timer? _sholatTimer;
  final SholatService _sholatService = SholatService();
  bool _useCurrentLocation = false;
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late WebSocketChannel channel;
  late DateTime _lastStatsUpdate;
  Timer? _healthCheckTimer;
  Timer? _timeTimer;
  Timer? _fetchTimer;
  DateTime _wibTime = DateTime.now();
  DateTime _witaTime = DateTime.now().add(const Duration(hours: 1));
  DateTime _witTime = DateTime.now().add(const Duration(hours: 2));
  String _dayPeriod = "Morning";
  String _nextPrayerName = "";
  String _currentPrayerName = "";
  String _nextPrayerTimeStr = "";
  String _nextPrayerCountdown = "";
  final ValueNotifier<int> _prayerTicker = ValueNotifier(0);
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  late PackageInfo _packageInfo;
  bool _isChecking = false;
  String? _updateError;
  Map<String, dynamic>? _updateInfo;
  List<String> _changelog = [];
  bool _showUpdateBanner = false;
  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  String? _profileImagePath;
  List<dynamic> notifications = [];
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;
  Timer? _realTimeClockTimer;
  String _currentTime = "00:00:00";
  String _currentTimeZoneDisplay = "WIB";
  String androidId = "unknown";
  int _bottomNavIndex = 0;
  Widget _selectedPage = const Placeholder();
  bool isLoading = false;
  ValueNotifier<bool> hasUnreadNotif = ValueNotifier(false);
  bool isNotifLoading = false;
  bool isRefreshing = false;
  String? errorMessage;
  List<dynamic> senderList = [];
  int _currentPage = 1;
  int _totalPages = 493;
  int onlineUsers = 0;
  int activeConnections = 0;
  final ValueNotifier<int> _carouselCurrentNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _quickActionNotifier = ValueNotifier<int>(0);
  bool _isLoadingNews = false;
  Map<String, dynamic>? _weatherInfo;
  Map<String, dynamic>? _fullWeatherData;
  bool _isLoadingWeather = false;
  String _timeZoneAbbreviation = "WIB";
  String _currentTimeZone = "WIB";

  // ─── INIT ──────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    AppConfig.sessionKey = widget.sessionKey;
    username = widget.username;
    AppConfig.username = widget.username;
    password = widget.password;
    role = widget.role;
    AppConfig.role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug ?? [];
    listDoos = widget.listDoos ?? [];
    newsList = widget.news ?? [];
    _initPackageInfo();
    _jadwalSholat = {
      'lokasi': 'Jakarta',
      'daerah': 'DKI Jakarta',
      'jadwal': {
        'imsak': '04:22',
        'subuh': '04:32',
        'terbit': '05:46',
        'dzuhur': '12:08',
        'ashar': '15:30',
        'maghrib': '18:20',
        'isya': '19:33',
      },
    };
    _selectedPage = _buildEnhancedNewsPage();
    _initAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initRealTimeSystems();
      }
    });
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTimes();
      } else {
        timer.cancel();
      }
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _fetchCnbcNews();
        _fetchWeatherData(_selectedCityName);
      }
    });
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        _initSholatData();
      }
    });
    _realTimeClockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateRealTimeClock();
      } else {
        timer.cancel();
      }
    });
    _loadProfileImage();
  }

  // ─── LOAD PROFILE ────────────────────────────────────────────────────────
  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _profileImagePath = prefs.getString('profile_image_path');
        if (_bottomNavIndex == 0) {
          _selectedPage = _buildEnhancedNewsPage();
        }
      });
    }
  }

  // ─── FETCH NEWS ──────────────────────────────────────────────────────────
  Future<void> _fetchCnbcNews({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _isLoadingNews = true);
    try {
      final response = await http.get(
        Uri.parse('https://api.siputzx.my.id/api/berita/cnbcindonesia'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> rawItems = decoded['data'] as List<dynamic>? ?? [];
        final mapped = rawItems.whereType<Map>().map<Map<String, dynamic>>((item) {
          final map = Map<String, dynamic>.from(item);
          return {
            'title': map['title']?.toString() ?? 'No Title',
            'link': map['link']?.toString() ?? '',
            'image': map['image']?.toString() ?? '',
            'category': map['category']?.toString() ?? '',
            'label': map['label']?.toString() ?? '',
            'date': map['date']?.toString() ?? '',
            'type': map['type']?.toString() ?? 'article',
          };
        }).toList();
        if (mounted && mapped.isNotEmpty) {
          setState(() => newsList = mapped);
        }
      }
    } catch (e) {
      print('Error fetching CNBC news: $e');
    } finally {
      if (mounted && !silent) setState(() => _isLoadingNews = false);
    }
  }

  // ─── REAL TIME SYSTEMS ───────────────────────────────────────────────────
  void _initRealTimeSystems() async {
    try {
      await _initAndroidIdAndConnect();
      await Future.delayed(const Duration(seconds: 2));
      await Future.wait([
        _fetchAdvancedStats(),
        _fetchSenders(),
        _fetchNotifications(),
      ]);
    } catch (e) {
      _startPollingFallback();
    }
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      final token = await messaging.getToken();
      if (token != null) {
        await http.post(
          Uri.parse("$baseUrl/updateFCMToken"),
          body: {"key": sessionKey, "token": token},
        );
      }
    } catch (fcmErr) {
      print("[FCM] Failed to setup FCM: $fcmErr");
    }
  }

  Future<void> _initPackageInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      _checkForUpdates();
    } catch (e) {}
  }

  Future<void> _checkForUpdates() async {
    if (_isChecking) return;
    setState(() { _isChecking = true; _updateError = null; });
    try {
      final response = await Dio().get(
        '$baseUrl/api/check-update',
        queryParameters: {
          'version': _packageInfo.version,
          'build': _packageInfo.buildNumber,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        },
        options: Options(
          headers: {'Authorization': 'Bearer ${widget.sessionKey}'},
        ),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['error'] != null) {
          setState(() {
            _updateError = data['error'].toString();
            _updateInfo = null;
            _changelog = [];
            _showUpdateBanner = false;
          });
        } else if (data['has_update'] == true && data['update_info'] != null) {
          setState(() {
            _updateInfo = data['update_info'];
            _changelog = List<String>.from(data['update_info']['changelog'] ?? []);
            _showUpdateBanner = true;
          });
          _showUpdateNotification(data['update_info']);
        } else {
          setState(() {
            _updateInfo = null;
            _changelog = [];
            _showUpdateBanner = false;
          });
        }
      } else {
        setState(() {
          _updateError = 'Server merespon dengan kode ${response.statusCode}';
          _showUpdateBanner = false;
        });
      }
    } catch (e) {
      setState(() {
        _updateError = 'Gagal mengecek update: ${e.toString()}';
        _showUpdateBanner = false;
      });
    } finally {
      setState(() => _isChecking = false);
    }
  }

  void _showUpdateNotification(Map<String, dynamic> updateInfo) {
    final version = updateInfo['version'] ?? 'terbaru';
    final isCritical = updateInfo['critical'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCritical ? Icons.report_problem_rounded : Icons.system_update_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCritical ? 'Update Kritis Tersedia!' : 'Update Baru Tersedia!',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                  Text('Versi v$version telah tersedia',
                      style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SizedBox.shrink()),
                );
              },
              child: const Text('UPDATE',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        backgroundColor: isCritical ? const Color(0xFFD32F2F) : const Color(0xFF00B4D8),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 15),
        margin: const EdgeInsets.fromLTRB(15, 5, 15, 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 10,
      ),
    );
  }

  void _initAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  void _startWebSocketHealthCheck() {
    _healthCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      try {
        if (channel.closeCode != null) {
          print("⚠️ WebSocket disconnected, reconnecting...");
          _reconnectWebSocket();
        }
      } catch (e) {}
    });
  }

  void _updateRealTimeClock() {
    final now = DateTime.now();
    final timeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    if (mounted) {
      _currentTime = timeString;
      _currentTimeZoneDisplay = _timeZoneAbbreviation;
    }
  }

  // ─── SHOLAT ────────────────────────────────────────────────────────────────
  Future<void> _initSholatData() async {
    if (_isLoadingSholat || !mounted) return;
    setState(() => _isLoadingSholat = true);
    try {
      final locationData = await _sholatService.getCurrentLocationCity();
      if (locationData != null && mounted) {
        final cityId = locationData['cityId'];
        final cityName = locationData['cityName'];
        final timeZone = locationData['timeZone'];
        setState(() {
          _selectedCityId = cityId;
          _selectedCityName = cityName;
          _useCurrentLocation = true;
          _currentTimeZone = timeZone;
          _timeZoneAbbreviation = timeZone;
        });
        await _fetchSholatSchedule(cityId);
        _fetchWeatherData(cityName);
        _saveLocationPreference(cityId, cityName);
      } else {
        await _loadSavedLocation();
      }
    } catch (e) {
      _setDefaultSholatSchedule();
    } finally {
      if (mounted) setState(() => _isLoadingSholat = false);
    }
  }

  Future<void> _fetchWeatherData(String cityName) async {
    print("🌤️ FETCHING WEATHER FOR: $cityName");
    if (_isLoadingWeather || !mounted) return;
    setState(() => _isLoadingWeather = true);
    try {
      String adm4 = "31.71.01.1001";
      final lowerCity = cityName.toLowerCase();
      if (lowerCity.contains("surabaya")) adm4 = "35.78.01.1001";
      else if (lowerCity.contains("bandung")) adm4 = "32.73.19.1001";
      else if (lowerCity.contains("medan")) adm4 = "12.71.01.1001";
      else if (lowerCity.contains("makassar")) adm4 = "73.71.01.1001";
      else if (lowerCity.contains("denpasar")) adm4 = "51.71.01.1001";
      else if (lowerCity.contains("semarang")) adm4 = "33.74.01.1001";
      else if (lowerCity.contains("palembang")) adm4 = "16.71.01.1001";
      else if (lowerCity.contains("yogyakarta") || lowerCity.contains("jogja")) adm4 = "34.71.01.1001";
      final response = await http.get(
        Uri.parse("https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4=$adm4"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data'].isNotEmpty) {
          final weatherList = data['data'][0]['cuaca'];
          if (weatherList != null && weatherList.isNotEmpty) {
            for (var dayForecasts in weatherList) {
              if (dayForecasts is List && dayForecasts.isNotEmpty) {
                setState(() {
                  _weatherInfo = dayForecasts[0];
                  _fullWeatherData = data;
                });
                break;
              }
            }
          }
        }
      }
    } catch (e) {
      print("❌ Weather Error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingWeather = false);
    }
  }

  Future<void> _saveLocationPreference(String cityId, String cityName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_city_id', cityId);
      await prefs.setString('last_city_name', cityName);
      await prefs.setBool('use_current_location', true);
    } catch (e) {}
  }

  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCityId = prefs.getString('last_city_id');
      final savedCityName = prefs.getString('last_city_name');
      final useCurrentLocation = prefs.getBool('use_current_location') ?? false;
      if (savedCityId != null && savedCityName != null) {
        setState(() {
          _selectedCityId = savedCityId;
          _selectedCityName = savedCityName;
          _useCurrentLocation = useCurrentLocation;
        });
        await _fetchSholatSchedule(savedCityId);
      } else {
        _setDefaultSholatSchedule();
      }
    } catch (e) {
      _setDefaultSholatSchedule();
    }
  }

  Future<void> _fetchSholatSchedule(String cityId) async {
    if (!mounted) return;
    try {
      _safeSetState(() => _isLoadingSholat = true);
      final data = await _sholatService.getJadwalSholat(cityId).timeout(
        Duration(seconds: 10),
        onTimeout: () => {},
      );
      if (mounted && data.isNotEmpty && data['status'] == true) {
        _safeSetState(() => _jadwalSholat = data['data']);
      } else {
        _setDefaultSholatSchedule();
      }
    } catch (e) {
      _setDefaultSholatSchedule();
    } finally {
      if (mounted) _safeSetState(() => _isLoadingSholat = false);
    }
  }

  void _setDefaultSholatSchedule() {
    if (mounted) {
      _safeSetState(() {
        _jadwalSholat = {
          'lokasi': 'Jakarta',
          'daerah': 'DKI Jakarta',
          'jadwal': {
            'imsak': '04:22',
            'subuh': '04:32',
            'terbit': '05:46',
            'dzuhur': '12:08',
            'ashar': '15:30',
            'maghrib': '18:20',
            'isya': '19:33',
          },
        };
        _isLoadingSholat = false;
      });
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      try {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(fn);
        });
      } catch (e) {
        print("⚠️ Error in setState: $e");
      }
    }
  }

  String _getSholatTime(String key) {
    if (_jadwalSholat == null || _jadwalSholat!['jadwal'] == null ||
        _jadwalSholat!['jadwal'][key] == null) {
      return '--:--';
    }
    return _jadwalSholat!['jadwal'][key]?.toString() ?? '--:--';
  }

  void _showCitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF061225), Color(0xFF0B1E35)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Color(0xFF00B4D8)),
                                SizedBox(width: 12),
                                Text(
                                  'Pilih Lokasi Sholat',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              if (mounted) setState(() => _isLoadingSholat = true);
                              await _initSholatData();
                            },
                            icon: Icon(Icons.gps_fixed),
                            label: Text('Gunakan Lokasi Saat Ini'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF00B4D8),
                              foregroundColor: Color(0xFF061225),
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Cari kota/kabupaten...',
                            hintStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.search, color: Colors.white70),
                          ),
                          style: TextStyle(color: Colors.white),
                          onChanged: (value) async {
                            if (value.length > 2) {
                              final results = await _sholatService.searchKota(value);
                              setState(() => _cityList = results);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Colors.white.withOpacity(0.1)),
                  Expanded(
                    child: _cityList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search, color: Colors.white30, size: 50),
                                SizedBox(height: 16),
                                Text('Cari kota atau kabupaten',
                                    style: TextStyle(color: Colors.white70)),
                                Text('Minimal 3 karakter',
                                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _cityList.length,
                            itemBuilder: (context, index) {
                              final city = _cityList[index];
                              return Container(
                                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.location_city,
                                    color: Color(0xFF00B4D8).withOpacity(0.7),
                                  ),
                                  title: Text(
                                    city['lokasi']?.toString() ?? 'Unknown',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: city['daerah'] != null
                                      ? Text(
                                          city['daerah'].toString(),
                                          style: TextStyle(color: Colors.white70, fontSize: 12),
                                        )
                                      : null,
                                  trailing: _selectedCityId == city['id'].toString()
                                      ? Icon(Icons.check, color: Color(0xFF00B4D8))
                                      : null,
                                  onTap: () async {
                                    if (mounted) {
                                      setState(() {
                                        _selectedCityId = city['id'].toString();
                                        _selectedCityName = city['lokasi']?.toString() ?? 'Jakarta';
                                        _useCurrentLocation = false;
                                        _isLoadingSholat = true;
                                      });
                                    }
                                    await _fetchSholatSchedule(city['id'].toString());
                                    if (mounted) {
                                      setState(() => _isLoadingSholat = false);
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.white70, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pilih kota untuk mendapatkan jadwal sholat yang akurat',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _isTimeLater(String time1, String time2) {
    try {
      final t1 = time1.split(':');
      final t2 = time2.split(':');
      final hour1 = int.tryParse(t1[0]) ?? 0;
      final minute1 = int.tryParse(t1[1]) ?? 0;
      final hour2 = int.tryParse(t2[0]) ?? 0;
      final minute2 = int.tryParse(t2[1]) ?? 0;
      return hour1 > hour2 || (hour1 == hour2 && minute1 > minute2);
    } catch (e) {
      return false;
    }
  }

  String _formatNewsDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Berita terbaru';
    try {
      final parsed = DateTime.parse(raw).toLocal();
      final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return raw;
    }
  }

  Future<void> _openNewsLink(String url) async {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link berita tidak tersedia')),
      );
      return;
    }
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link berita tidak valid')),
      );
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka link berita')),
      );
    }
  }

  // ─── FETCH STATS ──────────────────────────────────────────────────────────
  Future<void> _fetchAdvancedStats({int retryCount = 3}) async {
    if (retryCount <= 0 || !mounted) return;
    try {
      final uri = Uri.parse("$baseUrl/api/stats/real-time?key=$sessionKey");
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $sessionKey'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          onlineUsers = data['online_users'] ?? data['global_stats']?['online_users'] ?? onlineUsers;
          activeConnections = data['connections_count'] ?? data['personal_stats']?['active_connections'] ?? activeConnections;
          _lastStatsUpdate = DateTime.now();
        });
        return;
      }
      if (response.statusCode == 401) {
        _handleInvalidSession("Session expired");
        return;
      }
    } catch (_) {}
    await Future.delayed(const Duration(seconds: 2));
    await _fetchAdvancedStats(retryCount: retryCount - 1);
  }

  Future<void> _fetchNotifications() async {
    if (isNotifLoading) return;
    setState(() => isNotifLoading = true);
    try {
      final uri = Uri.parse("$baseUrl/notify/list").replace(
        queryParameters: {
          'key': sessionKey,
          'username': username,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final res = await http.get(
        uri,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $sessionKey'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() {
            notifications = data;
            hasUnreadNotif.value = data.isNotEmpty;
          });
        } else if (data is Map) {
          final notifList = data['notifications'] ?? data['data'] ?? [];
          if (notifList is List) {
            setState(() {
              notifications = notifList;
              hasUnreadNotif.value = notifList.isNotEmpty;
            });
          }
        }
      }
    } catch (e) {} finally {
      if (mounted) setState(() => isNotifLoading = false);
    }
  }

  Future<void> _fetchSenders({bool refresh = false}) async {
    if (isLoading && !refresh) return;
    final now = DateTime.now();
    if (!refresh && AppConfig.cachedSenders != null && AppConfig.lastSendersFetch != null) {
      if (now.difference(AppConfig.lastSendersFetch!).inSeconds < 15) {
        if (mounted) {
          setState(() {
            senderList = List<dynamic>.from(AppConfig.cachedSenders!);
            activeConnections = senderList.length;
          });
        }
        return;
      }
    }
    if (!refresh && mounted) setState(() { isLoading = true; errorMessage = null; });
    try {
      final uri = Uri.parse("$baseUrl/mySender?key=$sessionKey");
      final response = await http.get(uri, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['valid'] == true) {
          final List connections = data['connections'] ?? [];
          if (!mounted) return;
          setState(() {
            senderList = List<Map<String, dynamic>>.from(connections);
            activeConnections = senderList.length;
          });
          AppConfig.cachedSenders = senderList;
          AppConfig.lastSendersFetch = DateTime.now();
        } else {
          if (!mounted) return;
          setState(() {
            senderList.clear();
            activeConnections = 0;
            errorMessage = "Data sender tidak valid";
          });
        }
        return;
      }
      if (response.statusCode == 401) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          senderList.clear();
          activeConnections = 0;
          errorMessage = data['error'] ?? "Session expired";
        });
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = "Gagal mengambil data sender");
    } finally {
      if (!mounted) return;
      setState(() { isLoading = false; isRefreshing = false; });
    }
  }

  // ─── UPDATE TIMES ──────────────────────────────────────────────────────────
  void _updateTimes() {
    if (!mounted) return;
    final nowLocal = DateTime.now();
    final nowUtc = nowLocal.toUtc();
    final hour = nowLocal.hour;
    if (hour >= 5 && hour < 10) _dayPeriod = "Pagi 🌅";
    else if (hour >= 10 && hour < 15) _dayPeriod = "Siang ☀️";
    else if (hour >= 15 && hour < 18) _dayPeriod = "Sore 🌇";
    else _dayPeriod = "Malam 🌙";
    _wibTime = nowUtc.add(const Duration(hours: 7));
    _witaTime = nowUtc.add(const Duration(hours: 8));
    _witTime = nowUtc.add(const Duration(hours: 9));
    final now = nowLocal;
    if (_jadwalSholat != null && _jadwalSholat!['jadwal'] != null) {
      final jadwal = _jadwalSholat!['jadwal'];
      final sholatNames = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];
      final displayNames = ['Subuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];
      DateTime? nextPrayer;
      String nextName = "";
      String nextTimeStr = "";
      for (int i = 0; i < sholatNames.length; i++) {
        final timeStr = jadwal[sholatNames[i]]?.toString() ?? "";
        if (timeStr.isEmpty) continue;
        final prayerParts = timeStr.split(':');
        if (prayerParts.length < 2) continue;
        final hourP = int.tryParse(prayerParts[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final minuteP = int.tryParse(prayerParts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final prayerTime = DateTime(now.year, now.month, now.day, hourP, minuteP);
        if (prayerTime.isAfter(now)) {
          nextPrayer = prayerTime;
          nextName = displayNames[i];
          nextTimeStr = timeStr;
          break;
        }
      }
      if (nextPrayer == null) {
        final subuhParts = jadwal['subuh'].toString().split(':');
        final subuhHour = int.tryParse(subuhParts[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 4;
        final subuhMin = subuhParts.length > 1 ? (int.tryParse(subuhParts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 32) : 32;
        nextPrayer = DateTime(now.year, now.month, now.day + 1, subuhHour, subuhMin);
        nextName = "Subuh";
        nextTimeStr = jadwal['subuh'];
      }
      final diff = nextPrayer.difference(now);
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      final s = diff.inSeconds % 60;
      final countdown = "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
      _nextPrayerName = nextName;
      String currentName = "";
      for (int i = 0; i < sholatNames.length; i++) {
        final timeStr = jadwal[sholatNames[i]]?.toString() ?? "";
        if (timeStr.isEmpty) continue;
        final currParts = timeStr.split(':');
        if (currParts.length < 2) continue;
        final cHour = int.tryParse(currParts[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final cMin = int.tryParse(currParts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final prayerTime = DateTime(now.year, now.month, now.day, cHour, cMin);
        if (prayerTime.isBefore(now) || prayerTime.isAtSameMomentAs(now)) {
          currentName = displayNames[i];
        }
      }
      if (currentName.isEmpty) currentName = "Isya";
      _currentPrayerName = currentName;
      _nextPrayerTimeStr = nextTimeStr;
      _nextPrayerCountdown = countdown;
      _prayerTicker.value++;
    }
    if (mounted) setState(() {});
  }

  // ─── WEB SOCKET ────────────────────────────────────────────────────────────
  Future<void> _initAndroidIdAndConnect() async {
    if (kIsWeb) {
      androidId = "web_client";
    } else {
      try {
        final deviceInfo = await DeviceInfoPlugin().androidInfo;
        androidId = deviceInfo.id;
      } catch (_) {
        androidId = "unknown_device";
      }
    }
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    try {
      print("🌐 Connecting to WebSocket...");
      const wsUrl = 'ws://168.144.98.216:7041/ws';
      channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        protocols: ['otax-protocol'],
      );
      print("✅ WebSocket connection established");
      channel.stream.listen(
        (dynamic message) {
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          print("❌ WebSocket error: $error");
          _reconnectWebSocket();
        },
        onDone: () {
          print("🔌 WebSocket connection closed");
          if (channel.closeCode != 1000) _reconnectWebSocket();
        },
        cancelOnError: true,
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (channel != null && channel.closeCode == null) _sendWebSocketAuth();
      });
    } catch (e) {
      _reconnectWebSocket();
    }
  }

  void _sendWebSocketAuth() {
    try {
      final authMessage = jsonEncode({
        "type": "auth",
        "token": sessionKey,
        "androidId": androidId,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      });
      channel.sink.add(authMessage);
      print("✅ Authentication sent");
    } catch (e) {}
  }

  void _handleWebSocketMessage(dynamic event) {
    try {
      final data = jsonDecode(event.toString());
      final type = data['type']?.toString().toLowerCase();
      switch (type) {
        case 'stats_update':
        case 'stats':
          _handleStatsUpdate(data);
          break;
        case 'notification':
        case 'notify':
          _handleNewNotification(data);
          break;
        case 'connections_update':
        case 'senders':
          _handleConnectionsUpdate(data);
          break;
        case 'user_online':
        case 'online':
          _handleUserOnlineUpdate(data);
          break;
        case 'ping':
          channel.sink.add(jsonEncode({
            'type': 'pong',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }));
          break;
        case 'auth_success':
          print("✅ WebSocket authentication successful");
          channel.sink.add(jsonEncode({'type': 'get_initial_data', 'token': sessionKey}));
          break;
        case 'rat_update':
          final msg = data['message'] ?? 'APK RAT terbaru telah diupload di server!';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.system_update_alt, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ],
                ),
                backgroundColor: Colors.green.shade800,
                duration: const Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          break;
        default:
          print("📨 Unknown message type: $type");
      }
    } catch (e) {}
  }

  void _handleStatsUpdate(Map<String, dynamic> data) {
    if (mounted) {
      setState(() {
        onlineUsers = data['total_online_users'] ?? data['onlineUsers'] ?? data['online_count'] ?? onlineUsers;
        activeConnections = data['your_active_connections'] ?? data['myConnections'] ?? data['connections_count'] ?? activeConnections;
      });
    }
  }

  void _handleNewNotification(Map<String, dynamic> data) {
    final notification = {
      'id': data['id'] ?? DateTime.now().millisecondsSinceEpoch,
      'title': data['title'] ?? 'Notification',
      'message': data['message'] ?? '',
      'createdAt': data['timestamp'] ?? DateTime.now().toIso8601String(),
      'type': data['notification_type'] ?? 'info',
      'read': false,
    };
    if (mounted) {
      setState(() {
        notifications.insert(0, notification);
        hasUnreadNotif.value = true;
        if (notifications.length > 50) notifications = notifications.sublist(0, 50);
      });
      _showInAppNotification(notification);
    }
  }

  void _handleConnectionsUpdate(Map<String, dynamic> data) {
    final List<dynamic> connections = data['connections'] ?? [];
    if (mounted) {
      setState(() {
        senderList = connections.cast<Map<String, dynamic>>();
        activeConnections = connections.length;
      });
    }
  }

  void _handleUserOnlineUpdate(Map<String, dynamic> data) {
    final String action = data['action'] ?? 'update';
    final int count = data['count'] ?? onlineUsers;
    if (mounted) {
      setState(() {
        if (action == 'increment') onlineUsers += 1;
        else if (action == 'decrement') { onlineUsers -= 1; if (onlineUsers < 0) onlineUsers = 0; }
        else onlineUsers = count;
      });
    }
  }

  void _showInAppNotification(Map<String, dynamic> notification) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['title'], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 4),
            Text(notification['message'], style: TextStyle(color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        backgroundColor: _getNotificationColor(notification['type']),
        actions: [
          TextButton(onPressed: () { ScaffoldMessenger.of(context).hideCurrentMaterialBanner(); _openNotifications(); }, child: Text('BUKA', style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () { ScaffoldMessenger.of(context).hideCurrentMaterialBanner(); }, child: Text('TUTUP', style: TextStyle(color: Colors.white70))),
        ],
        padding: EdgeInsets.all(16),
      ),
    );
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    });
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'warning': return Colors.orange[800]!;
      case 'error': return Colors.red[800]!;
      case 'success': return Colors.green[800]!;
      default: return Colors.blue[800]!;
    }
  }

  int _reconnectAttempts = 0;
  bool _isReconnecting = false;

  void _reconnectWebSocket() {
    if (_isReconnecting) return;
    _isReconnecting = true;
    _reconnectAttempts++;
    final delaySeconds = _reconnectAttempts <= 5 ? pow(2, _reconnectAttempts).toInt() : 30;
    Future.delayed(Duration(seconds: delaySeconds), () {
      if (mounted) {
        _isReconnecting = false;
        _connectToWebSocket();
      }
    });
  }

  void _startPollingFallback() {
    Timer.periodic(Duration(seconds: 15), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (channel?.closeCode != null) {
        Future.wait([_fetchAdvancedStats(), _fetchSenders(), _fetchNotifications()]);
      }
    });
  }

  void _handleInvalidSession(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: glassBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: bloodRed.withOpacity(0.5), width: 1),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: bloodRed, size: 28),
              const SizedBox(width: 10),
              Text("Session Expired", style: TextStyle(color: bloodRed, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            Container(
              decoration: BoxDecoration(color: bloodRed, borderRadius: BorderRadius.circular(12)),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openNotifications() {
    if (hasUnreadNotif.value) hasUnreadNotif.value = false;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
            color: Color(0xFF0F1419),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Color(0xFF0F2540), width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF091A2D),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(bottom: BorderSide(color: Color(0xFF0F2540), width: 1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: bloodRed.withOpacity(0.1)),
                      child: Center(child: Icon(Icons.notifications_outlined, color: bloodRed, size: 22)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Notifikasi", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                          SizedBox(height: 2),
                          Text("${notifications.length} pesan baru", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)),
                      child: IconButton(
                        icon: Icon(Icons.close, size: 20, color: Colors.white.withOpacity(0.8)),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: notifications.isEmpty
                    ? _buildEmptyNotifications()
                    : _buildNotificationsList(),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF091A2D),
                  border: Border(top: BorderSide(color: Color(0xFF0F2540), width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFF3A3F45), width: 1),
                          color: Colors.white.withOpacity(0.03),
                        ),
                        child: TextButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.check_circle_outline, size: 18, color: Colors.white.withOpacity(0.7)),
                          label: Text("Tandai Semua Dibaca", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500)),
                          style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: bloodRed.withOpacity(0.1),
                        border: Border.all(color: bloodRed.withOpacity(0.2), width: 1),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.refresh, size: 20, color: bloodRed),
                        onPressed: () async { Navigator.pop(context); await _fetchNotifications(); _openNotifications(); },
                        tooltip: "Refresh",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyNotifications() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)),
              child: Icon(Icons.notifications_none_outlined, size: 36, color: Colors.white.withOpacity(0.2)),
            ),
            SizedBox(height: 20),
            Text("Tidak Ada Notifikasi", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text("Tidak ada notifikasi untuk ditampilkan saat ini", textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
            SizedBox(height: 24),
            Container(
              width: 180, height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFF3A3F45), width: 1),
              ),
              child: TextButton(
                onPressed: () async { Navigator.pop(context); await _fetchNotifications(); _openNotifications(); },
                style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh, size: 16, color: Colors.white.withOpacity(0.8)),
                    SizedBox(width: 8),
                    Text("Refresh", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: () async { await _fetchNotifications(); },
      color: bloodRed,
      backgroundColor: Color(0xFF0F1419),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          final title = notification["title"]?.toString() ?? "Notifikasi";
          final message = notification["message"]?.toString() ?? "-";
          final createdAt = notification["createdAt"]?.toString() ?? "";
          final isNew = index == 0;
          String formattedTime;
          try {
            final date = DateTime.parse(createdAt);
            final now = DateTime.now();
            final difference = now.difference(date);
            if (difference.inMinutes < 1) formattedTime = "Baru saja";
            else if (difference.inMinutes < 60) formattedTime = "${difference.inMinutes}m yang lalu";
            else if (difference.inHours < 24) formattedTime = "${difference.inHours}j yang lalu";
            else formattedTime = "${difference.inDays}h yang lalu";
          } catch (e) { formattedTime = "Waktu tidak diketahui"; }
          return _buildNotificationItem(title: title, message: message, time: formattedTime, isNew: isNew);
        },
      ),
    );
  }

  Widget _buildNotificationItem({required String title, required String message, required String time, required bool isNew}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          splashColor: bloodRed.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.02),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isNew ? Color(0xFF1565C0).withOpacity(0.08) : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isNew ? Color(0xFF1565C0).withOpacity(0.25) : Colors.white.withOpacity(0.08), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(title, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    if (isNew) Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Color(0xFF1565C0).withOpacity(0.25), borderRadius: BorderRadius.circular(8)),
                      child: Text("BARU", style: TextStyle(color: bloodRed, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(message, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14), maxLines: 3, overflow: TextOverflow.ellipsis),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time_outlined, size: 14, color: Colors.white.withOpacity(0.4)),
                    SizedBox(width: 6),
                    Text(time, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                    Spacer(),
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)),
                      child: IconButton(
                        icon: Icon(Icons.more_vert, size: 16, color: Colors.white.withOpacity(0.5)),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        splashRadius: 14,
                      ),
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

  // ─── BOTTOM NAV ────────────────────────────────────────────────────────────
  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
      if (index == 0) _selectedPage = _buildEnhancedNewsPage();
      else if (index == 1) _selectedPage = _buildWhatsAppMenuPage();
      else if (index == 2) {
        try { _selectedPage = BugGroupPage(sessionKey: sessionKey, role: role); }
        catch (e) { _selectedPage = Center(child: Text('Error: $e', style: TextStyle(color: Colors.red))); }
      } else if (index == 3) {
        _selectedPage = ToolsPage(
          sessionKey: sessionKey,
          userRole: role,
          listDoos: listDoos,
          username: username,
        );
      }
    });
  }

  // ─── WHATSAPP MENU ──────────────────────────────────────────────────────────
  Widget _buildWhatsAppMenuPage() {
  final primaryOrange = Color(0xFFFF6D00);
  final lightOrange = Color(0xFFFF9100);
  final List<Map<String, dynamic>> menuOptions = [
    {
      'title': 'MANTA BUG',
      'subtitle': 'Bug tanpa custom',
      'description': 'Gunakan langsung tanpa custom delay dan loops',
      'icon': Icons.bug_report,
      'iconColor': Color(0xFFFFB300),
      'gradientColors': [Color(0xFF0D0800), Color(0xFF3D1F00), Color(0xFFFF6D00)],
      'badgeText': 'RECOMMENDED',
      'badgeColor': Color(0xFFFFB300),
      'features': ['Mudah digunakan', 'Function terbaru', 'All work gacor', 'MANTA BUG'],
      'onTap': () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HomePage(
          username: username, password: password, listBug: listBug,
          role: role, expiredDate: expiredDate, sessionKey: sessionKey,
        )),
      ),
    },
    {
      'title': 'CUSTOM BUG',
      'subtitle': 'Menu custom bug',
      'description': 'Buat menu bug, delay pengiriman dan loops',
      'icon': Icons.settings_applications,
      'iconColor': Color(0xFFFFB300),
      'gradientColors': [Color(0xFF0D0800), Color(0xFF3D1F00), Color(0xFFFF9100)],
      'badgeText': 'CUSTOM',
      'badgeColor': Color(0xFFFF9100),
      'features': ['Pengaturan Mudah', 'Support Multi Bug', 'Bebas Spam', 'Gacor The Best'],
      'onTap': () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CustomPayloadPage(
          sessionKey: sessionKey, username: username, role: role, listBug: listBug,
        )),
      ),
    },
    {
      'title': 'SPAM PAIR',
      'subtitle': 'Menu Spam Pairing',
      'description': 'Pairing Whatsapp dan OTP Telegram',
      'icon': Icons.mail,
      'iconColor': Color(0xFFFFB300),
      'gradientColors': [Color(0xFF0D0800), Color(0xFF3D1F00), Color(0xFFFFB300)],
      'badgeText': 'SPAM',
      'badgeColor': Color(0xFFFFB300),
      'features': ['Mudah Digunakan', 'Anti Gimmick', 'Tanpa Sender', 'Pengecekan Backend'],
      'onTap': () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SpamPairPage(
          sessionKey: sessionKey, username: username, role: role,
        )),
      ),
    },
  ];

  final mediaQuery = MediaQuery.of(context);
  final shortestSide = mediaQuery.size.shortestSide;
  final isCompactWhatsAppLayout = shortestSide <= 430 || mediaQuery.devicePixelRatio >= 2.6;
  final double headerHeight = isCompactWhatsAppLayout ? 138 : 148;
  final double carouselViewport = 0.82;
  final double carouselEnlargeFactor = 0.35;
  final double topPadding = isCompactWhatsAppLayout ? 6 : 12;
  final double sectionSpacing = isCompactWhatsAppLayout ? 10 : 12;
  final double carouselHeight = isCompactWhatsAppLayout ? 490 : 520;

  return Scaffold(
    backgroundColor: Colors.transparent,
    body: Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/dashboard_bg.jpg'), // ← FOTO BACKGROUND
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // ─── OVERLAY GELAP ────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.40),
                  Colors.black.withOpacity(0.60),
                  Colors.black.withOpacity(0.80),
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
          Column(
            children: [
              _buildWhatsAppHeader(isCompact: isCompactWhatsAppLayout, headerHeight: headerHeight),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: topPadding, bottom: sectionSpacing),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: carouselHeight,
                        child: CarouselSlider.builder(
                          options: CarouselOptions(
                            height: carouselHeight,
                            viewportFraction: carouselViewport,
                            initialPage: 0,
                            enableInfiniteScroll: true,
                            autoPlay: true,
                            autoPlayInterval: Duration(seconds: 4),
                            autoPlayAnimationDuration: Duration(milliseconds: 850),
                            autoPlayCurve: Curves.easeOutQuart,
                            enlargeCenterPage: true,
                            enlargeFactor: carouselEnlargeFactor,
                            scrollDirection: Axis.horizontal,
                            onPageChanged: (index, reason) {
                              _carouselCurrentNotifier.value = index;
                            },
                          ),
                          itemCount: menuOptions.length,
                          itemBuilder: (context, index, realIndex) {
                            return _buildCarouselCard(menuOptions[index], index);
                          },
                        ),
                      ),
                      SizedBox(height: sectionSpacing),
                      ValueListenableBuilder<int>(
                        valueListenable: _carouselCurrentNotifier,
                        builder: (context, activeIndex, _) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(menuOptions.length, (i) {
                              final bool active = i == activeIndex;
                              return AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                margin: EdgeInsets.symmetric(horizontal: isCompactWhatsAppLayout ? 3 : 4),
                                width: active ? (isCompactWhatsAppLayout ? 16 : 20) : 6,
                                height: isCompactWhatsAppLayout ? 5 : 6,
                                decoration: BoxDecoration(
                                  gradient: active ? LinearGradient(
                                    colors: [primaryOrange, lightOrange, accentGold],
                                  ) : null,
                                  color: active ? null : Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: active ? [BoxShadow(color: primaryOrange.withOpacity(0.45), blurRadius: 6)] : [],
                                ),
                              );
                            }),
                          );
                        },
                      ),
                      SizedBox(height: sectionSpacing),
                      _buildInfoPanel(isCompact: isCompactWhatsAppLayout),
                      SizedBox(height: sectionSpacing),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildWhatsAppHeader({required bool isCompact, required double headerHeight}) {
  final orangeAccent = Color(0xFFFF6D00);
  final lightOrange = Color(0xFFFF9100);
  final solidDark = Color(0xFF0D0800);

  return Container(
    height: headerHeight,
    width: double.infinity,
    decoration: BoxDecoration(
      color: solidDark,
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))],
    ),
    child: Stack(
      children: [
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 2.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, orangeAccent, lightOrange, Colors.transparent],
                stops: [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 1.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.white.withOpacity(0.1), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          top: 20, bottom: 20, left: 0,
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [orangeAccent.withOpacity(0.8), lightOrange.withOpacity(0.4)],
              ),
              borderRadius: BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
            ),
          ),
        ),
        Positioned(
          top: 10, right: 15,
          child: Opacity(
            opacity: 0.12,
            child: SizedBox(width: 80, height: 50, child: CustomPaint(painter: _DotGridPainter())),
          ),
        ),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 18 : 22),
            child: Row(
              children: [
                Container(
                  width: isCompact ? 54 : 64,
                  height: isCompact ? 54 : 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1A0E00),
                    border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
                    boxShadow: [BoxShadow(color: orangeAccent.withOpacity(0.25), blurRadius: 15, spreadRadius: 2)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Center(child: Icon(Icons.chat, color: orangeAccent, size: isCompact ? 24 : 28)),
                    ),
                  ),
                ),
                SizedBox(width: isCompact ? 16 : 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "BUG MENU",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isCompact ? 19 : 23,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              shadows: [Shadow(color: orangeAccent.withOpacity(0.5), blurRadius: 10)],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [orangeAccent.withOpacity(0.5), Colors.transparent],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          _buildWhatsAppHeaderChip("ONLINE v2.0", Color(0xFFFF6D00), isCompact: isCompact),
                          SizedBox(width: 8),
                          _buildWhatsAppHeaderChip("Elegant Edition", accentGold, isCompact: isCompact),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Pilih menu yang tersedia bosque!",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: isCompact ? 10 : 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildWhatsAppHeaderChip(String text, Color color, {bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 7 : 9, vertical: isCompact ? 3 : 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white.withOpacity(0.10), color.withOpacity(0.08)]),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.38)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 12)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 4 : 5,
            height: isCompact ? 4 : 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color.withOpacity(0.55), blurRadius: 8)],
            ),
          ),
          SizedBox(width: isCompact ? 4 : 5),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: isCompact ? 7.6 : 8.4,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselCard(Map<String, dynamic> option, int index) {
    final gradientColors = option['gradientColors'] as List<Color>;
    final badgeColor = option['badgeColor'] as Color;
    final features = option['features'] as List<String>;
    final iconColor = option['iconColor'] as Color;
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final isCompact = shortestSide <= 430;

    return Animate(
      effects: [
        FadeEffect(duration: 350.ms, delay: (80 * index).ms),
        SlideEffect(begin: Offset(0, 0.04), end: Offset.zero, duration: 350.ms, delay: (80 * index).ms, curve: Curves.easeOut),
      ],
      child: GestureDetector(
        onTap: option['onTap'] as VoidCallback,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: isCompact ? 5 : 6, vertical: isCompact ? 4 : 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [gradientColors[0], gradientColors[1], gradientColors[2]],
              stops: [0.0, 0.52, 1.0],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.3),
            boxShadow: [
              BoxShadow(color: gradientColors[2].withOpacity(0.24), blurRadius: 34, spreadRadius: 2, offset: Offset(0, 18)),
              BoxShadow(color: Colors.black.withOpacity(0.34), blurRadius: 22, offset: Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white.withOpacity(0.12), Colors.transparent, Colors.black.withOpacity(0.12)],
                        stops: [0.0, 0.42, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: isCompact ? -20 : -28,
                  right: isCompact ? -14 : -18,
                  child: Container(
                    width: isCompact ? 82 : 100,
                    height: isCompact ? 82 : 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.10), width: 1.2),
                    ),
                  ),
                ),
                Positioned(
                  bottom: isCompact ? -8 : -12,
                  right: isCompact ? -8 : -12,
                  child: Opacity(
                    opacity: 0.08,
                    child: Text(
                      "MANTA X",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 52 : 66,
                        fontWeight: FontWeight.w900,
                        letterSpacing: isCompact ? 3 : 5,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: isCompact ? -10 : -14,
                  left: isCompact ? -10 : -14,
                  child: Container(
                    width: isCompact ? 72 : 90,
                    height: isCompact ? 72 : 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.white.withOpacity(0.14), Colors.white.withOpacity(0.04), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: isCompact ? 56 : 68,
                  right: isCompact ? -4 : -6,
                  child: Container(
                    width: isCompact ? 44 : 58,
                    height: isCompact ? 44 : 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: badgeColor.withOpacity(0.28)),
                    ),
                  ),
                ),
                Positioned(
                  top: 0, left: 0, right: 0,
                  height: isCompact ? 62 : 76,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white.withOpacity(0.16), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 16 : 20,
                      isCompact ? 12 : 14,
                      isCompact ? 16 : 20,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: isCompact ? 44 : 52,
                              height: isCompact ? 44 : 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.white.withOpacity(0.24), Colors.white.withOpacity(0.08)],
                                ),
                                border: Border.all(color: Colors.white.withOpacity(0.32), width: 1.5),
                                boxShadow: [BoxShadow(color: iconColor.withOpacity(0.28), blurRadius: 18, spreadRadius: 1)],
                              ),
                              child: Center(
                                child: Icon(option['icon'] as IconData, color: iconColor, size: isCompact ? 20 : 24),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 10, vertical: isCompact ? 4 : 5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [badgeColor.withOpacity(0.24), badgeColor.withOpacity(0.10)],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: badgeColor.withOpacity(0.72), width: 1.5),
                                boxShadow: [BoxShadow(color: badgeColor.withOpacity(0.18), blurRadius: 12)],
                              ),
                              child: Text(
                                option['badgeText'] as String,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isCompact ? 8 : 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: isCompact ? 0.7 : 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isCompact ? 8 : 10),
                        Text(
                          option['title'] as String,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isCompact ? 15.5 : 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: isCompact ? 0.5 : 1.0,
                            shadows: [Shadow(color: Colors.black.withOpacity(0.35), blurRadius: 8)],
                          ),
                        ),
                        SizedBox(height: isCompact ? 2 : 3),
                        Text(
                          option['subtitle'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.82),
                            fontSize: isCompact ? 10.2 : 11.4,
                            fontWeight: FontWeight.w500,
                            letterSpacing: isCompact ? 0.2 : 0.45,
                          ),
                        ),
                        SizedBox(height: isCompact ? 6 : 8),
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [badgeColor.withOpacity(0.85), Colors.white.withOpacity(0.08)],
                            ),
                          ),
                        ),
                        SizedBox(height: isCompact ? 6 : 8),
                        Text(
                          option['description'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.90),
                            fontSize: isCompact ? 10.6 : 11.8,
                            height: isCompact ? 1.35 : 1.45,
                            letterSpacing: 0.25,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isCompact ? 6 : 8),
                        Wrap(
                          spacing: isCompact ? 5 : 6,
                          runSpacing: isCompact ? 5 : 6,
                          children: features.take(2).map((f) => Container(
                            padding: EdgeInsets.symmetric(horizontal: isCompact ? 7 : 8, vertical: isCompact ? 4 : 5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white.withOpacity(0.14), Colors.white.withOpacity(0.06)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.16)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.stars_rounded, color: badgeColor, size: isCompact ? 10 : 11),
                                SizedBox(width: isCompact ? 3 : 4),
                                Text(f, style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: isCompact ? 8.6 : 9.4, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )).toList(),
                        ),
                        const Spacer(),
                        Container(
                          margin: EdgeInsets.only(bottom: isCompact ? 10 : 12),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Colors.white.withOpacity(0.22), Colors.white.withOpacity(0.10)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withOpacity(0.24), width: 1),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: option['onTap'] as VoidCallback,
                              splashColor: Colors.white.withOpacity(0.15),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 13),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("START MODULE", style: TextStyle(color: Colors.white, fontSize: isCompact ? 10.4 : 11.8, fontWeight: FontWeight.w800, letterSpacing: isCompact ? 1.0 : 1.4)),
                                    SizedBox(width: isCompact ? 6 : 8),
                                    Container(
                                      width: isCompact ? 18 : 22,
                                      height: isCompact ? 18 : 22,
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), shape: BoxShape.circle),
                                      child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: isCompact ? 12 : 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel({bool isCompact = false}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isCompact ? 14 : 16),
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 14, vertical: isCompact ? 10 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentPurple.withOpacity(0.14), accentPink.withOpacity(0.08), Colors.white.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(isCompact ? 18 : 20),
        border: Border.all(color: accentGold.withOpacity(0.18), width: 1),
        boxShadow: [BoxShadow(color: accentPurple.withOpacity(0.10), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: isCompact ? 30 : 34,
            height: isCompact ? 30 : 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [accentGold, accentPink, bloodRed]),
              borderRadius: BorderRadius.circular(isCompact ? 9 : 10),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: darkRed, size: isCompact ? 14 : 16),
          ),
          SizedBox(width: isCompact ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Semua menu telah diuji coba dan tanpa gimmick real work 100%",
                  style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: isCompact ? 10.2 : 11.2, fontWeight: FontWeight.w600, height: 1.3),
                ),
                SizedBox(height: isCompact ? 2 : 3),
                Row(
                  children: [
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [accentGold, accentPink]),
                        boxShadow: [BoxShadow(color: accentPink.withOpacity(0.45), blurRadius: 6)],
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      "MANTA TEAM",
                      style: TextStyle(color: lightPurple.withOpacity(0.72), fontSize: isCompact ? 8.8 : 9.4, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ENHANCED NEWS PAGE (MAIN DASHBOARD) ──────────────────────────────────
  Widget _buildEnhancedNewsPage() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => isRefreshing = true);
        await Future.wait([
          _fetchSenders(),
          _fetchNotifications(),
          _fetchCnbcNews(silent: true),
        ]);
        setState(() => isRefreshing = false);
      },
      color: Colors.white,
      backgroundColor: Color(0xFF020408),
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/dashboard_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // ─── OVERLAY GELAP ────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.40),
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.70),
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: [0.0, 0.25, 0.60, 1.0],
                ),
              ),
            ),
            // ─── SLIVER APP BAR ──────────────────────────────────────────
            CustomScrollView(
              physics: BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: false,
                  floating: false,
                  stretch: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  leading: const SizedBox.shrink(),
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.30),
                            Colors.black.withOpacity(0.10),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // ─── VIDEO BANNER ──────────────────────────────
                          Positioned.fill(
                            child: VideoBannerWidget(
                              videoPath: 'assets/videos/dashboard_hero.mp4',
                            ),
                          ),
                          // ─── OVERLAY ──────────────────────────────────
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.60),
                                    Colors.transparent,
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // ─── TEKS "MANTAX is HERE" ────────────────────
                          Positioned(
  bottom: 16,
  left: 16,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "MANTAX is HERE",
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          shadows: [
            Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 10),
          ],
        ),
      ),
      Row(
        children: [
          Text(
            username,  // ← NAMA DARI SERVER
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getRoleColor(role).withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _getRoleColor(role).withOpacity(0.5)),
            ),
            child: Text(
              role.toUpperCase(),  // ← ROLE DARI SERVER
              style: TextStyle(
                color: _getRoleColor(role),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
),
                // ─── KONTEN UTAMA ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Column(
                      children: [
                        // ─── UPDATE BANNER ──────────────────────────────
                        if (_showUpdateBanner && _updateInfo != null)
                          _buildUpdateBanner(),
                        // ─── USER PROFILE CARD ──────────────────────────
                        Container(
                          padding: EdgeInsets.all(24),
                          margin: EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 30,
                                offset: Offset(0, 15),
                              ),
                            ],
                            image: DecorationImage(
                              image: AssetImage('assets/images/profile_card_bg.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                // ─── OVERLAY ────────────────────────────
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.black.withOpacity(0.30),
                                        Colors.black.withOpacity(0.50),
                                        Colors.black.withOpacity(0.70),
                                      ],
                                      stops: [0.0, 0.40, 1.0],
                                    ),
                                  ),
                                ),
                                // ─── KONTEN ──────────────────────────────
                                Positioned(
                                  bottom: -10, right: -10,
                                  child: Opacity(
                                    opacity: 0.06,
                                    child: CustomPaint(
                                      size: Size(180, 180),
                                      painter: _HexPainter(color: accentPink),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: -10, left: -10,
                                  child: Opacity(
                                    opacity: 0.05,
                                    child: CustomPaint(
                                      size: Size(130, 130),
                                      painter: _HexPainter(color: bloodRed),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ProfilePage(
                                                    username: username,
                                                    password: password,
                                                    sessionKey: sessionKey,
                                                    expiredDate: expiredDate,
                                                    role: role,
                                                  ),
                                                ),
                                              );
                                              _loadProfileImage();
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  colors: [accentGold, accentPink, bloodRed],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: accentPink.withOpacity(0.22),
                                                    blurRadius: 24,
                                                    spreadRadius: 3,
                                                  ),
                                                ],
                                              ),
                                              child: CircleAvatar(
                                                radius: 28,
                                                backgroundColor: Colors.transparent,
                                                backgroundImage: _profileImagePath != null && _profileImagePath!.isNotEmpty
                                                    ? (_profileImagePath!.startsWith('http')
                                                        ? NetworkImage(_profileImagePath!)
                                                        : FileImage(File(_profileImagePath!)) as ImageProvider)
                                                    : null,
                                                child: (_profileImagePath == null || _profileImagePath!.isEmpty)
                                                    ? Icon(Icons.verified_user, color: Colors.white, size: 26)
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Ahlan Wa Sahlan!!",
                                                  style: TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w400,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  username,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w800,
                                                    fontFamily: 'Orbitron',
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _getRoleColor(role).withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(
                                                      color: _getRoleColor(role).withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    role.toUpperCase(),
                                                    style: TextStyle(
                                                      color: _getRoleColor(role),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 1,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                            const SizedBox(width: 12),
                                          Expanded(
                                            flex: 1,
                                            child: const MantaClockAccessory(),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              accentPurple.withOpacity(0.14),
                                              accentPink.withOpacity(0.10),
                                              Colors.transparent,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: accentGold.withOpacity(0.20),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          "MANTA X DASHBOARD",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: lightRed,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 2.0,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Divider(
                                        color: Colors.white.withOpacity(0.1),
                                        height: 1,
                                      ),
                                      SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildRealTimeStatChip(
                                            icon: Icons.people,
                                            value: '$onlineUsers',
                                            label: "Online Users",
                                            color: Color(0xFF76FF03),
                                            isLive: onlineUsers > 0,
                                          ),
                                          _buildRealTimeStatChip(
                                            icon: Icons.link,
                                            value: '$activeConnections',
                                            label: "Active Connections",
                                            color: Color(0xFFFF9800),
                                            isLive: activeConnections > 0,
                                          ),
                                          _buildStatChip(
                                            icon: Icons.calendar_today,
                                            value: expiredDate,
                                            label: "Expiration",
                                            color: Color(0xFFFFFFFF),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // ─── SHOLAT ──────────────────────────────────────
                        ValueListenableBuilder<int>(
                          valueListenable: _prayerTicker,
                          builder: (context, _, __) {
                            if (_isLoadingSholat) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.40),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: accentGold,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Text(
                                      "Menentukan Jam Sholat...",
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            if (_jadwalSholat == null || _jadwalSholat!['jadwal'] == null) {
                              return const SizedBox.shrink();
                            }
                            final jadwal = _jadwalSholat!['jadwal'];
                            final prayerItems = [
                              {'n': 'SUBUH', 't': jadwal['subuh'], 'c': const Color(0xFFFFA726)},
                              {'n': 'DZUHUR', 't': jadwal['dzuhur'], 'c': const Color(0xFFFFA726)},
                              {'n': 'ASHAR', 't': jadwal['ashar'], 'c': const Color(0xFFFFA726)},
                              {'n': 'MAGHRIB', 't': jadwal['maghrib'], 'c': const Color(0xFFFFA726)},
                              {'n': 'ISYA', 't': jadwal['isya'], 'c': const Color(0xFFFFA726)},
                            ];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF3D2817), Color(0xFF24160B)],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // ─── HEADER ────────────────────────────
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.mosque_rounded, color: accentGold, size: 18),
                                            SizedBox(width: 10),
                                            Text(
                                              "JADWAL SHOLAT",
                                              style: TextStyle(
                                                color: Colors.orange,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.1),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.timer_outlined, color: accentPink, size: 12),
                                              SizedBox(width: 6),
                                              Text(
                                                "MENUJU ${_nextPrayerName.toUpperCase()} : ",
                                                style: TextStyle(
                                                  color: accentPink.withOpacity(0.9),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                _nextPrayerCountdown,
                                                style: TextStyle(
                                                  color: Colors.orange,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'ShareTechMono',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  // ─── GRID SHOLAT ──────────────────────
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.center,
                                    children: prayerItems.map((p) {
                                      final bool isCurrent = _currentPrayerName.toUpperCase() == p['n'];
                                      return Container(
                                        width: (MediaQuery.of(context).size.width - 60) / 3.2,
                                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                        decoration: BoxDecoration(
                                          gradient: isCurrent
                                              ? LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    p['c'].withOpacity(0.3),
                                                    p['c'].withOpacity(0.1),
                                                  ],
                                                )
                                              : null,
                                          color: isCurrent ? null : Colors.black.withOpacity(0.25),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isCurrent
                                                ? p['c'].withOpacity(0.6)
                                                : Colors.white.withOpacity(0.08),
                                            width: isCurrent ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              p['n'],
                                              style: TextStyle(
                                                color: isCurrent ? p['c'] : Colors.white60,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              p['t'].toString(),
                                              style: TextStyle(
                                                color: isCurrent ? Colors.white : Colors.white60,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                fontFamily: 'ShareTechMono',
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  SizedBox(height: 12),
                                  // ─── KOTA ──────────────────────────────
                                  GestureDetector(
                                    onTap: _showCitySelector,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.location_on_rounded, color: Color(0xFFFF9800), size: 14),
                                          SizedBox(width: 6),
                                          Text(
                                            (_jadwalSholat?['lokasi'] ?? _selectedCityName)
                                                .toString()
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white30, size: 14),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        // ─── BERITA ──────────────────────────────────────
                        if (newsList.isNotEmpty) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.newspaper, color: accentPink, size: 24),
                                    SizedBox(width: 12),
                                    Text(
                                      "BERITA TERKINI",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 2,
                                        fontFamily: 'Orbitron',
                                      ),
                                    ),
                                    Spacer(),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [accentPink.withOpacity(0.20), accentGold.withOpacity(0.12)],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: accentPink.withOpacity(0.30),
                                        ),
                                      ),
                                      child: Text(
                                        "${newsList.length} Berita",
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                              SizedBox(
                                height: 260,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: newsList.length,
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  itemBuilder: (context, i) {
                                    final item = newsList[i];
                                    return _buildNewsCard(item, i);
                                  },
                                ),
                              ),
                              SizedBox(height: 30),
                            ],
                          ),
                        ],
                        // ─── QUICK ACTIONS ──────────────────────────────
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.03),
                                    Colors.white.withOpacity(0.01),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: accentPurple.withOpacity(0.34),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                  decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        image: const DecorationImage(
                        image: AssetImage(
                                 "assets/images/MANTAlogo.png",
      ),
      fit: BoxFit.cover,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 15,
        spreadRadius: 2,
      ),
    ],
  ),
),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "QUICK ACTIONS",
                                          style: TextStyle(
                                            color: lightPurple,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.5,
                                            fontFamily: 'Orbitron',
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Beberapa Menu MANTA X",
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          bloodRed.withOpacity(0.16),
                                          accentPurple.withOpacity(0.12),
                                          accentPink.withOpacity(0.08),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: primaryWhite.withOpacity(0.1),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: bloodRed.withOpacity(0.08),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          duration: Duration(milliseconds: 1000),
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [bloodRed, accentPurple],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: bloodRed.withOpacity(0.5),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "MANTA X",
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                            shadows: [
                                              Shadow(
                                                color: bloodRed.withOpacity(0.2),
                                                blurRadius: 5,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            CarouselSlider.builder(
                              options: CarouselOptions(
                                height: 190,
                                aspectRatio: 16 / 9,
                                viewportFraction: 0.78,
                                initialPage: 0,
                                enableInfiniteScroll: true,
                                reverse: false,
                                autoPlay: true,
                                autoPlayInterval: Duration(seconds: 5),
                                autoPlayAnimationDuration: Duration(milliseconds: 800),
                                autoPlayCurve: Curves.fastOutSlowIn,
                                enlargeCenterPage: true,
                                enlargeFactor: 0.35,
                                scrollDirection: Axis.horizontal,
                                onPageChanged: (index, reason) {
                                  _quickActionNotifier.value = index;
                                },
                              ),
                              itemCount: 6,
                              itemBuilder: (context, index, realIndex) {
                                final actions = [
                                  _ModernActionCard(
                                    title: "TabunganKu",
                                    subtitle: "Manage Duit",
                                    icon: Iconsax.wallet_3,
                                    iconColor: Colors.white,
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF000000), Color(0xFFFF9800), Color(0xFFE91E63)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const TabunganKuModule(),
                                        ),
                                      );
                                    },
                                    index: index,
                                  ),
                                  _ModernActionCard(
                                    title: "Manage Bug Sender",
                                    subtitle: "Pairing & Configuration",
                                    icon: Icons.bug_report_rounded,
                                    iconColor: Colors.white,
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFFF9800), Color(0xFFE91E63), Color(0xFF4A148C)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (_, __, ___) => BugSenderPage(
                                            sessionKey: sessionKey,
                                            username: username,
                                            role: role,
                                          ),
                                          transitionsBuilder: (_, animation, __, child) {
                                            return FadeTransition(
                                              opacity: CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeInOut,
                                              ),
                                              child: child,
                                            );
                                          },
                                          transitionDuration: Duration(milliseconds: 400),
                                        ),
                                      );
                                    },
                                    index: index,
                                  ),
                                  _ModernActionCard(
                                    title: "Chat Room",
                                    subtitle: "Global Communication",
                                    icon: Icons.chat_bubble_rounded,
                                    iconColor: Colors.white,
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF000000), Color(0xFFFF9800), Color(0xFF03A9F4)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (_, __, ___) => ChatRoomPage(username: username),
                                          transitionsBuilder: (_, animation, __, child) {
                                            return SlideTransition(
                                              position: Tween<Offset>(
                                                begin: Offset(1, 0),
                                                end: Offset.zero,
                                              ).animate(
                                                CurvedAnimation(
                                                  parent: animation,
                                                  curve: Curves.easeOutCubic,
                                                ),
                                              ),
                                              child: child,
                                            );
                                          },
                                          transitionDuration: Duration(milliseconds: 500),
                                        ),
                                      );
                                    },
                                    index: index,
                                  ),
                                  _ModernActionCard(
                                    title: "Telegram Report",
                                    subtitle: "MANTA Report System",
                                    icon: Icons.send,
                                    iconColor: Colors.white,
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFFF9800), Color(0xFF4A148C), Color(0xFFE91E63)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (_, __, ___) => MultiProvider(
                                            providers: [
                                              ChangeNotifierProvider<SessionProvider>(
                                                create: (_) {
                                                  final provider = SessionProvider();
                                                  provider.initialize();
                                                  return provider;
                                                },
                                              ),
                                            ],
                                            child: const DashboardPageTelegram(),
                                          ),
                                          transitionsBuilder: (_, animation, __, child) {
                                            final curvedAnimation = CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeInOut,
                                            );
                                            return FadeTransition(
                                              opacity: curvedAnimation,
                                              child: ScaleTransition(
                                                scale: Tween<double>(
                                                  begin: 0.9,
                                                  end: 1.0,
                                                ).animate(curvedAnimation),
                                                child: child,
                                              ),
                                            );
                                          },
                                          transitionDuration: Duration(milliseconds: 400),
                                        ),
                                      );
                                    },
                                    index: index,
                                  ),
                                  _ModernActionCard(
                                    title: "TES FUNC",
                                    subtitle: "Test Function & Message",
                                    icon: Icons.code_rounded,
                                    iconColor: Colors.white,
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFFF9800), Color(0xFF03A9F4), Color(0xFF000000)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TesFuncPage(
                                            sessionKey: sessionKey,
                                            username: username,
                                            role: role,
                                          ),
                                        ),
                                      );
                                    },
                                    index: index,
                                  ),
                                  _ModernActionCard(
                                    title: "Al-QURAN",
                                    subtitle: "Alquran Lengkap Beserta Terjemahan",
                                    icon: Icons.menu_book_rounded,
                                    iconColor: Colors.white,
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFFF9800), Color(0xFFE91E63), Color(0xFF0D47A1)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AlQuranPage(),
                                        ),
                                      );
                                    },
                                    index: index,
                                  ),
                                ];
                                return actions[index];
                              },
                            ),
                            const SizedBox(height: 20),
                            ValueListenableBuilder<int>(
                              valueListenable: _quickActionNotifier,
                              builder: (context, activeIndex, _) {
                                return Center(
                                  child: Wrap(
                                    spacing: 6,
                                    children: List.generate(6, (i) {
                                      final bool isActive = i == activeIndex;
                                      return AnimatedContainer(
                                        duration: Duration(milliseconds: 300),
                                        width: isActive ? 24 : 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(4),
                                          color: isActive
                                              ? bloodRed
                                              : Colors.white.withOpacity(0.16),
                                          boxShadow: isActive
                                              ? [
                                                  BoxShadow(
                                                    color: bloodRed.withOpacity(0.45),
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      );
                                    }),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        // ─── SOCIAL ──────────────────────────────────────
                        const SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.50),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.connect_without_contact,
                                    color: Color(0xFFFF9800),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "CONNECT WITH MANTA TEAM",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildSocialButton(
                                    icon: Icons.send,
                                    color: Color(0xFFFF9800),
                                    label: "Telegram",
                                    url: 'https://t.me/Babehmodssv2',
                                  ),
                                  _buildSocialButton(
                                    icon: Icons.video_library,
                                    color: Color(0xFFFF9800),
                                    label: "YouTube",
                                    url: 'https://youtube.com',
                                  ),
                                  _buildSocialButton(
                                    icon: Icons.music_note,
                                    color: Color(0xFF000000),
                                    label: "TikTok",
                                    url: 'https://www.tiktok.com/@iwan_tek_tek',
                                  ),
                                  _buildSocialButton(
                                    icon: Icons.favorite,
                                    color: Color(0xFFE91E63),
                                    label: "Thanks To",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ThanksToPage(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              Text(
                                "Selalu nantikan project terbaru dari TEAM MANTA",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case "owner": return Colors.red;
      case "tk": return primaryPurple;
      case "pt": return Colors.green;
      case "reseller": return Colors.orange;
      default: return lightPurple;
    }
  }

  Widget _buildRealTimeStatChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    bool isLive = false,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Center(child: Icon(icon, color: color, size: 24)),
            ),
            if (isLive)
              Positioned(
                top: 0, right: 0,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                    boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.8), blurRadius: 8, spreadRadius: 2)],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
        Text(value, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w400)),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Center(child: Icon(icon, color: color, size: 24)),
        ),
        SizedBox(height: 8),
        Text(value, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w400)),
      ],
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> item, int index) {
    final newsLink = item['link']?.toString() ?? '';
    final newsDate = _formatNewsDate(item['date']?.toString());

    return Container(
      width: 280,
      margin: EdgeInsets.only(right: 16),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _openNewsLink(newsLink),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D2137), Color(0xFF091A2B)],
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    child: Stack(
                      children: [
                        if (item['image'] != null)
                          Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(item['image']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12, right: 12,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.open_in_new_rounded, color: Color(0xFFFF5722), size: 12),
                                SizedBox(width: 4),
                                Text("BACA", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['title'] ?? 'No Title',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.white.withOpacity(0.5), size: 14),
                            SizedBox(width: 6),
                            Text(newsDate, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                            Spacer(),
                            Icon(Icons.arrow_forward, color: Color(0xFFFF5722), size: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateBanner() {
    final isCritical = _updateInfo?['critical'] == true;
    final version = _updateInfo?['version'] ?? 'terbaru';

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SizedBox.shrink()));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isCritical ? [Color(0xFFD32F2F), Color(0xFFB71C1C)] : [Color(0xFF2196F3), Color(0xFF1976D2)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isCritical ? Colors.red[300]! : Colors.blue[300]!, width: 2),
          boxShadow: [
            BoxShadow(color: isCritical ? Colors.red.withOpacity(0.3) : Colors.blue.withOpacity(0.3), blurRadius: 15, spreadRadius: 3, offset: Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Icon(isCritical ? Icons.warning : Icons.system_update, color: Colors.white, size: 24),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isCritical ? 'UPDATE KRITIS' : 'UPDATE TERSEDIA',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text('v$version', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Versi terbaru telah tersedia. Ketuk untuk mengupdate aplikasi.',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                  ),
                  if (_changelog.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text('Fitur baru:', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ..._changelog.take(2).map((change) => Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 12, color: Colors.white),
                          SizedBox(width: 6),
                          Expanded(child: Text(change, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11))),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
            SizedBox(width: 12),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required String label,
    String? url,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () async {
        if (url != null) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            await launchUrl(uri);
          }
        }
      },
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Center(child: Icon(icon, color: color, size: 24)),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MantaDrawer(
        username: username,
        password: widget.password,
        role: role,
        expiredDate: expiredDate,
        sessionKey: sessionKey,
        onNavigateToAdmin: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdminPage(sessionKey: sessionKey)),
          );
        },
        onProfileUpdated: _loadProfileImage,
      ),
      backgroundColor: deepBlack,
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 150,
        leading: Builder(
          builder: (context) => SizedBox(
            height: 56,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.menu_rounded, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                    if (_weatherInfo != null)
                      GestureDetector(
                        onTap: () {
                          if (_fullWeatherData != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WeatherPage(fullData: _fullWeatherData!),
                              ),
                            );
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.network(
                              _weatherInfo!['image'],
                              width: 24,
                              height: 24,
                              placeholderBuilder: (context) => Icon(Icons.wb_cloudy_rounded, color: Colors.white70, size: 20),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${_weatherInfo!['t']}°C",
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'),
                            ),
                          ],
                        ),
                      )
                    else if (_isLoadingWeather)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00B4D8))),
                        ),
                      )
                    else
                      IconButton(
                        icon: Icon(Icons.refresh_rounded, size: 18, color: Colors.white38),
                        onPressed: () => _fetchWeatherData(_selectedCityName),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF0F141B), const Color(0xFF162333)],
            ),
          ),
          child: CustomPaint(painter: _AestheticLinesPainter()),
        ),
        title: Container(
          height: 70,
          child: Image.asset(
            'assets/images/MANTAlogo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.white, Colors.white],
                ).createShader(bounds),
                child: const Text(
                  "MANTA X",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
                ),
              );
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.music_note_rounded, color: lightPurple),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    backgroundColor: deepBlack,
                    body: SpotifyMusicPlayer(sessionKey: sessionKey, username: username),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: ValueListenableBuilder<bool>(
              valueListenable: hasUnreadNotif,
              builder: (context, hasNew, child) {
                return Stack(
                  children: [
                    child!,
                    if (hasNew)
                      Positioned(
                        right: 0, top: 0,
                        child: Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: bloodRed,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: bloodRed.withOpacity(0.6), blurRadius: 10, spreadRadius: 1)],
                          ),
                        ),
                      ),
                  ],
                );
              },
              child: Icon(Icons.notifications_none_rounded, color: lightPurple),
            ),
            onPressed: _openNotifications,
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(
                    username: username,
                    password: password,
                    sessionKey: sessionKey,
                    expiredDate: expiredDate,
                    role: role,
                  ),
                ),
              );
              _loadProfileImage();
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16, left: 8),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: lightPurple.withOpacity(0.5), width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: cardDark,
                  backgroundImage: _profileImagePath != null && _profileImagePath!.isNotEmpty
                      ? (_profileImagePath!.startsWith('http')
                          ? NetworkImage(_profileImagePath!)
                          : FileImage(File(_profileImagePath!)) as ImageProvider)
                      : null,
                  child: (_profileImagePath == null || _profileImagePath!.isEmpty)
                      ? Icon(Icons.person_rounded, size: 16, color: lightPurple)
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FadeTransition(opacity: _animation, child: _selectedPage),
          Positioned(
            bottom: 62, left: -20,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.07,
                child: CustomPaint(size: Size(110, 110), painter: _HexPainter(color: bloodRed)),
              ),
            ),
          ),
          Positioned(
            bottom: 62, right: -20,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.07,
                child: CustomPaint(size: Size(100, 100), painter: _HexPainter(color: accentPurple)),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildGlassBottomNavBar(),
    );
  }

    Widget _buildGlassBottomNavBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: 80 + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        // Gradient fade biar background foto di belakang nav bar tetap keliatan
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black12,
            Colors.black26,
          ],
        ),
      ),
      child: Center(
        child: Container(
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            // Background image navbar - TERLIHAT JELAS
            image: const DecorationImage(
              image: AssetImage('assets/images/navbar_bg.png'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: const Color(0xFFFF7A00).withOpacity(0.6), // Orange border
              width: 1.5,
            ),
            boxShadow: [
              // Glow orange di sekitar nav bar
              BoxShadow(
                color: const Color(0xFFFF7A00).withOpacity(0.25),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              // Shadow dasar
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 25,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2), // Blur SANGAT RINGAN biar foto tetap keliatan
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.35),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(index: 0, icon: Icons.home_rounded, activeIcon: Icons.home_filled, label: "Home"),
                    _buildNavItem(index: 1, icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: "Chat"),
                    _buildNavItem(index: 2, icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: "Group"),
                    _buildNavItem(index: 3, icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: "Tools"),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    String? label,
  }) {
    bool isActive = _bottomNavIndex == index;

    return GestureDetector(
      onTap: () => _onBottomNavTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background lingkaran orange saat active
            if (isActive)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF7A00),
                      Color(0xFFFF9500),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7A00).withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            // Icon
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey<bool>(isActive),
                color: isActive
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
                size: isActive ? 26 : 24,
              ),
            ),
            // Dot merah kecil di pojok kanan atas icon saat active (seperti di foto)
            if (isActive)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF3B30), // Merah
                    border: Border.all(
                      color: const Color(0xFFFF7A00),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF3B30).withOpacity(0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }


  @override
  void dispose() {
    try { _timeTimer?.cancel(); _fetchTimer?.cancel(); _healthCheckTimer?.cancel(); _sholatTimer?.cancel(); _realTimeClockTimer?.cancel(); } catch (e) {}
    try { channel.sink.close(1000, 'App disposed'); } catch (e) {}
    _videoController?.dispose();
    _controller?.dispose();
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    super.dispose();
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MANTA CLOCK ACCESSORY - Jam Analog Realtime + Status Baterai & Jaringan
// ═════════════════════════════════════════════════════════════════════════════
class MantaClockAccessory extends StatefulWidget {
  const MantaClockAccessory({super.key});

  @override
  State<MantaClockAccessory> createState() => _MantaClockAccessoryState();
}

class _MantaClockAccessoryState extends State<MantaClockAccessory> {
  late Timer _timer;
  late DateTime _wibTime;

  final Battery _battery = Battery();
  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.unknown;
  StreamSubscription<BatteryState>? _batterySub;

  final Connectivity _connectivity = Connectivity();
  String _networkLabel = "Checking...";
  IconData _networkIcon = Icons.signal_cellular_alt_rounded;
  Color _networkColor = const Color(0xFF29B6F6);
  StreamSubscription<List<ConnectivityResult>>? _networkSub;

  @override
  void initState() {
    super.initState();
    _wibTime = DateTime.now().toUtc().add(const Duration(hours: 7));
    _startClock();
    _initBattery();
    _initNetwork();
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _wibTime = DateTime.now().toUtc().add(const Duration(hours: 7));
        });
      }
    });
  }

  Future<void> _initBattery() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) setState(() => _batteryLevel = level);
      _batterySub = _battery.onBatteryStateChanged.listen((state) async {
        final lvl = await _battery.batteryLevel;
        if (mounted) {
          setState(() {
            _batteryState = state;
            _batteryLevel = lvl;
          });
        }
      });
    } catch (e) {
      debugPrint('Battery error: $e');
    }
  }

  Future<void> _initNetwork() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateNetwork(results);
      _networkSub = _connectivity.onConnectivityChanged.listen((results) {
        _updateNetwork(results);
      });
    } catch (e) {
      debugPrint('Network error: $e');
    }
  }

  void _updateNetwork(List<ConnectivityResult> results) {
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    String label;
    IconData icon;
    Color color;

    switch (result) {
      case ConnectivityResult.wifi:
        label = "WiFi";
        icon = Icons.wifi_rounded;
        color = const Color(0xFF66BB6A);
        break;
      case ConnectivityResult.mobile:
        label = "Data Seluler (4G/5G)";
        icon = Icons.signal_cellular_alt_rounded;
        color = const Color(0xFF29B6F6);
        break;
      case ConnectivityResult.ethernet:
        label = "Ethernet";
        icon = Icons.settings_ethernet_rounded;
        color = const Color(0xFFAB47BC);
        break;
      case ConnectivityResult.none:
        label = "Tidak Ada Koneksi";
        icon = Icons.signal_wifi_off_rounded;
        color = Colors.redAccent;
        break;
      default:
        label = "Unknown";
        icon = Icons.help_outline_rounded;
        color = Colors.grey;
    }

    if (mounted) {
      setState(() {
        _networkLabel = label;
        _networkIcon = icon;
        _networkColor = color;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _batterySub?.cancel();
    _networkSub?.cancel();
    super.dispose();
  }

    @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ─── JAM ANALOG + WIB (di kanan atas) ─────────────────────────────
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFA726).withOpacity(0.55),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFA726).withOpacity(0.25),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: CustomPaint(
                    size: const Size(68, 68),
                    painter: _MantaAnalogClockPainter(
                      hour: _wibTime.hour,
                      minute: _wibTime.minute,
                      second: _wibTime.second,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFFA726).withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFA726),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFFA726),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      "WIB",
                      style: TextStyle(
                        color: Color(0xFFFFA726),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ─── STATUS BATERAI & JARINGAN (full width, baris terpisah) ────────
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                icon: _getBatteryIcon(),
                label: "BATERAI",
                value: "$_batteryLevel%",
                valueColor: _batteryLevel > 20
                    ? const Color(0xFF66BB6A)
                    : Colors.redAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatusCard(
                icon: _networkIcon,
                label: "JARINGAN",
                value: _networkLabel,
                valueColor: _networkColor,
              ),
            ),
          ],
        ),
      ],
    );
  }


  IconData _getBatteryIcon() {
    if (_batteryState == BatteryState.charging) {
      return Icons.battery_charging_full_rounded;
    }
    if (_batteryLevel >= 90) return Icons.battery_full_rounded;
    if (_batteryLevel >= 60) return Icons.battery_6_bar_rounded;
    if (_batteryLevel >= 40) return Icons.battery_4_bar_rounded;
    if (_batteryLevel >= 20) return Icons.battery_2_bar_rounded;
    return Icons.battery_alert_rounded;
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: valueColor, size: 13),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MantaAnalogClockPainter extends CustomPainter {
  final int hour;
  final int minute;
  final int second;

  _MantaAnalogClockPainter({
    required this.hour,
    required this.minute,
    required this.second,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1C2333),
          const Color(0xFF0D1117),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius - 1, bgPaint);

    final ringPaint = Paint()
      ..color = const Color(0xFFFFA726).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, radius - 4, ringPaint);

    final smallTick = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 1;
    final bigTick = Paint()
      ..color = const Color(0xFFFFA726).withOpacity(0.6)
      ..strokeWidth = 1.5;

    for (int i = 0; i < 60; i++) {
      final angle = i * 6 * (pi / 180);
      final isHour = i % 5 == 0;
      final innerR = isHour ? radius - 10 : radius - 6;
      final outerR = radius - 3;

      final start = Offset(
        center.dx + innerR * cos(angle - pi / 2),
        center.dy + innerR * sin(angle - pi / 2),
      );
      final end = Offset(
        center.dx + outerR * cos(angle - pi / 2),
        center.dy + outerR * sin(angle - pi / 2),
      );

      canvas.drawLine(start, end, isHour ? bigTick : smallTick);
    }

    final textStyle = TextStyle(
      color: Colors.white.withOpacity(0.55),
      fontSize: 9,
      fontWeight: FontWeight.w800,
    );
    for (int i in [3, 6, 9, 12]) {
      final angle = i * 30 * (pi / 180);
      final numR = radius - 17;
      final pos = Offset(
        center.dx + numR * cos(angle - pi / 2),
        center.dy + numR * sin(angle - pi / 2),
      );
      final span = TextSpan(text: '$i', style: textStyle);
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr, textAlign: TextAlign.center);
      tp.layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }

    final hourAngle = ((hour % 12) + minute / 60) * 30 * (pi / 180);
    _drawHand(canvas, center, hourAngle, radius * 0.42, 2.8, Colors.white.withOpacity(0.9));

    final minuteAngle = (minute + second / 60) * 6 * (pi / 180);
    _drawHand(canvas, center, minuteAngle, radius * 0.62, 2.0, Colors.white.withOpacity(0.85));

    final secondAngle = second * 6 * (pi / 180);
    final secondPaint = Paint()
      ..color = const Color(0xFFFFA726)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final secEnd = Offset(
      center.dx + radius * 0.72 * cos(secondAngle - pi / 2),
      center.dy + radius * 0.72 * sin(secondAngle - pi / 2),
    );
    final secTail = Offset(
      center.dx + radius * 0.12 * cos(secondAngle + pi / 2),
      center.dy + radius * 0.12 * sin(secondAngle + pi / 2),
    );
    canvas.drawLine(secTail, secEnd, secondPaint);

    final outerDot = Paint()
      ..color = const Color(0xFFFFA726)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, outerDot);

    final innerDot = Paint()
      ..color = const Color(0xFF0D1117)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 1.8, innerDot);
  }

  void _drawHand(Canvas canvas, Offset center, double angle, double length, double width, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    final end = Offset(
      center.dx + length * cos(angle - pi / 2),
      center.dy + length * sin(angle - pi / 2),
    );
    canvas.drawLine(center, end, paint);
  }

  @override
  bool shouldRepaint(covariant _MantaAnalogClockPainter oldDelegate) {
    return oldDelegate.hour != hour ||
        oldDelegate.minute != minute ||
        oldDelegate.second != second;
  }
}


// ─── PAINTERS ─────────────────────────────────────────────────────────────────
class _HexPainter extends CustomPainter {
  final Color color;
  const _HexPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i - pi / 6;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
    final paint2 = Paint()..color = color.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 0.8;
    final r2 = r * 0.6;
    final path2 = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i - pi / 6;
      final x = cx + r2 * cos(angle);
      final y = cy + r2 * sin(angle);
      if (i == 0) path2.moveTo(x, y);
      else path2.lineTo(x, y);
    }
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AestheticLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final tealPaint = Paint()..color = const Color(0xFF00B4D8).withOpacity(0.12)..strokeWidth = 0.8;
    final bluePaint = Paint()..color = const Color(0xFF4FC3F7).withOpacity(0.08)..strokeWidth = 0.5;
    for (double i = -size.width; i < size.width * 2; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), tealPaint);
    }
    for (double i = 0; i < size.width * 2; i += 120) {
      canvas.drawLine(Offset(i, 0), Offset(i - size.height, size.height), bluePaint);
    }
    final accentPaint = Paint()..color = const Color(0xFF00B4D8).withOpacity(0.2)..style = PaintingStyle.fill;
    final rng = Random(42);
    for (int i = 0; i < 15; i++) {
      double x = rng.nextDouble() * size.width;
      double y = rng.nextDouble() * size.height;
      double len = 30 + rng.nextDouble() * 50;
      canvas.drawLine(Offset(x, y), Offset(x + len, y), tealPaint..strokeWidth = 1.2);
      canvas.drawCircle(Offset(x + len, y), 2, accentPaint);
      if (rng.nextBool()) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 20), tealPaint..strokeWidth = 0.8);
      }
    }
    for (int i = 0; i < 5; i++) {
      double y = rng.nextDouble() * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), bluePaint..strokeWidth = 0.3);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..strokeWidth = 1.2..strokeCap = StrokeCap.round;
    const spacing = 8.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawPoints(PointMode.points, [Offset(x, y)], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── MODERN ACTION CARD ──────────────────────────────────────────────────────
class _ModernActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Gradient gradient;
  final VoidCallback onTap;
  final int index;

  const _ModernActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.gradient,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: [
        ScaleEffect(duration: 400.ms, curve: Curves.easeOutBack, delay: (100 * index).ms),
        FadeEffect(duration: 400.ms),
      ],
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.14), width: 1.2),
            boxShadow: [
              BoxShadow(color: gradient.colors.first.withOpacity(0.4), blurRadius: 20, spreadRadius: 2, offset: Offset(0, 8)),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20, right: -20,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.white.withOpacity(0.22), Colors.white.withOpacity(0.08)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.18)),
                          ),
                          child: Icon(icon, color: Colors.white, size: 28),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.18)),
                          ),
                          child: Text("Tap →", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                        SizedBox(height: 4),
                        Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.82), fontSize: 12.5, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white.withOpacity(0.1), Colors.transparent, Colors.black.withOpacity(0.05)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ─── MANTA DRAWER ────────────────────────────────────────────────────────────
class MantaDrawer extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final VoidCallback onNavigateToAdmin;
  final VoidCallback onProfileUpdated;

  const MantaDrawer({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
    required this.onNavigateToAdmin,
    required this.onProfileUpdated,
  });

  @override
  State<MantaDrawer> createState() => _MantaDrawerState();
}

class _MantaDrawerState extends State<MantaDrawer> {
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _profileImagePath = prefs.getString('profile_image_path'));
  }

  @override
  Widget build(BuildContext context) {
    final Color darkRed = Color(0xFF0D1117);
    final Color bloodRed = Color(0xFF00B4D8);
    final Color accentRed = bloodRed;
    final Color accentPurple = Color(0xFF4FC3F7);
    final Color accentPink = Colors.pinkAccent;
    final Color accentGold = Color(0xFFFFD700);

    return RepaintBoundary(
      child: Drawer(
        width: MediaQuery.of(context).size.width * 0.85,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                const Color(0xFF161B22).withOpacity(0.98),
                const Color(0xFF0D1117).withOpacity(0.99),
                const Color(0xFF111820).withOpacity(0.99),
              ],
            ),
            borderRadius: const BorderRadius.only(topRight: Radius.circular(40), bottomRight: Radius.circular(40)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 36, spreadRadius: 1, offset: const Offset(10, 0))],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topLeft,
                        radius: 1.5,
                        colors: [accentPurple.withOpacity(0.08), accentPink.withOpacity(0.05), accentRed.withOpacity(0.04), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(
                            username: widget.username,
                            password: widget.password,
                            sessionKey: widget.sessionKey,
                            expiredDate: widget.expiredDate,
                            role: widget.role,
                          ),
                        ),
                      );
                      _loadProfileImage();
                      widget.onProfileUpdated();
                    },
                    child: _buildDrawerHeader(context, darkRed, accentRed, accentGold, accentPink, accentPurple),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        if (widget.role == "KINGZ" || widget.role == "OWNER")
                          _DrawerMenuItem(
                            icon: Icons.admin_panel_settings,
                            title: 'Admin Page',
                            accentRed: accentRed,
                            darkRed: darkRed,
                            onTap: () { Navigator.pop(context); widget.onNavigateToAdmin(); },
                          ),
                        if (widget.role == "KINGZ")
                          _DrawerMenuItem(
                            icon: Icons.notifications_active,
                            title: 'Kirim Notifikasi',
                            accentRed: accentRed,
                            darkRed: darkRed,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SendNotificationPage(sessionKey: widget.sessionKey, username: widget.username),
                                ),
                              );
                            },
                          ),
                        _DrawerMenuItem(
                          icon: Iconsax.wallet_3,
                          title: 'TabunganKu',
                          accentRed: accentRed,
                          darkRed: darkRed,
                          onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const TabunganKuModule())); },
                        ),
                        _DrawerMenuItem(
                          icon: Icons.lock_reset,
                          title: 'Change Password',
                          accentRed: accentRed,
                          darkRed: darkRed,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChangePasswordPage(username: widget.username, sessionKey: widget.sessionKey),
                              ),
                            );
                          },
                        ),
                        _DrawerMenuItem(
                          icon: Icons.fingerprint,
                          title: 'NIK Check',
                          accentRed: accentRed,
                          darkRed: darkRed,
                          onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const NikCheckerPage())); },
                        ),
                        _DrawerMenuItem(
                          icon: Icons.system_update_alt,
                          title: 'Update App',
                          accentRed: accentRed,
                          darkRed: darkRed,
                          onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SizedBox.shrink())); },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('MANTA X © 2026', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, letterSpacing: 1)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(
    BuildContext context,
    Color darkRed,
    Color accentRed,
    Color accentGold,
    Color accentPink,
    Color accentPurple,
  ) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(topRight: Radius.circular(40)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1C2333).withOpacity(0.95),
            const Color(0xFF20384F).withOpacity(0.90),
            const Color(0xFF28516E).withOpacity(0.88),
            darkRed.withOpacity(0.98),
          ],
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.24), blurRadius: 24, spreadRadius: 1)],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60, left: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accentRed.withOpacity(0.18), accentPink.withOpacity(0.06), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            top: 20, right: -10,
            child: Opacity(opacity: 0.1, child: CustomPaint(size: const Size(140, 140), painter: _HexPainter(color: accentRed))),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [accentGold, accentPink, accentRed], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: accentPink.withOpacity(0.3), blurRadius: 30, spreadRadius: 2)],
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: darkRed),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: darkRed,
                    backgroundImage: _profileImagePath != null
                        ? (_profileImagePath!.startsWith('http')
                            ? NetworkImage(_profileImagePath!)
                            : FileImage(File(_profileImagePath!)) as ImageProvider)
                        : const AssetImage('assets/images/logo.jpg'),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.white, accentGold, accentPink],
                ).createShader(bounds),
                child: const Text(
                  'MANTA X',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4, color: Colors.white, shadows: [Shadow(offset: Offset(0, 4), blurRadius: 10, color: Colors.black54)]),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 60, height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: LinearGradient(
                    colors: [Colors.transparent, accentRed.withOpacity(0.8), Colors.transparent],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 20, left: 0, right: 0,
            child: Column(
              children: [
                Text(widget.username.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accentRed.withOpacity(0.3), width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: accentRed)),
                      const SizedBox(width: 10),
                      Text(widget.role.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('ACCESS UNTIL: ${widget.expiredDate}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentRed;
  final Color darkRed;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.accentRed,
    required this.darkRed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: accentRed.withOpacity(0.15),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [darkRed.withOpacity(0.4), accentRed.withOpacity(0.2)]),
                  ),
                  child: Icon(icon, color: accentRed, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(title, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 15, fontWeight: FontWeight.w500))),
                Icon(Icons.arrow_forward_ios, color: accentRed.withOpacity(0.5), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}