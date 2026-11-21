import 'package:worlds/features/worlds/domain/content_block.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';
import 'package:worlds/shared/models/world_category.dart';

/// Why a World cannot be published yet. [wire] matches the codes returned by
/// the server's `publish_world`, which checks the same rules again.
enum PublishProblemCode {
  titleInvalid('title_invalid'),
  descriptionRequired('description_required'),
  locationRequired('location_required'),
  contentRequired('content_required'),
  questionRequired('question_required'),
  artworkRequired('artwork_required'),
  textRequired('text_required'),
  blockNotAllowed('block_not_allowed'),
  blockIncomplete('block_incomplete'),
  answerRequired('answer_required'),
  choiceDestinationInvalid('choice_destination_invalid'),
  unknown('unknown');

  const PublishProblemCode(this.wire);

  final String wire;

  static PublishProblemCode fromWire(String value) {
    for (final code in values) {
      if (code.wire == value) return code;
    }
    return unknown;
  }
}

/// One reason a World cannot be published, optionally about one block.
class PublishProblem {
  const PublishProblem(this.code, {this.blockId});

  final PublishProblemCode code;
  final String? blockId;

  @override
  bool operator ==(Object other) =>
      other is PublishProblem && other.code == code && other.blockId == blockId;

  @override
  int get hashCode => Object.hash(code, blockId);

  @override
  String toString() => 'PublishProblem(${code.wire}, $blockId)';
}

/// The content rules, matching the database checks in
/// `supabase/migrations/20261120090000_create_world_authoring.sql`. The app
/// checks them for quick feedback; the server is the authority.
abstract final class WorldRules {
  static const titleMin = 3;
  static const titleMax = 80;
  static const descriptionMax = 2000;
  static const radiusMin = 25;
  static const radiusMax = 150;
  static const maxBlocks = 30;
  static const textMax = 2000;
  static const captionMax = 200;
  static const choicePromptMax = 300;
  static const choiceLabelMax = 80;
  static const minOptions = 2;
  static const maxOptions = 4;
  static const questionPromptMax = 500;
  static const hintMax = 300;
  static const successMessageMax = 300;
  static const answerMax = 100;
  static const artworkTitleMax = 80;
  static const artworkDescriptionMax = 2000;
  static const completionTitleMax = 80;
  static const completionMessageMax = 1000;

  /// Block types each category may use (docs/PRODUCT_SPEC.md section 5).
  static List<BlockType> allowedBlocks(WorldCategory category) =>
      switch (category) {
        WorldCategory.story => const [
          BlockType.text,
          BlockType.image,
          BlockType.storyChoice,
          BlockType.completion,
        ],
        WorldCategory.puzzle => const [
          BlockType.text,
          BlockType.image,
          BlockType.question,
          BlockType.completion,
        ],
        WorldCategory.art => const [
          BlockType.artwork,
          BlockType.text,
          BlockType.image,
          BlockType.completion,
        ],
        WorldCategory.experience => BlockType.values,
      };

  /// Null if [title] can be saved, otherwise what is wrong.
  static String? titleError(String title) {
    final trimmed = title.trim();
    if (trimmed.length < titleMin) {
      return 'Give your World a title of at least $titleMin characters.';
    }
    if (trimmed.length > titleMax) {
      return 'Keep the title to $titleMax characters or fewer.';
    }
    return null;
  }

  static String? descriptionError(String description) =>
      description.length > descriptionMax
      ? 'Keep the description to $descriptionMax characters or fewer.'
      : null;

  /// Null if [answer] can be stored, otherwise what is wrong.
  static String? answerError(String answer) {
    final normalized = answer.trim();
    if (normalized.isEmpty) return 'Enter the answer explorers must give.';
    if (normalized.length > answerMax) {
      return 'Keep the answer to $answerMax characters or fewer.';
    }
    return null;
  }

  /// Every reason [draft] cannot be published, in the order the server
  /// reports them. [pendingAnswerIds] are questions whose answer the editor
  /// will send with the next save.
  static List<PublishProblem> publishProblems(
    WorldDraft draft, {
    Set<String> pendingAnswerIds = const {},
  }) {
    final problems = <PublishProblem>[];
    final blocks = draft.blocks;

    if (titleError(draft.title) != null) {
      problems.add(const PublishProblem(PublishProblemCode.titleInvalid));
    }
    if (draft.description.trim().isEmpty) {
      problems.add(
        const PublishProblem(PublishProblemCode.descriptionRequired),
      );
    }
    if (draft.location == null) {
      problems.add(const PublishProblem(PublishProblemCode.locationRequired));
    }
    if (!blocks.any((block) => block is! CompletionBlock)) {
      problems.add(const PublishProblem(PublishProblemCode.contentRequired));
    }
    switch (draft.category) {
      case WorldCategory.puzzle when !blocks.any((b) => b is QuestionBlock):
        problems.add(const PublishProblem(PublishProblemCode.questionRequired));
      case WorldCategory.art when !blocks.any((b) => b is ArtworkBlock):
        problems.add(const PublishProblem(PublishProblemCode.artworkRequired));
      case WorldCategory.story when !blocks.any((b) => b is TextBlock):
        problems.add(const PublishProblem(PublishProblemCode.textRequired));
      default:
        break;
    }

    final allowed = allowedBlocks(draft.category);
    for (var index = 0; index < blocks.length; index++) {
      final block = blocks[index];
      if (!allowed.contains(block.type)) {
        problems.add(
          PublishProblem(PublishProblemCode.blockNotAllowed, blockId: block.id),
        );
        continue;
      }
      if (_incomplete(block)) {
        problems.add(
          PublishProblem(PublishProblemCode.blockIncomplete, blockId: block.id),
        );
      }
      if (block is QuestionBlock &&
          !block.hasAnswer &&
          !pendingAnswerIds.contains(block.id)) {
        problems.add(
          PublishProblem(PublishProblemCode.answerRequired, blockId: block.id),
        );
      }
      if (block is StoryChoiceBlock) {
        final invalid = block.options.any((option) {
          final destination = option.destinationBlockId;
          if (destination == null) return false;
          final target = blocks.indexWhere((b) => b.id == destination);
          return target <= index;
        });
        if (invalid) {
          problems.add(
            PublishProblem(
              PublishProblemCode.choiceDestinationInvalid,
              blockId: block.id,
            ),
          );
        }
      }
    }
    return problems;
  }

  static bool _incomplete(ContentBlock block) {
    bool blank(String value) => value.trim().isEmpty;
    return switch (block) {
      TextBlock(:final body) => blank(body),
      ImageBlock(:final assetId) => assetId == null,
      StoryChoiceBlock(:final prompt, :final options) =>
        blank(prompt) ||
            options.length < minOptions ||
            options.any((o) => blank(o.label) || o.destinationBlockId == null),
      QuestionBlock(:final prompt) => blank(prompt),
      ArtworkBlock(:final assetId, :final title, :final description) =>
        assetId == null || blank(title) || blank(description),
      CompletionBlock(:final title, :final message) =>
        blank(title) || blank(message),
    };
  }

  /// Blocks a choice at [index] may lead to: only later blocks, so every
  /// path moves towards an end.
  static List<ContentBlock> destinationsAfter(
    List<ContentBlock> blocks,
    int index,
  ) => blocks.sublist(index + 1);
}
