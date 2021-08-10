extends Control

export (float, 0.0, 2.0, 0.1) var slide_duration = 0.5

var cur = null
var queue = {}
var showing = false

onready var structure = get_node("HBC/Structure")
onready var power = get_node("HBC/Power")
onready var engines = get_node("HBC/Engines")
onready var tween = get_node("Tween")

func _ready() -> void:
	structure.visible = false
	power.visible = false
	engines.visible = false
	queue[structure] = {"prev": engines, "next": power}
	queue[power] = {"prev": structure, "next": engines}
	queue[engines] = {"prev": power, "next": structure}
	cur = structure
	cur.visible = true


func _on_toggle_shipinfo() -> void:
	tween.remove_all()
	if showing:
		showing = false
		var p = abs(margin_top) / 24
		tween.interpolate_property(self, "margin_top", margin_top, 0, slide_duration * p, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	else:
		showing = true
		var p = 1.0 - (abs(margin_top)/24)
		tween.interpolate_property(self, "margin_top", margin_top, -24, slide_duration * p, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func _on_Prev_Info_pressed():
	cur.visible = false
	cur = queue[cur].prev
	cur.visible = true


func _on_Next_Info_pressed():
	cur.visible = false
	cur = queue[cur].next
	cur.visible = true

func _on_structure_change(struct : int, max_structure : int) -> void:
	if structure:
		var p = 0
		if max_structure > 0:
			p = int((float(struct) / float(max_structure)) * 100)
		structure.get_node("Bar").value = p

func _on_power_change(available : int, total : int) -> void:
	if power:
		power.get_node("Available").text = String(available)
		power.get_node("Maximum").text = String(total)

func _on_engine_stats_change(propulsion_units : int, turns_to_trigger : int) -> void:
	if engines:
		engines.get_node("Units").text = String(propulsion_units)
		engines.get_node("Turns").text = String(turns_to_trigger)

