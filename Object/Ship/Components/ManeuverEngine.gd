extends PoweredComponent
class_name ManeuverEngine


# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal maneuver(degrees)
signal maneuver_stats_change(degrees, turns_to_trigger)
signal ordered(o)

# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var _degrees_per_unit : float = 60.0
var _units_per_turn : int = 1
var _turns_to_trigger : int = 1
var _turns_passed : int = 0
var _dir = 0
var _amount : float = 0.0


# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------

func _init(info : Dictionary).(info) -> void:
	if "units_per_turn" in info:
		_units_per_turn = max(1, min(info.units_per_turn, 3))
	if "turns_to_trigger" in info:
		_turns_to_trigger = info.turns_to_trigger
	call_deferred("emit_signal", "maneuver_stats_change", _units_per_turn * _degrees_per_unit, _turns_to_trigger)

# -----------------------------------------------------------
# Private Methods
# -----------------------------------------------------------
func _DegreesInBounds(d : float) -> float:
	while d < 0:
		d += 360
	while d >= 360:
		d -= 360
	return d

# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------
func report_info() -> void:
	if not _processing:
		emit_signal("maneuver_stats_change", _units_per_turn * _degrees_per_unit, _turns_to_trigger)
		emit_signal("ordered", _dir != 0)
		.report_info()


func process_turn() -> void:
	if not _processing:
		if _power_available >= _power_required:
			_turns_passed += 1
			if _turns_passed == _turns_to_trigger:
				_turns_passed = 0
				emit_signal("maneuver", _amount)
				emit_signal("release_power")
				_dir = 0
		else:
			_turns_passed = max(_turns_passed - 1, 0)
		
		# TODO: Handle Crew!
		
		.process_turn()


func command(order : String, detail = null) -> bool:
	if not _processing:
		if order == "ManeuverEngine" and _dir == 0 and detail != null:
			if detail > 0:
				_dir = 1
			elif detail < 0:
				_dir = -1
			if _dir != 0:
				_amount = _degrees_per_unit * max(0, min(abs(detail), _units_per_turn))
				_amount *= _dir
				emit_signal("pull_power", _power_required)
				emit_signal("ordered", _dir != 0)
				return true
		return .command(order, detail)
	return false


func belay(order : String) -> void:
	if not _processing:
		if _dir != 0 and order == "ManeuverEngine":
			_dir = 0
			emit_signal("release_power")
			emit_signal("ordered", false)
		.belay(order)
