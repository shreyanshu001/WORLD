// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_world.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SavedWorld {

 String get id; String get title; WorldCategory get category; String get creatorUsername; String? get creatorDisplayName;/// Storage path of the cover image, if there is one.
 String? get coverPath;/// From the position the app passed, computed by the server.
 double? get distanceMeters; DateTime get savedAt;
/// Create a copy of SavedWorld
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedWorldCopyWith<SavedWorld> get copyWith => _$SavedWorldCopyWithImpl<SavedWorld>(this as SavedWorld, _$identity);

  /// Serializes this SavedWorld to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedWorld&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.creatorUsername, creatorUsername) || other.creatorUsername == creatorUsername)&&(identical(other.creatorDisplayName, creatorDisplayName) || other.creatorDisplayName == creatorDisplayName)&&(identical(other.coverPath, coverPath) || other.coverPath == coverPath)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,category,creatorUsername,creatorDisplayName,coverPath,distanceMeters,savedAt);

@override
String toString() {
  return 'SavedWorld(id: $id, title: $title, category: $category, creatorUsername: $creatorUsername, creatorDisplayName: $creatorDisplayName, coverPath: $coverPath, distanceMeters: $distanceMeters, savedAt: $savedAt)';
}


}

/// @nodoc
abstract mixin class $SavedWorldCopyWith<$Res>  {
  factory $SavedWorldCopyWith(SavedWorld value, $Res Function(SavedWorld) _then) = _$SavedWorldCopyWithImpl;
@useResult
$Res call({
 String id, String title, WorldCategory category, String creatorUsername, String? creatorDisplayName, String? coverPath, double? distanceMeters, DateTime savedAt
});




}
/// @nodoc
class _$SavedWorldCopyWithImpl<$Res>
    implements $SavedWorldCopyWith<$Res> {
  _$SavedWorldCopyWithImpl(this._self, this._then);

  final SavedWorld _self;
  final $Res Function(SavedWorld) _then;

/// Create a copy of SavedWorld
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? category = null,Object? creatorUsername = null,Object? creatorDisplayName = freezed,Object? coverPath = freezed,Object? distanceMeters = freezed,Object? savedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WorldCategory,creatorUsername: null == creatorUsername ? _self.creatorUsername : creatorUsername // ignore: cast_nullable_to_non_nullable
as String,creatorDisplayName: freezed == creatorDisplayName ? _self.creatorDisplayName : creatorDisplayName // ignore: cast_nullable_to_non_nullable
as String?,coverPath: freezed == coverPath ? _self.coverPath : coverPath // ignore: cast_nullable_to_non_nullable
as String?,distanceMeters: freezed == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double?,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedWorld].
extension SavedWorldPatterns on SavedWorld {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedWorld value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedWorld() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedWorld value)  $default,){
final _that = this;
switch (_that) {
case _SavedWorld():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedWorld value)?  $default,){
final _that = this;
switch (_that) {
case _SavedWorld() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  WorldCategory category,  String creatorUsername,  String? creatorDisplayName,  String? coverPath,  double? distanceMeters,  DateTime savedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedWorld() when $default != null:
return $default(_that.id,_that.title,_that.category,_that.creatorUsername,_that.creatorDisplayName,_that.coverPath,_that.distanceMeters,_that.savedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  WorldCategory category,  String creatorUsername,  String? creatorDisplayName,  String? coverPath,  double? distanceMeters,  DateTime savedAt)  $default,) {final _that = this;
switch (_that) {
case _SavedWorld():
return $default(_that.id,_that.title,_that.category,_that.creatorUsername,_that.creatorDisplayName,_that.coverPath,_that.distanceMeters,_that.savedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  WorldCategory category,  String creatorUsername,  String? creatorDisplayName,  String? coverPath,  double? distanceMeters,  DateTime savedAt)?  $default,) {final _that = this;
switch (_that) {
case _SavedWorld() when $default != null:
return $default(_that.id,_that.title,_that.category,_that.creatorUsername,_that.creatorDisplayName,_that.coverPath,_that.distanceMeters,_that.savedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SavedWorld extends SavedWorld {
  const _SavedWorld({required this.id, required this.title, required this.category, required this.creatorUsername, this.creatorDisplayName, this.coverPath, this.distanceMeters, required this.savedAt}): super._();
  factory _SavedWorld.fromJson(Map<String, dynamic> json) => _$SavedWorldFromJson(json);

@override final  String id;
@override final  String title;
@override final  WorldCategory category;
@override final  String creatorUsername;
@override final  String? creatorDisplayName;
/// Storage path of the cover image, if there is one.
@override final  String? coverPath;
/// From the position the app passed, computed by the server.
@override final  double? distanceMeters;
@override final  DateTime savedAt;

/// Create a copy of SavedWorld
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedWorldCopyWith<_SavedWorld> get copyWith => __$SavedWorldCopyWithImpl<_SavedWorld>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SavedWorldToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedWorld&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.creatorUsername, creatorUsername) || other.creatorUsername == creatorUsername)&&(identical(other.creatorDisplayName, creatorDisplayName) || other.creatorDisplayName == creatorDisplayName)&&(identical(other.coverPath, coverPath) || other.coverPath == coverPath)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,category,creatorUsername,creatorDisplayName,coverPath,distanceMeters,savedAt);

@override
String toString() {
  return 'SavedWorld(id: $id, title: $title, category: $category, creatorUsername: $creatorUsername, creatorDisplayName: $creatorDisplayName, coverPath: $coverPath, distanceMeters: $distanceMeters, savedAt: $savedAt)';
}


}

/// @nodoc
abstract mixin class _$SavedWorldCopyWith<$Res> implements $SavedWorldCopyWith<$Res> {
  factory _$SavedWorldCopyWith(_SavedWorld value, $Res Function(_SavedWorld) _then) = __$SavedWorldCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, WorldCategory category, String creatorUsername, String? creatorDisplayName, String? coverPath, double? distanceMeters, DateTime savedAt
});




}
/// @nodoc
class __$SavedWorldCopyWithImpl<$Res>
    implements _$SavedWorldCopyWith<$Res> {
  __$SavedWorldCopyWithImpl(this._self, this._then);

  final _SavedWorld _self;
  final $Res Function(_SavedWorld) _then;

/// Create a copy of SavedWorld
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? category = null,Object? creatorUsername = null,Object? creatorDisplayName = freezed,Object? coverPath = freezed,Object? distanceMeters = freezed,Object? savedAt = null,}) {
  return _then(_SavedWorld(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WorldCategory,creatorUsername: null == creatorUsername ? _self.creatorUsername : creatorUsername // ignore: cast_nullable_to_non_nullable
as String,creatorDisplayName: freezed == creatorDisplayName ? _self.creatorDisplayName : creatorDisplayName // ignore: cast_nullable_to_non_nullable
as String?,coverPath: freezed == coverPath ? _self.coverPath : coverPath // ignore: cast_nullable_to_non_nullable
as String?,distanceMeters: freezed == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double?,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
