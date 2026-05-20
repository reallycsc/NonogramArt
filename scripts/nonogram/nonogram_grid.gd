class_name NonogramGrid

enum CellState { UNKNOWN, FILLED, EMPTY, CROSSED }

signal cell_changed(row: int, col: int, state: int)
signal puzzle_completed
signal error_counted(count: int)

var rows: int = 0
var cols: int = 0
var grid: Array = []
var solution: Array = []
var row_clues: Array = []
var col_clues: Array = []
var hint_cells: Array = []
var error_count: int = 0
var is_complete: bool = false
var _undo_stack: Array = []
var _redo_stack: Array = []


func setup(puzzle: PuzzleData) -> void:
	rows = puzzle.rows
	cols = puzzle.cols
	solution = puzzle.solution
	row_clues = puzzle.row_clues
	col_clues = puzzle.col_clues
	hint_cells = puzzle.hint_cells
	error_count = 0
	is_complete = false
	_undo_stack.clear()
	_redo_stack.clear()
	grid = []
	for r in range(rows):
		var row: Array = []
		for c in range(cols):
			row.append(CellState.UNKNOWN)
		grid.append(row)
	for cell in hint_cells:
		var r = cell.x
		var c = cell.y
		if r >= 0 and r < rows and c >= 0 and c < cols:
			grid[r][c] = CellState.CROSSED
			cell_changed.emit(r, c, grid[r][c])


func set_cell(row: int, col: int, state: int) -> void:
	if row < 0 or row >= rows or col < 0 or col >= cols:
		return
	if grid[row][col] == state:
		return
	if is_complete:
		return
	var old_state = grid[row][col]
	var was_error = (grid[row][col] == CellState.FILLED and solution[row][col] != 1)
	var is_error = (state == CellState.FILLED and solution[row][col] != 1)
	var error_delta = 0
	if was_error:
		error_delta -= 1
	if is_error:
		error_delta += 1
	_undo_stack.append({"row": row, "col": col, "old_state": old_state, "new_state": state, "error_delta": error_delta})
	_redo_stack.clear()
	grid[row][col] = state
	error_count += error_delta
	if error_count < 0:
		error_count = 0
	if error_delta != 0:
		error_counted.emit(error_count)
	cell_changed.emit(row, col, state)
	_check_completion()


func toggle_fill(row: int, col: int) -> void:
	if grid[row][col] == CellState.FILLED:
		set_cell(row, col, CellState.UNKNOWN)
	else:
		set_cell(row, col, CellState.FILLED)


func toggle_mark(row: int, col: int) -> void:
	if grid[row][col] == CellState.CROSSED:
		set_cell(row, col, CellState.UNKNOWN)
	else:
		set_cell(row, col, CellState.CROSSED)


func undo() -> void:
	if _undo_stack.is_empty():
		return
	var action = _undo_stack.pop_back()
	_redo_stack.append(action)
	grid[action.row][action.col] = action.old_state
	error_count -= action.error_delta
	if error_count < 0:
		error_count = 0
	if action.error_delta != 0:
		error_counted.emit(error_count)
	cell_changed.emit(action.row, action.col, action.old_state)


func redo() -> void:
	if _redo_stack.is_empty():
		return
	var action = _redo_stack.pop_back()
	_undo_stack.append(action)
	grid[action.row][action.col] = action.new_state
	error_count += action.error_delta
	if error_count < 0:
		error_count = 0
	if action.error_delta != 0:
		error_counted.emit(error_count)
	cell_changed.emit(action.row, action.col, action.new_state)


func reset() -> void:
	for r in range(rows):
		for c in range(cols):
			grid[r][c] = CellState.UNKNOWN
	for cell in hint_cells:
		var r = cell.x
		var c = cell.y
		if r >= 0 and r < rows and c >= 0 and c < cols:
			grid[r][c] = CellState.CROSSED
	_undo_stack.clear()
	_redo_stack.clear()
	error_count = 0
	is_complete = false
	for r in range(rows):
		for c in range(cols):
			cell_changed.emit(r, c, grid[r][c])


func get_cell(row: int, col: int) -> int:
	if row < 0 or row >= rows or col < 0 or col >= cols:
		return CellState.UNKNOWN
	return grid[row][col]


func is_row_complete(row: int) -> bool:
	var segments: Array = []
	var count = 0
	for c in range(cols):
		if grid[row][c] == CellState.FILLED:
			count += 1
		else:
			if count > 0:
				segments.append(count)
			count = 0
	if count > 0:
		segments.append(count)
	if segments.is_empty():
		segments = [0]
	return segments == row_clues[row]


func is_col_complete(col: int) -> bool:
	var segments: Array = []
	var count = 0
	for r in range(rows):
		if grid[r][col] == CellState.FILLED:
			count += 1
		else:
			if count > 0:
				segments.append(count)
			count = 0
	if count > 0:
		segments.append(count)
	if segments.is_empty():
		segments = [0]
	return segments == col_clues[col]


func _check_completion() -> void:
	for r in range(rows):
		for c in range(cols):
			if solution[r][c] == 1 and grid[r][c] != CellState.FILLED:
				return
			if solution[r][c] == 0 and grid[r][c] != CellState.EMPTY and grid[r][c] != CellState.CROSSED:
				return
	is_complete = true
	puzzle_completed.emit()
