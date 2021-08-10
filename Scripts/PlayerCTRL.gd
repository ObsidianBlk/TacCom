extends Node

# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal process_complete
signal freelook(c)
signal toggle_info

# Informational Signals...
signal structure_change(structure, max_structure)
signal power_change(available, total)
signal engine_stats_change(propulsion_units, turns_to_trigger)

# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
export var faction : String = ""		setget _set_faction

var region_node : Region = null

var _ships = []
var _ship_idx = -1
var _proc_idx = -1
var _proc_delay = 0.0

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
				_focus_ship()


# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------
func _ready() -> void:
	set_process(false)
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
	if event.is_action_pressed("show_info", false):
		emit_signal("toggle_info")
	if event.is_action_pressed("next_ship", false):
		_next_ship()
	if event.is_action_pressed("prev_ship", false):
		_prev_ship()

func _process(delta : float) -> void:
	_proc_delay -= delta
	if _proc_idx >= 0 and _proc_delay <= 0:
		_proc_delay = 1.0
		var ship = _ships[_proc_idx]
		ship.process_turn()
		_proc_idx += 1
		if _proc_idx >= _ships.size():
			_proc_idx = -1
			set_process(false)
			emit_signal("process_complete")

# -----------------------------------------------------------
# Private Methods
# -----------------------------------------------------------
func _next_ship() -> void:
	if _ship_idx >= 0:
		_unfocus_ship()
		_ship_idx += 1
		if _ship_idx == _ships.size():
			_ship_idx = 0
		_focus_ship()

func _prev_ship() -> void:
	if _ship_idx >= 0:
		_unfocus_ship()
		_ship_idx -= 1
		if _ship_idx < 0:
			_ship_idx += _ships.size()
		_focus_ship()

func _unfocus_ship() -> void:
	if _ship_idx >= 0 and _ship_idx < _ships.size():
		var ship : Ship = _ships[_ship_idx]
		ship.disconnect("structure_change", self, "_on_structure_change")
		ship.disconnect("power_change", self, "_on_power_change")
		ship.disconnect("engine_stats_change", self, "_on_engine_stats_change")

func _focus_ship() -> void:
	if _ship_idx >= 0 and _ship_idx < _ships.size() and region_node != null:
		var ship : Ship = _ships[_ship_idx]
		ship.connect("structure_change", self, "_on_structure_change")
		ship.connect("power_change", self, "_on_power_change")
		ship.connect("engine_stats_change", self, "_on_engine_stats_change")
		region_node.set_target_node(ship)
		ship.report_info()

# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------


# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------

func _on_structure_change(structure : int, max_structure : int) -> void:
	emit_signal("structure_change", structure, max_structure)

func _on_power_change(available : int, total : int) -> void:
	emit_signal("power_change", available, total)

func _on_engine_stats_change(propulsion_units : int, turns_to_trigger : int) -> void:
	emit_signal("engine_stats_change", propulsion_units, turns_to_trigger)

func _on_game_ready() -> void:
	_set_faction(faction, true)

func _on_process_turn() -> void:
	if _ships.size() > 0:
		_proc_idx = 0
		set_process(true)

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

