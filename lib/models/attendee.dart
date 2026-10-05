import 'package:flutter/widgets.dart';

/// One attendee entry in a trial's pre-trial details.
class Attendee {
  Attendee({String firstName = '', String lastName = '', String company = ''})
    : firstName = TextEditingController(text: firstName),
      lastName = TextEditingController(text: lastName),
      company = TextEditingController(text: company);

  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController company;

  void dispose() {
    firstName.dispose();
    lastName.dispose();
    company.dispose();
  }

  bool get isEmpty => firstName.text.isEmpty && lastName.text.isEmpty && company.text.isEmpty;

  // Tagged format so parseAttendeesText can rebuild the fields whatever's in the names.
  String toText() {
    final parts = [
      if (firstName.text.isNotEmpty) 'First name: ${firstName.text}',
      if (lastName.text.isNotEmpty) 'Last name: ${lastName.text}',
      if (company.text.isNotEmpty) 'Company: ${company.text}',
    ];
    return parts.join(', ');
  }

  // Display only, never parsed back.
  String toDisplayText() {
    final name = [firstName.text, lastName.text].where((s) => s.isNotEmpty).join(' ');
    final companyText = company.text;
    if (name.isEmpty) return companyText;
    if (companyText.isEmpty) return name;
    return '$name ($companyText)';
  }
}

/// Parses the stored `attendees` string back into entries. Lines in an older
/// free-text format are kept whole in the company field so nothing is lost.
List<Attendee> parseAttendeesText(String raw) {
  final lines = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
  if (lines.isEmpty) return [Attendee()];

  return lines.map((line) {
    var firstName = '';
    var lastName = '';
    var company = '';
    var matched = false;
    for (final part in line.split(', ')) {
      if (part.startsWith('First name: ')) {
        firstName = part.substring('First name: '.length);
        matched = true;
      } else if (part.startsWith('Last name: ')) {
        lastName = part.substring('Last name: '.length);
        matched = true;
      } else if (part.startsWith('Company: ')) {
        company = part.substring('Company: '.length);
        matched = true;
      }
    }
    if (!matched) {
      company = line.trim();
    }
    return Attendee(firstName: firstName, lastName: lastName, company: company);
  }).toList();
}

/// Stored attendees string to display text, one per line, e.g. "Ellis Bailey (ABC)".
String formatAttendeesForDisplay(String raw) {
  return parseAttendeesText(
    raw,
  ).map((a) => a.toDisplayText()).where((s) => s.isNotEmpty).join('\n');
}
