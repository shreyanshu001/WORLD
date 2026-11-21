import 'package:freezed_annotation/freezed_annotation.dart';

part 'content_block.freezed.dart';

/// The six supported block types (docs/PRODUCT_SPEC.md section 5). [wire]
/// matches the database's `block_type` column.
enum BlockType {
  text('text', 'Text', 'A passage of writing.'),
  image('image', 'Image', 'A photo with an optional caption.'),
  storyChoice(
    'story_choice',
    'Choice',
    'Let the reader choose where the story goes next.',
  ),
  question(
    'question',
    'Question',
    'A puzzle question with an answer only the server knows.',
  ),
  artwork('artwork', 'Artwork', 'An image with its title and context.'),
  completion(
    'completion',
    'Ending',
    'Ends the experience, or this branch of the story.',
  );

  const BlockType(this.wire, this.label, this.description);

  final String wire;
  final String label;
  final String description;

  static BlockType? fromWire(String value) {
    for (final type in values) {
      if (type.wire == value) return type;
    }
    return null;
  }
}

/// One typed, validated piece of a World's content. Blank fields are allowed
/// while drafting; publishing requires them.
///
/// A question's answer is never part of this model: the editor sends it to
/// the server once, and afterwards only [QuestionBlock.hasAnswer] is known.
@freezed
sealed class ContentBlock with _$ContentBlock {
  const ContentBlock._();

  const factory ContentBlock.text({
    required String id,
    @Default('') String body,
  }) = TextBlock;

  const factory ContentBlock.image({
    required String id,
    String? assetId,
    @Default('') String caption,
  }) = ImageBlock;

  const factory ContentBlock.storyChoice({
    required String id,
    @Default('') String prompt,
    @Default(<StoryOption>[]) List<StoryOption> options,
  }) = StoryChoiceBlock;

  const factory ContentBlock.question({
    required String id,
    @Default('') String prompt,
    @Default('') String hint,
    @Default('') String successMessage,

    /// Whether the server holds an answer for this question.
    @Default(false) bool hasAnswer,
  }) = QuestionBlock;

  const factory ContentBlock.artwork({
    required String id,
    String? assetId,
    @Default('') String title,
    @Default('') String description,
  }) = ArtworkBlock;

  const factory ContentBlock.completion({
    required String id,
    @Default('') String title,
    @Default('') String message,
    String? assetId,
  }) = CompletionBlock;

  BlockType get type => switch (this) {
    TextBlock() => BlockType.text,
    ImageBlock() => BlockType.image,
    StoryChoiceBlock() => BlockType.storyChoice,
    QuestionBlock() => BlockType.question,
    ArtworkBlock() => BlockType.artwork,
    CompletionBlock() => BlockType.completion,
  };

  /// The image this block shows, if any.
  String? get imageAssetId => switch (this) {
    ImageBlock(:final assetId) ||
    ArtworkBlock(:final assetId) ||
    CompletionBlock(:final assetId) => assetId,
    _ => null,
  };
}

/// One choice in a [StoryChoiceBlock], leading to a later block.
@freezed
abstract class StoryOption with _$StoryOption {
  const factory StoryOption({
    required String id,
    @Default('') String label,
    String? destinationBlockId,
  }) = _StoryOption;
}
