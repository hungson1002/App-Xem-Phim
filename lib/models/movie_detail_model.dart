// Model cho chi tiết phim với danh sách tập và diễn viên.
class MovieDetail {
  final String id;
  final String name;
  final String slug;
  final String originName;
  final String content;
  final String type;
  final String status;
  final int year;
  final String posterUrl;
  final String thumbUrl;
  final String time;
  final String episodeCurrent;
  final String episodeTotal;
  final String quality;
  final String lang;
  final String trailerUrl;
  final List<Category> category;
  final List<String> country;
  final List<String> actors;
  final List<String> directors;
  final List<ServerInfo> episodes;

  MovieDetail({
    required this.id,
    required this.name,
    required this.slug,
    required this.originName,
    required this.content,
    required this.type,
    required this.status,
    required this.year,
    required this.posterUrl,
    required this.thumbUrl,
    required this.time,
    required this.episodeCurrent,
    required this.episodeTotal,
    required this.quality,
    required this.lang,
    required this.trailerUrl,
    required this.category,
    required this.country,
    required this.actors,
    required this.directors,
    required this.episodes,
  });

  factory MovieDetail.fromJson(Map<String, dynamic> json) {
    List<Category> parseCategories(dynamic listData) {
      if (listData == null) return [];
      if (listData is List) {
        return listData.map((item) {
          if (item is Map) {
            return Category.fromJson(item as Map<String, dynamic>);
          }
          return Category(name: item.toString(), slug: '');
        }).toList();
      }
      return [];
    }

    List<String> parseListNames(dynamic listData) {
      if (listData == null) return [];
      if (listData is List) {
        return listData
            .map((item) {
              if (item is Map) {
                return item['name']?.toString() ?? '';
              }
              return item.toString();
            })
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [];
    }

    List<String> parseStringList(dynamic listData) {
      if (listData == null) return [];
      if (listData is List) {
        return listData.map((item) => item.toString()).toList();
      }
      return [];
    }

    List<ServerInfo> parseEpisodes(dynamic episodesData) {
      if (episodesData == null) return [];
      if (episodesData is List) {
        return episodesData
            .map(
              (server) => ServerInfo.fromJson(server as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    }

    return MovieDetail(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      originName: json['origin_name'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      year: json['year'] is int
          ? json['year']
          : int.tryParse(json['year'].toString()) ?? 0,
      posterUrl: json['poster_url'] ?? '',
      thumbUrl: json['thumb_url'] ?? '',
      time: json['time'] ?? '',
      episodeCurrent: json['episode_current'] ?? '',
      episodeTotal: json['episode_total'] ?? '',
      quality: json['quality'] ?? '',
      lang: json['lang'] ?? '',
      trailerUrl: json['trailer_url'] ?? '',
      category: parseCategories(json['category']),
      country: parseListNames(json['country']),
      actors: parseStringList(json['actor']),
      directors: parseStringList(json['director']),
      episodes: parseEpisodes(json['episodes']),
    );
  }
}

class Category {
  final String name;
  final String slug;

  Category({required this.name, required this.slug});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(name: json['name'] ?? '', slug: json['slug'] ?? '');
  }
}

// Model thông tin server.
class ServerInfo {
  final String serverName;
  final List<EpisodeInfo> episodes;

  ServerInfo({required this.serverName, required this.episodes});

  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    return ServerInfo(
      serverName: json['server_name'] ?? '',
      episodes:
          (json['server_data'] as List<dynamic>?)
              ?.map((ep) => EpisodeInfo.fromJson(ep))
              .toList() ??
          [],
    );
  }
}

// Model thông tin tập phim.
class EpisodeInfo {
  final String name;
  final String slug;
  final String filename;
  final String linkEmbed;
  final String linkM3u8;

  EpisodeInfo({
    required this.name,
    required this.slug,
    required this.filename,
    required this.linkEmbed,
    required this.linkM3u8,
  });

  factory EpisodeInfo.fromJson(Map<String, dynamic> json) {
    return EpisodeInfo(
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      filename: json['filename'] ?? '',
      linkEmbed: json['link_embed'] ?? '',
      linkM3u8: json['link_m3u8'] ?? '',
    );
  }
}
