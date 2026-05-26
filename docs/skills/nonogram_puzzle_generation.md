# 数织关卡生成 Skill

## 概述

从原图自动生成数织（Nonogram）关卡和彩色像素图。核心原则：**从原图提取主体形状作为数织解，优先保持形状完整，提示叉叉优先于翻转修复**。

完整流程：读取画册文档 → 解析难度范围 → 原图分块 → 复杂度计算 → 动态难度分配 → **主体识别图生成（GrabCut + 边缘检测回退）** → 基于主体识别图填充格子 → 线索计算 → 可解性验证 → 提示叉叉生成（优先） → 最小翻转修复（最后手段） → 关卡JSON + 彩色像素图。

多关卡拆分时：生成整张图片的主体识别图 → 按image_grid裁剪各关卡对应区域 → 各区域独立生成数织关卡。

## 工具与依赖

| 依赖 | 说明 |
| ---- | ---- |
| Python 3.11 | 运行生成脚本 |
| PIL/Pillow | 图片处理 |
| NumPy | 数值计算 |
| OpenCV (cv2) | GrabCut主体识别、Canny边缘检测 |
| scipy.ndimage | 形态学操作、连通区域分析 |
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
| reasoning_steps | int | 逻辑推理步数，量化关卡难度 |
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
4. 主体识别图生成 (generate_subject_detection_map)
    │  对整张原图生成主体识别图（黑=主体，白=背景）
    │  优先使用GrabCut算法识别主体
    │  GrabCut失败时回退到Canny边缘检测
    │  保存为 {pic_id}_subject_detection.jpg
    │
    ▼
5. 密度梯度填充+颜色丰富度干扰格
    │  对所有主体格子统一评分 (apply_density_gradient_fill)
    │  特征分数65% + 空间分数35% → 按密度权重排序填充
    │  不保证轮廓填充，由图片内容自然决定填充模式
    │  基于原图颜色丰富度注入背景干扰格 (inject_background_noise)
    │  消除全空/全满行列，提升填充率下限
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
8. 逻辑难度评估 (count_reasoning_steps)
    │  约束传播过程中统计推理步数
    │  每确定一个格子算一步
    │  步数越多→难度越高
    │
    ▼
9. 提示叉叉生成 (find_hint_cells, 优先策略)
    │  只标记 solution=0 的空白格（X标记）
    │  贪心策略：选择解决未知格最多的位置
    │  支持增量提示
    │
    ▼
10. 最小翻转修复 (make_solvable, 最后手段)
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

根据分块数量和难度范围，为每个区域分配具体难度。**核心规则：6个分块按复杂度分为3组（每组2个），低→最小尺寸，中→中间尺寸，高→最大尺寸。**

```python
def get_dynamic_difficulties(img_path, grid_x, grid_y, min_size, max_size):
    # 1. 读取原图并计算分块尺寸
    img = Image.open(img_path).convert('RGBA')
    img_w, img_h = img.size
    img_array = np.array(img)
    block_w = img_w // grid_x
    block_h = img_h // grid_y
    
    # 2. 计算每个区域的复杂度
    complexities = []
    for by in range(grid_y):
        for bx in range(grid_x):
            start_x = bx * block_w
            start_y = by * block_h
            block_array = img_array[start_y:start_y+block_h, start_x:start_x+block_w]
            complexity = calculate_block_complexity(block_array)
            complexities.append((bx, by, complexity))
    
    # 3. 按复杂度排序（低→高）
    complexities.sort(key=lambda x: x[2])
    
    # 4. 确定可用难度等级
    num_blocks = grid_x * grid_y
    available_sizes = [5, 10, 15, 20, 25]
    valid_sizes = sorted([s for s in available_sizes if min_size <= s <= max_size])
    
    # 5. 按复杂度分3组，每组映射到对应难度等级
    num_groups = 3
    group_size = num_blocks // num_groups
    group_remainder = num_blocks % num_groups
    group_map = []
    for g in range(num_groups):
        count = group_size + (1 if g < group_remainder else 0)
        if g == 0:      # 低复杂度组 → 最小尺寸
            mapped_size = valid_sizes[0]
        elif g == 1:    # 中复杂度组 → 中间尺寸（2种尺寸时映射到最大尺寸）
            mapped_size = valid_sizes[len(valid_sizes) // 2] if len(valid_sizes) >= 3 else valid_sizes[-1]
        else:           # 高复杂度组 → 最大尺寸
            mapped_size = valid_sizes[-1]
        group_map.append((count, mapped_size))
    
    # 6. 按复杂度排名分配难度
    difficulties = [0] * num_blocks
    block_idx = 0
    for count, mapped_size in group_map:
        for _ in range(count):
            if block_idx >= num_blocks:
                break
            bx, by, _ = complexities[block_idx]
            pos = by * grid_x + bx
            difficulties[pos] = mapped_size
            block_idx += 1
    
    return difficulties
```

