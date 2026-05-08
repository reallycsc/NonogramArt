@tool
extends EditorScript

const PuzzleDataScript = preload("res://scripts/data/puzzle_data.gd")
const NonogramSolverScript = preload("res://scripts/nonogram/nonogram_solver.gd")

func _run() -> void:
	print("=== 数织关卡验证工具 ===")
	_verify_all_puzzles()


func _verify_all_puzzles() -> void:
	var eras = ["mythology", "xia_shang_zhou", "spring_autumn", "qin_han",
				"three_kingdoms", "sui_tang", "song_yuan", "ming_qing",
				"modern", "contemporary"]
	for era_id in eras:
		_verify_era_puzzles(era_id)


func _verify_era_puzzles(era_id: String) -> void:
	var puzzle_dir = "res://data/puzzles/" + era_id
	var dir = DirAccess.open(puzzle_dir)
	if not dir:
		print("\n时代 '%s': 无关卡数据" % era_id)
		return

	var files: Array = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			files.append(puzzle_dir + "/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	print("\n=== 时代: %s (%d 关卡) ===" % [era_id, files.size()])
	for path in files:
		_verify_puzzle(path)


func _verify_puzzle(path: String) -> void:
	print("\n--- 验证: ", path, " ---")
	if not FileAccess.file_exists(path):
		print("文件不存在！")
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("无法打开文件！")
		return
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		print("JSON解析失败！")
		return
	var data = json.data
	var puzzle = PuzzleDataScript.from_json(data)

	print("关卡: %s (%dx%d)" % [puzzle.name, puzzle.rows, puzzle.cols])

	var clues = NonogramSolverScript.compute_clues(puzzle.solution)
	var clues_match = (clues.row_clues == puzzle.row_clues and clues.col_clues == puzzle.col_clues)
	print("提示数字一致性: ", "✓ 通过" if clues_match else "✗ 不匹配！")
	if not clues_match:
		print("  期望行提示: ", puzzle.row_clues)
		print("  计算行提示: ", clues.row_clues)
		print("  期望列提示: ", puzzle.col_clues)
		print("  计算列提示: ", clues.col_clues)

	var solution_valid = NonogramSolverScript.verify_solution(puzzle.row_clues, puzzle.col_clues, puzzle.solution)
	print("解答验证: ", "✓ 通过" if solution_valid else "✗ 无效！")

	var solvable = NonogramSolverScript.is_logically_solvable(puzzle.row_clues, puzzle.col_clues)
	print("可推理求解: ", "✓ 是" if solvable else "✗ 否（需要猜测）")

	if solvable:
		var result = NonogramSolverScript.solve(puzzle.row_clues, puzzle.col_clues)
		print("求解步数: ", result.steps)
		var match = _compare_solution(result.grid, puzzle.solution)
		print("解与答案一致: ", "✓ 是" if match else "✗ 否！")

	var overall = clues_match and solution_valid and solvable
	print("总体评价: ", "✓✓✓ 通过" if overall else "✗✗✗ 未通过")


func _compare_solution(solver_grid: Array, solution: Array) -> bool:
	for r in range(solution.size()):
		for c in range(solution[r].size()):
			var solver_val = 1 if solver_grid[r][c] == NonogramSolverScript.CellState.FILLED else 0
			if solver_val != solution[r][c]:
				return false
	return true
