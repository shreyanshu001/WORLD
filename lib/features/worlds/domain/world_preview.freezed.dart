// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'world_preview.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorldPreview {

 String get id; String get title; WorldCategory get category; double get latitude; double get longitude;/// Computed by the server from the search centre.
 double get distanceMeters; String get creatorUsername; String? get creatorDisplayName;
/// Create a copy of WorldPreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorldPreviewCopyWith<WorldPreview> get copyWith => _$WorldPreviewCopyWithImpl<WorldPreview>(this as WorldPreview, _$identity);

  /// Serializes this WorldPreview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorldPreview&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.creatorUsername, creatorUsername) || other.creatorUsername == creatorUsername)&&(identical(other.creatorDisplayName, creatorDisplayName) || other.creatorDisplayName == creatorDisplayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,category,latitude,longitude,distanceMeters,creatorUsername,creatorDisplayName);

@override
String toString() {
  return 'WorldPreview(id: $id, title: $title, category: $category, latitude: $latitude, longitude: $longitude, distanceMeters: $distanceMeters, creatorUsername: $creatorUsername, creatorDisplayName: $creatorDisplayName)';
}


}

/// @nodoc
abstract mixin class $WorldPreviewCopyWith<$Res>  {
  factory $WorldPreviewCopyWith(WorldPreview value, $Res Function(WorldPreview) _then) = _$WorldPreviewCopyWithImpl;
@useResult
$Res call({
 String id, String title, WorldCategory category, double latitude, double longitude, double distanceMeters, String creatorUsername, String? creatorDisplayName
});




}
/// @nodoc
class _$WorldPreviewCopyWithImpl<$Res>
    implements $WorldPreviewCopyWith<$Res> {
  _$WorldPreviewCopyWithImpl(this._self, this._then);

  final WorldPreview _self;
  final $Res Function(WorldPreview) _then;

/// Create a copy of WorldPreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? category = null,Object? latitude = null,Object? longitude = null,Object? distanceMeters = null,Object? creatorUsername = null,Object? creatorDisplayName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WorldCategory,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double,creatorUsername: null == creatorUsername ? _self.creatorUsername : creatorUsername // ignore: cast_nullable_to_non_nullable
as String,creatorDisplayName: freezed == creatorDisplayName ? _self.creatorDisplayName : creatorDisplayName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorldPreview].
extension WorldPreviewPatterns on WorldPreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorldPreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorldPreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorldPreview value)  $default,){
final _that = this;
switch (_that) {
case _WorldPreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorldPreview value)?  $default,){
final _that = this;
switch (_that) {
case _WorldPreview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  WorldCategory category,  double latitude,  double longitude,  double distanceMeters,  String creatorUsername,  String? creatorDisplayName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorldPreview() when $default != null:
return $default(_that.id,_that.title,_that.category,_that.latitude,_that.longitude,_that.distanceMeters,_that.creatorUsername,_that.creatorDisplayName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  WorldCategory category,  double latitude,  double longitude,  double distanceMeters,  String creatorUsername,  String? creatorDisplayName)  $default,) {final _that = this;
switch (_that) {
case _WorldPreview():
return $default(_that.id,_that.title,_that.category,_that.latitude,_that.longitude,_that.distanceMeters,_that.creatorUsername,_that.creatorDisplayName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  WorldCategory category,  double latitude,  double longitude,  double distanceMeters,  String creatorUsername,  String? creatorDisplayName)?  $default,) {final _that = this;
switch (_that) {
case _WorldPreview() when $default != null:
return $default(_that.id,_that.title,_that.category,_that.latitude,_that.longitude,_that.distanceMeters,_that.creatorUsername,_that.creatorDisplayName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorldPreview extends WorldPreview {
  const _WorldPreview({required this.id, required this.title, required this.category, required this.latitude, required this.longitude, required this.distanceMeters, required this.creatorUsername, this.creatorDisplayName}): super._();
  factory _WorldPreview.fromJson(Map<String, dynamic> json) => _$WorldPreviewFromJson(json);

@override final  String id;
@override final  String title;
@override final  WorldCategory category;
@override final  double latitude;
@override final  double longitude;
/// Computed by the server from the search centre.
@override final  double distanceMeters;
@override final  String creatorUsername;
@override final  String? creatorDisplayName;

/// Create a copy of WorldPreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorldPreviewCopyWith<_WorldPreview> get copyWith => __$WorldPreviewCopyWithImpl<_WorldPreview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorldPreviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorldPreview&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.creatorUsername, creatorUsername) || other.creatorUsername == creatorUsername)&&(identical(other.creatorDisplayName, creatorDisplayName) || other.creatorDisplayName == creatorDisplayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,category,latitude,longitude,distanceMeters,creatorUsername,creatorDisplayName);

@override
String toString() {
  return 'WorldPreview(id: $id, title: $title, category: $category, latitude: $latitude, longitude: $longitude, distanceMeters: $distanceMeters, creatorUsername: $creatorUsername, creatorDisplayName: $creatorDisplayName)';
}


}

/// @nodoc
abstract mixin class _$WorldPreviewCopyWith<$Res> implements $WorldPreviewCopyWith<$Res> {
  factory _$WorldPreviewCopyWith(_WorldPreview value, $Res Function(_WorldPreview) _then) = __$WorldPreviewCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, WorldCategory category, double latitude, double longitude, double distanceMeters, String creatorUsername, String? creatorDisplayName
});




}
/// @nodoc
class __$WorldPreviewCopyWithImpl<$Res>
    implements _$WorldPreviewCopyWith<$Res> {
  __$WorldPreviewCopyWithImpl(this._self, this._then);

  final _WorldPreview _self;
  final $Res Function(_WorldPreview) _then;

/// Create a copy of WorldPreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? category = null,Object? latitude = null,Object? longitude = null,Object? distanceMeters = null,Object? creatorUsername = null,Object? creatorDisplayName = freezed,}) {
  return _then(_WorldPreview(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WorldCategory,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double,creatorUsername: null == creatorUsername ? _self.creatorUsername : creatorUsername // ignore: cast_nullable_to_non_nullable
as String,creatorDisplayName: freezed == creatorDisplayName ? _self.creatorDisplayName : creatorDisplayName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
