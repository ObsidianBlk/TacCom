extends Control


# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal process_complete
signal freelook(c)


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

var _ships = []
var _ship_idx = -1
var _proc_idx = -1
var _proc_delay = 0.0

# -----------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------
onready var ship_status = get_node("HBC/Info/Status")
onready var commands = get_node("HBC/Info/Commands")
onready var power = get_node("HBC/Info/Power")
onready var engines = get_node("HBC/Info/Engines")
onready var maneuver = get_node("HBC/Info/Maneuver")
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
			print("Trying to set faction")
			_ships = region_node.get_ships_in_faction(faction)
			print("Obtained ", _ships.size(), " ships")
			_ship_idx = 0 if _ships.size() > 0 else -1
			if _ship_idx >= 0:
				_focus_ship()
		else:
			print("Region not configured")

# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------
func _ready() -> void:
	_set_region_path(region_path)
	power.visible = false
	engines.visible = false
	maneuver.visible = false
	commands.visible = false
	queue[commands] = {"prev": maneuver, "next": power, "connection":"", "struct":0}
	queue[power] = {"prev": commands, "next": engines, "connection":"", "struct":0}
	queue[engines] = {"prev": power, "next": maneuver, "connection":"", "struct":0}
	queue[maneuver] = {"prev": engines, "next": commands, "connection":"", "struct":0}
	print(queue)
	cur = commands
	cur.visible = true


func _unhandled_input(event):
	if event.is_action_pressed("freelook", false):
		set_process_unhandled_input(false)
		if showing_hud:
			_on_toggle_hud()
		if _ship_idx >= 0:
			emit_signal("freelook", _ships[_ship_idx].coord)
		else:
			emit_signal("freelook", Vector2.ZERO)
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
		var ship = _ships[_proc_idx]
		ship.process_turn()
		_proc_idx += 1
		if _proc_idx >= _ships.size():
			_proc_idx = -1
			set_process(false)
			set_process_unhandled_input(true)
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
		_DisconnectShip(ship, "power_change", self, "_on_power_change")
		_DisconnectShip(ship, "sublight_stats_change", self, "_on_sublight_stats_change")
		_DisconnectShip(ship, "maneuver_stats_change", self, "_on_maneuver_stats_change")

func _focus_ship() -> void:
	if _ship_idx >= 0 and _ship_idx < _ships.size() and region_node != null:
		var ship : Ship = _ships[_ship_idx]
		_ConnectShip(ship, "structure_change", self, "_on_structure_change")
		_ConnectShip(ship, "ordered", self, "_on_ordered")
		_ConnectShip(ship, "power_change", self, "_on_power_change")
		_ConnectShip(ship, "sublight_stats_change", self, "_on_sublight_stats_change")
		_ConnectShip(ship, "maneuver_stats_change", self, "_on_maneuver_stats_change")
		region_node.set_target_node(ship)
		ship.report_info()

func _SetStatusConnection(connection : String, struct_percentage : float) -> void:
	var color = Color("#ffe65d")
	if ship_status:
		ship_status.get_node("Label_Aft").set(
			"custom_colors/font_color",
			color if connection == "aft" else null
		)
		ship_status.get_node("Label_Mid").set(
			"custom_colors/font_color",
			color if connection == "mid" else null
		)
		ship_status.get_node("Label_Fore").set(
			"custom_colors/font_color",
			color if connection == "fore" else null
		)
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

func _on_process_turn() -> void:
	if _ships.size() > 0:
		_proc_idx = 0
		showing_hud = false
		margin_top = 0
		_SetVisToggle(false, "HBC/Info/Commands/Buttons/Sublight_BTN", "_on_Sublight_BTN_toggled")
		_SetVisToggle(false, "HBC/Info/Commands/Buttons/Manuvers_BTN", "_on_Manuvers_BTN_toggled")
		_SetVisToggle(false, "HBC/Info/Commands/Buttons/Missile_BTN", "_on_Missile_BTN_toggled")
		_SetVisToggle(false, "HBC/Info/Commands/Buttons/Lasers_BTN", "_on_Lasers_BTN_toggled")
		set_process_unhandled_input(false)
		set_process(true)

func _on_freelook_exit() -> void:
	if not showing_hud:
		_on_toggle_hud()
	set_process_unhandled_input(true)
	if _ship_idx >= 0 and region_node != null:
		region_node.set_target_node(_ships[_ship_idx])


func _on_ship_added(ship : Ship):
	if ship.faction == faction:
		_ships.append(ship)
		if _ship_idx < 0:
			_ship_idx = 0
			_focus_ship()


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
	var p = 0
	if max_structure > 0:
		p = floor((float(struct) / float(max_structure)) * 100)
	match comp:
		"Ship":
			queue[commands].struct = p
			if cur == commands:
				_SetStatusConnection(queue[cur].connection, queue[cur].struct)
		"Engineering":
			queue[power].connection = connection
			queue[power].struct = p
			if cur == power:
				_SetStatusConnection(queue[cur].connection, queue[cur].struct)
		"SublightEngine":
			queue[engines].connection = connection
			queue[engines].struct = p
			if cur == engines:
				_SetStatusConnection(queue[cur].connection, queue[cur].struct)
		"ManeuverEngine":
			queue[maneuver].connection = connection
			queue[maneuver].struct = p
			if cur == maneuver:
				_SetStatusConnection(queue[cur].connection, queue[cur].struct)

func _on_ordered(ordered : bool, comp : String) -> void:
	match comp:
		"SublightEngine":
			var btn = get_node("HBC/Info/Commands/Buttons/Sublight_BTN")
			btn.disconnect("toggled", self, "_on_Sublight_BTN_toggled")
			btn.pressed = ordered
			btn.connect("toggled", self, "_on_Sublight_BTN_toggled")
		"ManeuverEngine":
			var btn = get_node("HBC/Info/Commands/Buttons/Manuvers_BTN")
			btn.disconnect("toggled", self, "_on_Manuvers_BTN_toggled")
			btn.pressed = ordered
			btn.connect("toggled", self, "_on_Manuvers_BTN_toggled")

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

func _on_Sublight_BTN_toggled(button_pressed):
	if _ship_idx >= 0:
		var ship : Ship = _ships[_ship_idx]
		if button_pressed:
			if not ship.command("SublightEngine"):
				var btn = get_node("HBC/Info/Commands/Buttons/Sublight_BTN")
				btn.disconnect("toggled", self, "_on_Sublight_BTN_toggled")
				btn.pressed = false
				btn.disconnect("toggled", self, "_on_Sublight_BTN_toggled")
		else:
			ship.belay("SublightEngine")


func _on_Manuvers_BTN_toggled(button_pressed):
	if _ship_idx >= 0:
		var ship : Ship = _ships[_ship_idx]
		if button_pressed:
			if not ship.command("ManeuverEngine"):
				var btn = get_node("HBC/Info/Commands/Buttons/Manuvers_BTN")
				btn.disconnect("toggled", self, "_on_Manuvers_BTN_toggled")
				btn.pressed = false
				btn.disconnect("toggled", self, "_on_Manuvers_BTN_toggled")
		else:
			ship.belay("ManeuverEngine")


func _on_Lasers_BTN_toggled(button_pressed):
	pass # Replace with function body.


func _on_Missile_BTN_toggled(button_pressed):
	pass # Replace with function body.

