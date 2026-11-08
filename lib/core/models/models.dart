enum PlayerPosition { attack, midfield, defense, goalkeeper }

class User {
  final String id;
  final String username;
  final String avatarUrl;
  final int coins;
  final int globalRank;
  final int rankingPoints;
  final int totalGames;
  final int wins;
  final int totalCoinsEarned;
  final String role;

  User({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.coins,
    required this.globalRank,
    required this.rankingPoints,
    required this.totalGames,
    required this.wins,
    required this.totalCoinsEarned,
    this.role = 'user',
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  String get winRate => totalGames > 0 ? ((wins / totalGames) * 100).toStringAsFixed(0) : '0';

  User copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    int? coins,
    int? globalRank,
    int? rankingPoints,
    int? totalGames,
    int? wins,
    int? totalCoinsEarned,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coins: coins ?? this.coins,
      globalRank: globalRank ?? this.globalRank,
      rankingPoints: rankingPoints ?? this.rankingPoints,
      totalGames: totalGames ?? this.totalGames,
      wins: wins ?? this.wins,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      role: role ?? this.role,
    );
  }
}

class AdModel {
  final String id;
  final String title;
  final String? description;
  final String videoUrl;
  final String? linkUrl;
  final int rewardCoins;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final int viewsCount;
  final int completionsCount;
  final bool isExpired;
  final bool isEffectiveActive;

  AdModel({
    required this.id,
    required this.title,
    this.description,
    required this.videoUrl,
    this.linkUrl,
    this.rewardCoins = 500,
    this.isActive = true,
    this.startDate,
    this.endDate,
    this.viewsCount = 0,
    this.completionsCount = 0,
    this.isExpired = false,
    this.isEffectiveActive = true,
  });

  factory AdModel.fromJson(Map<String, dynamic> json) {
    final startStr = json['startDate'];
    final endStr = json['endDate'];
    final startDate = startStr != null ? DateTime.tryParse(startStr.toString()) : null;
    final endDate = endStr != null ? DateTime.tryParse(endStr.toString()) : null;

    final bool expired = json['isExpired'] ?? (endDate != null && DateTime.now().isAfter(endDate));
    final bool active = json['isActive'] ?? true;
    final bool effective = json['isEffectiveActive'] ??
        (active && !expired && (startDate == null || DateTime.now().isAfter(startDate)));

    return AdModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      videoUrl: json['videoUrl'] ?? '',
      linkUrl: json['linkUrl'],
      rewardCoins: json['rewardCoins'] ?? 500,
      isActive: active,
      startDate: startDate,
      endDate: endDate,
      viewsCount: json['viewsCount'] ?? 0,
      completionsCount: json['completionsCount'] ?? 0,
      isExpired: expired,
      isEffectiveActive: effective,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (description != null) 'description': description,
      'videoUrl': videoUrl,
      if (linkUrl != null) 'linkUrl': linkUrl,
      'rewardCoins': rewardCoins,
      'isActive': isActive,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
    };
  }
}

class FootballPlayer {
  final String id;
  final String name;
  final String teamName;
  final String teamLogo;
  final PlayerPosition position;
  final int currentPoints;
  final double points;
  
  // Detailed stats
  final int goals;
  final int assists;
  final int bigChances;
  final int passes;
  final int failedPasses;
  final int tackles;
  final int yellowCards;
  final int redCards;
  final int cleanSheet; // for defense/gk
  final int saves; // for gk

  FootballPlayer({
    required this.id,
    required this.name,
    required this.teamName,
    required this.teamLogo,
    required this.position,
    this.currentPoints = 0,
    this.points = 0.0,
    this.goals = 0,
    this.assists = 0,
    this.bigChances = 0,
    this.passes = 0,
    this.failedPasses = 0,
    this.tackles = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.cleanSheet = 0,
    this.saves = 0,
  });
}

class LiveEvent {
  final String id;
  final String title;
  final String playerName;
  final int pointsDelta;
  final String time;

  LiveEvent({
    required this.id,
    required this.title,
    required this.playerName,
    required this.pointsDelta,
    required this.time,
  });
}

class Match {
  final String id;
  final String competitionId;
  final String competition;
  final String homeTeamId;
  final String homeTeam;
  final String awayTeamId;
  final String awayTeam;
  final String homeLogo;
  final String awayLogo;
  final String matchTime;
  final bool isLive;
  final int homeScore;
  final int awayScore;
  final String liveMinute;
  final String status;

  Match({
    required this.id,
    this.competitionId = '',
    required this.competition,
    this.homeTeamId = '',
    required this.homeTeam,
    this.awayTeamId = '',
    required this.awayTeam,
    required this.homeLogo,
    required this.awayLogo,
    required this.matchTime,
    this.isLive = false,
    this.homeScore = 0,
    this.awayScore = 0,
    this.liveMinute = '',
    this.status = '',
  });
}
