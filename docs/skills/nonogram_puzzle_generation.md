# 数织关卡生成 Skill

## 概述

从原图自动生成数织（Nonogram）关卡和彩色像素图。核心原则：**从原图提取主体形状作为数织解，优先保持形状完整，提示叉叉优先于翻转修复**。

完整流程：读取画册文档 → 解析难度范围 → 原图分块 → 复杂度计算 → 动态难度分配 → Otsu二值化提取主体形状 → 线索计算 → 可解性验证 → 提示叉叉生成（优先） → 最小翻转修复（最后手段） → 关卡JSON + 彩色像素图。

## 工具与依赖

| 依赖 | 说明 |
| ---- | ---- |
| Python 3.11 | 运行生成脚本 |
| PIL/Pillow | 图片处理 |
| NumPy | 数值计算 |
| 画册文档 | `docs/albums/{album_id}.md`，定义难度范围和章节划分 |

## 数据结构

### 图片配置文件

`data/pictures/{album_id}.json` 中每张图片的配置：

**image_grid = {x:3, y:2}（6分块）示例**：

```json
{
  "id": "chapter1_01_yuanmou",
  "image": "res://assets/images/illustrations/chinese_history/chapter1_01_yuanmou.jpg",
  "pixel_image": "res://assets/images/illustrations/chinese_history/chapter1_01_yuanmou_nonogram_pixel.jpg",
  "image_grid": { "x": 3, "y": 2 },
  "puzzles": [
    "chapter1_01_yuanmou_0",
    "chapter1_01_yuanmou_1",
    "chapter1_01_yuanmou_2",
    "chapter1_01_yuanmou_3",
    "chapter1_01_yuanmou_4",
    "chapter1_01_yuanmou_5"
  ]
}
```

**image_grid = {x:1, y:1}（1分块）示例**：

```json
{
  "id": "geometric_shapes_000",
  "image": "res://assets/images/illustrations/geometric_shapes/geometric_shapes_000.jpg",
  "pixel_image": "res://assets/images/illustrations/geometric_shapes/geometric_shapes_000_nonogram_pixel.jpg",
  "image_grid": { "x": 1, "y": 1 },
  "puzzles": [
    "geometric_shapes_000_0"
  ]
}
```

**image_grid = {x:2, y:2}（4分块）示例**：

```json
{
  "id": "cute_animals_000",
  "image": "res://assets/images/illustrations/cute_animals/cute_animals_000.jpg",
  "pixel_image": "res://assets/images/illustrations/cute_animals/cute_animals_000_nonogram_pixel.jpg",
  "image_grid": { "x": 2, "y": 2 },
  "puzzles": [
    "cute_animals_000_d1",
    "cute_animals_000_d2",
    "cute_animals_000_d3",
    "cute_animals_000_d4"
  ]
}
```

### 关卡文件

`data/puzzles/{album_id}/{puzzle_id}.json`：

```json
{
  "id": "cute_animals_000_d1",
  "name": "cute_animals_000_d1",
  "picture_id": "cute_animals_000",
  "size": 5,
  "difficulty": "tutorial",
  "row_clues": [[1, 2], [2], [2], [2, 1], [4]],
  "col_clues": [[4], [4], [1, 1], [1, 1], [2]],
  "solution": [[1,0,1,1,0], [1,1,0,0,0], [1,1,0,0,0], [1,1,0,0,1], [0,1,1,1,1]],
  "hint_cells": [],
  "source_rect": { "x": 0, "y": 0, "width": 640, "height": 640 }
}
```

### 字段说明

| 字段 | 类型 | 说明 |
| ---- | ---- | ---- |
| id | string | 关卡唯一标识 |
| name | string | 关卡名称 |
| picture_id | string | 所属图片ID |
| size | int | 网格尺寸（正方形，size×size） |
| difficulty | string | 难度：tutorial(≤5)/easy(≤10)/medium(≤15)/hard(≤20)/expert(≤25) |
| row_clues | int[][] | 行线索，空行为 [0] |
| col_clues | int[][] | 列线索，空列为 [0] |
| solution | int[][] | 解网格，1=填充，0=空白 |
| hint_cells | int[][] | 提示叉叉坐标列表，每项 [row, col]，仅包含 solution=0 的格子 |
| source_rect | object | 对应原图的区域 {x, y, width, height} |

## 关卡大小与难度映射

| grid_size | difficulty | 说明 |
| --------- | ---------- | ---- |
| 5 | tutorial | 入门级，适合新手 |
| 10 | easy | 初级，适合进阶 |
| 15 | medium | 中级，需要一定经验 |
| 20 | hard | 高级，需要丰富经验 |
| 25 | expert | 专家级，最高难度 |

## 流程一：生成数织关卡与彩色像素图

### 运行命令

```powershell
# 生成指定画册的关卡
python tools/generate_nonogram.py {album_id}

# 示例：生成可爱动物画册
python tools/generate_nonogram.py cute_animals

# 示例：生成中国通史画册
python tools/generate_nonogram.py chinese_history
```

### 完整算法流程

