// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content_block.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ContentBlock {

 String get id;
/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContentBlockCopyWith<ContentBlock> get copyWith => _$ContentBlockCopyWithImpl<ContentBlock>(this as ContentBlock, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContentBlock&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'ContentBlock(id: $id)';
}


}

/// @nodoc
abstract mixin class $ContentBlockCopyWith<$Res>  {
  factory $ContentBlockCopyWith(ContentBlock value, $Res Function(ContentBlock) _then) = _$ContentBlockCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$ContentBlockCopyWithImpl<$Res>
    implements $ContentBlockCopyWith<$Res> {
  _$ContentBlockCopyWithImpl(this._self, this._then);

  final ContentBlock _self;
  final $Res Function(ContentBlock) _then;

/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ContentBlock].
extension ContentBlockPatterns on ContentBlock {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TextBlock value)?  text,TResult Function( ImageBlock value)?  image,TResult Function( StoryChoiceBlock value)?  storyChoice,TResult Function( QuestionBlock value)?  question,TResult Function( ArtworkBlock value)?  artwork,TResult Function( CompletionBlock value)?  completion,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TextBlock() when text != null:
return text(_that);case ImageBlock() when image != null:
return image(_that);case StoryChoiceBlock() when storyChoice != null:
return storyChoice(_that);case QuestionBlock() when question != null:
return question(_that);case ArtworkBlock() when artwork != null:
return artwork(_that);case CompletionBlock() when completion != null:
return completion(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TextBlock value)  text,required TResult Function( ImageBlock value)  image,required TResult Function( StoryChoiceBlock value)  storyChoice,required TResult Function( QuestionBlock value)  question,required TResult Function( ArtworkBlock value)  artwork,required TResult Function( CompletionBlock value)  completion,}){
final _that = this;
switch (_that) {
case TextBlock():
return text(_that);case ImageBlock():
return image(_that);case StoryChoiceBlock():
return storyChoice(_that);case QuestionBlock():
return question(_that);case ArtworkBlock():
return artwork(_that);case CompletionBlock():
return completion(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TextBlock value)?  text,TResult? Function( ImageBlock value)?  image,TResult? Function( StoryChoiceBlock value)?  storyChoice,TResult? Function( QuestionBlock value)?  question,TResult? Function( ArtworkBlock value)?  artwork,TResult? Function( CompletionBlock value)?  completion,}){
final _that = this;
switch (_that) {
case TextBlock() when text != null:
return text(_that);case ImageBlock() when image != null:
return image(_that);case StoryChoiceBlock() when storyChoice != null:
return storyChoice(_that);case QuestionBlock() when question != null:
return question(_that);case ArtworkBlock() when artwork != null:
return artwork(_that);case CompletionBlock() when completion != null:
return completion(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String body)?  text,TResult Function( String id,  String? assetId,  String caption)?  image,TResult Function( String id,  String prompt,  List<StoryOption> options)?  storyChoice,TResult Function( String id,  String prompt,  String hint,  String successMessage,  bool hasAnswer)?  question,TResult Function( String id,  String? assetId,  String title,  String description)?  artwork,TResult Function( String id,  String title,  String message,  String? assetId)?  completion,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TextBlock() when text != null:
return text(_that.id,_that.body);case ImageBlock() when image != null:
return image(_that.id,_that.assetId,_that.caption);case StoryChoiceBlock() when storyChoice != null:
return storyChoice(_that.id,_that.prompt,_that.options);case QuestionBlock() when question != null:
return question(_that.id,_that.prompt,_that.hint,_that.successMessage,_that.hasAnswer);case ArtworkBlock() when artwork != null:
return artwork(_that.id,_that.assetId,_that.title,_that.description);case CompletionBlock() when completion != null:
return completion(_that.id,_that.title,_that.message,_that.assetId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String body)  text,required TResult Function( String id,  String? assetId,  String caption)  image,required TResult Function( String id,  String prompt,  List<StoryOption> options)  storyChoice,required TResult Function( String id,  String prompt,  String hint,  String successMessage,  bool hasAnswer)  question,required TResult Function( String id,  String? assetId,  String title,  String description)  artwork,required TResult Function( String id,  String title,  String message,  String? assetId)  completion,}) {final _that = this;
switch (_that) {
case TextBlock():
return text(_that.id,_that.body);case ImageBlock():
return image(_that.id,_that.assetId,_that.caption);case StoryChoiceBlock():
return storyChoice(_that.id,_that.prompt,_that.options);case QuestionBlock():
return question(_that.id,_that.prompt,_that.hint,_that.successMessage,_that.hasAnswer);case ArtworkBlock():
return artwork(_that.id,_that.assetId,_that.title,_that.description);case CompletionBlock():
return completion(_that.id,_that.title,_that.message,_that.assetId);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String body)?  text,TResult? Function( String id,  String? assetId,  String caption)?  image,TResult? Function( String id,  String prompt,  List<StoryOption> options)?  storyChoice,TResult? Function( String id,  String prompt,  String hint,  String successMessage,  bool hasAnswer)?  question,TResult? Function( String id,  String? assetId,  String title,  String description)?  artwork,TResult? Function( String id,  String title,  String message,  String? assetId)?  completion,}) {final _that = this;
switch (_that) {
case TextBlock() when text != null:
return text(_that.id,_that.body);case ImageBlock() when image != null:
return image(_that.id,_that.assetId,_that.caption);case StoryChoiceBlock() when storyChoice != null:
return storyChoice(_that.id,_that.prompt,_that.options);case QuestionBlock() when question != null:
return question(_that.id,_that.prompt,_that.hint,_that.successMessage,_that.hasAnswer);case ArtworkBlock() when artwork != null:
return artwork(_that.id,_that.assetId,_that.title,_that.description);case CompletionBlock() when completion != null:
return completion(_that.id,_that.title,_that.message,_that.assetId);case _:
  return null;

}
}

}

