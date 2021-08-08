extends ShipComponent
class_name Engineering

# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal power_change(available, total)

# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var _max_power : int = 4
var _available_power : int = 4
var _reserved = {}

# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------

func _init(info : Dictionary).(info) -> void:
	if "power" in info:
		_max_power = info.power
		_available_power = _max_power
		emit_signal("power_change", _available_power, _max_power)

# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------


func request_power(requester : String, amount : int) -> int:
	if not requester in _reserved:
		if amount > _available_power:
			amount = _available_power
		_available_power -= amount
		_reserved[requester] = amount
		emit_signal("power_change", _available_power, _max_power)
	return _reserved[requester]

func release_power(requester : String) -> void:
	if requester in _reserved:
		_available_power += _reserved[requester]
		_reserved.erase(requester)
		emit_signal("power_change", _available_power, _max_power)
