extends Node

enum CellState {
	EMPTY = 0,
	FILLED = 1,
	CROSSED = 2
}

var current_puzzle: PuzzleData
var current_puzzle_id: String = ""
var grid_size: Vector2i
var puzzle_data: Array = []
var player_grid: Array = []
var row_hints: Array = []
var col_hints: Array = []
var color_map: Dictionary = {}
var life: int = 3

func _ready():
	pass

func load_puzzle_data() -> bool:
	var puzzle_id = GameManager.pending_puzzle_id
	if puzzle_id == "":
		push_error("未设置当前谜题ID (GameManager.pending_puzzle_id 为空)")
		return false
	if puzzle_id == current_puzzle_id and current_puzzle != null:
		return true
	current_puzzle_id = puzzle_id
	current_puzzle = PuzzleData.load_puzzle(puzzle_id)
	if not current_puzzle:
		push_error("关卡数据读取错误: " + puzzle_id)
		return false
	print("谜题ID: " + current_puzzle.id)
	print("谜题名称: " + current_puzzle.name)
	print("谜题大小: %dx%d" % [current_puzzle.rows, current_puzzle.cols])
	return true

func setup_game() -> bool:
	if not load_puzzle_data():
		return false
	puzzle_data = current_puzzle.solution
	grid_size = Vector2i(current_puzzle.rows, current_puzzle.cols)
	row_hints = _convert_clues_to_hints(current_puzzle.row_clues)
	col_hints = _convert_clues_to_hints(current_puzzle.col_clues)
	color_map = {"1": [255, 255, 255]}
	player_grid = []
	for x in range(grid_size.x):
		var row = []
		for y in range(grid_size.y):
			row.append(CellState.EMPTY)
		player_grid.append(row)
	life = 3
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			GameManager.nonogram_cell_updated.emit(x, y, player_grid[x][y])
	for cell in current_puzzle.hint_cells:
		var cx = cell.x
		var cy = cell.y
		if cx >= 0 and cx < grid_size.x and cy >= 0 and cy < grid_size.y:
			player_grid[cx][cy] = CellState.CROSSED
	return true

func apply_hint_cells() -> void:
	for cell in current_puzzle.hint_cells:
		var cx = cell.x
		var cy = cell.y
		if cx >= 0 and cx < grid_size.x and cy >= 0 and cy < grid_size.y:
			player_grid[cx][cy] = CellState.CROSSED
			GameManager.nonogram_cell_updated.emit(cx, cy, CellState.CROSSED)
			GameManager.nonogram_cell_finished.emit(cx, cy)

func _convert_clues_to_hints(clues: Array) -> Array:
	var hints: Array = []
	for clue in clues:
		var hint_row: Array = []
		if clue.size() == 1 and clue[0] == 0:
			pass
		else:
			for value in clue:
				hint_row.append("1:" + str(int(value)))
		hints.append(hint_row)
	return hints

# 检查初始棋盘状态并更新
func check_and_update_after_ready():
	for x in range(grid_size.x):
		if check_row_is_finish(x):
			_finish_row(x)
		if is_row_only_one_pattern(x):
			GameManager.nonogram_rowHint_is_only_one_pattern.emit(x)
		else:
			GameManager.nonogram_rowHint_deducible.emit(x, is_row_deducible(x))
	for y in range(grid_size.y):
		if check_col_is_finish(y):
			_finish_col(y)
		if is_col_only_one_pattern(y):
			GameManager.nonogram_colHint_is_only_one_pattern.emit(y)
		else:
			GameManager.nonogram_colHint_deducible.emit(y, is_col_deducible(y))

# 检查并处理错误填充
# @param x: 格子X坐标
# @param y: 格子Y坐标
# @param new_state: 新的格子状态
# @return: 如果错误了返回true, 否则返回false
func check_and_handle_error(x: int, y: int, new_state: int) -> bool:
	# 如果本来就被玩家设置为cross，就返回false
	if player_grid[x][y] == CellState.CROSSED:
		return false
	# 只检查填充状态的错误
	if new_state == CellState.FILLED:
		var should_be_filled = (puzzle_data[x][y] > 0)
		if not should_be_filled:
			# 填充了不该填充的格子，扣除生命值
			life -= 1
			GameManager.nonogram_life_updated.emit(life, x, y)
			return true
	return false

