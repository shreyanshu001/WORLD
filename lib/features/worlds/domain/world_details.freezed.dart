// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'world_details.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorldDetails {

 String get id; String get title; String? get description; WorldCategory get category; int get unlockRadiusMeters;/// Null only for the creator's own draft without a location yet.
 double? get latitude; double? get longitude;/// From the position the app passed, computed by the server.
 double? get distanceMeters; String get creatorUsername; String? get creatorDisplayName;/// Storage path of the cover image, if there is one.
 String? get coverPath; int get blockCount; WorldStatus get status; DateTime? get publishedAt;/// Whether the signed-in user created this World.
 bool get isCreator;
/// Create a copy of WorldDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorldDetailsCopyWith<WorldDetails> get copyWith => _$WorldDetailsCopyWithImpl<WorldDetails>(this as WorldDetails, _$identity);

  /// Serializes this WorldDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorldDetails&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.unlockRadiusMeters, unlockRadiusMeters) || other.unlockRadiusMeters == unlockRadiusMeters)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.creatorUsername, creatorUsername) || other.creatorUsername == creatorUsername)&&(identical(other.creatorDisplayName, creatorDisplayName) || other.creatorDisplayName == creatorDisplayName)&&(identical(other.coverPath, coverPath) || other.coverPath == coverPath)&&(identical(other.blockCount, blockCount) || other.blockCount == blockCount)&&(identical(other.status, status) || other.status == status)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.isCreator, isCreator) || other.isCreator == isCreator));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,category,unlockRadiusMeters,latitude,longitude,distanceMeters,creatorUsername,creatorDisplayName,coverPath,blockCount,status,publishedAt,isCreator);

@override
String toString() {
  return 'WorldDetails(id: $id, title: $title, description: $description, category: $category, unlockRadiusMeters: $unlockRadiusMeters, latitude: $latitude, longitude: $longitude, distanceMeters: $distanceMeters, creatorUsername: $creatorUsername, creatorDisplayName: $creatorDisplayName, coverPath: $coverPath, blockCount: $blockCount, status: $status, publishedAt: $publishedAt, isCreator: $isCreator)';
}


}

