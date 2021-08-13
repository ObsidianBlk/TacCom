extends Entity
class_name Asteroid

# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------
func _ready() -> void:
	_blocking = true

# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------
func collision_damage() -> float:
	return 100.0
