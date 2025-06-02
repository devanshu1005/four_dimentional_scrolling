import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount:
              controller.posts.length + 1, // Add one for loading indicator
          itemBuilder: (context, index) {
            if (index == controller.posts.length) {
              // Trigger lazy load
              controller.fetchPosts();
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            final post = controller.posts[index];
            return VideoReelItem(
              post: post,
              isCurrentPage:
                  true, // You can improve page tracking logic if needed
            );
          },
        );
      }),
    );
  }
}

class VideoReelItem extends StatefulWidget {
  final dynamic post; // Replace with your Post model
  final bool isCurrentPage;

  const VideoReelItem({
    super.key,
    required this.post,
    required this.isCurrentPage,
  });

  @override
  State<VideoReelItem> createState() => _VideoReelItemState();
}

class _VideoReelItemState extends State<VideoReelItem> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _showControls = false;   

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    // Replace with your actual video URL from the post
    // For demo purposes, using thumbnailUrl - replace with actual video URL
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.post.thumbnailUrl), // Replace with actual video URL
    );

    try {
      await _videoController.initialize();
      setState(() {
        _isVideoInitialized = true;
      });

      if (widget.isCurrentPage) {
        _videoController.play();
        _videoController.setLooping(true);
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  void didUpdateWidget(VideoReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentPage && _isVideoInitialized) {
      _videoController.play();
    } else if (!widget.isCurrentPage) {
      _videoController.pause();
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_videoController.value.isPlaying) {
        _videoController.pause();
      } else {
        _videoController.play();
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          // Video Player
          if (_isVideoInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: GestureDetector(
                  onTap: _toggleControls,
                  onDoubleTap: _togglePlayPause,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            // Loading or fallback image
            Container(
              width: double.infinity,
              height: double.infinity,
              child: Image.network(
                widget.post.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Icon(
                        Icons.video_library,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Play/Pause overlay
          if (_showControls && _isVideoInitialized)
            Center(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _videoController.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),

          // Right side actions (like Instagram)
          Positioned(
            right: 10,
            bottom: 100,
            child: Column(
              children: [
                // Profile Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(widget.post.pictureUrl),
                    onBackgroundImageError: (_, __) {},
                  ),
                ),
                const SizedBox(height: 20),

                // Like button
                _buildActionButton(
                  icon: Icons.favorite_border,
                  onTap: () {
                    // Handle like action
                  },
                ),
                const Text('120',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                const SizedBox(height: 20),

                // Comment button
                _buildActionButton(
                  icon: Icons.comment,
                  onTap: () {
                    // Handle comment action
                  },
                ),
                const Text('45',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                const SizedBox(height: 20),

                // Share button
                _buildActionButton(
                  icon: Icons.share,
                  onTap: () {
                    // Handle share action
                  },
                ),
                const SizedBox(height: 20),

                // More options
                _buildActionButton(
                  icon: Icons.more_vert,
                  onTap: () {
                    // Handle more options
                  },
                ),
              ],
            ),
          ),

          // Bottom info section
          Positioned(
            left: 10,
            bottom: 100,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.post.firstName} ${widget.post.lastName}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.post.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Video progress indicator (optional)
          if (_isVideoInitialized && _showControls)
            Positioned(
              bottom: 50,
              left: 10,
              right: 10,
              child: VideoProgressIndicator(
                _videoController,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Colors.grey,
                  backgroundColor: Colors.black26,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 25,
        ),
      ),
    );
  }
}
