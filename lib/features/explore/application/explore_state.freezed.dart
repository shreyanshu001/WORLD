// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'explore_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExploreState {

/// The centre of the current search; null until the user picks an area.
 GeoPoint? get searchCenter;/// Whether [searchCenter] is the user's own position.
 bool get centerIsUserLocation; WorldCategory? get category; String get searchText; List<WorldPreview> get worlds; bool get loading;/// Whether a search has completed at least once for an area.
 bool get searched; AppFailure? get error; String? get selectedWorldId; LocationStatus get locationStatus;/// The single position sample taken when the user tapped locate.
 GeoPoint? get userLocation; CameraRequest? get cameraRequest; ExploreView get view;
/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExploreStateCopyWith<ExploreState> get copyWith => _$ExploreStateCopyWithImpl<ExploreState>(this as ExploreState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExploreState&&(identical(other.searchCenter, searchCenter) || other.searchCenter == searchCenter)&&(identical(other.centerIsUserLocation, centerIsUserLocation) || other.centerIsUserLocation == centerIsUserLocation)&&(identical(other.category, category) || other.category == category)&&(identical(other.searchText, searchText) || other.searchText == searchText)&&const DeepCollectionEquality().equals(other.worlds, worlds)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.searched, searched) || other.searched == searched)&&(identical(other.error, error) || other.error == error)&&(identical(other.selectedWorldId, selectedWorldId) || other.selectedWorldId == selectedWorldId)&&(identical(other.locationStatus, locationStatus) || other.locationStatus == locationStatus)&&(identical(other.userLocation, userLocation) || other.userLocation == userLocation)&&(identical(other.cameraRequest, cameraRequest) || other.cameraRequest == cameraRequest)&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,searchCenter,centerIsUserLocation,category,searchText,const DeepCollectionEquality().hash(worlds),loading,searched,error,selectedWorldId,locationStatus,userLocation,cameraRequest,view);

@override
String toString() {
  return 'ExploreState(searchCenter: $searchCenter, centerIsUserLocation: $centerIsUserLocation, category: $category, searchText: $searchText, worlds: $worlds, loading: $loading, searched: $searched, error: $error, selectedWorldId: $selectedWorldId, locationStatus: $locationStatus, userLocation: $userLocation, cameraRequest: $cameraRequest, view: $view)';
}


}

/// @nodoc
abstract mixin class $ExploreStateCopyWith<$Res>  {
  factory $ExploreStateCopyWith(ExploreState value, $Res Function(ExploreState) _then) = _$ExploreStateCopyWithImpl;
@useResult
$Res call({
 GeoPoint? searchCenter, bool centerIsUserLocation, WorldCategory? category, String searchText, List<WorldPreview> worlds, bool loading, bool searched, AppFailure? error, String? selectedWorldId, LocationStatus locationStatus, GeoPoint? userLocation, CameraRequest? cameraRequest, ExploreView view
});


$GeoPointCopyWith<$Res>? get searchCenter;$AppFailureCopyWith<$Res>? get error;$GeoPointCopyWith<$Res>? get userLocation;

}
/// @nodoc
class _$ExploreStateCopyWithImpl<$Res>
    implements $ExploreStateCopyWith<$Res> {
  _$ExploreStateCopyWithImpl(this._self, this._then);

  final ExploreState _self;
  final $Res Function(ExploreState) _then;

/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? searchCenter = freezed,Object? centerIsUserLocation = null,Object? category = freezed,Object? searchText = null,Object? worlds = null,Object? loading = null,Object? searched = null,Object? error = freezed,Object? selectedWorldId = freezed,Object? locationStatus = null,Object? userLocation = freezed,Object? cameraRequest = freezed,Object? view = null,}) {
  return _then(_self.copyWith(
searchCenter: freezed == searchCenter ? _self.searchCenter : searchCenter // ignore: cast_nullable_to_non_nullable
as GeoPoint?,centerIsUserLocation: null == centerIsUserLocation ? _self.centerIsUserLocation : centerIsUserLocation // ignore: cast_nullable_to_non_nullable
as bool,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WorldCategory?,searchText: null == searchText ? _self.searchText : searchText // ignore: cast_nullable_to_non_nullable
as String,worlds: null == worlds ? _self.worlds : worlds // ignore: cast_nullable_to_non_nullable
as List<WorldPreview>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,searched: null == searched ? _self.searched : searched // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as AppFailure?,selectedWorldId: freezed == selectedWorldId ? _self.selectedWorldId : selectedWorldId // ignore: cast_nullable_to_non_nullable
as String?,locationStatus: null == locationStatus ? _self.locationStatus : locationStatus // ignore: cast_nullable_to_non_nullable
as LocationStatus,userLocation: freezed == userLocation ? _self.userLocation : userLocation // ignore: cast_nullable_to_non_nullable
as GeoPoint?,cameraRequest: freezed == cameraRequest ? _self.cameraRequest : cameraRequest // ignore: cast_nullable_to_non_nullable
as CameraRequest?,view: null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as ExploreView,
  ));
}
/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get searchCenter {
    if (_self.searchCenter == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.searchCenter!, (value) {
    return _then(_self.copyWith(searchCenter: value));
  });
}/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res>? get error {
    if (_self.error == null) {
    return null;
  }

  return $AppFailureCopyWith<$Res>(_self.error!, (value) {
    return _then(_self.copyWith(error: value));
  });
}/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get userLocation {
    if (_self.userLocation == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.userLocation!, (value) {
    return _then(_self.copyWith(userLocation: value));
  });
}
}


