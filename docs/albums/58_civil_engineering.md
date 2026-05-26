# 《土木工程》(Civil Engineering) 画册内容规划

## 画册信息

| 属性 | 内容 |
| ---- | ---- |
| 序号 | 58 |
| 英文名 | Civil Engineering |
| 书架 | 科技工业 |
| 书架英文名 | Science and Technology |
| 图片数 | 65 |
| 分块数/图 | 6 |
| 谜题数 | 390（常规312 + 专家78） |
| 难度配置 | 10×10~25×25 |
| 参考著作 | 茅以升《中国古桥技术史》 |

## 难度设计说明

中等难度范围，适合有一定数织基础的玩家。由于采用动态难度设计（同一图片内6个分块根据复杂度分配不同难度），整体难度递进更快。

### 难度分布策略

| 难度 | 图片范围 | 图片数量 | 说明 |
| ---- | -------- | -------- | ---- |
| 10×10 | 序号1-18 | 18 | 入门难度 |
| 15×15 | 序号19-33 | 15 | 中等难度 |
| 20×20 | 序号34-52 | 19 | 较高难度 |
| 25×25 | 序号53-65 | 13 | 专家难度 |

### 动态难度分配规则

每张图片的6个分块根据内容复杂度动态分配难度，每张图最多包含3种难度：

| 图片难度 | 分块0-1（低复杂度） | 分块2-3（中复杂度） | 分块4-5（高复杂度） |
| -------- | ------------------- | ------------------- | ------------------- |
| 10×10 | 5×5 | 5×5 | 10×10 |
| 15×15 | 5×5 | 10×10 | 15×15 |
| 20×20 | 10×10 | 15×15 | 20×20 |
| 25×25 | 15×15 | 20×20 | 25×25 |

### 难度递进示意

```
10×10 (18张) → 15×15 (15张) → 20×20 (19张) → 25×25 (13张)
第1-18张        第19-33张          第34-52张        第53-65张
```

## 徽章设计

| 章节 | 章节名称 | 章节英文名 | 图片数 | 徽章样式 |
| ---- | -------- | ---------- | ------ | -------- |
| 第1章 | 桥梁工程 | Bridge Engineering | 16 | 圆形徽章，底色深蓝，中央拱桥悬索，边缘钢缆纹饰 |
| 第2章 | 建筑工程 | Building Engineering | 16 | 圆形徽章，底色砖红，中央摩天大楼，边缘梁柱纹饰 |
| 第3章 | 交通工程 | Transportation Engineering | 17 | 圆形徽章，底色墨绿，中央高铁隧道，边缘铁轨纹饰 |
| 第4章 | 水利环境 | Water Resources and Environment | 16 | 圆形徽章，底色湖蓝，中央大坝水轮，边缘波纹纹饰 |

## 图片内容规划

### 第1章：桥梁工程 Bridge Engineering（16张）