**分组映射规则**：

| 可用尺寸数 | 低复杂度组 | 中复杂度组 | 高复杂度组 |
| ---------- | ---------- | ---------- | ---------- |
| 1种 | 最小 | 最小 | 最小 |
| 2种 | 最小 | 最大 | 最大 |
| 3种 | 最小 | 中间 | 最大 |

**设计理由**：线性均匀分布（旧方案）会导致小尺寸偏多、大尺寸偏少，不符合画册文档规定的2-2-2分组模式。分组分配确保每种难度等级恰好出现2次（6分块时），与文档规则完全一致。

##### 3.3 分配示例

**中国通史画册实际分配结果**（6分块，3×2）：

6分块（image_grid = {x:3, y:2}），难度范围 5×5～10×10：

| 图片 | 复杂度排名（低→高） | 分配难度 | 尺寸计数 |
| ---- | ------------------- | -------- | -------- |
| chapter1_01_yuanmou | [中, 低, 高, 高, 低, 中] | [10, 5, 10, 10, 5, 10] | {5:2, 10:4} |
| chapter2_12_simuwu | [低, 高, 高, 高, 低, 中] | [5, 10, 10, 10, 5, 10] | {5:2, 10:4} |
| chapter2_23_jingke | [高, 高, 中, 低, 低, 中] | [10, 10, 10, 5, 5, 10] | {5:2, 10:4} |

6分块（image_grid = {x:3, y:2}），难度范围 5×5～15×15：

| 图片 | 复杂度排名（低→高） | 分配难度 | 尺寸计数 |
| ---- | ------------------- | -------- | -------- |
| chapter3_24_qinshihuang | [低, 低, 中, 高, 中, 高] | [5, 5, 10, 15, 10, 15] | {5:2, 10:2, 15:2} |
| chapter3_31_hanwudi | [中, 高, 低, 中, 低, 高] | [10, 15, 5, 10, 5, 15] | {5:2, 10:2, 15:2} |
| chapter3_38_zhangheng | [低, 低, 高, 高, 中, 中] | [5, 5, 15, 15, 10, 10] | {5:2, 10:2, 15:2} |

6分块（image_grid = {x:3, y:2}），难度范围 10×10～20×20：

| 图片 | 复杂度排名（低→高） | 分配难度 | 尺寸计数 |
| ---- | ------------------- | -------- | -------- |
| chapter5_54_taizong | [低, 低, 中, 高, 高, 中] | [10, 10, 15, 20, 20, 15] | {10:2, 15:2, 20:2} |
| chapter6_77_qingmingtu | [低, 中, 高, 低, 高, 中] | [10, 15, 20, 10, 20, 15] | {10:2, 15:2, 20:2} |

6分块（image_grid = {x:3, y:2}），难度范围 15×15～25×25：

| 图片 | 复杂度排名（低→高） | 分配难度 | 尺寸计数 |
| ---- | ------------------- | -------- | -------- |
| chapter7_83_guoshoujing | [低, 低, 中, 中, 高, 高] | [15, 15, 20, 20, 25, 25] | {15:2, 20:2, 25:2} |
| chapter8_86_zhuyuanzhang | [高, 高, 中, 低, 低, 中] | [25, 25, 20, 15, 15, 20] | {15:2, 20:2, 25:2} |
| chapter11_105_xinzhongguo | [中, 低, 低, 中, 高, 高] | [20, 15, 15, 20, 25, 25] | {15:2, 20:2, 25:2} |

