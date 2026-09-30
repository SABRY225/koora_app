import '../models/models.dart';

class MockData {
  static final User currentUser = User(
    id: 'u1',
    username: 'KooraMaster',
    avatarUrl: '',
    coins: 500,
    globalRank: 12450,
    rankingPoints: 45,
    totalGames: 24,
    wins: 8,
    totalCoinsEarned: 12500,
  );

  static final List<Match> upcomingMatches = [
    Match(
      id: 'm2',
      competition: 'English Premier League',
      homeTeam: 'Arsenal',
      awayTeam: 'Man City',
      homeLogo: 'ARS',
      awayLogo: 'MCI',
      matchTime: 'Tomorrow, 19:30',
    ),
    Match(
      id: 'm3',
      competition: 'Saudi Pro League',
      homeTeam: 'Al Nassr',
      awayTeam: 'Al Hilal',
      homeLogo: 'NAS',
      awayLogo: 'HIL',
      matchTime: 'Friday, 21:00',
    ),
  ];

  static final Match liveMatch = Match(
    id: 'm1',
    competition: 'La Liga',
    homeTeam: 'Barcelona',
    awayTeam: 'Real Madrid',
    homeLogo: 'BAR',
    awayLogo: 'RMA',
    matchTime: 'Today, 22:00',
    isLive: true,
    homeScore: 2,
    awayScore: 1,
    liveMinute: '67:42',
  );

  static final List<FootballPlayer> availablePlayers = [
    FootballPlayer(
      id: 'p1',
      name: 'Vinicius Jr',
      teamName: 'Real Madrid',
      teamLogo: 'RMA',
      position: PlayerPosition.attack,
      currentPoints: 45,
    ),
    FootballPlayer(
      id: 'p2',
      name: 'Robert Lewandowski',
      teamName: 'Barcelona',
      teamLogo: 'BAR',
      position: PlayerPosition.attack,
      currentPoints: 60,
    ),
    FootballPlayer(
      id: 'p3',
      name: 'Jude Bellingham',
      teamName: 'Real Madrid',
      teamLogo: 'RMA',
      position: PlayerPosition.midfield,
      currentPoints: 20,
    ),
    FootballPlayer(
      id: 'p4',
      name: 'Pedri',
      teamName: 'Barcelona',
      teamLogo: 'BAR',
      position: PlayerPosition.midfield,
      currentPoints: 35,
    ),
    FootballPlayer(
      id: 'p5',
      name: 'Antonio Rudiger',
      teamName: 'Real Madrid',
      teamLogo: 'RMA',
      position: PlayerPosition.defense,
      currentPoints: 10,
    ),
    FootballPlayer(
      id: 'p6',
      name: 'Ronald Araujo',
      teamName: 'Barcelona',
      teamLogo: 'BAR',
      position: PlayerPosition.defense,
      currentPoints: 12,
    ),
    FootballPlayer(
      id: 'p7',
      name: 'Thibaut Courtois',
      teamName: 'Real Madrid',
      teamLogo: 'RMA',
      position: PlayerPosition.goalkeeper,
      currentPoints: 20,
    ),
    FootballPlayer(
      id: 'p8',
      name: 'Marc-Andre ter Stegen',
      teamName: 'Barcelona',
      teamLogo: 'BAR',
      position: PlayerPosition.goalkeeper,
      currentPoints: 30,
    ),
  ];
}
