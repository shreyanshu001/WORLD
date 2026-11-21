/// Why someone reports a World. The wire values match the list the database
/// accepts.
enum ReportReason {
  unsafeOrPrivatePlace(
    'unsafe_or_private_place',
    'Unsafe or private place',
    'It is on private property, somewhere restricted or somewhere risky.',
  ),
  harassmentOrHate(
    'harassment_or_hate',
    'Harassment or hate',
    'It targets or demeans a person or a group.',
  ),
  sexualContent(
    'sexual_content',
    'Sexual content',
    'It contains sexual or exploitative material.',
  ),
  dangerousActivity(
    'dangerous_activity',
    'Dangerous challenge',
    'It asks people to do something that could hurt them.',
  ),
  spamOrMisleading(
    'spam_or_misleading',
    'Spam or misleading',
    'It advertises, repeats itself or is not what it says.',
  ),
  other('other', 'Something else', 'Tell us what is wrong below.');

  const ReportReason(this.wire, this.label, this.explanation);

  final String wire;
  final String label;
  final String explanation;
}

/// What happened to a report.
enum ReportOutcome {
  /// Recorded for review.
  sent,

  /// This account already has a report of this World waiting for review.
  alreadyReported,
}

/// The limits the server enforces, mirrored for quick feedback.
abstract final class ReportRules {
  static const maxDetailsLength = 500;
}
