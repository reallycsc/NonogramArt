# 《工业生产》Industrial Production 画册内容规划

## 画册信息

| 属性 | 内容 |
| ---- | ---- |
| 序号 | 60 |
| 英文名 | Industrial Production |
| 书架 | 科技工业 |
| 书架英文名 | Science & Industry |
| 图片数 | 65 |
| 分块数/图 | 6 |
| 谜题数 | 390（常规312 + 专家78） |
| 难度配置 | 10×10~25×25 |
| 参考著作 | 泰勒《科学管理原理》 |

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
| 第1章 | 工业革命 | Industrial Revolution | 16 | 圆形徽章，底色古铜，中央蒸汽机齿轮，边缘铆钉纹饰 |
| 第2章 | 制造技术 | Manufacturing Technology | 16 | 圆形徽章，底色钢灰，中央流水线机械臂，边缘螺栓纹饰 |
| 第3章 | 现代工业 | Modern Industry | 17 | 圆形徽章，底色深蓝，中央工厂烟囱，边缘电路纹饰 |
| 第4章 | 未来制造 | Future Manufacturing | 16 | 圆形徽章，底色翠绿，中央3D打印机，边缘循环纹饰 |

## 图片内容规划

### 第1章：工业革命 Industrial Revolution（16张）

| 序号 | 章节 | 标题 | 描述 | 英文标题 | 英文描述 | 文件名 | 难度 |
| ---- | ---- | ---- | ---- | -------- | -------- | ------ | ---- |
| 1 | 第1章 | 流水线大批量 | 福特流水线让每辆汽车生产时间从十二小时缩短到一个半小时，标准化大规模生产。流水线是工业革命的里程碑，分工协作效率倍增。 | Assembly Line Mass Production | Ford's assembly line reduced car production time from twelve hours to one and a half hours, enabling standardized mass production. The assembly line is a milestone of the Industrial Revolution; division of labor multiplied efficiency. | industrial_production_000.jpg | 10×10 |
| 2 | 第1章 | 精益生产消除浪费 | 丰田精益生产消除一切不增值的活动，准时化生产只在需要时生产需要的数量。精益思想从工厂延伸到办公，消除浪费是永恒的追求。 | Lean Production: Eliminating Waste | Toyota's lean production eliminates all non-value-adding activities; just-in-time production produces only what's needed when it's needed. Lean thinking extends from factories to offices; eliminating waste is an eternal pursuit. | industrial_production_001.jpg | 10×10 |
| 3 | 第1章 | 六西格玛质量 | 六西格玛将缺陷率控制在百万分之三点四，DMAIC方法论系统改进质量。六西格玛用数据说话，统计工具让质量管理从经验走向科学。 | Six Sigma Quality | Six Sigma controls defect rates to 3.4 per million; the DMAIC methodology systematically improves quality. Six Sigma speaks with data; statistical tools transform quality management from experience to science. | industrial_production_002.jpg | 10×10 |
| 4 | 第1章 | 全面质量管理 | TQM强调全员参与全过程控制，从原材料到成品每个环节都追求零缺陷。质量是制造出来的不是检验出来的，预防胜于检查。 | Total Quality Management | TQM emphasizes full participation and process control; every step from raw materials to finished products pursues zero defects. Quality is built in, not inspected in; prevention beats detection. | industrial_production_003.jpg | 10×10 |
| 5 | 第1章 | 工业机器人焊接 | 焊接机器人沿预设轨迹精确焊接汽车车身，焊缝均匀美观速度是人工三倍。工业机器人是现代工厂的标准配置，重复精度零点一毫米。 | Industrial Robot Welding | Welding robots follow preset trajectories to precisely weld car bodies; seams are uniform and beautiful at three times manual speed. Industrial robots are standard equipment in modern factories, with repeat precision of 0.1 millimeters. | industrial_production_004.jpg | 10×10 |
| 6 | 第1章 | AGV自动导引车 | AGV小车沿磁条或激光导航在车间自动搬运物料，无需司机灵活调度。自动导引车是智能工厂的搬运工，二十四小时不间断运行。 | AGV Automated Guided Vehicle | AGV carts follow magnetic strips or laser navigation to automatically transport materials in workshops, requiring no drivers and enabling flexible scheduling. Automated guided vehicles are the porters of smart factories, running twenty-four hours non-stop. | industrial_production_005.jpg | 10×10 |
| 7 | 第1章 | MES制造执行 | MES系统实时监控生产进度和质量数据，从订单下达到成品入库全程追溯。制造执行系统是车间的数字大脑，信息透明让管理有的放矢。 | MES Manufacturing Execution | MES systems monitor production progress and quality data in real time, providing full traceability from order release to finished goods warehousing. Manufacturing execution systems are the workshop's digital brain; information transparency enables targeted management. | industrial_production_006.jpg | 10×10 |
| 8 | 第1章 | ERP企业资源 | ERP系统整合采购生产销售和财务数据，企业资源统一计划调度。ERP是企业的神经系统，信息孤岛变信息高速公路。 | ERP Enterprise Resources | ERP systems integrate procurement, production, sales, and financial data, unifying enterprise resource planning and scheduling. ERP is the enterprise's nervous system; information silos become information highways. | industrial_production_007.jpg | 10×10 |
| 9 | 第1章 | PLM产品全周期 | PLM管理产品从设计到报废的全生命周期数据，版本控制和变更管理确保一致。产品生命周期管理是创新的守护者，知识积累避免重复犯错。 | PLM Product Lifecycle | PLM manages product data throughout the entire lifecycle from design to retirement; version control and change management ensure consistency. Product lifecycle management is the guardian of innovation; knowledge accumulation avoids repeating mistakes. | industrial_production_008.jpg | 10×10 |
| 10 | 第1章 | SCADA数据采集 | SCADA系统采集传感器数据监控生产过程，操作员在控制室远程监控设备。数据采集与监控是工业自动化的眼睛，实时数据驱动决策。 | SCADA Data Acquisition | SCADA systems collect sensor data to monitor production processes; operators remotely monitor equipment from control rooms. Data acquisition and monitoring are the eyes of industrial automation; real-time data drives decisions. | industrial_production_009.jpg | 10×10 |
| 11 | 第1章 | DCS分散控制 | DCS将控制功能分散到现场控制器，操作站在中央集中监控管理。分散控制系统是流程工业的大脑，化工和电厂都依赖DCS安全运行。 | DCS Distributed Control | DCS distributes control functions to field controllers; operator stations provide centralized monitoring and management. Distributed control systems are the brain of process industries; chemical plants and power stations both depend on DCS for safe operation. | industrial_production_010.jpg | 10×10 |
| 12 | 第1章 | 注塑成型塑料 | 注塑机将熔融塑料注入模具冷却脱模，一个循环几秒到几十秒。注塑是塑料制品最常用的加工方法，从手机壳到汽车仪表盘。 | Injection Molding Plastics | Injection molding machines inject molten plastic into molds, cooling and demolding in cycles of seconds to tens of seconds. Injection molding is the most common processing method for plastic products, from phone cases to car dashboards. | industrial_production_011.jpg | 10×10 |
| 13 | 第1章 | 冲压板材成型 | 冲压机用模具将金属板材压制成零件，汽车车身覆盖件都是冲压成型。冲压是汽车制造的第一道工序，大型覆盖件需要千吨级冲压机。 | Stamping Sheet Metal Forming | Stamping presses use dies to press metal sheets into parts; car body panels are all stamp-formed. Stamping is the first process in automobile manufacturing; large panels require thousand-ton presses. | industrial_production_012.jpg | 10×10 |
| 14 | 第1章 | 压铸金属成型 | 压铸机将熔融铝合金高压注入金属模具，冷却后获得精密铸件。压铸件表面光洁尺寸精确，手机中框和汽车发动机壳体都是压铸件。 | Die Casting Metal Forming | Die casting machines inject molten aluminum alloy under high pressure into metal molds, obtaining precision castings after cooling. Die castings have smooth surfaces and precise dimensions; phone frames and car engine housings are die castings. | industrial_production_013.jpg | 10×10 |
| 15 | 第1章 | 涂装喷漆工艺 | 汽车涂装线经过电泳底漆中涂和面漆，机器人喷涂均匀无死角。涂装是汽车制造中最复杂的工艺，防腐和美观双重目标。 | Coating and Painting Process | Automotive coating lines go through electrophoretic primer, mid-coat, and topcoat; robot spraying is uniform with no dead angles. Coating is the most complex process in car manufacturing, serving both anti-corrosion and aesthetic purposes. | industrial_production_014.jpg | 10×10 |
| 16 | 第1章 | 总装流水线 | 汽车总装线上工人和机器人协同安装发动机座椅和仪表盘，每分钟一辆车下线。总装是汽车制造的最后一站，模块化装配提高效率。 | Final Assembly Line | On the car final assembly line, workers and robots collaboratively install engines, seats, and dashboards; one car rolls off every minute. Final assembly is the last stop of car manufacturing; modular assembly improves efficiency. | industrial_production_015.jpg | 10×10 |

