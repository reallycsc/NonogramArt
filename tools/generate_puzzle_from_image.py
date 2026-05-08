import os
import json
from PIL import Image, ImageEnhance

def enhance_and_threshold(image, contrast_factor=2.0, brightness_factor=1.5):
    enhancer = ImageEnhance.Contrast(image)
    image = enhancer.enhance(contrast_factor)
    enhancer = ImageEnhance.Brightness(image)
    image = enhancer.enhance(brightness_factor)
    return image

def image_to_binary_matrix(image_path, target_size=(10, 10), threshold=150):
    img = Image.open(image_path).convert('L')
    img = enhance_and_threshold(img)
    img = img.resize(target_size, Image.Resampling.LANCZOS)
    pixels = list(img.get_flattened_data())
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
        pixels += dfs(i+1, j)
        pixels += dfs(i-1, j)
        pixels += dfs(i, j+1)
        pixels += dfs(i, j-1)
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
            clues = []
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
            clues = []
        col_clues.append(clues)
    
    return row_clues, col_clues

def calculate_difficulty(size, row_clues, col_clues):
    total_clues = sum(len(row) for row in row_clues) + sum(len(col) for col in col_clues)
    cell_count = size[0] * size[1]
    filled_cells = sum(sum(row) for row in row_clues)
    
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

def generate_puzzle_json(image_path, puzzle_id, name, story_id, size=(10, 10)):
    binary_matrix = image_to_binary_matrix(image_path, size)
    binary_matrix = apply_smoothing(binary_matrix, iterations=1)
    binary_matrix = remove_small_blobs(binary_matrix, min_size=2)
    
    row_clues, col_clues = matrix_to_clues(binary_matrix)
    difficulty = calculate_difficulty(size, row_clues, col_clues)
    
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
        "hint_cells": [],
        "source_rect": {
            "x": 0,
            "y": 0,
            "w": size[0] * 16,
            "h": size[1] * 16
        }
    }
    
    return puzzle

def print_matrix(matrix):
    for row in matrix:
        print(''.join(['X' if cell == 1 else '.' for cell in row]))

def main():
    image_dir = "h:/Work/MyProject/ChineseMemory/assets/images/puzzles/mythology_jimeng"
    output_dir = "h:/Work/MyProject/ChineseMemory/data/puzzles/mythology_jimeng"
    os.makedirs(output_dir, exist_ok=True)
    
    puzzle_info = [
        ("pangu_sun.png", "pangu_sun_jimeng", "太阳", "pangu", (10, 10)),
        ("pangu_axe.png", "pangu_axe_jimeng", "盘古斧", "pangu", (12, 12)),
        ("pangu_mountain.png", "pangu_mountain_jimeng", "山脉", "pangu", (10, 10)),
        ("nuwa_stone.png", "nuwa_stone_jimeng", "五色石", "nuwa", (10, 10)),
        ("nuwa_turtle.png", "nuwa_turtle_jimeng", "玄武龟", "nuwa", (12, 12)),
        ("houyi_bow.png", "houyi_bow_jimeng", "神弓", "houyi", (12, 12)),
        ("houyi_sun.png", "houyi_sun_jimeng", "太阳", "houyi", (10, 10)),
    ]
    
    for img_name, puzzle_id, name, story_id, size in puzzle_info:
        image_path = os.path.join(image_dir, img_name)
        if not os.path.exists(image_path):
            print(f"图片不存在: {image_path}")
            continue
        
        print(f"\n=== 正在生成谜题: {puzzle_id} ===")
        print(f"图片: {img_name}")
        print(f"尺寸: {size[0]}x{size[1]}")
        
        puzzle = generate_puzzle_json(image_path, puzzle_id, name, story_id, size)
        
        print("生成的图案:")
        print_matrix(puzzle["solution"])
        
        output_path = os.path.join(output_dir, f"{puzzle_id}.json")
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(puzzle, f, ensure_ascii=False, indent=4)
        
        print(f"谜题已保存: {output_path}")
        print(f"难度: {puzzle['difficulty']}")
    
    print("\n=== 数织关卡生成完成！ ===")

if __name__ == "__main__":
    main()