extends Camera2D

# 定义缩放的最小、最大值和缩放步长
var min_zoom: float = 1
var max_zoom: float = 1
var zoom_step: float = 0.1

var drag_sensitivity: float = 1.0 # 控制拖拽灵敏度的系数，值越大，相机移动幅度相对于鼠标移动越大
var drag_threshold: float = 10.0 # 触发拖拽的移动阈值（像素），可防止误触
var smooth_speed: float = 10.0 # 平滑速度变量

var minPosition:Vector2 = Vector2.ZERO
var maxPosition:Vector2 = Vector2(1280,720)

var is_dragging := false
var drag_start_position: Vector2 = position
var target_position: Vector2 = position
var viewport_size: Vector2 = Vector2.ZERO

func _ready():
	viewport_size = get_viewport_rect().size
	maxPosition = viewport_size
	
func _unhandled_input(event: InputEvent) -> void:
	if not AnimationManager.wait_for_all_animations():
		return
	# 检测鼠标滚轮输入事件
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP: # 滚轮向上滚动，缩小画面（相机视野拉近，物体变大）
				zoom += Vector2(zoom_step, zoom_step)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: # 滚轮向下滚动，放大画面（相机视野拉远，物体变小）
				zoom -= Vector2(zoom_step, zoom_step)
			zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom)) # 将缩放比例限制在设定的范围内
			minPosition = viewport_size / zoom / 2
			maxPosition = viewport_size - minPosition
			position = position.clamp(minPosition, maxPosition)
			target_position = target_position.clamp(minPosition, maxPosition)
			if event.button_index == MOUSE_BUTTON_LEFT and event.ctrl_pressed:
				is_dragging = true
				drag_start_position = event.position
				get_viewport().set_input_as_handled()
		else:
			# 鼠标释放：重置所有状态
			is_dragging = false
	# 检测鼠标移动事件，并且仅在拖拽状态下处理
	if event is InputEventMouseMotion and is_dragging:
		if event.ctrl_pressed:
			if (event.position - drag_start_position).length() > drag_threshold:
				var drag_offset = (drag_start_position - event.position) * drag_sensitivity / zoom.x
				target_position += drag_offset
				target_position = target_position.clamp(minPosition, maxPosition)
				drag_start_position = event.position
			get_viewport().set_input_as_handled()
	
# 在 _process 中实现平滑移动
func _process(delta):
	position = position.lerp(target_position, smooth_speed * delta)
	# position = position.clamp(minPosition, maxPosition)

func reset():
	zoom = Vector2.ONE
	min_zoom = 1
	max_zoom = 1

# 相机震动效果
func shake(intensity: float = 100.0):
	var original_position = position
	var shake_offset = Vector2(intensity, -intensity)
	target_position = original_position + shake_offset
	# 等待一段时间后复位
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	target_position = original_position
	
