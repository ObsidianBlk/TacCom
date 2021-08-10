extends Reference
class_name PriorityQueue


var _data = []

func _sort_priority(a, b) -> bool:
	return a[0] > b[0]

func put(priority : float, value) -> void:
	_data.append([priority, value])
	_data.sort_custom(self, "_sort_priority")

func pop():
	var info = _data.pop_back()
	return info[1] # This returns the value

func pop_full():
	return _data.pop_back()

func peek(index : int):
	if index >= 0 and index < _data.size():
		return {
			"priority":_data[index][0],
			"value":_data[index][1]
		}
	return null

func peek_value(index : int):
	if index >= 0 and index < _data.size():
		return _data[index][1]
	return null

func find(value) -> int:
	for i in range(_data.size()):
		if _data[i][1] == value:
			return i
	return -1

func empty() -> bool:
	return _data.empty()

func size() -> int:
	return _data.size()

func clear() -> void:
	_data.clear()
