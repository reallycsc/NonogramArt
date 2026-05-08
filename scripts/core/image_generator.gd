extends Node

func _ready() -> void:
	_ensure_illustrations()
	_ensure_icons()


func _ensure_illustrations() -> void:
	_ensure_pangu_illustration()
	_ensure_nuwa_illustration()
	_ensure_houyi_illustration()
	_ensure_dayu_illustration()
	_ensure_taigong_illustration()
	_ensure_fenghuo_illustration()
	_ensure_wanbi_illustration()
	_ensure_goujian_illustration()
	_ensure_jingke_illustration()
	_ensure_qinshi_illustration()
	_ensure_zhangqian_illustration()
	_ensure_zhaojun_illustration()
	_ensure_caochuan_illustration()
	_ensure_taoyuan_illustration()
	_ensure_wenji_illustration()
	_ensure_xuanzang_illustration()
	_ensure_libai_illustration()
	_ensure_wencheng_illustration()
	_ensure_yuefei_illustration()
	_ensure_huozi_illustration()
	_ensure_marco_illustration()
	_ensure_zhenghe_illustration()
	_ensure_kangqian_illustration()
	_ensure_linzexu_illustration()
	_ensure_xinhai_illustration()
	_ensure_wusi_illustration()
	_ensure_changzheng_illustration()
	_ensure_liangdan_illustration()
	_ensure_gaige_illustration()
	_ensure_hangtian_illustration()


func _draw_circle_on_image(img: Image, cx: int, cy: int, radius: int, color: Color) -> void:
	for y in range(max(0, cy - radius), min(img.get_height(), cy + radius + 1)):
		for x in range(max(0, cx - radius), min(img.get_width(), cx + radius + 1)):
			var dx = x - cx
			var dy = y - cy
			if dx * dx + dy * dy <= radius * radius:
				img.set_pixel(x, y, color)


func _draw_line_on_image(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color, thickness: int = 1) -> void:
	var dx = abs(x1 - x0)
	var dy = abs(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx - dy
	var half_t = thickness / 2
	while true:
		for ty in range(-half_t, half_t + 1):
			for tx in range(-half_t, half_t + 1):
				var px = x0 + tx
				var py = y0 + ty
				if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
					img.set_pixel(px, py, color)
		if x0 == x1 and y0 == y1:
			break
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy


func _draw_rect_on_image(img: Image, rx: int, ry: int, rw: int, rh: int, color: Color) -> void:
	img.fill_rect(Rect2i(rx, ry, rw, rh), color)


func _draw_polygon_on_image(img: Image, points: PackedVector2Array, color: Color) -> void:
	if points.size() < 3:
		return
	var min_x = points[0].x
	var max_x = points[0].x
	var min_y = points[0].y
	var max_y = points[0].y
	for p in points:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)
	for y in range(int(min_y), int(max_y) + 1):
		if y < 0 or y >= img.get_height():
			continue
		var intersections: Array = []
		var n = points.size()
		for i in range(n):
			var j = (i + 1) % n
			var yi = points[i].y
			var yj = points[j].y
			if (yi <= y and yj > y) or (yj <= y and yi > y):
				var t = (y - yi) / (yj - yi)
				intersections.append(points[i].x + t * (points[j].x - points[i].x))
		intersections.sort()
		for k in range(0, intersections.size() - 1, 2):
			var x_start = max(0, int(intersections[k]))
			var x_end = min(img.get_width() - 1, int(intersections[k + 1]))
			for x in range(x_start, x_end + 1):
				img.set_pixel(x, y, color)


func _draw_arc_on_image(img: Image, cx: int, cy: int, radius: int, start_angle: float, end_angle: float, color: Color, thickness: int = 2) -> void:
	var steps = max(32, radius * 4)
	var angle_step = (end_angle - start_angle) / steps
	for i in range(steps):
		var a1 = start_angle + i * angle_step
		var a2 = start_angle + (i + 1) * angle_step
		var x1 = int(cx + cos(a1) * radius)
		var y1 = int(cy + sin(a1) * radius)
		var x2 = int(cx + cos(a2) * radius)
		var y2 = int(cy + sin(a2) * radius)
		_draw_line_on_image(img, x1, y1, x2, y2, color, thickness)


func _draw_title_on_image(img: Image, text: String, pos: Vector2i, color: Color) -> void:
	var font = ThemeDB.fallback_font
	for i in range(text.length()):
		var char_pos = Vector2i(pos.x + i * 45, pos.y)
		var char_img = Image.create(45, 40, false, Image.FORMAT_RGBA8)
		char_img.fill(Color(0, 0, 0, 0))
		var char_tex = ImageTexture.create_from_image(char_img)
		var rid = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(rid, RenderingServer.CANVAS_ITEM_NODE_GROUP_ROOT)
		RenderingServer.canvas_item_add_texture(rid, char_tex)
		font.draw_char(rid, Vector2(0, 32), text.unicode_at(i), 32, color)
		RenderingServer.free_rid(rid)


