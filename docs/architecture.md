# 《数织艺术》项目架构规划文档

> Godot 4.6 | 版本 1.0 | 2026-05-08

***

## 一、核心游戏循环

```
选择主题画册 → 查看画册图片 → 选择图片分块 → 解数织关卡 → 完成图片收集 → 解锁下一张图片 → 完成主题画册 → 解锁下一本画册
```

关键设计理念：**数织关卡还原的图片分块，是画册图片的一块拼图**。完成所有拼图后，拼合成完整的高清图片，形成"拼图"的仪式感。

***

## 二、数据层级关系与格式规范

### 2.1 数据层级关系

```
Album (主题画册)
 └── Picture (图片)
      ├── image: 完整图片路径
      └── Puzzle[] (数织关卡，图片分块)
           ├── name: 分块名称
           ├── grid: 数织网格数据
           ├── row_clues / col_clues: 行列提示
           └── solution: 正确答案
```

### 2.2 数据格式设计

**albums.json** — 画册定义：

```json
{
  "bookshelves": [
    {
      "id": "humanities_history",
      "name": "人文历史",
      "icon": "res://assets/images/icons/bookshelf_humanities.png",
      "order": 0
    }
  ],
  "albums": [
    {
      "id": "chinese_history",
      "name": "中国通史",
      "description": "中国历代王朝更迭与重大事件",
      "bookshelf_id": "humanities_history",
      "icon": "res://assets/images/icons/album_chinese_history.png",
      "unlock_condition": null,
      "order": 0
    }
  ]
}
```

**pictures/{album_id}.json** — 图片数据：

```json
{
  "album_id": "chinese_history",
  "pictures": [
    {
      "id": "yuanmouren",
      "title": "元谋人遗址",
      "summary": "中国最早的人类化石发现地",
      "full_text": "约170万年前，在云南元谋地区生活着中国境内已知最早的人类——元谋人...",
      "image": "res://assets/images/illustrations/chinese_history/yuanmouren.png",
      "image_grid": { "x": 3, "y": 2 },
      "puzzles": ["yuanmouren_0", "yuanmouren_1", "yuanmouren_2", "yuanmouren_3", "yuanmouren_4", "yuanmouren_5"],
      "order": 0
    }
  ]
}
```

**图片字段说明**：

- `image`：完整画册图片路径，是一张包含所有分块的完整艺术作品
- `image_grid`：图片的网格划分配置 (X×Y)，表示图片在逻辑上可划分为 X×Y 个分块区域
- `summary`：图片简要描述（用于图片卡片展示）
- `full_text`：图片详细介绍（用于图片详情页展示）
- 每个 puzzle 的 `source_rect` 字段记录该关卡对应的图片分块位置

**puzzles/{album_id}/{puzzle_id}.json** — 数织关卡数据：

```json
{
  "id": "yuanmouren_0",
  "name": "元谋人遗址-分块0",
  "picture_id": "yuanmouren",
  "size": { "rows": 10, "cols": 10 },
  "difficulty": "easy",
  "row_clues": [[2], [4], [6], [8], [10], [2], [2], [2], [2], [2]],
  "col_clues": [[1], [2], [3], [4], [10], [10], [4], [3], [2], [1]],
  "solution": [
    [0,0,0,0,1,1,0,0,0,0],
    [0,0,0,1,1,1,1,0,0,0],
    ...
  ],
  "hint_cells": [],
  "source_rect": { "x": 0, "y": 0, "w": 832, "h": 832 }
}
```

### 2.3 命名规范

**数织关卡命名**:

- 格式: `{picture_id}_{number}.json`
- number: 从 0 开始的连续整数，与图片分块一一对应
- 示例: `yuanmouren_0.json`, `huangdi_5.json`

**图片分块命名**:

- 格式: `{picture_id}_{number}.png`
- number: 从 0 开始的连续整数，与数织关卡一一对应
- 示例: `yuanmouren_0.png`, `huangdi_5.png`

**对应关系**:

- 图片分块 `picture_id_0.png` ↔ 数织关卡 `picture_id_0.json`
- 图片分块 `picture_id_1.png` ↔ 数织关卡 `picture_id_1.json`
- 数字编号顺序: 按图片网格从左到右、从上到下排列

***

## 三、场景结构与 UI 流程

