@tool
extends EditorScript

func _run() -> void:
	_generate_pangu_illustration()
	_generate_era_icons()
	print("占位图片生成完成！")


func _generate_pangu_illustration() -> void:
	var img = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))

	var ink_color = Color(0.15, 0.15, 0.15, 0.9)
	var red_color = Color(0.76, 0.23, 0.13, 0.9)
	var blue_color = Color(0.18, 0.36, 0.54, 0.7)
	var green_color = Color(0.18, 0.36, 0.18, 0.6)

	img.draw_rect(Rect2i(0, 0, 640, 200), Color(0.75, 0.85, 0.95, 0.4))

	img.draw_rect(Rect2i(0, 340, 640, 140), Color(0.6, 0.5, 0.35, 0.3))

	_draw_mountain(img, 80, 340, 200, 180, green_color)
	_draw_mountain(img, 300, 340, 280, 220, green_color)
	_draw_mountain(img, 500, 340, 180, 150, green_color)

	_draw_sun(img, 520, 80, 40, red_color)

	_draw_axe(img, 200, 120, ink_color)

	_draw_figure(img, 320, 180, ink_color)

	_draw_text_on_image(img, "盘古开天", Vector2i(240, 420), 36, ink_color)

	var dir = DirAccess.open("res://assets/images/illustrations/mythology")
	if not dir:
		DirAccess.make_dir_recursive_absolute("res://assets/images/illustrations/mythology")
	var err = img.save_png("res://assets/images/illustrations/mythology/pangu.png")
	if err == OK:
		print("盘古开天配图已生成")
	else:
		print("盘古开天配图生成失败: ", err)


func _generate_era_icons() -> void:
	var dir = DirAccess.open("res://assets/images/icons")
	if not dir:
		DirAccess.make_dir_recursive_absolute("res://assets/images/icons")
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
		var icon = Image.create(64, 64, false, Image.FORMAT_RGBA8)
		icon.fill(Color(0.96, 0.94, 0.91))
		icon.draw_circle(Vector2i(32, 32), 24, colors[i])
		icon.save_png("res://assets/images/icons/era_" + eras[i] + ".png")
	print("时代图标已生成")


func _draw_mountain(img: Image, x: int, base_y: int, width: int, height: int, color: Color) -> void:
	var points = PackedVector2Array([
		Vector2(x, base_y),
		Vector2(x + width / 2, base_y - height),
		Vector2(x + width, base_y),
	])
	var colors = PackedColorArray([color, color, color])
	img.draw_polygon(points, colors)


func _draw_sun(img: Image, cx: int, cy: int, radius: int, color: Color) -> void:
	img.draw_circle(Vector2i(cx, cy), radius, color)
	for i in range(8):
		var angle = i * PI / 4
		var start = Vector2(cx + cos(angle) * (radius + 5), cy + sin(angle) * (radius + 5))
		var end = Vector2(cx + cos(angle) * (radius + 20), cy + sin(angle) * (radius + 20))
		img.draw_line(start, end, color, 2)


func _draw_axe(img: Image, x: int, y: int, color: Color) -> void:
	img.draw_rect(Rect2i(x, y, 8, 80), color)
	var blade = PackedVector2Array([
		Vector2(x - 30, y),
		Vector2(x + 4, y - 20),
		Vector2(x + 4, y + 20),
	])
	img.draw_polygon(blade, PackedColorArray([color, color, color]))


func _draw_figure(img: Image, x: int, y: int, color: Color) -> void:
	img.draw_circle(Vector2i(x, y), 15, color)
	img.draw_rect(Rect2i(x - 8, y + 15, 16, 40), color)
	img.draw_line(Vector2(x - 8, y + 25), Vector2(x - 25, y + 10), color, 3)
	img.draw_line(Vector2(x + 8, y + 25), Vector2(x + 25, y + 10), color, 3)
	img.draw_line(Vector2(x - 5, y + 55), Vector2(x - 15, y + 80), color, 3)
	img.draw_line(Vector2(x + 5, y + 55), Vector2(x + 15, y + 80), color, 3)


func _draw_text_on_image(img: Image, text: String, pos: Vector2i, font_size: int, color: Color) -> void:
	var font = ThemeDB.fallback_font()
	for i in range(text.length()):
		img.draw_char(font, Vector2i(pos.x + i * font_size, pos.y), text[i], font_size, color)
