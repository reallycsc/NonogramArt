# 数织关卡生成 Skill

## 概述

从原图自动生成数织（Nonogram）关卡和彩色像素图。核心原则：**优先填充亮度更低的像素格**，填充率根据原图颜色含量动态变化，**所有关卡必须可纯逻辑求解**。

完整流程：原图 → 亮度提取 → 动态填充率计算 → 排名生成网格 → 空满行修复 → 线索计算 → 可解性验证 → 网格翻转修复 → 提示格生成（兜底） → 关卡JSON + 彩色像素图 + 黑白数织图。

## 工具与依赖

| 依赖 | 说明 |
| ---- | ---- |
| Python 3.11 | 运行生成脚本 |
| PIL/Pillow | 图片处理 |
| NumPy | 数值计算 |
| 生成脚本 | `tools/fix_all_dynamic_optimized.py`（最新优化版本） |

## 数据结构

### 图片配置文件

`data/pictures/{album_id}.json` 中每张图片的配置：

**image_grid = {x:3, y:2}（6分块）示例**：

```json
{
  "id": "chapter1_01_yuanmou",
  "image": "res://assets/images/illustrations/chinese_history/chapter1_01_yuanmou.jpg",
  "nonogram_pixel_image": "res://assets/images/illustrations/chinese_history/chapter1_01_yuanmou_nonogram_pixel.jpg",
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
  "nonogram_pixel_image": "res://assets/images/illustrations/geometric_shapes/geometric_shapes_000_nonogram_pixel.jpg",
  "image_grid": { "x": 1, "y": 1 },
  "puzzles": [
    "geometric_shapes_000_0"
  ]
}
```

**image_grid = {x:2, y:2}（4分块）示例**：

```json
{
  "id": "future_album_000",
  "image": "res://assets/images/illustrations/future_album/future_album_000.jpg",
  "nonogram_pixel_image": "res://assets/images/illustrations/future_album/future_album_000_nonogram_pixel.jpg",
  "image_grid": { "x": 2, "y": 2 },
  "puzzles": [
    "future_album_000_0",
    "future_album_000_1",
    "future_album_000_2",
    "future_album_000_3"
  ]
}
```

### 关卡文件

`data/puzzles/{album_id}/{puzzle_id}.json`：

```json
{
  "id": "chapter1_01_yuanmou_0",
  "name": "元谋人遗址-分块0",
  "picture_id": "chapter1_01_yuanmou",
  "size": { "rows": 5, "cols": 5 },
  "difficulty": "tutorial",
  "row_clues": [[1, 2], [2], [2], [2, 1], [4]],
  "col_clues": [[4], [4], [1, 1], [1, 1], [2]],
  "solution": [[1,0,1,1,0], [1,1,0,0,0], [1,1,0,0,0], [1,1,0,0,1], [0,1,1,1,1]],
  "hint_cells": [],
  "source_rect": { "x": 0, "y": 0, "w": 832, "h": 832 }
}
```

### 字段说明

| 字段 | 类型 | 说明 |
| ---- | ---- | ---- |
| id | string | 关卡唯一标识，格式 `{picture_id}_{分块序号}` |
| name | string | 关卡名称，格式 `{图片标题}-分块{序号}` |
| picture_id | string | 所属图片ID |
| size | object | 网格尺寸，rows = cols（正方形） |
| difficulty | string | 难度：tutorial/easy/medium/hard/expert |
| row_clues | int[][] | 行线索，空行为 [0] |
| col_clues | int[][] | 列线索，空列为 [0] |
| solution | int[][] | 解网格，1=填充，0=空白 |
| hint_cells | int[][] | 提示叉叉坐标列表，每项 [row, col]，仅包含 solution=0 的格子，游戏初始化时显示为X标记 |
| source_rect | object | 对应彩色像素图的区域 {x, y, w, h} |

## 关卡大小与难度映射