### 3.1 场景树

```
MainMenu
 ├── 背景（动态山水/水墨动画）
 ├── 标题 "数织艺术"
 ├── [开始旅程] 按钮
 ├── [画廊] 按钮
 └── [设置] 按钮

AlbumSelection (画册选择 - 横向卷轴)
 ├── 顶部：画册标题 + 简介
 ├── 中部：横向滚动画册列表，每个节点为一本画册
 │    ├── 已解锁：彩色封面，可点击
 │    ├── 当前：高亮 + 动画
 │    └── 未解锁：灰色封面，显示锁图标
 └── 底部：返回按钮

PictureList (图片列表)
 ├── 顶部：画册名称 + 返回
 ├── 中部：图片卡片网格
 │    └── PictureCard: 图片缩略图 + 标题 + 完成状态
 └── 底部：画册进度

PictureDetail (图片详情)
 ├── 上半部：完整图片（带分块高亮区域标记）
 │    ├── 未完成分块：剪影/暗色状态
 │    └── 已完成分块：完整显示
 ├── 分块选择栏：横向可滑动的分块缩略图列表
 │    ├── 已完成：彩色缩略图
 │    └── 未完成：剪影缩略图
 └── [进入数织] 按钮

PuzzleGame (数织游戏 - 核心玩法)
 ├── 顶部：分块名称 + 返回 + 提示按钮
 ├── 左侧：行提示数字
 ├── 上方：列提示数字
 ├── 中部：数织网格
 │    ├── 空白格：未操作
 │    ├── 填充格：黑色/主题色
 │    ├── 标记格：×标记（玩家标记为空）
 │    └── 错误格：红色闪烁
 ├── 底部：操作栏
 │    ├── [填充/标记] 切换
 │    ├── [撤销] 按钮
 │    ├── [重做] 按钮
 │    └── [重置] 按钮
 └── 完成弹窗：展示还原的分块 + 返回图片详情

Gallery (画廊)
 ├── 全部已完成的完整图片展示
 ├── 每张图片可点击查看拼图回顾
 └── 收集进度统计

Settings (设置)
 ├── 音量控制（BGM/SFX）
 ├── 难度偏好
 ├── 语言
 └── 关于
```

### 3.2 场景切换流程

```
MainMenu → AlbumSelection → PictureList → PictureDetail → PuzzleGame
   │                          ↑              │            │
   └── Gallery ←──────────────┘              │            │
   └── Settings                              │←───────────┘
                                    (完成数织后返回图片详情)
```

***

## 四、数织系统核心算法

核心要求：**所有数织关卡必须可通过纯逻辑推理求解，不需要猜测**。

### 4.1 算法架构

```
┌─────────────────────────────────────────────────┐
│              Nonogram System                     │
│                                                  │
│  ┌──────────────┐    ┌──────────────────────┐   │
│  │  Generator    │───→│  Validator (Solver)  │   │
│  │  (生成器)     │    │  (验证器/求解器)      │   │
│  └──────────────┘    └──────────────────────┘   │
│         │                     │                  │
│         │            ┌────────┴────────┐        │
│         │            │  可推理求解?      │        │
│         │            └────────┬────────┘        │
│         │               Yes ↙     ↘ No          │
│         │         保存关卡     调整/重新生成      │
│         │                     ↑                  │
│         └─────────────────────┘                  │
│                                                  │
│  ┌──────────────┐    ┌──────────────────────┐   │
│  │  Renderer    │    │  InputHandler        │   │
│  │  (渲染器)     │    │  (输入处理)           │   │
│  └──────────────┘    └──────────────────────┘   │
└─────────────────────────────────────────────────┘
```

### 4.2 求解器算法（NonogramSolver）

**核心思路：约束传播（Constraint Propagation）+ 行列求解**

```
算法流程：
1. 初始化：所有格子状态为 UNKNOWN
2. 循环：
   a. 对每一行，调用 line_solve(row_clues, current_state) 
      → 确定哪些格子必填、必空
   b. 对每一列，调用 line_solve(col_clues, current_state)
      → 确定哪些格子必填、必空
   c. 如果本轮没有任何变化 → 停止
3. 判断结果：
   - 所有格子确定 → 拼图可推理求解 ✓
   - 仍有未知格子 → 需要猜测，不可推理求解 ✗
```

