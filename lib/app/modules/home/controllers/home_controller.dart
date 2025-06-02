import 'package:four_dimentional_scrolling/app/model/feed_model.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeController extends GetxController {
  var posts = <Post>[].obs;
  var isLoading = true.obs;
  var currentPage = 1;
  var isMoreLoading = false.obs;
  var hasMore = true.obs;

  @override
  void onInit() {
    fetchPosts(); // load first page
    super.onInit();
  }

  void fetchPosts({bool isInitial = false}) async {
    if (!isInitial && (isMoreLoading.value || !hasMore.value)) return;

    try {
      if (isInitial) {
        isLoading(true);
      } else {
        isMoreLoading(true);
      }

      final response = await http.get(Uri.parse("https://api.wemotions.app/feed?page=$currentPage"));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        FeedModel feed = FeedModel.fromJson(jsonData);

        if (feed.posts.isEmpty) {
          hasMore(false); // No more data
        } else {
          posts.addAll(feed.posts); // Append new posts
          currentPage++;
        }
      } else {
        Get.snackbar('Error', 'Failed to load posts');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading(false);
      isMoreLoading(false);
    }
  }
}