/// @nodoc


class TextBlock extends ContentBlock {
  const TextBlock({required this.id, this.body = ''}): super._();
  

@override final  String id;
@JsonKey() final  String body;

/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextBlockCopyWith<TextBlock> get copyWith => _$TextBlockCopyWithImpl<TextBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.body, body) || other.body == body));
}


@override
int get hashCode => Object.hash(runtimeType,id,body);

@override
String toString() {
  return 'ContentBlock.text(id: $id, body: $body)';
}


}

/// @nodoc
abstract mixin class $TextBlockCopyWith<$Res> implements $ContentBlockCopyWith<$Res> {
  factory $TextBlockCopyWith(TextBlock value, $Res Function(TextBlock) _then) = _$TextBlockCopyWithImpl;
@override @useResult
$Res call({
 String id, String body
});




}
/// @nodoc
class _$TextBlockCopyWithImpl<$Res>
    implements $TextBlockCopyWith<$Res> {
  _$TextBlockCopyWithImpl(this._self, this._then);

  final TextBlock _self;
  final $Res Function(TextBlock) _then;

/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? body = null,}) {
  return _then(TextBlock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ImageBlock extends ContentBlock {
  const ImageBlock({required this.id, this.assetId, this.caption = ''}): super._();
  

@override final  String id;
 final  String? assetId;
@JsonKey() final  String caption;

/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageBlockCopyWith<ImageBlock> get copyWith => _$ImageBlockCopyWithImpl<ImageBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.caption, caption) || other.caption == caption));
}


@override
int get hashCode => Object.hash(runtimeType,id,assetId,caption);

@override
String toString() {
  return 'ContentBlock.image(id: $id, assetId: $assetId, caption: $caption)';
}


}

/// @nodoc
abstract mixin class $ImageBlockCopyWith<$Res> implements $ContentBlockCopyWith<$Res> {
  factory $ImageBlockCopyWith(ImageBlock value, $Res Function(ImageBlock) _then) = _$ImageBlockCopyWithImpl;
@override @useResult
$Res call({
 String id, String? assetId, String caption
});




}
/// @nodoc
class _$ImageBlockCopyWithImpl<$Res>
    implements $ImageBlockCopyWith<$Res> {
  _$ImageBlockCopyWithImpl(this._self, this._then);

  final ImageBlock _self;
  final $Res Function(ImageBlock) _then;

/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? assetId = freezed,Object? caption = null,}) {
  return _then(ImageBlock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,assetId: freezed == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String?,caption: null == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class StoryChoiceBlock extends ContentBlock {
  const StoryChoiceBlock({required this.id, this.prompt = '', final  List<StoryOption> options = const <StoryOption>[]}): _options = options,super._();
  

@override final  String id;
@JsonKey() final  String prompt;
 final  List<StoryOption> _options;
@JsonKey() List<StoryOption> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}


/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoryChoiceBlockCopyWith<StoryChoiceBlock> get copyWith => _$StoryChoiceBlockCopyWithImpl<StoryChoiceBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryChoiceBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&const DeepCollectionEquality().equals(other._options, _options));
}


@override
int get hashCode => Object.hash(runtimeType,id,prompt,const DeepCollectionEquality().hash(_options));

@override
String toString() {
  return 'ContentBlock.storyChoice(id: $id, prompt: $prompt, options: $options)';
}


}