```
画册文档 (docs/albums/{album_id}.md)
    │  解析每张图片的难度范围（min_size ~ max_size）
    │  解析章节划分
    │
    ▼
原图
    │
    ▼
1. 原图分块
    │  按 image_grid(X×Y) 分成 X×Y 个区域
    │  每个区域对应一个关卡
    │
    ▼
2. 复杂度计算 (calculate_complexity)
    │  计算每个区域的边缘密度和信息熵
    │  综合得出复杂度分数
    │
    ▼
3. 动态难度分配 (allocate_difficulties)
    │  根据画册文档的难度范围限定 min_size ~ max_size
    │  根据区域复杂度排序，在范围内分配递进难度
    │  低复杂度 → 较小网格，高复杂度 → 较大网格
    │
    ▼
4. Otsu二值化提取主体形状 (detect_subject_and_binarize)
    │  在原始高分辨率图像上计算Otsu阈值
    │  峰值背景检测：近白像素>15%→白背景→暗色主体
    │                    近黑像素>15%→黑背景→亮色主体
    │                    否则→少数派优先
    │  按阈值将每个格子二值化→主体形状网格
    │
    ▼
5. 亮度提取 (extract_cell_brightness_area)
    │  每块按 puzzle_size(N×N) 采样
    │  计算每个格子的区域平均灰度亮度 → [(row, col, brightness), ...]
    │
    ▼
6. 线索计算 (compute_clues)
    │  从网格提取行/列连续填充数
    │  空行/空列 → [0]
    │
    ▼
7. 可解性验证 (can_solve)
    │  约束传播算法（_propagate）
    │  返回是否纯逻辑可解
    │
    ▼
8. 提示叉叉生成 (find_hint_cells, 优先策略)
    │  只标记 solution=0 的空白格（X标记）
    │  贪心策略：选择解决未知格最多的位置
    │  支持增量提示
    │
    ▼
9. 最小翻转修复 (make_solvable, 最后手段)
    │  仅当提示叉叉不足以使关卡可解时使用
    │  最多翻转 min(10, size²//20) 个格子
    │  优先翻转亮度接近阈值的格子
    │  翻转后重新添加提示叉叉
    │  时间限制：10秒
    │
    ▼
输出关卡JSON文件 + 彩色像素图
```

### 步骤详解

#### 1. 原图分块

将原图按 `image_grid`（X列×Y行）分成 X×Y 个区域，每个区域对应一个关卡。分块数量由画册配置决定：

| image_grid | 分块数 | 适用场景 |
| ---------- | ------ | -------- |
| {x:1, y:1} | 1 | 单关卡图片 |
| {x:2, y:2} | 4 | 4关卡图片（如可爱动物） |
| {x:3, y:2} | 6 | 6关卡图片（如中国通史） |

**image_grid = {x:3, y:2}（6分块）示例**：

```
原图 (2496×1664)
┌──────────┬──────────┬──────────┐
│  block0  │  block1  │  block2  │  每块 832×832
├──────────┼──────────┼──────────┤
│  block3  │  block4  │  block5  │
└──────────┴──────────┴──────────┘
```

**image_grid = {x:2, y:2}（4分块）示例**：

```
原图 (1280×1280)
┌──────────┬──────────┐
│  block0  │  block1  │  每块 640×640
├──────────┼──────────┤
│  block2  │  block3  │
└──────────┴──────────┘
```

**image_grid = {x:1, y:1}（1分块）示例**：

```
原图 (1280×1280)
┌────────────────────┐
│      block0        │  整图 1280×1280
└────────────────────┘
```

#### 2. 复杂度计算

对每个分块区域计算图像复杂度，用于动态难度分配：

```python
def calculate_block_complexity(block_array):
    # 1. 转灰度图
    gray = np.dot(block_array[..., :3], [0.299, 0.587, 0.114]).astype(np.uint8)
    
    # 2. 边缘密度：水平和垂直方向的像素差异，归一化到 [0, 1]
    edges_x = np.abs(np.diff(gray, axis=1)).sum()
    edges_y = np.abs(np.diff(gray, axis=0)).sum()
    edge_density = (edges_x + edges_y) / (gray.shape[0] * gray.shape[1] * 255)
    
    # 3. 信息熵：衡量图像的信息量
    hist, _ = np.histogram(gray, bins=256, range=(0, 255))
    prob = hist / hist.sum()
    prob = prob[prob > 0]
    entropy = -np.sum(prob * np.log2(prob)) if len(prob) > 0 else 0
    
    # 4. 综合复杂度 = 边缘密度×50 + 信息熵
    # 边缘密度权重 50 使其与信息熵（通常 0-8）量级相当
    complexity = edge_density * 50 + entropy
    return complexity
```

**复杂度分数含义**：
- 边缘密度：图像中边缘/细节的多少，高边缘密度表示内容复杂
- 信息熵：图像颜色的丰富程度，高熵值表示颜色层次丰富
- 综合分数：两者加权求和，得分越高表示区域越复杂

#### 3. 动态难度分配

**核心原则：画册文档设定难度范围（最低～最高），区域复杂度决定范围内的具体分配。**

##### 3.1 读取画册文档确定难度范围

从 `docs/albums/{album_id}.md` 中解析每张图片的难度范围。每张图片的难度范围由其所属章节决定：

```python
def get_chapter_difficulty_range(pic_idx):
    # 可爱动物画册示例
    if pic_idx >= 0 and pic_idx <= 6:      # 第1章：萌宠乐园
        return 5, 10
    elif pic_idx >= 7 and pic_idx <= 14:   # 第2章：农场伙伴
        return 5, 10
    elif pic_idx >= 15 and pic_idx <= 21:  # 第3章：森林精灵
        return 5, 15
    elif pic_idx >= 22 and pic_idx <= 29:  # 第4章：海洋与天空
        return 5, 15
    else:
        return 5, 10
```