/// @nodoc
abstract mixin class $WorldDetailsCopyWith<$Res>  {
  factory $WorldDetailsCopyWith(WorldDetails value, $Res Function(WorldDetails) _then) = _$WorldDetailsCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? description, WorldCategory category, int unlockRadiusMeters, double? latitude, double? longitude, double? distanceMeters, String creatorUsername, String? creatorDisplayName, String? coverPath, int blockCount, WorldStatus status, DateTime? publishedAt, bool isCreator
});




}
/// @nodoc
class _$WorldDetailsCopyWithImpl<$Res>
    implements $WorldDetailsCopyWith<$Res> {
  _$WorldDetailsCopyWithImpl(this._self, this._then);

  final WorldDetails _self;
  final $Res Function(WorldDetails) _then;

/// Create a copy of WorldDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? category = null,Object? unlockRadiusMeters = null,Object? latitude = freezed,Object? longitude = freezed,Object? distanceMeters = freezed,Object? creatorUsername = null,Object? creatorDisplayName = freezed,Object? coverPath = freezed,Object? blockCount = null,Object? status = null,Object? publishedAt = freezed,Object? isCreator = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WorldCategory,unlockRadiusMeters: null == unlockRadiusMeters ? _self.unlockRadiusMeters : unlockRadiusMeters // ignore: cast_nullable_to_non_nullable
as int,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,distanceMeters: freezed == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double?,creatorUsername: null == creatorUsername ? _self.creatorUsername : creatorUsername // ignore: cast_nullable_to_non_nullable
as String,creatorDisplayName: freezed == creatorDisplayName ? _self.creatorDisplayName : creatorDisplayName // ignore: cast_nullable_to_non_nullable
as String?,coverPath: freezed == coverPath ? _self.coverPath : coverPath // ignore: cast_nullable_to_non_nullable
as String?,blockCount: null == blockCount ? _self.blockCount : blockCount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorldStatus,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isCreator: null == isCreator ? _self.isCreator : isCreator // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WorldDetails].
extension WorldDetailsPatterns on WorldDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorldDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorldDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorldDetails value)  $default,){
final _that = this;
switch (_that) {
case _WorldDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorldDetails value)?  $default,){
final _that = this;
switch (_that) {
case _WorldDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  WorldCategory category,  int unlockRadiusMeters,  double? latitude,  double? longitude,  double? distanceMeters,  String creatorUsername,  String? creatorDisplayName,  String? coverPath,  int blockCount,  WorldStatus status,  DateTime? publishedAt,  bool isCreator)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorldDetails() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.category,_that.unlockRadiusMeters,_that.latitude,_that.longitude,_that.distanceMeters,_that.creatorUsername,_that.creatorDisplayName,_that.coverPath,_that.blockCount,_that.status,_that.publishedAt,_that.isCreator);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  WorldCategory category,  int unlockRadiusMeters,  double? latitude,  double? longitude,  double? distanceMeters,  String creatorUsername,  String? creatorDisplayName,  String? coverPath,  int blockCount,  WorldStatus status,  DateTime? publishedAt,  bool isCreator)  $default,) {final _that = this;
switch (_that) {
case _WorldDetails():
return $default(_that.id,_that.title,_that.description,_that.category,_that.unlockRadiusMeters,_that.latitude,_that.longitude,_that.distanceMeters,_that.creatorUsername,_that.creatorDisplayName,_that.coverPath,_that.blockCount,_that.status,_that.publishedAt,_that.isCreator);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? description,  WorldCategory category,  int unlockRadiusMeters,  double? latitude,  double? longitude,  double? distanceMeters,  String creatorUsername,  String? creatorDisplayName,  String? coverPath,  int blockCount,  WorldStatus status,  DateTime? publishedAt,  bool isCreator)?  $default,) {final _that = this;
switch (_that) {
case _WorldDetails() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.category,_that.unlockRadiusMeters,_that.latitude,_that.longitude,_that.distanceMeters,_that.creatorUsername,_that.creatorDisplayName,_that.coverPath,_that.blockCount,_that.status,_that.publishedAt,_that.isCreator);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorldDetails extends WorldDetails {
  const _WorldDetails({required this.id, required this.title, this.description, required this.category, required this.unlockRadiusMeters, this.latitude, this.longitude, this.distanceMeters, required this.creatorUsername, this.creatorDisplayName, this.coverPath, required this.blockCount, required this.status, this.publishedAt, this.isCreator = false}): super._();
  factory _WorldDetails.fromJson(Map<String, dynamic> json) => _$WorldDetailsFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? description;
@override final  WorldCategory category;
@override final  int unlockRadiusMeters;
/// Null only for the creator's own draft without a location yet.
@override final  double? latitude;
@override final  double? longitude;
/// From the position the app passed, computed by the server.
@override final  double? distanceMeters;
@override final  String creatorUsername;
@override final  String? creatorDisplayName;
/// Storage path of the cover image, if there is one.
@override final  String? coverPath;
@override final  int blockCount;
@override final  WorldStatus status;
@override final  DateTime? publishedAt;
/// Whether the signed-in user created this World.
@override@JsonKey() final  bool isCreator;

/// Create a copy of WorldDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorldDetailsCopyWith<_WorldDetails> get copyWith => __$WorldDetailsCopyWithImpl<_WorldDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorldDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorldDetails&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.unlockRadiusMeters, unlockRadiusMeters) || other.unlockRadiusMeters == unlockRadiusMeters)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.creatorUsername, creatorUsername) || other.creatorUsername == creatorUsername)&&(identical(other.creatorDisplayName, creatorDisplayName) || other.creatorDisplayName == creatorDisplayName)&&(identical(other.coverPath, coverPath) || other.coverPath == coverPath)&&(identical(other.blockCount, blockCount) || other.blockCount == blockCount)&&(identical(other.status, status) || other.status == status)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.isCreator, isCreator) || other.isCreator == isCreator));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,category,unlockRadiusMeters,latitude,longitude,distanceMeters,creatorUsername,creatorDisplayName,coverPath,blockCount,status,publishedAt,isCreator);

@override
String toString() {
  return 'WorldDetails(id: $id, title: $title, description: $description, category: $category, unlockRadiusMeters: $unlockRadiusMeters, latitude: $latitude, longitude: $longitude, distanceMeters: $distanceMeters, creatorUsername: $creatorUsername, creatorDisplayName: $creatorDisplayName, coverPath: $coverPath, blockCount: $blockCount, status: $status, publishedAt: $publishedAt, isCreator: $isCreator)';
}


}

/// @nodoc
abstract mixin class _$WorldDetailsCopyWith<$Res> implements $WorldDetailsCopyWith<$Res> {
  factory _$WorldDetailsCopyWith(_WorldDetails value, $Res Function(_WorldDetails) _then) = __$WorldDetailsCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? description, WorldCategory category, int unlockRadiusMeters, double? latitude, double? longitude, double? distanceMeters, String creatorUsername, String? creatorDisplayName, String? coverPath, int blockCount, WorldStatus status, DateTime? publishedAt, bool isCreator
});




}
/// @nodoc
class __$WorldDetailsCopyWithImpl<$Res>
    implements _$WorldDetailsCopyWith<$Res> {
  __$WorldDetailsCopyWithImpl(this._self, this._then);

  final _WorldDetails _self;
  final $Res Function(_WorldDetails) _then;

/// Create a copy of WorldDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? category = null,Object? unlockRadiusMeters = null,Object? latitude = freezed,Object? longitude = freezed,Object? distanceMeters = freezed,Object? creatorUsername = null,Object? creatorDisplayName = freezed,Object? coverPath = freezed,Object? blockCount = null,Object? status = null,Object? publishedAt = freezed,Object? isCreator = null,}) {
  return _then(_WorldDetails(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WorldCategory,unlockRadiusMeters: null == unlockRadiusMeters ? _self.unlockRadiusMeters : unlockRadiusMeters // ignore: cast_nullable_to_non_nullable
as int,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,distanceMeters: freezed == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double?,creatorUsername: null == creatorUsername ? _self.creatorUsername : creatorUsername // ignore: cast_nullable_to_non_nullable
as String,creatorDisplayName: freezed == creatorDisplayName ? _self.creatorDisplayName : creatorDisplayName // ignore: cast_nullable_to_non_nullable
as String?,coverPath: freezed == coverPath ? _self.coverPath : coverPath // ignore: cast_nullable_to_non_nullable
as String?,blockCount: null == blockCount ? _self.blockCount : blockCount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorldStatus,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isCreator: null == isCreator ? _self.isCreator : isCreator // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
