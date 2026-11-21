import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';
import 'package:worlds/features/world_creation/domain/world_draft_codec.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

void main() {
  const blocks = <ContentBlock>[
    ContentBlock.text(id: 'b1', body: 'Hello'),
    ContentBlock.image(id: 'b2', assetId: 'a1', caption: ''),
    ContentBlock.storyChoice(
      id: 'b3',
      prompt: 'Which way?',
      options: [StoryOption(id: 'o1', label: 'Left', destinationBlockId: 'b6')],
    ),
    ContentBlock.question(
      id: 'b4',
      prompt: 'Who?',
      hint: 'Two words',
      hasAnswer: true,
    ),
    ContentBlock.artwork(
      id: 'b5',
      assetId: 'a2',
      title: 'Mural',
      description: 'Paint',
    ),
    ContentBlock.completion(id: 'b6', title: 'End', message: 'Bye'),
  ];

  final draft = WorldDraft(
    id: 'w1',
    category: WorldCategory.experience,
    title: '  Harbour Walk  ',
    description: '',
    location: const GeoPoint(latitude: 51.5, longitude: -0.12),
    unlockRadiusMeters: 75,
    blocks: blocks,
  );

  test('save JSON has exactly the keys the server accepts', () {
    final json = WorldDraftCodec.toSaveJson(draft);
    expect(json.keys.toSet(), {
      'id',
      'category',
      'title',
      'description',
      'cover_asset_id',
      'latitude',
      'longitude',
      'unlock_radius_meters',
      'blocks',
    });
    expect(json['title'], 'Harbour Walk');
    expect(json['description'], isNull);
    expect(json['latitude'], 51.5);
    expect(json['longitude'], -0.12);

    final saved = json['blocks']! as List<Map<String, Object?>>;
    Set<String> contentKeys(int i) =>
        (saved[i]['content']! as Map<String, Object?>).keys.toSet();
    expect(saved.map((b) => b['block_type']), [
      'text',
      'image',
      'story_choice',
      'question',
      'artwork',
      'completion',
    ]);
    expect(contentKeys(0), {'body'});
    expect(contentKeys(1), {'asset_id', 'caption'});
    expect(contentKeys(2), {'prompt', 'options'});
    expect(contentKeys(3), {'prompt', 'hint', 'success_message'});
    expect(contentKeys(4), {'asset_id', 'title', 'description'});
    expect(contentKeys(5), {'title', 'message', 'asset_id'});
  });

  test('no block ever carries an answer', () {
    final text = jsonEncode(WorldDraftCodec.toSaveJson(draft));
    expect(text, isNot(contains('answer')));
    expect(text, isNot(contains('has_answer')));
  });

  test('a server copy reads back, including which questions have answers', () {
    final server = {
      ...WorldDraftCodec.toSaveJson(draft),
      'title': 'Harbour Walk',
      'status': 'published',
      'published_at': '2026-11-20T10:00:00+00:00',
      'updated_at': '2026-11-20T10:00:00+00:00',
      'blocks': [
        for (final block in blocks)
          {
            ...WorldDraftCodec.blockToJson(block),
            'schema_version': 1,
            'has_answer': block is QuestionBlock,
          },
      ],
      'assets': [
        {'id': 'a1', 'storage_path': 'u/w1/a1.jpg', 'mime_type': 'image/jpeg'},
      ],
    };
    final parsed = WorldDraftCodec.fromServer(server);

    expect(parsed.title, 'Harbour Walk');
    expect(parsed.status, WorldStatus.published);
    expect(parsed.lifecycle, WorldLifecycle.published);
    expect(parsed.unlockRadiusMeters, 75);
    expect(parsed.blocks, blocks);
    expect(parsed.assets.single.storagePath, 'u/w1/a1.jpg');
  });

  test('a World without a place yet reads back with no location', () {
    final parsed = WorldDraftCodec.fromServer({
      'id': 'w2',
      'category': 'story',
      'title': 'Draft',
      'description': null,
      'latitude': null,
      'longitude': null,
      'unlock_radius_meters': 50,
      'status': 'draft',
      'published_at': '2026-11-01T00:00:00Z',
      'blocks': <Object>[],
      'assets': <Object>[],
    });
    expect(parsed.location, isNull);
    expect(parsed.lifecycle, WorldLifecycle.unpublished);
  });
}
