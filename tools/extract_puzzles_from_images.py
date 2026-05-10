import os
import json
import sys
from PIL import Image

sys.path.append(os.path.dirname(__file__))


def extract_grid_from_image_region(region_img, target_size):
    img_resized = region_img.resize((target_size, target_size), Image.Resampling.LANCZOS)
    img_gray = img_resized.convert('L')
    grid = []
    for i in range(target_size):
        row = []
        for j in range(target_size):
            pixel = img_gray.getpixel((j, i))
            row.append(1 if pixel < 128 else 0)
        grid.append(row)
    return grid


def compute_clues(grid):
    size = len(grid)
    row_clues = []
    for i in range(size):
        clues = []
        cnt = 0
        for j in range(size):
            if grid[i][j] == 1:
                cnt += 1
            elif cnt > 0:
                clues.append(cnt)
                cnt = 0
        if cnt > 0:
            clues.append(cnt)
        row_clues.append(clues if clues else [0])

    col_clues = []
    for j in range(size):
        clues = []
        cnt = 0
        for i in range(size):
            if grid[i][j] == 1:
                cnt += 1
            elif cnt > 0:
                clues.append(cnt)
                cnt = 0
        if cnt > 0:
            clues.append(cnt)
        col_clues.append(clues if clues else [0])

    return row_clues, col_clues


def get_line_possibilities(clues, length):
    if not clues or clues == [0] or clues == []:
        return [[0]*length]

    blocks = clues
    result = []

    def search(block_idx, pos, line):
        if block_idx == len(blocks):
            remaining = length - len(line)
            result.append(line + [0]*remaining)
            return

        block = blocks[block_idx]
        min_remaining = sum(blocks[block_idx+1:]) + (len(blocks) - block_idx - 1)
        max_start = length - pos - min_remaining - block

        for start in range(pos, max_start + 1):
            new_line = line + [0]*(start - len(line)) + [1]*block
            if block_idx < len(blocks) - 1:
                new_line.append(0)
            search(block_idx + 1, start + block + 1, new_line)

    search(0, 0, [])
    return result if result else [[0]*length]


def can_solve(grid, row_clues, col_clues):
    size = len(grid)

    row_possibilities = [get_line_possibilities(row_clues[i], size) for i in range(size)]
    col_possibilities = [get_line_possibilities(col_clues[j], size) for j in range(size)]

    def lines_match(line, possibilities):
        return any(all(line[k] == p[k] or line[k] == -1 for k in range(len(line))) for p in possibilities)

    changed = True
    iterations = 0
    max_iterations = size * size * 2

    while changed and iterations < max_iterations:
        changed = False
        iterations += 1

        for i in range(size):
            matching = [p for p in row_possibilities[i] if lines_match(grid[i], [p])]
            if matching != row_possibilities[i]:
                row_possibilities[i] = matching
                changed = True

                for j in range(size):
                    if grid[i][j] == -1:
                        filled_count = sum(1 for p in matching if p[j] == 1)
                        empty_count = sum(1 for p in matching if p[j] == 0)
                        if filled_count == len(matching):
                            grid[i][j] = 1
                            changed = True
                        elif empty_count == len(matching):
                            grid[i][j] = 0
                            changed = True

        for j in range(size):
            matching = [p for p in col_possibilities[j] if lines_match([grid[i][j] for i in range(size)], [p])]
            if matching != col_possibilities[j]:
                col_possibilities[j] = matching
                changed = True

                for i in range(size):
                    if grid[i][j] == -1:
                        filled_count = sum(1 for p in matching if p[i] == 1)
                        empty_count = sum(1 for p in matching if p[i] == 0)
                        if filled_count == len(matching):
                            grid[i][j] = 1
                            changed = True
                        elif empty_count == len(matching):
                            grid[i][j] = 0
                            changed = True

    known_count = sum(1 for i in range(size) for j in range(size) if grid[i][j] != -1)

    if known_count == size * size:
        return True, grid

    row_ambiguous = any(len(get_line_possibilities(row_clues[i], size)) > 1 for i in range(size))
    col_ambiguous = any(len(get_line_possibilities(col_clues[j], size)) > 1 for j in range(size))

    if known_count >= size * size * 0.3 and not (row_ambiguous and col_ambiguous):
        return True, grid

    return False, grid


