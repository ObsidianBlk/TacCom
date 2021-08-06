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
var _radiation : int = 0

func treat(c : Crewman) -> void:
	var healing = work_score(TYPE.MEDICAL)
	c.heal(healing * (dexterity * 2))

func heal(amount : int) -> void:
	if not alive():
		return

	if _radiation < 25 and amount > int(50 / float(constitution)):
		_wounds = max(_wounds - 1, 0)
	if _radiation > 0:
		_radiation = max(0, _radiation - int(float(amount) * 0.5))
		amount = int(float(amount) * 0.5)
	amount = max(0, amount - _radiation)
	_health = min(_health + amount, 100 - _radiation)

func work_score(job_type : int) -> float:
	var score = 0
	if _health > 0 and _wounds < 3:
		if job_type == type:
			score = float(skill_level)
		elif job_type != TYPE.MEDICAL:
			score = max(1, min(skill_level, 2))
		else:
			score = SKILL.LOW
		if _wounds > 0:
			score *= 1 - (float(_wounds)*0.3333)
		score *= health_rating()
	return score

func health_rating() -> float:
	var hr = 0
	if alive():
		return float(_health + (abs(constitution - _wounds) * 10)) / 110
	return hr

func alive() -> bool:
	return _health > 0 and _wounds < 3

func hazard(dmg : float, rads : float) -> void:
	if not alive():
		return
		
	var old_health = _health
	var hr = health_rating()
	if float(dexterity) * hr > float(dexterity):
		dmg *= 0.5
	if float(constitution) * hr > float(constitution):
		rads *= 0.5
	var wcon = max(0, constitution - _wounds)
	_health = max(0, min((_health + wcon * 10) - dmg, _health))
	if (old_health - _health) > (old_health * 0.25):
		_wounds += 1
	_radiation += rads

