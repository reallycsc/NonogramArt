@tool
extends EditorScript

const NonogramSolverScript = preload("res://scripts/nonogram/nonogram_solver.gd")

func _run() -> void:
	print("=== 数织关卡生成器 ===")
	print("用法：在 _run() 中调用以下方法：")
	print("  _generate_from_solution(id, name, story_id, solution, difficulty, source_rect)")
	print("  _generate_from_image(id, name, story_id, image_path, target_size, difficulty, source_rect)")
	print("  _batch_generate_from_solutions(puzzles_config)")
	print("  _batch_verify_and_fix(puzzle_dir)")


func generate_from_solution(p_id: String, p_name: String, p_story_id: String, p_solution: Array, p_difficulty: String = "medium", p_source_rect: Dictionary = {}) -> Dictionary:
	var num_rows = p_solution.size()
	var num_cols = p_solution[0].size() if num_rows > 0 else 0

	var clues = NonogramSolverScript.compute_clues(p_solution)
	var row_clues = clues.row_clues
	var col_clues = clues.col_clues

	var solvable = NonogramSolverScript.is_logically_solvable(row_clues, col_clues)
	var hint_cells: Array = []

	if not solvable:
		print("  关卡 '%s' 不可推理求解，尝试策略A：简化形状..." % p_name)
		var simplified = _simplify_solution(p_solution)
		if simplified != p_solution:
			var simp_clues = NonogramSolverScript.compute_clues(simplified)
			if NonogramSolverScript.is_logically_solvable(simp_clues.row_clues, simp_clues.col_clues):
				p_solution = simplified
				row_clues = simp_clues.row_clues
				col_clues = simp_clues.col_clues
				solvable = true
				print("  策略A成功！简化后可推理求解")

	if not solvable:
		print("  策略A失败，尝试策略B：添加提示格...")
		var result = _add_hint_cells(row_clues, col_clues, p_solution)
		if result.success:
			hint_cells = result.hint_cells
			solvable = true
			print("  策略B成功！添加了 %d 个提示格" % hint_cells.size())

	if not solvable:
		print("  策略B失败，尝试策略C：缩小网格...")
		if num_rows > 5 and num_cols > 5:
			var smaller = _downscale_solution(p_solution, num_rows - 5, num_cols - 5)
			if smaller.size() > 0:
				var small_clues = NonogramSolverScript.compute_clues(smaller)
				if NonogramSolverScript.is_logically_solvable(small_clues.row_clues, small_clues.col_clues):
					p_solution = smaller
					num_rows = p_solution.size()
					num_cols = p_solution[0].size() if num_rows > 0 else 0
					row_clues = small_clues.row_clues
					col_clues = small_clues.col_clues
					solvable = true
					print("  策略C成功！缩小到 %dx%d" % [num_rows, num_cols])

	var puzzle_data = {
		"id": p_id,
		"name": p_name,
		"story_id": p_story_id,
		"size": {"rows": num_rows, "cols": num_cols},
		"difficulty": p_difficulty,
		"row_clues": row_clues,
		"col_clues": col_clues,
		"solution": p_solution,
		"hint_cells": hint_cells,
		"source_rect": p_source_rect,
	}

	if solvable:
		var result = NonogramSolverScript.solve(row_clues, col_clues)
		print("  关卡 '%s' (%dx%d) 生成成功！可推理求解，步数：%d" % [p_name, num_rows, num_cols, result.steps])
		if not result.unique:
			print("  警告：解不唯一，建议添加提示格")
	else:
		print("  关卡 '%s' (%dx%d) 生成失败：无法通过自动调整使其可推理求解" % [p_name, num_rows, num_cols])
		print("  已保存原始数据，需要手动调整或添加更多 hint_cells")

	return puzzle_data


