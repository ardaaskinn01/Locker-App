import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppDateUtils {
  /// Returns today's date as a string key: 'yyyy-MM-dd'
  static String todayKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// Checks if a reset is due based on the last reset time and the reset hour.
  /// A reset is due if:
  /// 1. Current time is AFTER the reset hour.
  /// 2. Last reset happened BEFORE the last occurrence of the reset hour.
  static bool isResetDue(Timestamp lastResetTimestamp, int resetHour) {
    final now = DateTime.now();
    final lastReset = lastResetTimestamp.toDate();
    
    // Create a DateTime object for the reset time today
    final resetTimeToday = DateTime(now.year, now.month, now.day, resetHour);
    
    // If it hasn't reached the reset hour today, check against yesterday's reset time
    if (now.isBefore(resetTimeToday)) {
      final resetTimeYesterday = resetTimeToday.subtract(const Duration(days: 1));
      return lastReset.isBefore(resetTimeYesterday);
    }
    
    // If it's already past the reset hour today, reset if the last reset was before today's reset hour
    return lastReset.isBefore(resetTimeToday);
  }
}
