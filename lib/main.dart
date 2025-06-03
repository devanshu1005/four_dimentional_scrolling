import 'package:flutter/material.dart';
import 'package:four_dimentional_scrolling/app/model/video_model.dart';
import 'package:four_dimentional_scrolling/app/services/api_service.dart';
import 'package:four_dimentional_scrolling/app/widgets/reply_list_widget.dart';
import 'package:four_dimentional_scrolling/app/widgets/video_player_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FeedPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final PageController _pageController = PageController();
  final List<VideoModel> _videos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialVideos();
    _pageController.addListener(_onScroll);
  }

  Future<void> _loadInitialVideos() async {
    setState(() => _isLoading = true);
    final videos = await ApiService.fetchMainVideos(reset: true);
    setState(() {
      _videos.addAll(videos);
      _isLoading = false;
    });
  }

  Future<void> _loadMoreVideos() async {
    if (_isLoading || !ApiService.hasMore) return;

    setState(() => _isLoading = true);
    final videos = await ApiService.fetchMainVideos();
    setState(() {
      _videos.addAll(videos);
      _isLoading = false;
    });
  }

  void _onScroll() {
    final nextPageTrigger = _pageController.position.maxScrollExtent * 0.8;

    if (_pageController.position.pixels >= nextPageTrigger && !_isLoading) {
      _loadMoreVideos();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _videos.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _videos.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _videos.length) {
                  return const Center(child: CircularProgressIndicator());
                }

                final video = _videos[index];
                return Column(
                  children: [
                    Expanded(
                      child: VideoPlayerWidget(
                        videoUrl: video.videoUrl,
                        thumbnailUrl: video.thumbnailUrl,
                        autoPlay: true, 
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        video.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ReplyListWidget(parentId: video.id),
                  ],
                );
              },
            ),
    );
  }
}