### 第2章：制造技术 Manufacturing Technology（16张）

| 序号 | 章节 | 标题 | 描述 | 英文标题 | 英文描述 | 文件名 | 难度 |
| ---- | ---- | ---- | ---- | -------- | -------- | ------ | ---- |
| 17 | 第2章 | 质量检测在线 | 在线检测站用视觉系统和传感器检查每个零件尺寸和外观，不良品自动剔除。在线检测是质量的大门，百分之百全检取代抽样检验。 | Online Quality Inspection | Online inspection stations use vision systems and sensors to check every part's dimensions and appearance; defective products are automatically rejected. Online inspection is the gatekeeper of quality; one hundred percent full inspection replaces sampling. | industrial_production_016.jpg | 10×10 |
| 18 | 第2章 | SPC统计过程 | 控制图监控生产过程关键参数，数据点超出控制限立即报警调整。统计过程控制用数据预防质量问题，过程稳定才能产出合格品。 | SPC Statistical Process Control | Control charts monitor key production process parameters; data points exceeding control limits trigger immediate alarms and adjustments. Statistical process control uses data to prevent quality problems; only stable processes produce qualified products. | industrial_production_017.jpg | 10×10 |
| 19 | 第2章 | 防错Poka-yoke | 防错设计让操作者无法犯错，零件方向不对无法放入夹具。防错是精益生产的智慧，与其惩罚错误不如消除犯错的可能。 | Poka-yoke Error Proofing | Error-proofing designs make it impossible for operators to make mistakes; parts that face the wrong direction cannot be inserted into fixtures. Poka-yoke is the wisdom of lean production; better to eliminate the possibility of errors than to punish them. | industrial_production_018.jpg | 10×10 |
| 20 | 第2章 | 看板拉动生产 | 看板卡片传递生产指令，后工序需要时前工序才生产，拉动式生产减少库存。看板是精益生产的信号灯，可视化管理让问题无处藏身。 | Kanban Pull Production | Kanban cards convey production instructions; front processes produce only when back processes need them, and pull production reduces inventory. Kanban is the traffic light of lean production; visual management leaves problems nowhere to hide. | industrial_production_019.jpg | 15×15 |
| 21 | 第2章 | 5S现场管理 | 整理整顿清扫清洁素养五步法改善工作环境，工具定置摆放一目了然。5S是精益的起点，整洁有序的现场是高效生产的基础。 | 5S Workplace Management | The five steps of Sort, Set in Order, Shine, Standardize, and Sustain improve the work environment; tools are placed in fixed positions for easy identification. 5S is the starting point of lean; a clean and organized workplace is the foundation of efficient production. | industrial_production_020.jpg | 15×15 |
| 22 | 第2章 | TPM全员维护 | TPM让操作工参与设备日常维护，自主保养和专业维修结合减少故障。全员生产维护追求零故障零不良，设备健康是生产力的保障。 | TPM Total Productive Maintenance | TPM involves operators in daily equipment maintenance; combining autonomous maintenance with professional repair reduces failures. Total productive maintenance pursues zero breakdowns and zero defects; equipment health guarantees productivity. | industrial_production_021.jpg | 15×15 |
| 23 | 第2章 | 供应链管理 | 供应链从原材料供应商到最终客户，协同计划采购制造和配送。供应链管理是跨企业的优化，信息共享让牛鞭效应最小化。 | Supply Chain Management | The supply chain spans from raw material suppliers to end customers, coordinating planning, procurement, manufacturing, and distribution. Supply chain management is cross-enterprise optimization; information sharing minimizes the bullwhip effect. | industrial_production_022.jpg | 15×15 |
| 24 | 第2章 | 仓储物流管理 | 立体仓库用堆垛机自动存取货物，WMS系统管理库位和库存。智能仓储让物流效率倍增，先进先出和库存周转是核心指标。 | Warehousing and Logistics Management | Automated warehouses use stacker cranes for automatic storage and retrieval; WMS systems manage locations and inventory. Smart warehousing multiplies logistics efficiency; FIFO and inventory turnover are core metrics. | industrial_production_023.jpg | 15×15 |
| 25 | 第2章 | 工业以太网 | 工业以太网用确定性协议保证通信实时性，Profinet和EtherCAT是主流。工业网络是智能工厂的神经网络，毫秒级通信保证同步控制。 | Industrial Ethernet | Industrial Ethernet uses deterministic protocols to guarantee real-time communication; Profinet and EtherCAT are mainstream. Industrial networks are the neural network of smart factories; millisecond-level communication ensures synchronized control. | industrial_production_024.jpg | 15×15 |
| 26 | 第2章 | 数字工厂模型 | 数字工厂在虚拟空间模拟生产流程，优化布局和节拍后再实施。数字工厂是工业四点零的蓝图，先仿真后实施降低试错成本。 | Digital Factory Model | Digital factories simulate production processes in virtual space, optimizing layout and cycle times before implementation. Digital factories are the blueprint of Industry 4.0; simulate first, implement later, reducing trial-and-error costs. | industrial_production_025.jpg | 15×15 |
| 27 | 第2章 | 预测性维护 | 振动和温度传感器监测设备状态，AI算法预测故障提前安排维修。预测性维护从定期保养变为按需维修，减少停机节省成本。 | Predictive Maintenance | Vibration and temperature sensors monitor equipment status; AI algorithms predict failures and schedule maintenance in advance. Predictive maintenance shifts from periodic servicing to on-demand repair, reducing downtime and saving costs. | industrial_production_026.jpg | 15×15 |
| 28 | 第2章 | 工业互联网平台 | 工业互联网平台连接设备采集数据，工业APP提供分析和优化服务。工业互联网是制造业的操作系统，数据驱动智能决策。 | Industrial Internet Platform | Industrial internet platforms connect equipment and collect data; industrial apps provide analysis and optimization services. The industrial internet is the operating system of manufacturing; data drives intelligent decisions. | industrial_production_027.jpg | 15×15 |
| 29 | 第2章 | 增材制造量产 | 金属3D打印直接制造航空发动机零件，传统工艺无法实现的复杂结构一次成型。增材制造从原型走向量产，个性化定制不再昂贵。 | Additive Manufacturing Mass Production | Metal 3D printing directly manufactures aerospace engine parts; complex structures impossible with traditional processes are formed in one step. Additive manufacturing moves from prototyping to mass production; personalized customization is no longer expensive. | industrial_production_028.jpg | 15×15 |
| 30 | 第2章 | 柔性生产线 | 柔性生产线快速切换产品型号，混合生产不同品种满足小批量需求。柔性制造是消费升级的响应，大规模定制成为可能。 | Flexible Production Line | Flexible production lines quickly switch between product models, mixing different varieties to meet small-batch demands. Flexible manufacturing responds to consumption upgrades; mass customization becomes possible. | industrial_production_029.jpg | 15×15 |
| 31 | 第2章 | 绿色制造减排 | 绿色工厂用光伏发电和中水回用减少碳排放，清洁生产从源头减少污染。绿色制造是可持续发展的必由之路，环保和效益可以双赢。 | Green Manufacturing Emission Reduction | Green factories use solar power and water recycling to reduce carbon emissions; cleaner production reduces pollution at the source. Green manufacturing is the necessary path for sustainable development; environmental protection and profitability can be a win-win. | industrial_production_030.jpg | 15×15 |
| 32 | 第2章 | 安全生产管理 | 安全巡检和隐患排查是日常，危险作业审批和应急演练定期开展。安全生产是红线，零事故零伤害是永恒目标。 | Safety Production Management | Safety inspections and hazard identification are daily routines; hazardous work approvals and emergency drills are conducted regularly. Safety production is the red line; zero accidents and zero injuries are eternal goals. | industrial_production_031.jpg | 15×15 |

