import os
import json
from PIL import Image, ImageEnhance, ImageFilter
from copy import deepcopy

UNKNOWN = 0
FILLED = 1
EMPTY = 2

MYTHOLOGY_GRID_SIZE = 5
PIXEL_SCALE = 32

STORIES = {
    "pangu": {
        "name": "盘古开天",
        "x_cells": 3,
        "y_cells": 2,
        "objects": [
            {"id": "pangu_axe", "name": "巨斧", "col": 0, "row": 0},
            {"id": "pangu_sun", "name": "太阳", "col": 1, "row": 0},
            {"id": "pangu_mountain", "name": "山脉", "col": 2, "row": 0},
            {"id": "pangu_figure", "name": "盘古", "col": 0, "row": 1},
            {"id": "pangu_cloud", "name": "云雾", "col": 1, "row": 1},
            {"id": "pangu_earth", "name": "大地", "col": 2, "row": 1},
        ]
    },
    "nuwa": {
        "name": "女娲补天",
        "x_cells": 3,
        "y_cells": 2,
        "objects": [
            {"id": "nuwa_figure", "name": "女娲", "col": 0, "row": 0},
            {"id": "nuwa_stone", "name": "五色石", "col": 1, "row": 0},
            {"id": "nuwa_sky", "name": "天空裂缝", "col": 2, "row": 0},
            {"id": "nuwa_turtle", "name": "巨龟", "col": 0, "row": 1},
            {"id": "nuwa_pillar", "name": "天柱", "col": 1, "row": 1},
            {"id": "nuwa_cloud", "name": "祥云", "col": 2, "row": 1},
        ]
    },
    "houyi": {
        "name": "后羿射日",
        "x_cells": 3,
        "y_cells": 2,
        "objects": [
            {"id": "houyi_figure", "name": "后羿", "col": 0, "row": 0},
            {"id": "houyi_bow", "name": "神弓", "col": 1, "row": 0},
            {"id": "houyi_sun", "name": "太阳", "col": 2, "row": 0},
            {"id": "houyi_arrow", "name": "箭", "col": 0, "row": 1},
            {"id": "houyi_ground", "name": "焦土", "col": 1, "row": 1},
            {"id": "houyi_sky", "name": "天空", "col": 2, "row": 1},
        ]
    }
}


def line_solve(clues, current_states, line_length):
    if not clues or (len(clues) == 1 and clues[0] == 0):
        return [EMPTY] * line_length

    arrangements = generate_arrangements(clues, current_states, line_length)
    if not arrangements:
        return list(current_states)

    result = [UNKNOWN] * line_length
    for i in range(line_length):
        if current_states[i] != UNKNOWN:
            result[i] = current_states[i]
            continue
        all_filled = True
        all_empty = True
        for arr in arrangements:
            if arr[i] == FILLED:
                all_empty = False
            else:
                all_filled = False
        if all_filled:
            result[i] = FILLED
        elif all_empty:
            result[i] = EMPTY
    return result


def generate_arrangements(clues, current_states, line_length):
    results = []
    place_blocks(clues, 0, 0, current_states, line_length, [], results)
    return results


def place_blocks(clues, clue_idx, start_pos, current_states, line_length, partial, results):
    if clue_idx >= len(clues):
        arrangement = [EMPTY] * line_length
        for pos in partial:
            for i in pos:
                arrangement[i] = FILLED
        for i in range(line_length):
            if current_states[i] == FILLED and arrangement[i] != FILLED:
                return
            if current_states[i] == EMPTY and arrangement[i] != EMPTY:
                return
        results.append(arrangement)
        return

    block_size = clues[clue_idx]
    min_remaining = sum(clues[k] + 1 for k in range(clue_idx + 1, len(clues)))
    max_start = line_length - block_size - min_remaining

    for pos in range(start_pos, max_start + 1):
        can_place = True
        for i in range(start_pos, pos):
            if current_states[i] == FILLED:
                can_place = False
                break
        if not can_place:
            break

        block_valid = True
        for i in range(pos, pos + block_size):
            if current_states[i] == EMPTY:
                block_valid = False
                break
        if not block_valid:
            continue

        if pos + block_size < line_length and current_states[pos + block_size] == FILLED:
            if block_size == clues[clue_idx]:
                continue

        new_partial = list(partial)
        block_positions = list(range(pos, pos + block_size))
        new_partial.append(block_positions)
        next_start = pos + block_size + 1
        place_blocks(clues, clue_idx + 1, next_start, current_states, line_length, new_partial, results)


