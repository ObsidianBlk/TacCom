extends Entity
class_name Asteroid


signal animating
signal animation_complete


var _HP = 100

onready var explosion = get_node("Explosion")

# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------
func _ready() -> void:
	_blocking = true
	if explosion:
		explosion.connect("boom_over", self, "_on_damage_anim_complete")

# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------
func damage(type : int, amount : float) -> void:
	if type == TacCom.DAMAGE_TYPE.KINETIC:
		_HP -= amount
		if _HP <= 0:
			if visible and explosion:
				emit_signal("animating")
				explosion.boom()
			else:
				_on_damage_anim_complete()


func collision_damage() -> float:
	return 100.0


func collide(e : Entity, one_way : bool = false) -> void:
	var dmg = e.collision_damage()
	damage(TacCom.DAMAGE_TYPE.KINETIC, dmg)
	if not one_way:
		e.collide(self, true)


# -----------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------

func _on_damage_anim_complete() -> void:
	var parent = get_parent()
	if parent:
		parent.remove_child(self)
	queue_free()
	emit_signal("animation_complete")
