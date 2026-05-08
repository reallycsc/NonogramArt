import os
import json
from PIL import Image, ImageEnhance
from io import BytesIO

PROJECT_ROOT = "h:/Work/MyProject/ChineseMemory"
ILLUSTRATION_DIR = os.path.join(PROJECT_ROOT, "assets/images/illustrations/yuangu")
DATA_DIR = os.path.join(PROJECT_ROOT, "data")
PUZZLES_DIR = os.path.join(DATA_DIR, "puzzles/yuangu")

GRID_X = 3
GRID_Y = 2
PUZZLE_GRID_SIZE = 10

def image_to_binary_matrix(img, target_size=(10, 10), threshold=140):
    gray = img.convert('L')
    enhancer = ImageEnhance.Contrast(gray)
    gray = enhancer.enhance(2.0)
    enhancer = ImageEnhance.Brightness(gray)
    gray = enhancer.enhance(1.3)
    gray = gray.resize(target_size, Image.Resampling.LANCZOS)
    pixels = list(gray.getdata())
    matrix = []
    for i in range(target_size[1]):
        row = []
        for j in range(target_size[0]):
            pixel = pixels[i * target_size[0] + j]
            row.append(0 if pixel >= threshold else 1)
        matrix.append(row)
    return matrix

def apply_smoothing(matrix, iterations=1):
    for _ in range(iterations):
        new_matrix = [row[:] for row in matrix]
        rows = len(matrix)
        cols = len(matrix[0])
        for i in range(rows):
            for j in range(cols):
                neighbors = []
                for di in [-1, 0, 1]:
                    for dj in [-1, 0, 1]:
                        ni, nj = i + di, j + dj
                        if 0 <= ni < rows and 0 <= nj < cols:
                            neighbors.append(matrix[ni][nj])
                if sum(neighbors) >= 5:
                    new_matrix[i][j] = 1
                elif sum(neighbors) <= 2:
                    new_matrix[i][j] = 0
        matrix = new_matrix
    return matrix

def remove_small_blobs(matrix, min_size=2):
    rows, cols = len(matrix), len(matrix[0])
    visited = [[False for _ in range(cols)] for _ in range(rows)]
    result = [row[:] for row in matrix]

    def dfs(i, j):
        if i < 0 or i >= rows or j < 0 or j >= cols:
            return []
        if visited[i][j] or matrix[i][j] == 0:
            return []
        visited[i][j] = True
        pixels = [(i, j)]
        pixels += dfs(i + 1, j)
        pixels += dfs(i - 1, j)
        pixels += dfs(i, j + 1)
        pixels += dfs(i, j - 1)
        return pixels

    for i in range(rows):
        for j in range(cols):
            if not visited[i][j] and matrix[i][j] == 1:
                blob = dfs(i, j)
                if len(blob) < min_size:
                    for (bi, bj) in blob:
                        result[bi][bj] = 0
    return result

def matrix_to_clues(matrix):
    row_clues = []
    for row in matrix:
        clues = []
        count = 0
        for pixel in row:
            if pixel == 1:
                count += 1
            else:
                if count > 0:
                    clues.append(count)
                    count = 0
        if count > 0:
            clues.append(count)
        if not clues:
            clues = [0]
        row_clues.append(clues)

    col_clues = []
    for col_idx in range(len(matrix[0])):
        clues = []
        count = 0
        for row_idx in range(len(matrix)):
            if matrix[row_idx][col_idx] == 1:
                count += 1
            else:
                if count > 0:
                    clues.append(count)
                    count = 0
        if count > 0:
            clues.append(count)
        if not clues:
            clues = [0]
        col_clues.append(clues)

    return row_clues, col_clues

