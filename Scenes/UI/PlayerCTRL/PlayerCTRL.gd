extends Control


# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal end_turn
signal freelook(c)
signal game_over(faction)


enum PROCESS_STATE {FOCUS=0, PROCESS=1, END=2}
enum FREELOOK_MODE {NORMAL=0, MANEUVER=1, IONLANCE=3}

# -----------------------------------------------------------
# Exports
# -----------------------------------------------------------
export var region_path : NodePath = ""		setget _set_region_path
export var faction : String = ""			setget _set_faction
export (float, 0.0, 2.0, 0.1) var slide_duration = 0.5


# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var region_node : Region = null

var cur = null
var queue = {}
var showing_hud = false
var in_turn = false

var _freelook_mode = FREELOOK_MODE.NORMAL

var _ships = []
var _ship_idx = -1

var _proc_idx = -1
var _proc_delay = 0.0
var _proc_state = PROCESS_STATE.FOCUS

var _ship_structure = 0

# -----------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------
onready var ship_status = get_node("HBC/Info/Status")
onready var command = get_node("HBC/Info/Command")
onready var power = get_node("HBC/Info/Power")
onready var engines = get_node("HBC/Info/Engines")
onready var maneuver = get_node("HBC/Info/Maneuver")
onready var sensors = get_node("HBC/Info/Sensors")
onready var ionlance = get_node("HBC/Info/IonLance")

onready var tween = get_node("Tween")


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
			for i in range(_ships.size()):
				_ships[i].enable_update_sensor_mask = false
				
			_ships = region_node.get_ships_in_faction(faction)
			_ship_idx = 0 if _ships.size() > 0 else -1
			
			# Loop through the new list and enable their sensor masks
			for i in range(_ships.size()):
				_ships[i].enable_update_sensor_mask = true
				_ships[i].call_deferred("update_sensor_mask")
				if i == _ship_idx:
					_focus_ship()

# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------
func _ready() -> void:
	set_process(false)
	set_process_unhandled_input(false)
	
	_set_region_path(region_path)
	power.visible = false
	engines.visible = false
	maneuver.visible = false
	command.visible = false
	sensors.visible = false
	ionlance.visible = false
	queue[command] = {"prev": maneuver, "next": power, "connection":"", "struct":0}
	queue[power] = {"prev": command, "next": ionlance, "connection":"", "struct":0}
	queue[ionlance] = {"prev": power, "next": sensors, "connection":"", "struct":0}
	queue[sensors] = {"prev": ionlance, "next": engines, "connection":"", "struct":0}
	queue[engines] = {"prev": sensors, "next": maneuver, "connection":"", "struct":0}
	queue[maneuver] = {"prev": engines, "next": command, "connection":"", "struct":0}
	cur = command
	cur.visible = true


func _unhandled_input(event):
	if event.is_action_pressed("freelook", false):
		_freelook(FREELOOK_MODE.NORMAL)
	if event.is_action_pressed("show_info", false):
		_on_toggle_hud()
	if event.is_action_pressed("next_ship", false):
		_next_ship()
	if event.is_action_pressed("prev_ship", false):
		_prev_ship()

func _process(delta : float) -> void:
	_proc_delay -= delta
	if _proc_idx >= 0 and _proc_delay <= 0:
		_proc_delay = 1.0
		var ship = null
		if _proc_idx < _ships.size():
			ship = _ships[_proc_idx]
			if not ship.is_commandable():
				_proc_delay = 0
				_proc_state = PROCESS_STATE.PROCESS
		
		match _proc_state:
			PROCESS_STATE.FOCUS:
				region_node.set_target_node(ship)
				_proc_state = PROCESS_STATE.PROCESS
			PROCESS_STATE.PROCESS:
				if ship.is_commandable():
					ship.process_turn()
				_proc_idx += 1
				_proc_state = PROCESS_STATE.FOCUS
				if _proc_idx >= _ships.size():
					_proc_state = PROCESS_STATE.END
			PROCESS_STATE.END:
				_proc_idx = -1
				set_process(false)
				_unfocus_ship()
				in_turn = false
				ship = _FindOperableShip()
				if ship != null:
					#_focus_ship()
					#region_node.set_target_node(ship)
					#set_process_unhandled_input(true)
					emit_signal("end_turn")
				else:
					emit_signal("game_over", faction)

