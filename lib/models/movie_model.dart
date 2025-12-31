class Movie {
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
  final String webpPoster;
  final String webpThumb;
  final String time;
  final String episodeCurrent;
  final String quality;
  final String lang;
  final List<String> category;
  final List<String> country;
  final List<Episode> episodes;

  Movie({
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
    required this.webpPoster,
    required this.webpThumb,
    required this.time,
    required this.episodeCurrent,
    required this.quality,
    required this.lang,
    required this.category,
    required this.country,
    required this.episodes,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse lists of objects or strings to just a list of names/slugs if needed.
    // Based on server model, category is object list {id, name, slug}.
    // For simple UI display we might just want the names.
    
    List<String> parseListNames(dynamic listData) {
      if (listData == null) return [];
      if (listData is List) {
        return listData.map((item) {
          if (item is Map) {
             return item['name']?.toString() ?? ''; 
          }
          return item.toString();
        }).toList();
      }
      return [];
    }

    return Movie(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      originName: json['origin_name'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      year: json['year'] is int ? json['year'] : int.tryParse(json['year'].toString()) ?? 0,
      posterUrl: json['poster_url'] ?? '',
      thumbUrl: json['thumb_url'] ?? '',
      webpPoster: json['webp_poster'] ?? '',
      webpThumb: json['webp_thumb'] ?? '',
      time: json['time'] ?? '',
      episodeCurrent: json['episode_current'] ?? '',
      quality: json['quality'] ?? '',
      lang: json['lang'] ?? '',
      category: parseListNames(json['category']),
      country: parseListNames(json['country']),
      episodes: (json['episodes'] as List<dynamic>?)
          ?.map((episode) => Episode.fromJson(episode))
          .toList() ?? [],
    );
  }
}

class Episode {
  final String serverName;
  final List<ServerData> serverData;

  Episode({
    required this.serverName,
    required this.serverData,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      serverName: json['server_name'] ?? '',
      serverData: (json['server_data'] as List<dynamic>?)
          ?.map((data) => ServerData.fromJson(data))
          .toList() ?? [],
    );
  }
}

class ServerData {
  final String name;
  final String slug;
  final String filename;
  final String linkEmbed;
  final String linkM3u8;

  ServerData({
    required this.name,
    required this.slug,
    required this.filename,
    required this.linkEmbed,
    required this.linkM3u8,
  });

  factory ServerData.fromJson(Map<String, dynamic> json) {
    return ServerData(
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      filename: json['filename'] ?? '',
      linkEmbed: json['link_embed'] ?? '',
      linkM3u8: json['link_m3u8'] ?? '',
    );
  }
}