/// Adds pattern-matching-related methods to [ExploreState].
extension ExploreStatePatterns on ExploreState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExploreState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExploreState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExploreState value)  $default,){
final _that = this;
switch (_that) {
case _ExploreState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExploreState value)?  $default,){
final _that = this;
switch (_that) {
case _ExploreState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GeoPoint? searchCenter,  bool centerIsUserLocation,  WorldCategory? category,  String searchText,  List<WorldPreview> worlds,  bool loading,  bool searched,  AppFailure? error,  String? selectedWorldId,  LocationStatus locationStatus,  GeoPoint? userLocation,  CameraRequest? cameraRequest,  ExploreView view)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExploreState() when $default != null:
return $default(_that.searchCenter,_that.centerIsUserLocation,_that.category,_that.searchText,_that.worlds,_that.loading,_that.searched,_that.error,_that.selectedWorldId,_that.locationStatus,_that.userLocation,_that.cameraRequest,_that.view);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GeoPoint? searchCenter,  bool centerIsUserLocation,  WorldCategory? category,  String searchText,  List<WorldPreview> worlds,  bool loading,  bool searched,  AppFailure? error,  String? selectedWorldId,  LocationStatus locationStatus,  GeoPoint? userLocation,  CameraRequest? cameraRequest,  ExploreView view)  $default,) {final _that = this;
switch (_that) {
case _ExploreState():
return $default(_that.searchCenter,_that.centerIsUserLocation,_that.category,_that.searchText,_that.worlds,_that.loading,_that.searched,_that.error,_that.selectedWorldId,_that.locationStatus,_that.userLocation,_that.cameraRequest,_that.view);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GeoPoint? searchCenter,  bool centerIsUserLocation,  WorldCategory? category,  String searchText,  List<WorldPreview> worlds,  bool loading,  bool searched,  AppFailure? error,  String? selectedWorldId,  LocationStatus locationStatus,  GeoPoint? userLocation,  CameraRequest? cameraRequest,  ExploreView view)?  $default,) {final _that = this;
switch (_that) {
case _ExploreState() when $default != null:
return $default(_that.searchCenter,_that.centerIsUserLocation,_that.category,_that.searchText,_that.worlds,_that.loading,_that.searched,_that.error,_that.selectedWorldId,_that.locationStatus,_that.userLocation,_that.cameraRequest,_that.view);case _:
  return null;

}
}

}

/// @nodoc


class _ExploreState extends ExploreState {
  const _ExploreState({this.searchCenter, this.centerIsUserLocation = false, this.category, this.searchText = '', final  List<WorldPreview> worlds = const <WorldPreview>[], this.loading = false, this.searched = false, this.error, this.selectedWorldId, this.locationStatus = LocationStatus.notRequested, this.userLocation, this.cameraRequest, this.view = ExploreView.map}): _worlds = worlds,super._();
  

/// The centre of the current search; null until the user picks an area.
@override final  GeoPoint? searchCenter;
/// Whether [searchCenter] is the user's own position.
@override@JsonKey() final  bool centerIsUserLocation;
@override final  WorldCategory? category;
@override@JsonKey() final  String searchText;
 final  List<WorldPreview> _worlds;
@override@JsonKey() List<WorldPreview> get worlds {
  if (_worlds is EqualUnmodifiableListView) return _worlds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_worlds);
}

@override@JsonKey() final  bool loading;
/// Whether a search has completed at least once for an area.
@override@JsonKey() final  bool searched;
@override final  AppFailure? error;
@override final  String? selectedWorldId;
@override@JsonKey() final  LocationStatus locationStatus;
/// The single position sample taken when the user tapped locate.
@override final  GeoPoint? userLocation;
@override final  CameraRequest? cameraRequest;
@override@JsonKey() final  ExploreView view;