**line_solve 核心算法**：

```
输入：一行/列的提示数字 [c1, c2, ...]，当前已知状态
输出：可以确定的新格子状态

方法：枚举所有合法排列
1. 根据提示数字和已知状态，生成所有可能的填充排列
2. 对所有排列取交集：
   - 所有排列中都填充的格子 → 必填
   - 所有排列中都为空的格子 → 必空
3. 返回新确定的状态
```

**优化策略**：

- 对于短行/列（≤20格），直接枚举排列
- 对于长行/列（>20格），使用动态规划 + 左右边界法
- 缓存已求解的行/列结果，避免重复计算

### 4.3 生成器算法（NonogramGenerator）

**从完整画册图片生成可推理的数织关卡**：

```
输入：完整画册图片（宽高比与 X:Y 匹配）、当前画册的 grid_size (N)、分块划分 (X×Y)
输出：X×Y 个验证通过的数织关卡数据

流程：
1. 图片分析：
   - 验证图片宽高比是否与 X:Y 匹配
   - 确定图片中的 X×Y 个分块区域位置
   - 记录每个分块在原图中的坐标

2. 分块拆分（逻辑拆分，不破坏原图完整性）：
   - 将图片按等分划分为 X×Y 个大小相同的矩形区域
   - 每个区域对应一个拼图分块
   - 记录每个区域在原图中的坐标 (source_rect)

3. 对每个分块生成数织关卡：
   a. 分块提取：
      - 从原图中提取该分块的像素（使用原始高分辨率，不使用缩放后的版本）
      - 缩放到 N×N 网格尺寸
      - 多维度二值化处理（灰度 + 饱和度 + 亮度 + 边缘检测综合判定）
      - 生成 0/1 网格
      
   b. 图像后处理：
      - 平滑处理（消除孤立噪点）
      - 移除过小色块（避免无意义的碎片）
      - 重新验证
      
   c. 生成提示数字：
      - 从网格计算每行的连续填充段 → row_clues
      - 从网格计算每列的连续填充段 → col_clues
      
   d. 验证可推理性：
      - 用 Solver 求解（仅用 row_clues 和 col_clues）
      - 如果可推理求解且解唯一 → 通过 ✓
      - 如果不可推理 → 进入调整流程
      
   e. 调整流程（使不可推理的关卡变为可推理）：
      策略A：简化形状
        - 移除孤立的填充格
        - 填补小的空洞
        - 重新验证
      
      策略B：添加提示格
        - 选择 Solver 卡住的位置
        - 将该格预填为正确答案（hint_cells）
        - 重新验证
      
      策略C：调整分块选择
        - 如果当前分块过于复杂，选择区域内更简单的特征
        - 重新提取区域并重试

4. 输出：X×Y 个数织关卡数据，每个关卡包含 source_rect 字段指向原图位置
```

**图片生成与关卡生成完整流程**：

```
1. 生成图片（generate_jimeng_images.py）
   ├── 根据 X×Y 计算宽高比（如 3×2 → 3:2）
   ├── 选择匹配宽高比的 API 尺寸参数（如 2496x1664）
   ├── 调用即梦 API 生成完整画册场景图片
   └── 保存原始分辨率图片（不拉伸、不缩放）

2. 生成数织关卡（generate_puzzles_from_image.py）
   ├── 加载原始分辨率图片
   ├── 按 X×Y 等分拆分为分块
   ├── 对每个分块：提取 → 二值化 → 后处理 → 生成提示 → 验证可推理性
   └── 输出 X×Y 个 JSON 关卡文件
```

### 4.4 难度分级规范

| 难度 | 网格大小  |
| -- | ----- |
| 入门 | 5×5   |
| 简单 | 10×10 |
| 中等 | 15×15 |
| 困难 | 20×20 |

### 4.5 数据规模统计

**当前已生成数据**：

| 统计项 | 数量 |
| ---- | ---- |
| 画册总数 | 66本 |
| 图片总数 | 4650张 |
| 谜题总数 | 27900个 |

**画册分类**：

| 书架 | 画册数量 | 图片数量 |
| ---- | ---- | ---- |
| 人文历史 | 12 | 1050 |
| 艺术创作 | 10 | 710 |
| 自然地理 | 8 | 500 |
| 生物世界 | 10 | 670 |
| 生活社会 | 11 | 700 |
| 科技工业 | 11 | 720 |
| 综合素材 | 4 | 240 |

