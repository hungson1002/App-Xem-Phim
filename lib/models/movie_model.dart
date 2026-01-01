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
  final String time;
  final String episodeCurrent;
  final String episodeTotal;
  final String quality;
  final String lang;
  final List<String> category;
  final List<String> country;
  final List<String> actor;
  final List<EpisodeServer> episodes;

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
    required this.time,
    required this.episodeCurrent,
    required this.episodeTotal,
    required this.quality,
    required this.lang,
    required this.category,
    required this.country,
    required this.actor,
    this.episodes = const [],
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
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
      time: json['time'] ?? '',
      episodeCurrent: json['episode_current'] ?? '',
      episodeTotal: json['episode_total'] ?? '',
      quality: json['quality'] ?? '',
      lang: json['lang'] ?? '',
      category: parseListNames(json['category']),
      country: parseListNames(json['country']),
      actor: (json['actor'] as List?)?.map((e) => e.toString()).toList() ?? [],
      episodes: (json['episodes'] as List<dynamic>?)
              ?.where((e) => e is Map<String, dynamic>)
              .map((e) => EpisodeServer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <EpisodeServer>[],
    );
  }
}

class EpisodeServer {
  final String serverName;
  final List<Episode> serverData;

  EpisodeServer({
    required this.serverName,
    required this.serverData,
  });

  factory EpisodeServer.fromJson(Map<String, dynamic> json) {
    return EpisodeServer(
      serverName: json['server_name'] ?? '',
      serverData: (json['server_data'] as List<dynamic>?)
              ?.where((e) => e is Map<String, dynamic>)
              .map((e) => Episode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <Episode>[],
    );
  }
}

class Episode {
  final String name;
  final String slug;
  final String filename;
  final String linkEmbed;
  final String linkM3u8;

  Episode({
    required this.name,
    required this.slug,
    required this.filename,
    required this.linkEmbed,
    required this.linkM3u8,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      filename: json['filename'] ?? '',
      linkEmbed: json['link_embed'] ?? '',
      linkM3u8: json['link_m3u8'] ?? '',
    );
  }
}
