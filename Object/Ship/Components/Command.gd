extends ShipComponent
class_name Command

# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal commands_change(available, total)
signal invalid_command(order)


# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var _max = 1
var _total = 1
var _available = 1

# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------
func _init(info : Dictionary).(info) -> void:
	if "commands" in info:
		_max = info.commands
		_total = info.commands
		_available = _total
		call_deferred("emit_signal", "commands_change", _available, _total)


# -----------------------------------------------------------
# Private Methods
# -----------------------------------------------------------

func _handle_damage(type : int, amount : float, emitBlowback : bool = true) -> void:
	var ostruct = _structure
	._handle_damage(type, amount, emitBlowback)
	if (_structure / ostruct) < 0.75 and _total > 0:
		_total -= 1
		_available = min(_available, _total)
		emit_signal("commands_change", _available, _total)


# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------
func set_destroyed() -> void:
	_available = 0
	_total = 0
	emit_signal("commands_change", _available, _total)
	.set_destroyed()

func report_info() -> void:
	if not _processing_report:
		emit_signal("commands_change", _available, _total)
		.report_info()

func process_turn() -> void:
	if not _processing:
		# Just automatically reset the number of available commands
		_available = _total
		emit_signal("commands_change", _available, _total)
		# TODO: Handle Crew at this point...
		.process_turn()

func command(order : String, detail = null) -> bool:
	if not _processing:
		# Don't care the order, we loose an available command point
		# if one's available
		if _available > 0:
			_available -= 1
			emit_signal("commands_change", _available, _total)
		else:
			call_deferred("emit_signal", "invalid_command", order)
		return .command(order, detail)
	return false

func belay(order : String) -> void:
	if not _processing:
		if _available < _total:
			_available += 1
			emit_signal("commands_change", _available, _total)
		.belay(order)


