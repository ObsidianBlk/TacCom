extends "res://Scripts/Entity.gd"


func _input(event) -> void:
	if hexmap_node:
		hexmap_node.clear_highlights()
	if event.is_action_pressed("up"):
		shift_by_degree(0)
	if event.is_action_pressed("up_left"):
		shift_by_degree(60)
	if event.is_action_pressed("down_left"):
		shift_by_degree(120)
	if event.is_action_pressed("down"):
		shift_by_degree(180)
	if event.is_action_pressed("down_right"):
		shift_by_degree(240)
	if event.is_action_pressed("up_right"):
		shift_by_degree(300)
	if hexmap_node:
		var coords = hexmap_node.get_cells_at_distance(int(coord.x), int(coord.y), 2)
		for c in coords:
			hexmap_node.highlight_coord(c, Color(1,0,0))


func _draw():
	draw_circle(Vector2(0,0), 3, Color(0,0,1))


func _process(_delta : float) -> void:
	update()