func finish_cell_for_error(x: int, y: int) -> CellState:
	var cell_state = puzzle_data[x][y]
	if cell_state == CellState.EMPTY:
		cell_state = CellState.CROSSED
	player_grid[x][y] = cell_state
	check_solution(x, y)
	return cell_state
	
# 处理格子点击
# @param x: 格子X坐标
# @param y: 格子Y坐标
# @param button_index: 鼠标按钮索引
# @return: 点击前后的状态对
func on_cell_clicked(x: int, y: int, button_index: int) -> Vector2i:
	var cell_state1: int = player_grid[x][y]
	var cell_state2: int = -1
	
	if button_index == MOUSE_BUTTON_LEFT:
		if player_grid[x][y] == CellState.EMPTY:
			cell_state2 = CellState.FILLED
		else:
			cell_state2 = CellState.EMPTY
	elif button_index == MOUSE_BUTTON_RIGHT:
		if player_grid[x][y] == CellState.FILLED or player_grid[x][y] == CellState.CROSSED:
			cell_state2 = CellState.EMPTY
		else:
			cell_state2 = CellState.CROSSED
	else:
		cell_state2 = player_grid[x][y]
	
	# 改变格子状态
	if player_grid[x][y] != cell_state2:
		player_grid[x][y] = cell_state2
		GameManager.nonogram_cell_updated.emit(x, y, player_grid[x][y])
		# 检查游戏状态
		check_solution(x, y)
		
	return Vector2i(cell_state1, cell_state2)

func on_cell_dragging(x: int, y: int, button_index: int, cell_state_pair: Vector2i):
	if x < 0 or x >= grid_size.x or y < 0 or y >= grid_size.y:
		return
	
	if button_index == MOUSE_BUTTON_LEFT:
		# 起点初始为空，拖拽时不处理标记
		if cell_state_pair.x == CellState.EMPTY and player_grid[x][y] == CellState.CROSSED:
			return
		# 起点初始为填充，拖拽时不处理标记
		if cell_state_pair.x == CellState.FILLED and player_grid[x][y] == CellState.CROSSED:
			return
		# 起点初始为标记，拖拽时不处理空
		if cell_state_pair.x == CellState.CROSSED and player_grid[x][y] == CellState.EMPTY:
			return
	elif button_index == MOUSE_BUTTON_RIGHT:
		# 起点初始为空，拖拽时不处理填充
		if cell_state_pair.x == CellState.EMPTY and player_grid[x][y] == CellState.FILLED:
			return
		# 起点初始为填充，拖拽时不处理标记
		if cell_state_pair.x == CellState.FILLED and player_grid[x][y] == CellState.CROSSED:
			return
		# 起点初始为标记，拖拽时不处理填充
		if cell_state_pair.x == CellState.CROSSED and player_grid[x][y] == CellState.FILLED:
			return
	
	# 改变格子状态
	if player_grid[x][y] != cell_state_pair.y:
		player_grid[x][y] = cell_state_pair.y
		GameManager.nonogram_cell_updated.emit(x, y, player_grid[x][y])
		# 检查游戏状态
		check_solution(x, y)

# 检查单行是否完成
# @param x: 行索引
# @return: 是否完成
func check_row_is_finish(x: int) -> bool:
	for y in range(grid_size.y):
		# 只检查填充状态，忽略打叉状态
		var should_be_filled = (puzzle_data[x][y] > 0)
		var is_filled = (player_grid[x][y] == CellState.FILLED)
		if should_be_filled != is_filled:
			return false
	return true
	
# 检查单列是否完成
# @param y: 列索引
# @return: 是否完成
func check_col_is_finish(y: int) -> bool:
	for x in range(grid_size.x):
		# 只检查填充状态，忽略打叉状态
		var is_filled = (player_grid[x][y] == CellState.FILLED)
		var should_be_filled = (puzzle_data[x][y] > 0)
		if should_be_filled != is_filled:
			return false
	return true

