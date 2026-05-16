extends Sprite2D

@export var shake_duration: float = 1
@export var pause_duration: float = 0.5
@export var max_angle: float = 5
@export var decay_factor: float = 0.5
@export var swing_count: int = 4

var _tween: Tween = null

func _ready():
	_start_rotation_loop()

func _start_rotation_loop():
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_loops(0)
	var single_swing_duration = shake_duration / swing_count
	for i in range(swing_count):
		var current_amplitude = max_angle * pow(decay_factor, i)
		_tween.tween_property(self, "rotation_degrees", -current_amplitude, single_swing_duration / 2)\
			  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(self, "rotation_degrees", current_amplitude, single_swing_duration / 2)\
			  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_interval(pause_duration)