# -----------------------------------------------------------
# Private Methods
# -----------------------------------------------------------
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


func _freelook(mode : int, cursor_mode : int = TacCom.CURSOR_MODE.LOOK) -> void:
	_freelook_mode = mode
	set_process_unhandled_input(false)
	if showing_hud:
		_on_toggle_hud()
	if _ship_idx >= 0:
		emit_signal("freelook", _ships[_ship_idx].coord, cursor_mode)
	else:
		emit_signal("freelook", Vector2.ZERO, cursor_mode)

func _next_ship() -> void:
	if _ship_idx >= 0:
		_unfocus_ship()
		_ship_idx += 1
		if _ship_idx == _ships.size():
			_ship_idx = 0
		_FindOperableShip(1)
		_focus_ship()

func _prev_ship() -> void:
	if _ship_idx >= 0:
		_unfocus_ship()
		_ship_idx -= 1
		if _ship_idx < 0:
			_ship_idx += _ships.size()
		_FindOperableShip(-1)
		_focus_ship()

func _ConnectShip(ship : Ship, sig_name : String, obj, method : String) -> void:
	if not ship.is_connected(sig_name, obj, method):
		ship.connect(sig_name, obj, method)

func _DisconnectShip(ship : Ship, sig_name : String, obj, method : String) -> void:
	if ship.is_connected(sig_name, obj, method):
		ship.disconnect(sig_name, obj, method)

func _unfocus_ship() -> void:
	if _ship_idx >= 0 and _ship_idx < _ships.size():
		var ship : Ship = _ships[_ship_idx]
		_DisconnectShip(ship, "structure_change", self, "_on_structure_change")
		_DisconnectShip(ship, "ordered", self, "_on_ordered")
		_DisconnectShip(ship, "commands_change", self, "_on_commands_change")
		_DisconnectShip(ship, "invalid_command", self, "_on_invalid_command")
		_DisconnectShip(ship, "power_change", self, "_on_power_change")
		_DisconnectShip(ship, "sublight_stats_change", self, "_on_sublight_stats_change")
		_DisconnectShip(ship, "maneuver_stats_change", self, "_on_maneuver_stats_change")
		_DisconnectShip(ship, "sensor_stats_change", self, "_on_sensor_stats_change")
		_DisconnectShip(ship, "ionlance_stats_change", self, "_on_ionlance_stats_change")

func _focus_ship() -> void:
	if _ship_idx >= 0 and _ship_idx < _ships.size() and region_node != null:
		var ship : Ship = _ships[_ship_idx]
		_ConnectShip(ship, "structure_change", self, "_on_structure_change")
		_ConnectShip(ship, "ordered", self, "_on_ordered")
		_ConnectShip(ship, "commands_change", self, "_on_commands_change")
		_ConnectShip(ship, "invalid_command", self, "_on_invalid_command")
		_ConnectShip(ship, "power_change", self, "_on_power_change")
		_ConnectShip(ship, "sublight_stats_change", self, "_on_sublight_stats_change")
		_ConnectShip(ship, "maneuver_stats_change", self, "_on_maneuver_stats_change")
		_ConnectShip(ship, "sensor_stats_change", self, "_on_sensor_stats_change")
		_ConnectShip(ship, "ionlance_stats_change", self, "_on_ionlance_stats_change")
		region_node.set_target_node(ship)
		ship.report_info()