##### 3.2 完整难度分配算法

根据分块数量和难度范围，为每个区域分配具体难度：

```python
def get_dynamic_difficulties(img_path, grid_x, grid_y, pic_idx):
    # 1. 读取原图并计算分块尺寸
    img = Image.open(img_path).convert('RGBA')
    img_w, img_h = img.size
    img_array = np.array(img)
    block_w = img_w // grid_x
    block_h = img_h // grid_y
    
    # 2. 获取章节限定的难度范围
    min_size, max_size = get_chapter_difficulty_range(pic_idx)
    
    # 3. 计算每个区域的复杂度
    complexities = []
    for by in range(grid_y):
        for bx in range(grid_x):
            start_x = bx * block_w
            start_y = by * block_h
            block_array = img_array[start_y:start_y+block_h, start_x:start_x+block_w]
            complexity = calculate_block_complexity(block_array)
            complexities.append((bx, by, complexity))
    
    # 4. 按复杂度排序（低→高）
    complexities.sort(key=lambda x: x[2])
    
    # 5. 确定可用难度等级
    num_blocks = grid_x * grid_y
    available_sizes = [5, 10, 15, 20, 25]
    valid_sizes = sorted([s for s in available_sizes if min_size <= s <= max_size])
    
    # 6. 按复杂度排名均匀分配难度
    difficulties = [0] * num_blocks
    for idx, (bx, by, _) in enumerate(complexities):
        pos = by * grid_x + bx
        if len(valid_sizes) == 1:
            difficulties[pos] = valid_sizes[0]
        else:
            # 均匀分配：最低复杂度→最小难度，最高复杂度→最大难度
            size_idx = int(idx * (len(valid_sizes) - 1) / (num_blocks - 1))
            size_idx = min(size_idx, len(valid_sizes) - 1)
            difficulties[pos] = valid_sizes[size_idx]
    
    return difficulties
```

##### 3.3 分配示例

**可爱动物画册实际分配结果**（4分块，2×2）：

4分块（image_grid = {x:2, y:2}），难度范围 5×5～10×10：

| 图片 | 复杂度排名（低→高） | 分配难度 | 说明 |
| ---- | ------------------- | -------- | ---- |
| cute_animals_000 | [中, 低, 高, 低] | [5, 5, 10, 5] | 右下角简单 |
| cute_animals_003 | [低, 低, 低, 高] | [5, 5, 5, 10] | 前三角简单 |
| cute_animals_013 | [高, 低, 低, 低] | [10, 5, 5, 5] | 左上角复杂 |
| cute_animals_014 | [低, 低, 低, 高] | [5, 5, 5, 10] | 右下角复杂 |

4分块（image_grid = {x:2, y:2}），难度范围 5×5～15×15：

| 图片 | 复杂度排名（低→高） | 分配难度 | 说明 |
| ---- | ------------------- | -------- | ---- |
| cute_animals_019 | [高, 低, 中, 低] | [15, 5, 10, 5] | 左上角最复杂 |
| cute_animals_023 | [高, 中, 低, 低] | [15, 10, 5, 5] | 左上角最复杂 |
| cute_animals_026 | [低, 低, 高, 中] | [5, 5, 15, 10] | 左下角最复杂 |
| cute_animals_029 | [低, 高, 低, 中] | [5, 15, 5, 10] | 右上角最复杂 |

**关键特点**：
- 不同图片的难度分布完全不同，由各区域的实际复杂度决定
- 左上角不一定是5×5，取决于哪个区域复杂度最低
- 复杂度最高的区域会分配到范围内最大的难度

#### 4. Otsu二值化提取主体形状

**核心原则：从原图直接提取主体形状作为数织解，而非按排名填充。**

##### 4.1 算法流程

