import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const VastuAIApp());
}

// ─── DATA MODELS ─────────────────────────────────────────────────────────────

class VastuSuggestion {
  final String type; // 'good', 'defect', 'neutral', 'average'
  final String title;
  final String impact;
  final String remedy;
  final String detail;

  const VastuSuggestion({
    required this.type,
    required this.title,
    required this.impact,
    required this.remedy,
    required this.detail,
  });
}

class VastuResult {
  final int score;
  final String explanation;
  final List<VastuSuggestion> suggestions;

  const VastuResult({
    required this.score,
    required this.explanation,
    required this.suggestions,
  });
}

// ─── DUMMY VASTU DATA ENGINE ─────────────────────────────────────────────────

class VastuEngine {
  static final List<Map<String, dynamic>> _dummyLayouts = [
    {
      'entrance': 'south-west',
      'kitchen': 'north-east',
      'master_bedroom': 'south-east',
      'toilet': 'north-east',
      'living_room': 'north',
    },
    {
      'entrance': 'north',
      'kitchen': 'south-east',
      'master_bedroom': 'south-west',
      'toilet': 'north-west',
      'living_room': 'east',
    },
    {
      'entrance': 'east',
      'kitchen': 'north-west',
      'master_bedroom': 'south-west',
      'toilet': 'south-west',
      'living_room': 'north-east',
    },
  ];

