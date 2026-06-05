import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'services/tweet_service.dart';
import 'services/auth_service.dart';
import 'models/tweet.dart';
import 'models/comment.dart';
import 'models/reaction_count.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/create_post_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();
  await authService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zombie Network',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFCC0000),
          surface: Color(0xFF1A0000),
        ),
        useMaterial3: true,
      ),
      home: _buildHome(),
      routes: {
        '/login':       (context) => const LoginScreen(),
        '/home':        (context) => const MyHomePage(title: '[ ZOMBIE NETWORK ]'),
        '/register':    (context) => const RegisterScreen(),
        '/create-post': (context) => const CreatePostScreen(),
      },
    );
  }

  Widget _buildHome() {
    final authService = AuthService();
    if (authService.isAuthenticated()) {
      return const MyHomePage(title: '[ ZOMBIE NETWORK ]');
    } else {
      return const LoginScreen();
    }
  }
}

// ─── HOME PAGE ────────────────────────────────────────────────────────────────

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late TweetService _tweetService;
  late AuthService _authService;
  late Future<List<Tweet>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _tweetService = TweetService();
    _authService = AuthService();
    _loadPosts();
  }

  void _loadPosts() {
    setState(() {
      _postsFuture = _tweetService.fetchTweets();
    });
  }

  // Redirige al login cuando una acción con auth falla (POST/DELETE)
  void _handleSessionExpired() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('[ SESIÓN EXPIRADA — VUELVE A IDENTIFICARTE ]'),
        backgroundColor: Color(0xFFCC0000),
        duration: Duration(seconds: 3),
      ),
    );
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _deletePost(int id) async {
    try {
      await _tweetService.deleteTweet(id);
      _loadPosts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('[ POST ELIMINADO ]'),
            backgroundColor: Color(0xFFCC0000),
          ),
        );
      }
    } on SessionExpiredException {
      _handleSessionExpired();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[900],
          ),
        );
      }
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0000),
        title: const Text(
          '[ ELIMINAR POST ]',
          style: TextStyle(
            color: Color(0xFFCC0000),
            fontFamily: 'monospace',
            fontSize: 16,
          ),
        ),
        content: const Text(
          '¿Confirmas la eliminación?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCELAR',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deletePost(id);
            },
            child: const Text('ELIMINAR',
                style: TextStyle(color: Color(0xFFCC0000))),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tweetService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.getUser();
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0000),
        title: const Text(
          '[ ZOMBIE NETWORK ]',
          style: TextStyle(
            color: Color(0xFFCC0000),
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                user?.username ?? '',
                style: const TextStyle(
                  color: Color(0xFF888888),
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
          PopupMenuButton(
            iconColor: const Color(0xFFCC0000),
            color: const Color(0xFF1A0000),
            itemBuilder: (_) => [
              PopupMenuItem(
                onTap: _logout,
                child: const Text(
                  'CERRAR SESIÓN',
                  style: TextStyle(
                    color: Color(0xFFCC0000),
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF3A0000)),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFFCC0000),
        backgroundColor: const Color(0xFF1A0000),
        onRefresh: () async => _loadPosts(),
        child: FutureBuilder<List<Tweet>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFCC0000),
                ),
              );
            } else if (snapshot.hasError) {
              // Pantalla de error idéntica al original + instrucción de reintentar
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('☣',
                        style: TextStyle(
                            fontSize: 48, color: Color(0xFFCC0000))),
                    const SizedBox(height: 16),
                    Text(
                      '[ ERROR DE CONEXIÓN ]',
                      style: TextStyle(
                        color: Colors.red[400],
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        snapshot.error.toString(),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: _loadPosts,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFCC0000),
                        side: const BorderSide(color: Color(0xFFCC0000)),
                      ),
                      child: const Text('REINTENTAR',
                          style: TextStyle(fontFamily: 'monospace')),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  '[ SIN REPORTES EN LA ZONA ]',
                  style: TextStyle(
                    color: Color(0xFF555555),
                    fontFamily: 'monospace',
                  ),
                ),
              );
            }

            final posts = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return PostCard(
                  post: posts[index],
                  currentUserId: user?.id,
                  onDelete: _confirmDelete,
                  tweetService: _tweetService,
                  onSessionExpired: _handleSessionExpired,
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFCC0000),
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context)
            .pushNamed('/create-post')
            .then((_) => _loadPosts()),
        tooltip: 'Nuevo reporte',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── POST CARD ────────────────────────────────────────────────────────────────

