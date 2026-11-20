// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'world_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorldAsset {

 String get id; String get storagePath; String get mimeType;
/// Create a copy of WorldAsset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorldAssetCopyWith<WorldAsset> get copyWith => _$WorldAssetCopyWithImpl<WorldAsset>(this as WorldAsset, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorldAsset&&(identical(other.id, id) || other.id == id)&&(identical(other.storagePath, storagePath) || other.storagePath == storagePath)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType));
}


@override
int get hashCode => Object.hash(runtimeType,id,storagePath,mimeType);

@override
String toString() {
  return 'WorldAsset(id: $id, storagePath: $storagePath, mimeType: $mimeType)';
}


}

/// @nodoc
abstract mixin class $WorldAssetCopyWith<$Res>  {
  factory $WorldAssetCopyWith(WorldAsset value, $Res Function(WorldAsset) _then) = _$WorldAssetCopyWithImpl;
@useResult
$Res call({
 String id, String storagePath, String mimeType
});




}
/// @nodoc
class _$WorldAssetCopyWithImpl<$Res>
    implements $WorldAssetCopyWith<$Res> {
  _$WorldAssetCopyWithImpl(this._self, this._then);

  final WorldAsset _self;
  final $Res Function(WorldAsset) _then;

/// Create a copy of WorldAsset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? storagePath = null,Object? mimeType = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storagePath: null == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WorldAsset].
extension WorldAssetPatterns on WorldAsset {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorldAsset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorldAsset() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorldAsset value)  $default,){
final _that = this;
switch (_that) {
case _WorldAsset():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorldAsset value)?  $default,){
final _that = this;
switch (_that) {
case _WorldAsset() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String storagePath,  String mimeType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorldAsset() when $default != null:
return $default(_that.id,_that.storagePath,_that.mimeType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String storagePath,  String mimeType)  $default,) {final _that = this;
switch (_that) {
case _WorldAsset():
return $default(_that.id,_that.storagePath,_that.mimeType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String storagePath,  String mimeType)?  $default,) {final _that = this;
switch (_that) {
case _WorldAsset() when $default != null:
return $default(_that.id,_that.storagePath,_that.mimeType);case _:
  return null;

}
}

}

/// @nodoc


class _WorldAsset implements WorldAsset {
  const _WorldAsset({required this.id, required this.storagePath, required this.mimeType});
  

@override final  String id;
@override final  String storagePath;
@override final  String mimeType;

/// Create a copy of WorldAsset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorldAssetCopyWith<_WorldAsset> get copyWith => __$WorldAssetCopyWithImpl<_WorldAsset>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorldAsset&&(identical(other.id, id) || other.id == id)&&(identical(other.storagePath, storagePath) || other.storagePath == storagePath)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType));
}


@override
int get hashCode => Object.hash(runtimeType,id,storagePath,mimeType);

@override
String toString() {
  return 'WorldAsset(id: $id, storagePath: $storagePath, mimeType: $mimeType)';
}


}