***

## 五、项目目录结构

```
ChineseMemory/
├── project.godot

├── data/                           # 游戏数据（JSON）
│   ├── albums.json                  # 画册定义（包含7个书架、66个画册）
│   ├── pictures/                    # 图片数据（按画册分JSON文件）
│   │   ├── chinese_history.json     # 中国通史（105张图片，含完整历史内容）
│   │   ├── world_history.json       # 世界通史（100张）
│   │   ├── asian_civilization.json  # 亚洲文明史（95张）
│   │   ├── european_civilization.json
│   │   ├── africa_america_civilization.json
│   │   ├── war_military.json
│   │   ├── political_system.json
│   │   ├── economic_trade.json
│   │   ├── world_heritage.json
│   │   ├── chinese_heritage.json
│   │   ├── archaeology.json
│   │   ├── historical_mysteries.json
│   │   ├── chinese_painting.json
│   │   ├── western_painting.json
│   │   ├── sculpture.json
│   │   ├── photography.json
│   │   ├── architecture.json
│   │   ├── crafts.json
│   │   ├── design.json
│   │   ├── performing_arts.json
│   │   ├── folk_traditional.json
│   │   ├── contemporary_media.json
│   │   ├── mountains_plateaus.json
│   │   ├── plains_basins.json
│   │   ├── deserts_gobi.json
│   │   ├── rivers_lakes.json
│   │   ├── atmosphere.json
│   │   ├── geology.json
│   │   ├── paleontology.json
│   │   ├── nature_reserves.json
│   │   ├── mammals.json
│   │   ├── birds.json
│   │   ├── reptiles.json
│   │   ├── fish.json
│   │   ├── insects.json
│   │   ├── trees.json
│   │   ├── flowers.json
│   │   ├── crops.json
│   │   ├── fungi.json
│   │   ├── ecosystems.json
│   │   ├── fashion.json
│   │   ├── food.json
│   │   ├── housing.json
│   │   ├── transportation.json
│   │   ├── festivals.json
│   │   ├── religion.json
│   │   ├── family.json
│   │   ├── workplace.json
│   │   ├── education.json
│   │   ├── sports.json
│   │   ├── entertainment.json
│   │   ├── health.json
│   │   ├── math_physics.json
│   │   ├── chemistry_biology.json
│   │   ├── astronomy.json
│   │   ├── mechanical_electronic.json
│   │   ├── energy.json
│   │   ├── civil_engineering.json
│   │   ├── information_technology.json
│   │   ├── industrial_production.json
│   │   ├── agriculture_food.json
│   │   ├── transport_industry.json
│   │   ├── abstract.json
│   │   ├── symbols.json
│   │   ├── textures.json
│   │   └── miscellaneous.json
│   └── puzzles/                    # 数织关卡数据（按画册分子目录）
│       ├── chinese_history/         # 中国通史谜题（630个）
│       ├── world_history/           # 世界通史谜题（600个）
│       ├── ...                      # 其他画册谜题目录

├── assets/
│   ├── images/
│   │   ├── illustrations/          # 画册图片（按画册分子目录）
│   │   │   ├── chinese_history/    # 中国通史
│   │   │   ├── world_history/      # 世界通史
│   │   │   └── ...                 # 其他画册图片
│   │   ├── ui/                     # UI素材
│   │   ├── icons/                  # 图标（书架图标、画册图标等）
│   │   └── backgrounds/            # 背景图
│   ├── fonts/                      # 字体（中文+英文）
│   └── audio/
│       ├── bgm/                    # 背景音乐（按画册风格）
│       └── sfx/                    # 音效

├── scenes/                         # Godot场景文件
│   ├── main_menu.tscn
│   ├── album_selection.tscn
│   ├── picture_list.tscn
│   ├── picture_detail.tscn
│   ├── puzzle_game.tscn
│   ├── gallery.tscn
│   ├── settings.tscn
│   └── components/                 # 可复用组件场景
│       ├── picture_card.tscn
│       ├── album_node.tscn
│       ├── puzzle_cell.tscn
│       └── completion_popup.tscn

├── scripts/
│   ├── core/                       # 核心系统
│   │   ├── game_manager.gd         # 游戏主管理器
│   │   ├── save_manager.gd         # 存档管理
│   │   ├── audio_manager.gd        # 音频管理
│   │   └── scene_manager.gd        # 场景切换管理
│   │
│   ├── data/                       # 数据层
│   │   ├── album_data.gd           # 画册数据加载
│   │   ├── picture_data.gd         # 图片数据加载
│   │   └── puzzle_data.gd          # 关卡数据加载
│   │
│   ├── nonogram/                   # 数织系统（核心）
│   │   ├── nonogram_solver.gd      # 求解器（验证可推理性的关键）
│   │   ├── nonogram_generator.gd   # 生成器（编辑器工具）
│   │   ├── nonogram_grid.gd        # 网格逻辑管理
│   │   ├── nonogram_cell.gd        # 单元格逻辑
│   │   └── nonogram_clue.gd        # 提示数字逻辑
│   │
│   ├── ui/                         # UI脚本
│   │   ├── main_menu.gd
│   │   ├── album_selection.gd
│   │   ├── picture_list.gd
│   │   ├── picture_detail.gd
│   │   ├── puzzle_game.gd
│   │   ├── gallery.gd
│   │   └── settings.gd
│   │
│   └── autoload/                   # 全局自动加载
│       └── game_state.gd           # 游戏状态（进度/设置）

├── resources/                      # Godot资源
│   ├── themes/                     # 主题资源
│   │   └── chinese_theme.tres
│   └── styles/                     # 样式盒
│       ├── cell_filled.tres
│       ├── cell_empty.tres
│       └── cell_marked.tres

└── tools/                          # 开发工具（不打包进游戏）
    ├── generate_album_data.py             # 批量生成画册图片数据
    ├── generate_jimeng_images.py           # AI图片生成工具（即梦AI）
    ├── generate_ch01_yuangu.py             # 中国通史第一章生成脚本
    ├── generate_huangdi.py                 # 黄帝部落联盟图片生成
    ├── generate_huangdi_puzzles.py         # 黄帝数织关卡生成
    ├── generate_all_eras_images.py         # 批量生成所有画册图片
    ├── generate_missing_images.py          # 生成缺失图片
    ├── generate_placeholder.py             # 占位图片生成
    ├── update_puzzle_difficulty.py         # 更新谜题难度配置
    ├── check_and_fix_puzzles.py            # 检查并修复无效谜题
    ├── fix_source_rect.py                  # 修复谜题source_rect配置
    ├── generate_puzzles_from_image.py      # 从图片生成数织关卡
    ├── verify_all_puzzles.py               # 验证所有谜题可推理性
    ├── simple_image_puzzle_generator.py    # 从图片像素提取生成数织关卡
    ├── fix_grid_size_multiple_of_5.py      # 修复网格大小为5的倍数
    ├── smart_image_puzzle_generator.py     # 基于图片特征的智能谜题生成器
    └── pipeline/                           # 内容生产流水线工具
        ├── content_pipeline.gd
        ├── fix_puzzles.py
        ├── generate_puzzle_json.py
        ├── redesign_puzzles.py
        └── verify_all_puzzles.py
```