func _ensure_pangu_illustration() -> void:
	var path = "res://assets/images/illustrations/mythology/pangu.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var red = Color(0.76, 0.23, 0.13, 0.9)
	var green = Color(0.18, 0.36, 0.18, 0.6)

	_draw_rect_on_image(img, 0, 0, 640, 200, Color(0.75, 0.85, 0.95, 0.4))
	_draw_rect_on_image(img, 0, 340, 640, 140, Color(0.6, 0.5, 0.35, 0.3))

	_draw_polygon_on_image(img, PackedVector2Array([Vector2(80, 340), Vector2(180, 160), Vector2(280, 340)]), green)
	_draw_polygon_on_image(img, PackedVector2Array([Vector2(300, 340), Vector2(440, 120), Vector2(580, 340)]), green)

	_draw_circle_on_image(img, 520, 80, 35, red)
	for i in range(8):
		var angle = i * PI / 4
		var sx = int(520 + cos(angle) * 40)
		var sy = int(80 + sin(angle) * 40)
		var ex = int(520 + cos(angle) * 55)
		var ey = int(80 + sin(angle) * 55)
		_draw_line_on_image(img, sx, sy, ex, ey, red, 2)

	_draw_rect_on_image(img, 200, 100, 8, 100, ink)
	_draw_polygon_on_image(img, PackedVector2Array([Vector2(170, 100), Vector2(208, 80), Vector2(208, 120)]), ink)

	_draw_circle_on_image(img, 320, 200, 18, ink)
	_draw_rect_on_image(img, 310, 218, 20, 50, ink)
	_draw_line_on_image(img, 310, 235, 285, 215, ink, 4)
	_draw_line_on_image(img, 330, 235, 355, 215, ink, 4)
	_draw_line_on_image(img, 314, 268, 300, 300, ink, 4)
	_draw_line_on_image(img, 326, 268, 340, 300, ink, 4)

	img.save_png(path)


func _ensure_nuwa_illustration() -> void:
	var path = "res://assets/images/illustrations/mythology/nuwa.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var red = Color(0.76, 0.23, 0.13, 0.9)
	var green = Color(0.18, 0.36, 0.18, 0.6)

	_draw_rect_on_image(img, 0, 0, 640, 200, Color(0.75, 0.85, 0.95, 0.4))
	_draw_rect_on_image(img, 0, 340, 640, 140, Color(0.6, 0.5, 0.35, 0.3))

	var colors_arr = [red, Color(0.2, 0.6, 0.8), Color(0.9, 0.8, 0.2), Color(1, 1, 1), ink]
	for i in range(5):
		_draw_circle_on_image(img, 160 + i * 80, 160, 20, colors_arr[i])

	_draw_circle_on_image(img, 320, 260, 25, green)
	_draw_polygon_on_image(img, PackedVector2Array([
		Vector2(295, 260), Vector2(320, 230), Vector2(345, 260),
		Vector2(345, 290), Vector2(320, 310), Vector2(295, 290)
	]), green)
	_draw_rect_on_image(img, 310, 310, 8, 30, ink)
	_draw_rect_on_image(img, 322, 310, 8, 30, ink)
	_draw_rect_on_image(img, 298, 310, 8, 30, ink)
	_draw_rect_on_image(img, 334, 310, 8, 30, ink)

	_draw_circle_on_image(img, 480, 240, 15, ink)
	_draw_rect_on_image(img, 472, 255, 16, 40, ink)
	_draw_line_on_image(img, 472, 270, 455, 255, ink, 3)
	_draw_line_on_image(img, 488, 270, 505, 255, ink, 3)
	_draw_line_on_image(img, 476, 295, 465, 320, ink, 3)
	_draw_line_on_image(img, 484, 295, 495, 320, ink, 3)

	img.save_png(path)


func _ensure_houyi_illustration() -> void:
	var path = "res://assets/images/illustrations/mythology/houyi.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var gold = Color(0.85, 0.65, 0.1, 0.9)

	_draw_rect_on_image(img, 0, 0, 640, 300, Color(0.95, 0.85, 0.6, 0.5))
	_draw_rect_on_image(img, 0, 340, 640, 140, Color(0.6, 0.5, 0.35, 0.3))

	for i in range(3):
		var cx = 150 + i * 170
		var cy = 80
		_draw_circle_on_image(img, cx, cy, 30, gold)
		for j in range(8):
			var angle = j * PI / 4
			var sx = int(cx + cos(angle) * 33)
			var sy = int(cy + sin(angle) * 33)
			var ex = int(cx + cos(angle) * 45)
			var ey = int(cy + sin(angle) * 45)
			_draw_line_on_image(img, sx, sy, ex, ey, gold, 2)

	_draw_arc_on_image(img, 480, 200, 80, -PI * 0.7, PI * 0.7, ink, 4)
	_draw_line_on_image(img, 480, 120, 480, 280, ink, 2)

	_draw_circle_on_image(img, 400, 260, 15, ink)
	_draw_rect_on_image(img, 392, 275, 16, 40, ink)
	_draw_line_on_image(img, 392, 290, 375, 275, ink, 3)
	_draw_line_on_image(img, 408, 290, 425, 275, ink, 3)
	_draw_line_on_image(img, 396, 315, 385, 340, ink, 3)
	_draw_line_on_image(img, 404, 315, 415, 340, ink, 3)

	img.save_png(path)


func _ensure_qinshi_illustration() -> void:
	var path = "res://assets/images/illustrations/qin_han/qinshi.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var green = Color(0.2, 0.5, 0.2, 0.8)

	_draw_rect_on_image(img, 0, 0, 640, 200, Color(0.7, 0.8, 0.9, 0.4))
	_draw_rect_on_image(img, 0, 340, 640, 140, Color(0.6, 0.5, 0.35, 0.3))

	for i in range(4):
		var bx = 80 + i * 140
		_draw_rect_on_image(img, bx, 200, 30, 140, green)
		_draw_rect_on_image(img, bx - 10, 190, 50, 20, green)

	_draw_rect_on_image(img, 60, 260, 520, 15, green)

	_draw_circle_on_image(img, 320, 200, 20, ink)
	_draw_rect_on_image(img, 310, 220, 20, 50, ink)
	_draw_line_on_image(img, 310, 240, 290, 225, ink, 3)
	_draw_line_on_image(img, 330, 240, 350, 225, ink, 3)
	_draw_line_on_image(img, 314, 270, 300, 300, ink, 3)
	_draw_line_on_image(img, 326, 270, 340, 300, ink, 3)

	_draw_rect_on_image(img, 350, 150, 6, 80, ink)
	_draw_polygon_on_image(img, PackedVector2Array([Vector2(330, 150), Vector2(356, 130), Vector2(356, 170)]), ink)

	img.save_png(path)


