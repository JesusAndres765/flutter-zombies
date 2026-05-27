import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'services/tweet_service.dart';
import 'services/auth_service.dart';
import 'models/tweet.dart';
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
        '/login': (context) => const LoginScreen(),
        '/home': (context) =>
            const MyHomePage(title: '[ ZOMBIE NETWORK ]'),
        '/register': (context) => const RegisterScreen(),
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

// ─── HOME PAGE ───────────────────────────────────────────────────────────────

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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('☣',
                        style: TextStyle(fontSize: 48, color: Color(0xFFCC0000))),
                    const SizedBox(height: 16),
                    Text(
                      '[ ERROR DE CONEXIÓN ]',
                      style: TextStyle(
                        color: Colors.red[400],
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                      textAlign: TextAlign.center,
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
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFCC0000),
        foregroundColor: Colors.white,
        // onPressed se conectará a /create-post en el siguiente paso
        onPressed: () => Navigator.of(context).pushNamed('/create-post')
            .then((_) => _loadPosts()),
        child: const Icon(Icons.add),
        tooltip: 'Nuevo reporte',
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

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onDelete,
    required this.tweetService,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late Future<List<ReactionCount>> _reactionsFuture;

  // Mapeo de tipo de reacción a emoji
  static const Map<String, String> _reactionEmojis = {
    'REACTION_SKULL': '💀',
    'REACTION_BIOHAZARD': '☣️',
    'REACTION_FIRE': '🔥',
    'REACTION_BRAIN': '🧠',
    'REACTION_INFECTED': '🧟',
  };

  @override
  void initState() {
    super.initState();
    _loadReactions();
  }

  void _loadReactions() {
    setState(() {
      _reactionsFuture = widget.tweetService.fetchReactions(widget.post.id);
    });
  }

  Future<void> _handleReaction(int reactionId) async {
    try {
      await widget.tweetService.reactToPost(widget.post.id, reactionId);
      _loadReactions();
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

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.currentUserId != null &&
        widget.post.postedBy?.id == widget.currentUserId;

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
          // Header: username + delete
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
            child: Row(
              children: [
                const Text('☣ ',
                    style: TextStyle(
                      color: Color(0xFFCC0000),
                      fontSize: 12,
                    )),
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

          // Image
          if (widget.post.imageUrl != null &&
              widget.post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.zero),
              child: CachedNetworkImage(
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
                errorWidget: (context, url, error) => Container(
                  height: 80,
                  color: const Color(0xFF1A0000),
                  child: const Center(
                    child: Icon(Icons.broken_image,
                        color: Color(0xFF3A0000), size: 32),
                  ),
                ),
              ),
            ),
          ],

          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Text(
              widget.post.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),

          // Reactions bar
          Container(
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: Color(0xFF2A0000))),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: FutureBuilder<List<ReactionCount>>(
              future: _reactionsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(height: 32);
                }
                final reactions = snapshot.data!;
                return Row(
                  children: reactions.map((r) {
                    final emoji =
                        _reactionEmojis[r.reactionType] ?? '❓';
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
        ],
      ),
    );
  }
}