func save_puzzle(puzzle_data: Dictionary, dir_path: String) -> void:
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(dir_path.replace("res://", "")):
		DirAccess.make_dir_recursive_absolute(dir_path)

	var file_path = dir_path + "/" + puzzle_data.id + ".json"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		push_error("无法创建文件: " + file_path)
		return

	var hint_data: Array = []
	for cell in puzzle_data.hint_cells:
		if cell is Vector2i:
			hint_data.append([cell.x, cell.y])
		elif cell is Array:
			hint_data.append(cell)

	var json_data = {
		"id": puzzle_data.id,
		"name": puzzle_data.name,
		"story_id": puzzle_data.story_id,
		"size": puzzle_data.size,
		"difficulty": puzzle_data.difficulty,
		"row_clues": puzzle_data.row_clues,
		"col_clues": puzzle_data.col_clues,
		"solution": puzzle_data.solution,
		"hint_cells": hint_data,
		"source_rect": puzzle_data.source_rect,
	}

	var json_string = JSON.stringify(json_data, "\t")
	file.store_string(json_string)
	file.close()
	print("  已保存: " + file_path)


func generate_from_image(p_id: String, p_name: String, p_story_id: String, image_path: String, target_size: int = 10, p_difficulty: String = "medium", p_source_rect: Dictionary = {}) -> Dictionary:
	var img = Image.load_from_file(image_path)
	if not img:
		push_error("无法加载图片: " + image_path)
		return {}

	var binary = _image_to_binary(img, target_size, target_size)
	if binary.size() == 0:
		push_error("图片转换失败: " + image_path)
		return {}

	return generate_from_solution(p_id, p_name, p_story_id, binary, p_difficulty, p_source_rect)


func batch_generate(puzzles_config: Array, base_dir: String) -> void:
	print("\n=== 批量生成数织关卡 ===")
	var success_count = 0
	var fail_count = 0

	for config in puzzles_config:
		var era_id = config.get("era_id", "")
		var story_id = config.get("story_id", "")
		var puzzle_id = config.get("id", "")
		var puzzle_name = config.get("name", "")
		var solution = config.get("solution", [])
		var difficulty = config.get("difficulty", "medium")
		var source_rect = config.get("source_rect", {})

		if solution.size() == 0:
			print("  跳过空关卡: " + puzzle_id)
			fail_count += 1
			continue

		var puzzle_data = generate_from_solution(puzzle_id, puzzle_name, story_id, solution, difficulty, source_rect)
		var dir_path = base_dir + "/" + era_id
		save_puzzle(puzzle_data, dir_path)

		if NonogramSolverScript.is_logically_solvable(puzzle_data.row_clues, puzzle_data.col_clues):
			success_count += 1
		else:
			fail_count += 1

	print("\n=== 批量生成完成 ===")
	print("成功: %d, 失败: %d" % [success_count, fail_count])


