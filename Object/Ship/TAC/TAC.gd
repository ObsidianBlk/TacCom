extends "res://Scripts/Entity.gd"


onready var sprite = get_node("Sprite")


func _input(event) -> void:
	if hexmap_node:
		hexmap_node.clear_highlights()
	if event.is_action_pressed("up"):
		shift_by_degree(0)
		_swapFacing(Hexmap.EDGE.UP)
	if event.is_action_pressed("up_left"):
		shift_by_degree(60)
		_swapFacing(Hexmap.EDGE.LEFT_UP)
	if event.is_action_pressed("down_left"):
		shift_by_degree(120)
		_swapFacing(Hexmap.EDGE.LEFT_DOWN)
	if event.is_action_pressed("down"):
		shift_by_degree(180)
		_swapFacing(Hexmap.EDGE.DOWN)
	if event.is_action_pressed("down_right"):
		shift_by_degree(240)
		_swapFacing(Hexmap.EDGE.RIGHT_DOWN)
	if event.is_action_pressed("up_right"):
		shift_by_degree(300)
		_swapFacing(Hexmap.EDGE.RIGHT_UP)
	if hexmap_node:
		var coords = hexmap_node.get_cells_at_distance(int(coord.x), int(coord.y), 1)
		for c in coords:
			hexmap_node.highlight_coord(c, Color(1,0,0))


func _swapFacing(edge : int):
	if not sprite:
		return
	
	var width = sprite.texture.get_width() / 6
	var height = sprite.texture.get_height()
	match (edge):
		Hexmap.EDGE.UP:
			sprite.region_rect = Rect2(Vector2(0, 0), Vector2(width, height))
		Hexmap.EDGE.LEFT_UP:
			sprite.region_rect = Rect2(Vector2(width, 0), Vector2(width, height))
		Hexmap.EDGE.LEFT_DOWN:
			sprite.region_rect = Rect2(Vector2(width * 2, 0), Vector2(width, height))
		Hexmap.EDGE.DOWN:
			sprite.region_rect = Rect2(Vector2(width * 3, 0), Vector2(width, height))
		Hexmap.EDGE.RIGHT_DOWN:
			sprite.region_rect = Rect2(Vector2(width * 4, 0), Vector2(width, height))
		Hexmap.EDGE.RIGHT_UP:
			sprite.region_rect = Rect2(Vector2(width * 5, 0), Vector2(width, height))
