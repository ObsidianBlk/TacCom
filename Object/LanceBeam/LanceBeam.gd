extends Node2D


# -----------------------------------------------------------
# Signals
# -----------------------------------------------------------
signal pew_over

# -----------------------------------------------------------
# Export Variables
# -----------------------------------------------------------
export var beam_color : Color = Color(1,0,0)
export var offset : Vector2 = Vector2.ZERO
export var strike_area : Vector2 = Vector2(4,4)


# -----------------------------------------------------------
# Variables
# -----------------------------------------------------------
var _firing : bool = false
var _beamCount : int = 0
var _target : Vector2 = Vector2.ZERO
var _beams = {}

onready var timer = get_node("Timer")

# -----------------------------------------------------------
# Override Methods
# -----------------------------------------------------------

func _draw() -> void:
	for beam in _beams.keys():
		draw_line(offset, beam.to + offset, beam.color, 1)


func _process(delta : float) -> void:
	if not _beams.empty():
		var beams = _beams.keys()
		for beam in beams:
			if _beams[beam] > 0:
				_beams[beam] -= delta
			else:
				_beams.erase(beam)
				if _beams.empty() and _beamCount <= 0:
					_firing = false
					emit_signal("pew_over")
		update()

# -----------------------------------------------------------
# Private Methods
# -----------------------------------------------------------

func _CreateBeam() -> void:
	var color_offset = 0.5 + (0.5 * randf())
	var color = Color(
		beam_color.r * color_offset,
		beam_color.g * color_offset,
		beam_color.b * color_offset,
		beam_color.a
	)
	var strike = -strike_area + Vector2(
		strike_area.x * 2 * randf(),
		strike_area.y * 2 * randf()
	)
	var beam = {
		"to": _target + strike,
		"color": color
	}
	_beams[beam] = 0.2 + (0.5 * randf())

# -----------------------------------------------------------
# Public Methods
# -----------------------------------------------------------

func fire(target : Vector2, beam_count : int) -> void:
	if _firing:
		return
	
	randomize()
	_firing = true
	_target = target
	_beamCount = beam_count - 1
	
	_CreateBeam()
	timer.start(0.2 + (0.6 * randf()))
	



func _on_Timer_timeout():
	if _beamCount > 0:
		_CreateBeam()
		_beamCount -= 1
		timer.start(0.2 + (0.6 * randf()))