**关键特点**：
- 每种难度等级恰好出现2次，符合画册文档规定的2-2-2分组模式
- 不同图片的难度分布完全不同，由各区域的实际复杂度决定
- 左上角不一定是最小尺寸，取决于哪个区域复杂度最低
- 复杂度最高的区域会分配到范围内最大的难度

#### 4. 主体识别图生成

**核心原则：使用GrabCut算法从原图识别主体，生成黑白主体识别图，作为数织关卡设计的依据。**

##### 4.1 主体识别图概念

主体识别图是一张与原图同尺寸的灰度图像：
- **黑色(0)**：主体区域
- **白色(255)**：背景区域

保存路径：`{原图目录}/subject_detection/{pic_id}_subject_detection.jpg`

##### 4.2 GrabCut算法 (detect_subject_grabcut)

GrabCut是基于图割的交互式前景提取算法，通过迭代优化能量函数分离前景和背景。

**算法流程**：

1. **矩形初始化**：以图片边缘8%为边距定义矩形区域，矩形内部为可能的前景
2. **第一次GrabCut**：使用`cv2.GC_INIT_WITH_RECT`模式运行5次迭代
3. **Mask初始化回退**：如果结果填充率<5%或>85%，使用mask模式重新初始化：
   - 边缘8%区域标记为确定背景(GC_BGD)
   - 中心50%区域标记为确定前景(GC_FGD)
   - 使用`cv2.GC_INIT_WITH_MASK`模式运行5次迭代
4. **颜色差异+饱和度回退**：如果结果仍然<5%，计算边缘像素平均色作为背景色，使用颜色差异(>30)和饱和度(>0.10)联合判断主体
5. **形态学清理**：腐蚀2次+膨胀2次，去除噪点
6. **连通区域选择**：只保留中心点所在的连通区域（或最大连通区域）

```python
def detect_subject_grabcut(img):
    # 1. 矩形初始化GrabCut
    margin = int(min(h, w) * 0.08)
    rect = (margin, margin, w - 2*margin, h - 2*margin)
    cv2.grabCut(arr_bgr, mask, rect, bgd_model, fgd_model, 5, cv2.GC_INIT_WITH_RECT)
    
    # 2. 如果填充率异常，尝试mask模式
    if fill_rate < 5% or fill_rate > 85%:
        # 边缘=背景，中心=前景
        cv2.grabCut(arr_bgr, mask2, None, ..., cv2.GC_INIT_WITH_MASK)
    
    # 3. 如果仍然失败，使用颜色差异+饱和度
    if fill_rate < 5%:
        fallback_mask = (color_diff > 30) & (saturation > 0.10)
    
    # 4. 形态学清理 + 连通区域选择
    result_mask = erosion(dilation(result_mask))
    # 只保留中心连通区域
```

##### 4.3 Canny边缘检测回退 (detect_subject_edge)

当GrabCut无法正确识别主体时（填充率<10%或>80%），使用Canny边缘检测作为回退方案。

**算法流程**：

1. **高斯模糊**：5×5核，减少噪声
2. **Canny边缘检测**：低阈值50，高阈值150
3. **形态学闭运算**：椭圆核5×5，3次迭代，连接断开边缘
4. **膨胀**：2次迭代，扩大边缘区域
5. **轮廓查找**：`cv2.findContours`查找外部轮廓
6. **中心加权评分**：每个轮廓按 `面积 × (0.3 + 0.7 × 中心接近度)` 评分
7. **轮廓选择**：按评分降序累加，直到覆盖60%总面积
8. **填充轮廓**：`cv2.drawContours`填充选中轮廓
9. **孔洞填充**：`binary_fill_holes`填充轮廓内部
10. **连通区域选择**：只保留中心点所在的连通区域

