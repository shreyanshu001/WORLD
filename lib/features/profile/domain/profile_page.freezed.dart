// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfileWorld {

 String get id; String get title; WorldCategory get category; String? get coverPath; DateTime? get publishedAt;
/// Create a copy of ProfileWorld
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileWorldCopyWith<ProfileWorld> get copyWith => _$ProfileWorldCopyWithImpl<ProfileWorld>(this as ProfileWorld, _$identity);

  /// Serializes this ProfileWorld to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileWorld&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.coverPath, coverPath) || other.coverPath == coverPath)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,category,coverPath,publishedAt);

@override
String toString() {
  return 'ProfileWorld(id: $id, title: $title, category: $category, coverPath: $coverPath, publishedAt: $publishedAt)';
}


}

/// @nodoc
abstract mixin class $ProfileWorldCopyWith<$Res>  {
  factory $ProfileWorldCopyWith(ProfileWorld value, $Res Function(ProfileWorld) _then) = _$ProfileWorldCopyWithImpl;
@useResult
$Res call({
 String id, String title, WorldCategory category, String? coverPath, DateTime? publishedAt
});




}
/// @nodoc
class _$ProfileWorldCopyWithImpl<$Res>
    implements $ProfileWorldCopyWith<$Res> {
  _$ProfileWorldCopyWithImpl(this._self, this._then);

  final ProfileWorld _self;
  final $Res Function(ProfileWorld) _then;

/// Create a copy of ProfileWorld
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? category = null,Object? coverPath = freezed,Object? publishedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WorldCategory,coverPath: freezed == coverPath ? _self.coverPath : coverPath // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileWorld].
extension ProfileWorldPatterns on ProfileWorld {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileWorld value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileWorld() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileWorld value)  $default,){
final _that = this;
switch (_that) {
case _ProfileWorld():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileWorld value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileWorld() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  WorldCategory category,  String? coverPath,  DateTime? publishedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileWorld() when $default != null:
return $default(_that.id,_that.title,_that.category,_that.coverPath,_that.publishedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  WorldCategory category,  String? coverPath,  DateTime? publishedAt)  $default,) {final _that = this;
switch (_that) {
case _ProfileWorld():
return $default(_that.id,_that.title,_that.category,_that.coverPath,_that.publishedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  WorldCategory category,  String? coverPath,  DateTime? publishedAt)?  $default,) {final _that = this;
switch (_that) {
case _ProfileWorld() when $default != null:
return $default(_that.id,_that.title,_that.category,_that.coverPath,_that.publishedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileWorld implements ProfileWorld {
  const _ProfileWorld({required this.id, required this.title, required this.category, this.coverPath, this.publishedAt});
  factory _ProfileWorld.fromJson(Map<String, dynamic> json) => _$ProfileWorldFromJson(json);

@override final  String id;
@override final  String title;
@override final  WorldCategory category;
@override final  String? coverPath;
@override final  DateTime? publishedAt;

/// Create a copy of ProfileWorld
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileWorldCopyWith<_ProfileWorld> get copyWith => __$ProfileWorldCopyWithImpl<_ProfileWorld>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileWorldToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileWorld&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.coverPath, coverPath) || other.coverPath == coverPath)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,category,coverPath,publishedAt);

@override
String toString() {
  return 'ProfileWorld(id: $id, title: $title, category: $category, coverPath: $coverPath, publishedAt: $publishedAt)';
}


}

/// @nodoc
abstract mixin class _$ProfileWorldCopyWith<$Res> implements $ProfileWorldCopyWith<$Res> {
  factory _$ProfileWorldCopyWith(_ProfileWorld value, $Res Function(_ProfileWorld) _then) = __$ProfileWorldCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, WorldCategory category, String? coverPath, DateTime? publishedAt
});




}
/// @nodoc
class __$ProfileWorldCopyWithImpl<$Res>
    implements _$ProfileWorldCopyWith<$Res> {
  __$ProfileWorldCopyWithImpl(this._self, this._then);

  final _ProfileWorld _self;
  final $Res Function(_ProfileWorld) _then;

/// Create a copy of ProfileWorld
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? category = null,Object? coverPath = freezed,Object? publishedAt = freezed,}) {
  return _then(_ProfileWorld(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WorldCategory,coverPath: freezed == coverPath ? _self.coverPath : coverPath // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ProfilePage {

 String get username; String? get displayName; String? get bio; bool get isOwn; int get publishedCount;/// Null unless this is the page of the signed-in user.
 int? get draftCount; int? get discoveredCount; int? get completedCount; List<ProfileWorld> get worlds; bool get hasMore;
/// Create a copy of ProfilePage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfilePageCopyWith<ProfilePage> get copyWith => _$ProfilePageCopyWithImpl<ProfilePage>(this as ProfilePage, _$identity);

  /// Serializes this ProfilePage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfilePage&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.isOwn, isOwn) || other.isOwn == isOwn)&&(identical(other.publishedCount, publishedCount) || other.publishedCount == publishedCount)&&(identical(other.draftCount, draftCount) || other.draftCount == draftCount)&&(identical(other.discoveredCount, discoveredCount) || other.discoveredCount == discoveredCount)&&(identical(other.completedCount, completedCount) || other.completedCount == completedCount)&&const DeepCollectionEquality().equals(other.worlds, worlds)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,displayName,bio,isOwn,publishedCount,draftCount,discoveredCount,completedCount,const DeepCollectionEquality().hash(worlds),hasMore);

@override
String toString() {
  return 'ProfilePage(username: $username, displayName: $displayName, bio: $bio, isOwn: $isOwn, publishedCount: $publishedCount, draftCount: $draftCount, discoveredCount: $discoveredCount, completedCount: $completedCount, worlds: $worlds, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class $ProfilePageCopyWith<$Res>  {
  factory $ProfilePageCopyWith(ProfilePage value, $Res Function(ProfilePage) _then) = _$ProfilePageCopyWithImpl;
@useResult
$Res call({
 String username, String? displayName, String? bio, bool isOwn, int publishedCount, int? draftCount, int? discoveredCount, int? completedCount, List<ProfileWorld> worlds, bool hasMore
});




}
/// @nodoc
class _$ProfilePageCopyWithImpl<$Res>
    implements $ProfilePageCopyWith<$Res> {
  _$ProfilePageCopyWithImpl(this._self, this._then);

  final ProfilePage _self;
  final $Res Function(ProfilePage) _then;

/// Create a copy of ProfilePage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? username = null,Object? displayName = freezed,Object? bio = freezed,Object? isOwn = null,Object? publishedCount = null,Object? draftCount = freezed,Object? discoveredCount = freezed,Object? completedCount = freezed,Object? worlds = null,Object? hasMore = null,}) {
  return _then(_self.copyWith(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,isOwn: null == isOwn ? _self.isOwn : isOwn // ignore: cast_nullable_to_non_nullable
as bool,publishedCount: null == publishedCount ? _self.publishedCount : publishedCount // ignore: cast_nullable_to_non_nullable
as int,draftCount: freezed == draftCount ? _self.draftCount : draftCount // ignore: cast_nullable_to_non_nullable
as int?,discoveredCount: freezed == discoveredCount ? _self.discoveredCount : discoveredCount // ignore: cast_nullable_to_non_nullable
as int?,completedCount: freezed == completedCount ? _self.completedCount : completedCount // ignore: cast_nullable_to_non_nullable
as int?,worlds: null == worlds ? _self.worlds : worlds // ignore: cast_nullable_to_non_nullable
as List<ProfileWorld>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfilePage].
extension ProfilePagePatterns on ProfilePage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfilePage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfilePage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfilePage value)  $default,){
final _that = this;
switch (_that) {
case _ProfilePage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfilePage value)?  $default,){
final _that = this;
switch (_that) {
case _ProfilePage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String username,  String? displayName,  String? bio,  bool isOwn,  int publishedCount,  int? draftCount,  int? discoveredCount,  int? completedCount,  List<ProfileWorld> worlds,  bool hasMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfilePage() when $default != null:
return $default(_that.username,_that.displayName,_that.bio,_that.isOwn,_that.publishedCount,_that.draftCount,_that.discoveredCount,_that.completedCount,_that.worlds,_that.hasMore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String username,  String? displayName,  String? bio,  bool isOwn,  int publishedCount,  int? draftCount,  int? discoveredCount,  int? completedCount,  List<ProfileWorld> worlds,  bool hasMore)  $default,) {final _that = this;
switch (_that) {
case _ProfilePage():
return $default(_that.username,_that.displayName,_that.bio,_that.isOwn,_that.publishedCount,_that.draftCount,_that.discoveredCount,_that.completedCount,_that.worlds,_that.hasMore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String username,  String? displayName,  String? bio,  bool isOwn,  int publishedCount,  int? draftCount,  int? discoveredCount,  int? completedCount,  List<ProfileWorld> worlds,  bool hasMore)?  $default,) {final _that = this;
switch (_that) {
case _ProfilePage() when $default != null:
return $default(_that.username,_that.displayName,_that.bio,_that.isOwn,_that.publishedCount,_that.draftCount,_that.discoveredCount,_that.completedCount,_that.worlds,_that.hasMore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfilePage extends ProfilePage {
  const _ProfilePage({required this.username, this.displayName, this.bio, this.isOwn = false, required this.publishedCount, this.draftCount, this.discoveredCount, this.completedCount, final  List<ProfileWorld> worlds = const <ProfileWorld>[], this.hasMore = false}): _worlds = worlds,super._();
  factory _ProfilePage.fromJson(Map<String, dynamic> json) => _$ProfilePageFromJson(json);

@override final  String username;
@override final  String? displayName;
@override final  String? bio;
@override@JsonKey() final  bool isOwn;
@override final  int publishedCount;
/// Null unless this is the page of the signed-in user.
@override final  int? draftCount;
@override final  int? discoveredCount;
@override final  int? completedCount;
 final  List<ProfileWorld> _worlds;
@override@JsonKey() List<ProfileWorld> get worlds {
  if (_worlds is EqualUnmodifiableListView) return _worlds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_worlds);
}

@override@JsonKey() final  bool hasMore;

/// Create a copy of ProfilePage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfilePageCopyWith<_ProfilePage> get copyWith => __$ProfilePageCopyWithImpl<_ProfilePage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfilePageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfilePage&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.isOwn, isOwn) || other.isOwn == isOwn)&&(identical(other.publishedCount, publishedCount) || other.publishedCount == publishedCount)&&(identical(other.draftCount, draftCount) || other.draftCount == draftCount)&&(identical(other.discoveredCount, discoveredCount) || other.discoveredCount == discoveredCount)&&(identical(other.completedCount, completedCount) || other.completedCount == completedCount)&&const DeepCollectionEquality().equals(other._worlds, _worlds)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,displayName,bio,isOwn,publishedCount,draftCount,discoveredCount,completedCount,const DeepCollectionEquality().hash(_worlds),hasMore);

@override
String toString() {
  return 'ProfilePage(username: $username, displayName: $displayName, bio: $bio, isOwn: $isOwn, publishedCount: $publishedCount, draftCount: $draftCount, discoveredCount: $discoveredCount, completedCount: $completedCount, worlds: $worlds, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class _$ProfilePageCopyWith<$Res> implements $ProfilePageCopyWith<$Res> {
  factory _$ProfilePageCopyWith(_ProfilePage value, $Res Function(_ProfilePage) _then) = __$ProfilePageCopyWithImpl;
@override @useResult
$Res call({
 String username, String? displayName, String? bio, bool isOwn, int publishedCount, int? draftCount, int? discoveredCount, int? completedCount, List<ProfileWorld> worlds, bool hasMore
});




}
/// @nodoc
class __$ProfilePageCopyWithImpl<$Res>
    implements _$ProfilePageCopyWith<$Res> {
  __$ProfilePageCopyWithImpl(this._self, this._then);

  final _ProfilePage _self;
  final $Res Function(_ProfilePage) _then;

/// Create a copy of ProfilePage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? username = null,Object? displayName = freezed,Object? bio = freezed,Object? isOwn = null,Object? publishedCount = null,Object? draftCount = freezed,Object? discoveredCount = freezed,Object? completedCount = freezed,Object? worlds = null,Object? hasMore = null,}) {
  return _then(_ProfilePage(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,isOwn: null == isOwn ? _self.isOwn : isOwn // ignore: cast_nullable_to_non_nullable
as bool,publishedCount: null == publishedCount ? _self.publishedCount : publishedCount // ignore: cast_nullable_to_non_nullable
as int,draftCount: freezed == draftCount ? _self.draftCount : draftCount // ignore: cast_nullable_to_non_nullable
as int?,discoveredCount: freezed == discoveredCount ? _self.discoveredCount : discoveredCount // ignore: cast_nullable_to_non_nullable
as int?,completedCount: freezed == completedCount ? _self.completedCount : completedCount // ignore: cast_nullable_to_non_nullable
as int?,worlds: null == worlds ? _self._worlds : worlds // ignore: cast_nullable_to_non_nullable
as List<ProfileWorld>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
