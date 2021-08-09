extends ShipComponent
class_name PoweredComponent


# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal pull_power(amount)
signal release_power()

# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var _power_required : int = 0
var _power_available : int = 0


# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------
func _init(info : Dictionary).(info) -> void:
	if "power_required" in info:
		_power_required = info.power_required

# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------
func power(amount : int):
	_power_available = amount