# 递归生成所有可能匹配提示的模式
# @param current: 当前模式
# @param position: 当前位置
# @param hints: 提示数组
# @param n: 总长度
# @param patterns: 模式数组
static func generate_patterns(current: Array, position: int, hints: Array, n: int, patterns: Array):
	if hints.is_empty():
		# 所有提示块已放置，填充剩余格子为0
		while current.size() < n:
			current.append(0)
		patterns.append(current.duplicate())
		return
	
	var hint_parts = hints[0].split(":")
	var current_hint = hint_parts[1].to_int()
	var current_hint_color = hint_parts[0].to_int()
	var remaining_hints = hints.slice(1, hints.size())
	var next_hint_color = -1
	
	if not remaining_hints.is_empty():
		var next_hint_parts = remaining_hints[0].split(":")
		next_hint_color = next_hint_parts[0].to_int()
	
	# 计算剩余提示所需最小空间
	var min_remaining = 0
	var old_hint_color = hint_parts[0].to_int()
	for hint_str in remaining_hints:
		var hint_str_parts = hint_str.split(":")
		min_remaining += hint_str_parts[1].to_int()
		var hint_color = hint_str_parts[0].to_int()
		min_remaining += 1 if hint_color == old_hint_color else 0
		old_hint_color = hint_color
	
	# 计算当前块可能的起始位置范围
	var max_start = n - min_remaining - current_hint
	for start in range(position, max_start + 1):
		var new_pattern = current.duplicate()
		# 填充当前位置到起始位置之间的空白
		for i in range(position, start):
			new_pattern.append(0)
		# 放置当前提示块
		for i in range(current_hint):
			new_pattern.append(1)
		# 如果不是最后一个块，添加间隔
		var next_position = new_pattern.size()
		if current_hint_color == next_hint_color:
			new_pattern.append(0)
			next_position = new_pattern.size()
		# 递归处理剩余提示
		generate_patterns(new_pattern, next_position, remaining_hints, n, patterns)

# 检查当前行状态是否与特定模式兼容
# @param row_state: 行状态数组
# @param pattern: 模式数组
# @return: 是否兼容
static func is_pattern_compatible(row_state: Array, pattern: Array) -> bool:
	for i in range(row_state.size()):
		var state = row_state[i]
		var pattern_value = pattern[i]
		# 如果当前格子有明确状态，必须与模式匹配
		if state == CellState.FILLED and pattern_value != 1:
			return false
		if state == CellState.CROSSED and pattern_value != 0:
			return false
		# EMPTY状态不施加约束，可以匹配0或1
	return true

# 检查当前行是否可能
# @param row_state: 行状态数组
# @param hints: 提示数组
# @return: 是否可能
func is_row_possible(row_state: Array, hints: Array) -> bool:
	var n = row_state.size()
	#if n >= grid_size.x:
		#return true
	# 处理空提示情况
	if hints.is_empty():
		# 如果提示为空，行必须全未填充
		for state in row_state:
			if state == CellState.FILLED:
				return false
		return true
	
	# 计算最小所需长度
	var min_length = 0
	var old_hint_color = -1
	for hint_str in hints:
		var hint_str_parts = hint_str.split(":")
		min_length += hint_str_parts[1].to_int()
		var hint_color = hint_str_parts[0].to_int()
		min_length += 1 if hint_color == old_hint_color else 0
	
	if n < min_length:
		return false
	
	# 生成所有可能模式并检查兼容性
	var patterns = []
	generate_patterns([], 0, hints, n, patterns)
	for pattern in patterns:
		if is_pattern_compatible(row_state, pattern):
			return true
	
	return false

# 获取第y列的所有格子数据
# @param y: 列索引
# @return: 列数据数组
func get_column(y: int) -> Array:
	var column = []
	# 遍历每一行，取出第y列的元素
	for x in range(grid_size.x):
		# 安全检查，确保y不超出当前列的范围
		if y < grid_size.y:
			column.append(player_grid[x][y])
		else:
			# 如果某一行没有第y列，返回默认值
			column.append(CellState.EMPTY)
	
	return column

