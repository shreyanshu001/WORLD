// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'world_editor_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorldEditorState {

 String get worldId;/// What the creator is editing; null until a category is chosen for a
/// new World, or while an existing World loads.
 WorldDraft? get draft;/// The copy last confirmed by the server; null if never saved.
 WorldDraft? get saved; bool get loading; AppFailure? get loadError; EditorStep get step; bool get saving; AppFailure? get saveError;/// Questions whose new answer will be sent with the next save. The
/// answers themselves are kept out of this state so they are never
/// logged or shown.
 Set<String> get pendingAnswerIds;/// Upload targets in progress: block ids, or [coverUploadTarget].
 Set<String> get uploading;/// Upload targets whose last upload failed and can be retried.
 Set<String> get failedUploads; AppFailure? get uploadError; bool get publishing;/// Problems the server reported on the last publish attempt.
 List<PublishProblem> get serverProblems; PickerLocationStatus get locationStatus;/// Moves the place picker's map once.
 CameraRequest? get cameraRequest;/// False when the place picker was last left too far out to place the
/// pin precisely.
 bool get pickerZoomedIn; bool get deleted;
/// Create a copy of WorldEditorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorldEditorStateCopyWith<WorldEditorState> get copyWith => _$WorldEditorStateCopyWithImpl<WorldEditorState>(this as WorldEditorState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorldEditorState&&(identical(other.worldId, worldId) || other.worldId == worldId)&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.saved, saved) || other.saved == saved)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.loadError, loadError) || other.loadError == loadError)&&(identical(other.step, step) || other.step == step)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.saveError, saveError) || other.saveError == saveError)&&const DeepCollectionEquality().equals(other.pendingAnswerIds, pendingAnswerIds)&&const DeepCollectionEquality().equals(other.uploading, uploading)&&const DeepCollectionEquality().equals(other.failedUploads, failedUploads)&&(identical(other.uploadError, uploadError) || other.uploadError == uploadError)&&(identical(other.publishing, publishing) || other.publishing == publishing)&&const DeepCollectionEquality().equals(other.serverProblems, serverProblems)&&(identical(other.locationStatus, locationStatus) || other.locationStatus == locationStatus)&&(identical(other.cameraRequest, cameraRequest) || other.cameraRequest == cameraRequest)&&(identical(other.pickerZoomedIn, pickerZoomedIn) || other.pickerZoomedIn == pickerZoomedIn)&&(identical(other.deleted, deleted) || other.deleted == deleted));
}


@override
int get hashCode => Object.hash(runtimeType,worldId,draft,saved,loading,loadError,step,saving,saveError,const DeepCollectionEquality().hash(pendingAnswerIds),const DeepCollectionEquality().hash(uploading),const DeepCollectionEquality().hash(failedUploads),uploadError,publishing,const DeepCollectionEquality().hash(serverProblems),locationStatus,cameraRequest,pickerZoomedIn,deleted);

@override
String toString() {
  return 'WorldEditorState(worldId: $worldId, draft: $draft, saved: $saved, loading: $loading, loadError: $loadError, step: $step, saving: $saving, saveError: $saveError, pendingAnswerIds: $pendingAnswerIds, uploading: $uploading, failedUploads: $failedUploads, uploadError: $uploadError, publishing: $publishing, serverProblems: $serverProblems, locationStatus: $locationStatus, cameraRequest: $cameraRequest, pickerZoomedIn: $pickerZoomedIn, deleted: $deleted)';
}


}