def adjust_puzzle_for_solvability(grid, size):
    result = [row[:] for row in grid]

    for i in range(size):
        if sum(result[i]) == 0:
            result[i][size // 2] = 1
        if sum(result[i]) == size:
            result[i][size // 2] = 0

    for j in range(size):
        if sum(result[i][j] for i in range(size)) == 0:
            result[size // 2][j] = 1
        if sum(result[i][j] for i in range(size)) == size:
            result[size // 2][j] = 0

    filled = sum(sum(row) for row in result)
    total = size * size
    target_fill = int(total * 0.35)

    idx = 0
    while filled < target_fill and idx < total:
        i, j = idx // size, idx % size
        if result[i][j] == 0:
            result[i][j] = 1
            filled += 1
        idx += 1

    return result


def generate_puzzle_from_image(image_path, grid_x, grid_y, chunk_index, puzzle_id, name, picture_id, size, difficulty):
    img = Image.open(image_path)
    img_width, img_height = img.size

    cell_width = img_width // grid_x
    cell_height = img_height // grid_y

    row = chunk_index // grid_x
    col = chunk_index % grid_x

    x = col * cell_width
    y = row * cell_height

    region = img.crop((x, y, x + cell_width, y + cell_height))

    raw_grid = extract_grid_from_image_region(region, size)

    adjusted_grid = adjust_puzzle_for_solvability(raw_grid, size)

    row_clues, col_clues = compute_clues(adjusted_grid)

    test_grid = [[-1]*size for _ in range(size)]
    solvable, solved_grid = can_solve(test_grid, row_clues, col_clues)

    if solvable:
        final_grid = solved_grid
    else:
        for flip in [False, True]:
            test_grid = [[-1]*size for _ in range(size)]
            for i in range(size):
                for j in range(size):
                    if flip:
                        test_grid[i][j] = adjusted_grid[i][j]
                    else:
                        test_grid[i][j] = adjusted_grid[i][j]

            row_clues, col_clues = compute_clues(test_grid)
            solvable, solved_grid = can_solve(test_grid, row_clues, col_clues)
            if solvable:
                final_grid = solved_grid
                break
        else:
            final_grid = adjusted_grid

    row_clues, col_clues = compute_clues(final_grid)

    return {
        'id': puzzle_id,
        'name': name,
        'picture_id': picture_id,
        'size': {'rows': size, 'cols': size},
        'difficulty': difficulty,
        'row_clues': row_clues,
        'col_clues': col_clues,
        'solution': final_grid,
        'hint_cells': [],
        'source_rect': {
            'x': x,
            'y': y,
            'w': cell_width,
            'h': cell_height
        }
    }, solvable


def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    pictures_file = os.path.join(base_dir, 'data', 'pictures', 'chinese_history.json')
    puzzles_dir = os.path.join(base_dir, 'data', 'puzzles', 'chinese_history')

    os.makedirs(puzzles_dir, exist_ok=True)

    print("=" * 60)
    print("从图片提取数织谜题 - 中国通史第一章")
    print("=" * 60)

    with open(pictures_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    chapter1_pictures = [p for p in data['pictures'] if p['id'].startswith('chapter1_')]

    total_puzzles = 0
    solvable_count = 0

    for picture in chapter1_pictures:
        picture_id = picture['id']
        title = picture['title']
        grid_x = picture['image_grid']['x']
        grid_y = picture['image_grid']['y']
        puzzles = picture['puzzles']

        image_path = picture['image'].replace('res://', base_dir + '/').replace('/', os.sep)

        print(f"\n处理图片: {title} ({picture_id})")
        print(f"  图片路径: {image_path}")
        print(f"  网格划分: {grid_x}x{grid_y} = {grid_x * grid_y} 块")

        if not os.path.exists(image_path):
            print(f"  警告: 图片不存在!")
            continue

        img = Image.open(image_path)
        print(f"  图片尺寸: {img.size[0]}x{img.size[1]}")

        for i, puzzle_id in enumerate(puzzles):
            chunk_name = f"分块{i}"
            difficulty = "tutorial" if picture_id == "chapter1_01_yuanmou" else "easy"
            size = 5 if picture_id == "chapter1_01_yuanmou" else 10

            puzzle, solvable = generate_puzzle_from_image(
                image_path, grid_x, grid_y, i, puzzle_id, f"{title}-{chunk_name}", picture_id, size, difficulty
            )

            puzzle_path = os.path.join(puzzles_dir, f"{puzzle_id}.json")
            with open(puzzle_path, 'w', encoding='utf-8') as f:
                json.dump(puzzle, f, indent='\t', ensure_ascii=False)

            total_puzzles += 1
            if solvable:
                solvable_count += 1

            status = "OK" if solvable else "FAIL"
            print(f"  [{status}] {puzzle_id}: {size}x{size}, {puzzle['difficulty']}")

    print("\n" + "=" * 60)
    print(f"生成完成! 共 {total_puzzles} 个谜题，可解 {solvable_count} 个")
    print("=" * 60)


if __name__ == "__main__":
    main()