```python
def detect_subject_and_binarize(block_img, size):
    # 1. 在原始高分辨率图像上计算中心加权Otsu阈值
    img_array = np.array(block_img.convert('RGBA'))
    gray_full = (0.299 * img_array[:,:,0] + 0.587 * img_array[:,:,1] 
                 + 0.114 * img_array[:,:,2]).astype(int)
    
    # 2. 计算中心权重（距离中心越近权重越高）
    h, w = gray_full.shape
    cy, cx = h / 2.0, w / 2.0
    max_dist = np.sqrt(cy ** 2 + cx ** 2)
    y_coords = np.arange(h, dtype=np.float64).reshape(-1, 1)
    x_coords = np.arange(w, dtype=np.float64).reshape(1, -1)
    dist = np.sqrt((y_coords - cy) ** 2 + (x_coords - cx) ** 2)
    weights = 1.0 - 0.6 * (dist / max_dist)  # 中心权重1.0，角落权重0.4
    
    # 3. 加权Otsu阈值计算
    gray_flat = gray_full.flatten()
    weight_flat = weights.flatten()
    whist = np.bincount(gray_flat, weights=weight_flat, minlength=256)
    # ... 加权Otsu算法 ...
    threshold_val = otsu_result
    
    # 4. 中心vs边缘主体类型判断
    margin_y, margin_x = max(1, int(h * 0.2)), max(1, int(w * 0.2))
    center_region = gray_full[margin_y:h-margin_y, margin_x:w-margin_x]
    edge_region = np.concatenate([gray_full[:margin_y,:].flatten(),
                                   gray_full[h-margin_y:,:].flatten(),
                                   gray_full[margin_y:h-margin_y,:margin_x].flatten(),
                                   gray_full[margin_y:h-margin_y,w-margin_x:].flatten()])
    
    center_dark_ratio = float((center_region < threshold_val).sum()) / center_region.size
    edge_dark_ratio = float((edge_region < threshold_val).sum()) / edge_region.size
    
    if abs(center_dark_ratio - edge_dark_ratio) > 0.05:
        use_dark = center_dark_ratio > edge_dark_ratio  # 中心更暗→暗色主体
    else:
        # 比例接近时使用加权判断
        w_dark = float(np.sum(weight_flat * (gray_flat < threshold_val)))
        w_light = float(np.sum(weight_flat * (gray_flat >= threshold_val)))
        use_dark = w_dark > w_light
    
    # 5. 生成Otsu二值化网格（优先策略）
    brightness = extract_cell_brightness_area(block_img, size)
    grid = [[0] * size for _ in range(size)]
    for r, c, b_val in brightness:
        if use_dark:
            grid[r][c] = 1 if b_val < threshold_val else 0
        else:
            grid[r][c] = 1 if b_val >= threshold_val else 0
    
    otsu_fill_rate = sum(sum(row) for row in grid) / (size * size)
    
    # 6. 仅当Otsu填充率<15%时，使用边缘检测+连通区域分析作为回退
    if otsu_fill_rate < 0.15:
        sobel_x = np.zeros_like(gray_full, dtype=np.float64)
        sobel_y = np.zeros_like(gray_full, dtype=np.float64)
        sobel_x[:, 1:-1] = gray_full[:, 2:] - gray_full[:, :-2]
        sobel_y[1:-1, :] = gray_full[2:, :] - gray_full[:-2, :]
        edges = np.sqrt(sobel_x ** 2 + sobel_y ** 2)
        edge_threshold = np.percentile(edges, 85)
        edge_mask = edges > edge_threshold
        
        # 边缘膨胀 + 孔洞填充 + 连通区域标记
        edge_mask = np.pad(edge_mask, 1, mode='constant')
        for _ in range(2):
            edge_mask = np.logical_or(edge_mask, np.logical_and(
                np.roll(edge_mask, 1, axis=0),
                np.logical_and(
                    np.roll(edge_mask, 1, axis=1),
                    np.logical_and(
                        np.roll(edge_mask, -1, axis=0),
                        np.roll(edge_mask, -1, axis=1)
                    )
                )
            ))
        
        from scipy.ndimage import binary_fill_holes
        filled = binary_fill_holes(edge_mask).astype(np.int32)
        center_y, center_x = h // 2, w // 2
        if h > 2 and w > 2:
            filled[center_y-1:center_y+2, center_x-1:center_x+2] = 1
            from scipy.ndimage import label
            labeled, num_features = label(filled)
            if num_features > 0:
                center_label = labeled[center_y, center_x]
                filled = (labeled == center_label).astype(np.int32)
        
        edge_based_grid = [[0] * size for _ in range(size)]
        cell_h, cell_w = h / size, w / size
        for r in range(size):
            for c in range(size):
                y0, y1 = int(r * cell_h), int((r + 1) * cell_h)
                x0, x1 = int(c * cell_w), int((c + 1) * cell_w)
                region = filled[y0:y1, x0:x1]
                if region.size > 0 and np.mean(region) > 0.2:
                    edge_based_grid[r][c] = 1
        
        edge_fill_rate = sum(sum(row) for row in edge_based_grid) / (size * size)
        if edge_fill_rate > otsu_fill_rate:
            grid = [[edge_based_grid[r][c] for c in range(size)] for r in range(size)]
    
    # 7. 填充率上限钳制（超过65%时移除最不确定的格子）
    fill_count = sum(grid[r][c] for r in range(size) for c in range(size))
    fill_rate = fill_count / (size * size)
    
    max_fill_rate = 0.65
    if fill_rate > max_fill_rate:
        target_count = int(max_fill_rate * size * size)
        candidates = []
        for r, c, b_val in brightness:
            if grid[r][c] == 1:
                if use_dark:
                    margin = b_val - threshold_val
                else:
                    margin = threshold_val - b_val
                candidates.append((margin, r, c))
        candidates.sort(reverse=True)
        for margin, r, c in candidates:
            if fill_count <= target_count:
                break
            grid[r][c] = 0
            fill_count -= 1
        fill_rate = fill_count / (size * size)
    
    return grid, use_dark, threshold_val, fill_rate
```

##### 4.2 中心加权Otsu原理

**传统Otsu的问题**：当图片边缘有大面积背景时，全局阈值会被边缘区域主导，导致主体区域分割错误。

**中心加权策略**：
- 距离图片中心越近的像素权重越高（1.0）
- 距离图片边缘越近的像素权重越低（0.4）
- 阈值计算时更关注中心区域（主体通常位于中心）

```
权重分布示意：
┌─────────────────────────┐
│ 0.4  0.5  0.7  0.5  0.4 │
│ 0.5  0.7  0.9  0.7  0.5 │
│ 0.7  0.9  1.0  0.9  0.7 │
│ 0.5  0.7  0.9  0.7  0.5 │
│ 0.4  0.5  0.7  0.5  0.4 │
└─────────────────────────┘
```

