extends Control
class_name CellColor

# 节点引用
@onready var color_rect: ColorRect = $ColorRectFrame/ColorRectWhite/ColorRect
@onready var color_rect_red: ColorRect = $ColorRectFrame/ColorRectRed
@onready var cell_cross_sprite: Sprite2D = $CellCrossSprite
@onready var cell_cross_finished_sprite: Sprite2D = $CellCrossFinishedSprite
@onready var cell_error_sprite: Sprite2D = $CellErrorSprite
@onready var hover_rect: ColorRect = $HoverRect
@onready var hover_frame_sprite: Sprite2D = $HoverFrameSprite
# 信号定义
signal cell_hover_updated(x: int, y: int, is_hover: bool)
# 内部变量
var cell_x: int = 0
var cell_y: int = 0
var is_finished: bool = false
var finished_color = Color("#fbf6e1")
var _current_tween: Tween

func _on_cell_mouse_entered():
	hover_frame_sprite.show()
	cell_hover_updated.emit(cell_x,cell_y,true)
	
func _on_cell_mouse_exited():
	hover_frame_sprite.hide()
	cell_hover_updated.emit(cell_x,cell_y,false)
	
# 初始化格子
func setup(x: int, y: int, color: Color):
	cell_x = x
	cell_y = y
	finished_color = color
	update_appearance(NonogramManager.CellState.EMPTY)

# 更新外观
func update_appearance(state: int):
	match state:
		NonogramManager.CellState.FILLED:
			cell_cross_sprite.hide()
			color_rect.color =Color("#bc6d4d")
			color_rect.scale = Vector2.ZERO
			if _current_tween:
				_current_tween.kill()
			_current_tween = create_tween()
			_current_tween.tween_property(color_rect, "scale", Vector2.ONE, 0.1)
		NonogramManager.CellState.CROSSED:
			cell_cross_sprite.show()
			cell_cross_sprite.scale = Vector2.ZERO
			if _current_tween:
				_current_tween.kill()
			_current_tween = create_tween()
			_current_tween.tween_property(cell_cross_sprite, "scale", Vector2.ONE, 0.1)
		_:
			cell_cross_sprite.hide()
			color_rect.color = Color("#fbf6e1")
			
func finish(is_error: bool = false):
	is_finished = true
	if cell_cross_sprite.visible:
		cell_cross_sprite.hide()
		cell_cross_finished_sprite.show()
	if is_error:
		cell_cross_sprite.hide()
		cell_cross_finished_sprite.show()
		cell_error_sprite.show()
	
func update_hover(is_hover: bool):
	if is_hover:
		hover_rect.show()
	else:
		hover_rect.hide()

func life_change():
	var tween = create_tween()
	tween.tween_property(color_rect_red, "modulate:a", 0.5, 0.1)
	tween.tween_property(color_rect_red, "modulate:a", 0, 0.1)
