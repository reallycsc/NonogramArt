import os
import sys
import json
import requests
import time
from PIL import Image, ImageEnhance
from io import BytesIO
from math import gcd
from copy import deepcopy

API_BASE_URL = "https://ark.cn-beijing.volces.com/api/v3/images/generations"
API_KEY = "ark-769a3f8a-9ceb-4556-ae95-d882f7966850-2be63"
MODEL = "doubao-seedream-4-5-251128"

PROJECT_ROOT = "h:/Work/MyProject/NonogramArt"
ILLUSTRATION_DIR = os.path.join(PROJECT_ROOT, "assets/images/illustrations/chinese_history/chapter1")
PIXEL_DIR = os.path.join(PROJECT_ROOT, "assets/images/pixel/chinese_history/chapter1")
DATA_DIR = os.path.join(PROJECT_ROOT, "data")
PUZZLES_DIR = os.path.join(DATA_DIR, "puzzles/chinese_history")

GRID_X = 3
GRID_Y = 2
PUZZLE_GRID_SIZE = 10

ASPECT_RATIO_SIZES = {
    "1:1": "2048x2048",
    "4:3": "2304x1728",
    "3:4": "1728x2304",
    "16:9": "2848x1600",
    "9:16": "1600x2848",
    "3:2": "2496x1664",
    "2:3": "1664x2496",
    "21:9": "3136x1344",
}

STYLE_PREFIX = "中国风卡通插画风格，一幅完整的故事场景画，画面充满细节，避免纯色边缘区域。"
STYLE_SUFFIX = "色彩明快温暖，线条圆润，卡通造型可爱，完整构图，高分辨率，画面边缘有丰富细节，不要大面积纯色背景"

