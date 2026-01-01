import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/watch_room_provider.dart';
import '../models/movie_model.dart';
import '../services/movie_service.dart';
import 'watch_room_screen.dart';

class CreateWatchRoomScreen extends StatefulWidget {
  final Movie? selectedMovie;
  final String? selectedEpisodeSlug;

  const CreateWatchRoomScreen({
    super.key,
    this.selectedMovie,
    this.selectedEpisodeSlug,
  });

  @override
  State<CreateWatchRoomScreen> createState() => _CreateWatchRoomScreenState();
}

class _CreateWatchRoomScreenState extends State<CreateWatchRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _passwordController = TextEditingController();
  
  Movie? _selectedMovie;
  String? _selectedEpisodeSlug;
  bool _isPrivate = false;
  bool _isLoading = false;
  
  List<Movie> _searchResults = [];
  bool _isSearching = false;
  final MovieService _movieService = MovieService();

  @override
  void initState() {
    super.initState();
    _selectedMovie = widget.selectedMovie;
    _selectedEpisodeSlug = widget.selectedEpisodeSlug;
    
    if (_selectedMovie != null) {
      _titleController.text = '${_selectedMovie!.name} - Xem cùng nhau';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _searchMovies(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    
    try {
      // Increased limit to 100 for more search results
      final results = await _movieService.searchMovies(query, limit: 100);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tìm kiếm: $e')),
        );
      }
    }
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMovie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phim')),
      );
      return;
    }
    if (_selectedEpisodeSlug == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn tập phim')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = Provider.of<WatchRoomProvider>(context, listen: false);
    
    final success = await provider.createRoom(
      movieId: _selectedMovie!.id,
      episodeSlug: _selectedEpisodeSlug!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      isPrivate: _isPrivate,
      password: _isPrivate ? _passwordController.text.trim() : null,
      maxUsers: 50, // Default value
    );

    setState(() => _isLoading = false);

    if (success && provider.currentRoom != null) {
      // Navigate to watch room
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WatchRoomScreen(
            roomId: provider.currentRoom!.roomId,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Lỗi khi tạo phòng'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E13) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Tạo phòng xem'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Movie selection
                    _buildMovieSelection(),
                    
                    const SizedBox(height: 24),
                    
                    // Episode selection
                    if (_selectedMovie != null) _buildEpisodeSelection(),
                    
                    const SizedBox(height: 24),
                    
                    // Room title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Tên phòng',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên phòng';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Mô tả (tùy chọn)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.white,
                      ),
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Private room toggle
                    SwitchListTile(
                      title: const Text('Phòng riêng tư'),
                      subtitle: const Text('Cần mật khẩu để tham gia'),
                      value: _isPrivate,
                      onChanged: (value) {
                        setState(() => _isPrivate = value);
                      },
                    ),
                    
                    // Password field
                    if (_isPrivate) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.white,
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (_isPrivate && (value == null || value.trim().isEmpty)) {
                            return 'Vui lòng nhập mật khẩu';
                          }
                          return null;
                        },
                      ),
                    ],
                    
                    const SizedBox(height: 100), // Extra space để đảm bảo có thể scroll
                  ],
                ),
              ),
            ),
          ),
          
          // Fixed bottom button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B0E13) : const Color(0xFFF5F5F5),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createRoom,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Tạo phòng',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieSelection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn phim',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        
        const SizedBox(height: 12),
        
        if (_selectedMovie != null)
          Card(
            color: isDark ? Colors.grey[850] : Colors.white,
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _selectedMovie!.posterUrl,
                  width: 50,
                  height: 75,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 75,
                      color: Colors.grey[300],
                      child: const Icon(Icons.movie),
                    );
                  },
                ),
              ),
              title: Text(_selectedMovie!.name),
              subtitle: Text(_selectedMovie!.originName ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedMovie = null;
                    _selectedEpisodeSlug = null;
                  });
                },
              ),
            ),
          )
        else
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm phim...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.white,
            ),
            onChanged: _searchMovies,
          ),
        
        // Search results
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_searchResults.isNotEmpty && _selectedMovie == null)
          Container(
            constraints: const BoxConstraints(maxHeight: 250), // Giới hạn chiều cao
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true, // Quan trọng: cho phép ListView co lại
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final movie = _searchResults[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      movie.posterUrl,
                      width: 40,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 40,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.movie, size: 20),
                        );
                      },
                    ),
                  ),
                  title: Text(
                    movie.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(movie.originName ?? ''),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    print('Selected movie: ${movie.name}'); // Debug log
                    setState(() {
                      _selectedMovie = movie;
                      _searchResults = [];
                      _titleController.text = '${movie.name} - Xem cùng nhau';
                      
                      // Tự động chọn tập đầu tiên
                      if (movie.episodes.isNotEmpty && movie.episodes[0].serverData.isNotEmpty) {
                        _selectedEpisodeSlug = movie.episodes[0].serverData[0].slug;
                      } else {
                        // Tạo episode mặc định dựa trên episode_current
                        final episodeCurrent = movie.episodeCurrent;
                        if (episodeCurrent.toLowerCase().contains('full') || 
                            episodeCurrent.toLowerCase().contains('hoàn tất')) {
                          _selectedEpisodeSlug = 'full';
                        } else {
                          _selectedEpisodeSlug = 'tap-1';
                        }
                      }
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEpisodeSelection() {
    if (_selectedMovie == null) return const SizedBox();
    
    // Nếu không có episodes data từ API, tạo episodes mặc định
    List<ServerData> episodes = [];
    
    if (_selectedMovie!.episodes.isNotEmpty && _selectedMovie!.episodes[0].serverData.isNotEmpty) {
      episodes = _selectedMovie!.episodes[0].serverData;
    } else {
      // Tạo episodes mặc định dựa trên episode_current
      final episodeCurrent = _selectedMovie!.episodeCurrent;
      if (episodeCurrent.isNotEmpty) {
        if (episodeCurrent.contains('/')) {
          // Trường hợp "Hoàn Tất (6/6)" hoặc "5/10"
          final parts = episodeCurrent.split('/');
          if (parts.length == 2) {
            final totalEpisodes = int.tryParse(parts[1].replaceAll(RegExp(r'[^\d]'), '')) ?? 1;
            for (int i = 1; i <= totalEpisodes; i++) {
              episodes.add(ServerData(
                name: 'Tập $i',
                slug: 'tap-$i',
                filename: 'tap-$i',
                linkEmbed: '',
                linkM3u8: '',
              ));
            }
          }
        } else if (episodeCurrent.toLowerCase().contains('full') || 
                   episodeCurrent.toLowerCase().contains('hoàn tất')) {
          // Phim lẻ hoặc hoàn tất
          episodes.add(ServerData(
            name: 'Full',
            slug: 'full',
            filename: 'full',
            linkEmbed: '',
            linkM3u8: '',
          ));
        } else {
          // Trường hợp khác, tạo 1 tập mặc định
          episodes.add(ServerData(
            name: 'Tập 1',
            slug: 'tap-1',
            filename: 'tap-1',
            linkEmbed: '',
            linkM3u8: '',
          ));
        }
      } else {
        // Không có thông tin, tạo tập mặc định
        episodes.add(ServerData(
          name: 'Tập 1',
          slug: 'tap-1',
          filename: 'tap-1',
          linkEmbed: '',
          linkM3u8: '',
        ));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn tập',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        
        const SizedBox(height: 12),
        
        if (episodes.isEmpty)
          const Text(
            'Phim này chưa có tập nào',
            style: TextStyle(color: Colors.grey),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: episodes.map((episode) {
              final isSelected = _selectedEpisodeSlug == episode.slug;
              
              return FilterChip(
                label: Text(episode.name),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedEpisodeSlug = selected ? episode.slug : null;
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }
}