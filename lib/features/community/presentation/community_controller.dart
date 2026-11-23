import 'package:flutter/material.dart';

import 'package:kawangizi_mobile/core/storage/local_store.dart';
import 'package:kawangizi_mobile/features/auth/domain/backend_user.dart';
import '../../domain/community_models.dart';
import '../data/forum_repository.dart';

class CommunityController extends ChangeNotifier {
  CommunityController({
    required ForumRepository forumRepository,
    required LocalStore localStore,
  })  : _forumRepository = forumRepository,
        _localStore = localStore {
    _loadInitial();
  }

  final ForumRepository _forumRepository;
  final LocalStore _localStore;

  List<CommunityPost> _posts = [];
  CommunityPost? _activeThreadPost;
  bool _loading = true;

  List<CommunityPost> get posts => List.unmodifiable(_posts);
  CommunityPost? get activeThreadPost => _activeThreadPost;
  bool get loading => _loading;

  void _loadInitial() async {
    _loading = true;
    notifyListeners();
    try {
      _posts = await _forumRepository.getPosts();
    } catch (_) {
      _posts = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setActiveThreadPost(CommunityPost? post) {
    _activeThreadPost = post;
    notifyListeners();
  }

  Future<CommunityPost> createPost({
    required String title,
    required String content,
    required String tag,
    String? mediaUri,
    String? mediaType,
    required BackendUser user,
  }) async {
    final newPost = await _forumRepository.createPost(
      title: title,
      content: content,
      tag: tag,
      mediaUri: mediaUri,
      mediaType: mediaType,
      author: user.fullName,
      school: user.schoolName ?? '',
      authorId: user.id,
    );
    _posts = [newPost, ..._posts];
    notifyListeners();
    return newPost;
  }

  Future<CommunityPost> updatePost({
    required String id,
    required String title,
    required String content,
    required String tag,
    String? mediaUri,
    String? mediaType,
  }) async {
    final updated = await _forumRepository.updatePost(
      id: id,
      title: title,
      content: content,
      tag: tag,
      mediaUri: mediaUri,
      mediaType: mediaType,
    );
    _posts = _posts.map((p) => p.id == id ? updated : p).toList();
    if (_activeThreadPost?.id == id) _activeThreadPost = updated;
    notifyListeners();
    return updated;
  }

  Future<void> deletePost(String postId) async {
    await _forumRepository.deletePost(postId);
    _posts = _posts.where((p) => p.id != postId).toList();
    if (_activeThreadPost?.id == postId) _activeThreadPost = null;
    notifyListeners();
  }

  Future<void> toggleLikePost(String postId) async {
    await _forumRepository.toggleLikePost(postId);
    _posts = _posts.map((post) {
      if (post.id == postId) {
        final liked = !post.isLiked;
        return CommunityPost(
          id: post.id,
          author: post.author,
          school: post.school,
          authorId: post.authorId,
          timeAgo: post.timeAgo,
          createdAt: post.createdAt,
          tag: post.tag,
          tagColor: post.tagColor,
          tagBg: post.tagBg,
          title: post.title,
          content: post.content,
          mediaUri: post.mediaUri,
          mediaType: post.mediaType,
          likesCount: post.likesCount + (liked ? 1 : -1),
          isLiked: liked,
          isPinned: post.isPinned,
          comments: post.comments,
        );
      }
      return post;
    }).toList();
    notifyListeners();
  }

  Future<void> addComment(String postId, String content, BackendUser user) async {
    if (content.trim().isEmpty) return;
    await _forumRepository.addComment(postId, content, user.fullName, user.schoolName ?? '', user.id);
    _posts = _posts.map((post) {
      if (post.id == postId) {
        final newComment = CommunityComment(
          id: 'c-${DateTime.now().millisecondsSinceEpoch}',
          postId: postId,
          author: user.fullName,
          school: user.schoolName ?? '',
          authorId: user.id,
          timeAgo: 'Baru saja',
          createdAt: DateTime.now().toIso8601String(),
          content: content.trim(),
          likesCount: 0,
          isLiked: false,
          replies: [],
        );
        return CommunityPost(
          id: post.id,
          author: post.author,
          school: post.school,
          authorId: post.authorId,
          timeAgo: post.timeAgo,
          createdAt: post.createdAt,
          tag: post.tag,
          tagColor: post.tagColor,
          tagBg: post.tagBg,
          title: post.title,
          content: post.content,
          mediaUri: post.mediaUri,
          mediaType: post.mediaType,
          likesCount: post.likesCount,
          isLiked: post.isLiked,
          isPinned: post.isPinned,
          comments: [...post.comments, newComment],
        );
      }
      return post;
    }).toList();
    notifyListeners();
  }

  Future<void> addReply(String postId, String commentId, String content, BackendUser user) async {
    if (content.trim().isEmpty) return;
    await _forumRepository.addReply(postId, commentId, content, user.fullName, user.schoolName ?? '', user.id);
    _posts = _posts.map((post) {
      if (post.id == postId) {
        final newReply = CommunityCommentReply(
          id: 'r-${DateTime.now().millisecondsSinceEpoch}',
          commentId: commentId,
          author: user.fullName,
          school: user.schoolName ?? '',
          authorId: user.id,
          timeAgo: 'Baru saja',
          createdAt: DateTime.now().toIso8601String(),
          content: content.trim(),
          likesCount: 0,
          isLiked: false,
        );
        final updatedComments = post.comments.map((comment) {
          if (comment.id == commentId) {
            return CommunityComment(
              id: comment.id,
              postId: comment.postId,
              author: comment.author,
              school: comment.school,
              authorId: comment.authorId,
              timeAgo: comment.timeAgo,
              createdAt: comment.createdAt,
              content: comment.content,
              likesCount: comment.likesCount,
              isLiked: comment.isLiked,
              replies: [...comment.replies, CommunityCommentReply(
                id: 'r-${DateTime.now().millisecondsSinceEpoch}',
                commentId: commentId,
                author: user.fullName,
                school: user.schoolName ?? '',
                authorId: user.id,
                timeAgo: 'Baru saja',
                createdAt: DateTime.now().toIso8601String(),
                content: content.trim(),
                likesCount: 0,
                isLiked: false,
              )],
            );
          }
          return comment;
        }).toList();
        return CommunityPost(
          id: post.id,
          author: post.author,
          school: post.school,
          authorId: post.authorId,
          timeAgo: post.timeAgo,
          createdAt: post.createdAt,
          tag: post.tag,
          tagColor: post.tagColor,
          tagBg: post.tagBg,
          title: post.title,
          content: post.content,
          mediaUri: post.mediaUri,
          mediaType: post.mediaType,
          likesCount: post.likesCount,
          isLiked: post.isLiked,
          isPinned: post.isPinned,
          comments: updatedComments,
        );
      }
      return post;
    }).toList();
    notifyListeners();
  }

  Future<void> toggleLikeComment(String postId, String commentId) async {
    _posts = _posts.map((post) {
      if (post.id == postId) {
        final updatedComments = post.comments.map((comment) {
          if (comment.id == commentId) {
            final liked = !comment.isLiked;
            return CommunityComment(
              id: comment.id,
              postId: comment.postId,
              author: comment.author,
              school: comment.school,
              authorId: comment.authorId,
              timeAgo: comment.timeAgo,
              createdAt: comment.createdAt,
              content: comment.content,
              likesCount: comment.likesCount + (liked ? 1 : -1),
              isLiked: liked,
              replies: comment.replies,
            );
          }
          return comment;
        }).toList();
        return CommunityPost(
          id: post.id,
          author: post.author,
          school: post.school,
          authorId: post.authorId,
          timeAgo: post.timeAgo,
          createdAt: post.createdAt,
          tag: post.tag,
          tagColor: post.tagColor,
          tagBg: post.tagBg,
          title: post.title,
          content: post.content,
          mediaUri: post.mediaUri,
          mediaType: post.mediaType,
          likesCount: post.likesCount,
          isLiked: post.isLiked,
          isPinned: post.isPinned,
          comments: updatedComments,
        );
      }
      return post;
    }).toList();
    notifyListeners();
  }

  Future<void> resetToInitialData() async {
    await _forumRepository.savePosts([]);
    _posts = [];
    notifyListeners();
  }
}