| grid_size | difficulty | 拼接网格(3×2分块) | 拼接网格(2×2分块) | 拼接网格(1×1分块) | 适用章节 |
| --------- | ---------- | ------------------ | ------------------ | ------------------ | -------- |
| 5 | tutorial | 15×10 | 10×10 | 5×5 | 第1章 |
| 10 | easy | 30×20 | 20×20 | 10×10 | 第2-5章 |
| 15 | medium | 45×30 | 30×30 | 15×15 | 第6-9章 |
| 20 | hard | 60×40 | 40×40 | 20×20 | 第10-11章 |
| 25 | expert | 75×50 | 50×50 | 25×25 | 预留 |

## 流程一：生成数织关卡与彩色像素图

### 运行命令

```powershell
# 生成单个画册的关卡
python tools/fix_all_dynamic_optimized.py {album_id}

# 示例：生成中国通史画册
python tools/fix_all_dynamic_optimized.py chinese_history

# 示例：生成世界历史画册
python tools/fix_all_dynamic_optimized.py world_history

# 指定范围生成（用于调试）
python tools/fix_all_dynamic_optimized.py chinese_history --start 0 --end 10
```

### 完整算法流程

```
原图
    │
    ▼
1. 亮度提取 (extract_cell_brightness)
    │  将原图按 image_grid(X×Y) 分块
    │  每块按 puzzle_size(N×N) 采样
    │  计算每个格子的平均亮度 → [(row, col, brightness), ...]
    │
    ▼
2. 动态填充率计算 (compute_dynamic_fill_rate)
    │  Otsu阈值 → 自然暗像素比例(natural_rate)
    │  钳制到 [0.25, 0.65] → fill_rate
    │
    ▼
3. 排名生成网格 (generate_grid_by_ranking)
    │  按亮度升序排列所有格子
    │  填充前 fill_rate 比例的格子（最暗的优先）
    │
    ▼
4. 空满行修复 (fix_empty_and_full_lines)
    │  对全空行：填充该行最暗的 size//3 个格子
    │  对全满行：清除该行最亮的 size//3 个格子
    │  对全空列/全满列：同理处理
    │
    ▼
5. 线索计算 (compute_clues)
    │  从网格提取行/列连续填充数
    │  空行/空列 → [0]
    │
    ▼
6. 可解性验证 (can_solve)
    │  约束传播算法（_propagate）
    │  深度1试探算法（_probe）
    │  返回是否纯逻辑可解
    │
    ▼
7. 网格翻转修复 (make_solvable, 仅不可解时)
    │  翻转未知格子使关卡可纯逻辑求解
    │  优先翻转"填充未知格"（solution=1但求解后仍为-1）
    │  亮度接近阈值的格子优先（视觉偏差最小）
    │  时间限制：10秒
    │
    ▼
8. 提示叉叉生成 (find_hint_cells, 兜底机制)
    │  只标记 solution=0 的空白格（X标记）
    │  贪心策略：选择解决未知格最多的位置
    │  支持增量提示（在已有提示基础上继续添加）
    │  提示数量限制：max(15, size²/2)
    │
    ▼
输出关卡JSON文件
```

### 步骤详解

#### 1. 亮度提取

将原图按 `image_grid`（X列×Y行）分成 X×Y 个区域，每个区域对应一个关卡。在每个区域内，按 `puzzle_size`（N×N）采样，计算每个格子的平均亮度值。

**image_grid = {x:3, y:2}（6分块）示例**：

```
原图 (2496×1664)
┌──────────┬──────────┬──────────┐
│  block0  │  block1  │  block2  │  每块 832×832
│  5×5采样  │  5×5采样  │  5×5采样  │  → 25个亮度值
├──────────┼──────────┼──────────┤
│  block3  │  block4  │  block5  │
│  5×5采样  │  5×5采样  │  5×5采样  │
└──────────┴──────────┴──────────┘
```

**image_grid = {x:2, y:2}（4分块）示例**：

```
原图 (1280×1280)
┌──────────┬──────────┐
│  block0  │  block1  │  每块 640×640
│  5×5采样  │  5×5采样  │  → 25个亮度值
├──────────┼──────────┤
│  block2  │  block3  │
│  5×5采样  │  5×5采样  │
└──────────┴──────────┘
```

**image_grid = {x:1, y:1}（1分块）示例**：

