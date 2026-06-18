import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String referralSource;
  final double dailyAvgUsage;
  final List<String> selectedApps;
  final double dailyLimit;
  final String targetLanguage;
  final String languageLevel;
  final int jetons;
  final Timestamp lastJetonReset;
  final int dailyExerciseCount;
  final int dailyRewardedAdCount;
  final int resetHour;
  final int? pendingResetHour;
  final List<String> unlockedLevels;
  final Timestamp createdAt;
  final int totalExercisesCompleted;
  final int totalJetonsEarned;
  final int todaysTotalUsageMinutes;
  // Streak
  final int currentStreak;
  final int longestStreak;
  final Timestamp? lastActiveDate;
  final int bonusMinutes;
  final Map<String, dynamic>? activeChallenge;
  final Map<String, dynamic>? lastChallengeResult;
  final String? lastMiniGameDate;

  UserModel({
    required this.uid,
    required this.name,
    required this.referralSource,
    required this.dailyAvgUsage,
    required this.selectedApps,
    required this.dailyLimit,
    required this.targetLanguage,
    required this.languageLevel,
    required this.jetons,
    required this.lastJetonReset,
    required this.dailyExerciseCount,
    required this.dailyRewardedAdCount,
    required this.resetHour,
    this.pendingResetHour,
    required this.unlockedLevels,
    required this.createdAt,
    this.totalExercisesCompleted = 0,
    this.totalJetonsEarned = 0,
    this.todaysTotalUsageMinutes = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.bonusMinutes = 0,
    this.activeChallenge,
    this.lastChallengeResult,
    this.lastMiniGameDate,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      referralSource: data['referralSource'] ?? '',
      dailyAvgUsage: (data['dailyAvgUsage'] ?? 0).toDouble(),
      selectedApps: List<String>.from(data['selectedApps'] ?? []),
      dailyLimit: (data['dailyLimit'] ?? 0).toDouble(),
      targetLanguage: data['targetLanguage'] ?? '',
      languageLevel: data['languageLevel'] ?? '',
      jetons: data['jetons'] ?? 0,
      lastJetonReset: data['lastJetonReset'] ?? Timestamp.now(),
      dailyExerciseCount: data['dailyExerciseCount'] ?? 0,
      dailyRewardedAdCount: data['dailyRewardedAdCount'] ?? 0,
      resetHour: data['resetHour'] ?? 4,
      pendingResetHour: data['pendingResetHour'],
      unlockedLevels: List<String>.from(data['unlockedLevels'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      totalExercisesCompleted: data['totalExercisesCompleted'] ?? 0,
      totalJetonsEarned: data['totalJetonsEarned'] ?? 0,
      todaysTotalUsageMinutes: data['todaysTotalUsageMinutes'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      lastActiveDate: data['lastActiveDate'],
      bonusMinutes: data['bonusMinutes'] ?? 0,
      activeChallenge: data['activeChallenge'] != null ? Map<String, dynamic>.from(data['activeChallenge']) : null,
      lastChallengeResult: data['lastChallengeResult'] != null ? Map<String, dynamic>.from(data['lastChallengeResult']) : null,
      lastMiniGameDate: data['lastMiniGameDate'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'referralSource': referralSource,
      'dailyAvgUsage': dailyAvgUsage,
      'selectedApps': selectedApps,
      'dailyLimit': dailyLimit,
      'targetLanguage': targetLanguage,
      'languageLevel': languageLevel,
      'jetons': jetons,
      'lastJetonReset': lastJetonReset,
      'dailyExerciseCount': dailyExerciseCount,
      'dailyRewardedAdCount': dailyRewardedAdCount,
      'resetHour': resetHour,
      'pendingResetHour': pendingResetHour,
      'unlockedLevels': unlockedLevels,
      'createdAt': createdAt,
      'totalExercisesCompleted': totalExercisesCompleted,
      'totalJetonsEarned': totalJetonsEarned,
      'todaysTotalUsageMinutes': todaysTotalUsageMinutes,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate,
      'bonusMinutes': bonusMinutes,
      'activeChallenge': activeChallenge,
      'lastChallengeResult': lastChallengeResult,
      'lastMiniGameDate': lastMiniGameDate,
    };
  }

  UserModel copyWith({
    String? name,
    String? referralSource,
    double? dailyAvgUsage,
    List<String>? selectedApps,
    double? dailyLimit,
    String? targetLanguage,
    String? languageLevel,
    int? jetons,
    Timestamp? lastJetonReset,
    int? dailyExerciseCount,
    int? dailyRewardedAdCount,
    int? resetHour,
    int? pendingResetHour,
    List<String>? unlockedLevels,
    int? totalExercisesCompleted,
    int? totalJetonsEarned,
    int? todaysTotalUsageMinutes,
    int? currentStreak,
    int? longestStreak,
    Timestamp? lastActiveDate,
    int? bonusMinutes,
    Map<String, dynamic>? activeChallenge,
    Map<String, dynamic>? lastChallengeResult,
    String? lastMiniGameDate,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      referralSource: referralSource ?? this.referralSource,
      dailyAvgUsage: dailyAvgUsage ?? this.dailyAvgUsage,
      selectedApps: selectedApps ?? this.selectedApps,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      languageLevel: languageLevel ?? this.languageLevel,
      jetons: jetons ?? this.jetons,
      lastJetonReset: lastJetonReset ?? this.lastJetonReset,
      dailyExerciseCount: dailyExerciseCount ?? this.dailyExerciseCount,
      dailyRewardedAdCount: dailyRewardedAdCount ?? this.dailyRewardedAdCount,
      resetHour: resetHour ?? this.resetHour,
      pendingResetHour: pendingResetHour ?? this.pendingResetHour,
      unlockedLevels: unlockedLevels ?? this.unlockedLevels,
      createdAt: createdAt,
      totalExercisesCompleted: totalExercisesCompleted ?? this.totalExercisesCompleted,
      totalJetonsEarned: totalJetonsEarned ?? this.totalJetonsEarned,
      todaysTotalUsageMinutes: todaysTotalUsageMinutes ?? this.todaysTotalUsageMinutes,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      bonusMinutes: bonusMinutes ?? this.bonusMinutes,
      activeChallenge: activeChallenge ?? this.activeChallenge,
      lastChallengeResult: lastChallengeResult ?? this.lastChallengeResult,
      lastMiniGameDate: lastMiniGameDate ?? this.lastMiniGameDate,
    );
  }
}