| 序号 | 章节 | 标题 | 描述 | 英文标题 | 英文描述 | 文件名 | 难度 |
| ---- | ---- | ---- | ---- | -------- | -------- | ------ | ---- |
| 1 | 第1章 | 梁桥最简 | 梁桥是最简单的桥型，横梁架在桥墩上承受弯矩，简支梁和连续梁是基本形式。梁桥是桥梁的起点，从独木桥到公路梁桥原理一脉相承。 | Beam Bridge: The Simplest | Beam bridges are the simplest type; horizontal beams rest on piers bearing bending moments; simply supported and continuous beams are basic forms. Beam bridges are the starting point of bridge engineering; from log bridges to highway beam bridges, the principle is the same. | civil_engineering_000.jpg | 10×10 |
| 2 | 第1章 | 拱桥推力 | 拱桥将竖向荷载转为拱脚水平推力，石拱和钢拱利用受压优势跨越更大距离。赵州桥历经一千四百年仍屹立不倒，拱的力学之美穿越千年。 | Arch Bridge Thrust | Arch bridges convert vertical loads into horizontal thrust at the abutments; stone and steel arches use compression advantages to span greater distances. The Zhaozhou Bridge has stood for 1,400 years; the mechanical beauty of arches transcends millennia. | civil_engineering_001.jpg | 10×10 |
| 3 | 第1章 | 悬索桥主缆 | 悬索桥用主缆悬挂桥面，主缆锚固在两岸锚碇承受全部拉力，跨度可达两千米。金门大桥和明石海峡大桥是悬索桥的杰作，抛物线主缆是最美的结构线形。 | Suspension Bridge Main Cables | Suspension bridges hang the deck from main cables; cables are anchored at both shores bearing all tension, with spans reaching 2,000 meters. The Golden Gate Bridge and Akashi Kaikyo Bridge are masterpieces; parabolic main cables form the most beautiful structural lines. | civil_engineering_002.jpg | 10×10 |
| 4 | 第1章 | 斜拉桥索面 | 斜拉桥用斜拉索从桥塔直接拉住桥面，扇形索面如竖琴般优美。斜拉桥是二十世纪的桥型创新，苏通大桥主跨一千零八十八米曾是世界纪录。 | Cable-Stayed Bridge Cable Planes | Cable-stayed bridges use stay cables directly from towers to support the deck; fan-shaped cable planes are as elegant as harps. Cable-stayed bridges are a 20th-century innovation; the Sutong Bridge's 1,088-meter main span was once a world record. | civil_engineering_003.jpg | 10×10 |
| 5 | 第1章 | 桁架桥三角 | 桁架由三角形单元组成，杆件只受轴向拉压不受弯，用钢量少跨越能力强。桁架桥是铁路桥的经典形式，华伦桁架和普拉特桁架各有优劣。 | Truss Bridge Triangles | Trusses consist of triangular units; members carry only axial tension or compression without bending, using less steel for greater spans. Truss bridges are classic railway bridge forms; Warren and Pratt trusses each have their advantages. | civil_engineering_004.jpg | 10×10 |
| 6 | 第1章 | 刚构桥固结 | 刚构桥的梁和墩刚性连接形成门式框架，墩底固结承受弯矩和剪力。刚构桥适合跨越深谷，梁墩固结让结构更整体更经济。 | Rigid Frame Bridge Fixity | Rigid frame bridges have beams rigidly connected to piers forming portal frames; fixed pier bases resist bending moments and shear. Rigid frame bridges suit deep valley crossings; beam-pier fixity makes the structure more integral and economical. | civil_engineering_005.jpg | 10×10 |
| 7 | 第1章 | 桥梁基础深 | 桥梁基础深入河床以下，桩基和沉井将桥墩荷载传至坚实持力层。桥梁基础是看不见的关键，深水基础施工是桥梁建设最大的挑战。 | Deep Bridge Foundations | Bridge foundations extend below the riverbed; piles and caissons transfer pier loads to solid bearing strata. Bridge foundations are the unseen key; deep-water foundation construction is the greatest challenge in bridge building. | civil_engineering_006.jpg | 10×10 |
| 8 | 第1章 | 桥梁抗震 | 地震作用下桥梁墩柱承受往复水平力，延性设计让墩柱在塑性铰处耗能不倒塌。桥梁抗震是生命线工程的安全保障，减隔震支座降低地震输入。 | Bridge Seismic Resistance | Under earthquakes, bridge pier columns bear cyclic horizontal forces; ductility design allows piers to dissipate energy at plastic hinges without collapsing. Bridge seismic resistance ensures the safety of lifeline engineering; seismic isolation bearings reduce earthquake input. | civil_engineering_007.jpg | 10×10 |
| 9 | 第1章 | 桥梁风振 | 大跨度悬索桥在风荷载下产生涡振和颤振，塔科马海峡桥风毁是惨痛教训。桥梁抗风设计通过风洞试验和气动优化确保安全，导流板和开槽抑制振动。 | Bridge Wind-Induced Vibration | Long-span suspension bridges experience vortex shedding and flutter under wind; the Tacoma Narrows Bridge wind failure was a painful lesson. Bridge wind resistance design ensures safety through wind tunnel testing and aerodynamic optimization; guide vanes and slots suppress vibrations. | civil_engineering_008.jpg | 10×10 |
| 10 | 第1章 | 桥梁施工控制 | 悬臂施工逐段浇筑逐段张拉，每个节段的标高和索力都需精确控制。桥梁施工是动态过程，线形和内力随施工阶段不断变化需实时调整。 | Bridge Construction Control | Cantilever construction casts and post-tensions segment by segment; elevation and cable force of each segment require precise control. Bridge construction is a dynamic process; geometry and internal forces change continuously and need real-time adjustment. | civil_engineering_009.jpg | 10×10 |
| 11 | 第1章 | 桥梁健康监测 | 传感器实时监测桥梁应变位移和振动，大数据分析发现早期损伤预警安全。桥梁健康监测是数字孪生的起点，让每座桥都有自己的健康档案。 | Bridge Health Monitoring | Sensors monitor bridge strain, displacement, and vibration in real time; big data analysis detects early damage for safety warning. Bridge health monitoring is the starting point of digital twins; every bridge gets its own health record. | civil_engineering_010.jpg | 10×10 |
| 12 | 第1章 | 钢桥焊接疲劳 | 钢桥焊缝在车辆反复荷载下产生疲劳裂纹，正交异性钢桥面板是疲劳高发区。疲劳是钢桥的慢性病，定期检测和加固延长使用寿命。 | Steel Bridge Welding Fatigue | Steel bridge welds develop fatigue cracks under repeated vehicle loads; orthotropic steel bridge decks are fatigue-prone areas. Fatigue is a chronic disease of steel bridges; regular inspection and reinforcement extend service life. | civil_engineering_011.jpg | 10×10 |
| 13 | 第1章 | 混凝土桥耐久 | 氯离子侵入混凝土导致钢筋锈蚀膨胀剥落，是海港桥梁的头号耐久性问题。混凝土耐久性设计用高性能混凝土和防腐涂层延长桥梁寿命。 | Concrete Bridge Durability | Chloride intrusion into concrete causes rebar corrosion, expansion, and spalling; the number one durability problem for harbor bridges. Concrete durability design uses high-performance concrete and anti-corrosion coatings to extend bridge life. | civil_engineering_012.jpg | 10×10 |
| 14 | 第1章 | 组合桥协同 | 钢梁和混凝土桥面板通过剪力连接件协同工作，钢受拉混凝土受压各展所长。组合结构是材料优化的典范，比纯钢结构省混凝土比纯混凝土省钢。 | Composite Bridge Synergy | Steel beams and concrete bridge decks work together through shear connectors; steel takes tension, concrete takes compression, each playing to its strength. Composite structures are models of material optimization; saving concrete versus pure steel, saving steel versus pure concrete. | civil_engineering_013.jpg | 10×10 |
| 15 | 第1章 | 顶推法架设 | 桥梁在岸上逐段预制后用千斤顶顶推就位，不搭支架不影响通航。顶推法是跨线跨河桥的巧妙施工方案，梁体在墩顶滑道上缓缓前行。 | Incremental Launching Erection | Bridges are prefabricated segment by segment on shore and pushed into position by jacks; no scaffolding, no navigation interference. Incremental launching is a clever construction method for overpass and river bridges; the superstructure slowly advances on pier-top slide tracks. | civil_engineering_014.jpg | 10×10 |
| 16 | 第1章 | 转体法施工 | 桥梁在两岸旋转施工后转体合龙，跨越铁路和峡谷时避免中断交通。转体施工是桥梁建设的奇招，万吨桥体在球铰上旋转九度合龙。 | Swing Method Construction | Bridges are constructed on both shores then rotated to close; crossing railways and gorges without interrupting traffic. Swing construction is a brilliant bridge-building technique; ten-thousand-ton bridge bodies rotate on spherical bearings to close. | civil_engineering_015.jpg | 10×10 |