def solve(row_clues, col_clues):
    num_rows = len(row_clues)
    num_cols = len(col_clues)
    grid = [[UNKNOWN] * num_cols for _ in range(num_rows)]

    changed = True
    steps = 0
    while changed:
        changed = False
        steps += 1
        for r in range(num_rows):
            current = [grid[r][c] for c in range(num_cols)]
            new_states = line_solve(row_clues[r], current, num_cols)
            for c in range(num_cols):
                if new_states[c] != UNKNOWN and grid[r][c] == UNKNOWN:
                    grid[r][c] = new_states[c]
                    changed = True
        for c in range(num_cols):
            current = [grid[r][c] for r in range(num_rows)]
            new_states = line_solve(col_clues[c], current, num_rows)
            for r in range(num_rows):
                if new_states[r] != UNKNOWN and grid[r][c] == UNKNOWN:
                    grid[r][c] = new_states[r]
                    changed = True

    solvable = all(cell != UNKNOWN for row in grid for cell in row)
    return solvable, grid, steps


def compute_clues(solution):
    num_rows = len(solution)
    num_cols = len(solution[0]) if num_rows > 0 else 0

    row_clues = []
    for r in range(num_rows):
        segments = []
        count = 0
        for c in range(num_cols):
            if solution[r][c] == 1:
                count += 1
            else:
                if count > 0:
                    segments.append(count)
                count = 0
        if count > 0:
            segments.append(count)
        if not segments:
            segments = [0]
        row_clues.append(segments)

    col_clues = []
    for c in range(num_cols):
        segments = []
        count = 0
        for r in range(num_rows):
            if solution[r][c] == 1:
                count += 1
            else:
                if count > 0:
                    segments.append(count)
                count = 0
        if count > 0:
            segments.append(count)
        if not segments:
            segments = [0]
        col_clues.append(segments)

    return row_clues, col_clues


def find_hint_cells(row_clues, col_clues, solution, max_hints=10):
    num_rows = len(row_clues)
    num_cols = len(col_clues)

    grid = [[UNKNOWN] * num_cols for _ in range(num_rows)]

    changed = True
    while changed:
        changed = False
        for r in range(num_rows):
            current = [grid[r][c] for c in range(num_cols)]
            new_states = line_solve(row_clues[r], current, num_cols)
            for c in range(num_cols):
                if new_states[c] != UNKNOWN and grid[r][c] == UNKNOWN:
                    grid[r][c] = new_states[c]
                    changed = True
        for c in range(num_cols):
            current = [grid[r][c] for r in range(num_rows)]
            new_states = line_solve(col_clues[c], current, num_rows)
            for r in range(num_rows):
                if new_states[r] != UNKNOWN and grid[r][c] == UNKNOWN:
                    grid[r][c] = new_states[r]
                    changed = True

    stuck_cells = []
    for r in range(num_rows):
        for c in range(num_cols):
            if grid[r][c] == UNKNOWN:
                row_unknowns = sum(1 for cc in range(num_cols) if grid[r][cc] == UNKNOWN)
                col_unknowns = sum(1 for rr in range(num_rows) if grid[rr][c] == UNKNOWN)
                stuck_cells.append((r, c, row_unknowns + col_unknowns))

    stuck_cells.sort(key=lambda x: x[2])

    hint_cells = []
    for r, c, _ in stuck_cells:
        if len(hint_cells) >= max_hints:
            break
        hint_cells.append([r, c])

        test_grid = [row[:] for row in grid]
        for hr, hc in hint_cells:
            test_grid[hr][hc] = FILLED if solution[hr][hc] == 1 else EMPTY

        test_changed = True
        while test_changed:
            test_changed = False
            for rr in range(num_rows):
                current = [test_grid[rr][cc] for cc in range(num_cols)]
                new_states = line_solve(row_clues[rr], current, num_cols)
                for cc in range(num_cols):
                    if new_states[cc] != UNKNOWN and test_grid[rr][cc] == UNKNOWN:
                        test_grid[rr][cc] = new_states[cc]
                        test_changed = True
            for cc in range(num_cols):
                current = [test_grid[rr][cc] for rr in range(num_rows)]
                new_states = line_solve(col_clues[cc], current, num_rows)
                for rr in range(num_rows):
                    if new_states[rr] != UNKNOWN and test_grid[rr][cc] == UNKNOWN:
                        test_grid[rr][cc] = new_states[rr]
                        test_changed = True

        all_determined = all(cell != UNKNOWN for row in test_grid for cell in row)
        if all_determined:
            return hint_cells

    return hint_cells


def extract_region(image_path, col, row, x_cells, y_cells):
    img = Image.open(image_path)
    img_w, img_h = img.size
    region_w = img_w // x_cells
    region_h = img_h // y_cells
    x = col * region_w
    y = row * region_h
    region = img.crop((x, y, x + region_w, y + region_h))
    return region


