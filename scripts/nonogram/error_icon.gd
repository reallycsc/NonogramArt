extends Sprite2D

# 导出参数，方便在编辑器中调整
@export var shake_duration: float = 1      # 单次旋转持续时间（秒）
@export var pause_duration: float = 0.5   # 停顿时间（秒）
@export var max_angle: float = 5         # 最大旋转角度（度）
@export var decay_factor: float = 0.5      # 幅度衰减因子（0-1，越小衰减越快）
@export var swing_count: int = 4        # 2秒内的摆动次数

func _ready():
	start_rotation_cycle()

# 异步函数，处理完整的旋转周期（旋转 + 停顿）
func start_rotation_cycle():
	# 创建Tween对象
	var tween = create_tween()
	
	# 计算每个摆动阶段的时间（将总时间分配给各个摆动）
	var single_swing_duration = shake_duration / swing_count
	
	# 创建阻尼旋转动画序列
	for i in range(swing_count):
		# 计算当前摆动的幅度（指数衰减）
		var current_amplitude = max_angle * pow(decay_factor, i)
		
		# 向左摆动（负角度）
		tween.tween_property(self, "rotation_degrees", -current_amplitude, single_swing_duration / 2)\
			  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# 向右摆动（正角度），回到中心点
		tween.tween_property(self, "rotation_degrees", current_amplitude, single_swing_duration / 2)\
			  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# 等待旋转动画完成
	await tween.finished
	
	# 等待停顿时间
	await get_tree().create_timer(pause_duration).timeout
	
	# 重新开始下一个周期
	start_rotation_cycle()