***

## 六、关键类设计

### 6.1 NonogramSolver（求解器 — 最核心）

```gdscript
class_name NonogramSolver

enum CellState { UNKNOWN, FILLED, EMPTY }

static func solve(row_clues: Array, col_clues: Array) -> SolveResult
static func line_solve(clues: Array, current_states: Array, line_length: int) -> Array
static func is_logically_solvable(row_clues: Array, col_clues: Array) -> bool
static func compute_clues(solution: Array) -> Dictionary
static func verify_solution(row_clues: Array, col_clues: Array, solution: Array) -> bool
```

### 6.2 NonogramGrid（网格逻辑）

```gdscript
class_name NonogramGrid

enum CellState { UNKNOWN, FILLED, EMPTY }

signal cell_changed(row: int, col: int, state: int)
signal puzzle_completed
signal error_counted(count: int)

func setup(puzzle: PuzzleData) -> void
func set_cell(row: int, col: int, state: int) -> void
func toggle_fill(row: int, col: int) -> void
func toggle_mark(row: int, col: int) -> void
func undo() -> void
func redo() -> void
func reset() -> void
func get_cell(row: int, col: int) -> int
func is_row_complete(row: int) -> bool
func is_col_complete(col: int) -> bool
```

### 6.3 GameState（全局状态 — Autoload）

