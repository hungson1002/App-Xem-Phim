import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/watch_room_provider.dart';
import '../models/watch_room_model.dart';
import 'create_watch_room_screen.dart';
import 'watchroom_screen.dart';

class WatchRoomsScreen extends StatefulWidget {
  const WatchRoomsScreen({super.key});

  @override
  State<WatchRoomsScreen> createState() => _WatchRoomsScreenState();
}

class _WatchRoomsScreenState extends State<WatchRoomsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<WatchRoomProvider>(context, listen: false);
      provider.loadPublicRooms();
    });
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
      backgroundColor: isDark ? const Color(0xFF0B0E13) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Xem cùng nhau'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateWatchRoomScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm phòng...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.white,
              ),
              onChanged: (value) {
                final provider = Provider.of<WatchRoomProvider>(context, listen: false);
                provider.loadPublicRooms(search: value);
              },
            ),
          ),
          
          // Rooms list
          Expanded(
            child: _buildRoomsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsList() {
    return Consumer<WatchRoomProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.publicRooms.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.publicRooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.tv_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có phòng nào',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hãy tạo phòng đầu tiên!',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateWatchRoomScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo phòng mới'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadPublicRooms(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: provider.publicRooms.length,
            itemBuilder: (context, index) {
              final room = provider.publicRooms[index];
              return _buildRoomCard(room);
            },
          ),
        );
      },
    );
  }

  Widget _buildRoomCard(WatchRoom room) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnded = room.status != 'active';
    
    return Opacity(
      opacity: isEnded ? 0.6 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: isDark ? Colors.grey[850] : Colors.white,
        child: InkWell(
          onTap: isEnded ? null : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WatchRoomScreen(roomId: room.roomId),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Movie poster
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    room.movieInfo?.posterUrl ?? '',
                    width: 60,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 90,
                        color: Colors.grey[300],
                        child: const Icon(Icons.movie),
                      );
                    },
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Room info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        room.movieInfo?.name ?? 'Unknown Movie',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${room.userCount}/${room.maxUsers}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          if (room.isPrivate)
                            Icon(
                              Icons.lock,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          
                          const Spacer(),
                          
                          // Status indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: room.status == 'active' 
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              room.status == 'active' ? 'Đang hoạt động' : 'Đã kết thúc',
                              style: TextStyle(
                                fontSize: 10,
                                color: room.status == 'active' ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}