func _SetStructureColor(connection : String, is_focus : bool = false) -> void:
	var color = Color("#ffe65d")
	var label = null
	match connection:
		"fore":
			label = ship_status.get_node("Label_Fore")
		"mid":
			label = ship_status.get_node("Label_Mid")
		"aft":
			label = ship_status.get_node("Label_Aft")
	
	if _ships[_ship_idx].get_body_structure(connection) == 0.0:
		label.set("custom_colors/font_color", Color("#333333"))
	else:
		label.set("custom_colors/font_color", color if is_focus else null)

func _SetStatusConnection(connection : String, struct_percentage : float) -> void:
	if ship_status:
		_SetStructureColor("aft", connection == "aft")
		_SetStructureColor("mid", connection == "mid")
		_SetStructureColor("fore", connection == "fore")
		ship_status.get_node("Bar").value = struct_percentage

func _SetVisToggle(pressed : bool, path : String, method : String) -> void:
	var btn = get_node(path)
	if btn:
		btn.disconnect("toggled", self, method)
		btn.pressed = pressed
		btn.connect("toggled", self, method)

# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------

func _on_game_ready() -> void:
	_set_faction(faction, true)

func _on_ui_lock() -> void:
	if in_turn:
		set_process_unhandled_input(false)
		set_process(false)

func _on_ui_release() -> void:
	if in_turn:
		if _proc_idx >= 0:
			set_process(true)
		else:
			set_process_unhandled_input(true)


func _on_process_turn() -> void:
	if _ships.size() > 0:
		_proc_state = PROCESS_STATE.FOCUS
		_proc_idx = 0
		showing_hud = false
		margin_top = 0
		_SetVisToggle(false, "HBC/Info/Engines/Sublight_BTN", "_on_Sublight_BTN_toggled")
		_SetVisToggle(false, "HBC/Info/Maneuver/Manuvers_BTN", "_on_Manuvers_BTN_toggled")
		_SetVisToggle(false, "HBC/Info/Sensors/Sensors_BTN", "_on_Sensors_BTN_toggled")
		#_SetVisToggle(false, "HBC/Info/Commands/Buttons/Missile_BTN", "_on_Missile_BTN_toggled")
		#_SetVisToggle(false, "HBC/Info/Commands/Buttons/Lasers_BTN", "_on_Lasers_BTN_toggled")
		set_process_unhandled_input(false)
		set_process(true)

func _on_start_turn(fac : String) -> void:
	if fac == faction and _ships.size() > 0:
		in_turn = true
		_focus_ship()
		set_process_unhandled_input(true)

func _on_freelook_exit(c : Vector2, confirm : bool) -> void:
	if not showing_hud:
		_on_toggle_hud()
	if _ship_idx >= 0 and region_node != null:
		region_node.set_target_node(_ships[_ship_idx])
	
	match _freelook_mode:
		FREELOOK_MODE.NORMAL:
			pass
		FREELOOK_MODE.MANEUVER:
			if confirm:
				var ship : Ship = _ships[_ship_idx]
				var me = ship.relative_edge_from_coord(c)
				var dir = 0
				if me == Hexmap.EDGE.LEFT_UP or me == Hexmap.EDGE.LEFT_DOWN:
					dir = 1 if me == Hexmap.EDGE.LEFT_UP else 2
				elif me == Hexmap.EDGE.RIGHT_UP or me == Hexmap.EDGE.RIGHT_DOWN:
					dir = -1 if me == Hexmap.EDGE.RIGHT_UP else -2
				elif me == Hexmap.EDGE.DOWN:
					dir = 3
				#print("Freelook direction: ", dir, " | Freelook Edge: ", me)
				if dir == 0 or not ship.command("ManeuverEngine", dir):
					_SetVisToggle(false, "HBC/Info/Maneuver/Manuvers_BTN", "_on_Manuvers_BTN_toggled")
			else:
				_SetVisToggle(false, "HBC/Info/Maneuver/Manuvers_BTN", "_on_Manuvers_BTN_toggled")
		FREELOOK_MODE.IONLANCE:
			if confirm:
				if region_node:
					var ship : Ship = _ships[_ship_idx]
					var ent = region_node.get_entity_at_coord(c)
					var targetable = ent.is_physical()
					if ent is Ship and ent.faction == faction:
						targetable = false
					if not targetable or not ship.command("IonLance", c):
						_SetVisToggle(false, "HBC/Info/IonLance/IonLance_BTN", "_on_IonLance_BTN_toggled")
				else:
					_SetVisToggle(false, "HBC/Info/IonLance/IonLance_BTN", "_on_IonLance_BTN_toggled")
			else:
				_SetVisToggle(false, "HBC/Info/IonLance/IonLance_BTN", "_on_IonLance_BTN_toggled")
	set_process_unhandled_input(true)