func _ensure_zhangqian_illustration() -> void:
	var path = "res://assets/images/illustrations/qin_han/zhangqian.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var sand = Color(0.85, 0.75, 0.55, 0.6)
	var gold = Color(0.85, 0.65, 0.1, 0.7)

	_draw_rect_on_image(img, 0, 0, 640, 300, Color(0.9, 0.8, 0.6, 0.4))
	_draw_rect_on_image(img, 0, 300, 640, 180, sand)

	_draw_polygon_on_image(img, PackedVector2Array([
		Vector2(200, 280), Vector2(220, 220), Vector2(260, 220),
		Vector2(280, 280), Vector2(260, 300), Vector2(220, 300)
	]), sand)

	_draw_polygon_on_image(img, PackedVector2Array([
		Vector2(215, 220), Vector2(230, 180), Vector2(250, 220)
	]), sand)

	_draw_rect_on_image(img, 225, 170, 10, 30, ink)
	_draw_circle_on_image(img, 230, 165, 8, ink)

	_draw_line_on_image(img, 200, 290, 200, 340, ink, 3)
	_draw_line_on_image(img, 280, 290, 280, 340, ink, 3)
	_draw_line_on_image(img, 220, 300, 220, 340, ink, 3)
	_draw_line_on_image(img, 260, 300, 260, 340, ink, 3)

	_draw_circle_on_image(img, 400, 260, 15, ink)
	_draw_rect_on_image(img, 392, 275, 16, 40, ink)
	_draw_line_on_image(img, 392, 290, 380, 275, ink, 3)
	_draw_line_on_image(img, 408, 290, 420, 275, ink, 3)
	_draw_line_on_image(img, 396, 315, 385, 340, ink, 3)
	_draw_line_on_image(img, 404, 315, 415, 340, ink, 3)

	for i in range(3):
		_draw_circle_on_image(img, 450 + i * 50, 260, 15, gold)

	img.save_png(path)


func _ensure_zhaojun_illustration() -> void:
	var path = "res://assets/images/illustrations/qin_han/zhaojun.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var red = Color(0.76, 0.23, 0.13, 0.7)

	_draw_rect_on_image(img, 0, 0, 640, 250, Color(0.7, 0.8, 0.9, 0.4))
	_draw_rect_on_image(img, 0, 350, 640, 130, Color(0.6, 0.5, 0.35, 0.3))

	_draw_circle_on_image(img, 320, 220, 20, ink)
	_draw_rect_on_image(img, 308, 240, 24, 60, red)
	_draw_line_on_image(img, 308, 260, 290, 250, ink, 3)
	_draw_line_on_image(img, 332, 260, 350, 250, ink, 3)
	_draw_line_on_image(img, 312, 300, 300, 340, ink, 3)
	_draw_line_on_image(img, 328, 300, 340, 340, ink, 3)

	_draw_arc_on_image(img, 350, 240, 30, -PI * 0.5, PI * 0.5, ink, 2)
	_draw_line_on_image(img, 350, 210, 350, 270, ink, 2)

	for i in range(3):
		var gx = 100 + i * 200
		var gy = 100 + i * 30
		_draw_arc_on_image(img, gx, gy, 15, 0, PI, ink, 2)
		_draw_line_on_image(img, gx - 15, gy, gx + 15, gy, ink, 2)

	img.save_png(path)


func _ensure_xuanzang_illustration() -> void:
	var path = "res://assets/images/illustrations/sui_tang/xuanzang.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var gold = Color(0.85, 0.65, 0.1, 0.8)
	var orange = Color(0.9, 0.5, 0.1, 0.7)

	_draw_rect_on_image(img, 0, 0, 640, 300, Color(0.9, 0.8, 0.6, 0.4))
	_draw_rect_on_image(img, 0, 350, 640, 130, Color(0.6, 0.5, 0.35, 0.3))

	_draw_polygon_on_image(img, PackedVector2Array([
		Vector2(480, 350), Vector2(500, 200), Vector2(520, 200), Vector2(540, 350)
	]), gold)
	_draw_circle_on_image(img, 510, 195, 10, gold)
	_draw_rect_on_image(img, 490, 200, 40, 10, gold)

	_draw_circle_on_image(img, 300, 240, 18, ink)
	_draw_rect_on_image(img, 288, 258, 24, 60, orange)
	_draw_line_on_image(img, 288, 280, 270, 265, ink, 3)
	_draw_line_on_image(img, 312, 280, 330, 265, ink, 3)
	_draw_line_on_image(img, 292, 318, 280, 350, ink, 3)
	_draw_line_on_image(img, 308, 318, 320, 350, ink, 3)

	_draw_rect_on_image(img, 330, 200, 4, 120, ink)
	_draw_polygon_on_image(img, PackedVector2Array([
		Vector2(320, 200), Vector2(344, 190), Vector2(344, 210)
	]), ink)

	img.save_png(path)


