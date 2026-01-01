import 'package:flutter/material.dart';
import '../services/movie_service.dart';
import '../models/movie_model.dart';
import '../Components/search_results_grid.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final MovieService _movieService = MovieService();
  final TextEditingController _searchController = TextEditingController();
  List<Movie> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Search movies
  Future<void> _searchMovies(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final movies = await _movieService.searchMovies(query);
      setState(() {
        _searchResults = movies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching movies: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: 'Search movies...',
            hintStyle: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            border: InputBorder.none,
          ),
          onSubmitted: _searchMovies,
          textInputAction: TextInputAction.search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _searchMovies(_searchController.text),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!),
      );
    }

    if (_searchResults.isEmpty) {
      if (_searchController.text.isNotEmpty) {
        return const Center(
          child: Text('No movies found'),
        );
      }
      return const Center(
        child: Text('Enter a keyword to search'),
      );
    }

    return SearchResultsGrid(movies: _searchResults);
  }
}
