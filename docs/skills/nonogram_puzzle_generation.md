# 数织关卡生成与拼接像素图 Skill

## 概述

从像素图（_pixel.jpg）自动生成数织（Nonogram）关卡，并将所有关卡的解拼接为完整的数织拼接像素图（_nonogram.jpg）。核心原则：**优先填充亮度更低的像素块**，填充率根据像素图颜色含量动态变化。

完整流程：像素图 → 亮度提取 → 动态填充率计算 → 排名生成网格 → 空满行修复 → 线索计算 → 可解性验证 → 提示格生成 → 关卡JSON → 拼接像素图。

## 工具与依赖

| 依赖 | 说明 |
| ---- | ---- |
| Python 3.11 | 运行生成脚本，路径 `C:\Python311\python.exe` |
| PIL/Pillow | 图片处理 |
| 关卡脚本 | `tools/fix_all_dynamic.py` |
| 拼接脚本 | `tools/gen_nonogram_image.py` |

## 数据结构

### 图片配置文件

`data/pictures/{album_id}.json` 中每张图片的配置：

```json
{
  "id": "chapter1_01_yuanmou",
  "image": "res://assets/images/illustrations/chinese_history/chapter1_01_yuanmou.jpg",
  "pixel_image": "res://assets/images/illustrations/chinese_history/chapter1_01_yuanmou_pixel.jpg",
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
| hint_cells | int[][] | 提示格坐标列表，每项 [row, col] |
| source_rect | object | 对应像素图的区域 {x, y, w, h} |

## 关卡大小与难度映射

| grid_size | difficulty | 拼接网格(3×2分块) | 适用章节 |
| --------- | ---------- | ------------------ | -------- |
| 5 | tutorial | 15×10 | 第1章 |
| 10 | easy | 30×20 | 第2-5章 |
| 15 | medium | 45×30 | 第6-9章 |
| 20 | hard | 60×40 | 第10-11章 |
| 25 | expert | 75×50 | 预留 |

## 流程一：生成数织关卡

### 运行命令

```powershell
C:\Python311\python.exe -u tools\fix_all_dynamic.py
```

### 完整算法流程

```
像素图(_pixel.jpg)
    │
    ▼
1. 亮度提取 (extract_cell_brightness)
    │  将像素图按 image_grid(3×2) 分块
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
    │  约束传播算法
    │  返回是否纯逻辑可解
    │
    ▼
7. 提示格生成 (find_hint_cells, 仅不可解时)
    │  逐步揭示约束传播卡住的格子
    │  每揭示一个 → 重新约束传播
    │  直到完全可解或达到提示格上限
    │
    ▼