```
原图 (1280×1280)
┌────────────────────┐
│      block0        │  整图 1280×1280
│      5×5采样        │  → 25个亮度值
└────────────────────┘
```

采样方式：将每块区域等分为 N×N 个子区域，计算每个子区域内所有像素的 RGB 平均值，再取三通道均值作为亮度。

#### 2. 动态填充率计算

**核心原则：颜色多的原图填充率高，颜色少的填充率低。**

使用 Otsu 阈值算法自动确定亮度分割点：

1. 将亮度值构建256-bin直方图
2. 遍历所有可能阈值，计算类间方差
3. 取方差最大的阈值作为分割点
4. 统计低于阈值的像素比例 = natural_rate
5. 钳制到 [0.25, 0.65] 得到 fill_rate

| 参数 | 值 | 说明 |
| ---- | -- | ---- |
| 填充率下限 | 0.25 | 避免关卡过于稀疏 |
| 填充率上限 | 0.65 | 避免关卡过于密集 |

**示例**：
- 颜色丰富的区域：natural_rate=68% → fill_rate=65%（上限）
- 颜色适中的区域：natural_rate=40% → fill_rate=40%
- 颜色稀少的区域：natural_rate=12% → fill_rate=25%（下限）

#### 3. 排名生成网格

将所有 N×N 个格子按亮度升序排列（最暗的排最前），填充前 `fill_rate × N²` 个格子。

**关键**：这确保了数织解的形状与原图的明暗分布一致——暗区域填充，亮区域留空。

#### 4. 空满行修复

数织规则要求每行/列至少有一个线索（不能全空或全满）。修复策略：