func _ensure_libai_illustration() -> void:
	var path = "res://assets/images/illustrations/sui_tang/libai.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var blue = Color(0.2, 0.3, 0.6, 0.7)
	var green = Color(0.18, 0.36, 0.18, 0.5)
	var gold = Color(0.85, 0.65, 0.1, 0.9)

	_draw_rect_on_image(img, 0, 0, 640, 250, Color(0.15, 0.15, 0.3, 0.3))
	_draw_rect_on_image(img, 0, 350, 640, 130, Color(0.6, 0.5, 0.35, 0.3))

	_draw_circle_on_image(img, 520, 80, 40, gold)
	for i in range(12):
		var angle = i * PI / 6
		var sx = int(520 + cos(angle) * 43)
		var sy = int(80 + sin(angle) * 43)
		var ex = int(520 + cos(angle) * 58)
		var ey = int(80 + sin(angle) * 58)
		_draw_line_on_image(img, sx, sy, ex, ey, gold, 2)

	_draw_polygon_on_image(img, PackedVector2Array([Vector2(50, 350), Vector2(200, 150), Vector2(350, 350)]), green)

	_draw_circle_on_image(img, 300, 260, 18, ink)
	_draw_rect_on_image(img, 288, 278, 24, 50, blue)
	_draw_line_on_image(img, 288, 300, 270, 285, ink, 3)
	_draw_line_on_image(img, 312, 300, 330, 285, ink, 3)
	_draw_line_on_image(img, 292, 328, 280, 350, ink, 3)
	_draw_line_on_image(img, 308, 328, 320, 350, ink, 3)

	_draw_arc_on_image(img, 340, 280, 15, -PI * 0.6, PI * 0.3, ink, 2)

	img.save_png(path)


func _ensure_wencheng_illustration() -> void:
	var path = "res://assets/images/illustrations/sui_tang/wencheng.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var red = Color(0.76, 0.23, 0.13, 0.7)

	_draw_rect_on_image(img, 0, 0, 640, 200, Color(0.7, 0.8, 0.9, 0.4))
	_draw_rect_on_image(img, 0, 350, 640, 130, Color(0.6, 0.5, 0.35, 0.3))

	_draw_rect_on_image(img, 420, 180, 80, 170, red)
	_draw_polygon_on_image(img, PackedVector2Array([
		Vector2(400, 180), Vector2(460, 130), Vector2(520, 180)
	]), red)
	_draw_rect_on_image(img, 445, 250, 30, 100, ink)

	_draw_circle_on_image(img, 250, 230, 20, ink)
	_draw_rect_on_image(img, 238, 250, 24, 60, red)
	_draw_line_on_image(img, 238, 270, 220, 255, ink, 3)
	_draw_line_on_image(img, 262, 270, 280, 255, ink, 3)
	_draw_line_on_image(img, 242, 310, 230, 350, ink, 3)
	_draw_line_on_image(img, 258, 310, 270, 350, ink, 3)

	img.save_png(path)


func _ensure_dayu_illustration() -> void:
	var path = "res://assets/images/illustrations/xia_shang_zhou/dayu.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var blue = Color(0.2, 0.4, 0.7, 0.6)
	var green = Color(0.18, 0.36, 0.18, 0.6)

	_draw_rect_on_image(img, 0, 0, 640, 200, Color(0.7, 0.8, 0.9, 0.4))
	_draw_rect_on_image(img, 0, 300, 640, 180, blue)

	for i in range(5):
		var wx = 50 + i * 130
		_draw_arc_on_image(img, wx, 310, 30, 0, PI, blue, 3)

	_draw_polygon_on_image(img, PackedVector2Array([Vector2(80, 300), Vector2(200, 150), Vector2(320, 300)]), green)

	_draw_circle_on_image(img, 400, 220, 18, ink)
	_draw_rect_on_image(img, 388, 238, 24, 60, ink)
	_draw_line_on_image(img, 388, 260, 370, 245, ink, 3)
	_draw_line_on_image(img, 412, 260, 430, 245, ink, 3)
	_draw_line_on_image(img, 392, 298, 380, 330, ink, 3)
	_draw_line_on_image(img, 408, 298, 420, 330, ink, 3)

	_draw_rect_on_image(img, 440, 180, 6, 80, ink)
	_draw_polygon_on_image(img, PackedVector2Array([Vector2(420, 180), Vector2(446, 160), Vector2(446, 200)]), ink)

	img.save_png(path)


func _ensure_taigong_illustration() -> void:
	var path = "res://assets/images/illustrations/xia_shang_zhou/taigong.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var blue = Color(0.2, 0.4, 0.7, 0.5)
	var green = Color(0.18, 0.36, 0.18, 0.5)

	_draw_rect_on_image(img, 0, 0, 640, 250, Color(0.7, 0.8, 0.9, 0.4))
	_draw_rect_on_image(img, 0, 350, 640, 130, Color(0.6, 0.5, 0.35, 0.3))

	_draw_rect_on_image(img, 0, 280, 640, 70, blue)

	_draw_circle_on_image(img, 300, 240, 20, ink)
	_draw_rect_on_image(img, 288, 260, 24, 50, ink)
	_draw_line_on_image(img, 288, 280, 270, 265, ink, 3)
	_draw_line_on_image(img, 312, 280, 330, 265, ink, 3)
	_draw_line_on_image(img, 292, 310, 280, 340, ink, 3)
	_draw_line_on_image(img, 308, 310, 320, 340, ink, 3)

	_draw_line_on_image(img, 330, 240, 420, 200, ink, 2)
	_draw_line_on_image(img, 420, 200, 420, 260, ink, 2)

	img.save_png(path)


