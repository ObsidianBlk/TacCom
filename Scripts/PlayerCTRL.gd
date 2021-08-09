extends Node

# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal freelook(c)

# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
export var faction : String = ""		setget _set_faction

var region_node : Region = null

var _ships = []
var _ship_idx = -1

# -----------------------------------------------------------
# Setters/Getters
# -----------------------------------------------------------

func _set_faction(fac : String, force : bool = false) -> void:
	if fac != faction or force:
		faction = fac
		if region_node != null:
			print("Trying to set faction")
			_ships = region_node.get_ships_in_faction(faction)
			print("Obtained ", _ships.size(), " ships")
			_ship_idx = 0 if _ships.size() > 0 else -1
			if _ship_idx >= 0:
				region_node.set_target_node(_ships[_ship_idx])


# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------
func _ready() -> void:
	var parent = get_parent()
	if parent is Region:
		region_node = parent


func _unhandled_input(event):
	if event.is_action_pressed("freelook", false):
		set_process_unhandled_input(false)
		if _ship_idx >= 0:
			emit_signal("freelook", _ships[_ship_idx].coord)
		else:
			emit_signal("freelook", Vector2.ZERO)
	if event.is_action_pressed("next_ship", false):
		if _ship_idx >= 0:
			_ship_idx += 1
			if _ship_idx == _ships.size():
				_ship_idx = 0
			_focus_ship()
	if event.is_action_pressed("prev_ship", false):
		if _ship_idx >= 0:
			_ship_idx -= 1
			if _ship_idx < 0:
				_ship_idx += _ships.size()
			_focus_ship()


# -----------------------------------------------------------
# Private Methods
# -----------------------------------------------------------
func _focus_ship() -> void:
	if _ship_idx >= 0 and _ship_idx < _ships.size() and region_node != null:
		region_node.set_target_node(_ships[_ship_idx])

# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------


# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------

func _on_game_ready() -> void:
	print("Handling Ready")
	_set_faction(faction, true)

func _on_freelook_exit() -> void:
	set_process_unhandled_input(true)
	if _ship_idx >= 0 and region_node != null:
		region_node.set_target_node(_ships[_ship_idx])


func _on_ship_added(ship : Ship):
	if ship.faction == faction:
		_ships.append(ship)
		if _ship_idx < 0:
			_ship_idx = 0
			_focus_ship()