  static final Map<String, Map<String, VastuSuggestion>> _kb = {
    'kitchen': {
      'north-east': const VastuSuggestion(
        type: 'defect',
        title: 'Kitchen in North-East (Eshan Corner)',
        impact: 'Clash of Fire & Water elements. Severe financial losses, health issues, and family disputes.',
        remedy: 'Avoid use if possible. Paint walls yellow. Install a Jupiter Yantra.',
        detail: 'The North-East is the Water zone — source of divine energy. Fire (kitchen) here destroys this, draining wealth and causing brain-related ailments over time.',
      ),
      'south-east': const VastuSuggestion(
        type: 'good',
        title: 'Kitchen in South-East (Agni Corner)',
        impact: 'Excellent! Enhances health, cash flow, and family harmony.',
        remedy: 'Cook facing East for maximum benefits.',
        detail: 'Agni (Fire) zone perfectly aligns with the kitchen\'s fire element, boosting vitality and prosperity for all residents.',
      ),
      'north-west': const VastuSuggestion(
        type: 'good',
        title: 'Kitchen in North-West (Vayu Corner)',
        impact: 'Good alternative. Promotes social connections and movement.',
        remedy: 'Ensure proper ventilation always.',
        detail: 'North-West (Air) gives movement to fire, making cooking energetically balanced. May slightly increase household expenses.',
      ),
      'south-west': const VastuSuggestion(
        type: 'defect',
        title: 'Kitchen in South-West (Nairuthi)',
        impact: 'Disrupts stability. Causes anxiety, financial instability, digestive issues.',
        remedy: 'Paint walls yellow. Place a yellow stone under the stove.',
        detail: 'SW is the Earth zone. Fire here burns stability — leading to relationship conflicts and inability to save money.',
      ),
      'north': const VastuSuggestion(
        type: 'defect',
        title: 'Kitchen in North (Kuber Sthan)',
        impact: 'Burns wealth opportunities. Career stagnation.',
        remedy: 'Place a green plant. Shift stove to South-East.',
        detail: 'North is ruled by Kuber, lord of wealth. Kitchen (Fire) here evaporates wealth and opportunities.',
      ),
      'south': const VastuSuggestion(
        type: 'defect',
        title: 'Kitchen in South (Yama)',
        impact: 'Causes mental stress and short temper.',
        remedy: 'Paint walls pale red or orange.',
        detail: 'South is the zone of Relaxation. Fire here disrupts peace of mind, leading to stress and anger.',
      ),
      'east': const VastuSuggestion(
        type: 'defect',
        title: 'Kitchen in East (Surya)',
        impact: 'Minor defect. Mild health issues for women.',
        remedy: 'Place a green marble under the stove.',
        detail: 'East rules social connections. Kitchen can occasionally affect the health of the lady of the house.',
      ),
      'west': const VastuSuggestion(
        type: 'average',
        title: 'Kitchen in West (Varuna)',
        impact: 'Average. Good for food business. May cause skin issues.',
        remedy: 'Cook facing East or West. Use white/yellow aesthetics.',
        detail: 'West is the Gains zone. Great for chefs but can lead to skin allergies for family members.',
      ),
    },
    'master_bedroom': {
      'south-west': const VastuSuggestion(
        type: 'good',
        title: 'Master Bedroom in South-West (Best)',
        impact: 'Best position. Brings stability, leadership, authority, and health.',
        remedy: 'Sleep with head towards South. Use earthy tones.',
        detail: 'The Earth zone (SW) grounds the head of family — providing mental peace and decision-making power.',
      ),
      'north-east': const VastuSuggestion(
        type: 'defect',
        title: 'Master Bedroom in North-East',
        impact: 'Not ideal for couples. Restlessness, poor health, and conception issues.',
        remedy: 'Shift this room. Use it for meditation/prayer only.',
        detail: 'NE is the Divine water zone. Sleeping here causes an overactive mind and prevents deep rest.',
      ),
      'south-east': const VastuSuggestion(
        type: 'defect',
        title: 'Master Bedroom in South-East (Agni)',
        impact: 'Fire zone. Causes aggression, sleep disorders, marital conflicts.',
        remedy: 'Use cooling colors (Blue, Green). Avoid Red.',
        detail: 'Sleeping in the Fire zone increases body heat and aggression, leading to quarrels and hypertension.',
      ),
      'north-west': const VastuSuggestion(
        type: 'average',
        title: 'Master Bedroom in North-West (Vayu)',
        impact: 'Instability and frequent travel. Better suited for guests.',
        remedy: 'Use white or cream colors.',
        detail: 'Air zone makes occupants restless. Best for guest rooms or daughters awaiting marriage.',
      ),
      'west': const VastuSuggestion(
        type: 'good',
        title: 'Master Bedroom in West',
        impact: 'Good for financial gains and profits.',
        remedy: 'Sleep with head towards South or East.',
        detail: 'West (Gains zone) ensures efforts translate to tangible profits and financial security.',
      ),
      'north': const VastuSuggestion(
        type: 'defect',
        title: 'Master Bedroom in North',
        impact: 'Lacks stability. Good for youth, bad for family head.',
        remedy: 'Better for children\'s room or study.',
        detail: 'North lacks the Earth element stability required by the family head for authoritative living.',
      ),
    },
    'toilet': {
      'north-east': const VastuSuggestion(
        type: 'defect',
        title: 'Toilet in North-East ⚠️ Critical',
        impact: 'Most critical defect. Blocks all positive energy. Ruins health and finances.',
        remedy: 'Shift immediately. Use sea salt in corners. Hang Swastik.',
        detail: 'NE is Vastu Purusha\'s head. A toilet here applies filth to the brain — causing severe mental issues and chronic diseases.',
      ),
      'south-west': const VastuSuggestion(
        type: 'defect',
        title: 'Toilet in South-West',
        impact: 'Drains stability and savings. Causes kidney/leg problems.',
        remedy: 'Keep door always closed. Yellow tape around seat.',
        detail: 'SW stores wealth and stability — a toilet here flushes it all out, causing career instability.',
      ),
      'north-west': const VastuSuggestion(
        type: 'good',
        title: 'Toilet in North-West (Best)',
        impact: 'Ideal placement. Effectively releases negativity.',
        remedy: 'Ensure proper ventilation and cleanliness.',
        detail: 'Air zone naturally facilitates elimination, helping release physical toxins and mental negativity.',
      ),
      'west': const VastuSuggestion(
        type: 'good',
        title: 'Toilet in West',
        impact: 'Acceptable placement. Generally neutral effects.',
        remedy: 'Ensure proper exhaust fan.',
        detail: 'West is generally acceptable for toilet when North-West is unavailable.',
      ),
      'north': const VastuSuggestion(
        type: 'defect',
        title: 'Toilet in North (Kuber)',
        impact: 'Blocks career growth and money inflow.',
        remedy: 'Use blue tape. Keep extremely clean.',
        detail: 'North represents opportunities — a toilet here flushes away promotions and business deals.',
      ),
      'south-east': const VastuSuggestion(
        type: 'defect',
        title: 'Toilet in South-East (Agni)',
        impact: 'Fire/Water clash. Legal troubles and women\'s health issues.',
        remedy: 'Copper strips or red bulbs as correction.',
        detail: 'SE is the Fire direction — toilet extinguishes this fire causing digestion and legal hassles.',
      ),
    },
    'entrance': {
      'north': const VastuSuggestion(
        type: 'good',
        title: 'Entrance in North (Kuber Sthan)',
        impact: 'Excellent! Invites wealth and career opportunities.',
        remedy: 'Keep clutter-free. Place Kuber Yantra.',
        detail: 'North ruled by Kuber (Lord of wealth) — entry here attracts abundant financial growth.',
      ),
      'east': const VastuSuggestion(
        type: 'good',
        title: 'Entrance in East (Surya)',
        impact: 'Excellent! Brings fame, health, and social connections.',
        remedy: 'Keep well-lit. Decorate with plants.',
        detail: 'East is the rising sun direction — new beginnings, fame, and social success enter with every sunrise.',
      ),
      'south-west': const VastuSuggestion(
        type: 'defect',
        title: 'Entrance in South-West ⚠️',
        impact: 'Gateway of struggles and debt. Negative energy enters.',
        remedy: 'Install Lead (Seesa) Pyramid. Use heavy door.',
        detail: 'SW entry creates an energy leak — positivity leaves and negativity enters, bringing debts and failures.',
      ),
      'south-east': const VastuSuggestion(
        type: 'defect',
        title: 'Entrance in South-East',
        impact: 'Increases anxiety, fire accidents, and short temper.',
        remedy: 'Paint door Red. Add Copper Swastik above door.',
        detail: 'SE fire energy floods in through this entrance creating anger, arguments, and theft risks.',
      ),
      'north-west': const VastuSuggestion(
        type: 'average',
        title: 'Entrance in North-West',
        impact: 'Variable results. Helpful people but frequent absence from home.',
        remedy: 'Use white colors. Keep threshold clean.',
        detail: 'NW support zone brings helpful allies but can make residents travel frequently or feel restless.',
      ),
      'west': const VastuSuggestion(
        type: 'good',
        title: 'Entrance in West',
        impact: 'Good for business profits and gains.',
        remedy: 'Keep metal elements near door.',
        detail: 'West (Varuna / Profits zone) ensures financial returns from business ventures.',
      ),
    },
  };

  static VastuSuggestion _getOrNeutral(String room, String dir) {
    final neutral = VastuSuggestion(
      type: 'neutral',
      title: '${_capitalize(room.replaceAll('_', ' '))} in ${_capitalize(dir)}',
      impact: 'Placement has mixed or neutral effects.',
      remedy: 'Consult a Vastu expert for detailed corrections.',
      detail: 'This zone has no specific strong positive or negative influence based on Vastu Shastra.',
    );
    return _kb[room]?[dir] ?? neutral;
  }

  static String _capitalize(String s) =>
      s.split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

  static VastuResult analyze(Map<String, String> roomData) {
    int score = 50;
    final List<VastuSuggestion> suggestions = [];

    const weights = {
      'good': 15,
      'average': 5,
      'neutral': 0,
      'defect': -18,
    };

    for (final entry in roomData.entries) {
      final room = entry.key.toLowerCase().trim();
      final dir = entry.value.toLowerCase().trim();
      final s = _getOrNeutral(room, dir);
      suggestions.add(s);
      score += weights[s.type] ?? 0;
    }

    score = score.clamp(0, 100);

    String explanation;
    if (score > 80) {
      explanation = 'Excellent Vastu Compliance! Your space has very high positive vibrations and energy flow.';
    } else if (score > 60) {
      explanation = 'Good Vastu Compliance. Minor corrections with simple remedies will enhance your well-being.';
    } else if (score > 40) {
      explanation = 'Moderate Vastu Compliance. Several corrections recommended to improve energy balance.';
    } else {
      explanation = 'Critical Vastu Corrections Needed. Energy flow is severely blocked. Immediate remedies required.';
    }

    return VastuResult(score: score, explanation: explanation, suggestions: suggestions);
  }

