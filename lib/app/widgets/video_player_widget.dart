// widgets/video_player_widget.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'dart:async';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String thumbnailUrl;
  final bool autoPlay;
  final bool showControls;
  final BorderRadius? borderRadius;

  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    required this.thumbnailUrl,
    this.autoPlay = false,
    this.showControls = true,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _playPauseController;
  late AnimationController _overlayController;
  late AnimationController _progressController;
  late AnimationController _loadingController;
  late Animation<double> _playPauseAnimation;
  late Animation<double> _overlayAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _loadingAnimation;

  bool _isInitialized = false;
  bool _showControls = false;
  bool _isBuffering = false;
  Timer? _hideControlsTimer;
  Timer? _progressTimer;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVideo();
  }

  void _initializeAnimations() {
    _playPauseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _playPauseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _playPauseController, curve: Curves.elasticOut),
    );

    _overlayAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _overlayController, curve: Curves.easeOutCubic),
    );

    _progressAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.linear),
    );

    _loadingController.repeat();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.network(widget.videoUrl);

    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _isBuffering = _controller.value.isBuffering;
        });

        if (_controller.value.isInitialized && !_isInitialized) {
          setState(() {
            _isInitialized = true;
          });

          if (widget.autoPlay) {
            _controller.play();
            _playPauseController.forward();
          }
        }
      }
    });

    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _startProgressTimer();
      }
    });
  }

  void _startProgressTimer() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_controller.value.isInitialized && mounted) {
        final position = _controller.value.position;
        final duration = _controller.value.duration;

        if (duration.inMilliseconds > 0) {
          setState(() {
            _currentProgress =
                position.inMilliseconds / duration.inMilliseconds;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _playPauseController.dispose();
    _overlayController.dispose();
    _progressController.dispose();
    _loadingController.dispose();
    _hideControlsTimer?.cancel();
    _progressTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (!_isInitialized) return;

    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _playPauseController.reverse();
      } else {
        _controller.play();
        _playPauseController.forward();
      }
    });

    _showControlsTemporarily();
  }

  void _showControlsTemporarily() {
    if (!widget.showControls) return;

    setState(() {
      _showControls = true;
    });

    _overlayController.forward();
    _progressController.forward();

    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
        _overlayController.reverse();
        _progressController.reverse();
      }
    });
  }

  // void _onTap() {
  //   if (widget.showControls) {
  //     if (_showControls) {
  //       _togglePlayback();
  //     } else {
  //       _showControlsTemporarily();
  //     }
  //   } else {
  //     _togglePlayback();
  //   }
  // }

  void _onTap() {
    _togglePlayback();
  }

  Widget _buildPlayPauseButton() {
    return AnimatedBuilder(
      animation: _playPauseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale:
              0.8 + (_playPauseAnimation.value * 0.2), 
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _controller.value.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 18, 
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _loadingAnimation,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                value: null,
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    if (!_isInitialized || !widget.showControls) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _progressAnimation.value,
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _currentProgress,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoTime() {
    if (!_isInitialized || !widget.showControls) return const SizedBox.shrink();

    final position = _controller.value.position;
    final duration = _controller.value.duration;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '${_formatDuration(position)} / ${_formatDuration(duration)}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildThumbnail() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.network(
              widget.thumbnailUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.black87,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        child: Stack(
          children: [
            if (_controller.value.isInitialized)
              Center(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
            if (widget.showControls)
              AnimatedBuilder(
                animation: _overlayAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _showControls ? _overlayAnimation.value : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.0,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          const Spacer(),
                          _buildProgressBar(),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildVideoTime(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                },
              ),
            if (_showControls || !_controller.value.isPlaying)
              Center(
                child: _isBuffering
                    ? _buildLoadingIndicator()
                    : _buildPlayPauseButton(),
              ),
            if (!_isInitialized)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: _buildLoadingIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = GestureDetector(
      onTap: _onTap,
      child: _isInitialized ? _buildVideoPlayer() : _buildThumbnail(),
    );

    return widget.autoPlay
        ? VisibilityDetector(
            key: Key(widget.videoUrl),
            onVisibilityChanged: (info) {
              if (!_isInitialized) return;

              if (info.visibleFraction > 0.5) {
                if (!_controller.value.isPlaying) {
                  _controller.play();
                  _playPauseController.forward();
                }
              } else {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                  _playPauseController.reverse();
                }
              }
            },
            child: player,
          )
        : player;
  }
}
