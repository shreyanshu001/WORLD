// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'play_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlayProgress {

 bool get completed; String? get currentBlockId; List<String> get path; List<String> get answered; int get completionCount;
/// Create a copy of PlayProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayProgressCopyWith<PlayProgress> get copyWith => _$PlayProgressCopyWithImpl<PlayProgress>(this as PlayProgress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayProgress&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.currentBlockId, currentBlockId) || other.currentBlockId == currentBlockId)&&const DeepCollectionEquality().equals(other.path, path)&&const DeepCollectionEquality().equals(other.answered, answered)&&(identical(other.completionCount, completionCount) || other.completionCount == completionCount));
}


@override
int get hashCode => Object.hash(runtimeType,completed,currentBlockId,const DeepCollectionEquality().hash(path),const DeepCollectionEquality().hash(answered),completionCount);

@override
String toString() {
  return 'PlayProgress(completed: $completed, currentBlockId: $currentBlockId, path: $path, answered: $answered, completionCount: $completionCount)';
}


}

/// @nodoc
abstract mixin class $PlayProgressCopyWith<$Res>  {
  factory $PlayProgressCopyWith(PlayProgress value, $Res Function(PlayProgress) _then) = _$PlayProgressCopyWithImpl;
@useResult
$Res call({
 bool completed, String? currentBlockId, List<String> path, List<String> answered, int completionCount
});




}
/// @nodoc
class _$PlayProgressCopyWithImpl<$Res>
    implements $PlayProgressCopyWith<$Res> {
  _$PlayProgressCopyWithImpl(this._self, this._then);

  final PlayProgress _self;
  final $Res Function(PlayProgress) _then;

/// Create a copy of PlayProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? completed = null,Object? currentBlockId = freezed,Object? path = null,Object? answered = null,Object? completionCount = null,}) {
  return _then(_self.copyWith(
completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,currentBlockId: freezed == currentBlockId ? _self.currentBlockId : currentBlockId // ignore: cast_nullable_to_non_nullable
as String?,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as List<String>,answered: null == answered ? _self.answered : answered // ignore: cast_nullable_to_non_nullable
as List<String>,completionCount: null == completionCount ? _self.completionCount : completionCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayProgress].
extension PlayProgressPatterns on PlayProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayProgress value)  $default,){
final _that = this;
switch (_that) {
case _PlayProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayProgress value)?  $default,){
final _that = this;
switch (_that) {
case _PlayProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool completed,  String? currentBlockId,  List<String> path,  List<String> answered,  int completionCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayProgress() when $default != null:
return $default(_that.completed,_that.currentBlockId,_that.path,_that.answered,_that.completionCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool completed,  String? currentBlockId,  List<String> path,  List<String> answered,  int completionCount)  $default,) {final _that = this;
switch (_that) {
case _PlayProgress():
return $default(_that.completed,_that.currentBlockId,_that.path,_that.answered,_that.completionCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool completed,  String? currentBlockId,  List<String> path,  List<String> answered,  int completionCount)?  $default,) {final _that = this;
switch (_that) {
case _PlayProgress() when $default != null:
return $default(_that.completed,_that.currentBlockId,_that.path,_that.answered,_that.completionCount);case _:
  return null;

}
}

}

/// @nodoc


class _PlayProgress implements PlayProgress {
  const _PlayProgress({required this.completed, this.currentBlockId, final  List<String> path = const <String>[], final  List<String> answered = const <String>[], this.completionCount = 0}): _path = path,_answered = answered;
  

@override final  bool completed;
@override final  String? currentBlockId;
 final  List<String> _path;
@override@JsonKey() List<String> get path {
  if (_path is EqualUnmodifiableListView) return _path;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_path);
}

 final  List<String> _answered;
@override@JsonKey() List<String> get answered {
  if (_answered is EqualUnmodifiableListView) return _answered;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_answered);
}

@override@JsonKey() final  int completionCount;

/// Create a copy of PlayProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayProgressCopyWith<_PlayProgress> get copyWith => __$PlayProgressCopyWithImpl<_PlayProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayProgress&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.currentBlockId, currentBlockId) || other.currentBlockId == currentBlockId)&&const DeepCollectionEquality().equals(other._path, _path)&&const DeepCollectionEquality().equals(other._answered, _answered)&&(identical(other.completionCount, completionCount) || other.completionCount == completionCount));
}


@override
int get hashCode => Object.hash(runtimeType,completed,currentBlockId,const DeepCollectionEquality().hash(_path),const DeepCollectionEquality().hash(_answered),completionCount);

@override
String toString() {
  return 'PlayProgress(completed: $completed, currentBlockId: $currentBlockId, path: $path, answered: $answered, completionCount: $completionCount)';
}


}

