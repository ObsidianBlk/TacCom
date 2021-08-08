extends ShipComponent
class_name PoweredComponent


var _powerComponent : Engineering = null
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
func connect_engineering(c : Engineering) -> void:
	_powerComponent = c
