extends PoweredComponent
class_name SublightEngine


# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal sublight_propulsion(units)
signal sublight_stats_change(propulsion_units, turns_to_trigger)

# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var _propulsion_units : int = 1
var _turns_to_trigger : int = 1
var _turns_passed : int = 0
var _units_to_move = 1

# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------

func _init(info : Dictionary).(info) -> void:
	if "propulsion_units" in info:
		_propulsion_units = info.propulsion_units
	if "turns_to_trigger" in info:
		_turns_to_trigger = info.turns_to_trigger
	emit_signal("sublight_stats_change", _propulsion_units, _turns_to_trigger)

# -----------------------------------------------------------
# Private Methods
# -----------------------------------------------------------


# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------
func report_info() -> void:
	if not _processing:
		emit_signal("sublight_stats_change", _propulsion_units, _turns_to_trigger)
		.report_info()
		
func process_turn() -> void:
	if not _processing:
		if _power_available >= _power_required:
			_turns_passed += 1
			if _turns_passed == _turns_to_trigger:
				_turns_passed = 0
				emit_signal("sublight_propulsion", _propulsion_units)
		else:
			_turns_passed = max(_turns_passed - 1, 0)
		
		# TODO: Handle Crew!
		
		.process_turn()


# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------

func _on_order_sublight(units_to_move : int = 0) -> void:
	if units_to_move <= 0 or units_to_move > _propulsion_units:
		units_to_move = _propulsion_units
	_units_to_move = units_to_move
	emit_signal("pull_power", _power_required)

func _on_belay_sublight() -> void:
	emit_signal("release_power")