/// @nodoc
abstract mixin class _$PlayProgressCopyWith<$Res> implements $PlayProgressCopyWith<$Res> {
  factory _$PlayProgressCopyWith(_PlayProgress value, $Res Function(_PlayProgress) _then) = __$PlayProgressCopyWithImpl;
@override @useResult
$Res call({
 bool completed, String? currentBlockId, List<String> path, List<String> answered, int completionCount
});




}
/// @nodoc
class __$PlayProgressCopyWithImpl<$Res>
    implements _$PlayProgressCopyWith<$Res> {
  __$PlayProgressCopyWithImpl(this._self, this._then);

  final _PlayProgress _self;
  final $Res Function(_PlayProgress) _then;

/// Create a copy of PlayProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? completed = null,Object? currentBlockId = freezed,Object? path = null,Object? answered = null,Object? completionCount = null,}) {
  return _then(_PlayProgress(
completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,currentBlockId: freezed == currentBlockId ? _self.currentBlockId : currentBlockId // ignore: cast_nullable_to_non_nullable
as String?,path: null == path ? _self._path : path // ignore: cast_nullable_to_non_nullable
as List<String>,answered: null == answered ? _self._answered : answered // ignore: cast_nullable_to_non_nullable
as List<String>,completionCount: null == completionCount ? _self.completionCount : completionCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$PlaySession {

 String get worldId; String get title; WorldCategory get category; String? get coverPath; List<ContentBlock> get blocks;/// Storage paths of the images the parts use, by asset id.
 Map<String, String> get assetPaths; PlayProgress get progress;
/// Create a copy of PlaySession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaySessionCopyWith<PlaySession> get copyWith => _$PlaySessionCopyWithImpl<PlaySession>(this as PlaySession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaySession&&(identical(other.worldId, worldId) || other.worldId == worldId)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.coverPath, coverPath) || other.coverPath == coverPath)&&const DeepCollectionEquality().equals(other.blocks, blocks)&&const DeepCollectionEquality().equals(other.assetPaths, assetPaths)&&(identical(other.progress, progress) || other.progress == progress));
}


@override
int get hashCode => Object.hash(runtimeType,worldId,title,category,coverPath,const DeepCollectionEquality().hash(blocks),const DeepCollectionEquality().hash(assetPaths),progress);

@override
String toString() {
  return 'PlaySession(worldId: $worldId, title: $title, category: $category, coverPath: $coverPath, blocks: $blocks, assetPaths: $assetPaths, progress: $progress)';
}


}

/// @nodoc
abstract mixin class $PlaySessionCopyWith<$Res>  {
  factory $PlaySessionCopyWith(PlaySession value, $Res Function(PlaySession) _then) = _$PlaySessionCopyWithImpl;
@useResult
$Res call({
 String worldId, String title, WorldCategory category, String? coverPath, List<ContentBlock> blocks, Map<String, String> assetPaths, PlayProgress progress
});


$PlayProgressCopyWith<$Res> get progress;

}
/// @nodoc
class _$PlaySessionCopyWithImpl<$Res>
    implements $PlaySessionCopyWith<$Res> {
  _$PlaySessionCopyWithImpl(this._self, this._then);

  final PlaySession _self;
  final $Res Function(PlaySession) _then;

/// Create a copy of PlaySession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? worldId = null,Object? title = null,Object? category = null,Object? coverPath = freezed,Object? blocks = null,Object? assetPaths = null,Object? progress = null,}) {
  return _then(_self.copyWith(
worldId: null == worldId ? _self.worldId : worldId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WorldCategory,coverPath: freezed == coverPath ? _self.coverPath : coverPath // ignore: cast_nullable_to_non_nullable
as String?,blocks: null == blocks ? _self.blocks : blocks // ignore: cast_nullable_to_non_nullable
as List<ContentBlock>,assetPaths: null == assetPaths ? _self.assetPaths : assetPaths // ignore: cast_nullable_to_non_nullable
as Map<String, String>,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as PlayProgress,
  ));
}
/// Create a copy of PlaySession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayProgressCopyWith<$Res> get progress {
  
  return $PlayProgressCopyWith<$Res>(_self.progress, (value) {
    return _then(_self.copyWith(progress: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlaySession].
extension PlaySessionPatterns on PlaySession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaySession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaySession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaySession value)  $default,){
final _that = this;
switch (_that) {
case _PlaySession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaySession value)?  $default,){
final _that = this;
switch (_that) {
case _PlaySession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String worldId,  String title,  WorldCategory category,  String? coverPath,  List<ContentBlock> blocks,  Map<String, String> assetPaths,  PlayProgress progress)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaySession() when $default != null:
return $default(_that.worldId,_that.title,_that.category,_that.coverPath,_that.blocks,_that.assetPaths,_that.progress);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String worldId,  String title,  WorldCategory category,  String? coverPath,  List<ContentBlock> blocks,  Map<String, String> assetPaths,  PlayProgress progress)  $default,) {final _that = this;
switch (_that) {
case _PlaySession():
return $default(_that.worldId,_that.title,_that.category,_that.coverPath,_that.blocks,_that.assetPaths,_that.progress);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String worldId,  String title,  WorldCategory category,  String? coverPath,  List<ContentBlock> blocks,  Map<String, String> assetPaths,  PlayProgress progress)?  $default,) {final _that = this;
switch (_that) {
case _PlaySession() when $default != null:
return $default(_that.worldId,_that.title,_that.category,_that.coverPath,_that.blocks,_that.assetPaths,_that.progress);case _:
  return null;

}
}

}

/// @nodoc


class _PlaySession extends PlaySession {
  const _PlaySession({required this.worldId, required this.title, required this.category, this.coverPath, required final  List<ContentBlock> blocks, final  Map<String, String> assetPaths = const <String, String>{}, required this.progress}): _blocks = blocks,_assetPaths = assetPaths,super._();
  

@override final  String worldId;
@override final  String title;
@override final  WorldCategory category;
@override final  String? coverPath;
 final  List<ContentBlock> _blocks;
@override List<ContentBlock> get blocks {
  if (_blocks is EqualUnmodifiableListView) return _blocks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_blocks);
}

/// Storage paths of the images the parts use, by asset id.
 final  Map<String, String> _assetPaths;
/// Storage paths of the images the parts use, by asset id.
@override@JsonKey() Map<String, String> get assetPaths {
  if (_assetPaths is EqualUnmodifiableMapView) return _assetPaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_assetPaths);
}