def generate_arrangements(clues, current_states, line_length):
    results = []

    def place_blocks(clue_idx, start_pos, partial):
        if clue_idx >= len(clues):
            arrangement = [0] * line_length
            for positions in partial:
                for i in positions:
                    arrangement[i] = 1
            for i in range(line_length):
                if current_states[i] == 1 and arrangement[i] != 1:
                    return
                if current_states[i] == -1 and arrangement[i] != 0:
                    return
            results.append(arrangement)
            return

        block_size = clues[clue_idx]
        min_remaining = sum(clues[k] + 1 for k in range(clue_idx + 1, len(clues)))
        max_start = line_length - block_size - min_remaining

        for pos in range(start_pos, max_start + 1):
            can_skip = True
            for i in range(start_pos, pos):
                if current_states[i] == 1:
                    can_skip = False
                    break
            if not can_skip:
                break

            block_valid = True
            for i in range(pos, pos + block_size):
                if current_states[i] == -1:
                    block_valid = False
                    break
            if not block_valid:
                continue

            if pos + block_size < line_length and current_states[pos + block_size] == 1:
                continue

            new_partial = partial + [list(range(pos, pos + block_size))]
            next_start = pos + block_size + 1
            place_blocks(clue_idx + 1, next_start, new_partial)

    place_blocks(0, 0, [])
    return results

def line_solve(clues, current_states, line_length):
    if not clues or (len(clues) == 1 and clues[0] == 0):
        return [-1] * line_length

    arrangements = generate_arrangements(clues, current_states, line_length)
    if not arrangements:
        return current_states[:]

    result = [0] * line_length
    for i in range(line_length):
        if current_states[i] != 0:
            result[i] = current_states[i]
            continue
        all_filled = True
        all_empty = True
        for arr in arrangements:
            if arr[i] == 1:
                all_empty = False
            else:
                all_filled = False
        if all_filled:
            result[i] = 1
        elif all_empty:
            result[i] = -1

    return result

def solve_nonogram(row_clues, col_clues):
    num_rows = len(row_clues)
    num_cols = len(col_clues)
    grid = [[0] * num_cols for _ in range(num_rows)]

    changed = True
    while changed:
        changed = False
        for r in range(num_rows):
            current = grid[r][:]
            new_states = line_solve(row_clues[r], current, num_cols)
            for c in range(num_cols):
                if new_states[c] != 0 and grid[r][c] == 0:
                    grid[r][c] = new_states[c]
                    changed = True
        for c in range(num_cols):
            current = [grid[r][c] for r in range(num_rows)]
            new_states = line_solve(col_clues[c], current, num_rows)
            for r in range(num_rows):
                if new_states[r] != 0 and grid[r][c] == 0:
                    grid[r][c] = new_states[r]
                    changed = True

    fully_determined = all(grid[r][c] != 0 for r in range(num_rows) for c in range(num_cols))
    solution = [[1 if grid[r][c] == 1 else 0 for c in range(num_cols)] for r in range(num_rows)]
    return fully_determined, solution

