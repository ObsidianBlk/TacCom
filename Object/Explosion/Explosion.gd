extends Node2D


signal boom_over

export var offset : Vector2 = Vector2(-8,-8)
export var size : Vector2 = Vector2(16,16)

var booming : bool = false
var boom_step : int = 0

onready var boom1 : Sprite = get_node("Boom1")
onready var boom2 : Sprite = get_node("Boom2")
onready var boom3 : Sprite = get_node("Boom3")
onready var tween : Tween = get_node("Tween")
onready var timer : Timer = get_node("Timer")


func _PlaceBoom(boom : Sprite):
	var x = offset.x + (size.x * randf())
	var y = offset.y + (size.y * randf())
	boom.position = Vector2(x, y)
	tween.interpolate_property(boom, "frame", 0, 8, 0.8, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)

func boom() -> void:
	if booming:
		return
		
	randomize()
	booming = true
	_PlaceBoom(boom1)
	boom_step = 1
	timer.start(0.2 + (0.4 * randf()))
	tween.start()


func _on_tween_all_completed():
	booming = false
	emit_signal("boom_over")


func _on_Timer_timeout():
	if boom_step == 1:
		boom_step = 2
		_PlaceBoom(boom2)
		timer.start(0.2 + (0.4 * randf()))
	elif boom_step == 2:
		boom_step = 0
		_PlaceBoom(boom3)
		
