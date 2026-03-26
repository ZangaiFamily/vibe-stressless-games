## Procedural audio manager for the hex puzzle game.
## Generates all sounds at runtime — no external audio files needed.
## Sounds are soft, crystalline tones matching the minimal aesthetic.
extends Node

var _players: Dictionary = {}


func _ready() -> void:
	_create_sound("rotate", _generate_click(400.0, 0.08))
	_create_sound("rotate_back", _generate_click(350.0, 0.08))
	_create_sound("hover", _generate_click(600.0, 0.04), -18.0)
	_create_sound("match", _generate_tone(800.0, 0.15))
	_create_sound("unmatch", _generate_tone(300.0, 0.12), -6.0)
	_create_sound("win", _generate_win_chime())
	_create_sound("new_game", _generate_tone(500.0, 0.2), -3.0)


func play(sound_name: String, pitch_variation: float = 0.0) -> void:
	if sound_name not in _players:
		return
	var player: AudioStreamPlayer = _players[sound_name]
	if pitch_variation > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	else:
		player.pitch_scale = 1.0
	player.play()


func play_rotate(clockwise: bool) -> void:
	play("rotate" if clockwise else "rotate_back", 0.05)


func play_hover() -> void:
	play("hover", 0.1)


func play_match() -> void:
	play("match", 0.08)


func play_unmatch() -> void:
	play("unmatch", 0.05)


func play_win() -> void:
	play("win")


func play_new_game() -> void:
	play("new_game")


func _create_sound(name: String, stream: AudioStreamWAV, volume_db: float = -3.0) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	_players[name] = player


func _generate_click(freq: float, duration: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var samples: int = int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var envelope: float = exp(-t * 40.0)  # Fast decay
		var wave: float = sin(TAU * freq * t) * envelope
		# Add a subtle harmonic
		wave += sin(TAU * freq * 2.5 * t) * envelope * 0.3
		var sample_val: int = clampi(int(wave * 16000.0), -32768, 32767)
		data[i * 2] = sample_val & 0xFF
		data[i * 2 + 1] = (sample_val >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream


func _generate_tone(freq: float, duration: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var samples: int = int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var envelope: float = sin(PI * t / duration)  # Smooth bell curve
		var wave: float = sin(TAU * freq * t) * envelope
		wave += sin(TAU * freq * 1.5 * t) * envelope * 0.2  # Fifth harmonic
		var sample_val: int = clampi(int(wave * 12000.0), -32768, 32767)
		data[i * 2] = sample_val & 0xFF
		data[i * 2 + 1] = (sample_val >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream


func _generate_win_chime() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 1.0
	var samples: int = int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)

	# Ascending arpeggio: C5, E5, G5, C6
	var notes: Array[float] = [523.25, 659.25, 783.99, 1046.5]
	var note_duration: float = 0.25

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var wave: float = 0.0

		for n in range(notes.size()):
			var note_start: float = n * 0.15
			var nt: float = t - note_start
			if nt >= 0.0:
				var env: float = exp(-nt * 4.0) * sin(minf(nt * 20.0, PI / 2.0))
				wave += sin(TAU * notes[n] * nt) * env * 0.5
				wave += sin(TAU * notes[n] * 2.0 * nt) * env * 0.15

		var sample_val: int = clampi(int(wave * 10000.0), -32768, 32767)
		data[i * 2] = sample_val & 0xFF
		data[i * 2 + 1] = (sample_val >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream
