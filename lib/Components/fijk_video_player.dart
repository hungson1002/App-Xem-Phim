import 'package:flutter/material.dart';
import 'package:fijkplayer/fijkplayer.dart';

class FijkVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isPlaying;
  final double currentTime;
  final Function(bool) onPlayPause;
  final Function(double) onSeek;

  const FijkVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.isPlaying,
    required this.currentTime,
    required this.onPlayPause,
    required this.onSeek,
  });

  @override
  State<FijkVideoPlayer> createState() => _FijkVideoPlayerState();
}

class _FijkVideoPlayerState extends State<FijkVideoPlayer> {
  final FijkPlayer _player = FijkPlayer();
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      print('🎬 Initializing Fijk Player with URL: ${widget.videoUrl}');

      // Kiểm tra URL format
      if (!widget.videoUrl.startsWith('http')) {
        setState(() {
          _hasError = true;
          _errorMessage = 'URL không hợp lệ: ${widget.videoUrl}';
        });
        return;
      }

      // ✅ FLOW KHỞI TẠO CHUẨN (COPY Y NGUYÊN)

      // 1. TẮT HARDWARE DECODER (RẤT QUAN TRỌNG)
      _player.setOption(FijkOption.playerCategory, "mediacodec", 0);
      _player.setOption(FijkOption.playerCategory, "mediacodec-auto-rotate", 0);
      _player.setOption(FijkOption.playerCategory, "opensles", 0);

      // 2. SET NETWORK TIMEOUT
      _player.setOption(FijkOption.formatCategory, "timeout", 30000000);
      _player.setOption(FijkOption.formatCategory, "reconnect", 1);

      // 3. SET HEADERS VỚI setOption (ĐÚNG CÁCH CHO FIJK)
      _player.setOption(
        FijkOption.formatCategory,
        "user_agent",
        "Mozilla/5.0 (Linux; Android 13; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36",
      );

      // Thêm referer dựa trên URL
      if (widget.videoUrl.contains('phimmoichillz')) {
        _player.setOption(
          FijkOption.formatCategory,
          "referer",
          "https://phimmoichillz.net/",
        );
      } else if (widget.videoUrl.contains('kkphim')) {
        _player.setOption(
          FijkOption.formatCategory,
          "referer",
          "https://kkphim.vip/",
        );
      } else {
        _player.setOption(
          FijkOption.formatCategory,
          "referer",
          "https://phimapi.com/",
        );
      }

      // 4. BUFFERING OPTIONS
      _player.setOption(
        FijkOption.playerCategory,
        "max_cached_duration",
        30000,
      );
      _player.setOption(FijkOption.playerCategory, "infbuf", 1);
      _player.setOption(FijkOption.playerCategory, "packet-buffering", 0);

      print('🌐 All options set, preparing player...');

      // Listen to player state changes
      _player.addListener(() {
        final value = _player.value;
        print('🎬 Player state: ${value.state}');

        if (value.state == FijkState.prepared && !_isInitialized) {
          setState(() {
            _isInitialized = true;
            _hasError = false;
          });
          print('✅ Fijk Player initialized successfully');
        } else if (value.state == FijkState.error) {
          setState(() {
            _hasError = true;
            _errorMessage =
                'Lỗi phát video: ${value.exception?.message ?? 'Unknown error'}';
          });
          print('❌ Fijk Player error: ${value.exception}');
        }
      });

      // 5. SET DATA SOURCE (KHÔNG CẦN HEADERS PARAMETER)
      await _player.setDataSource(widget.videoUrl, autoPlay: false);

      // 6. PREPARE ASYNC
      await _player.prepareAsync();
    } catch (e) {
      print('❌ Fijk Player initialization error: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Không thể khởi tạo video player: $e';
      });
    }
  }

  @override
  void dispose() {
    _player.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Không thể phát video',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isInitialized = false;
                  });
                  _initializePlayer();
                },
                child: const Text('Thử lại'),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'URL: ${widget.videoUrl}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Đang khởi tạo Fijk Player...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Đang load stream với headers...',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: FijkView(
          player: _player,
          panelBuilder: fijkPanel2Builder(fill: true, snapShot: true),
        ),
      ),
    );
  }
}