# 检查当前列是否可能
# @param col_state: 列状态数组
# @param hints: 提示数组
# @return: 是否可能
func is_col_possible(col_state: Array, hints: Array) -> bool:
	var n = col_state.size()
	#if n >= grid_size.y:
		#return true
	# 处理空提示情况
	if hints.is_empty():
		# 如果提示为空，列必须全未填充
		for state in col_state:
			if state == CellState.FILLED:
				return false
		return true
	
	# 计算最小所需长度
	var min_length = 0
	var old_hint_color = -1
	for hint_str in hints:
		var hint_str_parts = hint_str.split(":")
		min_length += hint_str_parts[1].to_int()
		var hint_color = hint_str_parts[0].to_int()
		min_length += 1 if hint_color == old_hint_color else 0
	
	if n < min_length:
		return false
	
	# 生成所有可能模式并检查兼容性
	var patterns = []
	generate_patterns([], 0, hints, n, patterns)
	for pattern in patterns:
		if is_pattern_compatible(col_state, pattern):
			return true
	
	return false
	
# 分析行的确定格子
# @param row_index: 行索引
# @return: 包含确定格子信息的字典，格式为 {column: state}，state为1表示填充，0表示空白
func get_row_determinate_cells(row_index: int) -> Dictionary:
	var row_state = player_grid[row_index]
	var row_hint = row_hints[row_index]
	var n = row_state.size()
	
	# 生成所有可能的有效模式
	var possible_patterns = []
	generate_patterns([], 0, row_hint, n, possible_patterns)
	
	# 过滤出与当前状态兼容的模式
	var compatible_patterns = []
	for pattern in possible_patterns:
		if is_pattern_compatible(row_state, pattern):
			compatible_patterns.append(pattern)
	
	# 如果没有兼容的模式，返回空字典
	if compatible_patterns.is_empty():
		return {}
	
	# 分析所有兼容模式，找出确定的格子
	var determinate_cells = {}
	for i in range(n):
		# 跳过已经有明确状态的格子
		if row_state[i] != CellState.EMPTY:
			continue
		
		# 检查所有模式在该位置的值是否一致
		var all_same = true
		var first_value = compatible_patterns[0][i]
		
		for pattern in compatible_patterns:
			if pattern[i] != first_value:
				all_same = false
				break
		
		# 如果所有模式在该位置的值一致，记录为确定格子
		if all_same:
			determinate_cells[i] = first_value
	
	return determinate_cells
	
# 判断行是否可推理
# @param row_index: 行索引
# @return: 是否存在根据行提示一定能填入的格子
func is_row_deducible(row_index: int) -> bool:
	var determinate_cells = get_row_determinate_cells(row_index)
	if not determinate_cells.is_empty():
		print("第" + str(row_index+1) + "行存在一定能填入的格子！")
		for column in determinate_cells.keys():
			var state = determinate_cells[column]
			var state_str = "填充" if state == 1 else "空白"
			print("列 %d 一定是 %s" % [column + 1, state_str])
		return true
	else:
		return false

# 分析列的确定格子
# @param col_index: 列索引
# @return: 包含确定格子信息的字典，格式为 {row: state}，state为1表示填充，0表示空白
func get_col_determinate_cells(col_index: int) -> Dictionary:
	# 构建列状态数组
	var col_state = []
	for row in range(grid_size.x):
		col_state.append(player_grid[row][col_index])
	
	var col_hint = col_hints[col_index]
	var n = col_state.size()
	
	# 生成所有可能的有效模式
	var possible_patterns = []
	generate_patterns([], 0, col_hint, n, possible_patterns)
	
	# 过滤出与当前状态兼容的模式
	var compatible_patterns = []
	for pattern in possible_patterns:
		if is_pattern_compatible(col_state, pattern):
			compatible_patterns.append(pattern)
	
	# 如果没有兼容的模式，返回空字典
	if compatible_patterns.is_empty():
		return {}
	
	# 分析所有兼容模式，找出确定的格子
	var determinate_cells = {}
	for i in range(n):
		# 跳过已经有明确状态的格子
		if col_state[i] != CellState.EMPTY:
			continue
		
		# 检查所有模式在该位置的值是否一致
		var all_same = true
		var first_value = compatible_patterns[0][i]
		
		for pattern in compatible_patterns:
			if pattern[i] != first_value:
				all_same = false
				break
		
		# 如果所有模式在该位置的值一致，记录为确定格子
		if all_same:
			determinate_cells[i] = first_value
	
	return determinate_cells