/// @nodoc
abstract mixin class $WorldEditorStateCopyWith<$Res>  {
  factory $WorldEditorStateCopyWith(WorldEditorState value, $Res Function(WorldEditorState) _then) = _$WorldEditorStateCopyWithImpl;
@useResult
$Res call({
 String worldId, WorldDraft? draft, WorldDraft? saved, bool loading, AppFailure? loadError, EditorStep step, bool saving, AppFailure? saveError, Set<String> pendingAnswerIds, Set<String> uploading, Set<String> failedUploads, AppFailure? uploadError, bool publishing, List<PublishProblem> serverProblems, PickerLocationStatus locationStatus, CameraRequest? cameraRequest, bool pickerZoomedIn, bool deleted
});


$WorldDraftCopyWith<$Res>? get draft;$WorldDraftCopyWith<$Res>? get saved;$AppFailureCopyWith<$Res>? get loadError;$AppFailureCopyWith<$Res>? get saveError;$AppFailureCopyWith<$Res>? get uploadError;

}
/// @nodoc
class _$WorldEditorStateCopyWithImpl<$Res>
    implements $WorldEditorStateCopyWith<$Res> {
  _$WorldEditorStateCopyWithImpl(this._self, this._then);

  final WorldEditorState _self;
  final $Res Function(WorldEditorState) _then;

/// Create a copy of WorldEditorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? worldId = null,Object? draft = freezed,Object? saved = freezed,Object? loading = null,Object? loadError = freezed,Object? step = null,Object? saving = null,Object? saveError = freezed,Object? pendingAnswerIds = null,Object? uploading = null,Object? failedUploads = null,Object? uploadError = freezed,Object? publishing = null,Object? serverProblems = null,Object? locationStatus = null,Object? cameraRequest = freezed,Object? pickerZoomedIn = null,Object? deleted = null,}) {
  return _then(_self.copyWith(
worldId: null == worldId ? _self.worldId : worldId // ignore: cast_nullable_to_non_nullable
as String,draft: freezed == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as WorldDraft?,saved: freezed == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as WorldDraft?,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadError: freezed == loadError ? _self.loadError : loadError // ignore: cast_nullable_to_non_nullable
as AppFailure?,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as EditorStep,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,saveError: freezed == saveError ? _self.saveError : saveError // ignore: cast_nullable_to_non_nullable
as AppFailure?,pendingAnswerIds: null == pendingAnswerIds ? _self.pendingAnswerIds : pendingAnswerIds // ignore: cast_nullable_to_non_nullable
as Set<String>,uploading: null == uploading ? _self.uploading : uploading // ignore: cast_nullable_to_non_nullable
as Set<String>,failedUploads: null == failedUploads ? _self.failedUploads : failedUploads // ignore: cast_nullable_to_non_nullable
as Set<String>,uploadError: freezed == uploadError ? _self.uploadError : uploadError // ignore: cast_nullable_to_non_nullable
as AppFailure?,publishing: null == publishing ? _self.publishing : publishing // ignore: cast_nullable_to_non_nullable
as bool,serverProblems: null == serverProblems ? _self.serverProblems : serverProblems // ignore: cast_nullable_to_non_nullable
as List<PublishProblem>,locationStatus: null == locationStatus ? _self.locationStatus : locationStatus // ignore: cast_nullable_to_non_nullable
as PickerLocationStatus,cameraRequest: freezed == cameraRequest ? _self.cameraRequest : cameraRequest // ignore: cast_nullable_to_non_nullable
as CameraRequest?,pickerZoomedIn: null == pickerZoomedIn ? _self.pickerZoomedIn : pickerZoomedIn // ignore: cast_nullable_to_non_nullable
as bool,deleted: null == deleted ? _self.deleted : deleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of WorldEditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorldDraftCopyWith<$Res>? get draft {
    if (_self.draft == null) {
    return null;
  }

  return $WorldDraftCopyWith<$Res>(_self.draft!, (value) {
    return _then(_self.copyWith(draft: value));
  });
}/// Create a copy of WorldEditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorldDraftCopyWith<$Res>? get saved {
    if (_self.saved == null) {
    return null;
  }

  return $WorldDraftCopyWith<$Res>(_self.saved!, (value) {
    return _then(_self.copyWith(saved: value));
  });
}/// Create a copy of WorldEditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res>? get loadError {
    if (_self.loadError == null) {
    return null;
  }

  return $AppFailureCopyWith<$Res>(_self.loadError!, (value) {
    return _then(_self.copyWith(loadError: value));
  });
}/// Create a copy of WorldEditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res>? get saveError {
    if (_self.saveError == null) {
    return null;
  }

  return $AppFailureCopyWith<$Res>(_self.saveError!, (value) {
    return _then(_self.copyWith(saveError: value));
  });
}/// Create a copy of WorldEditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res>? get uploadError {
    if (_self.uploadError == null) {
    return null;
  }

  return $AppFailureCopyWith<$Res>(_self.uploadError!, (value) {
    return _then(_self.copyWith(uploadError: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorldEditorState].
extension WorldEditorStatePatterns on WorldEditorState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorldEditorState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorldEditorState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorldEditorState value)  $default,){
final _that = this;
switch (_that) {
case _WorldEditorState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorldEditorState value)?  $default,){
final _that = this;
switch (_that) {
case _WorldEditorState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String worldId,  WorldDraft? draft,  WorldDraft? saved,  bool loading,  AppFailure? loadError,  EditorStep step,  bool saving,  AppFailure? saveError,  Set<String> pendingAnswerIds,  Set<String> uploading,  Set<String> failedUploads,  AppFailure? uploadError,  bool publishing,  List<PublishProblem> serverProblems,  PickerLocationStatus locationStatus,  CameraRequest? cameraRequest,  bool pickerZoomedIn,  bool deleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorldEditorState() when $default != null:
return $default(_that.worldId,_that.draft,_that.saved,_that.loading,_that.loadError,_that.step,_that.saving,_that.saveError,_that.pendingAnswerIds,_that.uploading,_that.failedUploads,_that.uploadError,_that.publishing,_that.serverProblems,_that.locationStatus,_that.cameraRequest,_that.pickerZoomedIn,_that.deleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String worldId,  WorldDraft? draft,  WorldDraft? saved,  bool loading,  AppFailure? loadError,  EditorStep step,  bool saving,  AppFailure? saveError,  Set<String> pendingAnswerIds,  Set<String> uploading,  Set<String> failedUploads,  AppFailure? uploadError,  bool publishing,  List<PublishProblem> serverProblems,  PickerLocationStatus locationStatus,  CameraRequest? cameraRequest,  bool pickerZoomedIn,  bool deleted)  $default,) {final _that = this;
switch (_that) {
case _WorldEditorState():
return $default(_that.worldId,_that.draft,_that.saved,_that.loading,_that.loadError,_that.step,_that.saving,_that.saveError,_that.pendingAnswerIds,_that.uploading,_that.failedUploads,_that.uploadError,_that.publishing,_that.serverProblems,_that.locationStatus,_that.cameraRequest,_that.pickerZoomedIn,_that.deleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String worldId,  WorldDraft? draft,  WorldDraft? saved,  bool loading,  AppFailure? loadError,  EditorStep step,  bool saving,  AppFailure? saveError,  Set<String> pendingAnswerIds,  Set<String> uploading,  Set<String> failedUploads,  AppFailure? uploadError,  bool publishing,  List<PublishProblem> serverProblems,  PickerLocationStatus locationStatus,  CameraRequest? cameraRequest,  bool pickerZoomedIn,  bool deleted)?  $default,) {final _that = this;
switch (_that) {
case _WorldEditorState() when $default != null:
return $default(_that.worldId,_that.draft,_that.saved,_that.loading,_that.loadError,_that.step,_that.saving,_that.saveError,_that.pendingAnswerIds,_that.uploading,_that.failedUploads,_that.uploadError,_that.publishing,_that.serverProblems,_that.locationStatus,_that.cameraRequest,_that.pickerZoomedIn,_that.deleted);case _:
  return null;

}
}

}

/// @nodoc


class _WorldEditorState extends WorldEditorState {
  const _WorldEditorState({required this.worldId, this.draft, this.saved, this.loading = false, this.loadError, this.step = EditorStep.category, this.saving = false, this.saveError, final  Set<String> pendingAnswerIds = const <String>{}, final  Set<String> uploading = const <String>{}, final  Set<String> failedUploads = const <String>{}, this.uploadError, this.publishing = false, final  List<PublishProblem> serverProblems = const <PublishProblem>[], this.locationStatus = PickerLocationStatus.idle, this.cameraRequest, this.pickerZoomedIn = true, this.deleted = false}): _pendingAnswerIds = pendingAnswerIds,_uploading = uploading,_failedUploads = failedUploads,_serverProblems = serverProblems,super._();
  

@override final  String worldId;
/// What the creator is editing; null until a category is chosen for a
/// new World, or while an existing World loads.
@override final  WorldDraft? draft;
/// The copy last confirmed by the server; null if never saved.
@override final  WorldDraft? saved;
@override@JsonKey() final  bool loading;
@override final  AppFailure? loadError;
@override@JsonKey() final  EditorStep step;
@override@JsonKey() final  bool saving;
@override final  AppFailure? saveError;
/// Questions whose new answer will be sent with the next save. The
/// answers themselves are kept out of this state so they are never
/// logged or shown.
 final  Set<String> _pendingAnswerIds;
/// Questions whose new answer will be sent with the next save. The
/// answers themselves are kept out of this state so they are never
/// logged or shown.
@override@JsonKey() Set<String> get pendingAnswerIds {
  if (_pendingAnswerIds is EqualUnmodifiableSetView) return _pendingAnswerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_pendingAnswerIds);
}

/// Upload targets in progress: block ids, or [coverUploadTarget].
 final  Set<String> _uploading;
/// Upload targets in progress: block ids, or [coverUploadTarget].
@override@JsonKey() Set<String> get uploading {
  if (_uploading is EqualUnmodifiableSetView) return _uploading;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_uploading);
}

/// Upload targets whose last upload failed and can be retried.
 final  Set<String> _failedUploads;
/// Upload targets whose last upload failed and can be retried.
@override@JsonKey() Set<String> get failedUploads {
  if (_failedUploads is EqualUnmodifiableSetView) return _failedUploads;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_failedUploads);
}

