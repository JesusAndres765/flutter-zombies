import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/tweet_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TweetService _tweetService = TweetService();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String _previewUrl = '';

  @override
  void dispose() {
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final hasScheme = uri.hasAbsolutePath && (uri.isScheme('http') || uri.isScheme('https'));
    final isSearchUrl = url.contains('/search') || 
                        (url.contains('?') && !url.contains('.jpg') && !url.contains('.png') && !url.contains('.jpeg'));
    return hasScheme && !isSearchUrl;
  }

  Future<void> _submitPost() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      setState(() => _errorMessage = 'La descripción no puede estar vacía');
      return;
    }

    final imageUrl = _imageUrlController.text.trim();
    if (imageUrl.isNotEmpty && !_isValidUrl(imageUrl)) {
      setState(() => _errorMessage = 'Por favor, introduce una URL de imagen directa válida (ej: debe empezar con http:// o https:// y terminar en extensión de imagen, o no ser un buscador)');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _tweetService.createTweet(
        description,
        imageUrl.isEmpty ? null : imageUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('[ REPORTE ENVIADO ]'),
            backgroundColor: Color(0xFFCC0000),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0000),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFCC0000)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '[ NUEVO REPORTE ]',
          style: TextStyle(
            color: Color(0xFFCC0000),
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF3A0000)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text(
              'DESCRIPCIÓN DEL REPORTE',
              style: TextStyle(
                color: Color(0xFF888888),
                fontFamily: 'monospace',
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              maxLength: 500,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Describe lo que observaste...',
                hintStyle: const TextStyle(
                  color: Color(0xFF444444),
                  fontFamily: 'monospace',
                ),
                filled: true,
                fillColor: const Color(0xFF1A0000),
                counterStyle: const TextStyle(color: Color(0xFF555555)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFF3A0000)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFF3A0000)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFFCC0000)),
                ),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 20),
            const Text(
              'URL DE IMAGEN (OPCIONAL)',
              style: TextStyle(
                color: Color(0xFF888888),
                fontFamily: 'monospace',
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _imageUrlController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'https://...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF444444),
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.image_outlined,
                        color: Color(0xFFCC0000),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A0000),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide:
                            const BorderSide(color: Color(0xFF3A0000)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide:
                            const BorderSide(color: Color(0xFF3A0000)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide:
                            const BorderSide(color: Color(0xFFCC0000)),
                      ),
                    ),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _previewUrl = _imageUrlController.text.trim();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFCC0000),
                    side: const BorderSide(color: Color(0xFF3A0000)),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'VER',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ),

            // Image preview
            if (_previewUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF3A0000)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: _isValidUrl(_previewUrl)
                      ? CachedNetworkImage(
                          imageUrl: _previewUrl,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 180,
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
                              child: Text(
                                '[ ARCHIVO NO SOPORTADO / ENLACE ROTO ]',
                                style: TextStyle(
                                  color: Color(0xFF884444),
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          height: 80,
                          color: const Color(0xFF1A0000),
                          child: const Center(
                            child: Text(
                              '[ URL DE IMAGEN INVÁLIDA O DE BÚSQUEDA ]',
                              style: TextStyle(
                                color: Color(0xFF884444),
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A0000),
                  border: Border.all(color: const Color(0xFFCC0000)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '[ ERROR ] $_errorMessage',
                  style: const TextStyle(
                    color: Color(0xFFCC0000),
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton(
              onPressed: _isLoading ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCC0000),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF660000),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'ENVIAR REPORTE',
                      style: TextStyle(
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}