/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExploreStateCopyWith<_ExploreState> get copyWith => __$ExploreStateCopyWithImpl<_ExploreState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExploreState&&(identical(other.searchCenter, searchCenter) || other.searchCenter == searchCenter)&&(identical(other.centerIsUserLocation, centerIsUserLocation) || other.centerIsUserLocation == centerIsUserLocation)&&(identical(other.category, category) || other.category == category)&&(identical(other.searchText, searchText) || other.searchText == searchText)&&const DeepCollectionEquality().equals(other._worlds, _worlds)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.searched, searched) || other.searched == searched)&&(identical(other.error, error) || other.error == error)&&(identical(other.selectedWorldId, selectedWorldId) || other.selectedWorldId == selectedWorldId)&&(identical(other.locationStatus, locationStatus) || other.locationStatus == locationStatus)&&(identical(other.userLocation, userLocation) || other.userLocation == userLocation)&&(identical(other.cameraRequest, cameraRequest) || other.cameraRequest == cameraRequest)&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,searchCenter,centerIsUserLocation,category,searchText,const DeepCollectionEquality().hash(_worlds),loading,searched,error,selectedWorldId,locationStatus,userLocation,cameraRequest,view);

@override
String toString() {
  return 'ExploreState(searchCenter: $searchCenter, centerIsUserLocation: $centerIsUserLocation, category: $category, searchText: $searchText, worlds: $worlds, loading: $loading, searched: $searched, error: $error, selectedWorldId: $selectedWorldId, locationStatus: $locationStatus, userLocation: $userLocation, cameraRequest: $cameraRequest, view: $view)';
}


}

/// @nodoc
abstract mixin class _$ExploreStateCopyWith<$Res> implements $ExploreStateCopyWith<$Res> {
  factory _$ExploreStateCopyWith(_ExploreState value, $Res Function(_ExploreState) _then) = __$ExploreStateCopyWithImpl;
@override @useResult
$Res call({
 GeoPoint? searchCenter, bool centerIsUserLocation, WorldCategory? category, String searchText, List<WorldPreview> worlds, bool loading, bool searched, AppFailure? error, String? selectedWorldId, LocationStatus locationStatus, GeoPoint? userLocation, CameraRequest? cameraRequest, ExploreView view
});


@override $GeoPointCopyWith<$Res>? get searchCenter;@override $AppFailureCopyWith<$Res>? get error;@override $GeoPointCopyWith<$Res>? get userLocation;

}
/// @nodoc
class __$ExploreStateCopyWithImpl<$Res>
    implements _$ExploreStateCopyWith<$Res> {
  __$ExploreStateCopyWithImpl(this._self, this._then);

  final _ExploreState _self;
  final $Res Function(_ExploreState) _then;

/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? searchCenter = freezed,Object? centerIsUserLocation = null,Object? category = freezed,Object? searchText = null,Object? worlds = null,Object? loading = null,Object? searched = null,Object? error = freezed,Object? selectedWorldId = freezed,Object? locationStatus = null,Object? userLocation = freezed,Object? cameraRequest = freezed,Object? view = null,}) {
  return _then(_ExploreState(
searchCenter: freezed == searchCenter ? _self.searchCenter : searchCenter // ignore: cast_nullable_to_non_nullable
as GeoPoint?,centerIsUserLocation: null == centerIsUserLocation ? _self.centerIsUserLocation : centerIsUserLocation // ignore: cast_nullable_to_non_nullable
as bool,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WorldCategory?,searchText: null == searchText ? _self.searchText : searchText // ignore: cast_nullable_to_non_nullable
as String,worlds: null == worlds ? _self._worlds : worlds // ignore: cast_nullable_to_non_nullable
as List<WorldPreview>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,searched: null == searched ? _self.searched : searched // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as AppFailure?,selectedWorldId: freezed == selectedWorldId ? _self.selectedWorldId : selectedWorldId // ignore: cast_nullable_to_non_nullable
as String?,locationStatus: null == locationStatus ? _self.locationStatus : locationStatus // ignore: cast_nullable_to_non_nullable
as LocationStatus,userLocation: freezed == userLocation ? _self.userLocation : userLocation // ignore: cast_nullable_to_non_nullable
as GeoPoint?,cameraRequest: freezed == cameraRequest ? _self.cameraRequest : cameraRequest // ignore: cast_nullable_to_non_nullable
as CameraRequest?,view: null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as ExploreView,
  ));
}

/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get searchCenter {
    if (_self.searchCenter == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.searchCenter!, (value) {
    return _then(_self.copyWith(searchCenter: value));
  });
}/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res>? get error {
    if (_self.error == null) {
    return null;
  }

  return $AppFailureCopyWith<$Res>(_self.error!, (value) {
    return _then(_self.copyWith(error: value));
  });
}/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get userLocation {
    if (_self.userLocation == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.userLocation!, (value) {
    return _then(_self.copyWith(userLocation: value));
  });
}
}

// dart format on
