## Manages all game audio: music, ambience, and SFX.
## Tag-based SFX playback with streak pitch scaling and volume ducking.
## See design/gdd/audio-manager.md for full specification.
extends Node

enum AudioState { MENU, GAMEPLAY, SUMMARY, MUTED }

## Streak pitch scaling
@export var base_pitch: float = 1.0
@export var pitch_increment: float = 0.02
@export var min_pitch: float = 0.8
@export var max_pitch: float = 1.6
@export var pitch_variance: float = 0.05

## Polyphony
@export var max_polyphony: int = 8

## Ducking
@export var duck_amount_db: float = -6.0
@export var duck_duration: float = 0.5
@export var duck_fade_time: float = 0.3

var _state: AudioState = AudioState.MENU
var _streak_count: int = 0
var _sfx_pool: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _sfx_map: Dictionary = {}  # StringName -> AudioStream
var _duck_tween: Tween

# High-priority tags that trigger music ducking
var _duck_tags: Array[StringName] = [&"streak_milestone", &"life_lost"]


func _ready() -> void:
	_setup_buses()
	_setup_sfx_pool()
	_setup_music_player()
	_setup_ambience_player()
	_load_sfx_assets()
	print("[AudioManager] Ready — %d SFX loaded" % _sfx_map.size())


func play_sfx(tag: StringName) -> void:
	if _state == AudioState.MUTED:
		return

	if not _sfx_map.has(tag):
		# Check fallback mappings for new items
		if SFX_FALLBACKS.has(tag) and _sfx_map.has(SFX_FALLBACKS[tag]):
			tag = SFX_FALLBACKS[tag]
		else:
			push_warning("[AudioManager] Unknown SFX tag: %s" % tag)
			return

	var player := _get_available_sfx_player()
	if not player:
		return

	player.stream = _sfx_map[tag]

	# Apply streak-based pitch scaling for collection sounds
	var pitch := base_pitch
	if tag.begins_with("collect_"):
		pitch = clampf(base_pitch + _streak_count * pitch_increment, min_pitch, max_pitch)
	pitch += randf_range(-pitch_variance, pitch_variance)
	player.pitch_scale = pitch

	player.play()

	# Ducking for high-priority sounds
	if tag in _duck_tags:
		_apply_duck()


func set_streak(count: int) -> void:
	_streak_count = count


func set_state(state: AudioState) -> void:
	_state = state
	match state:
		AudioState.MUTED:
			if _music_player:
				_music_player.volume_db = -80.0
			if _ambience_player:
				_ambience_player.volume_db = -80.0
		AudioState.SUMMARY:
			if _music_player:
				_music_player.volume_db = -9.0  # Ducked during summary
			_ensure_bg_playing()
		AudioState.GAMEPLAY, AudioState.MENU:
			if _music_player:
				_music_player.volume_db = -6.0
			if _ambience_player:
				_ambience_player.volume_db = -3.0
			_ensure_bg_playing()


func _ensure_bg_playing() -> void:
	if _music_player and not _music_player.playing and _music_player.stream:
		_music_player.play()
	if _ambience_player and not _ambience_player.playing and _ambience_player.stream:
		_ambience_player.play()


func _setup_buses() -> void:
	# Buses are configured in the audio bus layout .tres file
	# Ensure buses exist: Master, Music, Ambience, SFX
	pass


func _setup_sfx_pool() -> void:
	for i in max_polyphony:
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		_sfx_pool.append(player)


func _setup_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Master"
	_music_player.volume_db = -6.0
	add_child(_music_player)

	# Load and play music if available
	for ext in ["ogg", "wav", "mp3"]:
		var music_path := "res://assets/audio/music/lofi_track.%s" % ext
		if ResourceLoader.exists(music_path):
			_music_player.stream = load(music_path)
			_music_player.play()
			break


func _setup_ambience_player() -> void:
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = &"Master"
	_ambience_player.volume_db = -3.0
	add_child(_ambience_player)

	for ext in ["ogg", "wav", "mp3"]:
		var rain_path := "res://assets/audio/ambience/rain_loop.%s" % ext
		if ResourceLoader.exists(rain_path):
			_ambience_player.stream = load(rain_path)
			_ambience_player.play()
			break


## Explicit SFX paths — DirAccess fails in web exports (.pck).
const SFX_PATHS: Array[String] = [
	"res://assets/audio/sfx/collect_bronze.wav",
	"res://assets/audio/sfx/collect_gold.wav",
	"res://assets/audio/sfx/collect_silver.wav",
	"res://assets/audio/sfx/hit_bomb.wav",
	"res://assets/audio/sfx/hit_poop.wav",
	"res://assets/audio/sfx/hit_spike.wav",
	"res://assets/audio/sfx/life_lost.wav",
	"res://assets/audio/sfx/streak_milestone.wav",
	"res://assets/audio/sfx/ui_tap.wav",
]

## Fallback mappings for new items that reuse existing SFX.
const SFX_FALLBACKS: Dictionary = {
	&"collect_emerald": &"collect_silver",
	&"collect_diamond": &"collect_gold",
	&"hit_lightning": &"hit_spike",
	&"hit_trash": &"hit_bomb",
	&"hit_ice": &"hit_spike",
}


func _load_sfx_assets() -> void:
	for path in SFX_PATHS:
		if ResourceLoader.exists(path):
			var tag := StringName(path.get_file().get_basename())
			_sfx_map[tag] = load(path)


func _get_available_sfx_player() -> AudioStreamPlayer:
	# Find a free player
	for player in _sfx_pool:
		if not player.playing:
			return player
	# All busy — steal the oldest
	return _sfx_pool[0]


func _apply_duck() -> void:
	if not _music_player:
		return

	if _duck_tween and _duck_tween.is_valid():
		_duck_tween.kill()

	var original_vol := -6.0 if _state != AudioState.SUMMARY else -9.0
	var ducked_vol := original_vol + duck_amount_db

	_duck_tween = create_tween()
	_duck_tween.tween_property(_music_player, "volume_db", ducked_vol, duck_fade_time)
	_duck_tween.tween_interval(duck_duration)
	_duck_tween.tween_property(_music_player, "volume_db", original_vol, duck_fade_time)
