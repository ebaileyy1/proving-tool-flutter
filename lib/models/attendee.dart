import 'package:flutter/widgets.dart';

/// One attendee entry in a trial's pre-trial details. Shared by the Add
/// and Edit trial forms so both render the same structured
/// first/last/company fields instead of one drifting into a flat
/// free-text box.
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

  bool get isEmpty =>
      firstName.text.isEmpty && lastName.text.isEmpty && company.text.isEmpty;

  String toText() {
    final parts = [
      if (firstName.text.isNotEmpty) 'First name: ${firstName.text}',
      if (lastName.text.isNotEmpty) 'Last name: ${lastName.text}',
      if (company.text.isNotEmpty) 'Company: ${company.text}',
    ];
    return parts.join(', ');
  }
}

/// Turns the newline-joined string `Attendee.toText()` produces (and that
/// the `attendees` column stores) back into structured entries. A line
/// that doesn't match the expected "First name: X, Last name: Y, Company:
/// Z" shape is preserved verbatim in the company field rather than
/// dropped, so editing a trial created before this parser existed never
/// loses data.
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
    return Attendee(
      firstName: firstName,
      lastName: lastName,
      company: company,
    );
  }).toList();
}
