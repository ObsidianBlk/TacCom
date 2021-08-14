extends Node



# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal end_turn
signal game_over(faction)


enum TURN_STATE {FOCUS=0, PROCESS=1, END=2}
enum AI_STATE {TURNING, HEADING}

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
	_focus_ship()

	match _turn_state:
		TURN_STATE.FOCUS:
			if ship.is_commandable() and ship.visible:
				region_node.set_target_node(ship)
				_turn_delay = TURN_VISIBLE_DELAY
			_turn_state = TURN_STATE.PROCESS
		TURN_STATE.PROCESS:
			if ship.is_commandable():
				_ProcessAI(ship)
				ship.process_turn()
				if ship.visible:
					_turn_delay = TURN_VISIBLE_DELAY
				_unfocus_ship()
			_ship_idx += 1
			_turn_state = TURN_STATE.FOCUS
			if _ship_idx >= _ships.size():
				_ship_idx = 0
			if _ship_idx == _turn_sidx:
				_turn_state = TURN_STATE.END
			else:
				_ships[_ship_idx].report_info()
		TURN_STATE.END:
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

func _GetMemory(key : String, default = null):
	if _ship_memory:
		var mem = _ship_memory[_ship_idx]
		if key in mem:
			return mem[key]
	return default

func _SetMemory(key : String, value) -> void:
	if _ship_memory:
		var mem = _ship_memory[_ship_idx]
		if value == null:
			if key in mem:
				mem.erase(key)
		else:
			mem[key] = value

func _GetSetMemory(key : String, default = null):
	var val = _GetMemory(key)
	if val == null:
		if default != null:
			_SetMemory(key, default)
		return default
	return val

func _ProcessAI(ship : Ship) -> void:
	if _commands_available > 0:
		_AI_Sensors(ship)
	if _commands_available > 0:
		_AI_IonLance(ship)
	if _commands_available > 0:
		_AI_Heading(ship)
	if _commands_available > 0:
		_AI_Turn(ship)


func _AI_Sensors(ship : Ship) -> bool:
	var commanded = false
	var target = _GetMemory("target")
	if target == null:
		var entlist = ship.get_entities_in_sensor_range()
		if entlist.size() > 0:
			for ent in entlist:
				if ent is Ship:
					if Factions.get_relation(faction, ent.faction) < -10:
						print("Found target: ", ent, " | I am: ", ship)
						_SetMemory("target", ent)
						break
	
	if not ship.long_range_sensors_enabled():
		var tts = _GetMemory("time_to_sensor", 0)
		if tts > 0:
			_SetMemory("time_to_sensor", tts - 1)
		else:
			commanded = ship.command("Sensors")
			_SetMemory("time_to_sensor", round(rand_range(3, 8)))
	
	return commanded

func _AI_IonLance(ship : Ship) -> bool:
	var commanded = false
	var target = _GetMemory("target")
	if target:
		var tts = _GetMemory("time_to_strike", 0)
		if tts > 0:
			_SetMemory("time_to_strike", tts - 1)
		else:
			print("AI Firing IonLance at: ", target)
			commanded = ship.command("IonLance", target.coord)
			_SetMemory("time_to_strike", round(rand_range(0, 2)))
	else:
		_SetMemory("time_to_strike", null)
	return commanded

func _AI_Heading(ship : Ship) -> bool:
	var commanded = false
	var change_heading = false
	var target = _GetMemory("target")
	var route = _GetMemory("target_route")
	if target != null or route != null:
		if target != null and route == null:
			route = ship.path_to_entity(target)
			if route.size() == 0:
				route = null
		if route != null:
			if route.size() < _sensors_short and target == null:
				_SetMemory("target_route", null)
			else:
				var next_cell = route[0]
				route.remove(0)
				if route.size() > 0:
					_SetMemory("target_route", route)
				else:
					_SetMemory("target_route", null)
				var nce = ship.edge_from_coord(next_cell)
				var move = true
				if nce != ship.facing_edge():
					var re = ship.relative_edge_from_coord(next_cell)
					var isRight = re == Hexmap.EDGE.RIGHT_UP or re == Hexmap.EDGE.RIGHT_DOWN
					print("Forcing turn change")
					_SetMemory("heading_change_turns", 0)
					_SetMemory("last_turn", -1 if isRight else 1)
					move = _commands_available > 1
				if move:
					commanded = ship.command("SublightEngine")
	
	else:
		var hct = _GetMemory("heading_change_turns", -1)
		if hct < 0:
			hct = round(rand_range(0, 10))
			_SetMemory("heading_change_turns", hct)
		
		if hct >= 0:
			if hct == 0:
				var left_available = not ship.is_neighbor_edge_blocked(ship.forward_left_edge())
				var right_available = not ship.is_neighbor_edge_blocked(ship.forward_right_edge())
				if left_available and right_available:
					commanded = ship.command("SublightEngine")
			else:
				if not ship.is_neighbor_edge_blocked(ship.facing_edge()):
					commanded = ship.command("SublightEngine")
				else:
					_SetMemory("heading_change_turns", 0)
	
	return commanded



func _AI_Turn(ship : Ship) -> bool:
	var last_turn = _GetMemory("last_turn", 0)
	var hct = _GetMemory("heading_change_turns", -1)
	#if hct > 1:
	#	_SetMemory("heading_change_turns", hct - 1)
	var commanded = false
	
	if hct == 0:
		var dir = last_turn if last_turn != 0 else -2
		if dir == -2:
			dir = -1 if randf() < 0.5 else 1
		
		var left_available = not ship.is_neighbor_edge_blocked(ship.forward_left_edge())
		var right_available = not ship.is_neighbor_edge_blocked(ship.forward_right_edge())
		if dir == 1:
			if not left_available and right_available:
				dir = -1
		if dir == -1:
			if not right_available and left_available:
				dir = 1
		commanded = ship.command("ManeuverEngine", dir)
		_SetMemory("last_turn", dir)
		_SetMemory("heading_change_turns", round(rand_range(2, 10)))
		return commanded
	_SetMemory("last_turn", 0)
	return commanded


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
		if not _ships[_ship_idx].is_controllable():
			if _FindOperableShip() == null:
				emit_signal("game_over", faction)
				return
		
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