```gdscript
extends Node

signal album_unlocked(album_id: String)
signal puzzle_completed(puzzle_id: String)
signal picture_completed(picture_id: String)
signal progress_changed

var album_progress: Dictionary = {}
var completed_puzzles: Array = []
var completed_pictures: Array = []

var settings: Dictionary = {
    "bgm_volume": 0.8,
    "sfx_volume": 1.0,
    "difficulty_preference": "auto",
    "show_errors": true,
    "auto_mark": true
}

func is_album_unlocked(album_id: String) -> bool
func complete_puzzle(puzzle_id: String) -> void
func complete_picture(picture_id: String) -> void
func get_album_completion(album_id: String) -> float
func get_picture_completion(picture_id: String) -> float
func save_game() -> void
func load_game() -> void
```

### 6.4 PuzzleData（关卡数据类）

```gdscript
class_name PuzzleData

var id: String
var name: String
var picture_id: String
var rows: int
var cols: int
var row_clues: Array        # Array of Array[int]
var col_clues: Array        # Array of Array[int]
var solution: Array         # Array of Array[int] (0 or 1)
var hint_cells: Array       # Array of Vector2i (预揭示的格子)
var difficulty: String      # "easy" / "medium" / "hard"
var source_rect: Dictionary # 在图片中的位置 {"x": int, "y": int, "w": int, "h": int}

static func from_json(data: Dictionary) -> PuzzleData
static func load_puzzle(puzzle_id: String) -> PuzzleData
func to_json() -> Dictionary
```

### 6.5 AlbumData / PictureData（数据加载层）

```gdscript
class_name AlbumData
static func load_albums() -> Dictionary
static func get_album_list() -> Array
static func get_album(album_id: String) -> Dictionary

class_name PictureData
static func load_pictures(album_id: String) -> Array
static func get_picture(album_id: String, picture_id: String) -> Dictionary
```

***

## 七、视觉风格指南

### 7.1 整体风格定位

- **核心风格**：中国风卡通（Chinese Style Cartoon）
- **设计理念**：将传统中国元素与现代卡通美学相结合，营造亲切、温暖、富有文化底蕴的视觉体验
- **目标受众**：全年龄段，侧重亲子家庭用户

### 7.2 配色规范

| 颜色名称 | 色值      | 用途           |
| ---- | ------- | ------------ |
| 宣纸白  | #F5F0E8 | 主背景色、画布底色    |
| 浅宣灰  | #E8E0D5 | 次要背景、分隔区域    |
| 朱砂红  | #C23B22 | 主强调色、按钮、进度指示 |
| 珊瑚红  | #E85D4C | 交互反馈、高亮提示    |
| 墨黑   | #2C2C2C | 正文文字、图标      |
| 墨灰   | #5A5A5A | 次要文字、说明文字    |
| 靛蓝   | #2E5C8A | 主题色、装饰元素     |
| 青绿   | #3E8B6A | 成功状态、自然主题    |
| 鎏金   | #C9A962 | 装饰边框、标题点缀    |
| 赭石   | #8B4513 | 历史主题、大地色系    |

### 7.3 字体规范

| 用途    | 字体类型                  | 字号范围    | 字重 |
| ----- | --------------------- | ------- | -- |
| 主标题   | 书法风格字体（如站酷文艺体）        | 28-48px | 粗  |
| 副标题   | 书法风格字体                | 20-28px | 中粗 |
| 正文    | 宋体/黑体（思源宋体/思源黑体）      | 14-18px | 常规 |
| 小字说明  | 黑体                    | 12-14px | 细  |
| 数字/符号 | 等宽字体（如JetBrains Mono） | 12-16px | 中等 |

### 7.4 配图风格规范

#### 7.4.1 统一风格要求

- **风格类型**：中国风卡通插画
- **色彩基调**：明亮温暖，饱和度适中
- **线条风格**：圆润流畅，略带书法笔触感
- **人物造型**：Q版卡通风格，比例2-3头身
- **场景构建**：层次分明，富有故事性

## 7.5 数织网格视觉规范