##### 4.3 中心vs边缘主体类型判断

**核心思想**：比较中心区域和边缘区域的暗像素比例差异。

| 条件 | 判断 | 适用场景 |
| ---- | ---- | -------- |
| 中心暗像素比例 > 边缘暗像素比例 + 5% | 暗色主体 | 暗色物体在亮色背景上 |
| 中心暗像素比例 < 边缘暗像素比例 - 5% | 亮色主体 | 亮色物体在暗色背景上 |
| 比例差异 < 5% | 加权少数派优先 | 背景复杂的图片 |

**示例**：
- 云朵图片：中心是白色云朵，边缘是蓝色天空 → 中心暗比例 < 边缘暗比例 → 亮色主体
- 汽车图片：中心是浅色车身，边缘是浅色道路 → 比例接近 → 加权少数派判断

##### 4.4 边缘检测+连通区域分析（低填充率回退策略）

**适用场景**：仅当Otsu二值化结果填充率<15%时才执行，应对主体有清晰轮廓但颜色与背景接近的情况（如浅色汽车在浅色道路上）。

**算法流程**：
1. **优先使用Otsu**：首先使用中心加权Otsu生成网格，检查填充率
2. **低填充率触发**：仅当Otsu填充率<15%时，执行边缘检测+连通区域分析
3. **Sobel边缘检测**：检测图像中的高对比度边缘
4. **边缘膨胀**：连接断开的边缘线
5. **孔洞填充**：填充边缘包围的区域
6. **连通区域标记**：只保留中心主体区域，去除背景噪点
7. **选择更好的结果**：比较边缘检测填充率与Otsu填充率，选择填充率更高的结果

**优化效果示例**：

| 图片 | Otsu填充率 | 边缘检测填充率 | 效果 |
| ---- | ---------- | -------------- | ---- |
| 汽车 | 10% | 61% | ✅ 显著改善 |
| 雨伞 | 36% | - | ✅ 使用Otsu结果 |
| 花朵 | 32% | - | ✅ 使用Otsu结果 |

##### 4.5 填充率上限钳制

**问题**：某些图片Otsu二值化后填充率过高（如>80%），导致数织关卡过于简单。

**解决策略**：
- 设定最大填充率：65%
- 超过此值时，按亮度接近阈值的程度排序，移除最不确定的填充格
- 优先移除"边缘"格子（亮度最接近阈值），保留"核心"格子（亮度明显偏离阈值）

**算法流程**：
1. 计算当前填充率
2. 如果超过65%，计算需要移除的格子数：`target_count = int(0.65 * size * size)`
3. 收集所有填充格，按亮度接近阈值的程度排序（边缘格在前，核心格在后）
4. 从前往后移除格子，直到填充率降到65%以下

**优化效果**：

| 图片 | 优化前填充率 | 优化后填充率 |
| ---- | ------------ | ------------ |
| 云朵 | 85% | 65% |
| 太阳 | 92% | 65% |
| 书本 | 84% | 65% |

##### 4.6 主体识别示例

| 图片 | 近白比例 | 近黑比例 | 中心暗比例 | 边缘暗比例 | 判断结果 | 说明 |
| ---- | -------- | -------- | ---------- | ---------- | -------- | ---- |
| 空心正方形（蓝框白底） | 36% | 0% | 低 | 高 | 暗色主体 | 白底→蓝色边框是主体 |
| 实心三角形（红底白底） | 40% | 0% | 高 | 低 | 暗色主体 | 白底→红色三角是主体 |
| 黑猫（亮底） | 70% | 0% | 高 | 低 | 暗色主体 | 白底→黑猫是主体 |
| 白天鹅（暗底） | 0% | 65% | 低 | 高 | 亮色主体 | 黑底→白天鹅是主体 |
| 云朵（蓝天） | 低 | 高 | 低 | 高 | 亮色主体 | 蓝底→白云是主体 |

#### 5. 亮度提取

将每个分块区域按 `puzzle_size`（N×N）采样，计算每个格子的**区域平均灰度亮度值**（而非中心点采样）。

采样方式：将每块区域等分为 N×N 个子区域，取每个子区域所有像素的加权平均灰度值 `gray = mean(0.299*R + 0.587*G + 0.114*B)`。

**为什么用区域平均而非中心点？** 中心点采样在高对比度边界处可能采到错误的值，区域平均更稳定。

#### 6. 线索计算

从网格提取标准数织线索：
- 行线索：每行从左到右统计连续填充块数
- 列线索：每列从上到下统计连续填充块数
- 空行/空列的线索为 `[0]`

#### 7. 可解性验证

使用约束传播（Constraint Propagation）算法验证关卡是否可纯逻辑求解：

1. 为每行/列生成所有可能的排列（`_gen_arr`，带LRU缓存）
2. 约束传播（`_propagate`）：迭代过滤与已知格子矛盾的排列，对所有排列一致的格子确定其值
3. 检查是否所有格子都已确定

**重要**：`can_solve` 仅用于判断是否需要修复，**不修改解网格**。解始终使用从原图生成的网格（或翻转修复后的网格）。

#### 8. 提示叉叉生成（优先策略）

**核心原则：提示叉叉不改变解的形状，优先于翻转使用。**