### 第3章：现代工业 Modern Industry（17张）

| 序号 | 章节 | 标题 | 描述 | 英文标题 | 英文描述 | 文件名 | 难度 |
| ---- | ---- | ---- | ---- | -------- | -------- | ------ | ---- |
| 33 | 第3章 | 工艺流程优化 | 工艺工程师分析生产瓶颈，调整工序和参数缩短节拍提升产能。工艺优化是持续改进的核心，小改动大收益。 | Process Flow Optimization | Process engineers analyze production bottlenecks, adjusting procedures and parameters to shorten cycle times and boost capacity. Process optimization is the core of continuous improvement; small changes, big gains. | industrial_production_032.jpg | 15×15 |
| 34 | 第3章 | 工装夹具设计 | 专用夹具快速定位夹紧工件，保证加工精度和操作安全。工装是生产的辅助工具，好的夹具让操作简单高效。 | Tooling and Fixture Design | Specialized fixtures quickly locate and clamp workpieces, ensuring machining precision and operational safety. Tooling is the auxiliary tool of production; good fixtures make operations simple and efficient. | industrial_production_033.jpg | 15×15 |
| 35 | 第3章 | 表面处理工艺 | 电镀和阳极氧化在零件表面形成功能层，耐磨防腐美观。表面处理是产品的面子工程，也是功能性的关键工序。 | Surface Treatment Process | Electroplating and anodizing form functional layers on part surfaces, providing wear resistance, corrosion protection, and aesthetics. Surface treatment is both the face of the product and a key functional process. | industrial_production_034.jpg | 20×20 |
| 36 | 第3章 | 精密铸造失蜡 | 失蜡铸造用蜡模制造精密铸件，涡轮叶片和珠宝都采用此法。熔模铸造精度高表面光洁，复杂内腔一次铸成。 | Precision Investment Casting | Investment casting uses wax patterns to produce precision castings; turbine blades and jewelry both use this method. Lost-wax casting offers high precision and smooth surfaces; complex internal cavities are cast in one piece. | industrial_production_035.jpg | 20×20 |
| 37 | 第3章 | 粉末冶金压制 | 金属粉末在模具中高压成型后烧结，齿轮和磁体大批量低成本生产。粉末冶金材料利用率高近净成型，适合大批量小型零件。 | Powder Metallurgy Pressing | Metal powder is pressed at high pressure in molds and then sintered; gears and magnets are produced in large volumes at low cost. Powder metallurgy offers high material utilization and near-net shaping, suitable for high-volume small parts. | industrial_production_036.jpg | 20×20 |
| 38 | 第3章 | 半导体封装测试 | 晶圆切割后芯片用引线键合连接到封装基板，塑封保护后测试分选。封装是芯片穿上外衣，测试是品质的最后一道关。 | Semiconductor Packaging and Testing | After wafer dicing, chips are wire-bonded to packaging substrates, molded for protection, then tested and sorted. Packaging gives chips their outer garments; testing is the final gate of quality. | industrial_production_037.jpg | 20×20 |
| 39 | 第3章 | PCB制造工艺 | 覆铜板经曝光蚀刻形成铜箔线路，钻孔电镀实现层间互连。PCB是电子产品的载体，从双面板到几十层高频板工艺不断升级。 | PCB Manufacturing Process | Copper-clad boards are exposed and etched to form copper traces; drilling and plating achieve interlayer connections. PCBs are the carriers of electronic products; processes keep upgrading from double-sided to dozens of high-frequency layers. | industrial_production_038.jpg | 20×20 |
| 40 | 第3章 | SMT贴片组装 | 高速贴片机将元器件贴装到PCB焊盘上，回流焊将锡膏熔化焊接。表面贴装技术让电子产品越来越小，贴装精度已达微米级。 | SMT Surface Mount Assembly | High-speed pick-and-place machines mount components onto PCB pads; reflow soldering melts solder paste to form joints. Surface mount technology makes electronic products increasingly compact; placement precision has reached the micrometer level. | industrial_production_039.jpg | 20×20 |
| 41 | 第3章 | 光学检测AOI | AOI设备用高清相机检查PCB焊点和元件缺陷，替代人工目检。自动光学检测是电子制造的质量卫士，微米级缺陷无处遁形。 | AOI Automated Optical Inspection | AOI equipment uses high-resolution cameras to inspect PCB solder joints and component defects, replacing manual visual inspection. Automated optical inspection is the quality guardian of electronics manufacturing; micrometer-level defects have nowhere to hide. | industrial_production_040.jpg | 20×20 |
| 42 | 第3章 | X射线检测BGA | X射线穿透PCB检查BGA芯片底部焊点，目视无法看到的缺陷一览无余。X射线检测是隐藏焊点的透视镜，虚焊和桥接无所遁形。 | X-Ray Inspection for BGA | X-rays penetrate PCBs to inspect BGA chip bottom solder joints; defects invisible to the eye are fully revealed. X-ray inspection is the fluoroscope for hidden solder joints; cold solder and bridging have nowhere to hide. | industrial_production_041.jpg | 20×20 |
| 43 | 第3章 | 食品加工安全 | 食品工厂在洁净车间生产，HACCP体系从原料到成品控制危害点。食品安全是底线，从农场到餐桌全程可追溯。 | Food Processing Safety | Food factories produce in clean rooms; the HACCP system controls hazard points from raw materials to finished products. Food safety is the baseline; full traceability from farm to table. | industrial_production_042.jpg | 20×20 |
| 44 | 第3章 | 制药GMP规范 | GMP药厂在A级洁净区灌装药品，每批产品放行前检验合格。药品生产质量管理规范是制药的宪法，质量源于设计而非检验。 | Pharmaceutical GMP Standards | GMP pharmaceutical plants fill drugs in Grade A clean areas; each batch is tested and approved before release. Good Manufacturing Practice is the constitution of pharmaceuticals; quality comes from design, not inspection. | industrial_production_043.jpg | 20×20 |
| 45 | 第3章 | 纺织印染工艺 | 织布机将经纬纱交织成布，染色和印花赋予色彩和图案。纺织工业从手工到自动化，数码印花让小批量定制成为可能。 | Textile Dyeing and Printing | Looms interweave warp and weft yarns into fabric; dyeing and printing add color and patterns. The textile industry has gone from manual to automated; digital printing makes small-batch customization possible. | industrial_production_044.jpg | 20×20 |
| 46 | 第3章 | 钢铁冶炼高炉 | 高炉中铁矿石还原为铁水，转炉吹氧脱碳炼钢，连铸成坯轧制成材。钢铁是工业的粮食，从矿石到钢材的炼金之旅。 | Blast Furnace Iron and Steelmaking | In blast furnaces, iron ore is reduced to molten iron; converters blow oxygen to decarburize steel; continuous casting forms billets that are rolled into products. Steel is the grain of industry; the alchemical journey from ore to steel. | industrial_production_045.jpg | 20×20 |
| 47 | 第3章 | 玻璃浮法成型 | 浮法玻璃让熔融锡液上的玻璃液自然摊平，表面平整如镜。浮法工艺是玻璃制造的革命，建筑和汽车玻璃都由此生产。 | Float Glass Forming | Float glass lets molten glass naturally level on molten tin, producing surfaces smooth as mirrors. The float process revolutionized glass manufacturing; architectural and automotive glass are both produced this way. | industrial_production_046.jpg | 20×20 |
| 48 | 第3章 | 水泥旋窑烧成 | 水泥旋窑中石灰石在高温下煅烧成熟料，添加石膏磨细即为水泥。水泥是建筑的粮食，全球年产量超过四十亿吨。 | Cement Rotary Kiln Firing | In cement rotary kilns, limestone is calcined at high temperatures into clinker; adding gypsum and grinding produces cement. Cement is the grain of construction; global annual production exceeds four billion tons. | industrial_production_047.jpg | 20×20 |
| 49 | 第3章 | 造纸工艺流程 | 木材制浆后纸浆在造纸机上脱水压榨烘干，卷成大卷再分切成纸。造纸术是中国四大发明之一，现代造纸机速度可达每分钟两千米。 | Papermaking Process | After wood pulping, paper pulp is dewatered, pressed, and dried on paper machines, then rolled into large rolls and slit into sheets. Papermaking is one of China's four great inventions; modern paper machines can reach speeds of two thousand meters per minute. | industrial_production_048.jpg | 20×20 |