```python
def detect_subject_edge(img):
    # 1. Canny边缘检测
    edges = cv2.Canny(blurred, 50, 150)
    
    # 2. 形态学闭运算 + 膨胀
    closed = cv2.morphologyEx(edges, cv2.MORPH_CLOSE, kernel, iterations=3)
    dilated = cv2.dilate(closed, kernel, iterations=2)
    
    # 3. 轮廓查找 + 中心加权评分
    contours = cv2.findContours(dilated, ...)
    scored = [(cnt, area * (0.3 + 0.7 * center_score), area) for cnt in contours]
    
    # 4. 选择评分最高的轮廓（覆盖60%面积）
    selected = accumulate_until(scored_sorted, 0.6 * total_area)
    
    # 5. 填充 + 孔洞填充 + 连通区域选择
    cv2.drawContours(mask, selected, -1, 255, -1)
    result = binary_fill_holes(mask)
```

##### 4.4 主体识别图生成流程 (generate_subject_detection_map)

**完整流程**：

1. 检查是否已有缓存的主体识别图，有则直接复用
2. 优先使用GrabCut算法
3. 如果GrabCut填充率<10%或>80%，尝试边缘检测回退
4. 选择填充率更合理的结果
5. 生成黑白图像并保存

```python
def generate_subject_detection_map(img_path, output_dir, pic_id):
    # 1. 检查缓存
    if os.path.exists(output_path):
        return output_path  # 复用已有结果
    
    # 2. GrabCut主体识别
    mask = detect_subject_grabcut(img)
    fill_rate = mask.sum() / (h * w) * 100
    method = "GrabCut"
    
    # 3. 填充率异常时回退到边缘检测
    if fill_rate < 10 or fill_rate > 80:
        edge_mask = detect_subject_edge(img)
        edge_fill = edge_mask.sum() / (h * w) * 100
        # 选择更合理的结果
        if fill_rate < 10 and edge_fill > fill_rate:
            mask, fill_rate, method = edge_mask, edge_fill, "Edge"
        elif fill_rate > 80 and 10 < edge_fill < 80:
            mask, fill_rate, method = edge_mask, edge_fill, "Edge"
    
    # 4. 保存主体识别图（黑=主体，白=背景）
    result_array = np.full((h, w), 255, dtype=np.uint8)
    result_array[mask] = 0
    Image.fromarray(result_array, mode='L').save(output_path)
```

**日常物品画册识别效果示例**：

| 图片 | GrabCut填充率 | 边缘检测填充率 | 最终方法 | 说明 |
| ---- | ------------- | -------------- | -------- | ---- |
| 杯子 | 45.2% | - | GrabCut | GrabCut直接成功 |
| 帽子 | 2.3% | 69.4% | Edge | GrabCut失败，边缘检测回退成功 |
| 汽车 | 61.5% | - | GrabCut | GrabCut直接成功 |
| 云朵 | 82.1% | 38.7% | Edge | GrabCut填充率过高，边缘检测回退 |

##### 4.5 轮廓提取 (extract_outline_grid)

从完整主体网格中提取轮廓格子——即上下左右任一方向相邻非主体格子的主体格：

```python
def extract_outline_grid(subject_grid):
    outline = [[0] * size for _ in range(size)]
    for r in range(size):
        for c in range(size):
            if subject_grid[r][c] == 0:
                continue
            is_edge = False
            for dr, dc in [(-1,0),(1,0),(0,-1),(0,1)]:
                nr, nc = r+dr, c+dc
                if nr<0 or nr>=size or nc<0 or nc>=size:
                    is_edge = True; break
                if subject_grid[nr][nc] == 0:
                    is_edge = True; break
            if is_edge:
                outline[r][c] = 1
    return outline
```

**设计理由**：只保留轮廓格使填充率大幅降低，线索更模糊，推理难度提升。

##### 4.6 密度梯度填充 (apply_density_gradient_fill)

对主体区域的所有格子统一评分，按密度权重排序后填充。**核心思想：不保证任何区域（包括轮廓）一定被填充，而是由图片内容的视觉特征自然决定哪些格子被填充，从而消除"每张图都先描轮廓"的重复感。**

所有尺寸的关卡统一使用密度梯度填充+背景干扰模式，难度等级由网格尺寸决定，控制整体填充密度：

