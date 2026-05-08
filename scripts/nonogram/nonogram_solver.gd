class_name NonogramSolver

enum CellState { UNKNOWN, FILLED, EMPTY }


class SolveResult:
	var solvable: bool = false
	var unique: bool = false
	var grid: Array = []
	var steps: int = 0


static func solve(row_clues: Array, col_clues: Array) -> SolveResult:
	var num_rows = row_clues.size()
	var num_cols = col_clues.size()
	var grid: Array = []
	for r in range(num_rows):
		var row: Array = []
		for c in range(num_cols):
			row.append(CellState.UNKNOWN)
		grid.append(row)

	var changed = true
	var steps = 0
	while changed:
		changed = false
		steps += 1
		for r in range(num_rows):
			var current = []
			for c in range(num_cols):
				current.append(grid[r][c])
			var new_states = line_solve(row_clues[r], current, num_cols)
			for c in range(num_cols):
				if new_states[c] != CellState.UNKNOWN and grid[r][c] == CellState.UNKNOWN:
					grid[r][c] = new_states[c]
					changed = true
		for c in range(num_cols):
			var current = []
			for r in range(num_rows):
				current.append(grid[r][c])
			var new_states = line_solve(col_clues[c], current, num_rows)
			for r in range(num_rows):
				if new_states[r] != CellState.UNKNOWN and grid[r][c] == CellState.UNKNOWN:
					grid[r][c] = new_states[r]
					changed = true

	var result = SolveResult.new()
	result.grid = grid
	result.steps = steps
	result.solvable = _is_fully_determined(grid)
	if result.solvable:
		result.unique = _check_unique(row_clues, col_clues, grid)
	return result


static func is_logically_solvable(row_clues: Array, col_clues: Array) -> bool:
	var result = solve(row_clues, col_clues)
	return result.solvable


static func line_solve(clues: Array, current_states: Array, line_length: int) -> Array:
	if clues.is_empty() or (clues.size() == 1 and clues[0] == 0):
		var result = []
		for i in range(line_length):
			result.append(CellState.EMPTY)
		return result

	var arrangements = _generate_arrangements(clues, current_states, line_length)
	if arrangements.is_empty():
		return current_states.duplicate()

	var result = []
	for i in range(line_length):
		result.append(CellState.UNKNOWN)

	for i in range(line_length):
		if current_states[i] != CellState.UNKNOWN:
			result[i] = current_states[i]
			continue
		var all_filled = true
		var all_empty = true
		for arr in arrangements:
			if arr[i] == CellState.FILLED:
				all_empty = false
			else:
				all_filled = false
		if all_filled:
			result[i] = CellState.FILLED
		elif all_empty:
			result[i] = CellState.EMPTY

	return result


static func _generate_arrangements(clues: Array, current_states: Array, line_length: int) -> Array:
	var results: Array = []
	_place_blocks(clues, 0, 0, current_states, line_length, [], results)
	return results


static func _place_blocks(clues: Array, clue_idx: int, start_pos: int, current_states: Array, line_length: int, partial: Array, results: Array) -> void:
	if clue_idx >= clues.size():
		var arrangement = []
		for i in range(line_length):
			arrangement.append(CellState.EMPTY)
		for pos in partial:
			for i in pos:
				arrangement[i] = CellState.FILLED
		for i in range(line_length):
			if current_states[i] == CellState.FILLED and arrangement[i] != CellState.FILLED:
				return
			if current_states[i] == CellState.EMPTY and arrangement[i] != CellState.EMPTY:
				return
		results.append(arrangement)
		return

	var block_size = clues[clue_idx]
	var min_remaining = 0
	for k in range(clue_idx + 1, clues.size()):
		min_remaining += clues[k] + 1

	var max_start = line_length - block_size - min_remaining

	for pos in range(start_pos, max_start + 1):
		var can_place = true
		for i in range(start_pos, pos):
			if current_states[i] == CellState.FILLED:
				can_place = false
				break
		if not can_place:
			break

		var block_valid = true
		for i in range(pos, pos + block_size):
			if current_states[i] == CellState.EMPTY:
				block_valid = false
				break
		if not block_valid:
			continue

		if pos + block_size < line_length and current_states[pos + block_size] == CellState.FILLED:
			if block_size == clues[clue_idx]:
				continue

		var new_partial = partial.duplicate()
		var block_positions = []
		for i in range(pos, pos + block_size):
			block_positions.append(i)
		new_partial.append(block_positions)

		var next_start = pos + block_size + 1
		_place_blocks(clues, clue_idx + 1, next_start, current_states, line_length, new_partial, results)