# 判断列是否可推理
# @param col_index: 列索引
# @return: 是否存在根据列提示一定能填入的格子
func is_col_deducible(col_index: int) -> bool:
	var determinate_cells = get_col_determinate_cells(col_index)
	if not determinate_cells.is_empty():
		print("第" + str(col_index+1) + "列存在一定能填入的格子！")
		for row in determinate_cells.keys():
			var state = determinate_cells[row]
			var state_str = "填充" if state == 1 else "空白"
			print("行 %d 一定是 %s" % [row + 1, state_str])
		return true
	else:
		return false

# 判断行是否只有一种可能的模式
# @param row_index: 行索引
# @return: 如果只有一种可能的模式并且当前填的格子都和答案吻合则返回true，否则返回false。
func is_row_only_one_pattern(row_index: int) -> bool:
	var row_state = player_grid[row_index]
	var row_hint = row_hints[row_index]
	var n = row_state.size()
	
	# 生成所有可能的有效模式
	var possible_patterns = []
	generate_patterns([], 0, row_hint, n, possible_patterns)
	
	# 过滤出与当前状态兼容的模式
	var compatible_patterns = []
	for pattern in possible_patterns:
		if is_pattern_compatible(row_state, pattern):
			compatible_patterns.append(pattern)
	
	# 如果只有一种兼容的模式，并且玩家当前填的格子都和答案相同，则返回true
	if compatible_patterns.size() == 1:
		for y in range(grid_size.y):
			var is_filled = (player_grid[row_index][y] == CellState.FILLED)
			if is_filled:
				var should_be_filled = (puzzle_data[row_index][y] > 0)
				if should_be_filled != is_filled:
					return false
		return true
	else:
		return false

# 判断列是否只有一种可能的模式
# @param col_index: 列索引
# @return: 如果只有一种可能的模式并且当前填的格子都和答案吻合则返回true，否则返回false。
func is_col_only_one_pattern(col_index: int) -> bool:
	# 构建列状态数组
	var col_state = []
	for row in range(grid_size.x):
		col_state.append(player_grid[row][col_index])
	
	var col_hint = col_hints[col_index]
	var n = col_state.size()
	
	# 生成所有可能的有效模式
	var possible_patterns = []
	generate_patterns([], 0, col_hint, n, possible_patterns)
	
	# 过滤出与当前状态兼容的模式
	var compatible_patterns = []
	for pattern in possible_patterns:
		if is_pattern_compatible(col_state, pattern):
			compatible_patterns.append(pattern)
	
	# 如果只有一种兼容的模式，并且玩家当前填的格子都和答案相同，则返回true
	if compatible_patterns.size() == 1:
		for x in range(grid_size.x):
			# 只检查玩家填充过的格子
			var is_filled = (player_grid[x][col_index] == CellState.FILLED)
			if is_filled:
				var should_be_filled = (puzzle_data[x][col_index] > 0)
				if should_be_filled != is_filled:
					return false
		return true
	else:
		return false

# 检查整个游戏是否完成
# @return: 是否完成
func check_is_finish() -> bool:
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			# 只检查填充状态，忽略打叉状态
			var should_be_filled = (puzzle_data[x][y] > 0)
			var is_filled = (player_grid[x][y] == CellState.FILLED)
			if should_be_filled != is_filled:
				return false
	return true