### 第4章：未来制造 Future Manufacturing（16张）

| 序号 | 章节 | 标题 | 描述 | 英文标题 | 英文描述 | 文件名 | 难度 |
| ---- | ---- | ---- | ---- | -------- | -------- | ------ | ---- |
| 50 | 第4章 | 轮胎制造硫化 | 生胎在硫化机中高温高压交联成型，橡胶从塑性变为弹性。轮胎是汽车的鞋子，硫化工艺赋予橡胶弹性和强度。 | Tire Vulcanization Manufacturing | Green tires are cross-linked at high temperature and pressure in vulcanizing presses; rubber transforms from plastic to elastic. Tires are a car's shoes; vulcanization gives rubber its elasticity and strength. | industrial_production_049.jpg | 20×20 |
| 51 | 第4章 | 电池制造涂布 | 锂电池极片涂布机将浆料均匀涂在铝箔上，辊压分切后卷绕成电芯。电池制造是精密化工过程，涂布均匀性决定电池性能一致性。 | Battery Coating Manufacturing | Lithium battery electrode coating machines uniformly apply slurry onto aluminum foil; after roller pressing and slitting, electrodes are wound into cells. Battery manufacturing is a precision chemical process; coating uniformity determines battery performance consistency. | industrial_production_050.jpg | 20×20 |
| 52 | 第4章 | 光伏组件层压 | 光伏组件将电池片用EVA胶膜层压封装在玻璃和背板之间，保证二十五年寿命。组件封装是光伏制造的最后一环，耐候性是关键。 | Photovoltaic Module Lamination | PV modules laminate cells between glass and backsheet using EVA film, guaranteeing a twenty-five-year lifespan. Module encapsulation is the final step of PV manufacturing; weather resistance is key. | industrial_production_051.jpg | 20×20 |
| 53 | 第4章 | 工业四点零 | 工业四点零用物联网和AI实现智能制造，设备自主决策人机协同。第四次工业革命正在发生，数据是新时代的石油。 | Industry 4.0 | Industry 4.0 uses IoT and AI to achieve smart manufacturing; equipment makes autonomous decisions with human-machine collaboration. The Fourth Industrial Revolution is happening; data is the oil of the new era. | industrial_production_052.jpg | 25×25 |
| 54 | 第4章 | 灯塔工厂标杆 | 世界经济论坛认证的灯塔工厂代表全球制造业最先进水平，数字化智能化全面领先。灯塔工厂照亮制造业的未来方向。 | Lighthouse Factory Benchmark | Lighthouse factories certified by the World Economic Forum represent the most advanced level of global manufacturing, with comprehensive digital and intelligent leadership. Lighthouse factories illuminate the future direction of manufacturing. | industrial_production_053.jpg | 25×25 |
| 55 | 第4章 | 碳足迹核算 | 产品碳足迹从原材料到报废全生命周期碳排放核算，碳标签让消费者知情。碳足迹是绿色制造的度量衡，减碳从量化开始。 | Carbon Footprint Accounting | Product carbon footprints account for lifecycle carbon emissions from raw materials to disposal; carbon labels inform consumers. Carbon footprint is the measure of green manufacturing; decarbonization starts with quantification. | industrial_production_054.jpg | 25×25 |
| 56 | 第4章 | 循环经济回收 | 废旧电子产品回收提炼贵金属，塑料瓶再生为纤维，循环经济变废为宝。循环经济是线性经济的替代方案，废弃物是放错位置的资源。 | Circular Economy Recycling | E-waste is recycled to extract precious metals; plastic bottles are regenerated into fibers; the circular economy turns waste into treasure. The circular economy is the alternative to the linear economy; waste is just resources in the wrong place. | industrial_production_055.jpg | 25×25 |
| 57 | 第4章 | 人机协作安全 | 协作机器人与工人并肩工作，力控传感器碰到人立即停止。人机协作是未来工厂的形态，机器做重复工人做创造。 | Human-Robot Collaboration Safety | Collaborative robots work alongside workers; force-control sensors stop immediately upon human contact. Human-robot collaboration is the form of future factories; machines do the repetitive work, humans do the creative. | industrial_production_056.jpg | 25×25 |
| 58 | 第4章 | 产线平衡优化 | 产线平衡让每个工站节拍时间相近，消除瓶颈工站提升整体效率。产线平衡是效率的放大器，最慢的工站决定整条线的速度。 | Production Line Balancing Optimization | Line balancing makes each station's cycle time similar, eliminating bottleneck stations to improve overall efficiency. Line balancing is an efficiency amplifier; the slowest station determines the speed of the entire line. | industrial_production_057.jpg | 25×25 |
| 59 | 第4章 | 装配线平衡 | 装配线平衡分析让每个工位作业时间相近，消除瓶颈提高整线效率。装配线平衡是工业工程的基本功，节拍一致才能流畅生产。 | Assembly Line Balancing | Assembly line balancing analysis makes each workstation's task time similar, eliminating bottlenecks to improve line efficiency. Assembly line balancing is a fundamental skill of industrial engineering; consistent cycle times enable smooth production. | industrial_production_058.jpg | 25×25 |
| 60 | 第4章 | 防静电控制 | 电子车间铺设防静电地板，工人穿戴防静电手环和工服，湿度控制减少静电。静电是电子元件的隐形杀手，几十伏静电就能击穿芯片。 | ESD Control | Electronics workshops install anti-static floors; workers wear anti-static wristbands and garments; humidity control reduces static. Static electricity is the invisible killer of electronic components; just tens of volts can break down a chip. | industrial_production_059.jpg | 25×25 |
| 61 | 第4章 | 洁净室等级 | 百级洁净室每立方米大于零点五微米粒子不超过三千五百个，芯片和药品在此生产。洁净室是精密制造的庇护所，空气过滤和气流组织是核心。 | Cleanroom Classification | Class 100 cleanrooms have no more than 3,500 particles larger than 0.5 micrometers per cubic meter; chips and drugs are produced here. Cleanrooms are the sanctuaries of precision manufacturing; air filtration and airflow organization are the core. | industrial_production_060.jpg | 25×25 |
| 62 | 第4章 | 工业设计美学 | 工业设计师用曲面建模软件设计产品外观，人机工程和美学兼顾。好的工业设计让产品好用又好看，从苹果手机到戴森吹风机。 | Industrial Design Aesthetics | Industrial designers use surface modeling software to design product appearances, balancing ergonomics and aesthetics. Good industrial design makes products both functional and beautiful, from Apple phones to Dyson hair dryers. | industrial_production_061.jpg | 25×25 |
| 63 | 第4章 | 模具设计制造 | 注塑模具用线切割和电火花加工型腔，冷却水路和顶出系统精密设计。模具是工业之母，一副模具百万次注塑仍需保持精度。 | Mold Design and Manufacturing | Injection molds use wire cutting and EDM to machine cavities; cooling channels and ejection systems are precisely designed. Molds are the mother of industry; a single mold must maintain precision through millions of injection cycles. | industrial_production_062.jpg | 25×25 |
| 64 | 第4章 | 工艺卡片指导 | 工艺卡片详细规定每道工序的设备参数和操作步骤，工人按卡作业标准化。工艺文件是生产的法规，标准化操作保证质量一致。 | Process Card Instructions | Process cards detail the equipment parameters and operation steps for each process; workers follow the cards for standardized operations. Process documents are the regulations of production; standardized operations ensure quality consistency. | industrial_production_063.jpg | 25×25 |
| 65 | 第4章 | 产能规划排程 | APS高级排程系统根据订单和产能约束优化生产计划，最大化设备利用率。产能规划是生产的指挥棒，交期和效率的平衡艺术。 | Capacity Planning and Scheduling | APS advanced scheduling systems optimize production plans based on orders and capacity constraints, maximizing equipment utilization. Capacity planning is the baton of production; the art of balancing delivery dates and efficiency. | industrial_production_064.jpg | 25×25 |

**图片规格：**
- 分辨率：2496×1664（3:2宽高比）
- 分块方式：3×2 = 6块/图
- 常规谜题数：312个（前52张图每张6个分块谜题）
- **25×25专家谜题数**：78个（第53-65号图片各6个分块谜题）
- 谜题总数：403个

**像素图：**
- 命名规范：原图文件名 + `_pixel.jpg`
- 示例：`industrial_production_000_pixel.jpg`

**关卡文件：**
- 目录：`data/puzzles/industrial_production/`
- 常规关卡命名：`{图片ID}_{分块索引}.json`
  - 示例：`industrial_production_000_0.json` ~ `industrial_production_000_5.json`
- 专家关卡命名：`{图片ID}_expert.json`
  - 示例：`industrial_production_052_expert.json`
  - 仅第53-65号图片包含专家关卡