@override final  AppFailure? uploadError;
@override@JsonKey() final  bool publishing;
/// Problems the server reported on the last publish attempt.
 final  List<PublishProblem> _serverProblems;
/// Problems the server reported on the last publish attempt.
@override@JsonKey() List<PublishProblem> get serverProblems {
  if (_serverProblems is EqualUnmodifiableListView) return _serverProblems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_serverProblems);
}

@override@JsonKey() final  PickerLocationStatus locationStatus;
/// Moves the place picker's map once.
@override final  CameraRequest? cameraRequest;
/// False when the place picker was last left too far out to place the
/// pin precisely.
@override@JsonKey() final  bool pickerZoomedIn;
@override@JsonKey() final  bool deleted;

/// Create a copy of WorldEditorState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorldEditorStateCopyWith<_WorldEditorState> get copyWith => __$WorldEditorStateCopyWithImpl<_WorldEditorState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorldEditorState&&(identical(other.worldId, worldId) || other.worldId == worldId)&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.saved, saved) || other.saved == saved)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.loadError, loadError) || other.loadError == loadError)&&(identical(other.step, step) || other.step == step)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.saveError, saveError) || other.saveError == saveError)&&const DeepCollectionEquality().equals(other._pendingAnswerIds, _pendingAnswerIds)&&const DeepCollectionEquality().equals(other._uploading, _uploading)&&const DeepCollectionEquality().equals(other._failedUploads, _failedUploads)&&(identical(other.uploadError, uploadError) || other.uploadError == uploadError)&&(identical(other.publishing, publishing) || other.publishing == publishing)&&const DeepCollectionEquality().equals(other._serverProblems, _serverProblems)&&(identical(other.locationStatus, locationStatus) || other.locationStatus == locationStatus)&&(identical(other.cameraRequest, cameraRequest) || other.cameraRequest == cameraRequest)&&(identical(other.pickerZoomedIn, pickerZoomedIn) || other.pickerZoomedIn == pickerZoomedIn)&&(identical(other.deleted, deleted) || other.deleted == deleted));
}