### 第2章：建筑工程 Building Engineering（16张）

| 序号 | 章节 | 标题 | 描述 | 英文标题 | 英文描述 | 文件名 | 难度 |
| ---- | ---- | ---- | ---- | -------- | -------- | ------ | ---- |
| 17 | 第2章 | 框架结构梁柱 | 钢筋混凝土框架由梁柱刚性连接组成，梁承受楼面荷载柱将力传至基础。框架结构是最常见的建筑结构，灵活分隔空间适合办公楼和商场。 | Frame Structure Beams and Columns | Reinforced concrete frames consist of rigidly connected beams and columns; beams carry floor loads, columns transfer forces to foundations. Frame structures are the most common building structures; flexible space division suits offices and shopping malls. | civil_engineering_016.jpg | 10×10 |
| 18 | 第2章 | 剪力墙抗侧 | 剪力墙承受水平风荷载和地震作用，是高层建筑的抗侧力体系核心。剪力墙刚度大侧移小，框剪结构兼具框架的灵活和剪力墙的刚强。 | Shear Wall Lateral Resistance | Shear walls resist horizontal wind loads and seismic forces; the core of tall building lateral force systems. Shear walls have high stiffness and small drift; frame-shear wall structures combine frame flexibility with shear wall rigidity. | civil_engineering_017.jpg | 10×10 |
| 19 | 第2章 | 核心筒超高层 | 核心筒布置在建筑中心包围电梯楼梯，是超高层的主要抗侧力构件。核心筒加外框筒形成筒中筒结构，上海中心大厦就是这种体系。 | Core Tube Supertall | Core tubes surround elevators and stairs at the building center; the main lateral force element in supertalls. Core tube plus outer framed tube form tube-in-tube structures; the Shanghai Tower uses this system. | civil_engineering_018.jpg | 10×10 |
| 20 | 第2章 | 钢结构轻巧 | 钢结构强度高自重轻施工快，是超高层和大跨空间的首选结构。钢结构耐火性差需防火涂料，鸟巢和国家大剧院都是钢结构杰作。 | Steel Structure Lightweight | Steel structures have high strength, light weight, and fast construction; the preferred structure for supertalls and large-span spaces. Steel has poor fire resistance requiring protective coatings; the Bird's Nest and National Centre for the Performing Arts are steel structure masterpieces. | civil_engineering_019.jpg | 15×15 |
| 21 | 第2章 | 网壳空间结构 | 网壳由钢管杆件组成空间曲面，用最少的材料覆盖最大的空间。网壳是建筑与结构的完美结合，国家游泳中心水立方的膜结构是另一种空间覆盖。 | Reticulated Shell Spatial Structure | Reticulated shells consist of steel tube members forming spatial curved surfaces; covering the largest space with the least material. Reticulated shells are the perfect union of architecture and structure; the Water Cube's membrane structure is another spatial enclosure. | civil_engineering_020.jpg | 15×15 |
| 22 | 第2章 | 张弦梁杂交 | 张弦梁上弦受压下弦受拉撑杆连接，预应力让结构更轻更刚。张弦梁是刚柔并济的结构，上海浦东机场航站楼就用了张弦梁。 | Beam String Hybrid Structure | Beam string structures have compression upper chords, tension lower chords, and struts connecting them; prestressing makes the structure lighter and stiffer. Beam strings combine rigidity and flexibility; the Shanghai Pudong Airport terminal uses beam string structures. | civil_engineering_021.jpg | 15×15 |
| 23 | 第2章 | 地基基础承载 | 建筑荷载通过基础传给地基土层，浅基础用于硬土深基础用于软土。地基承载力决定建筑能建多高，桩基将荷载传到深层坚硬土层。 | Foundation Bearing Capacity | Building loads are transferred to soil through foundations; shallow foundations for hard soil, deep foundations for soft soil. Foundation bearing capacity determines how tall a building can be; piles transfer loads to deep hard soil layers. | civil_engineering_022.jpg | 15×15 |
| 24 | 第2章 | 深基坑支护 | 城市建筑地下室施工需开挖深基坑，地下连续墙和内支撑防止土体坍塌。深基坑是城市建设的地下战场，周边建筑和管线的保护至关重要。 | Deep Excavation Support | Urban building basements require deep excavation; diaphragm walls and internal bracing prevent soil collapse. Deep excavations are the underground battlefields of urban construction; protecting adjacent buildings and utilities is crucial. | civil_engineering_023.jpg | 15×15 |
| 25 | 第2章 | 混凝土浇筑 | 混凝土由水泥砂石和水拌合后浇筑入模，振捣密实养护成型。混凝土是最重要的建筑材料，预拌混凝土泵送技术让高层浇筑成为可能。 | Concrete Pouring | Concrete is mixed from cement, sand, aggregate, and water, then poured into forms, vibrated, and cured. Concrete is the most important building material; ready-mix concrete pumping technology enables high-rise pouring. | civil_engineering_024.jpg | 15×15 |
| 26 | 第2章 | 预应力混凝土 | 预应力混凝土先张拉钢筋再浇筑混凝土，预压应力抵消外荷载产生的拉应力。预应力让混凝土梁跨越更大距离更轻更薄，大跨桥梁和体育馆屋盖常用。 | Prestressed Concrete | Prestressed concrete first tensions steel then pours concrete; precompression offsets tensile stress from external loads. Prestressing enables concrete beams to span greater distances, lighter and thinner; commonly used in long-span bridges and gymnasium roofs. | civil_engineering_025.jpg | 15×15 |
| 27 | 第2章 | 建筑抗震设计 | 建筑抗震设计按设防烈度确定地震力，小震不坏中震可修大震不倒。抗震设计是建筑安全的底线，延性构造让建筑在地震中耗能不倒塌。 | Building Seismic Design | Building seismic design determines earthquake forces based on fortification intensity; no damage under minor quakes, repairable under moderate, no collapse under major. Seismic design is the baseline of building safety; ductile detailing allows buildings to dissipate energy without collapsing. | civil_engineering_026.jpg | 15×15 |
| 28 | 第2章 | 隔震减震 | 隔震支座在基础和上部结构之间设置柔性层，将地震力隔离在上部结构之外。隔震技术可降低地震力百分之六十以上，是建筑抗震的革命性方案。 | Seismic Isolation and Damping | Isolation bearings install a flexible layer between foundation and superstructure, isolating seismic forces from the upper structure. Isolation technology can reduce seismic forces by over 60%; a revolutionary approach to building seismic resistance. | civil_engineering_027.jpg | 15×15 |
| 29 | 第2章 | BIM数字建造 | BIM将建筑信息整合到三维模型中，设计施工运维全生命周期共享数据。BIM是建筑业的数字化转型，碰撞检测和虚拟施工减少返工浪费。 | BIM Digital Construction | BIM integrates building information into 3D models; data is shared across the entire lifecycle of design, construction, and operations. BIM is the digital transformation of the construction industry; clash detection and virtual construction reduce rework and waste. | civil_engineering_028.jpg | 15×15 |
| 30 | 第2章 | 装配式建筑 | 装配式建筑将构件在工厂预制后运到现场拼装，减少现场湿作业缩短工期。装配式建筑是建筑工业化的方向，像搭积木一样盖房子。 | Prefabricated Buildings | Prefabricated buildings produce components in factories then assemble on-site; reducing wet work and shortening construction schedules. Prefabricated construction is the direction of building industrialization; building houses like assembling blocks. | civil_engineering_029.jpg | 15×15 |
| 31 | 第2章 | 绿色建筑节能 | 绿色建筑用保温隔热和自然通风减少能耗，太阳能和雨水回收实现资源循环。绿色建筑是可持续发展的建筑理念，LEED认证是全球绿色建筑标准。 | Green Building Energy Efficiency | Green buildings use insulation and natural ventilation to reduce energy consumption; solar energy and rainwater recycling achieve resource circulation. Green building is the sustainable development concept; LEED certification is the global green building standard. | civil_engineering_030.jpg | 15×15 |
| 32 | 第2章 | 超高层挑战 | 超高层建筑面临风荷载振动和电梯分区等挑战，结构体系和机电设备都需要创新。超高层是人类建筑技术的巅峰，迪拜哈利法塔八百二十八米是当前最高。 | Supertall Challenges | Supertall buildings face challenges of wind loads, vibration, and elevator zoning; structural systems and MEP systems both need innovation. Supertalls are the pinnacle of building technology; Dubai's Burj Khalifa at 828 meters is currently the tallest. | civil_engineering_031.jpg | 15×15 |

