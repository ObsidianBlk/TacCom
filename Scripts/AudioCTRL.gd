extends Node

enum BUS {MASTER=0, MUSIC=1, SFX=2}

const TRACKS = [
	"res://Assets/Audio/Music/Brave Solders.ogg",
	"res://Assets/Audio/Music/Return to Nowhere.ogg",
	"res://Assets/Audio/Music/Space Chase.ogg",
	"res://Assets/Audio/Music/battleThemeA.ogg"
]

export (float, 0.0, 2.0) var fade_out_timer = 1.0
export (float, 0.0, 2.0) var fade_in_timer = 1.0
export (float, 0.0, 1.0) var master_volume				setget set_master_volume, get_master_volume
export (float, 0.0, 1.0) var music_volume				setget set_music_volume, get_music_volume

var _track_fade_volume = -1
var _track_index = 1
var _track_next = -1

onready var tween = get_node("Tween")
onready var stream_music = get_node("MusicStream")


func _ready() -> void:
	randomize()


func change_music_track() -> void:
	if _track_fade_volume > 0:
		return
		
	var new_track = floor(TRACKS.size() * randf())
	for _i in range(4):
		if new_track != _track_index:
			break
		new_track == floor(TRACKS.size() * randf())
	if new_track != _track_index:
		_track_fade_volume = get_music_volume()
		_track_next = new_track
		tween.interpolate_property(self, "music_volume", _track_fade_volume, 0, fade_out_timer, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()


func play_track(index : int) -> void:
	if index >= 0 and index < TRACKS.size():
		if stream_music.playing:
			_track_fade_volume = get_music_volume()
			_track_next = index
			tween.interpolate_property(self, "music_volume", _track_fade_volume, 0, fade_out_timer, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			tween.start()
		else:
			stream_music.stream = load(TRACKS[_track_index])
			stream_music.play()


func get_bus_volume(bus_id : int) -> float:
	var bus = null
	match bus_id:
		BUS.MASTER:
			bus = AudioServer.get_bus_index("Master")
		BUS.MUSIC:
			bus = AudioServer.get_bus_index("Music")
		BUS.SFX:
			bus = AudioServer.get_bus_index("SFX")
	
	if bus != null:
		return db2linear(AudioServer.get_bus_volume_db(bus))
	return 0.0


func set_bus_volume(bus_id : int, volume : float) -> void:
	var bus = null
	match bus_id:
		BUS.MASTER:
			bus = AudioServer.get_bus_index("Master")
		BUS.MUSIC:
			bus = AudioServer.get_bus_index("Music")
		BUS.SFX:
			bus = AudioServer.get_bus_index("SFX")
	
	if bus != null:
		AudioServer.set_bus_volume_db(bus, linear2db(volume))


func get_master_volume() -> float:
	return get_bus_volume(BUS.MASTER)

func set_master_volume(volume : float) -> void:
	set_bus_volume(BUS.MASTER, volume)

func get_music_volume() -> float:
	return get_bus_volume(BUS.MUSIC)

func set_music_volume(volume : float) -> void:
	set_bus_volume(BUS.MUSIC, volume)




func _on_fade_completed():
	if _track_next >= 0:
		_track_index = _track_next
		_track_next = -1
		stream_music.stop()
		stream_music.stream = load(TRACKS[_track_index])
		stream_music.play()
		tween.interpolate_property(self, "music_volume", 0, _track_fade_volume, fade_in_timer, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()
	else:
		_track_fade_volume = -1