  static VastuResult generateDummyResult() {
    final random = Random();
    final layout = _dummyLayouts[random.nextInt(_dummyLayouts.length)];
    return analyze(Map<String, String>.from(layout));
  }
}

// ─── APP ─────────────────────────────────────────────────────────────────────

class VastuAIApp extends StatelessWidget {
  const VastuAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VastuAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF59E0B),
          secondary: Color(0xFFFF8C00),
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: const HomePage(),
    );
  }
}

// ─── HOME PAGE ────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  Uint8List? _selectedImage;
  bool _isAnalyzing = false;
  VastuResult? _result;
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImage = bytes;
        _result = null;
      });
    }
  }

  Future<void> _analyze() async {
    if (_selectedImage == null) return;
    setState(() => _isAnalyzing = true);

    // Simulate AI processing delay
    await Future.delayed(const Duration(milliseconds: 2500));

    final result = VastuEngine.generateDummyResult();

    setState(() {
      _isAnalyzing = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // Background gradient orbs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFF59E0B).withOpacity(0.15),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFFF4500).withOpacity(0.1),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildUploadSection(),
                        const SizedBox(height: 20),
                        if (_result != null) ...[
                          _buildResultsSection(),
                          const SizedBox(height: 40),
                        ],
                        const SizedBox(height: 20),
                      ],
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

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFF0A0A0F).withOpacity(0.9),
      floating: true,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFFF6B35)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.explore, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
              children: [
                const TextSpan(text: 'Vastu', style: TextStyle(color: Colors.white)),
                TextSpan(
                  text: 'AI',
                  style: TextStyle(color: const Color(0xFFF59E0B)),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'EN',
            style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFFF6B35)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(
                      0.3 + 0.2 * _pulseController.value),
                  blurRadius: 30 + 20 * _pulseController.value,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'VASTU SHASTRA\nAI ANALYZER',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            height: 1.1,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFFFD700), Color(0xFFFF8C00)],
              ).createShader(const Rect.fromLTWH(0, 0, 300, 50)),
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3),
        const SizedBox(height: 12),
        Text(
          'Upload your floor plan and get instant\nVastu insights powered by AI vision',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 15,
            color: Colors.white54,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
      ],
    );
  }

  Widget _buildUploadSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          // Image area
          GestureDetector(
            onTap: _isAnalyzing ? null : _pickImage,
            child: Container(
              height: 220,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedImage != null
                      ? const Color(0xFFF59E0B).withOpacity(0.4)
                      : Colors.white.withOpacity(0.08),
                  width: 1.5,
                ),
                color: Colors.white.withOpacity(0.02),
              ),
              child: _isAnalyzing
                  ? _buildScanningAnimation()
                  : _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : _buildUploadPlaceholder(),
            ),
          ),
          // Analyze button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GestureDetector(
              onTap: (_selectedImage == null || _isAnalyzing) ? null : _analyze,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  gradient: (_selectedImage != null && !_isAnalyzing)
                      ? const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFFF8C00), Color(0xFFFF6B35)],
                        )
                      : null,
                  color: (_selectedImage == null || _isAnalyzing)
                      ? Colors.white.withOpacity(0.05)
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: (_selectedImage != null && !_isAnalyzing)
                      ? [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: _isAnalyzing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'ANALYZING GEOMETRY...',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _selectedImage == null
                                  ? 'SELECT FLOOR PLAN FIRST'
                                  : 'START AI ANALYSIS',
                              style: GoogleFonts.outfit(
                                color: _selectedImage == null
                                    ? Colors.white30
                                    : Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            if (_selectedImage != null) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.auto_awesome,
                                  color: Colors.white, size: 18),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 700.ms).slideY(begin: 0.2);
  }

  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.2 + 0.1 * _pulseController.value),
              ),
            ),
            child: Icon(
              Icons.cloud_upload_outlined,
              color: const Color(0xFFF59E0B).withOpacity(0.8),
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Drop your blueprint here',
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Supports JPG, PNG • Max 10MB',
          style: GoogleFonts.outfit(
            color: Colors.white30,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildScanningAnimation() {
    return Stack(
      children: [
        if (_selectedImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              _selectedImage!,
              fit: BoxFit.cover,
              width: double.infinity,
              color: Colors.black.withOpacity(0.6),
              colorBlendMode: BlendMode.darken,
            ),
          ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _rotateController,
                builder: (_, child) => Transform.rotate(
                  angle: _rotateController.value * 2 * pi,
                  child: child,
                ),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF59E0B),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.radar, color: Color(0xFFF59E0B), size: 28),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'AI ANALYZING FLOOR PLAN...',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFF59E0B),
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ).animate().fadeIn().then().fadeOut(
                    duration: 800.ms,
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSection() {
    final result = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score card
        _buildScoreCard(result),
        const SizedBox(height: 16),
        // Explanation card
        _buildExplanationCard(result),
        const SizedBox(height: 20),
        // Section title
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.checklist_rounded, color: Color(0xFF60A5FA), size: 20),
              const SizedBox(width: 8),
              Text(
                'Actionable Vastu Insights',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        // Suggestion cards
        ...result.suggestions.asMap().entries.map(
              (e) => _buildSuggestionCard(e.value, e.key),
            ),
        const SizedBox(height: 20),
        // Disclaimer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white30, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Demo Mode: Results based on simulated floor plan data. Connect to live AI for real analysis.',
                  style: GoogleFonts.outfit(
                    color: Colors.white30,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Done by footer
        Center(
          child: Text(
            'Done by: Sukhee Sakthivel GM  ·  VastuAI',
            style: GoogleFonts.outfit(
              color: const Color(0xFFF59E0B).withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
  }

  Widget _buildScoreCard(VastuResult result) {
    final score = result.score;
    final color = score > 80
        ? const Color(0xFF10B981)
        : score > 60
            ? const Color(0xFFF59E0B)
            : score > 40
                ? const Color(0xFFFF8C00)
                : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Text(
            'VASTU COMPLIANCE SCORE',
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          CircularPercentIndicator(
            radius: 80,
            lineWidth: 12,
            animation: true,
            animationDuration: 1500,
            percent: score / 100,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score',
                  style: GoogleFonts.outfit(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1,
                  ),
                ),
                Text(
                  '/100',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.white30,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            progressColor: color,
            backgroundColor: Colors.white.withOpacity(0.08),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              score > 80
                  ? '✨ Excellent Vastu'
                  : score > 60
                      ? '✅ Good Compliance'
                      : score > 40
                          ? '⚠️ Needs Correction'
                          : '🚨 Critical Issues',
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(VastuResult result) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF59E0B).withOpacity(0.08),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Color(0xFFF59E0B), width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote, color: Color(0xFFF59E0B), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              result.explanation,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 15,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(VastuSuggestion s, int index) {
    final isGood = s.type == 'good';
    final isDefect = s.type == 'defect';
    final isAverage = s.type == 'average';

    final bgColor = isGood
        ? const Color(0xFF10B981).withOpacity(0.05)
        : isDefect
            ? const Color(0xFFEF4444).withOpacity(0.05)
            : isAverage
                ? const Color(0xFFF59E0B).withOpacity(0.05)
                : Colors.white.withOpacity(0.03);

    final borderColor = isGood
        ? const Color(0xFF10B981).withOpacity(0.2)
        : isDefect
            ? const Color(0xFFEF4444).withOpacity(0.2)
            : isAverage
                ? const Color(0xFFF59E0B).withOpacity(0.2)
                : Colors.white.withOpacity(0.06);

    final emoji = isDefect ? '❌' : isGood ? '✅' : isAverage ? '⚠️' : '📌';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.title,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('Impact', s.impact, const Color(0xFFEF4444)),
          const SizedBox(height: 8),
          _infoRow('Remedy', s.remedy, const Color(0xFF10B981), hasBg: true),
          const SizedBox(height: 8),
          _infoRow('Detail', s.detail, const Color(0xFF60A5FA), hasBg: true),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 500.ms)
        .slideX(begin: 0.05);
  }

  Widget _infoRow(String label, String value, Color color, {bool hasBg = false}) {
    return Container(
      padding: hasBg ? const EdgeInsets.all(10) : EdgeInsets.zero,
      decoration: hasBg
          ? BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.12)),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.75),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