func _on_ship_added(ship : Ship):
	if ship.faction == faction:
		var nidx = _ships.size()
		_ships.append(ship)
		_ships[nidx].enable_update_sensor_mask = true
		_ships[nidx].update_sensor_mask()
		if _ship_idx < 0:
			_ship_idx = 0
			_focus_ship()

func _on_ship_removed(ship : Ship):
	for i in range(_ships.size()):
		if _ships[i] == ship:
			_ships.remove(i)
			if _ships.size() > 0:
				_ship_idx = 0
				_focus_ship()
			break


func _on_toggle_hud() -> void:
	tween.remove_all()
	if showing_hud:
		showing_hud = false
		var p = abs(margin_top) / 24
		tween.interpolate_property(self, "margin_top", margin_top, 0, slide_duration * p, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	else:
		showing_hud = true
		var p = 1.0 - (abs(margin_top)/24)
		tween.interpolate_property(self, "margin_top", margin_top, -24, slide_duration * p, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()


func _on_Prev_Info_pressed():
	cur.visible = false
	cur = queue[cur].prev
	_SetStatusConnection(queue[cur].connection, queue[cur].struct)
	cur.visible = true


func _on_Next_Info_pressed():
	cur.visible = false
	cur = queue[cur].next
	_SetStatusConnection(queue[cur].connection, queue[cur].struct)
	cur.visible = true


func _on_structure_change(struct : int, max_structure : int, comp : String, connection : String) -> void:
	var color = Color("#333333")
	var p = 0
	if max_structure > 0:
		p = floor((float(struct) / float(max_structure)) * 100)
	match comp:
		"Ship":
			_ship_structure = p
			#if cur == commands:
			#	_SetStatusConnection(queue[cur].connection, queue[cur].struct)
		"Command":
			queue[command].struct = p
			queue[command].connection = connection
			command.get_node("Label").set(
				"custom_colors/font_color",
				color if p == 0 else null
			)
			if cur == command:
				_SetStatusConnection(queue[cur].connection, queue[cur].struct)
		"Engineering":
			queue[power].connection = connection
			queue[power].struct = p
			power.get_node("Label").set(
				"custom_colors/font_color",
				color if p == 0 else null
			)
			if cur == power:
				_SetStatusConnection(queue[cur].connection, queue[cur].struct)
		"SublightEngine":
			queue[engines].connection = connection
			queue[engines].struct = p
			if p == 0:
				engines.get_node("Sublight_BTN").disabled = true
			else:
				engines.get_node("Sublight_BTN").disabled = false
			if cur == engines:
				_SetStatusConnection(queue[cur].connection, queue[cur].struct)
		"ManeuverEngine":
			queue[maneuver].connection = connection
			queue[maneuver].struct = p
			if p == 0:
				maneuver.get_node("Manuvers_BTN").disabled = true
			else:
				maneuver.get_node("Manuvers_BTN").disabled = false
			if cur == maneuver:
				_SetStatusConnection(queue[cur].connection, queue[cur].struct)
		"Sensors":
			queue[sensors].connection = connection
			queue[sensors].struct = p
			if p == 0:
				sensors.get_node("Sensors_BTN").disabled = true
			else:
				sensors.get_node("Sensors_BTN").disabled = false
			if cur == sensors:
				_SetStatusConnection(queue[cur].connection, queue[cur].struct)
		"IonLance":
			queue[ionlance].connection = connection
			queue[ionlance].struct = p
			if p == 0:
				ionlance.get_node("IonLance_BTN").disabled = true
			else:
				ionlance.get_node("IonLance_BTN").disabled = false
			if cur == ionlance:
				_SetStatusConnection(queue[cur].connection, queue[cur].struct)


func _on_ordered(ordered : bool, comp : String) -> void:
	match comp:
		"SublightEngine":
			_SetVisToggle(ordered, "HBC/Info/Engines/Sublight_BTN", "_on_Sublight_BTN_toggled")
		"ManeuverEngine":
			_SetVisToggle(ordered, "HBC/Info/Maneuver/Manuvers_BTN", "_on_Manuvers_BTN_toggled")
		"Sensors":
			_SetVisToggle(ordered, "HBC/Info/Sensors/Sensors_BTN", "_on_Sensors_BTN_toggled")
		"IonLance":
			_SetVisToggle(ordered, "HBC/Info/IonLance/IonLance_BTN", "_on_IonLance_BTN_toggled")

func _on_commands_change(available : int, total : int) -> void:
	if command:
		command.get_node("Available").text = String(available)
		command.get_node("Maximum").text = String(total)

func _on_invalid_command(order : String, ship : Ship) -> void:
	print("Invalid Command Made")
	ship.belay(order)

func _on_power_change(available : int, total : int) -> void:
	if power:
		power.get_node("Available").text = String(available)
		power.get_node("Maximum").text = String(total)

func _on_sublight_stats_change(propulsion_units : int, turns_to_trigger : int) -> void:
	if engines:
		engines.get_node("Units").text = String(propulsion_units)
		engines.get_node("Turns").text = String(turns_to_trigger)

func _on_maneuver_stats_change(degrees : float, turns_to_trigger : int) -> void:
	if maneuver:
		maneuver.get_node("Degrees").text = String(int(degrees))
		maneuver.get_node("Turns").text = String(turns_to_trigger)

func _on_sensor_stats_change(short_radius : int, long_radius : int) -> void:
	if sensors:
		sensors.get_node("Short").text = String(short_radius)
		sensors.get_node("Long").text = String(long_radius)

func _on_ionlance_stats_change(rng : int, dmg : float) -> void:
	if ionlance:
		ionlance.get_node("range").text = String(rng)
		ionlance.get_node("damage").text = String(floor(dmg))

func _on_Sublight_BTN_toggled(button_pressed):
	if _ship_idx >= 0:
		var ship : Ship = _ships[_ship_idx]
		if button_pressed:
			if not ship.command("SublightEngine"):
				_SetVisToggle(false, "HBC/Info/Engines/Sublight_BTN", "_on_Sublight_BTN_toggled")
		else:
			ship.belay("SublightEngine")


func _on_Manuvers_BTN_toggled(button_pressed):
	if _ship_idx >= 0:
		var ship : Ship = _ships[_ship_idx]
		if button_pressed:
			var fo = get_focus_owner()
			if fo:
				fo.release_focus()
			_freelook(FREELOOK_MODE.MANEUVER)
		else:
			ship.belay("ManeuverEngine")


func _on_Sensors_BTN_toggled(button_pressed):
	if _ship_idx >= 0:
		var ship : Ship = _ships[_ship_idx]
		if button_pressed:
			if not ship.command("Sensors"):
				_SetVisToggle(false, "HBC/Info/Sensors/Sensors_BTN", "_on_Sensors_BTN_toggled")
		else:
			ship.belay("Sensors")

func _on_IonLance_BTN_toggled(button_pressed):
	if _ship_idx >= 0:
		var ship : Ship = _ships[_ship_idx]
		if button_pressed:
			var fo = get_focus_owner()
			if fo:
				fo.release_focus()
			_freelook(FREELOOK_MODE.IONLANCE, TacCom.CURSOR_MODE.TARGET)
		else:
			ship.belay("IonLance")