func _ensure_fenghuo_illustration() -> void:
	var path = "res://assets/images/illustrations/xia_shang_zhou/fenghuo.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var red = Color(0.76, 0.23, 0.13, 0.9)
	var orange = Color(0.9, 0.5, 0.1, 0.8)

	_draw_rect_on_image(img, 0, 0, 640, 300, Color(0.15, 0.1, 0.2, 0.4))
	_draw_rect_on_image(img, 0, 350, 640, 130, Color(0.6, 0.5, 0.35, 0.3))

	_draw_rect_on_image(img, 300, 200, 40, 150, ink)
	_draw_polygon_on_image(img, PackedVector2Array([
		Vector2(280, 200), Vector2(320, 140), Vector2(360, 200)
	]), ink)

	_draw_circle_on_image(img, 320, 120, 15, orange)
	_draw_circle_on_image(img, 310, 110, 10, red)
	_draw_circle_on_image(img, 330, 105, 12, orange)
	_draw_circle_on_image(img, 320, 95, 8, red)

	img.save_png(path)


func _ensure_wanbi_illustration() -> void:
	var path = "res://assets/images/illustrations/spring_autumn/wanbi.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var jade = Color(0.5, 0.8, 0.5, 0.8)

	_draw_rect_on_image(img, 0, 0, 640, 200, Color(0.7, 0.8, 0.9, 0.4))
	_draw_rect_on_image(img, 0, 340, 640, 140, Color(0.6, 0.5, 0.35, 0.3))

	_draw_circle_on_image(img, 320, 200, 60, jade)
	_draw_circle_on_image(img, 320, 200, 30, Color(0.96, 0.94, 0.91))

	_draw_circle_on_image(img, 200, 260, 15, ink)
	_draw_rect_on_image(img, 188, 275, 24, 50, ink)
	_draw_line_on_image(img, 188, 295, 170, 280, ink, 3)
	_draw_line_on_image(img, 212, 295, 230, 280, ink, 3)
	_draw_line_on_image(img, 192, 325, 180, 350, ink, 3)
	_draw_line_on_image(img, 208, 325, 220, 350, ink, 3)

	img.save_png(path)


func _ensure_goujian_illustration() -> void:
	var path = "res://assets/images/illustrations/spring_autumn/goujian.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var green = Color(0.18, 0.36, 0.18, 0.5)

	_draw_rect_on_image(img, 0, 0, 640, 200, Color(0.7, 0.8, 0.9, 0.4))
	_draw_rect_on_image(img, 0, 340, 640, 140, Color(0.6, 0.5, 0.35, 0.3))

	_draw_rect_on_image(img, 280, 100, 6, 120, ink)
	_draw_polygon_on_image(img, PackedVector2Array([Vector2(260, 100), Vector2(286, 80), Vector2(286, 120)]), ink)

	_draw_circle_on_image(img, 400, 240, 18, ink)
	_draw_rect_on_image(img, 388, 258, 24, 50, green)
	_draw_line_on_image(img, 388, 278, 370, 263, ink, 3)
	_draw_line_on_image(img, 412, 278, 430, 263, ink, 3)
	_draw_line_on_image(img, 392, 308, 380, 340, ink, 3)
	_draw_line_on_image(img, 408, 308, 420, 340, ink, 3)

	_draw_circle_on_image(img, 180, 200, 8, Color(0.5, 0.3, 0.1, 0.7))

	img.save_png(path)


func _ensure_jingke_illustration() -> void:
	var path = "res://assets/images/illustrations/spring_autumn/jingke.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var blue = Color(0.2, 0.3, 0.5, 0.6)

	_draw_rect_on_image(img, 0, 0, 640, 200, Color(0.7, 0.8, 0.9, 0.4))
	_draw_rect_on_image(img, 0, 340, 640, 140, Color(0.6, 0.5, 0.35, 0.3))

	_draw_rect_on_image(img, 100, 200, 440, 150, Color(0.8, 0.7, 0.5, 0.3))
	_draw_rect_on_image(img, 100, 200, 440, 10, ink)
	_draw_rect_on_image(img, 100, 340, 440, 10, ink)

	_draw_circle_on_image(img, 300, 240, 18, ink)
	_draw_rect_on_image(img, 288, 258, 24, 50, blue)
	_draw_line_on_image(img, 288, 278, 270, 263, ink, 3)
	_draw_line_on_image(img, 312, 278, 340, 250, ink, 3)
	_draw_line_on_image(img, 292, 308, 280, 340, ink, 3)
	_draw_line_on_image(img, 308, 308, 320, 340, ink, 3)

	img.save_png(path)


func _ensure_caochuan_illustration() -> void:
	var path = "res://assets/images/illustrations/three_kingdoms/caochuan.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var blue = Color(0.2, 0.4, 0.7, 0.5)
	var gold = Color(0.85, 0.65, 0.1, 0.9)

	_draw_rect_on_image(img, 0, 0, 640, 200, Color(0.6, 0.7, 0.85, 0.5))
	_draw_rect_on_image(img, 0, 280, 640, 200, blue)

	_draw_rect_on_image(img, 200, 300, 240, 30, Color(0.5, 0.4, 0.2, 0.8))
	_draw_polygon_on_image(img, PackedVector2Array([
		Vector2(180, 300), Vector2(320, 260), Vector2(460, 300)
	]), Color(0.5, 0.4, 0.2, 0.8))

	for i in range(5):
		var ax = 220 + i * 40
		_draw_line_on_image(img, ax, 260, ax, 240, gold, 2)
		_draw_line_on_image(img, ax - 5, 240, ax + 5, 240, gold, 2)

	img.save_png(path)


