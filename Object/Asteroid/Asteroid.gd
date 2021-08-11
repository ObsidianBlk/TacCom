extends Entity
class_name Asteroid

# -----------------------------------------------------------
# Setters/Getters
# -----------------------------------------------------------
func set_coord(c : Vector2):
	if hexmap_node:
		hexmap_node.set_coord_blocked(coord, false)
	.set_coord(c)
	if hexmap_node:
		hexmap_node.set_coord_blocked(coord, true)