### 第3章：交通工程 Transportation Engineering（17张）

| 序号 | 章节 | 标题 | 描述 | 英文标题 | 英文描述 | 文件名 | 难度 |
| ---- | ---- | ---- | ---- | -------- | -------- | ------ | ---- |
| 33 | 第3章 | 隧道掘进盾构 | 盾构机在地下旋转刀盘切削土体，拼装管片形成衬砌，泥水或土压平衡维持开挖面稳定。盾构隧道是城市地铁和越江通道的首选工法，直径十五米的盾构机是地下巨无霸。 | Shield Tunnel Boring | Shield machines rotate cutterheads to excavate soil underground, assembling segments for lining; slurry or earth pressure balance maintains face stability. Shield tunnels are the preferred method for urban subways and river crossings; 15-meter diameter shields are underground giants. | civil_engineering_032.jpg | 15×15 |
| 34 | 第3章 | 隧道新奥法 | 新奥法利用围岩自身承载能力，喷锚支护和监控量测动态调整支护参数。新奥法是山岭隧道的经典工法，围岩是隧道结构的一部分。 | NATM Tunneling | NATM utilizes the surrounding rock's self-bearing capacity; shotcrete-bolt support and monitoring dynamically adjust support parameters. NATM is the classic method for mountain tunnels; surrounding rock is part of the tunnel structure. | civil_engineering_033.jpg | 15×15 |
| 35 | 第3章 | 沉管隧道水下 | 预制管段浮运至水面上沉放对接，水下连接形成隧道，港珠澳大桥海底隧道就是沉管法。沉管隧道是跨越深水航道的方案，管段在水下精确对接是施工难点。 | Immersed Tube Tunnel Underwater | Prefabricated tube sections are floated to position, sunk, and connected underwater; the Hong Kong-Zhuhai-Macao Bridge subsea tunnel uses this method. Immersed tube tunnels cross deep navigation channels; precise underwater connection is the construction challenge. | civil_engineering_034.jpg | 20×20 |
| 36 | 第3章 | 高速铁路轨道 | 高速铁路无砟轨道精度要求毫米级，路基沉降控制严格保证高速行车平顺性。高铁轨道是精密工程，三百五十公里时速下轨道不平顺不超过两毫米。 | High-Speed Railway Track | High-speed railway ballastless tracks require millimeter-level precision; strict subgrade settlement control ensures smooth high-speed running. HSR tracks are precision engineering; at 350 km/h, track irregularity must not exceed 2 mm. | civil_engineering_035.jpg | 20×20 |
| 37 | 第3章 | 公路线形设计 | 公路线形设计综合考虑平曲线竖曲线和视距，确保行车安全和舒适。公路设计是速度与安全的平衡，曲线半径和纵坡限制随设计速度提高而加严。 | Highway Alignment Design | Highway alignment design comprehensively considers horizontal curves, vertical curves, and sight distance, ensuring driving safety and comfort. Highway design balances speed and safety; curve radius and gradient limits become stricter as design speed increases. | civil_engineering_036.jpg | 20×20 |
| 38 | 第3章 | 机场跑道 | 机场跑道混凝土道面承受飞机起降冲击荷载，道面强度和平整度要求极高。跑道是机场的生命线，道面下多层结构确保承载力和排水。 | Airport Runway | Airport runway concrete pavements bear aircraft landing impact loads; extremely high requirements for pavement strength and evenness. Runways are the airport's lifeline; multi-layer substructure ensures bearing capacity and drainage. | civil_engineering_037.jpg | 20×20 |
| 39 | 第3章 | 港口码头 | 重力式码头用沉箱和块石抵抗土压力，高桩码头用桩基支撑上部结构。港口是海上贸易的门户，深水泊位可停靠二十万吨级集装箱船。 | Port and Wharf | Gravity wharves use caissons and rubble to resist earth pressure; high-pile wharves use pile foundations to support superstructures. Ports are gateways for maritime trade; deep-water berths can accommodate 200,000-ton container ships. | civil_engineering_038.jpg | 20×20 |
| 40 | 第3章 | 交通信号控制 | 交通信号灯用红黄绿三色控制路口通行权，智能信号根据车流量动态调整配时。交通信号是城市交通的指挥棒，自适应信号系统减少路口等待时间。 | Traffic Signal Control | Traffic signals use red, yellow, and green to control intersection right-of-way; intelligent signals dynamically adjust timing based on traffic flow. Traffic signals are the baton of urban traffic; adaptive signal systems reduce intersection waiting times. | civil_engineering_039.jpg | 20×20 |
| 41 | 第3章 | 轨道交通地铁 | 地铁在地下隧道中运行不受地面交通影响，是城市大运量公共交通的骨干。地铁建设成本高但运量大效率高，是百万人口以上城市的标配。 | Rail Transit Subway | Subways operate in underground tunnels unaffected by surface traffic; the backbone of urban mass transit. Subway construction is costly but offers high capacity and efficiency; standard for cities with over one million population. | civil_engineering_040.jpg | 20×20 |
| 42 | 第3章 | 磁悬浮列车 | 磁悬浮列车用电磁力悬浮和推进，无轮轨摩擦速度可达六百公里每小时。磁悬浮是轨道交通的尖端技术，上海磁浮示范线运营已超二十年。 | Maglev Train | Maglev trains use electromagnetic forces for levitation and propulsion; without wheel-rail friction, speeds reach 600 km/h. Maglev is cutting-edge rail transit technology; the Shanghai Maglev Demonstration Line has operated for over 20 years. | civil_engineering_041.jpg | 20×20 |
| 43 | 第3章 | 智慧交通系统 | 智慧交通用摄像头和传感器采集路况信息，导航软件实时推荐最优路线。智慧交通是交通管理的未来，车路协同让自动驾驶更安全。 | Intelligent Transportation System | Intelligent transportation uses cameras and sensors to collect traffic data; navigation apps recommend optimal routes in real time. Intelligent transportation is the future of traffic management; vehicle-infrastructure cooperation makes autonomous driving safer. | civil_engineering_042.jpg | 20×20 |
| 44 | 第3章 | 立交枢纽 | 立交桥用匝道连接不同方向道路，消除交叉冲突点提高通行效率。立交枢纽是城市交通的关节，苜蓿叶和定向匝道各有适用场景。 | Interchange Hub | Interchanges use ramps to connect roads in different directions, eliminating crossing conflicts and improving traffic efficiency. Interchange hubs are the joints of urban traffic; cloverleaf and directional ramps each have applicable scenarios. | civil_engineering_043.jpg | 20×20 |
| 45 | 第3章 | 路基路面工程 | 路基用土石填筑或开挖形成，路面上层沥青下层碎石分层压实。路基路面是公路的骨架和皮肤，水损害是路面破坏的头号杀手。 | Subgrade and Pavement Engineering | Subgrades are formed by earthwork filling or excavation; pavements have asphalt surface layers over crushed stone base, compacted in layers. Subgrade and pavement are the skeleton and skin of highways; water damage is the number one killer of pavement. | civil_engineering_044.jpg | 20×20 |
| 46 | 第3章 | 桥梁伸缩缝 | 桥梁伸缩缝适应温度变化和车辆荷载引起的梁端位移，保证行车平顺。伸缩缝是桥梁的关节，模数式伸缩缝可适应大位移且降噪。 | Bridge Expansion Joints | Bridge expansion joints accommodate beam-end displacement from temperature changes and vehicle loads, ensuring smooth riding. Expansion joints are the joints of bridges; modular expansion joints accommodate large displacements with noise reduction. | civil_engineering_045.jpg | 20×20 |
| 47 | 第3章 | 支座传力 | 桥梁支座将上部结构荷载传给墩台，同时适应温度变形和地震位移。支座是桥梁的关节，橡胶支座和球形钢支座各有适用场景。 | Bearing Force Transfer | Bridge bearings transfer superstructure loads to piers and abutments while accommodating thermal deformation and seismic displacement. Bearings are the joints of bridges; rubber and spherical steel bearings each have applicable scenarios. | civil_engineering_046.jpg | 20×20 |
| 48 | 第3章 | 交通规划 | 交通规划预测未来出行需求，确定道路网和公共交通布局。交通规划是城市发展的蓝图，职住平衡和TOD模式减少长距离通勤。 | Transportation Planning | Transportation planning forecasts future travel demand and determines road network and public transit layout. Transportation planning is the blueprint for urban development; job-housing balance and TOD reduce long-distance commuting. | civil_engineering_047.jpg | 20×20 |
| 49 | 第3章 | 交通安全设施 | 护栏防撞和标志标线引导是交通安全设施的核心，减少事故和减轻伤害。交通安全设施是公路的守护者，波形梁护栏和防眩板保护夜间行车。 | Traffic Safety Facilities | Crash barriers, signs, and markings are the core of traffic safety facilities, reducing accidents and mitigating injuries. Traffic safety facilities are highway guardians; corrugated beam barriers and anti-glare screens protect nighttime driving. | civil_engineering_048.jpg | 20×20 |

