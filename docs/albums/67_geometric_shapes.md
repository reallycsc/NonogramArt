# 《几何图形》Geometric Shapes 画册内容规划

## 画册信息

| 属性 | 内容 |
| ---- | ---- |
| 序号 | 67 |
| 英文名 | Geometric Shapes |
| 书架 | 启蒙乐园 |
| 书架英文名 | Beginner's Paradise |
| 图片数 | 8 |
| 分块数/图 | 1 |
| 谜题数 | 8 |
| 难度配置 | 5×5～15×15 |
| 参考著作 | 欧几里得《几何原本》 |

## 难度设计说明

本画册为新手引导画册，每张图片对应一个数织关卡，难度从5×5逐步递进到15×15。图形设计遵循简单到复杂的原则，帮助玩家逐步掌握数织技巧。

### 难度分布策略

| 难度 | 图片范围 | 图片数量 | 说明 |
| ---- | -------- | -------- | ---- |
| 5×5 | 序号1-4 | 4 | 新手入门关卡 |
| 10×10 | 序号5-8 | 4 | 基础训练关卡 |

### 难度递进示意

```
5×5 (4张) → 10×10 (4张)
第1-4张      第5-8张
```

## 图片内容规划

### 第1章：基础图形 Basic Shapes（4张）

| 序号 | 标题 | 描述 | 英文标题 | 英文描述 | 文件名 | 难度 |
| ---- | ---- | ---- | -------- | -------- | ------ | ---- |
| 1 | 空心正方形 | 正方形是最基础的几何图形，四条边相等，四个角都是直角。 | Hollow Square | The square is the most fundamental geometric shape, with four equal sides and four right angles. | geometric_shapes_000.jpg | 5×5 |
| 2 | 实心三角形 | 三角形是最简单的多边形，由三条边组成。 | Solid Triangle | The triangle is the simplest polygon, composed of three sides. | geometric_shapes_001.jpg | 5×5 |
| 3 | 十字形 | 十字形由两条垂直相交的线段组成，是对称图形的典型代表。 | Cross Shape | The cross shape consists of two vertically intersecting line segments, a typical representative of symmetrical figures. | geometric_shapes_002.jpg | 5×5 |
| 4 | 菱形 | 菱形是四边相等的平行四边形，具有完美的对称性。 | Diamond | The diamond is a parallelogram with four equal sides, possessing perfect symmetry. | geometric_shapes_003.jpg | 5×5 |

### 第2章：组合图形 Composite Shapes（4张）

| 序号 | 标题 | 描述 | 英文标题 | 英文描述 | 文件名 | 难度 |
| ---- | ---- | ---- | -------- | -------- | ------ | ---- |
| 5 | 同心正方形 | 同心正方形由多个嵌套的正方形组成，展示了图形的层次结构。 | Concentric Squares | Concentric squares consist of multiple nested squares, demonstrating the hierarchical structure of shapes. | geometric_shapes_004.jpg | 10×10 |
| 6 | 箭头 | 箭头是由三角形和矩形组合而成的指向性图形，在日常生活中广泛使用。 | Arrow | The arrow is a directional shape composed of a triangle and a rectangle, widely used in daily life. | geometric_shapes_005.jpg | 10×10 |
| 7 | 心形 | 心形是表达爱与情感的象征性图形，由两条曲线在顶部相交形成。 | Heart Shape | The heart shape is a symbolic figure expressing love and emotion, formed by two curves intersecting at the top. | geometric_shapes_006.jpg | 10×10 |
| 8 | 星形 | 星形是由多个三角形围绕中心点排列组成的对称图形，象征着希望与梦想。 | Star Shape | The star shape is a symmetrical figure composed of multiple triangles arranged around a center point, symbolizing hope and dreams. | geometric_shapes_007.jpg | 10×10 |

## 图形网格定义

### 5×5 图形

#### 图形1：空心正方形
```
■ ■ ■ ■ ■
■ □ □ □ ■
■ □ □ □ ■
■ □ □ □ ■
■ ■ ■ ■ ■
```
- 填充率：68%
- 行线索：[5, 1 1, 1 1, 1 1, 5]
- 列线索：[5, 1 1, 1 1, 1 1, 5]