def add_hint_cells(matrix, row_clues, col_clues):
    solvable, _ = solve_nonogram(row_clues, col_clues)
    if solvable:
        return matrix, []

    hint_cells = []
    rows = len(matrix)
    cols = len(matrix[0])
    max_hints = min(rows * cols // 4, 10)

    temp_matrix = [row[:] for row in matrix]
    for attempt in range(max_hints):
        best_r, best_c = -1, -1
        best_score = -1

        for r in range(rows):
            for c in range(cols):
                if temp_matrix[r][c] == 1:
                    filled_neighbors = 0
                    for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                        nr, nc = r + dr, c + dc
                        if 0 <= nr < rows and 0 <= nc < cols and temp_matrix[nr][nc] == 1:
                            filled_neighbors += 1
                    if filled_neighbors > best_score:
                        best_score = filled_neighbors
                        best_r, best_c = r, c

        if best_r >= 0:
            hint_cells.append([best_r, best_c])
            test_matrix = [row[:] for row in temp_matrix]
            test_rc, test_cc = matrix_to_clues(test_matrix)
            solvable, _ = solve_nonogram(test_rc, test_cc)
            if solvable:
                break

            for dr in range(-1, 2):
                for dc in range(-1, 2):
                    nr, nc = best_r + dr, best_c + dc
                    if 0 <= nr < rows and 0 <= nc < cols and temp_matrix[nr][nc] == 0:
                        temp_matrix[nr][nc] = 1

    return temp_matrix, hint_cells

def calculate_difficulty(size, matrix):
    cell_count = size[0] * size[1]
    filled_cells = sum(sum(row) for row in matrix)
    if cell_count <= 25:
        return "easy"
    elif cell_count <= 100:
        density = filled_cells / cell_count
        if density < 0.2:
            return "easy"
        elif density < 0.5:
            return "medium"
        else:
            return "hard"
    else:
        return "hard"

def split_image_into_blocks(img, grid_x, grid_y):
    w, h = img.size
    block_w = w // grid_x
    block_h = h // grid_y
    blocks = []
    for row in range(grid_y):
        for col in range(grid_x):
            x1 = col * block_w
            y1 = row * block_h
            x2 = x1 + block_w
            y2 = y1 + block_h
            block = img.crop((x1, y1, x2, y2))
            blocks.append({
                "image": block,
                "source_rect": {
                    "x": x1,
                    "y": y1,
                    "w": block_w,
                    "h": block_h
                }
            })
    return blocks

def generate_puzzle_from_block(block_img, puzzle_id, name, story_id, source_rect, size=(10, 10)):
    binary_matrix = image_to_binary_matrix(block_img, size)
    binary_matrix = apply_smoothing(binary_matrix, iterations=1)
    binary_matrix = remove_small_blobs(binary_matrix, min_size=2)

    filled = sum(sum(row) for row in binary_matrix)
    total = size[0] * size[1]
    if filled == 0 or filled == total:
        center = size[0] // 2
        for r in range(center - 2, center + 3):
            for c in range(center - 2, center + 3):
                binary_matrix[r][c] = 1

    row_clues, col_clues = matrix_to_clues(binary_matrix)
    solvable, _ = solve_nonogram(row_clues, col_clues)

    hint_cells = []
    if not solvable:
        binary_matrix, hint_cells = add_hint_cells(binary_matrix, row_clues, col_clues)
        row_clues, col_clues = matrix_to_clues(binary_matrix)
        solvable, _ = solve_nonogram(row_clues, col_clues)

    difficulty = calculate_difficulty(size, binary_matrix)

    puzzle = {
        "id": puzzle_id,
        "name": name,
        "story_id": story_id,
        "size": {
            "rows": size[1],
            "cols": size[0]
        },
        "difficulty": difficulty,
        "row_clues": row_clues,
        "col_clues": col_clues,
        "solution": binary_matrix,
        "hint_cells": hint_cells,
        "source_rect": source_rect
    }

    return puzzle, solvable

def main():
    story = {
        "id": "huangdi",
        "title": "黄帝部落联盟"
    }

    img_path = os.path.join(ILLUSTRATION_DIR, f"{story['id']}.png")
    
    if not os.path.exists(img_path):
        print(f"图片不存在: {img_path}")
        return

    img = Image.open(img_path)
    print(f"生成数织关卡: {story['title']} ({img.size[0]}x{img.size[1]})")

    blocks = split_image_into_blocks(img, GRID_X, GRID_Y)

    total_puzzles = 0
    solvable_puzzles = 0

    for block_idx, block_info in enumerate(blocks):
        puzzle_id = f"{story['id']}_{block_idx}"
        name = f"{story['title']}-分块{block_idx}"
        source_rect = block_info["source_rect"]

        print(f"\n  生成关卡: {puzzle_id} ({PUZZLE_GRID_SIZE}×{PUZZLE_GRID_SIZE})")

        puzzle, solvable = generate_puzzle_from_block(
            block_info["image"],
            puzzle_id,
            name,
            story["id"],
            source_rect,
            size=(PUZZLE_GRID_SIZE, PUZZLE_GRID_SIZE)
        )

        total_puzzles += 1
        if solvable:
            solvable_puzzles += 1

        filled = sum(sum(row) for row in puzzle["solution"])
        total = PUZZLE_GRID_SIZE * PUZZLE_GRID_SIZE
        print(f"    填充率: {filled}/{total} ({filled * 100 // total}%)")
        print(f"    难度: {puzzle['difficulty']}")
        print(f"    可推理求解: {'是' if solvable else '否 (已添加提示格)'}")
        if puzzle["hint_cells"]:
            print(f"    提示格: {puzzle['hint_cells']}")
        print(f"    图案预览:")
        for row in puzzle["solution"]:
            print(f"      {''.join(['X' if c == 1 else '.' for c in row])}")

        puzzle_path = os.path.join(PUZZLES_DIR, f"{puzzle_id}.json")
        with open(puzzle_path, 'w', encoding='utf-8') as f:
            json.dump(puzzle, f, ensure_ascii=False, indent=2)
        print(f"    已保存: {puzzle_path}")

    print(f"\n完成! {solvable_puzzles}/{total_puzzles} 个关卡可推理求解")

if __name__ == "__main__":
    main()