| 元素       | 样式规范                  |
| -------- | --------------------- |
| **网格背景** | 宣纸白色(#F5F0E8)，细灰色网格线  |
| **填充格**  | 主题色渐变（如朱砂红→珊瑚红），圆角2px |
| **标记格**  | 墨灰色半透明叉号(×)，30%透明度    |
| **选中状态** | 浅橙色高亮边框               |
| **完成效果** | 渐显原图分块，配合成功动画         |
| **错误提示** | 红色闪烁边框                |

### 7.6 UI组件风格

#### 7.6.1 按钮

- **主按钮**：朱砂红渐变背景，圆角8px，悬浮时微微放大
- **次按钮**：透明边框，墨灰色文字，悬浮时填充浅宣灰
- **图标按钮**：圆形，hover时显示tooltip

#### 7.6.2 卡片

- 圆角12px，浅宣灰背景，轻微阴影
- 悬浮时阴影加深，微微上移

#### 7.6.3 进度条

- 朱砂红填充，宣纸白背景，圆角4px
- 渐变动画效果

### 7.7 动画效果规范

| 动画类型     | 效果描述       | 适用场景      |
| -------- | ---------- | --------- |
| **转场动画** | 水墨晕染淡入淡出   | 场景切换      |
| **文字动画** | 毛笔书写逐字显示   | 标题、重要文本   |
| **画卷展开** | 卷轴从中间向两侧展开 | 画册打开      |
| **印章盖印** | 印章下落盖印效果   | 成就解锁、关卡完成 |
| **粒子效果** | 花瓣/雪花飘落    | 节日、特殊成就   |
| **数字填充** | 逐格渐显填充     | 数织解谜过程    |

### 7.8 音效与背景音乐

| 类型       | 风格要求                       |
| -------- | -------------------------- |
| **背景音乐** | 以古琴、笛子、古筝、二胡等传统乐器为主，旋律舒缓优美 |
| **点击音效** | 清脆的木鱼声或古琴拨弦声               |
| **填充音效** | 轻柔的墨点音效                    |
| **完成音效** | 欢快的民乐合奏                    |
| **错误音效** | 低沉的古琴单音                    |

### 7.9 图标风格

- **风格**：线性图标为主，略带书法笔触感
- **尺寸**：24×24px（标准），32×32px（大）
- **描边**：2px统一线宽
- **圆角**：适度圆润

***

## 八、开发优先级与里程碑

### Phase 1 — 核心原型

1. ✅ 搭建 Godot 项目基础结构
2. ✅ 实现 NonogramSolver（求解器 + 可推理验证）
3. ✅ 实现 PuzzleGame 场景（数织核心玩法）
4. ✅ 用硬编码的测试关卡验证玩法

### Phase 2 — 数据与流程

1. ✅ 实现 JSON 数据加载系统
2. ✅ 实现 AlbumSelection → PictureList → PictureDetail 场景流程
3. ✅ 实现 GameState 存档系统
4. ✅ 制作 1~2 本画册的完整内容

### Phase 3 — 内容生产（已完成）

1. ✅ 开发 NonogramGenerator 编辑器工具
2. ✅ 批量生成 AI 配图（30张完整画册图片）
3. ✅ 从图片提取分块 → 生成数织关卡 → 验证可推理性
4. ✅ **补全所有画册内容（66本画册，4650张图片，27900个谜题）**

### Phase 4 — 打磨上线 (进行中)

1. 画廊系统 + 收集成就
2. 音效与背景音乐
3. UI 动画与转场效果
4. 多平台适配（PC/移动端）
5. 测试与 Bug 修复

***

## 九、技术风险与应对

| 风险          | 影响     | 应对策略                              |
| ----------- | ------ | --------------------------------- |
| 数织关卡不可推理    | 核心玩法受阻 | Generator 自动调整 + hint_cells 机制兜底 |
| AI 配图分块提取不准 | 关卡质量差  | 半自动工具 + 人工校验                      |
| 大型数织求解性能    | 游戏卡顿   | 限制最大网格20×20，优化 line_solve 算法     |
| 中文内容量巨大     | 开发周期长  | 自动化脚本批量生成，先做1本画册验证再扩展          |
| 移动端数织操作体验   | 交互困难   | 支持拖拽填充、缩放、双指操作                    |