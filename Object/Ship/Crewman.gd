extends Node
class_name Crewman


enum TYPE {GENERAL=0, OPERATIONS=1, MEDICAL=2, ENGINEERING=3, SCIENCE=4, TACTICAL=5}
enum SKILL {LOW=1, AVERAGE=2, PROFICENT=3, TRAINED=4, EXPERT=5} 

export (TYPE) var type = TYPE.GENERAL
export (SKILL) var skill_level = SKILL.LOW
export (int, 1, 5) var constitution = 2
export (int, 1, 5) var dexterity = 2

var _health : int = 100
var _wounds : int = 0 # Once three wounds are reached, the crewman is dead

func treat(c : Crewman) -> void:
	pass # Determine if and how well this crewman heals the given crewman

func heal(amount : int) -> void:
	_health = min(_health + amount, 100)

func work_score() -> float:
	var score = 0
	if _health > 0 and _wounds < 3:
		score = float(skill_level)
		score *= (float(_health + (constitution * 10))/110)
		if _wounds > 0:
			score *= 1 - (float(_wounds)*0.3333)
	return score

func alive() -> bool:
	return _health > 0

func _handle_hazard(risk : float) -> void:
	pass # Make a calculation on if a crewman gets hurt, by how much, and if they die