/// @nodoc
abstract mixin class $StoryChoiceBlockCopyWith<$Res> implements $ContentBlockCopyWith<$Res> {
  factory $StoryChoiceBlockCopyWith(StoryChoiceBlock value, $Res Function(StoryChoiceBlock) _then) = _$StoryChoiceBlockCopyWithImpl;
@override @useResult
$Res call({
 String id, String prompt, List<StoryOption> options
});




}
/// @nodoc
class _$StoryChoiceBlockCopyWithImpl<$Res>
    implements $StoryChoiceBlockCopyWith<$Res> {
  _$StoryChoiceBlockCopyWithImpl(this._self, this._then);

  final StoryChoiceBlock _self;
  final $Res Function(StoryChoiceBlock) _then;

/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? prompt = null,Object? options = null,}) {
  return _then(StoryChoiceBlock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<StoryOption>,
  ));
}


}

/// @nodoc


class QuestionBlock extends ContentBlock {
  const QuestionBlock({required this.id, this.prompt = '', this.hint = '', this.successMessage = '', this.hasAnswer = false}): super._();
  

@override final  String id;
@JsonKey() final  String prompt;
@JsonKey() final  String hint;
@JsonKey() final  String successMessage;
/// Whether the server holds an answer for this question.
@JsonKey() final  bool hasAnswer;

/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionBlockCopyWith<QuestionBlock> get copyWith => _$QuestionBlockCopyWithImpl<QuestionBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&(identical(other.hint, hint) || other.hint == hint)&&(identical(other.successMessage, successMessage) || other.successMessage == successMessage)&&(identical(other.hasAnswer, hasAnswer) || other.hasAnswer == hasAnswer));
}


@override
int get hashCode => Object.hash(runtimeType,id,prompt,hint,successMessage,hasAnswer);

@override
String toString() {
  return 'ContentBlock.question(id: $id, prompt: $prompt, hint: $hint, successMessage: $successMessage, hasAnswer: $hasAnswer)';
}


}

/// @nodoc
abstract mixin class $QuestionBlockCopyWith<$Res> implements $ContentBlockCopyWith<$Res> {
  factory $QuestionBlockCopyWith(QuestionBlock value, $Res Function(QuestionBlock) _then) = _$QuestionBlockCopyWithImpl;
@override @useResult
$Res call({
 String id, String prompt, String hint, String successMessage, bool hasAnswer
});




}
/// @nodoc
class _$QuestionBlockCopyWithImpl<$Res>
    implements $QuestionBlockCopyWith<$Res> {
  _$QuestionBlockCopyWithImpl(this._self, this._then);

  final QuestionBlock _self;
  final $Res Function(QuestionBlock) _then;

/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? prompt = null,Object? hint = null,Object? successMessage = null,Object? hasAnswer = null,}) {
  return _then(QuestionBlock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,hint: null == hint ? _self.hint : hint // ignore: cast_nullable_to_non_nullable
as String,successMessage: null == successMessage ? _self.successMessage : successMessage // ignore: cast_nullable_to_non_nullable
as String,hasAnswer: null == hasAnswer ? _self.hasAnswer : hasAnswer // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class ArtworkBlock extends ContentBlock {
  const ArtworkBlock({required this.id, this.assetId, this.title = '', this.description = ''}): super._();
  

@override final  String id;
 final  String? assetId;
@JsonKey() final  String title;
@JsonKey() final  String description;

/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtworkBlockCopyWith<ArtworkBlock> get copyWith => _$ArtworkBlockCopyWithImpl<ArtworkBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtworkBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,id,assetId,title,description);

@override
String toString() {
  return 'ContentBlock.artwork(id: $id, assetId: $assetId, title: $title, description: $description)';
}


}

/// @nodoc
abstract mixin class $ArtworkBlockCopyWith<$Res> implements $ContentBlockCopyWith<$Res> {
  factory $ArtworkBlockCopyWith(ArtworkBlock value, $Res Function(ArtworkBlock) _then) = _$ArtworkBlockCopyWithImpl;
@override @useResult
$Res call({
 String id, String? assetId, String title, String description
});




}
/// @nodoc
class _$ArtworkBlockCopyWithImpl<$Res>
    implements $ArtworkBlockCopyWith<$Res> {
  _$ArtworkBlockCopyWithImpl(this._self, this._then);

  final ArtworkBlock _self;
  final $Res Function(ArtworkBlock) _then;

/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? assetId = freezed,Object? title = null,Object? description = null,}) {
  return _then(ArtworkBlock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,assetId: freezed == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class CompletionBlock extends ContentBlock {
  const CompletionBlock({required this.id, this.title = '', this.message = '', this.assetId}): super._();
  

@override final  String id;
@JsonKey() final  String title;
@JsonKey() final  String message;
 final  String? assetId;

/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompletionBlockCopyWith<CompletionBlock> get copyWith => _$CompletionBlockCopyWithImpl<CompletionBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompletionBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.assetId, assetId) || other.assetId == assetId));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,message,assetId);

