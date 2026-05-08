@tool
extends EditorScript

const NonogramSolverScript = preload("res://scripts/nonogram/nonogram_solver.gd")
const GeneratePuzzleScript = preload("res://tools/puzzle_generator/generate_puzzle.gd")

func _run() -> void:
	print("=== 配图物体提取与关卡生成工具 ===")
	print("用法：在 _run() 中调用以下方法：")
	print("  extract_region_and_generate(image_path, region, puzzle_config)")
	print("  batch_extract_and_generate(stories_config)")
	print("  verify_all_pipelines()")


func extract_region_and_generate(image_path: String, region: Rect2i, puzzle_config: Dictionary) -> Dictionary:
	var img = Image.load_from_file(image_path)
	if not img:
		push_error("无法加载图片: " + image_path)
		return {}

	if region.position.x < 0 or region.position.y < 0:
		push_error("区域位置无效")
		return {}
	if region.end.x > img.get_width() or region.end.y > img.get_height():
		push_error("区域超出图片范围")
		return {}

	var region_img = img.get_region(region)
	if not region_img:
		push_error("无法提取区域")
		return {}

	var target_size = puzzle_config.get("target_size", 10)
	var binary = _threshold_to_binary(region_img, target_size, target_size)
	if binary.size() == 0:
		push_error("二值化失败")
		return {}

	var generator = GeneratePuzzleScript.new()
	var puzzle_data = generator.generate_from_solution(
		puzzle_config.get("id", ""),
		puzzle_config.get("name", ""),
		puzzle_config.get("story_id", ""),
		binary,
		puzzle_config.get("difficulty", "medium"),
		{"x": region.position.x, "y": region.position.y, "w": region.size.x, "h": region.size.y}
	)

	return puzzle_data


func batch_extract_and_generate(stories_config: Array) -> void:
	print("\n=== 批量提取物体并生成关卡 ===")
	var generator = GeneratePuzzleScript.new()
	var total = stories_config.size()
	var success = 0

	for i in range(total):
		var config = stories_config[i]
		print("\n[%d/%d] 处理: %s" % [i + 1, total, config.get("id", "")])

		var image_path = config.get("image_path", "")
		var regions = config.get("regions", [])
		var era_id = config.get("era_id", "")
		var story_id = config.get("story_id", "")
		var output_dir = config.get("output_dir", "res://data/puzzles/" + era_id)

		for region_config in regions:
			var region = Rect2i(
				region_config.get("x", 0),
				region_config.get("y", 0),
				region_config.get("w", 64),
				region_config.get("h", 64)
			)
			var puzzle_id = region_config.get("id", "")
			var puzzle_name = region_config.get("name", "")
			var target_size = region_config.get("target_size", 10)
			var difficulty = region_config.get("difficulty", "medium")

			var puzzle_data = extract_region_and_generate(image_path, region, {
				"id": puzzle_id,
				"name": puzzle_name,
				"story_id": story_id,
				"target_size": target_size,
				"difficulty": difficulty,
			})

			if puzzle_data.size() > 0:
				generator.save_puzzle(puzzle_data, output_dir)
				success += 1

	print("\n=== 批量处理完成 ===")
	print("成功: %d / %d" % [success, total])


func _threshold_to_binary(img: Image, target_rows: int, target_cols: int, threshold: float = 0.5) -> Array:
	var resized = img.duplicate()
	resized.resize(target_cols, target_rows, Image.INTERPOLATE_NEAREST)

	var result: Array = []
	for y in range(target_rows):
		var row: Array = []
		for x in range(target_cols):
			var pixel = resized.get_pixel(x, y)
			var brightness = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114
			var alpha = pixel.a
			if alpha < 0.3:
				row.append(0)
			else:
				row.append(1 if brightness < threshold else 0)
		result.append(row)

	var has_filled = false
	for row in result:
		for cell in row:
			if cell == 1:
				has_filled = true
				break
		if has_filled:
			break

	if not has_filled:
		for y in range(target_rows):
			for x in range(target_cols):
				var pixel = resized.get_pixel(x, y)
				var saturation = max(pixel.r, max(pixel.g, pixel.b)) - min(pixel.r, min(pixel.g, pixel.b))
				if saturation > 0.2:
					result[y][x] = 1
				else:
					result[y][x] = 0

	return result


func verify_all_pipelines() -> void:
	print("\n=== 验证所有内容生产流水线 ===")

	var eras = ["mythology", "xia_shang_zhou", "spring_autumn", "qin_han",
				"three_kingdoms", "sui_tang", "song_yuan", "ming_qing",
				"modern", "contemporary"]

	var total_puzzles = 0
	var solvable_puzzles = 0
	var unsolvable_puzzles = 0

	for era_id in eras:
		var puzzle_dir = "res://data/puzzles/" + era_id
		if not DirAccess.dir_exists_absolute(puzzle_dir):
			print("  时代 '%s': 无关卡数据" % era_id)
			continue

		var dir = DirAccess.open(puzzle_dir)
		if not dir:
			continue

		var files: Array = []
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

		var era_solvable = 0
		var era_total = 0

		for file_name in files:
			var path = puzzle_dir + "/" + file_name
			var file = FileAccess.open(path, FileAccess.READ)
			if not file:
				continue
			var json = JSON.new()
			var err = json.parse(file.get_as_text())
			file.close()
			if err != OK:
				continue

			var data = json.data
			era_total += 1
			total_puzzles += 1

			if NonogramSolverScript.is_logically_solvable(data.row_clues, data.col_clues):
				era_solvable += 1
				solvable_puzzles += 1
			else:
				unsolvable_puzzles += 1
				print("  ✗ 不可推理: %s/%s" % [era_id, file_name])

		print("  时代 '%s': %d/%d 可推理求解" % [era_id, era_solvable, era_total])

	print("\n=== 验证完成 ===")
	print("总计: %d 关卡, %d 可推理, %d 不可推理" % [total_puzzles, solvable_puzzles, unsolvable_puzzles])
