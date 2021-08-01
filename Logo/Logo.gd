extends Node2D
tool

signal logo_complete

export var jam_color : Color = Color(1,1,1,1)		setget _set_jam_color
export var duo_color : Color = Color(1,1,1,1)		setget _set_duo_color
export var duo2_color : Color = Color(1,1,1,1)		setget _set_duo2_color
export var use_duo_2 : bool = false					setget _set_use_duo_2

enum STATE {TM = 0, OBS = 1, LOWREZ = 2}
var state = STATE.TM

var shader_mat = null
var last_skip_time = 0

onready var color_swap_node = get_node("CanvasLayer/Colorswap_Shader")
onready var timer = get_node("Timer")
onready var anim = get_node("Anim")

func _set_jam_color(c : Color) -> void:
	jam_color = c
	if shader_mat:
		var dc = Color(c.r * 0.75, c.g * 0.75, c.b * 0.75, c.a)
		var lc = Color(c.r * 1.25, c.g * 1.25, c.b * 1.25, c.a)
		shader_mat.set_shader_param("color_1_to", jam_color)
		shader_mat.set_shader_param("color_2_to", dc)
		shader_mat.set_shader_param("color_3_to", lc)		

func _set_duo_color(c : Color) -> void:
	duo_color = c
	_duo_to_shader()

func _set_duo2_color(c : Color) -> void:
	duo2_color = c
	_duo_to_shader()

func _set_use_duo_2(e : bool) -> void:
	use_duo_2 = e
	_duo_to_shader()

func _duo_to_shader() -> void:
	var c = duo_color
	if use_duo_2:
		c = duo2_color
	if shader_mat:
		var dc = Color(c.r * 0.75, c.g * 0.75, c.b * 0.75, c.a)
		shader_mat.set_shader_param("color_8_to", c)
		shader_mat.set_shader_param("color_4_to", dc)

func _ready() -> void:
	if color_swap_node:
		shader_mat = color_swap_node.get_material()
		if shader_mat:
			shader_mat.set_shader_param("color_5_to", Color("#84a98c"))
			shader_mat.set_shader_param("color_6_to", Color("#354f52"))
			shader_mat.set_shader_param("color_7_to", Color("#cad2c5"))
			_set_jam_color(jam_color)
			_set_duo_color(duo_color)

			anim.connect("animation_finished", self, "_on_anim_finished")
			timer.connect("timeout", self, "_on_timeout")
		else:
			print("ERROR: Failed to obtain shader material.")
	else:
		print("ERROR: Failed to obtain node containing color swap shader.")


func _input(event) -> void:
	var ispressed = (event is InputEventMouseButton) or (event is InputEventKey) or (event is InputEventJoypadButton)
	if ispressed:
		set_process_input(false)	
		var skip_time = OS.get_system_time_msecs()
		if last_skip_time > 0 and skip_time - last_skip_time < 200:
			emit_signal("logo_complete")
			return
		last_skip_time = skip_time
		match state:
			STATE.TM:
				state = STATE.OBS
				anim.play("OBS")
			STATE.OBS:
				state = STATE.LOWREZ
				anim.play("JAM")
			STATE.LOWREZ:
				emit_signal("logo_complete")
				return
		timer.start(0.1)


func _on_timeout() -> void:
	set_process_input(true)

func _on_anim_finished(anim_name : String) -> void:
	match(anim_name):
		"TM":
			anim.play("TM_to_OBS")
		"TM_to_OBS":
			state = STATE.OBS
			anim.play("OBS")
		"OBS":
			anim.play("OBS_to_JAM")
		"OBS_to_JAM":
			state = STATE.LOWREZ
			anim.play("JAM")
		"JAM":
			emit_signal("logo_complete")