@override
String toString() {
  return 'ContentBlock.completion(id: $id, title: $title, message: $message, assetId: $assetId)';
}


}

/// @nodoc
abstract mixin class $CompletionBlockCopyWith<$Res> implements $ContentBlockCopyWith<$Res> {
  factory $CompletionBlockCopyWith(CompletionBlock value, $Res Function(CompletionBlock) _then) = _$CompletionBlockCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String message, String? assetId
});




}
/// @nodoc
class _$CompletionBlockCopyWithImpl<$Res>
    implements $CompletionBlockCopyWith<$Res> {
  _$CompletionBlockCopyWithImpl(this._self, this._then);

  final CompletionBlock _self;
  final $Res Function(CompletionBlock) _then;

/// Create a copy of ContentBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? message = null,Object? assetId = freezed,}) {
  return _then(CompletionBlock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,assetId: freezed == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$StoryOption {

 String get id; String get label; String? get destinationBlockId;
/// Create a copy of StoryOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoryOptionCopyWith<StoryOption> get copyWith => _$StoryOptionCopyWithImpl<StoryOption>(this as StoryOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryOption&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.destinationBlockId, destinationBlockId) || other.destinationBlockId == destinationBlockId));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,destinationBlockId);

@override
String toString() {
  return 'StoryOption(id: $id, label: $label, destinationBlockId: $destinationBlockId)';
}


}

/// @nodoc
abstract mixin class $StoryOptionCopyWith<$Res>  {
  factory $StoryOptionCopyWith(StoryOption value, $Res Function(StoryOption) _then) = _$StoryOptionCopyWithImpl;
@useResult
$Res call({
 String id, String label, String? destinationBlockId
});




}
/// @nodoc
class _$StoryOptionCopyWithImpl<$Res>
    implements $StoryOptionCopyWith<$Res> {
  _$StoryOptionCopyWithImpl(this._self, this._then);

  final StoryOption _self;
  final $Res Function(StoryOption) _then;

/// Create a copy of StoryOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? destinationBlockId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,destinationBlockId: freezed == destinationBlockId ? _self.destinationBlockId : destinationBlockId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StoryOption].
extension StoryOptionPatterns on StoryOption {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoryOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoryOption() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoryOption value)  $default,){
final _that = this;
switch (_that) {
case _StoryOption():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoryOption value)?  $default,){
final _that = this;
switch (_that) {
case _StoryOption() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  String? destinationBlockId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoryOption() when $default != null:
return $default(_that.id,_that.label,_that.destinationBlockId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  String? destinationBlockId)  $default,) {final _that = this;
switch (_that) {
case _StoryOption():
return $default(_that.id,_that.label,_that.destinationBlockId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  String? destinationBlockId)?  $default,) {final _that = this;
switch (_that) {
case _StoryOption() when $default != null:
return $default(_that.id,_that.label,_that.destinationBlockId);case _:
  return null;

}
}

}

/// @nodoc


class _StoryOption implements StoryOption {
  const _StoryOption({required this.id, this.label = '', this.destinationBlockId});
  

@override final  String id;
@override@JsonKey() final  String label;
@override final  String? destinationBlockId;

/// Create a copy of StoryOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoryOptionCopyWith<_StoryOption> get copyWith => __$StoryOptionCopyWithImpl<_StoryOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoryOption&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.destinationBlockId, destinationBlockId) || other.destinationBlockId == destinationBlockId));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,destinationBlockId);

@override
String toString() {
  return 'StoryOption(id: $id, label: $label, destinationBlockId: $destinationBlockId)';
}


}

/// @nodoc
abstract mixin class _$StoryOptionCopyWith<$Res> implements $StoryOptionCopyWith<$Res> {
  factory _$StoryOptionCopyWith(_StoryOption value, $Res Function(_StoryOption) _then) = __$StoryOptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, String? destinationBlockId
});




}
/// @nodoc
class __$StoryOptionCopyWithImpl<$Res>
    implements _$StoryOptionCopyWith<$Res> {
  __$StoryOptionCopyWithImpl(this._self, this._then);

  final _StoryOption _self;
  final $Res Function(_StoryOption) _then;

/// Create a copy of StoryOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? destinationBlockId = freezed,}) {
  return _then(_StoryOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,destinationBlockId: freezed == destinationBlockId ? _self.destinationBlockId : destinationBlockId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
