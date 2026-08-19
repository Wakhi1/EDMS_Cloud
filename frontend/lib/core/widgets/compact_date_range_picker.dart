import 'package:flutter/material.dart';

/// A small, no-frills date-range picker for filter bars — two short trips
/// through a bare [CalendarDatePicker] in a fixed-size dialog, instead of
/// [showDateRangePicker]'s large two-pane picker (which, sized for "set my
/// vacation dates," is disproportionate for narrowing a records/audit
/// filter). Returns null if either step is cancelled.
Future<DateTimeRange?> showCompactDateRangePicker(
  BuildContext context, {
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? initialFrom,
  DateTime? initialTo,
}) async {
  final from = await _pickOneDate(
    context,
    title: 'From date',
    firstDate: firstDate,
    lastDate: lastDate,
    initial: initialFrom ?? lastDate,
  );
  if (from == null || !context.mounted) return null;

  final to = await _pickOneDate(
    context,
    title: 'To date',
    firstDate: from,
    lastDate: lastDate,
    initial: (initialTo != null && !initialTo.isBefore(from) && !initialTo.isAfter(lastDate)) ? initialTo : lastDate,
  );
  if (to == null) return null;

  return DateTimeRange(start: from, end: to);
}

Future<DateTime?> _pickOneDate(
  BuildContext context, {
  required String title,
  required DateTime firstDate,
  required DateTime lastDate,
  required DateTime initial,
}) {
  var selected = initial;
  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      content: SizedBox(
        width: 300,
        height: 320,
        child: CalendarDatePicker(
          initialDate: initial,
          firstDate: firstDate,
          lastDate: lastDate,
          onDateChanged: (d) => selected = d,
        ),
      ),
      actionsPadding: const EdgeInsets.all(8),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(selected), child: const Text('Select')),
      ],
    ),
  );
}