STORIES = [
    {
        "id": "chapter1_01_yuanmou",
        "title": "元谋人遗址",
        "summary": "中国最早的人类化石发现地",
        "full_text": "约170万年前，在云南元谋地区生活着中国境内已知最早的人类——元谋人。他们已经能够制作和使用简单的石器，标志着中国人类历史的开端。元谋人的发现，将中国人类历史向前推进了100多万年。",
        "objects": ["石器", "化石", "山洞", "热带植物"],
        "prompt": (
            "远古云南元谋地区，两个早期人类在红土地上进行石器制作，"
            "周围是茂密的热带丛林和山洞入口，地上散落着打制石器和动物骨骼化石，"
            "阳光透过树冠洒下斑驳光影，地面有蕨类植物和苔藓，画面四周都有丰富的自然元素"
        )
    },
    {
        "id": "chapter1_02_beijing_ape",
        "title": "北京猿人生活场景",
        "summary": "原始人在山洞前使用石器",
        "full_text": "约70万年前，北京周口店的龙骨山洞穴中生活着一群原始人类——北京猿人。他们已经掌握了用火技术，能够打制石器，过着群居采集和狩猎的生活。火的使用是人类文明史上的重大进步。",
        "objects": ["篝火", "石器", "山洞", "兽皮"],
        "prompt": (
            "周口店山洞前，一群原始人围坐在篝火旁取暖，"
            "有人手持石器加工食物，洞口挂着兽皮，"
            "远处是秋天的山林，洞内壁上有简单壁画，地面有石头和植被，"
            "天空中有飞鸟，画面边缘有丰富的自然景物"
        )
    },
    {
        "id": "chapter1_03_shandingdong",
        "title": "山顶洞人狩猎",
        "summary": "原始人类围猎大型动物",
        "full_text": "约3万年前，山顶洞人已经拥有了更先进的工具和技术。他们制作骨针缝制衣物，使用长矛和投掷武器进行集体狩猎，还会制作装饰品。山顶洞人的出现标志着中国旧石器时代晚期的到来。",
        "objects": ["长矛", "火把", "鹿", "岩石"],
        "prompt": (
            "一群原始猎人手持木矛和火把围猎一头鹿，"
            "有人投掷石块，远处山洞口有等待的族人，"
            "背景是雪后的山林和岩石，地面有枯草和石块，"
            "画面四周都有狩猎场景的丰富细节"
        )
    },
    {
        "id": "chapter1_04_hemudu",
        "title": "河姆渡文化",
        "summary": "原始农耕和干栏式房屋建筑",
        "full_text": "约7000年前，长江下游的河姆渡人创造了灿烂的农耕文明。他们种植水稻，建造干栏式木构房屋，饲养家畜，制作精美的黑陶。河姆渡文化是中国南方稻作文明的代表。",
        "objects": ["稻穗", "干栏式房屋", "黑陶", "河流"],
        "prompt": (
            "江南水乡，干栏式木屋建在水边高脚柱上，"
            "人们在稻田中劳作种植水稻，有人制作黑陶器皿，"
            "水中有鱼和菱角，岸边有芦苇和树木，"
            "天空中有飞鸟，画面四周都有丰富的水乡元素"
        )
    },
    {
        "id": "chapter1_05_yangshao",
        "title": "仰韶文化彩陶",
        "summary": "精美的彩陶器皿",
        "full_text": "约5000年前，黄河中游的仰韶文化以其精美的彩陶闻名于世。人们制作带有鱼纹、蛙纹和几何花纹的彩陶器皿，过着定居的农业生活。仰韶文化是中国新石器时代最重要的文化之一。",
        "objects": ["彩陶", "鱼纹", "陶窑", "农田"],
        "prompt": (
            "黄河岸边原始村落，人们制作精美的彩陶器皿，"
            "陶器上有鱼纹和几何花纹，旁边有陶窑在烧制，"
            "远处是黄土高原和半地穴式房屋，农田里有庄稼，"
            "天空中有云朵，画面四周都有生活场景细节"
        )
    },
    {
        "id": "chapter1_06_liangzhu",
        "title": "良渚古城",
        "summary": "长江流域早期文明",
        "full_text": "约5300年前，良渚古城是长江流域早期国家的都城。宏伟的城墙、大型祭坛和精美玉器见证了良渚文明的辉煌。良渚古城的发现证实了中国五千年文明史，2019年被列入世界文化遗产。",
        "objects": ["玉琮", "城墙", "祭坛", "水网"],
        "prompt": (
            "长江流域早期城市，宏伟的城墙和护城河环绕，"
            "城内有祭坛和玉器作坊，人们制作精美的玉琮和玉璧，"
            "远处是稻田和水渠，河中有船只，"
            "天空中有飞鸟，画面四周都有城市和自然元素"
        )
    },
    {
        "id": "chapter1_07_huangdi",
        "title": "黄帝部落联盟",
        "summary": "炎黄二帝带领部落",
        "full_text": "约5000年前，黄帝与炎帝联合各部落，在涿鹿之野击败蚩尤，统一了中原各部。黄帝被尊为华夏始祖，炎黄子孙成为中华民族的代称。这一时期标志着华夏文明的起源。",
        "objects": ["龙旗", "战鼓", "部落", "旗帜"],
        "prompt": (
            "炎黄二帝站在高台上，手持龙旗和熊旗，"
            "身后是联合的部落族人，战鼓声声，旗帜飘扬，"
            "周围有山川和树木，地面有装饰性图案，"
            "天空中有祥云，画面四周都有部落联盟的丰富细节"
        )
    },
    {
        "id": "chapter1_08_dayu",
        "title": "大禹治水",
        "summary": "大禹带领民众治理洪水",
        "full_text": "约4000年前，大禹受命治理洪水，他三过家门而不入，采用疏导的方法，历时十三年终于治水成功。大禹治水体现了中华民族不畏艰险、公而忘私的精神，也奠定了夏朝建立的基础。",
        "objects": ["耒耜", "洪水", "山川", "堤坝"],
        "prompt": (
            "大禹手持耒耜站在河岸边指挥民众治理洪水，"
            "人们挖掘河道、堆筑堤坝，洪水被引导流入大海，"
            "远处山川壮丽，有树木和岩石，"
            "天空中有乌云和阳光，画面四周都有治水场景的丰富细节"
        )
    }
]

def get_size_for_grid(x_cells, y_cells):
    g = gcd(x_cells, y_cells)
    ratio_w = x_cells // g
    ratio_h = y_cells // g
    ratio_key = f"{ratio_w}:{ratio_h}"
    if ratio_key in ASPECT_RATIO_SIZES:
        return ASPECT_RATIO_SIZES[ratio_key]
    return "2K"