当关卡无法纯推理完成时，首先添加提示叉叉（X标记，标记空白格）。提示叉叉的优势：
- **不改变解的形状**：只标记已知为空的格子，不修改填充格
- **帮助推理**：减少搜索空间，使约束传播能继续推进
- **用户体验好**：玩家看到X标记可以跳过这些格子

**设计原则**：提示叉叉只标记 solution=0 的格子（空白格），游戏初始化时这些格子显示为X标记状态，告诉玩家"这个格子一定是空的"。不标记 solution=1 的填充格，避免直接揭示答案。

**算法流程**：
1. 初始化网格，将已有提示叉叉设为已知空格（值为0）
2. 运行约束传播
3. 如果完全可解，结束
4. 找到所有 solution=0 的未知格
5. 贪心评估：选择所在行列未确定格最少的格子（约束效果最强）
6. 逐一标记为提示叉叉，每标记一个后重新约束传播
7. 直到完全可解或达到提示叉叉上限

**提示叉叉上限**：`max(15, size²//4)`

#### 9. 最小翻转修复（最后手段）

**核心原则：翻转会改变解的形状，仅在提示叉叉不足时使用，且严格限制翻转数量。**

**算法流程**：
1. 运行 `can_solve` 获取当前未确定的格子列表
2. 优先收集"填充未知格"（solution=1 但求解后仍为 -1 的格子）
3. 对候选格子按亮度接近阈值的程度排序（视觉偏差最小）
4. 逐一尝试翻转，评估翻转后的剩余未知格子数
5. 选择使"剩余未知格子数"最少的翻转
6. 翻转后修复可能产生的空行/空列
7. 重复直到可解或达到翻转上限
8. 翻转后重新添加提示叉叉

**翻转上限策略**：`min(10, max(3, size²//20))`

| 网格大小 | 最大翻转数 | 说明 |
| -------- | ---------- | ---- |
| 5×5 | 3 | 小网格几乎不需要翻转 |
| 10×10 | 5 | 中等网格少量翻转 |
| 15×15 | 7 | 大网格允许稍多翻转 |
| 20×20 | 10 | 最大网格上限 |

**亮度惩罚**：翻转时优先选择亮度接近阈值的格子，使视觉偏差最小。

**处理流程**：
1. 纯推理可解 → 完成（最佳情况）
2. 不可解 → 添加提示叉叉 → 可解 → 完成
3. 提示叉叉不足 → 最小翻转（≤10格）+ 更多提示 → 完成
4. 仍不足 → 再尝试2轮翻转（每轮≤5格）+ 提示 → 完成

### 输出格式

运行时逐行输出每个关卡的状态：

```
[1] cute_animals_000_d1 (5x5) subject=light nat=28% fill=28% OK
[2] cute_animals_000_d2 (5x5) subject=dark nat=36% fill=36% OK flips=1
[3] cute_animals_000_d3 (10x10) subject=light nat=37% fill=37% OK flips=1
[4] cute_animals_000_d4 (10x10) subject=light nat=48% fill=48% OK
```

| 字段 | 说明 |
| ---- | ---- |
| subject | 主体类型：dark=暗色主体，light=亮色主体 |
| nat | 主体自然比例 |
| fill | 实际填充率 |
| OK | 纯逻辑可解（无需提示叉叉） |
| OK flips=N | 纯逻辑可解（翻转了N个格子） |
| HINTS(n) | 需要n个提示叉叉，可完全求解 |

### source_rect 计算

每个关卡在原图中的对应区域：

```
col_idx = puzzle_index % grid_x
row_idx = puzzle_index // grid_x
cell_w = original_image_width // grid_x
cell_h = original_image_height // grid_y

source_rect = {
    "x": col_idx * cell_w,
    "y": row_idx * cell_h,
    "width": cell_w,
    "height": cell_h
}
```

## 流程二：生成数织像素图

### 设计原则

数织像素图是原图的像素化版本，用于在游戏中展示数织完成后的效果。每个格子的颜色从原图对应位置采样，格子大小由对应关卡的难度决定。

### 生成算法

```python
def generate_nonogram_pixel_image(img_path, output_path, grid_x, grid_y, difficulties):
    img = Image.open(img_path).convert('RGBA')
    img_w, img_h = img.size
    
    block_w = img_w // grid_x
    block_h = img_h // grid_y
    img_array = np.array(img)
    
    # 输出尺寸与原图相同
    result_img = Image.new('RGB', (img_w, img_h), (255, 255, 255))
    
    for block_idx in range(grid_x * grid_y):
        bx = block_idx % grid_x
        by = block_idx // grid_x
        
        start_x = bx * block_w
        start_y = by * block_h
        block_array = img_array[start_y:start_y+block_h, start_x:start_x+block_w]
        
        size = difficulties[block_idx]  # 该区域的关卡难度（如5、10、15）
        cell_w = block_w / size         # 每个像素格的宽度（浮点数）
        cell_h = block_h / size         # 每个像素格的高度（浮点数）
        
        for r in range(size):
            for c in range(size):
                # 采样位置：格子中心点
                px = int(c * cell_w + cell_w / 2)
                py = int(r * cell_h + cell_h / 2)
                color = block_array[py, px][:3]  # 从原图获取颜色
                
                # 填充区域：格子对应的像素范围
                y_start = start_y + int(r * cell_h)
                y_end = start_y + int((r + 1) * cell_h)
                x_start = start_x + int(c * cell_w)
                x_end = start_x + int((c + 1) * cell_w)
                
                # 用原图颜色填充该格子
                for y in range(y_start, min(y_end, img_h)):
                    for x in range(x_start, min(x_end, img_w)):
                        result_img.putpixel((x, y), (int(color[0]), int(color[1]), int(color[2])))
    
    result_img.save(output_path)
```