#### 图形2：实心三角形
```
□ □ □ □ ■
□ □ □ ■ ■
□ □ ■ ■ ■
□ ■ ■ ■ ■
■ ■ ■ ■ ■
```
- 填充率：40%
- 行线索：[1, 2, 3, 4, 5]
- 列线索：[2, 3, 4, 5, 1]

#### 图形3：十字形
```
□ □ ■ □ □
□ □ ■ □ □
■ ■ ■ ■ ■
□ □ ■ □ □
□ □ ■ □ □
```
- 填充率：36%
- 行线索：[1, 1, 5, 1, 1]
- 列线索：[1, 1, 5, 1, 1]

#### 图形4：菱形
```
□ □ ■ □ □
□ ■ ■ ■ □
■ ■ ■ ■ ■
□ ■ ■ ■ □
□ □ ■ □ □
```
- 填充率：52%
- 行线索：[1, 3, 5, 3, 1]
- 列线索：[1, 3, 5, 3, 1]

### 10×10 图形

#### 图形5：同心正方形
```
■ ■ ■ ■ ■ ■ ■ ■ ■ ■
■ □ □ □ □ □ □ □ □ ■
■ □ ■ ■ ■ ■ ■ ■ □ ■
■ □ ■ □ □ □ □ ■ □ ■
■ □ ■ □ □ □ □ ■ □ ■
■ □ ■ □ □ □ □ ■ □ ■
■ □ ■ □ □ □ □ ■ □ ■
■ □ ■ ■ ■ ■ ■ ■ □ ■
■ □ □ □ □ □ □ □ □ ■
■ ■ ■ ■ ■ ■ ■ ■ ■ ■
```
- 填充率：64%

#### 图形6：箭头
```
□ □ □ □ ■ ■ □ □ □ □
□ □ □ ■ ■ ■ ■ □ □ □
□ □ ■ ■ ■ ■ ■ ■ □ □
□ ■ ■ ■ ■ ■ ■ ■ ■ □
■ ■ ■ ■ ■ ■ ■ ■ ■ ■
□ □ □ □ ■ ■ □ □ □ □
□ □ □ □ ■ ■ □ □ □ □
□ □ □ □ ■ ■ □ □ □ □
□ □ □ □ ■ ■ □ □ □ □
□ □ □ □ ■ ■ □ □ □ □
```
- 填充率：42%

#### 图形7：心形
```
□ □ ■ ■ □ □ ■ ■ □ □
□ ■ ■ ■ ■ ■ ■ ■ ■ □
■ ■ ■ ■ ■ ■ ■ ■ ■ ■
■ ■ ■ ■ ■ ■ ■ ■ ■ ■
■ ■ ■ ■ ■ ■ ■ ■ ■ ■
□ ■ ■ ■ ■ ■ ■ ■ ■ □
□ □ ■ ■ ■ ■ ■ ■ □ □
□ □ □ ■ ■ ■ ■ □ □ □
□ □ □ □ ■ ■ □ □ □ □
□ □ □ □ □ □ □ □ □ □
```
- 填充率：52%

#### 图形8：星形
```
□ □ □ □ ■ ■ □ □ □ □
□ □ □ □ ■ ■ □ □ □ □
□ ■ ■ ■ ■ ■ ■ ■ ■ □
□ □ □ ■ ■ ■ ■ □ □ □
■ ■ ■ ■ ■ ■ ■ ■ ■ ■
■ ■ ■ ■ ■ ■ ■ ■ ■ ■
□ □ □ ■ ■ ■ ■ □ □ □
□ ■ ■ ■ ■ ■ ■ ■ ■ □
□ □ □ □ ■ ■ □ □ □ □
□ □ □ □ ■ ■ □ □ □ □
```
- 填充率：38%

**图片规格：**
- 分辨率：根据难度动态调整
- 分块方式：1×1 = 1块/图（每张图片对应一个完整关卡）
- 谜题总数：8个

**像素图：**
- 命名规范：原图文件名 + `_pixel.jpg`
- 示例：`geometric_shapes_000_pixel.jpg`

**关卡文件：**
- 目录：`data/puzzles/geometric_shapes/`
- 关卡命名：`{图片ID}.json`
  - 示例：`geometric_shapes_000.json`
