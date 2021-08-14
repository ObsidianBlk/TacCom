extends Node



# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal end_turn
signal game_over(faction)


enum TURN_STATE {FOCUS=0, PROCESS=1, END=2}

const TURN_VISIBLE_DELAY = 1.0

# -----------------------------------------------------------
# Exports
# -----------------------------------------------------------
export var region_path : NodePath = ""		setget _set_region_path
export var faction : String = ""			setget _set_faction


# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var region_node : Region = null

var _in_turn = false
var _ships = null
var _ship_memory = null
var _ship_idx = -1
var _turn_sidx = -1
var _turn_delay = 0
var _turn_state = TURN_STATE.FOCUS

var _commands_available = 0
var _sensors_short = 0
var _sensors_long = 0


# -----------------------------------------------------------
# Setters/Getters
# -----------------------------------------------------------
func _set_region_path(rp : NodePath) -> void:
	set_process(false)
	region_path = rp
	if rp != "":
		var reg = get_node_or_null(region_path)
		if reg != null and reg is Region:
			region_node = reg
	else:
		region_node = null

func _set_faction(fac : String, force : bool = false) -> void:
	if fac != faction or force:
		faction = fac
		if region_node != null:
			# Loop through any existing ships and disable their sensor masks
			if _ships != null:
				for i in range(_ships.size()):
					_ships[i].enable_update_sensor_mask = false
				
			_ships = region_node.get_ships_in_faction(faction)
			_ship_idx = -1
			_ship_memory = null
			if _ships.size() > 0:
				_ship_idx = 0
				_ship_memory = []
				for _i in range(_ships.size()):
					_ship_memory.append({})


# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------
func _ready() -> void:
	_set_region_path(region_path)

func _process(delta : float) -> void:
	if _ships.size() <= 0:
		return
	
	if _turn_delay > 0:
		_turn_delay -= delta
		if _turn_delay > 0:
			return
	
	if _turn_sidx < 0:
		_turn_sidx = _ship_idx
	var ship : Ship = _ships[_ship_idx]

	match _turn_state:
		TURN_STATE.FOCUS:
			print("Focusing on ship")
			if ship.visible:
				region_node.set_target_node(ship)
				_turn_delay = TURN_VISIBLE_DELAY
			_turn_state = TURN_STATE.PROCESS
		TURN_STATE.PROCESS:
			print("Processing ship")
			if ship.is_commandable():
				_ProcessAI(ship)
				ship.process_turn()
				if ship.visible:
					_turn_delay = TURN_VISIBLE_DELAY
			_ship_idx += 1
			_turn_state = TURN_STATE.FOCUS
			if _ship_idx >= _ships.size():
				_ship_idx = 0
			if _ship_idx == _turn_sidx:
				_turn_state = TURN_STATE.END
			else:
				_ships[_ship_idx].report_info()
		TURN_STATE.END:
			print("Ending turn")
			_turn_state = TURN_STATE.FOCUS
			set_process(false)
			_unfocus_ship()
			_in_turn = false
			ship = _FindOperableShip()
			if ship != null:
				emit_signal("end_turn")
			else:
				emit_signal("game_over", faction)

# -----------------------------------------------------------
# Private Methods
# -----------------------------------------------------------
func _ProcessAI(ship : Ship) -> void:
	pass


func _FindOperableShip(dir : int = 1) -> Ship:
	var sidx = _ship_idx
	var ship : Ship = _ships[_ship_idx]
	if dir != 0:
		while ship != null and not ship.is_controllable():
			if dir == 1:
				_ship_idx += 1
				if _ship_idx >= _ships.size():
					_ship_idx = 0
			else:
				_ship_idx -= 1
				if _ship_idx < 0:
					_ship_idx = _ships.size() - 1
			
			ship = null
			if _ship_idx != sidx:
				ship = _ships[_ship_idx]
	return ship

func _ConnectShip(ship : Ship, sig_name : String, obj, method : String) -> void:
	if not ship.is_connected(sig_name, obj, method):
		ship.connect(sig_name, obj, method)

func _DisconnectShip(ship : Ship, sig_name : String, obj, method : String) -> void:
	if ship.is_connected(sig_name, obj, method):
		ship.disconnect(sig_name, obj, method)

func _unfocus_ship() -> void:
	if _ship_idx >= 0 and _ship_idx < _ships.size():
		var ship : Ship = _ships[_ship_idx]
		_DisconnectShip(ship, "commands_change", self, "_on_commands_change")
		_DisconnectShip(ship, "invalid_command", self, "_on_invalid_command")
		_DisconnectShip(ship, "sensor_stats_change", self, "_on_sensor_stats_change")

func _focus_ship() -> void:
	if _ship_idx >= 0 and _ship_idx < _ships.size() and region_node != null:
		var ship : Ship = _ships[_ship_idx]
		_ConnectShip(ship, "commands_change", self, "_on_commands_change")
		_ConnectShip(ship, "invalid_command", self, "_on_invalid_command")
		_ConnectShip(ship, "sensor_stats_change", self, "_on_sensor_stats_change")
		ship.report_info()


# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------
func _on_game_ready() -> void:
	_set_faction(faction, true)

func _on_start_turn(fac : String) -> void:
	if fac == faction and _ships.size() > 0:
		_in_turn = true
		set_process(true)

func _on_ui_lock() -> void:
	if _in_turn:
		set_process(false)

func _on_ui_release() -> void:
	if _in_turn:
		set_process(true)

func _on_commands_change(available : int, total : int) -> void:
	_commands_available = available

func _on_invalid_command(order : String, ship : Ship) -> void:
	ship.belay(order)

func _on_sensor_stats_change(short_radius : int, long_radius : int) -> void:
	_sensors_short = short_radius
	_sensors_long = long_radius