func _ensure_taoyuan_illustration() -> void:
	var path = "res://assets/images/illustrations/three_kingdoms/taoyuan.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var pink = Color(0.9, 0.5, 0.6, 0.7)
	var green = Color(0.18, 0.36, 0.18, 0.6)

	_draw_rect_on_image(img, 0, 0, 640, 200, Color(0.7, 0.8, 0.9, 0.4))
	_draw_rect_on_image(img, 0, 340, 640, 140, Color(0.6, 0.5, 0.35, 0.3))

	_draw_rect_on_image(img, 280, 200, 80, 140, Color(0.5, 0.3, 0.2, 0.7))
	_draw_circle_on_image(img, 320, 180, 50, green)
	_draw_circle_on_image(img, 260, 200, 15, pink)
	_draw_circle_on_image(img, 380, 200, 15, pink)
	_draw_circle_on_image(img, 320, 160, 12, pink)

	for i in range(3):
		var px = 220 + i * 100
		_draw_circle_on_image(img, px, 280, 15, ink)
		_draw_rect_on_image(img, px - 8, 295, 16, 40, ink)

	img.save_png(path)


func _ensure_wenji_illustration() -> void:
	var path = "res://assets/images/illustrations/three_kingdoms/wenji.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var red = Color(0.76, 0.23, 0.13, 0.7)

	_draw_rect_on_image(img, 0, 0, 640, 200, Color(0.7, 0.8, 0.9, 0.4))
	_draw_rect_on_image(img, 0, 340, 640, 140, Color(0.6, 0.5, 0.35, 0.3))

	_draw_circle_on_image(img, 200, 120, 10, red)
	_draw_polygon_on_image(img, PackedVector2Array([
		Vector2(190, 120), Vector2(200, 90), Vector2(210, 120)
	]), red)
	_draw_rect_on_image(img, 196, 130, 8, 15, ink)

	_draw_circle_on_image(img, 350, 250, 18, ink)
	_draw_rect_on_image(img, 338, 268, 24, 50, ink)
	_draw_line_on_image(img, 338, 288, 320, 273, ink, 3)
	_draw_line_on_image(img, 362, 288, 380, 273, ink, 3)
	_draw_line_on_image(img, 342, 318, 330, 350, ink, 3)
	_draw_line_on_image(img, 358, 318, 370, 350, ink, 3)

	_draw_rect_on_image(img, 380, 200, 4, 100, ink)
	_draw_polygon_on_image(img, PackedVector2Array([
		Vector2(370, 200), Vector2(394, 185), Vector2(394, 215)
	]), ink)

	img.save_png(path)


func _ensure_yuefei_illustration() -> void:
	var path = "res://assets/images/illustrations/song_yuan/yuefei.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var red = Color(0.76, 0.23, 0.13, 0.7)

	_draw_rect_on_image(img, 0, 0, 640, 200, Color(0.7, 0.8, 0.9, 0.4))
	_draw_rect_on_image(img, 0, 340, 640, 140, Color(0.6, 0.5, 0.35, 0.3))

	_draw_circle_on_image(img, 300, 220, 18, ink)
	_draw_rect_on_image(img, 288, 238, 24, 50, red)
	_draw_line_on_image(img, 288, 258, 270, 243, ink, 3)
	_draw_line_on_image(img, 312, 258, 340, 230, ink, 3)
	_draw_line_on_image(img, 292, 288, 280, 320, ink, 3)
	_draw_line_on_image(img, 308, 288, 320, 320, ink, 3)

	_draw_rect_on_image(img, 340, 210, 4, 100, ink)
	_draw_polygon_on_image(img, PackedVector2Array([
		Vector2(330, 210), Vector2(354, 195), Vector2(354, 225)
	]), ink)

	img.save_png(path)


func _ensure_huozi_illustration() -> void:
	var path = "res://assets/images/illustrations/song_yuan/huozi.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var wood = Color(0.6, 0.4, 0.2, 0.7)

	_draw_rect_on_image(img, 0, 0, 640, 200, Color(0.7, 0.8, 0.9, 0.4))
	_draw_rect_on_image(img, 0, 340, 640, 140, Color(0.6, 0.5, 0.35, 0.3))

	for i in range(3):
		for j in range(4):
			var bx = 200 + j * 60
			var by = 180 + i * 50
			_draw_rect_on_image(img, bx, by, 40, 40, wood)
			_draw_rect_on_image(img, bx + 5, by + 5, 30, 30, ink)

	img.save_png(path)


func _ensure_marco_illustration() -> void:
	var path = "res://assets/images/illustrations/song_yuan/marco.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var blue = Color(0.2, 0.4, 0.7, 0.5)
	var sand = Color(0.85, 0.75, 0.55, 0.4)

	_draw_rect_on_image(img, 0, 0, 640, 250, Color(0.7, 0.8, 0.9, 0.4))
	_draw_rect_on_image(img, 0, 300, 640, 180, sand)

	_draw_rect_on_image(img, 200, 280, 240, 30, Color(0.5, 0.3, 0.2, 0.8))
	_draw_polygon_on_image(img, PackedVector2Array([
		Vector2(180, 280), Vector2(320, 230), Vector2(460, 280)
	]), Color(0.5, 0.3, 0.2, 0.8))
	_draw_rect_on_image(img, 310, 180, 10, 60, ink)
	_draw_rect_on_image(img, 280, 170, 80, 20, ink)

	img.save_png(path)