关卡JSON文件
```

### 步骤详解

#### 1. 亮度提取

将像素图按 `image_grid`（3列×2行）分成6个区域，每个区域对应一个关卡。在每个区域内，按 `puzzle_size`（N×N）采样，计算每个格子的平均亮度值。

```
像素图 (2496×1664)
┌──────────┬──────────┬──────────┐
│  block0  │  block1  │  block2  │  每块 832×832
│  5×5采样  │  5×5采样  │  5×5采样  │  → 25个亮度值
├──────────┼──────────┼──────────┤
│  block3  │  block4  │  block5  │
│  5×5采样  │  5×5采样  │  5×5采样  │
└──────────┴──────────┴──────────┘
```

采样方式：将每块区域等分为 N×N 个子区域，计算每个子区域内所有像素的 RGB 平均值，再取三通道均值作为亮度。

#### 2. 动态填充率计算

**核心原则：颜色多的像素图填充率高，颜色少的填充率低。**

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

**关键**：这确保了数织解的形状与像素图的明暗分布一致——暗区域填充，亮区域留空。

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

使用约束传播（Constraint Propagation）算法验证关卡是否可纯逻辑求解：

1. 为每行/列生成所有可能的排列
2. 迭代过滤不可能的排列
3. 对所有排列一致的格子确定其值
4. 重复直到无新格子可确定

**重要**：`can_solve` 仅用于判断是否需要提示格，**不修改解网格**。解始终使用从像素图生成的 `adjusted_grid`。

#### 7. 提示格生成

当关卡不可纯逻辑求解时，通过逐步揭示格子来辅助求解：

1. 找到约束传播卡住的格子（值为-1）
2. 按所在行列的未确定格子数排序（少的优先，约束传播效果更强）
3. 逐一揭示，每揭示一个后重新约束传播
4. 跳过已被传播确定的格子
5. 直到完全可解或达到提示格上限

提示格上限：`max(15, size × size // 4)`

| 关卡大小 | 提示格上限 |
| -------- | ---------- |
| 5×5 | 15 |
| 10×10 | 25 |
| 15×15 | 56 |
| 20×20 | 100 |

### 输出格式

运行时逐行输出每个关卡的状态：

```
[1] chapter1_01_yuanmou_0 (5x5) nat=68% fill=56% OK [0.4s]
[2] chapter1_01_yuanmou_2 (5x5) nat=48% fill=48% HINTS(5) [1.1s]
```

| 字段 | 说明 |
| ---- | ---- |
| nat | Otsu自然暗像素比例 |
| fill | 实际填充率 |
| OK | 纯逻辑可解 |
| HINTS(n) | 需要n个提示格，可完全求解 |
| PARTIAL(n) | 达到提示格上限仍未完全求解（需增加上限） |

### source_rect 计算

每个关卡在像素图中的对应区域：

```
col_idx = puzzle_index % grid_x
row_idx = puzzle_index // grid_x
cell_w = pixel_image_width // grid_x
cell_h = pixel_image_height // grid_y

source_rect = {
    "x": col_idx * cell_w,
    "y": row_idx * cell_h,
    "w": cell_w,
    "h": cell_h
}
```

## 流程二：生成数织拼接像素图

### 运行命令

```powershell
C:\Python311\python.exe -u tools\gen_nonogram_image.py
```

### 算法流程

```
关卡JSON文件(6个)
    │
    ▼
1. 读取每个关卡的 solution 网格
    │
    ▼
2. 按 image_grid(3×2) 排列拼接
    │  puzzle_0 | puzzle_1 | puzzle_2
    │  ---------+----------+---------
    │  puzzle_3 | puzzle_4 | puzzle_5
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

6个关卡按 `image_grid`（3列×2行）排列：

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
| 文件命名 | `{原像素图名}_nonogram.jpg`（将 `_pixel` 替换为 `_nonogram`） |
| 输出目录 | 与像素图同一目录 |
| 像素块大小 | 40×40px |
| 填充格颜色 | 黑色 (0,0,0) |
| 空白格颜色 | 白色 (255,255,255) |
| 文件格式 | JPG（quality=95） |

### 各关卡大小对应的输出尺寸

| puzzle_size | 拼接网格 | 图片尺寸 |
| ----------- | -------- | -------- |
| 5 | 15×10 | 600×400 |
| 10 | 30×20 | 1200×800 |
| 15 | 45×30 | 1800×1200 |
| 20 | 60×40 | 2400×1600 |
| 25 | 75×50 | 3000×2000 |

## 完整操作流程

### 从零开始生成所有关卡和拼接图

```powershell
# 步骤1：生成所有数织关卡（约5分钟）
C:\Python311\python.exe -u tools\fix_all_dynamic.py

# 步骤2：生成所有数织拼接像素图（约30秒）
C:\Python311\python.exe -u tools\gen_nonogram_image.py
```

### 仅重新生成某张图的关卡

修改 `fix_all_dynamic.py` 中的循环范围，或创建针对单图的脚本（参考 `fix_ch1_dynamic.py`）。

### 验证关卡

```powershell
# 查看某个关卡的解网格
C:\Python311\python.exe -c "
import json
with open(r'data\puzzles\chinese_history\chapter1_01_yuanmou_0.json', 'r', encoding='utf-8') as f:
    d = json.load(f)
for row in d['solution']:
    print(''.join('█' if c else '·' for c in row))
"
```

## 经验教训与注意事项

### 已解决的问题

| 问题 | 原因 | 解决方案 |
| ---- | ---- | -------- |
| 关卡解与像素图形状不一致 | 使用固定阈值128分割 | 改为Otsu动态阈值+排名法 |
| 填充率固定40%不合理 | 颜色丰富和稀少的区域用同一比例 | 动态填充率，根据Otsu自然比例钳制到25%-65% |
| 空行/全满行无意义 | 排名法可能产生全空或全满的行列 | fix_empty_and_full_lines按亮度排名修复 |
| can_solve返回部分解 | 约束传播未完全确定时返回含-1的网格 | 始终使用adjusted_grid作为最终解，can_solve仅判断可解性 |
| 提示格重复添加 | 约束传播已确定的格子被再次添加 | 添加 `if grid[r][c] != -1: continue` 跳过已确定格子 |
| 大关卡提示格不足 | 固定上限15对20×20关卡不够 | 动态上限 `max(15, size*size//4)` |

### 关键设计决策

1. **排名法优于阈值法**：按亮度排名填充比固定阈值分割更能保留像素图的视觉特征
2. **动态填充率优于固定填充率**：颜色多的区域自然需要更多填充格
3. **解不可修改**：从像素图生成的解是"正确答案"，可解性验证只决定是否需要提示格，不改变解本身
4. **提示格策略**：优先揭示约束传播效果最强的格子（所在行列未确定格子最少的）

### 性能参考

| 操作 | 数量 | 耗时 |
| ---- | ---- | ---- |
| 生成630个关卡 | 630 | 约295秒 |
| 生成105张拼接图 | 105 | 约30秒 |
