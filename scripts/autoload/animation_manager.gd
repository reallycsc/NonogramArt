extends Node

var _active_tweens: Dictionary = {}

func register_tween(tween: Tween) -> void:
	if _active_tweens.has(tween):
		return
	_active_tweens[tween] = true
	tween.finished.connect(func():
		_active_tweens.erase(tween)
	, CONNECT_ONE_SHOT)

func wait_for_all_animations() -> bool:
	return _active_tweens.is_empty()

func await_for_all_animations():
	while not _active_tweens.is_empty():
		var keys = _active_tweens.keys()
		var tween = keys[0] as Tween
		if tween and tween.is_valid():
			await tween.finished
		else:
			_active_tweens.erase(tween)

func clear_queue():
	for tween in _active_tweens.keys():
		if tween and tween.is_valid():
			tween.kill()
	_active_tweens.clear()
