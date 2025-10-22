// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PromptPreset {

 String get id;// 프리셋 고유 ID (예: 'preset_code_improve')
 String get name;// 프리셋 이름 (예: '코드 점진 개선')
// 각 파이프라인 단계별 시스템 프롬프트 리스트
// 길이는 최대 AppConstants.maxPipelineModels 와 같거나 작아야 함
 List<String> get prompts;
/// Create a copy of PromptPreset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PromptPresetCopyWith<PromptPreset> get copyWith => _$PromptPresetCopyWithImpl<PromptPreset>(this as PromptPreset, _$identity);

  /// Serializes this PromptPreset to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PromptPreset&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.prompts, prompts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(prompts));

@override
String toString() {
  return 'PromptPreset(id: $id, name: $name, prompts: $prompts)';
}


}

/// @nodoc
abstract mixin class $PromptPresetCopyWith<$Res>  {
  factory $PromptPresetCopyWith(PromptPreset value, $Res Function(PromptPreset) _then) = _$PromptPresetCopyWithImpl;
@useResult
$Res call({
 String id, String name, List<String> prompts
});




}
/// @nodoc
class _$PromptPresetCopyWithImpl<$Res>
    implements $PromptPresetCopyWith<$Res> {
  _$PromptPresetCopyWithImpl(this._self, this._then);

  final PromptPreset _self;
  final $Res Function(PromptPreset) _then;

/// Create a copy of PromptPreset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? prompts = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,prompts: null == prompts ? _self.prompts : prompts // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PromptPreset].
extension PromptPresetPatterns on PromptPreset {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PromptPreset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PromptPreset() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PromptPreset value)  $default,){
final _that = this;
switch (_that) {
case _PromptPreset():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PromptPreset value)?  $default,){
final _that = this;
switch (_that) {
case _PromptPreset() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  List<String> prompts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PromptPreset() when $default != null:
return $default(_that.id,_that.name,_that.prompts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  List<String> prompts)  $default,) {final _that = this;
switch (_that) {
case _PromptPreset():
return $default(_that.id,_that.name,_that.prompts);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  List<String> prompts)?  $default,) {final _that = this;
switch (_that) {
case _PromptPreset() when $default != null:
return $default(_that.id,_that.name,_that.prompts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PromptPreset implements PromptPreset {
  const _PromptPreset({required this.id, required this.name, required final  List<String> prompts}): _prompts = prompts;
  factory _PromptPreset.fromJson(Map<String, dynamic> json) => _$PromptPresetFromJson(json);

@override final  String id;
// 프리셋 고유 ID (예: 'preset_code_improve')
@override final  String name;
// 프리셋 이름 (예: '코드 점진 개선')
// 각 파이프라인 단계별 시스템 프롬프트 리스트
// 길이는 최대 AppConstants.maxPipelineModels 와 같거나 작아야 함
 final  List<String> _prompts;
// 프리셋 이름 (예: '코드 점진 개선')
// 각 파이프라인 단계별 시스템 프롬프트 리스트
// 길이는 최대 AppConstants.maxPipelineModels 와 같거나 작아야 함
@override List<String> get prompts {
  if (_prompts is EqualUnmodifiableListView) return _prompts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_prompts);
}


/// Create a copy of PromptPreset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PromptPresetCopyWith<_PromptPreset> get copyWith => __$PromptPresetCopyWithImpl<_PromptPreset>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PromptPresetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PromptPreset&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._prompts, _prompts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_prompts));

@override
String toString() {
  return 'PromptPreset(id: $id, name: $name, prompts: $prompts)';
}


}

/// @nodoc
abstract mixin class _$PromptPresetCopyWith<$Res> implements $PromptPresetCopyWith<$Res> {
  factory _$PromptPresetCopyWith(_PromptPreset value, $Res Function(_PromptPreset) _then) = __$PromptPresetCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, List<String> prompts
});




}
/// @nodoc
class __$PromptPresetCopyWithImpl<$Res>
    implements _$PromptPresetCopyWith<$Res> {
  __$PromptPresetCopyWithImpl(this._self, this._then);

  final _PromptPreset _self;
  final $Res Function(_PromptPreset) _then;

/// Create a copy of PromptPreset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? prompts = null,}) {
  return _then(_PromptPreset(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,prompts: null == prompts ? _self._prompts : prompts // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$ModelConfig {

 String get modelId; String get systemPrompt; bool get isEnabled; int get order;
/// Create a copy of ModelConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelConfigCopyWith<ModelConfig> get copyWith => _$ModelConfigCopyWithImpl<ModelConfig>(this as ModelConfig, _$identity);

  /// Serializes this ModelConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelConfig&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.systemPrompt, systemPrompt) || other.systemPrompt == systemPrompt)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,modelId,systemPrompt,isEnabled,order);

@override
String toString() {
  return 'ModelConfig(modelId: $modelId, systemPrompt: $systemPrompt, isEnabled: $isEnabled, order: $order)';
}


}

/// @nodoc
abstract mixin class $ModelConfigCopyWith<$Res>  {
  factory $ModelConfigCopyWith(ModelConfig value, $Res Function(ModelConfig) _then) = _$ModelConfigCopyWithImpl;
@useResult
$Res call({
 String modelId, String systemPrompt, bool isEnabled, int order
});




}
/// @nodoc
class _$ModelConfigCopyWithImpl<$Res>
    implements $ModelConfigCopyWith<$Res> {
  _$ModelConfigCopyWithImpl(this._self, this._then);

  final ModelConfig _self;
  final $Res Function(ModelConfig) _then;

/// Create a copy of ModelConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? modelId = null,Object? systemPrompt = null,Object? isEnabled = null,Object? order = null,}) {
  return _then(_self.copyWith(
modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,systemPrompt: null == systemPrompt ? _self.systemPrompt : systemPrompt // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ModelConfig].
extension ModelConfigPatterns on ModelConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModelConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModelConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModelConfig value)  $default,){
final _that = this;
switch (_that) {
case _ModelConfig():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModelConfig value)?  $default,){
final _that = this;
switch (_that) {
case _ModelConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String modelId,  String systemPrompt,  bool isEnabled,  int order)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModelConfig() when $default != null:
return $default(_that.modelId,_that.systemPrompt,_that.isEnabled,_that.order);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String modelId,  String systemPrompt,  bool isEnabled,  int order)  $default,) {final _that = this;
switch (_that) {
case _ModelConfig():
return $default(_that.modelId,_that.systemPrompt,_that.isEnabled,_that.order);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String modelId,  String systemPrompt,  bool isEnabled,  int order)?  $default,) {final _that = this;
switch (_that) {
case _ModelConfig() when $default != null:
return $default(_that.modelId,_that.systemPrompt,_that.isEnabled,_that.order);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModelConfig implements ModelConfig {
  const _ModelConfig({required this.modelId, this.systemPrompt = '', this.isEnabled = true, required this.order});
  factory _ModelConfig.fromJson(Map<String, dynamic> json) => _$ModelConfigFromJson(json);

@override final  String modelId;
@override@JsonKey() final  String systemPrompt;
@override@JsonKey() final  bool isEnabled;
@override final  int order;

/// Create a copy of ModelConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModelConfigCopyWith<_ModelConfig> get copyWith => __$ModelConfigCopyWithImpl<_ModelConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModelConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModelConfig&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.systemPrompt, systemPrompt) || other.systemPrompt == systemPrompt)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,modelId,systemPrompt,isEnabled,order);

@override
String toString() {
  return 'ModelConfig(modelId: $modelId, systemPrompt: $systemPrompt, isEnabled: $isEnabled, order: $order)';
}


}

/// @nodoc
abstract mixin class _$ModelConfigCopyWith<$Res> implements $ModelConfigCopyWith<$Res> {
  factory _$ModelConfigCopyWith(_ModelConfig value, $Res Function(_ModelConfig) _then) = __$ModelConfigCopyWithImpl;
@override @useResult
$Res call({
 String modelId, String systemPrompt, bool isEnabled, int order
});




}
/// @nodoc
class __$ModelConfigCopyWithImpl<$Res>
    implements _$ModelConfigCopyWith<$Res> {
  __$ModelConfigCopyWithImpl(this._self, this._then);

  final _ModelConfig _self;
  final $Res Function(_ModelConfig) _then;

/// Create a copy of ModelConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? modelId = null,Object? systemPrompt = null,Object? isEnabled = null,Object? order = null,}) {
  return _then(_ModelConfig(
modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,systemPrompt: null == systemPrompt ? _self.systemPrompt : systemPrompt // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SettingsState {

 String get apiKey; List<ModelConfig> get modelPipeline; String get selectedModel; String get themeMode;// 프리셋 목록 추가
 List<PromptPreset> get promptPresets;// 현재 선택된 프리셋 ID 추가 (null이면 선택 안됨)
 String? get selectedPresetId;
/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsStateCopyWith<SettingsState> get copyWith => _$SettingsStateCopyWithImpl<SettingsState>(this as SettingsState, _$identity);

  /// Serializes this SettingsState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsState&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey)&&const DeepCollectionEquality().equals(other.modelPipeline, modelPipeline)&&(identical(other.selectedModel, selectedModel) || other.selectedModel == selectedModel)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&const DeepCollectionEquality().equals(other.promptPresets, promptPresets)&&(identical(other.selectedPresetId, selectedPresetId) || other.selectedPresetId == selectedPresetId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,apiKey,const DeepCollectionEquality().hash(modelPipeline),selectedModel,themeMode,const DeepCollectionEquality().hash(promptPresets),selectedPresetId);

@override
String toString() {
  return 'SettingsState(apiKey: $apiKey, modelPipeline: $modelPipeline, selectedModel: $selectedModel, themeMode: $themeMode, promptPresets: $promptPresets, selectedPresetId: $selectedPresetId)';
}


}

/// @nodoc
abstract mixin class $SettingsStateCopyWith<$Res>  {
  factory $SettingsStateCopyWith(SettingsState value, $Res Function(SettingsState) _then) = _$SettingsStateCopyWithImpl;
@useResult
$Res call({
 String apiKey, List<ModelConfig> modelPipeline, String selectedModel, String themeMode, List<PromptPreset> promptPresets, String? selectedPresetId
});




}
/// @nodoc
class _$SettingsStateCopyWithImpl<$Res>
    implements $SettingsStateCopyWith<$Res> {
  _$SettingsStateCopyWithImpl(this._self, this._then);

  final SettingsState _self;
  final $Res Function(SettingsState) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? apiKey = null,Object? modelPipeline = null,Object? selectedModel = null,Object? themeMode = null,Object? promptPresets = null,Object? selectedPresetId = freezed,}) {
  return _then(_self.copyWith(
apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,modelPipeline: null == modelPipeline ? _self.modelPipeline : modelPipeline // ignore: cast_nullable_to_non_nullable
as List<ModelConfig>,selectedModel: null == selectedModel ? _self.selectedModel : selectedModel // ignore: cast_nullable_to_non_nullable
as String,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String,promptPresets: null == promptPresets ? _self.promptPresets : promptPresets // ignore: cast_nullable_to_non_nullable
as List<PromptPreset>,selectedPresetId: freezed == selectedPresetId ? _self.selectedPresetId : selectedPresetId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SettingsState].
extension SettingsStatePatterns on SettingsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettingsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettingsState value)  $default,){
final _that = this;
switch (_that) {
case _SettingsState():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettingsState value)?  $default,){
final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String apiKey,  List<ModelConfig> modelPipeline,  String selectedModel,  String themeMode,  List<PromptPreset> promptPresets,  String? selectedPresetId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
return $default(_that.apiKey,_that.modelPipeline,_that.selectedModel,_that.themeMode,_that.promptPresets,_that.selectedPresetId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String apiKey,  List<ModelConfig> modelPipeline,  String selectedModel,  String themeMode,  List<PromptPreset> promptPresets,  String? selectedPresetId)  $default,) {final _that = this;
switch (_that) {
case _SettingsState():
return $default(_that.apiKey,_that.modelPipeline,_that.selectedModel,_that.themeMode,_that.promptPresets,_that.selectedPresetId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String apiKey,  List<ModelConfig> modelPipeline,  String selectedModel,  String themeMode,  List<PromptPreset> promptPresets,  String? selectedPresetId)?  $default,) {final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
return $default(_that.apiKey,_that.modelPipeline,_that.selectedModel,_that.themeMode,_that.promptPresets,_that.selectedPresetId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SettingsState extends SettingsState {
  const _SettingsState({this.apiKey = '', final  List<ModelConfig> modelPipeline = const [], this.selectedModel = 'anthropic/claude-3.5-sonnet', this.themeMode = 'system', final  List<PromptPreset> promptPresets = const [], this.selectedPresetId}): _modelPipeline = modelPipeline,_promptPresets = promptPresets,super._();
  factory _SettingsState.fromJson(Map<String, dynamic> json) => _$SettingsStateFromJson(json);

@override@JsonKey() final  String apiKey;
 final  List<ModelConfig> _modelPipeline;
@override@JsonKey() List<ModelConfig> get modelPipeline {
  if (_modelPipeline is EqualUnmodifiableListView) return _modelPipeline;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modelPipeline);
}

@override@JsonKey() final  String selectedModel;
@override@JsonKey() final  String themeMode;
// 프리셋 목록 추가
 final  List<PromptPreset> _promptPresets;
// 프리셋 목록 추가
@override@JsonKey() List<PromptPreset> get promptPresets {
  if (_promptPresets is EqualUnmodifiableListView) return _promptPresets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_promptPresets);
}

// 현재 선택된 프리셋 ID 추가 (null이면 선택 안됨)
@override final  String? selectedPresetId;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsStateCopyWith<_SettingsState> get copyWith => __$SettingsStateCopyWithImpl<_SettingsState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SettingsStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettingsState&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey)&&const DeepCollectionEquality().equals(other._modelPipeline, _modelPipeline)&&(identical(other.selectedModel, selectedModel) || other.selectedModel == selectedModel)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&const DeepCollectionEquality().equals(other._promptPresets, _promptPresets)&&(identical(other.selectedPresetId, selectedPresetId) || other.selectedPresetId == selectedPresetId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,apiKey,const DeepCollectionEquality().hash(_modelPipeline),selectedModel,themeMode,const DeepCollectionEquality().hash(_promptPresets),selectedPresetId);

@override
String toString() {
  return 'SettingsState(apiKey: $apiKey, modelPipeline: $modelPipeline, selectedModel: $selectedModel, themeMode: $themeMode, promptPresets: $promptPresets, selectedPresetId: $selectedPresetId)';
}


}

/// @nodoc
abstract mixin class _$SettingsStateCopyWith<$Res> implements $SettingsStateCopyWith<$Res> {
  factory _$SettingsStateCopyWith(_SettingsState value, $Res Function(_SettingsState) _then) = __$SettingsStateCopyWithImpl;
@override @useResult
$Res call({
 String apiKey, List<ModelConfig> modelPipeline, String selectedModel, String themeMode, List<PromptPreset> promptPresets, String? selectedPresetId
});




}
/// @nodoc
class __$SettingsStateCopyWithImpl<$Res>
    implements _$SettingsStateCopyWith<$Res> {
  __$SettingsStateCopyWithImpl(this._self, this._then);

  final _SettingsState _self;
  final $Res Function(_SettingsState) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? apiKey = null,Object? modelPipeline = null,Object? selectedModel = null,Object? themeMode = null,Object? promptPresets = null,Object? selectedPresetId = freezed,}) {
  return _then(_SettingsState(
apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,modelPipeline: null == modelPipeline ? _self._modelPipeline : modelPipeline // ignore: cast_nullable_to_non_nullable
as List<ModelConfig>,selectedModel: null == selectedModel ? _self.selectedModel : selectedModel // ignore: cast_nullable_to_non_nullable
as String,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String,promptPresets: null == promptPresets ? _self._promptPresets : promptPresets // ignore: cast_nullable_to_non_nullable
as List<PromptPreset>,selectedPresetId: freezed == selectedPresetId ? _self.selectedPresetId : selectedPresetId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
