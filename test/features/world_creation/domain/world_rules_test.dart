import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';
import 'package:worlds/features/world_creation/domain/world_rules.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

void main() {
  const place = GeoPoint(latitude: 51.5, longitude: -0.12);

  WorldDraft draft(
    WorldCategory category,
    List<ContentBlock> blocks, {
    String title = 'Harbour Walk',
    String description = 'A walk.',
    GeoPoint? location = place,
  }) => WorldDraft(
    id: 'w',
    category: category,
    title: title,
    description: description,
    location: location,
    blocks: blocks,
  );

  List<PublishProblemCode> codes(List<PublishProblem> problems) => [
    for (final p in problems) p.code,
  ];

  group('publishProblems', () {
    test('a complete story has none', () {
      final problems = WorldRules.publishProblems(
        draft(WorldCategory.story, const [
          ContentBlock.text(id: 't', body: 'Once upon a time.'),
          ContentBlock.completion(id: 'c', title: 'End', message: 'Bye.'),
        ]),
      );
      expect(problems, isEmpty);
    });

    test('missing description, place and content are reported', () {
      final problems = WorldRules.publishProblems(
        draft(
          WorldCategory.experience,
          const [ContentBlock.completion(id: 'c', title: 'End', message: 'x')],
          description: '  ',
          location: null,
        ),
      );
      expect(codes(problems), [
        PublishProblemCode.descriptionRequired,
        PublishProblemCode.locationRequired,
        PublishProblemCode.contentRequired,
      ]);
    });

    test('a short title is reported', () {
      final problems = WorldRules.publishProblems(
        draft(WorldCategory.story, const [
          ContentBlock.text(id: 't', body: 'x'),
        ], title: ' ab '),
      );
      expect(codes(problems), [PublishProblemCode.titleInvalid]);
    });

    test('each category needs its kind of part', () {
      const text = ContentBlock.text(id: 't', body: 'x');
      expect(
        codes(WorldRules.publishProblems(draft(WorldCategory.puzzle, [text]))),
        [PublishProblemCode.questionRequired],
      );
      expect(
        codes(WorldRules.publishProblems(draft(WorldCategory.art, [text]))),
        [PublishProblemCode.artworkRequired],
      );
      expect(
        codes(
          WorldRules.publishProblems(
            draft(WorldCategory.story, const [
              ContentBlock.image(id: 'i', assetId: 'a'),
            ]),
          ),
        ),
        [PublishProblemCode.textRequired],
      );
    });

    test('a question needs an answer, saved or about to be sent', () {
      final world = draft(WorldCategory.puzzle, const [
        ContentBlock.question(id: 'q', prompt: 'Who lived here?'),
      ]);
      expect(WorldRules.publishProblems(world), [
        const PublishProblem(PublishProblemCode.answerRequired, blockId: 'q'),
      ]);
      expect(
        WorldRules.publishProblems(world, pendingAnswerIds: {'q'}),
        isEmpty,
      );
      expect(
        WorldRules.publishProblems(
          world.copyWith(
            blocks: const [
              ContentBlock.question(id: 'q', prompt: 'Who?', hasAnswer: true),
            ],
          ),
        ),
        isEmpty,
      );
    });

    test('choices must lead forward and be complete', () {
      ContentBlock choice(String? first, String? second) =>
          ContentBlock.storyChoice(
            id: 'choice',
            prompt: 'Which way?',
            options: [
              StoryOption(id: 'o1', label: 'Left', destinationBlockId: first),
              StoryOption(id: 'o2', label: 'Right', destinationBlockId: second),
            ],
          );
      List<ContentBlock> story(ContentBlock c) => [
        const ContentBlock.text(id: 'intro', body: 'A fork.'),
        c,
        const ContentBlock.completion(id: 'left', title: 'L', message: 'l'),
        const ContentBlock.completion(id: 'right', title: 'R', message: 'r'),
      ];

      expect(
        WorldRules.publishProblems(
          draft(WorldCategory.story, story(choice('left', 'right'))),
        ),
        isEmpty,
      );
      expect(
        WorldRules.publishProblems(
          draft(WorldCategory.story, story(choice('left', 'intro'))),
        ),
        [
          const PublishProblem(
            PublishProblemCode.choiceDestinationInvalid,
            blockId: 'choice',
          ),
        ],
      );
      expect(
        WorldRules.publishProblems(
          draft(WorldCategory.story, story(choice('left', null))),
        ),
        [
          const PublishProblem(
            PublishProblemCode.blockIncomplete,
            blockId: 'choice',
          ),
        ],
      );
    });

    test('a part the category does not allow is reported', () {
      final problems = WorldRules.publishProblems(
        draft(WorldCategory.art, const [
          ContentBlock.artwork(
            id: 'a',
            assetId: 'x',
            title: 'Mural',
            description: 'Paint.',
          ),
          ContentBlock.question(id: 'q', prompt: 'Who?', hasAnswer: true),
        ]),
      );
      expect(problems, [
        const PublishProblem(PublishProblemCode.blockNotAllowed, blockId: 'q'),
      ]);
    });

    test('blank required fields make a part incomplete', () {
      final problems = WorldRules.publishProblems(
        draft(WorldCategory.experience, const [
          ContentBlock.text(id: 't', body: ' '),
          ContentBlock.image(id: 'i'),
          ContentBlock.artwork(id: 'a', assetId: 'x', title: 'Art'),
          ContentBlock.completion(id: 'c', title: 'End'),
        ]),
      );
      expect([for (final p in problems) p.blockId], ['t', 'i', 'a', 'c']);
      expect(
        problems.every((p) => p.code == PublishProblemCode.blockIncomplete),
        isTrue,
      );
    });
  });

  test('the creator offers only the parts each category allows', () {
    expect(
      WorldRules.allowedBlocks(WorldCategory.puzzle),
      isNot(contains(BlockType.storyChoice)),
    );
    expect(
      WorldRules.allowedBlocks(WorldCategory.story),
      isNot(contains(BlockType.question)),
    );
    expect(
      WorldRules.allowedBlocks(WorldCategory.art),
      contains(BlockType.artwork),
    );
    expect(
      WorldRules.allowedBlocks(WorldCategory.experience),
      BlockType.values,
    );
  });

  test('field rules match the database', () {
    expect(WorldRules.titleError('ab'), isNotNull);
    expect(WorldRules.titleError('  abc  '), isNull);
    expect(WorldRules.titleError('x' * 81), isNotNull);
    expect(WorldRules.descriptionError('x' * 2001), isNotNull);
    expect(WorldRules.answerError('   '), isNotNull);
    expect(WorldRules.answerError('x' * 101), isNotNull);
    expect(WorldRules.answerError('Keeper'), isNull);
  });
}