@override
int get hashCode => Object.hash(runtimeType,worldId,draft,saved,loading,loadError,step,saving,saveError,const DeepCollectionEquality().hash(_pendingAnswerIds),const DeepCollectionEquality().hash(_uploading),const DeepCollectionEquality().hash(_failedUploads),uploadError,publishing,const DeepCollectionEquality().hash(_serverProblems),locationStatus,cameraRequest,pickerZoomedIn,deleted);

@override
String toString() {
  return 'WorldEditorState(worldId: $worldId, draft: $draft, saved: $saved, loading: $loading, loadError: $loadError, step: $step, saving: $saving, saveError: $saveError, pendingAnswerIds: $pendingAnswerIds, uploading: $uploading, failedUploads: $failedUploads, uploadError: $uploadError, publishing: $publishing, serverProblems: $serverProblems, locationStatus: $locationStatus, cameraRequest: $cameraRequest, pickerZoomedIn: $pickerZoomedIn, deleted: $deleted)';
}


}

/// @nodoc
abstract mixin class _$WorldEditorStateCopyWith<$Res> implements $WorldEditorStateCopyWith<$Res> {
  factory _$WorldEditorStateCopyWith(_WorldEditorState value, $Res Function(_WorldEditorState) _then) = __$WorldEditorStateCopyWithImpl;
@override @useResult
$Res call({
 String worldId, WorldDraft? draft, WorldDraft? saved, bool loading, AppFailure? loadError, EditorStep step, bool saving, AppFailure? saveError, Set<String> pendingAnswerIds, Set<String> uploading, Set<String> failedUploads, AppFailure? uploadError, bool publishing, List<PublishProblem> serverProblems, PickerLocationStatus locationStatus, CameraRequest? cameraRequest, bool pickerZoomedIn, bool deleted
});


@override $WorldDraftCopyWith<$Res>? get draft;@override $WorldDraftCopyWith<$Res>? get saved;@override $AppFailureCopyWith<$Res>? get loadError;@override $AppFailureCopyWith<$Res>? get saveError;@override $AppFailureCopyWith<$Res>? get uploadError;

}
/// @nodoc
class __$WorldEditorStateCopyWithImpl<$Res>
    implements _$WorldEditorStateCopyWith<$Res> {
  __$WorldEditorStateCopyWithImpl(this._self, this._then);

  final _WorldEditorState _self;
  final $Res Function(_WorldEditorState) _then;

/// Create a copy of WorldEditorState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? worldId = null,Object? draft = freezed,Object? saved = freezed,Object? loading = null,Object? loadError = freezed,Object? step = null,Object? saving = null,Object? saveError = freezed,Object? pendingAnswerIds = null,Object? uploading = null,Object? failedUploads = null,Object? uploadError = freezed,Object? publishing = null,Object? serverProblems = null,Object? locationStatus = null,Object? cameraRequest = freezed,Object? pickerZoomedIn = null,Object? deleted = null,}) {
  return _then(_WorldEditorState(
worldId: null == worldId ? _self.worldId : worldId // ignore: cast_nullable_to_non_nullable
as String,draft: freezed == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as WorldDraft?,saved: freezed == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as WorldDraft?,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,loadError: freezed == loadError ? _self.loadError : loadError // ignore: cast_nullable_to_non_nullable
as AppFailure?,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as EditorStep,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,saveError: freezed == saveError ? _self.saveError : saveError // ignore: cast_nullable_to_non_nullable
as AppFailure?,pendingAnswerIds: null == pendingAnswerIds ? _self._pendingAnswerIds : pendingAnswerIds // ignore: cast_nullable_to_non_nullable
as Set<String>,uploading: null == uploading ? _self._uploading : uploading // ignore: cast_nullable_to_non_nullable
as Set<String>,failedUploads: null == failedUploads ? _self._failedUploads : failedUploads // ignore: cast_nullable_to_non_nullable
as Set<String>,uploadError: freezed == uploadError ? _self.uploadError : uploadError // ignore: cast_nullable_to_non_nullable
as AppFailure?,publishing: null == publishing ? _self.publishing : publishing // ignore: cast_nullable_to_non_nullable
as bool,serverProblems: null == serverProblems ? _self._serverProblems : serverProblems // ignore: cast_nullable_to_non_nullable
as List<PublishProblem>,locationStatus: null == locationStatus ? _self.locationStatus : locationStatus // ignore: cast_nullable_to_non_nullable
as PickerLocationStatus,cameraRequest: freezed == cameraRequest ? _self.cameraRequest : cameraRequest // ignore: cast_nullable_to_non_nullable
as CameraRequest?,pickerZoomedIn: null == pickerZoomedIn ? _self.pickerZoomedIn : pickerZoomedIn // ignore: cast_nullable_to_non_nullable
as bool,deleted: null == deleted ? _self.deleted : deleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of WorldEditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorldDraftCopyWith<$Res>? get draft {
    if (_self.draft == null) {
    return null;
  }

  return $WorldDraftCopyWith<$Res>(_self.draft!, (value) {
    return _then(_self.copyWith(draft: value));
  });
}/// Create a copy of WorldEditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorldDraftCopyWith<$Res>? get saved {
    if (_self.saved == null) {
    return null;
  }

  return $WorldDraftCopyWith<$Res>(_self.saved!, (value) {
    return _then(_self.copyWith(saved: value));
  });
}/// Create a copy of WorldEditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res>? get loadError {
    if (_self.loadError == null) {
    return null;
  }

  return $AppFailureCopyWith<$Res>(_self.loadError!, (value) {
    return _then(_self.copyWith(loadError: value));
  });
}/// Create a copy of WorldEditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res>? get saveError {
    if (_self.saveError == null) {
    return null;
  }

  return $AppFailureCopyWith<$Res>(_self.saveError!, (value) {
    return _then(_self.copyWith(saveError: value));
  });
}/// Create a copy of WorldEditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res>? get uploadError {
    if (_self.uploadError == null) {
    return null;
  }

  return $AppFailureCopyWith<$Res>(_self.uploadError!, (value) {
    return _then(_self.copyWith(uploadError: value));
  });
}
}

// dart format on
