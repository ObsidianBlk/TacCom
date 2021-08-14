extends Node2D

signal game_ready
signal start_turn(faction)
signal resume_game

var _factions = null
var _fac_index = -1

onready var audioctrl_node = get_node("AudioCTRL")

onready var logo_node = get_node_or_null("Logo")
onready var region = get_node_or_null("Region")

onready var mainmenu_node = get_node("CanvasLayer/MainMenu")
onready var pausemenu_node = get_node("CanvasLayer/PauseMenu")
onready var winner_node = get_node("CanvasLayer/Winner")
onready var game_bg_node = get_node("CanvasLayer/ParallaxBackground/ParallaxLayer")



func _ready() -> void:
	Factions.register("TAC")
	Factions.register("COM")
	#Factions.register("NEUTRAL")
	Factions.set_relation("TAC", "COM", -100, true)
	
	connect("game_ready", self, "_on_game_ready")
	#if region != null:
	#	call_deferred("_build_region")


func _build_region() -> void:
	#region.create_map("res://Assets/Maps/AsteroidPocket/AsteroidPocket.png")
	region.create_map("res://Assets/Maps/Test.png")
	emit_signal("game_ready")
	emit_signal("start_turn", "TAC")
	audioctrl_node.change_music_track()


func _on_logo_complete() -> void:
	remove_child(logo_node)
	logo_node.queue_free()
	audioctrl_node.play_track(1)
	mainmenu_node.visible = true

func _on_game_ready() -> void:
	_factions = Factions.get_list()
	for i in range(_factions.size()):
		if _factions[i] == "TAC":
			_fac_index = i
			break
	emit_signal("start_turn", _factions[_fac_index])

func _on_start() -> void:
	mainmenu_node.visible = false
	region.visible = true
	game_bg_node.visible = true
	call_deferred("_build_region")

func _on_options() -> void:
	pass

func _on_Player_game_over(faction):
	winner_node.text = "COM"
	winner_node.visible = true

func _on_AI_game_over(faction):
	winner_node.text = "TAC"
	winner_node.visible = true

func _on_end_turn():
	if _factions.size() > 0:
		_fac_index += 1
		if _fac_index >= _factions.size():
			_fac_index = 0
		emit_signal("start_turn", _factions[_fac_index])


func _on_quit() -> void:
	get_tree().quit()


func _on_NextSongTimer_timeout():
	audioctrl_node.change_music_track()


func _on_resume_game():
	emit_signal("resume_game")


func _on_mainmenu():
	region.visible = false
	game_bg_node.visible = false
	mainmenu_node.visible = true


func _on_pause():
	pausemenu_node.visible = true