| 网格尺寸 | 难度等级 | 主体格填充比例 | 说明 |
| -------- | -------- | -------------- | ---- |
| 5×5 | d1 | 75% | 最简单，保留大部分视觉特征 |
| 10×10 | d2 | 55% | 中等密度 |
| 15×15 | d3 | 40% | 较稀疏，推理难度较高 |
| 20×20 | d4 | 28% | 最稀疏，仅保留高密度区域 |
| 25×25 | d4 | 28% | 同20×20，最稀疏 |

难度等级计算：`difficulty_level = max(1, min(4, size // 5))`

```python
def apply_density_gradient_fill(subject_grid, difficulty_level, block_img, size):
    grid = [[0] * size for _ in range(size)]  # 空网格，无轮廓保证
    overall_fill_ratios = {1: 0.75, 2: 0.55, 3: 0.40, 4: 0.28}
    overall_ratio = overall_fill_ratios.get(difficulty_level, 0.40)

    # 对所有主体格子（轮廓+内部统一）计算密度权重
    for each subject cell (r, c):
        # 特征分数：饱和度30% + 对比度30% + 暗度20% + 亮度方差20%
        feature_score = avg_sat * 0.3 + contrast_weight + darkness_weight + variance_weight
        # 空间分数：距中心越近分数越高
        spatial_score = 1.0 - (dist_to_center / max_dist)

    # 归一化后加权：特征65% + 空间35%
    density_weight = norm_feature * 0.65 + norm_spatial * 0.35

    # 按密度权重降序排列，填充前 overall_ratio 比例的主体格
    weighted_cells.sort(key=lambda x: x[2], reverse=True)
    num_to_fill = max(1, int(subject_count * overall_ratio))
    for i in range(num_to_fill):
        grid[r][c] = 1
    return grid
```

**设计理由**：
- **去掉轮廓保证**：旧方案强制填充所有轮廓格，导致每张图玩家都是先沿轮廓推理，体验高度重复。新方案让轮廓格与内部格统一竞争，由图片内容自然决定填充模式
- **特征权重65%**：高饱和度/对比度的区域（如动物眼睛、花纹、高对比边界）自然获得高密度，这些区域恰好也是轮廓中视觉特征明显的部分
- **空间权重35%**：中心区域密度高于边缘，创造"中心密→边缘疏"的梯度效果
- **难度等级控制整体密度**：d1(75%)→d4(28%)，大尺寸关卡整体更稀疏，推理难度更高
- **不同图片产生不同填充模式**：色彩丰富的图片填充集中在特征区域，色彩单一的图片填充更均匀分散

##### 4.7 颜色丰富度干扰格注入 (inject_background_noise)

在背景区域注入干扰格，解决两个问题：
1. **填充率过低**（<15%）：关卡内容太少
2. **全空/全满行列**：线索过于简单（[0]或[size]）

**颜色丰富度计算** (extract_cell_colorfulness)：

```python
def extract_cell_colorfulness(block_img, size):
    # 对每个格子计算颜色丰富度
    colorfulness[(r,c)] = avg_sat * 0.6 + (1.0 - avg_bright/255) * 0.25 + min(bright_var/1000, 0.15) * 0.15
```

**公式组成**：
- 饱和度(avg_sat)×0.6：有颜色的区域优先级高
- 暗度(1-brightness/255)×0.25：阴影/暗区优先级较高
- 亮度方差(bright_var)×0.15：有纹理变化的区域优先级较高

**干扰格注入策略**：

1. **消除全空行/列**：在空行/列中选颜色丰富度最高的背景格填充
2. **消除全满行/列**：在全满行/列中移除中间的主体格
3. **提升填充率**：按颜色丰富度降序填充背景格，直到达到20%

```python
def inject_background_noise(grid, subject_grid, min_fill_rate=0.15, colorfulness=None):
    # 1. 找出空行/空列和全满行/全满列
    # 2. 按颜色丰富度降序排列背景候选格
    bg_candidates.sort(key=lambda x: (-x[3], x[2]))  # 颜色丰富度优先
    
    # 3. 消除空行：选该行颜色最丰富的背景格填充
    for row_idx in empty_rows:
        best = max(row_cands, key=lambda x: x[3])
        grid[best[0]][best[1]] = 1
    
    # 4. 消除全满行：移除中间主体格
    for row_idx in full_rows:
        grid[row_idx][mid_col] = 0
    
    # 5. 补充填充率
    if fill_rate < min_fill_rate:
        for r, c, _, cf in bg_candidates:
            grid[r][c] = 1
```