@override final  PlayProgress progress;

/// Create a copy of PlaySession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaySessionCopyWith<_PlaySession> get copyWith => __$PlaySessionCopyWithImpl<_PlaySession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaySession&&(identical(other.worldId, worldId) || other.worldId == worldId)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.coverPath, coverPath) || other.coverPath == coverPath)&&const DeepCollectionEquality().equals(other._blocks, _blocks)&&const DeepCollectionEquality().equals(other._assetPaths, _assetPaths)&&(identical(other.progress, progress) || other.progress == progress));
}


@override
int get hashCode => Object.hash(runtimeType,worldId,title,category,coverPath,const DeepCollectionEquality().hash(_blocks),const DeepCollectionEquality().hash(_assetPaths),progress);

@override
String toString() {
  return 'PlaySession(worldId: $worldId, title: $title, category: $category, coverPath: $coverPath, blocks: $blocks, assetPaths: $assetPaths, progress: $progress)';
}


}

/// @nodoc
abstract mixin class _$PlaySessionCopyWith<$Res> implements $PlaySessionCopyWith<$Res> {
  factory _$PlaySessionCopyWith(_PlaySession value, $Res Function(_PlaySession) _then) = __$PlaySessionCopyWithImpl;
@override @useResult
$Res call({
 String worldId, String title, WorldCategory category, String? coverPath, List<ContentBlock> blocks, Map<String, String> assetPaths, PlayProgress progress
});


@override $PlayProgressCopyWith<$Res> get progress;

}
/// @nodoc
class __$PlaySessionCopyWithImpl<$Res>
    implements _$PlaySessionCopyWith<$Res> {
  __$PlaySessionCopyWithImpl(this._self, this._then);

  final _PlaySession _self;
  final $Res Function(_PlaySession) _then;

/// Create a copy of PlaySession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? worldId = null,Object? title = null,Object? category = null,Object? coverPath = freezed,Object? blocks = null,Object? assetPaths = null,Object? progress = null,}) {
  return _then(_PlaySession(
worldId: null == worldId ? _self.worldId : worldId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WorldCategory,coverPath: freezed == coverPath ? _self.coverPath : coverPath // ignore: cast_nullable_to_non_nullable
as String?,blocks: null == blocks ? _self._blocks : blocks // ignore: cast_nullable_to_non_nullable
as List<ContentBlock>,assetPaths: null == assetPaths ? _self._assetPaths : assetPaths // ignore: cast_nullable_to_non_nullable
as Map<String, String>,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as PlayProgress,
  ));
}

/// Create a copy of PlaySession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayProgressCopyWith<$Res> get progress {
  
  return $PlayProgressCopyWith<$Res>(_self.progress, (value) {
    return _then(_self.copyWith(progress: value));
  });
}
}

// dart format on
