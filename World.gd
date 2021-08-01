extends Node2D

onready var logo_node = get_node("Logo")

func _on_logo_complete() -> void:
	remove_child(logo_node)
	logo_node.queue_free()


