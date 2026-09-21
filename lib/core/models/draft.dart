class CachedRecording {
  final String path;
  bool muted;
  final int createdAt;

  CachedRecording({
    required this.path,
    this.muted = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'muted': muted,
        'createdAt': createdAt,
      };

  factory CachedRecording.fromJson(Map<String, dynamic> json) => CachedRecording(
        path: json['path'] as String,
        muted: json['muted'] as bool? ?? true,
        createdAt: json['createdAt'] as int,
      );
}
/// Draft model
class Draft {
  final String id;
  String name;
  String? instrumentalPath;
  int? instrumentalDurationMs;
  double? bpm;
  String lyricText;
  final int createdAt;
  int updatedAt;
  List<CachedRecording> cachedRecordings;

  Draft({
    required this.id,
    required this.name,
    this.instrumentalPath,
    this.instrumentalDurationMs,
    this.bpm,
    this.lyricText = '',
    required this.createdAt,
    required this.updatedAt,
    List<CachedRecording>? cachedRecordings,
  }) : cachedRecordings = cachedRecordings ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'instrumentalPath': instrumentalPath,
        'instrumentalDurationMs': instrumentalDurationMs,
        'bpm': bpm,
        'lyricText': lyricText,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'cachedRecordings': cachedRecordings.map((r) => r.toJson()).toList(),
      };

  factory Draft.fromJson(Map<String, dynamic> json) => Draft(
        id: json['id'] as String,
        name: json['name'] as String,
        instrumentalPath: json['instrumentalPath'] as String?,
        instrumentalDurationMs: json['instrumentalDurationMs'] as int?,
        bpm: (json['bpm'] as num?)?.toDouble(),
        lyricText: json['lyricText'] as String? ?? '',
        createdAt: json['createdAt'] as int,
        updatedAt: json['updatedAt'] as int,
        cachedRecordings: (json['cachedRecordings'] as List<dynamic>?)
                ?.map((e) => CachedRecording.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}