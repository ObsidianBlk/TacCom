extends PoweredComponent
class_name IonLance

# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal attack(target, dmg)
signal ionlance_stats_change(range_units, dmg)
signal ordered(o)


# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var _max_range : int = 0
var _range : int = 0
var _max_dmg : float = 0.0
var _dmg : float = 0.0
var _target_coord = null


# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------

func _init(info : Dictionary).(info) -> void:
	if "range" in info:
		if info.range > 0:
			_max_range = info.range
			_range = _max_range
	if "damage" in info:
		if info.damage > 0:
			_max_dmg = info.damage
			_dmg = _max_dmg
	call_deferred("emit_signal", "ionlance_stats_change", _range, _dmg)


# -----------------------------------------------------------
# Private Methods
# -----------------------------------------------------------

func _handle_damage(type : int, amount : float, emitBlowback : bool = true) -> void:
	var ostruct = _structure
	._handle_damage(type, amount, emitBlowback)
	if (_structure / ostruct) < 0.75:
		if _range > 1:
			_range -= 1
		else:
			_dmg *= 0.25
			if _dmg < 0.2 * _max_dmg:
				_dmg = 0.0
		emit_signal("ionlance_stats_change", _range, _dmg)



# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------
func set_destroyed() -> void:
	_range = 0
	_dmg = 0
	emit_signal("ionlance_stats_change", _range, _dmg)
	.set_destroyed()

func report_info() -> void:
	if not _processing_report:
		emit_signal("ionlance_stats_change", _range, _dmg)
		emit_signal("ordered", _target_coord != null)
		.report_info()


func process_turn() -> void:
	if not _processing:
		if _target_coord != null and _power_available >= _power_required:
			emit_signal("attack", _target_coord, _dmg)
			emit_signal("release_power")
		
		# TODO: Handle Crew!
		
		.process_turn()


func command(order : String, detail = null) -> bool:
	if not _processing:
		if order == "IonLance" and detail != null:
			if detail is Vector2:
				_target_coord = detail
			emit_signal("pull_power", _power_required)
			emit_signal("ordered", _target_coord != null)
			return true
		return .command(order, detail)
	return false


func belay(order : String) -> void:
	if not _processing:
		if order == "IonLance" and _target_coord != null:
			_target_coord = null
			emit_signal("release_power")
			emit_signal("ordered", _target_coord != null)
		.belay(order)