func _ensure_zhenghe_illustration() -> void:
	var path = "res://assets/images/illustrations/ming_qing/zhenghe.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var blue = Color(0.2, 0.4, 0.7, 0.5)
	var red = Color(0.76, 0.23, 0.13, 0.7)

	_draw_rect_on_image(img, 0, 0, 640, 250, Color(0.7, 0.8, 0.9, 0.4))
	_draw_rect_on_image(img, 0, 300, 640, 180, blue)

	_draw_rect_on_image(img, 180, 280, 280, 40, Color(0.5, 0.3, 0.2, 0.8))
	_draw_polygon_on_image(img, PackedVector2Array([
		Vector2(160, 280), Vector2(320, 220), Vector2(480, 280)
	]), Color(0.5, 0.3, 0.2, 0.8))
	_draw_rect_on_image(img, 300, 160, 20, 70, ink)
	_draw_rect_on_image(img, 270, 150, 80, 20, red)
	_draw_rect_on_image(img, 290, 130, 40, 20, red)

	img.save_png(path)


func _ensure_kangqian_illustration() -> void:
	var path = "res://assets/images/illustrations/ming_qing/kangqian.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var gold = Color(0.85, 0.65, 0.1, 0.8)
	var red = Color(0.76, 0.23, 0.13, 0.7)

	_draw_rect_on_image(img, 0, 0, 640, 200, Color(0.7, 0.8, 0.9, 0.4))
	_draw_rect_on_image(img, 0, 340, 640, 140, Color(0.6, 0.5, 0.35, 0.3))

	_draw_rect_on_image(img, 250, 200, 140, 140, red)
	_draw_polygon_on_image(img, PackedVector2Array([
		Vector2(230, 200), Vector2(320, 130), Vector2(410, 200)
	]), red)
	_draw_rect_on_image(img, 290, 250, 60, 90, gold)

	_draw_circle_on_image(img, 320, 160, 10, gold)

	img.save_png(path)


func _ensure_linzexu_illustration() -> void:
	var path = "res://assets/images/illustrations/ming_qing/linzexu.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var orange = Color(0.9, 0.5, 0.1, 0.8)
	var red = Color(0.76, 0.23, 0.13, 0.9)

	_draw_rect_on_image(img, 0, 0, 640, 200, Color(0.7, 0.8, 0.9, 0.4))
	_draw_rect_on_image(img, 0, 340, 640, 140, Color(0.6, 0.5, 0.35, 0.3))

	_draw_circle_on_image(img, 300, 200, 20, orange)
	_draw_circle_on_image(img, 290, 190, 12, red)
	_draw_circle_on_image(img, 310, 185, 10, orange)

	_draw_circle_on_image(img, 450, 250, 18, ink)
	_draw_rect_on_image(img, 438, 268, 24, 50, ink)
	_draw_line_on_image(img, 438, 288, 420, 273, ink, 3)
	_draw_line_on_image(img, 462, 288, 480, 273, ink, 3)
	_draw_line_on_image(img, 442, 318, 430, 350, ink, 3)
	_draw_line_on_image(img, 458, 318, 470, 350, ink, 3)

	img.save_png(path)


func _ensure_xinhai_illustration() -> void:
	var path = "res://assets/images/illustrations/modern/xinhai.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var red = Color(0.76, 0.23, 0.13, 0.9)

	_draw_rect_on_image(img, 0, 0, 640, 300, Color(0.7, 0.8, 0.9, 0.4))
	_draw_rect_on_image(img, 0, 340, 640, 140, Color(0.6, 0.5, 0.35, 0.3))

	_draw_rect_on_image(img, 200, 150, 6, 150, ink)
	_draw_polygon_on_image(img, PackedVector2Array([
		Vector2(206, 150), Vector2(206, 200), Vector2(350, 175)
	]), red)

	_draw_circle_on_image(img, 400, 260, 15, ink)
	_draw_rect_on_image(img, 388, 275, 24, 40, ink)
	_draw_line_on_image(img, 388, 290, 370, 275, ink, 3)
	_draw_line_on_image(img, 412, 290, 430, 275, ink, 3)
	_draw_line_on_image(img, 392, 315, 380, 340, ink, 3)
	_draw_line_on_image(img, 408, 315, 420, 340, ink, 3)

	img.save_png(path)


func _ensure_wusi_illustration() -> void:
	var path = "res://assets/images/illustrations/modern/wusi.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var red = Color(0.76, 0.23, 0.13, 0.9)
	var orange = Color(0.9, 0.5, 0.1, 0.8)

	_draw_rect_on_image(img, 0, 0, 640, 200, Color(0.7, 0.8, 0.9, 0.4))
	_draw_rect_on_image(img, 0, 340, 640, 140, Color(0.6, 0.5, 0.35, 0.3))

	_draw_rect_on_image(img, 290, 150, 6, 120, ink)
	_draw_circle_on_image(img, 293, 130, 15, orange)
	_draw_circle_on_image(img, 288, 118, 10, red)

	_draw_rect_on_image(img, 380, 180, 80, 100, Color(0.9, 0.85, 0.7, 0.8))
	_draw_rect_on_image(img, 380, 180, 80, 10, ink)

	img.save_png(path)


func _ensure_changzheng_illustration() -> void:
	var path = "res://assets/images/illustrations/modern/changzheng.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var white = Color(0.9, 0.9, 0.95, 0.8)
	var red = Color(0.76, 0.23, 0.13, 0.9)

	_draw_rect_on_image(img, 0, 0, 640, 200, Color(0.6, 0.7, 0.85, 0.4))
	_draw_rect_on_image(img, 0, 340, 640, 140, Color(0.6, 0.5, 0.35, 0.3))

	_draw_polygon_on_image(img, PackedVector2Array([
		Vector2(100, 340), Vector2(250, 100), Vector2(400, 340)
	]), white)
	_draw_polygon_on_image(img, PackedVector2Array([
		Vector2(350, 340), Vector2(500, 150), Vector2(600, 340)
	]), white)

	_draw_circle_on_image(img, 520, 60, 15, red)
	for i in range(5):
		var angle = i * 2 * PI / 5 - PI / 2
		var sx = int(520 + cos(angle) * 18)
		var sy = int(60 + sin(angle) * 18)

	img.save_png(path)