**设计理由**：基于原图颜色选择干扰格位置，使干扰格与原图内容自然关联，避免机械地围绕主体轮廓排列。

##### 4.8 逻辑难度评估 (count_reasoning_steps)

在约束传播过程中统计推理步数，量化关卡难度：

```python
def count_reasoning_steps(row_clues, col_clues, size):
    steps = 0
    while changed:
        for each row/col:
            filter matching possibilities
            for each undetermined cell:
                if all possibilities agree → determine cell
                steps += 1
    return steps
```

**步数含义**：
- 步数 = 纯逻辑推理能确定的格子数
- 5×5关卡：典型 5~25 步
- 10×10关卡：典型 20~100 步
- 15×15关卡：典型 50~225 步

步数越高，推理链越长，难度越大。

##### 4.9 基于主体识别图填充格子 (subject_image_to_grid)

将主体识别图转换为N×N的数织解网格：

```python
def subject_image_to_grid(subject_img, size):
    arr = np.array(subject_img.convert('L'))  # 转灰度
    cell_h, cell_w = h / size, w / size
    
    grid = [[0] * size for _ in range(size)]
    for r in range(size):
        for c in range(size):
            # 取格子区域
            region = arr[y0:y1, x0:x1]
            # 黑色(主体)占比>50%则填充
            dark_ratio = (region < 128).sum() / region.size
            grid[r][c] = 1 if dark_ratio > 0.5 else 0
    return grid
```

**关键设计**：
- 使用区域平均而非中心点采样，更稳定
- 50%阈值确保格子归属明确
- 主体识别图已做过形态学清理，边界清晰

##### 4.6 多关卡拆分时的区域裁剪

当一张图片需要拆分为多个数织关卡时（image_grid > 1×1），每个关卡只使用主体识别图中对应区域的主体信息：

```
整张主体识别图 (1280×1280)
┌──────────┬──────────┐
│  区域0   │  区域1   │  每块 640×640
│ crop→grid│ crop→grid│  各自独立生成数织关卡
├──────────┼──────────┤
│  区域2   │  区域3   │
│ crop→grid│ crop→grid│
└──────────┴──────────┘
```

**裁剪逻辑**：
```python
# 在main()中，对每个关卡：
bx = puzzle_index % grid_x
by = puzzle_index // grid_x
start_x = bx * block_w
start_y = by * block_h

# 裁剪主体识别图到当前关卡区域
block_subject = subject_img_full.crop((start_x, start_y, end_x, end_y))

# 基于裁剪后的主体识别图生成网格
grid = subject_image_to_grid(block_subject, size)
```

**优势**：
- 每个关卡只关注自己区域内的主体，不会受其他区域影响
- 主体跨越多个区域时，各区域独立保留各自部分
- 确保数织解与原图对应区域的主体形状一致

##### 4.7 Otsu二值化回退方案 (detect_subject_and_binarize)

