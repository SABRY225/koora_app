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
  });
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
