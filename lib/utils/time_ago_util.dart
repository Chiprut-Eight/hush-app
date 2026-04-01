import 'package:hush_app/l10n/app_localizations.dart';

/// Returns a human-readable relative time string for the given [dateTime].
/// Shows exactly one time unit: seconds, minutes, hours, days, weeks, months, or years.
String getTimeAgo(DateTime dateTime, AppLocalizations l10n) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inSeconds < 60) {
    return l10n.timeAgoSeconds(diff.inSeconds < 1 ? 1 : diff.inSeconds);
  } else if (diff.inMinutes < 60) {
    return l10n.timeAgoMinutes(diff.inMinutes);
  } else if (diff.inHours < 24) {
    return l10n.timeAgoHours(diff.inHours);
  } else if (diff.inDays < 7) {
    return l10n.timeAgoDays(diff.inDays);
  } else if (diff.inDays < 30) {
    return l10n.timeAgoWeeks(diff.inDays ~/ 7);
  } else if (diff.inDays < 365) {
    return l10n.timeAgoMonths(diff.inDays ~/ 30);
  } else {
    return l10n.timeAgoYears(diff.inDays ~/ 365);
  }
}