### 关键设计要点

1. **输出尺寸与原图相同**：像素图的尺寸等于原图尺寸，不做缩放
2. **网格大小由关卡难度决定**：5×5关卡的区域分成5×5格，10×10关卡的区域分成10×10格，15×15关卡的区域分成15×15格
3. **颜色从原图获取**：每个格子的颜色取自原图对应位置的中心点像素
4. **浮点数精确计算**：使用浮点数计算格子坐标，避免白边和缝隙
5. **不同难度区域格子大小不同**：5×5区域每格128px，10×10区域每格64px，15×15区域每格约42px（以640px宽的分块为例）

### 像素图示例

4分块（image_grid = {x:2, y:2}），难度 [5, 10, 10, 15]：

```
原图 (1280×1280)
┌──────────┬──────────┐
│  5×5格   │  10×10格  │  每块 640×640
│  每格128px│  每格64px │
├──────────┼──────────┤
│  10×10格 │  15×15格  │
│  每格64px │  每格42px │
└──────────┴──────────┘
输出尺寸：1280×1280（与原图相同）
```

6分块（image_grid = {x:3, y:2}），难度 [5, 5, 10, 10, 15, 15]：

```
原图 (2496×1664)
┌──────────┬──────────┬──────────┐
│  5×5格   │  5×5格   │  10×10格  │  每块 832×832
├──────────┼──────────┼──────────┤
│  10×10格 │  15×15格 │  15×15格  │
└──────────┴──────────┴──────────┘
输出尺寸：2496×1664（与原图相同）
```

### 输出规格

| 属性 | 值 |
| ---- | -- |
| 文件命名 | `{图片ID}_nonogram_pixel.jpg` |
| 输出尺寸 | 与原图相同 |
| 颜色来源 | 从原图对应位置中心点采样 |
| 网格大小 | 由对应关卡的难度决定 |
| 分割线 | 无（分块间紧密拼接） |
| 白边 | 无（浮点数精确计算） |
| 文件格式 | JPG |

## 完整操作流程

### 生成指定画册的数织关卡

```powershell
# 生成指定画册的关卡
python tools/generate_nonogram.py {album_id}

# 示例
python tools/generate_nonogram.py cute_animals
python tools/generate_nonogram.py chinese_history
```

### 检查画册可解率

```powershell
# 检查单个画册的可解率
python tools/check_chinese_fast.py

# 修改脚本中的 base 变量可检查其他画册
```

## 动态难度设计

### 设计原则

1. **画册文档定义难度范围**：每张图片的难度范围由其所属章节决定，文档中设定最低和最高难度
2. **区域复杂度决定具体分配**：在同一张图片的多个分块中，根据每个区域的图像复杂度分配不同难度
3. **低复杂度→小网格，高复杂度→大网格**：内容简单的区域使用更小的网格，内容复杂的区域使用更大的网格

### 画册文档格式

画册文档（`docs/albums/{album_id}.md`）中定义每张图片的难度范围：

```markdown
### 动态难度策略

| 章节 | 难度范围 | 说明 |
| ---- | -------- | ---- |
| 第1章：萌宠乐园 | 5×5～10×10 | 前期关卡，从5×5开始逐步提升到10×10 |
| 第3章：森林精灵 | 5×5～15×15 | 后期关卡，从5×5开始逐步提升到15×15 |

### 图片内容规划

| 序号 | 章节 | 标题 | 文件名 | 难度范围 |
| ---- | ---- | ---- | ------ | -------- |
| 1 | 第1章 | 小猫 | cute_animals_000.jpg | 5×5～10×10 |
| 16 | 第3章 | 小鹿 | cute_animals_015.jpg | 5×5～15×15 |
```

### 难度分配流程

```
1. 读取画册文档
   │  解析每张图片所属章节 → 确定难度范围 [min_size, max_size]
   │
   ▼
2. 计算每个区域的复杂度
   │  边缘密度 + 信息熵 → 综合复杂度分数
   │
   ▼
3. 按复杂度排序
   │  低复杂度 → 小网格
   │  高复杂度 → 大网格
   │
   ▼
4. 在 [min_size, max_size] 范围内分配
   │  可用难度等级：5, 10, 15, 20, 25
   │  过滤出范围内的等级
   │  按复杂度排名均匀分配
   │
   ▼
输出每个区域的难度
```

### 不同分块数量的分配规则

#### 1分块（image_grid = {x:1, y:1}）

直接使用难度范围内的最大值：

| 难度范围 | 分配难度 |
| -------- | -------- |
| 5×5～5×5 | 5×5 |
| 5×5～10×10 | 10×10 |
| 5×5～15×15 | 15×15 |

#### 4分块（image_grid = {x:2, y:2}）

| 难度范围 | 低复杂度×2 | 高复杂度×2 |
| -------- | ---------- | ---------- |
| 5×5～10×10 | 5×5 | 10×10 |
| 5×5～15×15 | 5×5, 10×10 | 10×10, 15×15 |

