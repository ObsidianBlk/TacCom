extends Control


# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal start
signal options
signal quit


# -----------------------------------------------------------
# Export Variables
# -----------------------------------------------------------
export var background_only : bool = false			setget set_background_only


# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var _ca1_dir = 0
var _ca2_dir = 0
var _ca3_dir = 0
var _ca4_dir = 0

# -----------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------
onready var logo_node = get_node("Logo")
onready var menu_node = get_node("Menu")


# -----------------------------------------------------------
# Setters / Getters
# -----------------------------------------------------------
func set_background_only(o : bool) -> void:
	background_only = o
	if background_only:
		if not (logo_node and menu_node):
			call_deferred("set_background_only", o)
		else:
			logo_node.visible = false
			menu_node.visible = false


# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------
func _ready() -> void:
	if OS.has_feature("web"):
		get_node("Menu/Buttons/BTN_Quit").visible = false
	set_background_only(background_only)




func _on_BTN_Quit_pressed():
	emit_signal("quit")


func _on_BTN_Options_pressed():
	emit_signal("options")


func _on_BTN_Start_pressed():
	emit_signal("start")