class PostCard extends StatefulWidget {
  final Tweet post;
  final int? currentUserId;
  final void Function(int) onDelete;
  final TweetService tweetService;
  final VoidCallback onSessionExpired;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onDelete,
    required this.tweetService,
    required this.onSessionExpired,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late Future<List<ReactionCount>> _reactionsFuture;

  bool _showComments   = false;
  List<Comment>? _comments;
  bool _loadingComments = false;
  bool _postingComment  = false;
  final TextEditingController _commentCtrl = TextEditingController();

  static const Map<String, String> _reactionEmojis = {
    'REACTION_SKULL':     '💀',
    'REACTION_BIOHAZARD': '☣️',
    'REACTION_FIRE':      '🔥',
    'REACTION_BRAIN':     '🧠',
    'REACTION_INFECTED':  '🧟',
  };

  @override
  void initState() {
    super.initState();
    _loadReactions();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _loadReactions() {
    if (!mounted) return;
    setState(() {
      _reactionsFuture = widget.tweetService.fetchReactions(widget.post.id);
    });
  }

  Future<void> _handleReaction(int reactionId) async {
    try {
      await widget.tweetService.reactToPost(widget.post.id, reactionId);
      _loadReactions();
    } on SessionExpiredException {
      widget.onSessionExpired();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red[900],
        ));
      }
    }
  }

  Future<void> _toggleComments() async {
    if (_showComments) {
      setState(() => _showComments = false);
      return;
    }
    if (_comments == null) {
      setState(() { _showComments = true; _loadingComments = true; });
      try {
        final comments =
            await widget.tweetService.fetchComments(widget.post.id);
        if (mounted) {
          setState(() { _comments = comments; _loadingComments = false; });
        }
      } catch (e) {
        if (mounted) {
          setState(() { _showComments = false; _loadingComments = false; });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('[ ERROR ] $e'),
            backgroundColor: Colors.red[900],
          ));
        }
      }
    } else {
      setState(() => _showComments = true);
    }
  }

  Future<void> _reloadComments() async {
    final comments = await widget.tweetService.fetchComments(widget.post.id);
    if (mounted) setState(() => _comments = comments);
  }

  Future<void> _postComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _postingComment = true);
    try {
      await widget.tweetService.createComment(widget.post.id, text);
      _commentCtrl.clear();
      await _reloadComments();
    } on SessionExpiredException {
      widget.onSessionExpired();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('[ ERROR ] $e'),
          backgroundColor: Colors.red[900],
        ));
      }
    } finally {
      if (mounted) setState(() => _postingComment = false);
    }
  }

  Future<void> _confirmDeleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0000),
        title: const Text(
          '[ ELIMINAR TRANSMISIÓN ]',
          style: TextStyle(
            color: Color(0xFFCC0000),
            fontFamily: 'monospace',
            fontSize: 14,
          ),
        ),
        content: const Text(
          '¿Confirmas la eliminación?',
          style: TextStyle(color: Colors.white70, fontFamily: 'monospace'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCELAR',
                style: TextStyle(color: Colors.white54, fontFamily: 'monospace')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ELIMINAR',
                style: TextStyle(color: Color(0xFFCC0000), fontFamily: 'monospace')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.tweetService.deleteComment(widget.post.id, comment.id);
      await _reloadComments();
    } on SessionExpiredException {
      widget.onSessionExpired();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('[ ERROR ] $e'),
          backgroundColor: Colors.red[900],
        ));
      }
    }
  }

  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final hasScheme = uri.hasAbsolutePath &&
        (uri.isScheme('http') || uri.isScheme('https'));
    final isSearchUrl = url.contains('/search') ||
        (url.contains('?') &&
            !url.contains('.jpg') &&
            !url.contains('.png') &&
            !url.contains('.jpeg'));
    return hasScheme && !isSearchUrl;
  }

  Widget _buildImageErrorWidget() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A0000), Color(0xFF0D0000)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFCC0000), size: 28),
            SizedBox(height: 6),
            Text(
              '[ ARCHIVO DAÑADO / ENLACE ROTO ]',
              style: TextStyle(
                color: Color(0xFFCC0000),
                fontSize: 10,
                fontFamily: 'monospace',
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.currentUserId != null &&
        widget.post.postedBy?.id == widget.currentUserId;
    final commentCount = _comments?.length ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF120000),
        border: Border.all(color: const Color(0xFF3A0000)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
            child: Row(
              children: [
                const Text('☣ ',
                    style: TextStyle(color: Color(0xFFCC0000), fontSize: 12)),
                Expanded(
                  child: Text(
                    widget.post.postedBy?.username ?? 'Desconocido',
                    style: const TextStyle(
                      color: Color(0xFFCC0000),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Color(0xFF884444), size: 18),
                    onPressed: () => widget.onDelete(widget.post.id),
                    tooltip: 'Eliminar post',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),

          // ── Imagen ────────────────────────────────────────────────────
          if (widget.post.imageUrl != null &&
              widget.post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.zero),
              child: _isValidUrl(widget.post.imageUrl)
                  ? CachedNetworkImage(
                      imageUrl: widget.post.imageUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: const Color(0xFF1A0000),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFCC0000),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          _buildImageErrorWidget(),
                    )
                  : _buildImageErrorWidget(),
            ),
          ],

          // ── Descripción ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Text(
              widget.post.description,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ),

          // ── Reacciones ────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF2A0000))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: FutureBuilder<List<ReactionCount>>(
              future: _reactionsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(height: 32);
                final reactions = snapshot.data!;
                return Row(
                  children: reactions.map((r) {
                    final emoji = _reactionEmojis[r.reactionType] ?? '❓';
                    return Expanded(
                      child: InkWell(
                        onTap: () => _handleReaction(r.reactionId),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 2),
                          child: Column(
                            children: [
                              Text(emoji,
                                  style: const TextStyle(fontSize: 18)),
                              const SizedBox(height: 2),
                              Text(
                                '${r.count}',
                                style: const TextStyle(
                                  color: Color(0xFF888888),
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // ── Botón transmisiones ───────────────────────────────────────
          InkWell(
            onTap: _toggleComments,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF2A0000))),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  const Text('📡 ', style: TextStyle(fontSize: 12)),
                  Text(
                    _comments != null
                        ? '[ $commentCount TRANSMISION${commentCount != 1 ? "ES" : ""} ]'
                        : '[ TRANSMISIONES ]',
                    style: const TextStyle(
                      color: Color(0xFF884444),
                      fontFamily: 'monospace',
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showComments ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF884444),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          // ── Sección expandible ────────────────────────────────────────
          if (_showComments) ...[
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0D0000),
                border:
                    Border(top: BorderSide(color: Color(0xFF2A0000))),
              ),
              child: _loadingComments
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFCC0000),
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_comments != null && _comments!.isNotEmpty)
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _comments!.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: Color(0xFF1A0000),
                            ),
                            itemBuilder: (_, i) => _CommentTile(
                              comment: _comments![i],
                              currentUserId: widget.currentUserId,
                              onDelete: () =>
                                  _confirmDeleteComment(_comments![i]),
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.fromLTRB(14, 12, 14, 4),
                            child: Text(
                              '[ SIN TRANSMISIONES EN ESTA ZONA ]',
                              style: TextStyle(
                                color: Color(0xFF555555),
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          ),

                        Container(
                          decoration: const BoxDecoration(
                            border: Border(
                                top:
                                    BorderSide(color: Color(0xFF2A0000))),
                          ),
                          padding:
                              const EdgeInsets.fromLTRB(10, 8, 10, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentCtrl,
                                  maxLength: 280,
                                  maxLines: 2,
                                  minLines: 1,
                                  enabled: !_postingComment,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'TRANSMITIR MENSAJE...',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF444444),
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF1A0000),
                                    isDense: true,
                                    counterText: '',
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF3A0000)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF3A0000)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFCC0000)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 36,
                                child: ElevatedButton(
                                  onPressed: _postingComment
                                      ? null
                                      : _postComment,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFFCC0000),
                                    disabledBackgroundColor:
                                        const Color(0xFF660000),
                                    foregroundColor: Colors.white,
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: _postingComment
                                      ? const SizedBox(
                                          height: 14,
                                          width: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'ENVIAR',
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 11,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── COMMENT TILE ─────────────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final int? currentUserId;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.currentUserId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = comment.isOwner(currentUserId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '☣ ${comment.username}',
                  style: const TextStyle(
                    color: Color(0xFF884444),
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  comment.content,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.close,
                  color: Color(0xFF663333), size: 14),
              onPressed: onDelete,
              tooltip: 'Eliminar transmisión',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}