def generate_jimeng_image(prompt, size="2K"):
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    full_prompt = STYLE_PREFIX + prompt + STYLE_SUFFIX
    payload = {
        "model": MODEL,
        "prompt": full_prompt,
        "sequential_image_generation": "disabled",
        "response_format": "url",
        "size": size,
        "stream": False,
        "watermark": False
    }
    try:
        print(f"  调用API生成图片 (size={size})...")
        response = requests.post(API_BASE_URL, headers=headers, json=payload, timeout=180)
        response.raise_for_status()
        result = response.json()
        if result.get("data") and isinstance(result["data"], list) and len(result["data"]) > 0:
            if result["data"][0].get("url"):
                return result["data"][0]["url"]
        print(f"  API调用失败: {result.get('error', {}).get('message', '未知错误')}")
        return None
    except requests.exceptions.RequestException as e:
        print(f"  请求异常: {str(e)}")
        return None

def download_image(url, save_path):
    try:
        response = requests.get(url, timeout=60)
        response.raise_for_status()
        img = Image.open(BytesIO(response.content))
        img.save(save_path)
        print(f"  图片已保存: {save_path} ({img.size[0]}x{img.size[1]})")
        return True
    except Exception as e:
        print(f"  下载图片失败: {str(e)}")
        return False

def has_full_or_empty_lines(matrix):
    rows = len(matrix)
    cols = len(matrix[0]) if matrix else 0
    
    for row in matrix:
        if sum(row) == 0 or sum(row) == cols:
            return True
    
    for j in range(cols):
        col_sum = sum(matrix[i][j] for i in range(rows))
        if col_sum == 0 or col_sum == rows:
            return True
    
    return False