#### 6分块（image_grid = {x:3, y:2}）

| 难度范围 | 低复杂度×2 | 中复杂度×2 | 高复杂度×2 |
| -------- | ---------- | ---------- | ---------- |
| 5×5～10×10 | 5×5 | 5×5, 10×10 | 10×10 |
| 5×5～15×15 | 5×5 | 10×10 | 15×15 |
| 5×5～20×20 | 5×5, 10×10 | 10×10, 15×15 | 15×15, 20×20 |

## 经验教训与注意事项

### 已解决的问题

| 问题 | 原因 | 解决方案 |
| ---- | ---- | -------- |
| 关卡解与原图形状不一致 | 使用固定阈值128分割 | 改为Otsu动态阈值+排名法 |
| 主体识别错误 | 始终假设暗色是主体 | 智能主体识别：比较暗色/亮色比例，自动判断主体类型 |
| 填充率固定40%不合理 | 颜色丰富和稀少的区域用同一比例 | 动态填充率，根据Otsu自然比例钳制到25%-65% |
| 空行/全满行无意义 | 排名法可能产生全空或全满的行列 | fix_empty_and_full_lines按亮度排名修复 |
| can_solve返回部分解 | 约束传播未完全确定时返回含-1的网格 | 始终使用adjusted_grid作为最终解，can_solve仅判断可解性 |
| 提示格重复添加 | 约束传播已确定的格子被再次添加 | 跳过已确定格子 |
| 大关卡提示格不足 | 固定上限15对20×20关卡不够 | 动态上限 `max(15, size²//2)` |
| 数织像素图有白色分割线 | 分块间绘制灰色分割线 | 删除分割线绘制代码，分块紧密拼接 |
| 数织像素图有白边/白色缝隙 | 整数除法导致像素块之间有未覆盖的白色缝隙 | 浮点数计算 + 精确坐标 |
| 排列生成算法Bug | base case 使用 `start <= length` 判断 | 改为 `len(current) <= length` |
| 生成速度极慢 | 深度试探算法每步复制和过滤更多排列 | 禁用深度试探（`max_depth=0`），只使用约束传播 |
| hint_cells重复 | 重试循环中重复调用不知道已有提示格 | 新增 `existing_hints` 参数，支持增量添加；保存前去重 |
| fully_solvable检查逻辑错误 | 用 `len(hint_cells) < max_h` 判断可解性 | 新增 `can_solve_with_hints` 函数 |
| 像素图尺寸与原图不一致 | 使用固定像素大小拼接 | 改为与原图相同尺寸，根据难度动态计算格子大小 |
| 像素图颜色不正确 | 使用黑白二值 | 改为从原图对应位置中心点采样真实颜色 |
| 难度分配固定 | 所有图片左上角都是5×5 | 根据区域复杂度动态分配难度 |
| RGBA无法保存为JPEG | JPEG不支持透明通道 | 添加 `img.convert('RGB')` 转换 |
| JSON BOM编码错误 | 文件含BOM头 | 使用 `encoding='utf-8-sig'` 读取 |
| 浅色主体在浅色背景上识别失败 | 颜色接近导致二值化效果差 | 新增边缘检测+连通区域分析，利用轮廓定位主体 |
| 全局Otsu阈值被边缘背景主导 | 大面积背景影响阈值计算 | 新增中心加权Otsu，更关注中心区域 |
| 云朵/太阳等亮色主体误判为暗色 | 主体颜色与背景颜色对比不明显 | 新增中心vs边缘主体类型判断 |
| 填充率过高导致关卡过于简单 | Otsu二值化后填充率>80% | 新增填充率上限钳制，超过65%时移除最不确定的格子 |
| 边缘检测总是执行，影响速度 | 所有图片都执行边缘检测 | 改为仅当Otsu填充率<15%时才执行边缘检测作为回退 |

### 经验与教训

1. **Otsu阈值必须在原始高分辨率图像上计算**：在下采样后的5×5网格（仅25个采样点）上计算Otsu阈值，会导致所有格子被判定为同一类（fill=0%或fill=100%）。必须在原始高分辨率图像上计算阈值，然后下采样到目标网格。

2. **排名填充法会破坏形状**：旧的 `generate_grid_by_ranking_with_subject` 按亮度排名后取前N%的像素作为填充格，这会破坏原始形状的连续性。例如，空心正方形的边框可能被排名法拆散。正确做法是用Otsu二值化直接提取主体形状。

3. **少数派优先不适用于所有图形**：少数派优先假设"主体总是占少数"，但对空心图形（如空心正方形，边框占64%）不适用。峰值背景检测通过识别背景颜色来解决这个问题。

4. **翻转过度会破坏形状**：旧算法最多翻转 `size²//3` 个格子（15×15网格=75次翻转），严重破坏原始形状。新算法限制翻转数量为 `min(10, max(3, size²//20))`，并优先使用提示叉叉。

5. **fix_empty_and_full_lines 会修改形状**：全空行/全满行在数织中是完全合法的（线索为[0]或[size]），不需要修复。修改它们会破坏原始形状。

6. **提示叉叉优先于翻转**：提示叉叉只标记空白格，不改变解的形状，应优先使用。翻转是最后手段，应严格限制数量。

7. **区域平均采样优于中心点采样**：中心点采样在高对比度边界处可能采到错误的值，区域平均更稳定。
