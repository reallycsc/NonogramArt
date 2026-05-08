extends Node

# 存储正在播放的动画播放器及其结束信号
var _active_tweens: Array[Tween] = []

# 注册一个Tween开始播放
func register_tween(tween: Tween) -> void:
	if not _active_tweens.has(tween):
		_active_tweens.append(tween)
		# 连接动画结束信号，播放结束后自动从列表中移除
		tween.finished.connect(func():
			if _active_tweens.has(tween):
				_active_tweens.erase(tween)
		)
		
# 等待所有已注册的动画播放器完成
func wait_for_all_animations() -> bool:
	if _active_tweens.is_empty():
		return true
	# 持续检查，直到列表为空（所有动画结束）或超时
	while not _active_tweens.is_empty():
		return false
	return true

# 等待所有已注册的动画播放器完成
func await_for_all_animations():
	# 过滤掉已释放的tween
	var valid_tweens = []
	for tween in _active_tweens:
		if tween:
			valid_tweens.append(tween)
		else:
			_active_tweens.erase(tween)
	for tween in valid_tweens:
		await tween.finished
		
# 手动清空所有动画队列
func clear_queue():
	for tween in _active_tweens:
		if tween:
			tween.kill()  # 确保停止并清理tween
	_active_tweens.clear()
