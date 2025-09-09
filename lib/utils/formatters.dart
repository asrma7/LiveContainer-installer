import 'dart:math';

String formatFileSize(int sizeInBytes) {
  if (sizeInBytes <= 0) return '0 KB';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];

  int i = (log(sizeInBytes) / log(1024)).floor();
  double size = sizeInBytes / pow(1024, i);

  return '${size.toStringAsFixed(2)} ${suffixes[i]}';
}

const List<String> _months = [
  '',
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatVersionDate(String dateStr) {
  try {
    DateTime date = DateTime.parse(dateStr);
    return "${_months[date.month]} ${date.day}, ${date.year}";
  } catch (e) {
    return dateStr;
  }
}

String timeAgo(String dateStr) {
  try {
    DateTime date = DateTime.parse(dateStr);
    Duration diff = DateTime.now().difference(date);

    if (diff.inDays >= 365) {
      int years = (diff.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (diff.inDays >= 30) {
      int months = (diff.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (diff.inDays >= 1) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  } catch (e) {
    return dateStr;
  }
}
