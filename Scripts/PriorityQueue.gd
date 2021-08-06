extends Node
class_name PriorityQueue


var _data = []

func _sort_priority(a, b) -> bool:
	return a[0] > b[0]

func put(priority : float, value) -> void:
	_data.append([priority, value])
	_data.sort_custom(self, "_sort_priority")

func pop():
	return _data.pop_back()

func empty() -> bool:
	return _data.empty()

func size() -> int:
	return _data.size()

func clear() -> void:
	_data.clear()
