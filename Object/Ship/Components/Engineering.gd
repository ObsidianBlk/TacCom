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

func connect_powered_component(pc : PoweredComponent) -> void:
	pc.connect("pull_power", self, "_on_pull_power", [pc])
	pc.connect("release_power", self, "_on_release_power", [pc])


func process_turn() -> void:
	# Just automatically take back ALL the power! HA!
	_available_power = _max_power
	_reserved = {}
	# TODO: Handle Crew at this point...

# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------
func _on_pull_power(amount : int, pc : PoweredComponent) -> void:
	var oap = _available_power
	if amount > _available_power:
		amount = _available_power
	if pc in _reserved:
		amount += _reserved[pc]
		_available_power += _reserved[pc]
	if amount > 0:
		_reserved[pc] = amount
		_available_power -= amount
		pc.power(amount)
		if oap != _available_power:
			emit_signal("power_change", _available_power, _max_power)


func _on_release_power(pc : PoweredComponent) -> void:
	if pc in _reserved:
		_available_power += _reserved[pc]
		_reserved.erase(pc)
		emit_signal("power_change", _available_power, _max_power)