| 情况 | 处理方式 | 填充/清除数量 |
| ---- | -------- | ------------- |
| 全空行 | 填充该行亮度最低的格子 | max(1, size//3) |
| 全满行 | 清除该行亮度最高的格子 | max(1, size//3) |
| 全空列 | 填充该列亮度最低的格子 | max(1, size//3) |
| 全满列 | 清除该列亮度最高的格子 | max(1, size//3) |

修复后仍保持"暗优先"原则——需要填充时选最暗的，需要清除时选最亮的。

#### 5. 线索计算

从网格提取标准数织线索：
- 行线索：每行从左到右统计连续填充块数
- 列线索：每列从上到下统计连续填充块数
- 空行/空列的线索为 `[0]`

#### 6. 可解性验证

使用约束传播（Constraint Propagation）+ 深度试探（Probing）算法验证关卡是否可纯逻辑求解：

1. 为每行/列生成所有可能的排列（`_generate_line_arrangements_cached`，带LRU缓存）
2. 约束传播（`_propagate`）：迭代过滤与已知格子矛盾的排列，对所有排列一致的格子确定其值
3. 深度试探（`_probe`）：对未确定格尝试两种值，若某值导致矛盾则确定另一值；若两种值推出的结果有交集则确定交集部分
4. 时间限制：30秒（防止复杂关卡卡住）

**自适应试探深度**：
| 网格大小 | 最大试探深度 |
| -------- | ------------ |
| ≤10×10 | max_depth=3 |
| ≤15×15 | max_depth=2 |
| >15×15 | max_depth=1 |

**重要**：`can_solve` 仅用于判断是否需要修复，**不修改解网格**。解始终使用从原图生成的 `adjusted_grid`（或翻转修复后的网格）。

#### 7. 网格翻转修复（make_solvable）

当关卡不可纯逻辑求解时，**优先翻转格子使关卡可解**，而非添加提示格。翻转比提示格更优因为：
- 玩家无需任何预揭示信息
- 翻转后的网格仍保持视觉一致性
- 特别适合小网格（5×5、10×10），提示格在小网格中过于明显

**算法流程**：
1. 运行 `can_solve` 获取当前未确定的格子列表
2. 优先收集"填充未知格"（solution=1 但求解后仍为 -1 的格子），这些格子翻转后可以标记为提示叉叉
3. 对候选格子按亮度接近阈值的程度排序（视觉偏差最小）
4. 两阶段评估：
   - 阶段1：快速约束传播筛选（`_quick_propagate`）
   - 阶段2：深度试探精确评估（`_count_unknown_after_solve`）
5. 选择使"剩余未知格子数"最少的翻转（评分最优）
6. 翻转后修复可能产生的空行/空列（`_fix_empty_full_lines`）
7. 重复直到可解或达到翻转上限

**翻转上限策略**：
| 网格大小 | 最大翻转数 | 时间限制 |
| -------- | ---------- | -------- |
| ≤10×10 | size²/3 | 10秒 |
| >10×10 | size²/3 | 10秒 |

**亮度惩罚**：翻转时优先选择亮度接近阈值的格子（`brightness_penalty = abs(brightness - threshold) / threshold`），使视觉偏差最小。

**填充格奖励**：优先翻转填充格而非空白格，因为填充格翻转后可以标记为提示叉叉（`filled_bonus = -size * 0.5`）。

#### 8. 提示叉叉生成（兜底机制）

当翻转修复仍无法使关卡可解时，通过逐步标记空白格（X标记）来辅助求解：

**设计原则**：提示叉叉只标记 solution=0 的格子（空白格），游戏初始化时这些格子显示为X标记状态，告诉玩家"这个格子一定是空的"。不标记 solution=1 的填充格，避免直接揭示答案。

**算法流程**：
1. 初始化网格，将已有提示叉叉设为已知空格（值为0）
2. 运行约束传播和深度试探
3. 如果完全可解，结束
4. 找到所有 solution=0 的未知格（空白格候选）
5. 贪心评估：选择所在行列未确定格最少的格子（约束效果最强）
6. 逐一标记为提示叉叉，每标记一个后重新约束传播
7. 跳过已被传播确定的格子
8. 直到完全可解或达到提示叉叉上限

**提示叉叉上限**：`max(15, size × size // 2)`

| 关卡大小 | 提示叉叉上限 |
| -------- | ---------- |
| 5×5 | 15 |
| 10×10 | 50 |
| 15×15 | 112 |
| 20×20 | 200 |
| 25×25 | 312 |

**支持增量提示**：`find_hint_cells` 函数支持 `existing_hints` 参数，在已有提示基础上继续添加，避免重复。

**去重机制**：保存前对 hint_cells 去重，防止重试循环中重复添加相同的提示格。

### 输出格式

运行时逐行输出每个关卡的状态：

```
[1] chapter1_01_yuanmou_0 (5x5) nat=68% fill=56% OK [0.4s]
[2] chapter1_01_yuanmou_1 (5x5) nat=32% fill=44% OK flips=1 [0.8s]
[3] chapter1_04_hemudu_3 (10x10) nat=32% fill=38% HINTS(9) [8.8s]
```

| 字段 | 说明 |
| ---- | ---- |
| nat | Otsu自然暗像素比例 |
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
    "w": cell_w,
    "h": cell_h
}
```

## 流程二：生成黑白数织图

**注意**：黑白数织图由 `generate_nonogram_image` 函数在主生成流程中同步生成，无需单独运行脚本。

### 算法流程

```
关卡JSON文件(X×Y个)
    │
    ▼
1. 读取每个关卡的 solution 网格
    │
    ▼
2. 按 image_grid(X×Y) 排列拼接
    │  3×2: puzzle_0 | puzzle_1 | puzzle_2
    │       ---------+----------+---------
    │       puzzle_3 | puzzle_4 | puzzle_5
    │  2×2: puzzle_0 | puzzle_1
    │       ---------+---------
    │       puzzle_2 | puzzle_3
    │  1×1: puzzle_0
    │
    ▼
3. 生成黑白像素图
    │  solution=1 → 黑色(0,0,0)
    │  solution=0 → 白色(255,255,255)
    │  每格 40×40 像素
    │
    ▼
_nonogram.jpg
```

### 拼接规则

关卡按 `image_grid`（X列×Y行）排列：

```
puzzle_index → (col, row)
col = puzzle_index % grid_x
row = puzzle_index // grid_x

像素坐标：
x = (col * puzzle_size + cell_col) * pixel_size
y = (row * puzzle_size + cell_row) * pixel_size
```

### 输出规格

| 属性 | 值 |
| ---- | -- |
| 文件命名 | `{图片ID}_nonogram.jpg` |
| 输出目录 | 与原图同一目录 |
| 像素块大小 | 40×40px |
| 填充格颜色 | 黑色 (0,0,0) |
| 空白格颜色 | 白色 (255,255,255) |
| 文件格式 | JPG（quality=95） |

### 各关卡大小对应的输出尺寸

image_grid = {x:3, y:2}（6分块）：

| puzzle_size | 拼接网格 | 图片尺寸 |
| ----------- | -------- | -------- |
| 5 | 15×10 | 600×400 |
| 10 | 30×20 | 1200×800 |
| 15 | 45×30 | 1800×1200 |
| 20 | 60×40 | 2400×1600 |
| 25 | 75×50 | 3000×2000 |

image_grid = {x:2, y:2}（4分块）：

| puzzle_size | 拼接网格 | 图片尺寸 |
| ----------- | -------- | -------- |
| 5 | 10×10 | 400×400 |
| 10 | 20×20 | 800×800 |
| 15 | 30×30 | 1200×1200 |
| 20 | 40×40 | 1600×1600 |
| 25 | 50×50 | 2000×2000 |

image_grid = {x:1, y:1}（1分块）：

| puzzle_size | 拼接网格 | 图片尺寸 |
| ----------- | -------- | -------- |
| 5 | 5×5 | 200×200 |
| 10 | 10×10 | 400×400 |
| 15 | 15×15 | 600×600 |

## 完整操作流程

### 生成单个画册的数织关卡

```powershell
# 生成单个画册的关卡
python tools/fix_all_dynamic_optimized.py {album_id}

# 示例
python tools/fix_all_dynamic_optimized.py chinese_history
```

### 检查画册可解率

```powershell
# 检查单个画册的可解率（快速版，使用深度1试探）
python tools/check_chinese_fast.py

# 修改脚本中的 base 变量可检查其他画册
```

## 动态难度设计

### 设计原则

同一张图片的多个分块根据内容复杂度分配不同难度。内容复杂的区域使用更大的网格（更多细节），内容简单的区域使用更小的网格（更易完成）。分块数量由 image_grid 决定（1×1=1块，2×2=4块，3×2=6块）。

### 难度分配规则

6分块（image_grid = {x:3, y:2}）：

| 图片难度 | 低复杂度分块 | 中复杂度分块 | 高复杂度分块 |
| -------- | ------------ | ------------ | ------------ |
| 10×10 | 5×5 | 5×5 | 10×10 |
| 15×15 | 5×5 | 10×10 | 15×15 |
| 20×20 | 10×10 | 15×15 | 20×20 |
| 25×25 | 15×15 | 20×20 | 25×25 |

4分块（image_grid = {x:2, y:2}）：

| 图片难度 | 低复杂度分块 | 中复杂度分块 | 高复杂度分块 |
| -------- | ------------ | ------------ | ------------ |
| 10×10 | 5×5 | 10×10 | 10×10 |
| 15×15 | 5×5 | 10×10 | 15×15 |
| 20×20 | 10×10 | 15×15 | 20×20 |
| 25×25 | 15×15 | 20×20 | 25×25 |

1分块（image_grid = {x:1, y:1}）：

| 图片难度 | 该分块难度 |
| -------- | ---------- |
| 5×5 | 5×5 |
| 10×10 | 10×10 |
| 15×15 | 15×15 |

### 复杂度计算 (analyze_block_complexity)

```python
def analyze_block_complexity(img, grid_x, grid_y, block_index, sample_size=20):
    # 1. 提取分块区域
    # 2. 采样像素计算：
    #    - 像素多样性：unique_pixels / total_pixels
    #    - 亮度方差：brightness_variance / 1000
    #    - 边缘密度：edge_density
    # 3. 综合复杂度 = 多样性×0.4 + 方差×0.3 + 边缘×0.3
```

### 动态难度分配流程 (get_difficulty_sizes)

根据 image_grid 的分块数量选择对应的难度分配函数：

```python
def get_difficulty_sizes(max_size, num_blocks):
    if num_blocks == 6:
        return get_difficulty_sizes_6block(max_size)
    elif num_blocks == 4:
        return get_difficulty_sizes_4block(max_size)
    elif num_blocks == 1:
        return [max_size]
    else:
        raise ValueError(f"Unsupported num_blocks: {num_blocks}")

def get_difficulty_sizes_6block(max_size):
    if max_size <= 5:
        return [5, 5, 5, 5, 5, 5]
    elif max_size <= 10:
        return [5, 5, 5, 10, 10, 10]
    elif max_size <= 15:
        return [5, 5, 10, 10, 15, 15]
    elif max_size <= 20:
        return [10, 10, 15, 15, 20, 20]
    else:
        return [15, 15, 20, 20, 25, 25]

def get_difficulty_sizes_4block(max_size):
    if max_size <= 5:
        return [5, 5, 5, 5]
    elif max_size <= 10:
        return [5, 10, 10, 10]
    elif max_size <= 15:
        return [5, 10, 10, 15]
    elif max_size <= 20:
        return [10, 15, 15, 20]
    else:
        return [15, 20, 20, 25]
```

### 基础难度配置

每本画册的关卡难度规划定义在 `get_base_difficulty` 函数中：

```python
def get_base_difficulty(album_id, pic_idx):
    size_map = {
        'chinese_history': [
            (0, 1, 5),    # 第1张：5×5
            (1, 23, 10),  # 序号1-22：10×10
            (23, 38, 15), # 序号23-37：15×15
            (38, 77, 20), # 序号38-76：20×20
            (77, 105, 25) # 序号77-104：25×25
        ],
        # ... 其他画册配置
    }
```

## 数织像素图 (_nonogram_pixel.jpg)

### 生成方式

**直接生成**：`generate_pixel_image` 函数按动态难度网格从原图采样颜色，直接生成 `{id}_nonogram_pixel.jpg`。

### 设计要求

- **无分割线**：多个分块之间不绘制任何分割线，像素块紧密拼接
- **无白边**：使用浮点数精确计算像素块坐标（`round()`），确保每个像素块无缝覆盖，不留白色缝隙
- **黑色画布初始化**：使用 `np.zeros()` 初始化画布，避免白色底色透出

### 像素块坐标计算

```python
cell_w = img_width / image_grid_x   # 浮点数精确计算
cell_h = img_height / image_grid_y

pixel_w = block_w / puzzle_size
pixel_h = block_h / puzzle_size

dst_x0 = int(round(x0_f + c * pixel_w))    # round() 确保无缝拼接
dst_y0 = int(round(y0_f + r * pixel_h))
dst_x1 = int(round(x0_f + (c + 1) * pixel_w))
dst_y1 = int(round(y0_f + (r + 1) * pixel_h))
```

### 输出规格

| 属性 | 值 |
| ---- | -- |
| 文件命名 | `{图片ID}_nonogram_pixel.jpg` |
| 颜色来源 | 按动态难度网格从原图采样 |
| 分割线 | 无（分块间紧密拼接，不绘制分割线） |
| 白边 | 无（浮点数精确计算，无缝隙） |
| 文件格式 | JPG（quality=95） |

## 经验教训与注意事项

### 已解决的问题

| 问题 | 原因 | 解决方案 |
| ---- | ---- | -------- |
| 关卡解与原图形状不一致 | 使用固定阈值128分割 | 改为Otsu动态阈值+排名法 |
| 填充率固定40%不合理 | 颜色丰富和稀少的区域用同一比例 | 动态填充率，根据Otsu自然比例钳制到25%-65% |
| 空行/全满行无意义 | 排名法可能产生全空或全满的行列 | fix_empty_and_full_lines按亮度排名修复 |
| can_solve返回部分解 | 约束传播未完全确定时返回含-1的网格 | 始终使用adjusted_grid作为最终解，can_solve仅判断可解性 |
| 提示格重复添加 | 约束传播已确定的格子被再次添加 | 添加 `if grid[r][c] != -1: continue` 跳过已确定格子 |
| 大关卡提示格不足 | 固定上限15对20×20关卡不够 | 动态上限 `max(15, size²//2)` |
| 数织像素图有白色分割线 | 分块间绘制灰色分割线 | 删除分割线绘制代码，分块紧密拼接 |
| 数织像素图有白边/白色缝隙 | 整数除法导致像素块之间有未覆盖的白色缝隙 | 浮点数计算 `cell_w = img_width / image_grid_x` + `round()` + `np.zeros()` |
| **排列生成算法Bug** | `_generate_line_arrangements` 的 base case 使用 `start <= length` 判断，导致某些线索（如[1,2]在5格中）只生成1个排列而非3个 | 改为 `len(current) <= length`，直接检查当前排列的实际长度 |
| **生成速度极慢** | 排列数量增加后，深度试探算法每步复制和过滤更多排列 | 禁用深度试探（`max_depth=0`），只使用约束传播，添加时间限制 |
| **hint_cells重复** | 重试循环中重复调用 `find_hint_cells` 不知道已有提示格 | 新增 `existing_hints` 参数，支持增量添加；保存前去重 |
| **fully_solvable检查逻辑错误** | 用 `len(hint_cells) < max_h` 判断可解性 | 新增 `can_solve_with_hints` 函数，正确验证含hint_cells的可解性 |
| **生成时make_solvable超时** | 每个翻转候选都运行完整can_solve | 添加时间限制（10秒），减少评估候选数量 |

### 关键设计决策

1. **排名法优于阈值法**：按亮度排名填充比固定阈值分割更能保留原图的视觉特征
2. **动态填充率优于固定填充率**：颜色多的区域自然需要更多填充格
3. **翻转修复优于提示叉叉**：翻转使关卡可纯逻辑求解，玩家无需预揭示信息；提示叉叉仅作兜底
4. **排列生成必须完整**：`_generate_line_arrangements` 的 base case 必须使用 `len(current) <= length`，否则会导致约束传播不完整
5. **提示叉叉策略**：只标记 solution=0 的空白格（显示为X），不标记填充格，避免直接揭示答案；优先标记约束传播效果最强的空白格
6. **生成速度优化**：禁用深度试探（`max_depth=0`），只使用约束传播，大幅提高生成速度
7. **时间限制保护**：所有耗时操作都有时间限制，防止单个关卡卡住整个流程

### 性能参考

| 操作 | 数量 | 耗时 |
| ---- | ---- | ---- |
| 生成630个关卡（chinese_history，含_probe+行/列揭示） | 630 | 约993秒 |
| 生成105张拼接图 | 105 | 约30秒 |

### 可解性统计（修复排列Bug后）

修复排列生成Bug后，可解率大幅提升：

| 网格大小 | 总数 | 纯逻辑可解 | 需提示叉叉 | 可解率 |
| -------- | ---- | ---------- | ---------- | ------ |
| 5×5 | 102 | 102 | 0 | **100%** |
| 10×10 | 174 | 174 | 0 | **100%** |
| 15×15 | 164 | 163 | 1 | **99.4%** |
| 20×20 | 134 | 133 | 1 | **99.3%** |
| 25×25 | 56 | 55 | 1 | **98.2%** |
| **合计** | **630** | **627** | **3** | **99.5%** |

检查脚本：`tools/check_chinese_fast.py`（使用约束传播 + 深度1试探）

### 验证关卡

```powershell
# 查看某个关卡的解网格
python -c "
import json
with open(r'data\puzzles\chinese_history\chapter1_01_yuanmou_0.json', 'r', encoding='utf-8') as f:
    d = json.load(f)
for row in d['solution']:
    print(''.join('█' if c else '·' for c in row))
"

# 检查画册可解率
python tools/check_chinese_fast.py
```

### 检查其他画册可解率

修改 `tools/check_chinese_fast.py` 中的 `base` 变量：

```python
base = r"H:\Work\MyProject\NonogramArt\data\puzzles\{album_id}"
```

然后运行：

```powershell
python tools/check_chinese_fast.py
```