func _finish_row(index: int):
	# 锁定这一行所有格子
	for y in range(grid_size.y):
		if player_grid[index][y] == CellState.EMPTY:
			player_grid[index][y] = CellState.CROSSED
			GameManager.nonogram_cell_updated.emit(index, y, player_grid[index][y])
			if is_col_only_one_pattern(y):
				GameManager.nonogram_colHint_is_only_one_pattern.emit(y)
			else:
				GameManager.nonogram_colHint_deducible.emit(y, is_col_deducible(y))
		GameManager.nonogram_cell_finished.emit(index, y)
	GameManager.nonogram_rowHint_finished.emit(index)

func _finish_col(index: int):
	# 锁定这一列所有格子
	for x in range(grid_size.x):
		if player_grid[x][index] == CellState.EMPTY:
			player_grid[x][index] = CellState.CROSSED
			GameManager.nonogram_cell_updated.emit(x, index, player_grid[x][index])
			if is_row_only_one_pattern(x):
				GameManager.nonogram_rowHint_is_only_one_pattern.emit(x)
			else:
				GameManager.nonogram_rowHint_deducible.emit(x, is_row_deducible(x))
		GameManager.nonogram_cell_finished.emit(x, index)
	GameManager.nonogram_colHint_finished.emit(index)

# 检查解决方案
# @param x: 格子X坐标
# @param y: 格子Y坐标
func check_solution(x: int, y: int):
	# 检查行是否有错
	var row_is_error = not is_row_possible(player_grid[x], row_hints[x])
	GameManager.nonogram_rowHint_error.emit(x, row_is_error)
	if not row_is_error:
		# 检查行是否已完成
		if check_row_is_finish(x):
			print("检查当前行已完成：" + str(x))
			_finish_row(x)
		else:
			# 检查行是否只有一种可能的模式
			if is_row_only_one_pattern(x):
				GameManager.nonogram_rowHint_is_only_one_pattern.emit(x)
			else:
				GameManager.nonogram_rowHint_deducible.emit(x, is_row_deducible(x))
	# 检查列是否有错
	var col_is_error = not is_col_possible(get_column(y), col_hints[y])
	GameManager.nonogram_colHint_error.emit(y, col_is_error)
	if not col_is_error:
		# 检查列是否已完成
		if check_col_is_finish(y):
			print("检查当前列已完成：" + str(y))
			_finish_col(y)
		else:
			# 检查列是否只有一种可能的模式
			if is_col_only_one_pattern(y):
				GameManager.nonogram_colHint_is_only_one_pattern.emit(y)
			else:
				GameManager.nonogram_colHint_deducible.emit(y, is_col_deducible(y))
	if (not row_is_error) and (not col_is_error):
		if check_is_finish():
			# 记录关卡成信息
			GameManager.complete_puzzle(current_puzzle_id)
			GameManager.nonogram_game_completed.emit()
			

# 获取格子状态
# @param x: 格子X坐标
# @param y: 格子Y坐标
# @return: 格子状态
func get_cell_state(x: int, y: int) -> int:
	if x < 0 or x >= grid_size.x or y < 0 or y >= grid_size.y:
		return CellState.EMPTY
	return player_grid[x][y]

# 获取行提示
# @param row: 行索引
# @return: 行提示数组
func get_row_hints(row: int) -> Array:
	if row < 0 or row >= grid_size.x:
		return []
	return row_hints[row]

# 获取列提示
# @param col: 列索引
# @return: 列提示数组
func get_col_hints(col: int) -> Array:
	if col < 0 or col >= grid_size.y:
		return []
	return col_hints[col]

# 获取对应格子ID的颜色
# @param id: 颜色ID
# @return: 颜色对象
func get_color_by_id_for_hint(id: String) -> Color:
	var color_array = color_map.get(id, [])
	var alpha = 1 if color_map.size() > 1 else 0
	return Color(color_array[0] / 255, color_array[1] / 255, color_array[2] / 255, alpha)
	
# 获取指定位置格子的颜色
# @param x: 格子X坐标
# @param y: 格子Y坐标
# @return: 颜色对象
func get_color_by_index(x: int, y: int) -> Color:
	var id = str(puzzle_data[x][y])
	var color_array = color_map.get(id, [])
	return Color(color_array[0] / 255, color_array[1] / 255, color_array[2] / 255) if color_array else Color("#ffffff")