/// @nodoc
abstract mixin class _$WorldAssetCopyWith<$Res> implements $WorldAssetCopyWith<$Res> {
  factory _$WorldAssetCopyWith(_WorldAsset value, $Res Function(_WorldAsset) _then) = __$WorldAssetCopyWithImpl;
@override @useResult
$Res call({
 String id, String storagePath, String mimeType
});




}
/// @nodoc
class __$WorldAssetCopyWithImpl<$Res>
    implements _$WorldAssetCopyWith<$Res> {
  __$WorldAssetCopyWithImpl(this._self, this._then);

  final _WorldAsset _self;
  final $Res Function(_WorldAsset) _then;

/// Create a copy of WorldAsset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? storagePath = null,Object? mimeType = null,}) {
  return _then(_WorldAsset(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storagePath: null == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$WorldDraft {

 String get id; WorldCategory get category; String get title; String get description; String? get coverAssetId; GeoPoint? get location; int get unlockRadiusMeters; List<ContentBlock> get blocks; WorldStatus get status; DateTime? get publishedAt; List<WorldAsset> get assets;
/// Create a copy of WorldDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorldDraftCopyWith<WorldDraft> get copyWith => _$WorldDraftCopyWithImpl<WorldDraft>(this as WorldDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorldDraft&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.coverAssetId, coverAssetId) || other.coverAssetId == coverAssetId)&&(identical(other.location, location) || other.location == location)&&(identical(other.unlockRadiusMeters, unlockRadiusMeters) || other.unlockRadiusMeters == unlockRadiusMeters)&&const DeepCollectionEquality().equals(other.blocks, blocks)&&(identical(other.status, status) || other.status == status)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&const DeepCollectionEquality().equals(other.assets, assets));
}


@override
int get hashCode => Object.hash(runtimeType,id,category,title,description,coverAssetId,location,unlockRadiusMeters,const DeepCollectionEquality().hash(blocks),status,publishedAt,const DeepCollectionEquality().hash(assets));

@override
String toString() {
  return 'WorldDraft(id: $id, category: $category, title: $title, description: $description, coverAssetId: $coverAssetId, location: $location, unlockRadiusMeters: $unlockRadiusMeters, blocks: $blocks, status: $status, publishedAt: $publishedAt, assets: $assets)';
}


}

/// @nodoc
abstract mixin class $WorldDraftCopyWith<$Res>  {
  factory $WorldDraftCopyWith(WorldDraft value, $Res Function(WorldDraft) _then) = _$WorldDraftCopyWithImpl;
@useResult
$Res call({
 String id, WorldCategory category, String title, String description, String? coverAssetId, GeoPoint? location, int unlockRadiusMeters, List<ContentBlock> blocks, WorldStatus status, DateTime? publishedAt, List<WorldAsset> assets
});


$GeoPointCopyWith<$Res>? get location;

}
/// @nodoc
class _$WorldDraftCopyWithImpl<$Res>
    implements $WorldDraftCopyWith<$Res> {
  _$WorldDraftCopyWithImpl(this._self, this._then);

  final WorldDraft _self;
  final $Res Function(WorldDraft) _then;

/// Create a copy of WorldDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? category = null,Object? title = null,Object? description = null,Object? coverAssetId = freezed,Object? location = freezed,Object? unlockRadiusMeters = null,Object? blocks = null,Object? status = null,Object? publishedAt = freezed,Object? assets = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WorldCategory,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,coverAssetId: freezed == coverAssetId ? _self.coverAssetId : coverAssetId // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint?,unlockRadiusMeters: null == unlockRadiusMeters ? _self.unlockRadiusMeters : unlockRadiusMeters // ignore: cast_nullable_to_non_nullable
as int,blocks: null == blocks ? _self.blocks : blocks // ignore: cast_nullable_to_non_nullable
as List<ContentBlock>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorldStatus,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,assets: null == assets ? _self.assets : assets // ignore: cast_nullable_to_non_nullable
as List<WorldAsset>,
  ));
}
/// Create a copy of WorldDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorldDraft].
extension WorldDraftPatterns on WorldDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorldDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorldDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorldDraft value)  $default,){
final _that = this;
switch (_that) {
case _WorldDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorldDraft value)?  $default,){
final _that = this;
switch (_that) {
case _WorldDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  WorldCategory category,  String title,  String description,  String? coverAssetId,  GeoPoint? location,  int unlockRadiusMeters,  List<ContentBlock> blocks,  WorldStatus status,  DateTime? publishedAt,  List<WorldAsset> assets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorldDraft() when $default != null:
return $default(_that.id,_that.category,_that.title,_that.description,_that.coverAssetId,_that.location,_that.unlockRadiusMeters,_that.blocks,_that.status,_that.publishedAt,_that.assets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  WorldCategory category,  String title,  String description,  String? coverAssetId,  GeoPoint? location,  int unlockRadiusMeters,  List<ContentBlock> blocks,  WorldStatus status,  DateTime? publishedAt,  List<WorldAsset> assets)  $default,) {final _that = this;
switch (_that) {
case _WorldDraft():
return $default(_that.id,_that.category,_that.title,_that.description,_that.coverAssetId,_that.location,_that.unlockRadiusMeters,_that.blocks,_that.status,_that.publishedAt,_that.assets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  WorldCategory category,  String title,  String description,  String? coverAssetId,  GeoPoint? location,  int unlockRadiusMeters,  List<ContentBlock> blocks,  WorldStatus status,  DateTime? publishedAt,  List<WorldAsset> assets)?  $default,) {final _that = this;
switch (_that) {
case _WorldDraft() when $default != null:
return $default(_that.id,_that.category,_that.title,_that.description,_that.coverAssetId,_that.location,_that.unlockRadiusMeters,_that.blocks,_that.status,_that.publishedAt,_that.assets);case _:
  return null;

}
}

}

/// @nodoc


class _WorldDraft extends WorldDraft {
  const _WorldDraft({required this.id, required this.category, this.title = '', this.description = '', this.coverAssetId, this.location, this.unlockRadiusMeters = WorldDraft.defaultRadius, final  List<ContentBlock> blocks = const <ContentBlock>[], this.status = WorldStatus.draft, this.publishedAt, final  List<WorldAsset> assets = const <WorldAsset>[]}): _blocks = blocks,_assets = assets,super._();
  

@override final  String id;
@override final  WorldCategory category;
@override@JsonKey() final  String title;
@override@JsonKey() final  String description;
@override final  String? coverAssetId;
@override final  GeoPoint? location;
@override@JsonKey() final  int unlockRadiusMeters;
 final  List<ContentBlock> _blocks;
@override@JsonKey() List<ContentBlock> get blocks {
  if (_blocks is EqualUnmodifiableListView) return _blocks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_blocks);
}

@override@JsonKey() final  WorldStatus status;
@override final  DateTime? publishedAt;
 final  List<WorldAsset> _assets;
@override@JsonKey() List<WorldAsset> get assets {
  if (_assets is EqualUnmodifiableListView) return _assets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assets);
}