func batch_verify_and_fix(puzzle_dir: String) -> void:
	print("\n=== 批量验证并修复关卡 ===")
	var dir = DirAccess.open(puzzle_dir)
	if not dir:
		push_error("无法打开目录: " + puzzle_dir)
		return

	var files: Array = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			files.append(puzzle_dir + "/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	for file_path in files:
		print("\n--- 验证: ", file_path, " ---")
		var file = FileAccess.open(file_path, FileAccess.READ)
		if not file:
			continue
		var json = JSON.new()
		var err = json.parse(file.get_as_text())
		file.close()
		if err != OK:
			print("  JSON解析失败")
			continue

		var data = json.data
		var row_clues = data.row_clues
		var col_clues = data.col_clues
		var solution = data.solution
		var solvable = NonogramSolverScript.is_logically_solvable(row_clues, col_clues)

		if solvable:
			var result = NonogramSolverScript.solve(row_clues, col_clues)
			var match = _compare_solution(result.grid, solution)
			if match:
				print("  ✓ 通过 (步数: %d)" % result.steps)
			else:
				print("  ✗ 解与答案不一致！")
		else:
			print("  ✗ 不可推理求解，尝试修复...")
			var fixed = generate_from_solution(data.id, data.name, data.story_id, solution, data.difficulty, data.source_rect)
			var fixed_solvable = NonogramSolverScript.is_logically_solvable(fixed.row_clues, fixed.col_clues)
			if fixed_solvable:
				print("  ✓ 修复成功！")
				save_puzzle(fixed, puzzle_dir)
			else:
				print("  ✗ 自动修复失败，需手动调整")


func _simplify_solution(solution: Array) -> Array:
	var num_rows = solution.size()
	var num_cols = solution[0].size() if num_rows > 0 else 0
	var modified = []
	for r in range(num_rows):
		var row = []
		for c in range(num_cols):
			row.append(solution[r][c])
		modified.append(row)

	var changed = true
	while changed:
		changed = false
		for r in range(num_rows):
			for c in range(num_cols):
				if modified[r][c] == 1:
					var neighbors_filled = 0
					if r > 0 and modified[r-1][c] == 1:
						neighbors_filled += 1
					if r < num_rows - 1 and modified[r+1][c] == 1:
						neighbors_filled += 1
					if c > 0 and modified[r][c-1] == 1:
						neighbors_filled += 1
					if c < num_cols - 1 and modified[r][c+1] == 1:
						neighbors_filled += 1
					if neighbors_filled == 0:
						modified[r][c] = 0
						changed = true
					elif neighbors_filled == 1:
						if _is_edge_cell(modified, r, c):
							continue
						modified[r][c] = 0
						changed = true

		for r in range(num_rows):
			for c in range(num_cols):
				if modified[r][c] == 0:
					var filled_neighbors = 0
					if r > 0 and modified[r-1][c] == 1:
						filled_neighbors += 1
					if r < num_rows - 1 and modified[r+1][c] == 1:
						filled_neighbors += 1
					if c > 0 and modified[r][c-1] == 1:
						filled_neighbors += 1
					if c < num_cols - 1 and modified[r][c+1] == 1:
						filled_neighbors += 1
					if filled_neighbors >= 3:
						modified[r][c] = 1
						changed = true

	return modified


func _is_edge_cell(solution: Array, r: int, c: int) -> bool:
	var num_rows = solution.size()
	var num_cols = solution[0].size() if num_rows > 0 else 0
	if r == 0 or r == num_rows - 1 or c == 0 or c == num_cols - 1:
		return true
	return false


func _add_hint_cells(row_clues: Array, col_clues: Array, solution: Array) -> Dictionary:
	var num_rows = row_clues.size()
	var num_cols = col_clues.size()
	var hint_cells: Array = []
	var max_hints = min(num_rows * num_cols / 4, 10)

	var grid: Array = []
	for r in range(num_rows):
		var row: Array = []
		for c in range(num_cols):
			row.append(NonogramSolverScript.CellState.UNKNOWN)
		grid.append(row)

	var changed = true
	while changed:
		changed = false
		for r in range(num_rows):
			var current = []
			for c in range(num_cols):
				current.append(grid[r][c])
			var new_states = NonogramSolverScript.line_solve(row_clues[r], current, num_cols)
			for c in range(num_cols):
				if new_states[c] != NonogramSolverScript.CellState.UNKNOWN and grid[r][c] == NonogramSolverScript.CellState.UNKNOWN:
					grid[r][c] = new_states[c]
					changed = true
		for c in range(num_cols):
			var current = []
			for r in range(num_rows):
				current.append(grid[r][c])
			var new_states = NonogramSolverScript.line_solve(col_clues[c], current, num_rows)
			for r in range(num_rows):
				if new_states[r] != NonogramSolverScript.CellState.UNKNOWN and grid[r][c] == NonogramSolverScript.CellState.UNKNOWN:
					grid[r][c] = new_states[r]
					changed = true

	var stuck_cells: Array = []
	for r in range(num_rows):
		for c in range(num_cols):
			if grid[r][c] == NonogramSolverScript.CellState.UNKNOWN:
				stuck_cells.append({"r": r, "c": c, "importance": 0})

	for cell in stuck_cells:
		var r = cell.r
		var c = cell.c
		var row_unknowns = 0
		var col_unknowns = 0
		for cc in range(num_cols):
			if grid[r][cc] == NonogramSolverScript.CellState.UNKNOWN:
				row_unknowns += 1
		for rr in range(num_rows):
			if grid[rr][c] == NonogramSolverScript.CellState.UNKNOWN:
				col_unknowns += 1
		cell.importance = row_unknowns + col_unknowns

	stuck_cells.sort_custom(func(a, b): return a.importance < b.importance)

	for cell in stuck_cells:
		if hint_cells.size() >= max_hints:
			break
		hint_cells.append([cell.r, cell.c])

		var test_grid: Array = []
		for r in range(num_rows):
			var row: Array = []
			for c in range(num_cols):
				row.append(grid[r][c])
			test_grid.append(row)

		for hc in hint_cells:
			var hr = hc[0]
			var hcc = hc[1]
			test_grid[hr][hcc] = NonogramSolverScript.CellState.FILLED if solution[hr][hcc] == 1 else NonogramSolverScript.CellState.EMPTY

		var test_changed = true
		while test_changed:
			test_changed = false
			for r in range(num_rows):
				var current = []
				for c in range(num_cols):
					current.append(test_grid[r][c])
				var new_states = NonogramSolverScript.line_solve(row_clues[r], current, num_cols)
				for c in range(num_cols):
					if new_states[c] != NonogramSolverScript.CellState.UNKNOWN and test_grid[r][c] == NonogramSolverScript.CellState.UNKNOWN:
						test_grid[r][c] = new_states[c]
						test_changed = true
			for c in range(num_cols):
				var current = []
				for r in range(num_rows):
					current.append(test_grid[r][c])
				var new_states = NonogramSolverScript.line_solve(col_clues[c], current, num_rows)
				for r in range(num_rows):
					if new_states[r] != NonogramSolverScript.CellState.UNKNOWN and test_grid[r][c] == NonogramSolverScript.CellState.UNKNOWN:
						test_grid[r][c] = new_states[r]
						test_changed = true

		var all_determined = true
		for r in range(num_rows):
			for c in range(num_cols):
				if test_grid[r][c] == NonogramSolverScript.CellState.UNKNOWN:
					all_determined = false
					break
			if not all_determined:
				break

		if all_determined:
			return {"success": true, "hint_cells": hint_cells}

	return {"success": false, "hint_cells": hint_cells}


func _downscale_solution(solution: Array, target_rows: int, target_cols: int) -> Array:
	if target_rows < 5 or target_cols < 5:
		return []

	var num_rows = solution.size()
	var num_cols = solution[0].size() if num_rows > 0 else 0

	if target_rows >= num_rows or target_cols >= num_cols:
		return []

	var result: Array = []
	var row_ratio = float(num_rows) / float(target_rows)
	var col_ratio = float(num_cols) / float(target_cols)

	for r in range(target_rows):
		var row: Array = []
		for c in range(target_cols):
			var src_r_start = int(r * row_ratio)
			var src_r_end = int((r + 1) * row_ratio)
			var src_c_start = int(c * col_ratio)
			var src_c_end = int((c + 1) * col_ratio)

			var filled_count = 0
			var total_count = 0
			for sr in range(src_r_start, src_r_end):
				for sc in range(src_c_start, src_c_end):
					if sr < num_rows and sc < num_cols:
						total_count += 1
						if solution[sr][sc] == 1:
							filled_count += 1

			row.append(1 if (total_count > 0 and filled_count > total_count / 2) else 0)
		result.append(row)

	return result


func _image_to_binary(img: Image, target_rows: int, target_cols: int) -> Array:
	if not img:
		return []

	var resized = img.duplicate()
	resized.resize(target_cols, target_rows, Image.INTERPOLATE_NEAREST)

	var result: Array = []
	for y in range(target_rows):
		var row: Array = []
		for x in range(target_cols):
			var pixel = resized.get_pixel(x, y)
			var brightness = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114
			row.append(1 if brightness < 0.5 else 0)
		result.append(row)

	return result


func _compare_solution(solver_grid: Array, solution: Array) -> bool:
	for r in range(solution.size()):
		for c in range(solution[r].size()):
			var solver_val = 1 if solver_grid[r][c] == NonogramSolverScript.CellState.FILLED else 0
			if solver_val != solution[r][c]:
				return false
	return true