当主体识别图不可用（如cv2未安装或识别失败）时，回退到Otsu二值化方法：

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
[1] cute_animals_000_d1 (5x5) subject=density_gradient fill=56% steps=21 OK noise=2
[2] cute_animals_000_d2 (5x5) subject=density_gradient fill=44% steps=25 OK noise=4
[3] cute_animals_000_d3 (10x10) subject=density_gradient fill=31% steps=81 OK noise=7
[4] cute_animals_000_d4 (10x10) subject=density_gradient fill=26% steps=87 OK noise=10
```

| 字段 | 说明 |
| ---- | ---- |
| subject | 主体类型：density_gradient=密度梯度填充，dark=暗色主体(Otsu回退)，light=亮色主体(Otsu回退) |
| fill | 实际填充率 |
| steps | 逻辑推理步数，步数越多难度越高 |
| OK | 纯逻辑可解（无需提示叉叉） |
| OK noise=N | 纯逻辑可解，注入了N个颜色丰富度干扰格 |
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
   │  按复杂度分3组：低→最小，中→中间，高→最大
   │  6分块时每组2个，确保2-2-2分布
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

按复杂度分3组（1+1+2），低→最小，中→中间，高→最大：

| 难度范围 | 低复杂度×1 | 中复杂度×1 | 高复杂度×2 |
| -------- | ---------- | ---------- | ---------- |
| 5×5～10×10 | 5×5 | 10×10 | 10×10 |
| 5×5～15×15 | 5×5 | 10×10 | 15×15 |

#### 6分块（image_grid = {x:3, y:2}）

按复杂度分3组（每组2个），低→最小，中→中间，高→最大：

| 难度范围 | 低复杂度×2 | 中复杂度×2 | 高复杂度×2 |
| -------- | ---------- | ---------- | ---------- |
| 5×5～10×10 | 5×5 | 10×10 | 10×10 |
| 5×5～15×15 | 5×5 | 10×10 | 15×15 |
| 10×10～20×20 | 10×10 | 15×15 | 20×20 |
| 15×15～25×25 | 15×15 | 20×20 | 25×25 |

**注意**：当可用尺寸只有2种时（如5×5～10×10），中复杂度组映射到最大尺寸，因此实际分布为 {最小:2, 最大:4}。

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
| Otsu无法区分主体与白色填充 | 几何图形中白色底色被误认为主体 | 改用GrabCut算法从原图识别主体，生成主体识别图 |
| GrabCut对部分图片识别失败 | 主体与背景颜色接近或主体过小 | 添加Canny边缘检测回退，以及颜色差异+饱和度回退 |
| 多关卡图片主体识别不精确 | 对每个分块单独识别导致边界不一致 | 改为对整张图片生成主体识别图，再按区域裁剪 |
| 像素图显示背景颜色 | 所有格子都着色导致主体不突出 | 基于主体识别图只着色填充格，空白格留白 |
| 全主体填充导致关卡太简单 | 所有主体格子都填充，线索过于明确 | 改为轮廓+稀疏填充策略，只保留轮廓格和少量内部特征点 |
| 干扰格排列太规律 | 按距离主体轮廓远近选择干扰格 | 改为基于原图颜色丰富度选择，有颜色的区域优先填充 |
| 全空/全满行列过多 | 轮廓+稀疏填充后大量行/列为空或全满 | 注入颜色丰富度干扰格消除空行/列，移除主体格消除全满行/列 |
| 线性均匀分布导致难度分配不符合文档规则 | 旧算法按复杂度排名线性分配，6分块时产生{5:5,10:1}等不合规分布 | 改为按复杂度分3组（每组2个），低→最小，中→中间，高→最大，确保2-2-2分布 |
| 4策略填充体验重复 | 每种难度固定使用一种策略(full/feature/outline_sparse/skeleton)，解谜体验单一 | 改为密度梯度填充，所有难度使用同一算法，通过特征分数+空间分数创造区域密度差异 |
| 轮廓保证导致重复感 | 强制填充所有轮廓格，每张图玩家都是先沿轮廓推理，体验高度重复 | 去掉轮廓保证，轮廓格与内部格统一评分竞争，由图片内容自然决定填充模式 |

### 经验与教训

1. **Otsu阈值必须在原始高分辨率图像上计算**：在下采样后的5×5网格（仅25个采样点）上计算Otsu阈值，会导致所有格子被判定为同一类（fill=0%或fill=100%）。必须在原始高分辨率图像上计算阈值，然后下采样到目标网格。

2. **排名填充法会破坏形状**：旧的 `generate_grid_by_ranking_with_subject` 按亮度排名后取前N%的像素作为填充格，这会破坏原始形状的连续性。例如，空心正方形的边框可能被排名法拆散。正确做法是用主体识别图直接提取主体形状。

3. **少数派优先不适用于所有图形**：少数派优先假设"主体总是占少数"，但对空心图形（如空心正方形，边框占64%）不适用。峰值背景检测通过识别背景颜色来解决这个问题。

4. **翻转过度会破坏形状**：旧算法最多翻转 `size²//3` 个格子（15×15网格=75次翻转），严重破坏原始形状。新算法限制翻转数量为 `min(10, max(3, size²//20))`，并优先使用提示叉叉。

