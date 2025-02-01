import 'package:flutter/material.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Game Decider Coin Flip',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const CoinFlipGame(),
    );
  }
}

class CoinFlipGame extends StatefulWidget {
  const CoinFlipGame({super.key});

  @override
  _CoinFlipGameState createState() => _CoinFlipGameState();
}

class _CoinFlipGameState extends State<CoinFlipGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isHeads = true;
  bool _isFlipping = false;
  String _result = '';
  final Random _random = Random();
  late AudioPlayer _audioPlayer;
  late ConfettiController _confettiController;
  late BannerAd _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: 3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Ad failed to load: $error');
        },
      ),
    );
    _bannerAd.load();
  }

  void _flipCoin() async {
    if (_isFlipping) return;
    setState(() {
      _isFlipping = true;
      _result = '';
    });

    await _audioPlayer.play(AssetSource('flip_sound.mp3'));
    await _controller.forward(from: 0);

    final result = _random.nextBool();
    setState(() {
      _isHeads = result;
      _result = result ? 'Heads!' : 'Tails!';
      _isFlipping = false;
      _confettiController.play();
      _audioPlayer.play(AssetSource('success_sound.mp3'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Decider Coin Flip'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Center(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.deepPurpleAccent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment(-0.9, -0.8),
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi * 2,
                numberOfParticles: 50,
                gravity: 0.2,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..rotateX(_animation.value * pi),
                      alignment: Alignment.center,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color:
                              _isHeads ? Colors.orangeAccent : Colors.blueGrey,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 15,
                              spreadRadius: 3,
                              offset: Offset(0, 8),
                            )
                          ],
                        ),
                        child: Icon(
                          _isHeads ? Icons.circle : Icons.cancel,
                          size: 90,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                Text(
                  _result,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black26,
                        offset: Offset(3.0, 3.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _flipCoin,
                  child: const Text(
                    'Flip Coin to Decide!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_isAdLoaded)
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(top: 20),
                    height: _bannerAd.size.height.toDouble(),
                    width: double.infinity,
                    child: AdWidget(ad: _bannerAd),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    _confettiController.dispose();
    _bannerAd.dispose();
    super.dispose();
  }
}
