extends Node

var sounds = {}
var music_player: AudioStreamPlayer
var sound_volume: float = 1.0
var music_volume: float = 0.5

func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	# Note: In Godot 4, you'll need to create these audio files first
	# For now, this won't cause errors even if files don't exist

func play_sound(name: String):
	if name in sounds:
		sounds[name].play()

func set_sound_volume(volume: float):
	sound_volume = clamp(volume, 0.0, 1.0)
	for sound in sounds.values():
		sound.volume_db = linear_to_db(sound_volume)  # Godot 4 syntax

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	music_player.volume_db = linear_to_db(music_volume)  # Godot 4 syntax