/// Create a copy of WorldDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorldDraftCopyWith<_WorldDraft> get copyWith => __$WorldDraftCopyWithImpl<_WorldDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorldDraft&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.coverAssetId, coverAssetId) || other.coverAssetId == coverAssetId)&&(identical(other.location, location) || other.location == location)&&(identical(other.unlockRadiusMeters, unlockRadiusMeters) || other.unlockRadiusMeters == unlockRadiusMeters)&&const DeepCollectionEquality().equals(other._blocks, _blocks)&&(identical(other.status, status) || other.status == status)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&const DeepCollectionEquality().equals(other._assets, _assets));
}


@override
int get hashCode => Object.hash(runtimeType,id,category,title,description,coverAssetId,location,unlockRadiusMeters,const DeepCollectionEquality().hash(_blocks),status,publishedAt,const DeepCollectionEquality().hash(_assets));

@override
String toString() {
  return 'WorldDraft(id: $id, category: $category, title: $title, description: $description, coverAssetId: $coverAssetId, location: $location, unlockRadiusMeters: $unlockRadiusMeters, blocks: $blocks, status: $status, publishedAt: $publishedAt, assets: $assets)';
}


}

/// @nodoc
abstract mixin class _$WorldDraftCopyWith<$Res> implements $WorldDraftCopyWith<$Res> {
  factory _$WorldDraftCopyWith(_WorldDraft value, $Res Function(_WorldDraft) _then) = __$WorldDraftCopyWithImpl;
@override @useResult
$Res call({
 String id, WorldCategory category, String title, String description, String? coverAssetId, GeoPoint? location, int unlockRadiusMeters, List<ContentBlock> blocks, WorldStatus status, DateTime? publishedAt, List<WorldAsset> assets
});


@override $GeoPointCopyWith<$Res>? get location;

}
/// @nodoc
class __$WorldDraftCopyWithImpl<$Res>
    implements _$WorldDraftCopyWith<$Res> {
  __$WorldDraftCopyWithImpl(this._self, this._then);

  final _WorldDraft _self;
  final $Res Function(_WorldDraft) _then;

/// Create a copy of WorldDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? category = null,Object? title = null,Object? description = null,Object? coverAssetId = freezed,Object? location = freezed,Object? unlockRadiusMeters = null,Object? blocks = null,Object? status = null,Object? publishedAt = freezed,Object? assets = null,}) {
  return _then(_WorldDraft(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WorldCategory,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,coverAssetId: freezed == coverAssetId ? _self.coverAssetId : coverAssetId // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint?,unlockRadiusMeters: null == unlockRadiusMeters ? _self.unlockRadiusMeters : unlockRadiusMeters // ignore: cast_nullable_to_non_nullable
as int,blocks: null == blocks ? _self._blocks : blocks // ignore: cast_nullable_to_non_nullable
as List<ContentBlock>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorldStatus,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,assets: null == assets ? _self._assets : assets // ignore: cast_nullable_to_non_nullable
as List<WorldAsset>,
  ));
}

/// Create a copy of WorldDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}

/// @nodoc
mixin _$WorldSummary {

 String get id; String get title; WorldCategory get category; WorldStatus get status; DateTime? get publishedAt; DateTime get updatedAt;
/// Create a copy of WorldSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorldSummaryCopyWith<WorldSummary> get copyWith => _$WorldSummaryCopyWithImpl<WorldSummary>(this as WorldSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorldSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,category,status,publishedAt,updatedAt);

@override
String toString() {
  return 'WorldSummary(id: $id, title: $title, category: $category, status: $status, publishedAt: $publishedAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $WorldSummaryCopyWith<$Res>  {
  factory $WorldSummaryCopyWith(WorldSummary value, $Res Function(WorldSummary) _then) = _$WorldSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String title, WorldCategory category, WorldStatus status, DateTime? publishedAt, DateTime updatedAt
});




}
/// @nodoc
class _$WorldSummaryCopyWithImpl<$Res>
    implements $WorldSummaryCopyWith<$Res> {
  _$WorldSummaryCopyWithImpl(this._self, this._then);

  final WorldSummary _self;
  final $Res Function(WorldSummary) _then;

/// Create a copy of WorldSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? category = null,Object? status = null,Object? publishedAt = freezed,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WorldCategory,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorldStatus,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [WorldSummary].
extension WorldSummaryPatterns on WorldSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorldSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorldSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorldSummary value)  $default,){
final _that = this;
switch (_that) {
case _WorldSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorldSummary value)?  $default,){
final _that = this;
switch (_that) {
case _WorldSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  WorldCategory category,  WorldStatus status,  DateTime? publishedAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorldSummary() when $default != null:
return $default(_that.id,_that.title,_that.category,_that.status,_that.publishedAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  WorldCategory category,  WorldStatus status,  DateTime? publishedAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _WorldSummary():
return $default(_that.id,_that.title,_that.category,_that.status,_that.publishedAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  WorldCategory category,  WorldStatus status,  DateTime? publishedAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _WorldSummary() when $default != null:
return $default(_that.id,_that.title,_that.category,_that.status,_that.publishedAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _WorldSummary extends WorldSummary {
  const _WorldSummary({required this.id, required this.title, required this.category, required this.status, this.publishedAt, required this.updatedAt}): super._();
  

@override final  String id;
@override final  String title;
@override final  WorldCategory category;
@override final  WorldStatus status;
@override final  DateTime? publishedAt;
@override final  DateTime updatedAt;

/// Create a copy of WorldSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorldSummaryCopyWith<_WorldSummary> get copyWith => __$WorldSummaryCopyWithImpl<_WorldSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorldSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,category,status,publishedAt,updatedAt);

@override
String toString() {
  return 'WorldSummary(id: $id, title: $title, category: $category, status: $status, publishedAt: $publishedAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$WorldSummaryCopyWith<$Res> implements $WorldSummaryCopyWith<$Res> {
  factory _$WorldSummaryCopyWith(_WorldSummary value, $Res Function(_WorldSummary) _then) = __$WorldSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, WorldCategory category, WorldStatus status, DateTime? publishedAt, DateTime updatedAt
});




}
/// @nodoc
class __$WorldSummaryCopyWithImpl<$Res>
    implements _$WorldSummaryCopyWith<$Res> {
  __$WorldSummaryCopyWithImpl(this._self, this._then);

  final _WorldSummary _self;
  final $Res Function(_WorldSummary) _then;

/// Create a copy of WorldSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? category = null,Object? status = null,Object? publishedAt = freezed,Object? updatedAt = null,}) {
  return _then(_WorldSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WorldCategory,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorldStatus,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