def region_to_binary_matrix(region, grid_size, threshold=128):
    region = region.convert('RGB')

    gray = region.convert('L')
    hsv = region.convert('HSV')
    saturation = hsv.split()[1]
    value = hsv.split()[2]

    edges = gray.filter(ImageFilter.FIND_EDGES)

    small_gray = gray.resize((grid_size, grid_size), Image.Resampling.LANCZOS)
    small_sat = saturation.resize((grid_size, grid_size), Image.Resampling.LANCZOS)
    small_val = value.resize((grid_size, grid_size), Image.Resampling.LANCZOS)
    small_edge = edges.resize((grid_size, grid_size), Image.Resampling.LANCZOS)

    gray_pixels = list(small_gray.getdata())
    sat_pixels = list(small_sat.getdata())
    val_pixels = list(small_val.getdata())
    edge_pixels = list(small_edge.getdata())

    matrix = []
    for i in range(grid_size):
        row_data = []
        for j in range(grid_size):
            idx = i * grid_size + j
            g = gray_pixels[idx]
            s = sat_pixels[idx]
            v = val_pixels[idx]
            e = edge_pixels[idx]

            is_dark = g < 160
            is_colorful = s > 40
            has_edge = e > 50
            is_not_bright = v < 200

            filled = (is_dark and is_not_bright) or (is_colorful and is_not_bright) or (has_edge and is_dark)
            row_data.append(1 if filled else 0)
        matrix.append(row_data)
    return matrix


def apply_smoothing(matrix, iterations=1):
    for _ in range(iterations):
        new_matrix = [row[:] for row in matrix]
        for i in range(len(matrix)):
            for j in range(len(matrix[0])):
                neighbors = []
                for di in [-1, 0, 1]:
                    for dj in [-1, 0, 1]:
                        ni, nj = i + di, j + dj
                        if 0 <= ni < len(matrix) and 0 <= nj < len(matrix[0]):
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


def simplify_matrix(matrix):
    new_matrix = deepcopy(matrix)
    rows, cols = len(new_matrix), len(new_matrix[0])
    for i in range(rows):
        for j in range(cols):
            neighbors = 0
            total = 0
            for di in [-1, 0, 1]:
                for dj in [-1, 0, 1]:
                    if di == 0 and dj == 0:
                        continue
                    ni, nj = i + di, j + dj
                    if 0 <= ni < rows and 0 <= nj < cols:
                        total += 1
                        neighbors += new_matrix[ni][nj]
            if new_matrix[i][j] == 1 and neighbors <= 1:
                new_matrix[i][j] = 0
            elif new_matrix[i][j] == 0 and neighbors >= 6:
                new_matrix[i][j] = 1
    return new_matrix


def print_matrix(matrix):
    for row in matrix:
        print(''.join(['#' if cell == 1 else '.' for cell in row]))


def generate_puzzle_from_region(image_path, obj_info, story_id, grid_size, x_cells, y_cells, pixel_scale):
    col = obj_info["col"]
    row = obj_info["row"]

    region = extract_region(image_path, col, row, x_cells, y_cells)

    matrix = region_to_binary_matrix(region, grid_size, threshold=128)
    matrix = apply_smoothing(matrix, iterations=1)
    matrix = remove_small_blobs(matrix, min_size=2)

    row_clues, col_clues = compute_clues(matrix)

    solvable, grid, steps = solve(row_clues, col_clues)

    hint_cells = []
    if not solvable:
        print(f"    不可推理，尝试简化形状...")
        simplified = simplify_matrix(matrix)
        s_row_clues, s_col_clues = compute_clues(simplified)
        s_solvable, s_grid, s_steps = solve(s_row_clues, s_col_clues)
        if s_solvable:
            matrix = simplified
            row_clues, col_clues = s_row_clues, s_col_clues
            solvable = True
            steps = s_steps
            print(f"    简化后可推理 [OK]")

    if not solvable:
        print(f"    简化后仍不可推理，尝试添加提示格...")
        hint_cells = find_hint_cells(row_clues, col_clues, matrix, max_hints=5)
        if hint_cells:
            test_grid = [[UNKNOWN] * grid_size for _ in range(grid_size)]
            for hr, hc in hint_cells:
                test_grid[hr][hc] = FILLED if matrix[hr][hc] == 1 else EMPTY

            test_changed = True
            while test_changed:
                test_changed = False
                for r in range(grid_size):
                    current = [test_grid[r][c] for c in range(grid_size)]
                    new_states = line_solve(row_clues[r], current, grid_size)
                    for c in range(grid_size):
                        if new_states[c] != UNKNOWN and test_grid[r][c] == UNKNOWN:
                            test_grid[r][c] = new_states[c]
                            test_changed = True
                for c in range(grid_size):
                    current = [test_grid[r][c] for r in range(grid_size)]
                    new_states = line_solve(col_clues[c], current, grid_size)
                    for r in range(grid_size):
                        if new_states[r] != UNKNOWN and test_grid[r][c] == UNKNOWN:
                            test_grid[r][c] = new_states[r]
                            test_changed = True

            all_determined = all(cell != UNKNOWN for row in test_grid for cell in row)
            if all_determined:
                solvable = True
                print(f"    添加 {len(hint_cells)} 个提示格后可推理 [OK]")
            else:
                print(f"    添加提示格后仍不可推理 [FAIL]")

    region_w = grid_size * pixel_scale
    region_h = grid_size * pixel_scale
    source_rect = {
        "x": col * region_w,
        "y": row * region_h,
        "w": region_w,
        "h": region_h
    }

    filled_count = sum(cell for row in matrix for cell in row)
    total_cells = grid_size * grid_size
    density = filled_count / total_cells if total_cells > 0 else 0

    difficulty = "easy"
    if density < 0.3:
        difficulty = "easy"
    elif density < 0.6:
        difficulty = "medium"
    else:
        difficulty = "hard"

    puzzle = {
        "id": obj_info["id"],
        "name": obj_info["name"],
        "story_id": story_id,
        "size": {
            "rows": grid_size,
            "cols": grid_size
        },
        "difficulty": difficulty,
        "row_clues": row_clues,
        "col_clues": col_clues,
        "solution": matrix,
        "hint_cells": hint_cells,
        "source_rect": source_rect
    }

    return puzzle, solvable


