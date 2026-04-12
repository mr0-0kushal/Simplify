import 'package:intl/intl.dart';

extension SimplifyDateTimeX on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);
}

abstract final class DateTimeFormatting {
  static final DateFormat _date = DateFormat('EEE, d MMM');
  static final DateFormat _dateTime = DateFormat('EEE, d MMM h:mm a');
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _createdAt = DateFormat('d MMM yyyy');
  static final DateFormat _report = DateFormat('d MMM yyyy, h:mm a');

  static String friendlyDate(DateTime date, {bool includeTime = false}) {
    final DateTime now = DateTime.now();
    final DateTime tomorrow = now.add(const Duration(days: 1));

    if (date.isSameDate(now)) {
      return includeTime ? 'Today at ${_time.format(date)}' : 'Today';
    }

    if (date.isSameDate(tomorrow)) {
      return includeTime ? 'Tomorrow at ${_time.format(date)}' : 'Tomorrow';
    }

    return includeTime ? _dateTime.format(date) : _date.format(date);
  }

  static String onlyTime(DateTime date) => _time.format(date);

  static String createdAtLabel(DateTime date) => _createdAt.format(date);

  static String reportStamp(DateTime date) => _report.format(date);

  static String timeRange(DateTime start, {required int durationMinutes}) {
    final DateTime end = start.add(Duration(minutes: durationMinutes));
    return '${_time.format(start)} - ${_time.format(end)}';
  }
}