static func _is_fully_determined(grid: Array) -> bool:
	for row in grid:
		for cell in row:
			if cell == CellState.UNKNOWN:
				return false
	return true


static func _check_unique(row_clues: Array, col_clues: Array, grid: Array) -> bool:
	var num_rows = row_clues.size()
	var num_cols = col_clues.size()
	var first_filled = -1
	var first_filled_col = -1
	for r in range(num_rows):
		for c in range(num_cols):
			if grid[r][c] == CellState.FILLED:
				first_filled = r
				first_filled_col = c
				break
		if first_filled >= 0:
			break
	if first_filled < 0:
		return true
	var alt_grid: Array = []
	for r in range(num_rows):
		var row: Array = []
		for c in range(num_cols):
			if r == first_filled and c == first_filled_col:
				row.append(CellState.EMPTY)
			else:
				row.append(grid[r][c])
		alt_grid.append(row)
	var changed = true
	while changed:
		changed = false
		for r in range(num_rows):
			var current = []
			for c in range(num_cols):
				current.append(alt_grid[r][c])
			var new_states = line_solve(row_clues[r], current, num_cols)
			for c in range(num_cols):
				if new_states[c] != CellState.UNKNOWN and alt_grid[r][c] == CellState.UNKNOWN:
					alt_grid[r][c] = new_states[c]
					changed = true
		for c in range(num_cols):
			var current = []
			for r in range(num_rows):
				current.append(alt_grid[r][c])
			var new_states = line_solve(col_clues[c], current, num_rows)
			for r in range(num_rows):
				if new_states[r] != CellState.UNKNOWN and alt_grid[r][c] == CellState.UNKNOWN:
					alt_grid[r][c] = new_states[r]
					changed = true
	return not _is_fully_determined(alt_grid)


static func verify_solution(row_clues: Array, col_clues: Array, solution: Array) -> bool:
	var num_rows = row_clues.size()
	var num_cols = col_clues.size()
	if solution.size() != num_rows:
		return false
	for r in range(num_rows):
		if solution[r].size() != num_cols:
			return false

	for r in range(num_rows):
		var segments: Array = []
		var count = 0
		for c in range(num_cols):
			if solution[r][c] == 1:
				count += 1
			else:
				if count > 0:
					segments.append(count)
				count = 0
		if count > 0:
			segments.append(count)
		if segments.is_empty():
			segments = [0]
		if segments != row_clues[r]:
			return false

	for c in range(num_cols):
		var segments: Array = []
		var count = 0
		for r in range(num_rows):
			if solution[r][c] == 1:
				count += 1
			else:
				if count > 0:
					segments.append(count)
				count = 0
		if count > 0:
			segments.append(count)
		if segments.is_empty():
			segments = [0]
		if segments != col_clues[c]:
			return false

	return true


static func compute_clues(solution: Array) -> Dictionary:
	var num_rows = solution.size()
	var num_cols = solution[0].size() if num_rows > 0 else 0
	var row_clues: Array = []
	var col_clues: Array = []

	for r in range(num_rows):
		var segments: Array = []
		var count = 0
		for c in range(num_cols):
			if solution[r][c] == 1:
				count += 1
			else:
				if count > 0:
					segments.append(count)
				count = 0
		if count > 0:
			segments.append(count)
		if segments.is_empty():
			segments = [0]
		row_clues.append(segments)

	for c in range(num_cols):
		var segments: Array = []
		var count = 0
		for r in range(num_rows):
			if solution[r][c] == 1:
				count += 1
			else:
				if count > 0:
					segments.append(count)
				count = 0
		if count > 0:
			segments.append(count)
		if segments.is_empty():
			segments = [0]
		col_clues.append(segments)

	return {"row_clues": row_clues, "col_clues": col_clues}
