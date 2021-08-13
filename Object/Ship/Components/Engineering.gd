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
var _generated_power : int = 4
var _available_power : int = 4
var _reserved = {}

# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------

func _init(info : Dictionary).(info) -> void:
	if "power" in info:
		_max_power = info.power
		_generated_power = _max_power
		_available_power = _max_power
		call_deferred("emit_signal", "power_change", _available_power, _generated_power)

# -----------------------------------------------------------
# Private Methods
# -----------------------------------------------------------

func _handle_damage(type : int, amount : float, emitBlowback : bool = true) -> void:
	var ostruct = _structure
	match type:
		TacCom.DAMAGE_TYPE.ENERGY:
			var dmg = amount - (amount * _EnergyDefense())
			_structure = max(0, _structure - (_structure * (dmg / 200)))
		_:
			._handle_damage(type, amount, false)
	
	if emitBlowback and (_structure / ostruct) < 0.75:
		_generated_power -= 1
		_available_power = min(_available_power, _generated_power)
		emit_signal("power_change", _available_power, _generated_power)
		if _generated_power == 0:
			print("Engineering catastrophic explosion!")
			emit_signal("damage_blowback", TacCom.DAMAGE_TYPE.KINETIC, _structure * 2)
			_structure = 0
		else:
			print("Engineering Energy Blockback! ", _structure, "/", ostruct, "=", (_structure/ostruct))
			emit_signal("damage_blowback", TacCom.DAMAGE_TYPE.KINETIC, (ostruct - _structure) * 0.5)

# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------

func connect_powered_component(pc : PoweredComponent) -> void:
	pc.connect("pull_power", self, "_on_pull_power", [pc])
	pc.connect("release_power", self, "_on_release_power", [pc])

func set_destroyed() -> void:
	_available_power = 0
	_generated_power = 0
	emit_signal("power_change", _available_power, _generated_power)
	for pc in _reserved.keys():
		pc.power(0)
	_reserved = {}
	.set_destroyed()

func report_info() -> void:
	if not _processing_report:
		emit_signal("power_change", _available_power, _generated_power)
		.report_info()

func process_turn() -> void:
	if not _processing:
		# Just automatically take back ALL the power! HA!
		_available_power = _generated_power
		_reserved = {}
		# TODO: Handle Crew at this point...
		.process_turn()

# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------
func _on_pull_power(amount : int, pc : PoweredComponent) -> void:
	if amount <= 0:
		return

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
		_available_power = min(_available_power + _reserved[pc], _generated_power)
		_reserved.erase(pc)
		pc.power(0)
		emit_signal("power_change", _available_power, _generated_power)

