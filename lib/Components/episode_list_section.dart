import 'package:flutter/material.dart';
import '../models/movie_model.dart';

class EpisodeListSection extends StatefulWidget {
  final List<EpisodeServer> episodes;
  final String type; // 'series', 'single', etc.
  final String quality;

  const EpisodeListSection({
    super.key,
    required this.episodes,
    required this.type,
    required this.quality,
  });

  @override
  State<EpisodeListSection> createState() => _EpisodeListSectionState();
}

class _EpisodeListSectionState extends State<EpisodeListSection> {
  int _selectedServerIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.episodes.isEmpty) {
      if (widget.type == 'single') {
         return _buildSingleMovieQualityBadge(context);
      }
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if we have multiple servers
    final hasMultipleServers = widget.episodes.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh sách tập',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        if (hasMultipleServers) ...[
          const SizedBox(height: 12),
          _buildServerSelector(context),
        ],
       
        const SizedBox(height: 12),
        
        // Show episodes for the selected server
        _buildEpisodeGrid(context, widget.episodes[_selectedServerIndex]),
      ],
    );
  }

  Widget _buildSingleMovieQualityBadge(BuildContext context) {
      // Fallback for single movies without explicit episode links yet
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'Chất lượng',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF5BA3F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.quality, // e.g., "Full HD"
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      );
  }

  Widget _buildServerSelector(BuildContext context) {
    // Simple dropdown or row of server names could go here
    // For now, just a text indicating multiple servers or a simplified toggler could be added
    // Implementing a simple Row of chips for servers
     final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(widget.episodes.length, (index) {
          final isSelected = index == _selectedServerIndex;
          return Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedServerIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF5BA3F5) : (isDark ? const Color(0xFF1A2332) : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.episodes[index].serverName,
                  style: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEpisodeGrid(BuildContext context, EpisodeServer server) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // If it's a single movie type, usually just 1 episode "Full". 
    // If user specifically requested: "với phim là phim lẻ, hiển thị button là chất lượng phim"
    // So if type is 'single' AND we have episodes (like "Full"), we might still want to show it as a big button like the quality one.
    
    if (widget.type == 'single' || widget.type == 'movie') {
       // Often 'single' movies in APIs have one episode named 'Full' or 'Tap Full'.
       // We can display it similar to the quality badge, or a large "Play Movie" button.
       // Let's stick to the grid for now but maybe wider?
       // Actually, the user requirement: "với phim là phim lẻ, hiển thị button là chất lượng phim".
       // So I should show the Quality Button regardless of episode list content if it's single? 
       // But clicking it should probably play?
       // For now, let's display the episodes as buttons. 
       
       if (server.serverData.length == 1) {
          return Center(
             child: Container(
               width: double.infinity,
               margin: const EdgeInsets.only(bottom: 8),
               child: ElevatedButton(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFF5BA3F5),
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                 ),
                 onPressed: () {
                    // Navigate to player
                 },
                 child: Text(
                   'Xem Phim (${widget.quality})',
                   style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                 ),
               ),
             ),
          );
       }
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, // 5 buttons per row
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: server.serverData.length,
      itemBuilder: (context, index) {
        final episode = server.serverData[index];
        return InkWell(
          onTap: () {
             // Handle episode tap (play)
          },
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2332) : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.transparent),
            ),
            alignment: Alignment.center,
            child: Text(
              episode.name,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
}