5. **fix_empty_and_full_lines 会修改形状**：全空行/全满行在数织中是完全合法的（线索为[0]或[size]），不需要修复。修改它们会破坏原始形状。

6. **提示叉叉优先于翻转**：提示叉叉只标记空白格，不改变解的形状，应优先使用。翻转是最后手段，应严格限制数量。

7. **区域平均采样优于中心点采样**：中心点采样在高对比度边界处可能采到错误的值，区域平均更稳定。

8. **GrabCut是日常物品主体识别的首选方法**：GrabCut利用颜色信息进行图割优化，对日常物品（杯子、手机、汽车等）识别效果好。但当主体与背景颜色接近时（如帽子），需要边缘检测回退。

9. **主体识别图应缓存复用**：生成主体识别图是耗时操作（GrabCut 5次迭代），应检查已有缓存避免重复计算。缓存在`{原图目录}/subject_detection/`目录下。

10. **多关卡拆分必须基于整图主体识别图裁剪**：对每个分块单独生成主体识别图会导致边界不一致和重复计算。正确做法是先对整张图片生成主体识别图，再按image_grid裁剪各区域。

11. **几何图形画册不适合GrabCut**：GrabCut对几何图形（如正方形、三角形）识别效果差，因为白色填充区域会被误认为主体。几何图形画册应使用内容规划文档中的■/□网格作为主体识别依据。

12. **全主体填充导致关卡太简单**：对所有主体格子都填充，线索过于明确，玩家几乎不需要推理。正确做法是只保留轮廓格+稀疏内部特征点，大幅降低填充率，提升推理难度。

13. **干扰格应基于原图颜色选择**：按距离主体轮廓远近选择干扰格会导致排列过于规律（围绕主体一圈）。正确做法是基于原图颜色丰富度选择——有颜色、有纹理、有阴影的区域优先填充，使干扰格与原图内容自然关联。

14. **必须消除全空/全满行列**：全空行线索为[0]，全满行线索为[size]，玩家无需推理即可确定。轮廓+稀疏填充后容易产生大量空行/列，必须通过干扰格注入和主体格移除来消除。

15. **逻辑推理步数量化难度**：推理步数是量化关卡难度的有效指标。5×5关卡典型5~25步，10×10关卡典型20~100步，15×15关卡典型50~225步。步数越高，推理链越长。

16. **动态难度分配必须按分组模式而非线性分布**：线性均匀分布（`size_idx = int(idx * (len(valid_sizes) - 1) / (num_blocks - 1))`）在6分块时产生不合规的尺寸分布（如{5:5,10:1}而非文档要求的{5:2,10:4}）。正确做法是按复杂度分3组，每组映射到对应难度等级，确保2-2-2分布。

17. **难度等级应由网格尺寸决定而非分块索引**：旧算法用 `(block_idx % 4) + 1` 计算难度等级，导致同一图片的不同尺寸分块可能获得不合理的稀疏保留率。正确做法是 `difficulty_level = max(1, min(4, size // 5))`，5×5→d1、10×10→d2、15×15→d3、20×20/25×25→d4，确保大尺寸关卡更稀疏、推理难度更高。

18. **密度梯度填充优于多策略切换，且不应保证轮廓填充**：4策略系统(full/feature/outline_sparse/skeleton)虽然每种策略的填充方式不同，但同一难度等级内所有关卡体验一致，缺乏变化。密度梯度填充通过特征分数(65%)+空间分数(35%)的加权组合，使每个关卡的密度分布都基于图片内容自然生成。更重要的是，**不应保证轮廓格一定被填充**——旧方案强制填充所有轮廓格，导致每张图玩家都是先沿轮廓推理，体验高度重复。去掉轮廓保证后，轮廓格与内部格统一竞争，由图片内容的视觉特征自然决定哪些格子被填充，有效消除重复感。
