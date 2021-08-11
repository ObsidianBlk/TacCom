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
var _degrees : float = 60.0
var _turns_to_trigger : int = 1
var _turns_passed : int = 0
var _ordered : bool = false


# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------

func _init(info : Dictionary).(info) -> void:
	if "degrees" in info:
		_degrees = _DegreesInBounds(info.degrees)
	if "turns_to_trigger" in info:
		_turns_to_trigger = info.turns_to_trigger
	emit_signal("maneuver_stats_change", _degrees, _turns_to_trigger)

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
		emit_signal("maneuver_stats_change", _degrees, _turns_to_trigger)
		emit_signal("ordered", _ordered)
		.report_info()


func process_turn() -> void:
	if not _processing:
		if _power_available >= _power_required:
			_turns_passed += 1
			if _turns_passed == _turns_to_trigger:
				_turns_passed = 0
				emit_signal("maneuver", _degrees)
				emit_signal("release_power")
				_ordered = false
		else:
			_turns_passed = max(_turns_passed - 1, 0)
		
		# TODO: Handle Crew!
		
		.process_turn()


func command(order : String) -> bool:
	if not _processing:
		if order == "ManeuverEngine":
			_ordered = true
			emit_signal("pull_power", _power_required)
			emit_signal("ordered", _ordered)
			return true
		return .command(order)
	return false


func belay(order : String) -> void:
	if not _processing:
		_ordered = false
		emit_signal("release_power")
		emit_signal("ordered", _ordered)
		.belay(order)
