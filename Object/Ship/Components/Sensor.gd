extends PoweredComponent
class_name Sensor

# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal long_range(long_radius)
signal sensor_stats_change(short_radius, long_radius)
signal ordered(o)


# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var _base_radius = {"short":1, "long":1}
var _radius = {"short":1, "long":1}
var _ordered : bool = false


# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------

func _init(info : Dictionary).(info) -> void:
	if "short_radius" in info:
		_base_radius.short = info.short_radius
		_radius.short = info.short_radius
	if "long_radius" in info:
		_base_radius.long = info.long_radius
		_radius.long = info.long_radius
	call_deferred("emit_signal", "sensor_stats_change", _radius.short, _radius.long)
	#emit_signal("sensor_stats_change", _radius.short, _radius.long)


# -----------------------------------------------------------
# Private Methods
# -----------------------------------------------------------

func _handle_damage(type : int, amount : float, emitBlowback : bool = true) -> void:
	var ostruct = _structure
	._handle_damage(type, amount, emitBlowback)
	if (_structure / ostruct) < 0.75 and _radius.short > 1:
		if _radius.long > 0:
			_radius.long -= 1
		else:
			_radius.short -= 1
		emit_signal("sensor_stats_change", _radius.short, _radius.long)


# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------
func set_destroyed() -> void:
	_radius.short = 0
	_radius.long = 0
	emit_signal("sensor_stats_change", _radius.short, _radius.long)
	.set_destroyed()


func report_info() -> void:
	if not _processing_report:
		emit_signal("sensor_stats_change", _radius.short, _radius.long)
		emit_signal("ordered", _ordered)
		.report_info()


func process_turn() -> void:
	if not _processing:
		if _power_available >= _power_required:
			emit_signal("long_range", _radius.long)
			emit_signal("release_power")
			_ordered = false
		
		# TODO: Handle Crew!
		
		.process_turn()


func command(order : String, detail = null) -> bool:
	if not _processing:
		if order == "Sensors":
			if _radius.long > 0:
				_ordered = true
				emit_signal("pull_power", _power_required)
				emit_signal("ordered", _ordered)
				return true
		return .command(order, detail)
	return false


func belay(order : String) -> void:
	if not _processing:
		if order == "Sensors" and _ordered:
			_ordered = false
			emit_signal("release_power")
			emit_signal("ordered", _ordered)
		.belay(order)