func _ensure_liangdan_illustration() -> void:
	var path = "res://assets/images/illustrations/contemporary/liangdan.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var red = Color(0.76, 0.23, 0.13, 0.9)
	var blue = Color(0.2, 0.3, 0.6, 0.7)

	_draw_rect_on_image(img, 0, 0, 640, 300, Color(0.7, 0.8, 0.9, 0.4))
	_draw_rect_on_image(img, 0, 340, 640, 140, Color(0.6, 0.5, 0.35, 0.3))

	_draw_polygon_on_image(img, PackedVector2Array([
		Vector2(300, 80), Vector2(290, 200), Vector2(310, 200)
	]), red)
	_draw_rect_on_image(img, 285, 200, 30, 40, red)
	_draw_polygon_on_image(img, PackedVector2Array([
		Vector2(280, 240), Vector2(320, 240), Vector2(330, 260), Vector2(270, 260)
	]), red)
	_draw_rect_on_image(img, 275, 260, 50, 20, red)

	_draw_circle_on_image(img, 500, 80, 15, red)

	img.save_png(path)


func _ensure_gaige_illustration() -> void:
	var path = "res://assets/images/illustrations/contemporary/gaige.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink = Color(0.15, 0.15, 0.15, 0.9)
	var blue = Color(0.3, 0.5, 0.7, 0.7)

	_draw_rect_on_image(img, 0, 0, 640, 200, Color(0.7, 0.8, 0.9, 0.4))
	_draw_rect_on_image(img, 0, 340, 640, 140, Color(0.6, 0.5, 0.35, 0.3))

	_draw_rect_on_image(img, 150, 120, 60, 220, blue)
	_draw_rect_on_image(img, 160, 130, 40, 30, Color(0.7, 0.85, 0.95, 0.8))
	_draw_rect_on_image(img, 160, 170, 40, 30, Color(0.7, 0.85, 0.95, 0.8))
	_draw_rect_on_image(img, 160, 210, 40, 30, Color(0.7, 0.85, 0.95, 0.8))

	_draw_rect_on_image(img, 350, 80, 80, 260, blue)
	_draw_rect_on_image(img, 360, 90, 60, 30, Color(0.7, 0.85, 0.95, 0.8))
	_draw_rect_on_image(img, 360, 130, 60, 30, Color(0.7, 0.85, 0.95, 0.8))
	_draw_rect_on_image(img, 360, 170, 60, 30, Color(0.7, 0.85, 0.95, 0.8))
	_draw_rect_on_image(img, 360, 210, 60, 30, Color(0.7, 0.85, 0.95, 0.8))

	img.save_png(path)


func _ensure_hangtian_illustration() -> void:
	var path = "res://assets/images/illustrations/contemporary/hangtian.png"
	if ResourceLoader.exists(path):
		return
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.05, 0.05, 0.15, 1.0))

	var white = Color(1, 1, 1, 0.8)
	var gold = Color(0.85, 0.65, 0.1, 0.9)
	var blue = Color(0.2, 0.4, 0.8, 0.7)

	for i in range(50):
		var sx = int(i * 13 % 640)
		var sy = int(i * 7 % 300)
		img.set_pixel(sx, sy, white)

	_draw_circle_on_image(img, 500, 100, 40, Color(0.7, 0.7, 0.7, 0.8))
	_draw_circle_on_image(img, 490, 90, 8, Color(0.5, 0.5, 0.5, 0.6))
	_draw_circle_on_image(img, 510, 105, 5, Color(0.5, 0.5, 0.5, 0.6))

	_draw_rect_on_image(img, 280, 200, 80, 60, blue)
	_draw_polygon_on_image(img, PackedVector2Array([
		Vector2(270, 200), Vector2(320, 170), Vector2(370, 200)
	]), blue)
	_draw_rect_on_image(img, 295, 260, 50, 20, gold)
	_draw_rect_on_image(img, 305, 280, 30, 30, gold)

	img.save_png(path)


func _ensure_icons() -> void:
	var eras = ["mythology", "xia_shang_zhou", "spring_autumn", "qin_han", "three_kingdoms", "sui_tang", "song_yuan", "ming_qing", "modern", "contemporary"]
	var colors = [
		Color(0.76, 0.23, 0.13),
		Color(0.6, 0.4, 0.2),
		Color(0.5, 0.5, 0.2),
		Color(0.2, 0.5, 0.2),
		Color(0.2, 0.4, 0.6),
		Color(0.6, 0.2, 0.6),
		Color(0.4, 0.6, 0.4),
		Color(0.7, 0.5, 0.3),
		Color(0.3, 0.3, 0.6),
		Color(0.8, 0.2, 0.2),
	]
	for i in range(eras.size()):
		var path = "res://assets/images/icons/era_" + eras[i] + ".png"
		if ResourceLoader.exists(path):
			continue
		var icon = Image.create(64, 64, false, Image.FORMAT_RGBA8)
		icon.fill(Color(0.96, 0.94, 0.91))
		_draw_circle_on_image(icon, 32, 32, 24, colors[i])
		icon.save_png(path)