def main():
    base_dir = "h:/Work/MyProject/ChineseMemory"
    illustration_dir = os.path.join(base_dir, "assets/images/illustrations/mythology_jimeng")
    output_dir = os.path.join(base_dir, "data/puzzles/mythology_jimeng")
    os.makedirs(output_dir, exist_ok=True)

    grid_size = MYTHOLOGY_GRID_SIZE
    pixel_scale = PIXEL_SCALE

    print("=" * 70)
    print("从完整插图生成数织关卡（遵循新规则）")
    print(f"难度阶段: 入门级 (grid_size = {grid_size})")
    print(f"像素缩放因子: P = {pixel_scale}")
    print("=" * 70)

    total_puzzles = 0
    solvable_puzzles = 0
    unsolvable_list = []

    for story_id, story_info in STORIES.items():
        image_path = os.path.join(illustration_dir, f"{story_id}.png")
        if not os.path.exists(image_path):
            print(f"\n插图不存在: {image_path}")
            continue

        img = Image.open(image_path)
        x_cells = story_info['x_cells']
        y_cells = story_info['y_cells']
        region_w = img.size[0] // x_cells
        region_h = img.size[1] // y_cells

        print(f"\n{'='*60}")
        print(f"故事: {story_info['name']} ({story_id})")
        print(f"插图尺寸: {img.size[0]}x{img.size[1]}")
        print(f"布局: {x_cells}x{y_cells} 区域, 每区域 {region_w}x{region_h} 像素")
        print(f"{'='*60}")

        for obj_info in story_info["objects"]:
            print(f"\n  区域 ({obj_info['col']},{obj_info['row']}): {obj_info['name']} ({obj_info['id']})")

            puzzle, solvable = generate_puzzle_from_region(
                image_path, obj_info, story_id, grid_size, x_cells, y_cells, pixel_scale
            )

            total_puzzles += 1

            print(f"    图案:")
            for row in puzzle["solution"]:
                print(f"      {''.join(['#' if c == 1 else '.' for c in row])}")
            print(f"    填充密度: {sum(c for r in puzzle['solution'] for c in r)}/{grid_size*grid_size}")
            print(f"    难度: {puzzle['difficulty']}")
            print(f"    可推理: {'YES' if solvable else 'NO'}")
            if puzzle["hint_cells"]:
                print(f"    提示格: {len(puzzle['hint_cells'])} 个")

            output_path = os.path.join(output_dir, f"{obj_info['id']}.json")
            with open(output_path, 'w', encoding='utf-8') as f:
                json.dump(puzzle, f, ensure_ascii=False, indent=4)
            print(f"    已保存: {output_path}")

            if solvable:
                solvable_puzzles += 1
            else:
                unsolvable_list.append(f"{story_id}/{obj_info['id']}")

    print(f"\n{'='*70}")
    print(f"生成完成！")
    print(f"  总计: {total_puzzles} 个关卡")
    print(f"  可推理: {solvable_puzzles} 个")
    print(f"  不可推理: {len(unsolvable_list)} 个")
    if unsolvable_list:
        print(f"  不可推理关卡:")
        for name in unsolvable_list:
            print(f"    - {name}")
    else:
        print(f"  所有关卡均可通过纯逻辑推理完成！ [OK]")
    print(f"{'='*70}")


if __name__ == "__main__":
    main()
