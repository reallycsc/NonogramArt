extends Node2D
class_name ColHint

# 节点引用
@onready var colHint_hover: Panel = $ColHintHover
@onready var colHint_bg_odd: Panel = $ColHintBgOdd
@onready var colHint_bg_even: Panel = $ColHintBgEven
@onready var colHint_bg_finish: Panel = $ColHintBgFinish
@onready var colHint_labels: VBoxContainer = $ColHintLabels
@onready var error_icon: Sprite2D = $ErrorIconBg

var rect_array:Array[ColorRect] = []
var label_array:Array[Label] = []
var line_array:Array[Line2D] = []

# 初始化列提示
func setup(hintText: Array, col_id: int) -> int:
	# 设置单双号不同的背景颜色
	if col_id % 2 == 0:
		colHint_bg_even.show()
		colHint_bg_odd.hide()
	else:
		colHint_bg_even.hide()
		colHint_bg_odd.show()
	# 添加提示数字
	var min_size = colHint_labels.size.x
	var minimum_size = Vector2(min_size, min_size)
	for hint_str in hintText:
		var hint_str_parts = hint_str.split(":")
		var color_rect = ColorRect.new()
		colHint_labels.add_child(color_rect)
		rect_array.append(color_rect)
		color_rect.custom_minimum_size = minimum_size
		color_rect.color = NonogramManager.get_color_by_id_for_hint(hint_str_parts[0])
		var label = Label.new()
		color_rect.add_child(label)
		label_array.append(label)
		label.text = hint_str_parts[1]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = minimum_size
		label.label_settings = LabelSettings.new()
		label.label_settings.font_color = Color("#462203")
		label.label_settings.font_size = 18
		label.label_settings.outline_color = Color.WHITE
		label.label_settings.outline_size = 8
		label.label_settings.shadow_color = Color.GRAY
		label.label_settings.shadow_offset = Vector2.ZERO
		label.label_settings.shadow_size = 0
		var line = Line2D.new()
		label.add_child(line)
		line_array.append(line)
		line.add_point(Vector2(0,minimum_size.y))
		line.add_point(Vector2(minimum_size.x,0))
		line.width = 3
		line.hide()
		line.default_color = Color("505050b4")
	# 返回提示宽度
	return max(colHint_bg_odd.size.y, min_size * hintText.size())+24

func update_height(height: int):
	colHint_hover.size.y = height
	colHint_bg_even.size.y = height
	colHint_bg_odd.size.y = height
	colHint_bg_finish.size.y = height
	colHint_labels.size.y = height-8
	
func finish():
	for rect in rect_array:
		rect.color.a = 0
	for label in label_array:
		label.label_settings.font_color = Color.DIM_GRAY
		label.label_settings.outline_color = Color.WHITE
		label.label_settings.outline_size = 6
		label.label_settings.shadow_offset = Vector2.ZERO
		label.label_settings.shadow_size = 0
	for line in line_array:
		line.show()
	colHint_bg_finish.show()

func update_hover(is_hover: bool):
	if is_hover:
		colHint_hover.show()
	else:
		colHint_hover.hide()

func update_error(is_error: bool):
	if is_error:
		for label in label_array:
			label.label_settings.font_color = Color.RED
		error_icon.show()
	else:
		for label in label_array:
			label.label_settings.font_color = Color("#462203")
		error_icon.hide()

func update_only_one_pattern():
	for label in label_array:
		label.label_settings.font_color = Color.ORANGE
		label.label_settings.shadow_size = 12
	
func update_deducible(is_deducible: bool):
	if is_deducible:
		for label in label_array:
			label.label_settings.font_color = Color("#5988FF")
			label.label_settings.shadow_size = 12
	else:
		for label in label_array:
			label.label_settings.font_color = Color("#462203")
			label.label_settings.shadow_size = 0
