// Component hiển thị danh sách người tham gia trong phòng xem chung.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/watch_room_model.dart';

class WatchRoomParticipants extends StatelessWidget {
  final List<Participant> participants;
  final String hostId;

  const WatchRoomParticipants({
    super.key,
    required this.participants,
    required this.hostId,
  });

  // Xây dựng danh sách ngang hiển thị avatar những người đang trong phòng.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                'Đang xem (${participants.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final participant = participants[index];
                final isHostUser = participant.id == hostId;
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFF5BA3F5),
                            child:
                                (participant.avatar != null &&
                                    participant.avatar!.isNotEmpty)
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: participant.avatar!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) =>
                                          Text(
                                            participant.name
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                    ),
                                  )
                                : Text(
                                    participant.name
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          if (isHostUser)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.star,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 60,
                        child: Text(
                          participant.name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