def fix_full_empty_lines(matrix):
    rows = len(matrix)
    cols = len(matrix[0]) if matrix else 0
    
    new_matrix = [row[:] for row in matrix]
    
    for i in range(rows):
        row_sum = sum(new_matrix[i])
        if row_sum == 0:
            new_matrix[i][cols//2] = 1
            if cols > 1:
                new_matrix[i][cols//2 - 1] = 1
        elif row_sum == cols:
            new_matrix[i][0] = 0
            if cols > 1:
                new_matrix[i][cols-1] = 0
    
    for j in range(cols):
        col_sum = sum(new_matrix[i][j] for i in range(rows))
        if col_sum == 0:
            new_matrix[rows//2][j] = 1
            if rows > 1:
                new_matrix[rows//2 - 1][j] = 1
        elif col_sum == rows:
            new_matrix[0][j] = 0
            if rows > 1:
                new_matrix[rows-1][j] = 0
    
    return new_matrix

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
    steps = 0
    while changed:
        changed = False
        steps += 1
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
    margin_w = (w - block_w * grid_x) // 2
    margin_h = (h - block_h * grid_y) // 2
    blocks = []
    for row in range(grid_y):
        for col in range(grid_x):
            x1 = margin_w + col * block_w
            y1 = margin_h + row * block_h
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
    
    if filled == 0:
        center = size[0] // 2
        for r in range(max(0, center - 2), min(size[0], center + 3)):
            for c in range(max(0, center - 2), min(size[1], center + 3)):
                binary_matrix[r][c] = 1
    elif filled == total:
        for r in range(size[0]):
            for c in [0, size[1]-1]:
                binary_matrix[r][c] = 0
        for c in range(size[1]):
            for r in [0, size[0]-1]:
                binary_matrix[r][c] = 0

    if has_full_or_empty_lines(binary_matrix):
        print(f"    检测到全满/全空行/列，正在修复...")
        binary_matrix = fix_full_empty_lines(binary_matrix)

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

def save_pixel_image(matrix, save_path):
    size = len(matrix)
    img = Image.new('RGB', (size, size), color='white')
    pixels = img.load()
    for i in range(size):
        for j in range(size):
            if matrix[i][j] == 1:
                pixels[j, i] = (0, 0, 0)
    img.save(save_path)

def main():
    os.makedirs(ILLUSTRATION_DIR, exist_ok=True)
    os.makedirs(PIXEL_DIR, exist_ok=True)
    os.makedirs(PUZZLES_DIR, exist_ok=True)

    print("=" * 80)
    print("中国通史·第一章：远古时代 — 图片与数织关卡生成（优化版）")
    print(f"图片数量: {len(STORIES)}张")
    print(f"每张图片分块: {GRID_X}×{GRID_Y} = {GRID_X * GRID_Y}块")
    print(f"数织网格: {PUZZLE_GRID_SIZE}×{PUZZLE_GRID_SIZE}")
    print(f"功能: 自动检测并修复全满/全空行/列")
    print("=" * 80)

    api_size = get_size_for_grid(GRID_X, GRID_Y)
    print(f"\n图片宽高比: {GRID_X}:{GRID_Y} → API尺寸: {api_size}")

    image_results = []
    for idx, story in enumerate(STORIES):
        print(f"\n{'=' * 60}")
        print(f"[{idx + 1}/{len(STORIES)}] {story['title']} ({story['id']})")
        print(f"  核心物体: {', '.join(story['objects'])}")
        print(f"  提示词: {story['prompt'][:60]}...")
        print(f"{'=' * 60}")

        save_path = os.path.join(ILLUSTRATION_DIR, f"{story['id']}.png")

        if os.path.exists(save_path):
            img = Image.open(save_path)
            print(f"  图片已存在，跳过生成: {save_path} ({img.size[0]}x{img.size[1]})")
            image_results.append({
                "story": story,
                "path": save_path,
                "success": True
            })
            continue

        image_url = generate_jimeng_image(story["prompt"], size=api_size)
        if image_url:
            print(f"  生成成功，正在下载...")
            if download_image(image_url, save_path):
                image_results.append({
                    "story": story,
                    "path": save_path,
                    "success": True
                })
            else:
                image_results.append({
                    "story": story,
                    "path": save_path,
                    "success": False
                })
        else:
            print(f"  生成失败: {story['id']}")
            image_results.append({
                "story": story,
                "path": save_path,
                "success": False
            })

        time.sleep(5)

    print("\n" + "=" * 80)
    print("图片生成完成，开始生成数织关卡...")
    print("=" * 80)

    total_puzzles = 0
    solvable_puzzles = 0
    puzzles_with_fixed_lines = 0

    for idx, result in enumerate(image_results):
        story = result["story"]
        if not result["success"]:
            print(f"\n跳过 {story['title']}（图片未生成）")
            continue

        print(f"\n{'=' * 60}")
        print(f"[{idx + 1}/{len(STORIES)}] 生成数织关卡: {story['title']}")
        print(f"{'=' * 60}")

        img = Image.open(result["path"])
        blocks = split_image_into_blocks(img, GRID_X, GRID_Y)

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

            has_fixed = has_full_or_empty_lines(puzzle["solution"])
            if not has_fixed:
                puzzles_with_fixed_lines += 1

            total_puzzles += 1
            if solvable:
                solvable_puzzles += 1

            filled = sum(sum(row) for row in puzzle["solution"])
            total = PUZZLE_GRID_SIZE * PUZZLE_GRID_SIZE
            print(f"    填充率: {filled}/{total} ({filled * 100 // total}%)")
            print(f"    难度: {puzzle['difficulty']}")
            print(f"    可推理求解: {'是' if solvable else '否 (已添加提示格)'}")
            print(f"    无全满/全空行/列: {'是' if not has_fixed else '否'}")
            if puzzle["hint_cells"]:
                print(f"    提示格: {puzzle['hint_cells']}")

            puzzle_path = os.path.join(PUZZLES_DIR, f"{puzzle_id}.json")
            with open(puzzle_path, 'w', encoding='utf-8') as f:
                json.dump(puzzle, f, ensure_ascii=False, indent=2)
            print(f"    已保存: {puzzle_path}")

            pixel_path = os.path.join(PIXEL_DIR, f"{puzzle_id}.png")
            save_pixel_image(puzzle["solution"], pixel_path)
            print(f"    像素图已保存: {pixel_path}")

    print("\n" + "=" * 80)
    print("生成完成！")
    print("=" * 80)
    print(f"\n结果摘要:")
    print(f"  图片: {sum(1 for r in image_results if r['success'])}/{len(STORIES)} 成功")
    print(f"  数织关卡: {total_puzzles} 个")
    print(f"  可推理求解: {solvable_puzzles}/{total_puzzles}")
    print(f"  无全满/全空行/列: {puzzles_with_fixed_lines}/{total_puzzles}")
    print(f"\n目录:")
    print(f"  插画目录: {ILLUSTRATION_DIR}")
    print(f"  像素图目录: {PIXEL_DIR}")
    print(f"  关卡目录: {PUZZLES_DIR}")

    for idx, result in enumerate(image_results):
        story = result["story"]
        status = "[OK]" if result["success"] else "[FAIL]"
        if result["success"]:
            img = Image.open(result["path"])
            print(f"  {status} {story['title']}: {img.size[0]}x{img.size[1]}")
        else:
            print(f"  {status} {story['title']}: failed")

if __name__ == "__main__":
    main()