### 第4章：水利环境 Water Resources and Environment（16张）

| 序号 | 章节 | 标题 | 描述 | 英文标题 | 英文描述 | 文件名 | 难度 |
| ---- | ---- | ---- | ---- | -------- | -------- | ------ | ---- |
| 50 | 第4章 | 大坝挡水 | 混凝土重力坝靠自重抵抗水压力，土石坝靠坝体重量和防渗心墙挡水。大坝是水利枢纽的核心，三峡大坝坝高一百八十一米是世界最大的混凝土重力坝。 | Dam Water Retention | Concrete gravity dams resist water pressure by self-weight; earth-rock dams rely on weight and impervious cores. Dams are the core of water conservancy hubs; the Three Gorges Dam at 181 meters is the world's largest concrete gravity dam. | civil_engineering_049.jpg | 20×20 |
| 51 | 第4章 | 溢洪道泄洪 | 溢洪道在洪水期将多余水量安全泄放，挑流消能将水流抛入空中跌入水垫消能。溢洪道是大坝的安全阀，设计洪水标准确保千年一遇洪水不漫坝。 | Spillway Flood Discharge | Spillways safely release excess water during floods; trajectory bucket energy dissipators throw water into the air to plunge into plunge pools. Spillways are the safety valves of dams; design flood standards ensure no overtopping during 1,000-year floods. | civil_engineering_050.jpg | 20×20 |
| 52 | 第4章 | 灌溉渠道 | 灌溉渠道将水从水库输送到农田，衬砌减少渗漏提高输水效率。灌溉是农业的命脉，滴灌和喷灌比漫灌节水百分之三十以上。 | Irrigation Canals | Irrigation canals transport water from reservoirs to farmland; lining reduces seepage and improves conveyance efficiency. Irrigation is the lifeline of agriculture; drip and sprinkler irrigation save over 30% water compared to flood irrigation. | civil_engineering_051.jpg | 20×20 |
| 53 | 第4章 | 防洪堤防 | 防洪堤沿河岸修建阻挡洪水漫溢，堤身用黏土防渗砂砾石排水。防洪堤是河流的城墙，千年一遇的防洪标准保护城市安全。 | Flood Protection Levees | Flood levees are built along riverbanks to prevent flood overflow; levee bodies use clay for seepage control and gravel for drainage. Flood levees are rivers' city walls; 1,000-year flood protection standards safeguard cities. | civil_engineering_052.jpg | 25×25 |
| 54 | 第4章 | 供水管网 | 城市供水管网将自来水厂的水输送到千家万户，管材和压力分区确保水质水量。供水管网是城市的血脉，漏损控制是供水管理的永恒主题。 | Water Supply Network | Urban water supply networks deliver treated water from plants to households; pipe materials and pressure zones ensure water quality and quantity. Water supply networks are the city's blood vessels; leakage control is the eternal theme of water supply management. | civil_engineering_053.jpg | 25×25 |
| 55 | 第4章 | 排水污水处理 | 城市污水通过管网收集到污水处理厂，生化处理去除有机物和氮磷后达标排放。污水处理是城市卫生的保障，从一级处理到深度处理水质逐步提升。 | Drainage and Wastewater Treatment | Urban sewage is collected through pipe networks to treatment plants; biological treatment removes organics, nitrogen, and phosphorus before compliant discharge. Wastewater treatment safeguards urban sanitation; water quality improves progressively from primary to advanced treatment. | civil_engineering_054.jpg | 25×25 |
| 56 | 第4章 | 海绵城市 | 海绵城市用透水铺装和雨水花园吸收雨水，减少内涝和面源污染。海绵城市是雨洪管理的新理念，让城市像海绵一样吸水释水。 | Sponge City | Sponge cities use permeable paving and rain gardens to absorb rainwater, reducing flooding and non-point source pollution. The sponge city is a new concept in stormwater management; letting cities absorb and release water like sponges. | civil_engineering_055.jpg | 25×25 |
| 57 | 第4章 | 南水北调 | 南水北调工程将长江水调往北方缺水地区，东中西三条调水线路总长数千公里。南水北调是世纪工程，解决中国水资源南北不均的战略举措。 | South-to-North Water Diversion | The South-to-North Water Diversion transfers Yangtze River water to water-scarce northern regions; three routes span thousands of kilometers. The diversion is a century project; a strategic measure to address China's north-south water imbalance. | civil_engineering_056.jpg | 25×25 |
| 58 | 第4章 | 岩土工程边坡 | 边坡失稳滑坡是地质灾害的主要形式，锚索和挡土墙是常用加固措施。岩土工程研究土和岩石的力学性质，是土木工程的地基。 | Geotechnical Slope Engineering | Slope instability and landslides are major geological hazards; anchor cables and retaining walls are common reinforcement measures. Geotechnical engineering studies the mechanical properties of soil and rock, the foundation of civil engineering. | civil_engineering_057.jpg | 25×25 |
| 59 | 第4章 | 地下空间开发 | 城市地下空间开发建设地铁商场和综合管廊，缓解地面空间不足。地下空间是城市的第二层，深层地下空间开发是未来的方向。 | Underground Space Development | Urban underground space development builds subways, malls, and utility tunnels, alleviating surface space shortage. Underground space is the city's second layer; deep underground development is the future direction. | civil_engineering_058.jpg | 25×25 |
| 60 | 第4章 | 结构健康监测 | 传感器网络实时监测建筑和桥梁的应力变形和振动，数字孪生模型同步更新。结构健康监测是工程安全的守护者，从定期检测到实时监测是质的飞跃。 | Structural Health Monitoring | Sensor networks monitor building and bridge stress, deformation, and vibration in real time; digital twin models update synchronously. Structural health monitoring is the guardian of engineering safety; from periodic inspection to real-time monitoring is a qualitative leap. | civil_engineering_059.jpg | 25×25 |
| 61 | 第4章 | 工程测量定位 | 全站仪和GPS定位工程控制点，无人机航测快速获取地形数据。工程测量是建设的眼睛，毫米级精度确保工程按设计精确实施。 | Engineering Survey Positioning | Total stations and GPS position engineering control points; drone aerial surveys rapidly acquire topographic data. Engineering surveying is the eyes of construction; millimeter-level precision ensures projects are built exactly as designed. | civil_engineering_060.jpg | 25×25 |
| 62 | 第4章 | 建筑声学隔声 | 建筑声学设计控制室内混响时间和隔声量，音乐厅追求完美音质住宅追求安静。声学是建筑环境的隐形维度，吸声材料和隔声构造是两大手段。 | Architectural Acoustics Sound Insulation | Architectural acoustics design controls indoor reverberation time and sound insulation; concert halls pursue perfect acoustics, residences pursue quietness. Acoustics is the invisible dimension of the built environment; sound-absorbing materials and sound-insulating construction are two main approaches. | civil_engineering_061.jpg | 25×25 |
| 63 | 第4章 | 建筑采光照明 | 自然采光用天窗和采光井引入阳光，人工照明用LED灯具创造舒适光环境。建筑采光是节能和健康的平衡，日光系数和照度标准指导设计。 | Building Daylighting and Lighting | Natural daylighting introduces sunlight through skylights and light wells; artificial lighting uses LED fixtures to create comfortable luminous environments. Building daylighting balances energy efficiency and health; daylight factor and illuminance standards guide design. | civil_engineering_062.jpg | 25×25 |
| 64 | 第4章 | 建筑暖通空调 | 暖通空调系统调节室内温度湿度和空气质量，地源热泵利用地下恒温层节能。暖通是建筑的环境控制系统，舒适和节能是永恒的追求。 | Building HVAC | HVAC systems regulate indoor temperature, humidity, and air quality; ground-source heat pumps use underground constant temperature for energy savings. HVAC is the building's environmental control system; comfort and energy efficiency are eternal pursuits. | civil_engineering_063.jpg | 25×25 |
| 65 | 第4章 | 城市规划布局 | 城市规划确定用地性质和开发强度，功能分区和交通网络塑造城市形态。城市规划是城市发展的顶层设计，宜居性和可持续性是核心目标。 | Urban Planning Layout | Urban planning determines land use and development intensity; functional zoning and transportation networks shape urban form. Urban planning is the top-level design for city development; livability and sustainability are core objectives. | civil_engineering_064.jpg | 25×25 |

**图片规格：**
- 分辨率：2496×1664（3:2宽高比）
- 分块方式：3×2 = 6块/图
- 常规谜题数：312个（前52张图每张6个分块谜题）
- **25×25专家谜题数**：78个（第53-65号图片各6个分块谜题）
- 谜题总数：403个

**像素图：**
- 命名规范：原图文件名 + `_pixel.jpg`
- 示例：`civil_engineering_000_pixel.jpg`

**关卡文件：**
- 目录：`data/puzzles/civil_engineering/`
- 常规关卡命名：`{图片ID}_{分块索引}.json`
  - 示例：`civil_engineering_000_0.json` ~ `civil_engineering_000_5.json`
- 专家关卡命名：`{图片ID}_expert.json`
  - 示例：`civil_engineering_052_expert.json`
  - 仅第53-65号图片包含专家关卡
