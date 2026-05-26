# 《机械电子》(Mechanical and Electronic) 画册内容规划

## 画册信息

| 属性 | 内容 |
| ---- | ---- |
| 序号 | 56 |
| 英文名 | Mechanical and Electronic |
| 书架 | 科技工业 |
| 书架英文名 | Science and Technology |
| 图片数 | 65 |
| 分块数/图 | 6 |
| 谜题数 | 390（常规312 + 专家78） |
| 难度配置 | 10×10~25×25 |
| 参考著作 | 钱学森《工程控制论》 |

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
| 第1章 | 机械工程 | Mechanical Engineering | 16 | 圆形徽章，底色钢灰，中央齿轮杠杆，边缘螺栓纹饰 |
| 第2章 | 电子技术 | Electronic Technology | 16 | 圆形徽章，底色墨绿，中央芯片电路，边缘电波纹饰 |
| 第3章 | 自动化控制 | Automation Control | 17 | 圆形徽章，底色深蓝，中央机械手臂，边缘传感器纹饰 |
| 第4章 | 精密制造 | Precision Manufacturing | 16 | 圆形徽章，底色铜金，中央游标卡尺，边缘刻度纹饰 |

## 图片内容规划

### 第1章：机械工程 Mechanical Engineering（16张）

| 序号 | 章节 | 章节 | 标题 | 描述 | 英文标题 | 英文描述 | 文件名 | 难度 |
| ---- | ---- | ---- | ---- | ---- | -------- | -------- | ------ | ---- |
| 1 | 第1章 | 第1章 | 齿轮传动啮合 | 大小齿轮相互啮合传递旋转运动，齿数比决定传动比，从钟表到减速器无处不在。齿轮是机械传动的基石，精确的齿形保证平稳啮合和高效传力。 | Gear Meshing Transmission | Large and small gears mesh to transmit rotational motion; the gear ratio determines the transmission ratio, ubiquitous from clocks to speed reducers. Gears are the cornerstone of mechanical transmission; precise tooth profiles ensure smooth meshing and efficient force transmission. | mechanical_electronic_000.jpg | 10×10 |
| 2 | 第1章 | 第1章 | 杠杆省力原理 | 阿基米德说给我一个支点就能撬动地球，杠杆原理让小力移动重物。杠杆是最简单的机械，支点力臂和重臂的关系决定了省力还是省距离。 | Lever Force-Saving Principle | Archimedes said give me a fulcrum and I can move the Earth; the lever principle allows small force to move heavy objects. The lever is the simplest machine; the relationship between fulcrum, effort arm, and load arm determines whether it saves force or distance. | mechanical_electronic_001.jpg | 10×10 |
| 3 | 第1章 | 第1章 | 滑轮组省力 | 定滑轮改变力的方向，动滑轮省力一半，滑轮组组合实现既省力又方便。滑轮是起重机的核心部件，建筑工地上塔吊利用滑轮组吊起数吨重物。 | Pulley Systems for Force Saving | Fixed pulleys change the direction of force; movable pulleys save half the effort; pulley combinations achieve both force saving and convenience. Pulleys are core components of cranes; tower cranes on construction sites use pulley systems to lift several tons. | mechanical_electronic_002.jpg | 10×10 |
| 4 | 第1章 | 第1章 | 斜面省力搬运 | 斜面将重物沿倾斜面推上比垂直提起省力，斜面越缓越省力但距离越长。斜面是楔子和螺旋的基础，盘山公路和螺丝钉都是斜面的巧妙应用。 | Inclined Plane for Easier Transport | Pushing heavy objects up an incline requires less force than lifting vertically; the gentler the slope, the less force needed but the longer the distance. The inclined plane is the basis of wedges and screws; mountain roads and screws are clever applications of inclined planes. | mechanical_electronic_003.jpg | 10×10 |
| 5 | 第1章 | 第1章 | 弹簧储能释能 | 弹簧压缩或拉伸时储存弹性势能，释放时恢复原状释放能量。弹簧是机械储能元件，从钟表发条到汽车减震器，弹性变形是能量的暂存方式。 | Spring Energy Storage and Release | Springs store elastic potential energy when compressed or stretched, releasing energy when returning to their original shape. Springs are mechanical energy storage elements; from clock mainsprings to car shock absorbers, elastic deformation is a temporary energy storage method. | mechanical_electronic_004.jpg | 10×10 |
| 6 | 第1章 | 第1章 | 轴承减少摩擦 | 滚动轴承用钢珠将滑动摩擦变为滚动摩擦，摩擦力降低到原来的十分之一。轴承是旋转机械的关节，从硬盘电机到风力发电机都离不开精密轴承。 | Bearings Reducing Friction | Rolling bearings use steel balls to convert sliding friction into rolling friction, reducing friction to one-tenth. Bearings are the joints of rotating machinery; from hard drive motors to wind turbines, precision bearings are indispensable. | mechanical_electronic_005.jpg | 10×10 |
| 7 | 第1章 | 第1章 | 凸轮机构转换 | 凸轮旋转将连续转动变为从动件的往复运动，发动机气门就是凸轮驱动。凸轮机构是运动转换的魔术师，旋转运动变为直线运动或摆动。 | Cam Mechanism Motion Conversion | Rotating cams convert continuous rotation into reciprocating motion of followers; engine valves are cam-driven. Cam mechanisms are magicians of motion conversion, transforming rotational motion into linear motion or oscillation. | mechanical_electronic_006.jpg | 10×10 |
| 8 | 第1章 | 第1章 | 连杆机构运动 | 曲柄连杆将活塞的往复直线运动转为曲轴的旋转运动，是内燃机的核心机构。连杆机构是机械运动的翻译器，蒸汽机和汽车发动机都依赖它工作。 | Linkage Mechanism Motion | Crank-connecting rod converts the piston's reciprocating linear motion into the crankshaft's rotational motion, the core mechanism of internal combustion engines. Linkage mechanisms are translators of mechanical motion; steam engines and automobile engines both depend on them. | mechanical_electronic_007.jpg | 10×10 |
| 9 | 第1章 | 第1章 | 液压传动压力 | 帕斯卡定律让小缸的力在大缸上放大，液压千斤顶用小力举起大重量。液压传动用不可压缩的油液传递力，挖掘机和注塑机都靠液压驱动。 | Hydraulic Transmission Pressure | Pascal's law amplifies force from a small cylinder to a large one; hydraulic jacks lift heavy weights with small force. Hydraulic transmission uses incompressible fluid to transmit force; excavators and injection molding machines are hydraulically driven. | mechanical_electronic_008.jpg | 10×10 |
| 10 | 第1章 | 第1章 | 气动压缩空气 | 空气压缩机将空气压缩储存能量，气动工具轻便安全不怕过载。气动技术用压缩空气驱动气缸和气马达，风镐和喷漆枪都是气动工具。 | Pneumatic Compressed Air | Air compressors compress and store energy in air; pneumatic tools are lightweight, safe, and overload-resistant. Pneumatic technology uses compressed air to drive cylinders and air motors; jackhammers and spray guns are pneumatic tools. | mechanical_electronic_009.jpg | 10×10 |
| 11 | 第1章 | 第1章 | 焊接金属连接 | 电弧焊用高温电弧熔化金属焊条和母材，冷却后两块金属融为一体。焊接是金属连接的永久方式，从造船到建筑钢结构无处不在。 | Welding Metal Joining | Arc welding uses high-temperature arcs to melt welding rods and base metal; after cooling, the two metal pieces become one. Welding is a permanent method of metal joining, ubiquitous from shipbuilding to structural steel construction. | mechanical_electronic_010.jpg | 10×10 |
| 12 | 第1章 | 第1章 | 铸造液态成型 | 将熔融金属浇入砂型或金属型中冷却凝固，铸造成型可制造复杂形状零件。铸造是最古老的金属加工方法，青铜器时代就有了铸造技术。 | Casting Liquid Molding | Molten metal is poured into sand or metal molds to cool and solidify; casting can produce complex-shaped parts. Casting is the oldest metalworking method; casting technology existed since the Bronze Age. | mechanical_electronic_011.jpg | 10×10 |
| 13 | 第1章 | 第1章 | 锻造塑性变形 | 铁匠用锤子反复锻打烧红的铁块，金属在塑性变形中变得致密强韧。锻造改善金属内部组织，汽轮机叶片和飞机起落架都需锻造保证强度。 | Forging Plastic Deformation | Blacksmiths repeatedly hammer red-hot iron; metal becomes denser and tougher through plastic deformation. Forging improves internal metal structure; turbine blades and aircraft landing gear require forging for strength assurance. | mechanical_electronic_012.jpg | 10×10 |
| 14 | 第1章 | 第1章 | 机加工切削 | 车床刀具切削旋转工件外圆，铣刀切削平面和沟槽，精度可达微米级。机加工是精密制造的基石，数控机床让切削加工自动化和智能化。 | Machining Cutting | Lathe tools cut rotating workpiece outer diameters; milling cutters machine flat surfaces and grooves with micron-level precision. Machining is the cornerstone of precision manufacturing; CNC machines make cutting automated and intelligent. | mechanical_electronic_013.jpg | 10×10 |
| 15 | 第1章 | 第1章 | 数控机床自动 | 数控机床按程序自动完成复杂加工，五轴联动加工出叶轮等空间曲面。数控技术是制造业的革命，从手工操作到程序控制精度和效率飞跃提升。 | CNC Machine Automation | CNC machines automatically complete complex machining according to programs; five-axis simultaneous machining produces spatial surfaces like impellers. CNC technology is a manufacturing revolution; from manual operation to program control, precision and efficiency leap forward. | mechanical_electronic_014.jpg | 10×10 |
| 16 | 第1章 | 第1章 | 3D打印增材 | 3D打印机逐层堆积材料制造零件，无需刀具和模具，复杂结构一次成型。增材制造颠覆了传统减材加工，从原型制作到航空零件应用越来越广。 | 3D Printing Additive Manufacturing | 3D printers build parts layer by layer, requiring no cutting tools or molds; complex structures are formed in one go. Additive manufacturing subverts traditional subtractive processing; applications are expanding from prototyping to aerospace parts. | mechanical_electronic_015.jpg | 10×10 |

### 第2章：电子技术 Electronic Technology（16张）

| 序号 | 章节 | 章节 | 标题 | 描述 | 英文标题 | 英文描述 | 文件名 | 难度 |
| ---- | ---- | ---- | ---- | ---- | -------- | -------- | ------ | ---- |
| 17 | 第2章 | 第2章 | 电路板布线 | PCB上铜箔线路连接电子元器件，多层板在内部层间走线，表面贴装元件密布。印刷电路板是电子设备的基础，绿色板上的铜线是电流的高速公路。 | PCB Circuit Board Routing | Copper foil traces on PCBs connect electronic components; multi-layer boards route signals between internal layers with densely packed surface-mount components. Printed circuit boards are the foundation of electronic devices; copper traces on green boards are highways for current. | mechanical_electronic_016.jpg | 10×10 |
| 18 | 第2章 | 第2章 | 芯片光刻制造 | 光刻机用紫外光将电路图案投影到硅片光刻胶上，纳米级线宽在方寸间刻出百亿晶体管。芯片制造是人类最精密的工艺，极紫外光刻是皇冠上的明珠。 | Chip Lithography Manufacturing | Lithography machines project circuit patterns onto silicon wafer photoresist using UV light; nanometer-scale line widths etch tens of billions of transistors in a tiny area. Chip manufacturing is humanity's most precise process; extreme ultraviolet lithography is the crown jewel. | mechanical_electronic_017.jpg | 10×10 |
| 19 | 第2章 | 第2章 | 晶体管开关 | MOSFET晶体管用栅极电压控制源漏间电流通断，是数字电路的基本开关。晶体管发明是信息时代的起点，从电子管到晶体管体积缩小功耗降低。 | Transistor Switch | MOSFET transistors use gate voltage to control current flow between source and drain, serving as the basic switch in digital circuits. The invention of the transistor marked the beginning of the information age; from vacuum tubes to transistors, size shrank and power consumption decreased. | mechanical_electronic_018.jpg | 10×10 |
| 20 | 第2章 | 第2章 | 运算放大器 | 运算放大器将微弱信号放大数千倍，负反馈让放大倍数精确稳定。运放是模拟电路的万能积木，从音频放大到传感器信号调理都离不开它。 | Operational Amplifier | Operational amplifiers amplify weak signals thousands of times; negative feedback makes the gain precise and stable. Op-amps are the universal building blocks of analog circuits; indispensable from audio amplification to sensor signal conditioning. | mechanical_electronic_019.jpg | 15×15 |
| 21 | 第2章 | 第2章 | 模数转换ADC | ADC将模拟电压转换为数字编码，采样率和分辨率决定转换精度。模数转换是模拟世界与数字世界的桥梁，声音和图像经ADC后才能被计算机处理。 | Analog-to-Digital Converter (ADC) | ADCs convert analog voltage into digital codes; sampling rate and resolution determine conversion accuracy. Analog-to-digital conversion is the bridge between the analog and digital worlds; sound and images must pass through ADC before computers can process them. | mechanical_electronic_020.jpg | 15×15 |
| 22 | 第2章 | 第2章 | 微控制器MCU | 单片机将CPU存储器和外设集成在一颗芯片上，是嵌入式系统的大脑。从智能手表到洗衣机，微控制器藏在每个智能设备中默默工作。 | Microcontroller Unit (MCU) | Microcontrollers integrate CPU, memory, and peripherals on a single chip, serving as the brain of embedded systems. From smart watches to washing machines, microcontrollers work silently inside every smart device. | mechanical_electronic_021.jpg | 15×15 |
| 23 | 第2章 | 第2章 | 传感器感知 | 温度传感器将热量变化转为电压信号，加速度计感知运动姿态。传感器是电子系统的感官，从手机陀螺仪到工业压力变送器感知物理世界。 | Sensor Perception | Temperature sensors convert heat changes into voltage signals; accelerometers sense motion and orientation. Sensors are the sensory organs of electronic systems, perceiving the physical world from phone gyroscopes to industrial pressure transmitters. | mechanical_electronic_022.jpg | 15×15 |
| 24 | 第2章 | 第2章 | 执行器驱动 | 电机将电能转为旋转运动，电磁阀控制流体通断，执行器是控制系统的手脚。从机器人关节到汽车刹车，执行器将控制信号变为物理动作。 | Actuator Drive | Motors convert electrical energy into rotational motion; solenoid valves control fluid flow; actuators are the hands and feet of control systems. From robot joints to car brakes, actuators convert control signals into physical actions. | mechanical_electronic_023.jpg | 15×15 |
| 25 | 第2章 | 第2章 | PLC工业控制 | 可编程逻辑控制器按程序控制生产线设备顺序动作，替代了传统的继电器柜。PLC是工业自动化的核心，从流水线到电梯控制都由它指挥。 | PLC Industrial Control | Programmable logic controllers control production line equipment sequences according to programs, replacing traditional relay cabinets. PLCs are the core of industrial automation, commanding everything from assembly lines to elevator control. | mechanical_electronic_024.jpg | 15×15 |
| 26 | 第2章 | 第2章 | 步进电机精控 | 步进电机每接收一个脉冲转动一个步距角，无需编码器即可精确控制位置。步进电机是3D打印机和数控机床的驱动器，开环控制简单可靠。 | Stepper Motor Precision Control | Stepper motors rotate one step angle per pulse, enabling precise position control without encoders. Stepper motors are the drivers for 3D printers and CNC machines; open-loop control is simple and reliable. | mechanical_electronic_025.jpg | 15×15 |
| 27 | 第2章 | 第2章 | 伺服电机闭环 | 伺服电机配编码器实现闭环位置控制，响应快精度高，工业机器人关节标配。伺服系统是精密运动控制的核心，毫秒级响应微米级定位。 | Servo Motor Closed Loop | Servo motors with encoders achieve closed-loop position control; fast response and high precision make them standard for industrial robot joints. Servo systems are the core of precision motion control, with millisecond-level response and micron-level positioning. | mechanical_electronic_026.jpg | 15×15 |
| 28 | 第2章 | 第2章 | 变频器调速 | 变频器改变电源频率控制交流电机转速，节能效果显著，空调和电梯都在用。变频调速是电机节能的最佳方案，按需供能避免浪费。 | Variable Frequency Drive Speed Control | Variable frequency drives change power supply frequency to control AC motor speed, with significant energy savings; used in air conditioners and elevators. Variable frequency speed control is the best solution for motor energy efficiency, supplying energy on demand to avoid waste. | mechanical_electronic_027.jpg | 15×15 |
| 29 | 第2章 | 第2章 | 触摸屏交互 | 电容触摸屏感应手指电荷变化定位触点，多点触控让缩放旋转自然流畅。触摸屏是人机交互的革命，从电阻屏到电容屏触控体验不断进化。 | Touchscreen Interaction | Capacitive touchscreens sense finger charge changes to locate touch points; multi-touch enables natural pinch-zoom and rotation. Touchscreens are a revolution in human-machine interaction; touch experience continuously evolves from resistive to capacitive screens. | mechanical_electronic_028.jpg | 15×15 |
| 30 | 第2章 | 第2章 | OLED自发光 | OLED每个像素自发光无需背光，可弯曲可透明，黑色纯净对比度极高。OLED是显示技术的未来，从手机到电视画面越来越绚丽。 | OLED Self-Emitting Display | OLED pixels emit light themselves without backlight; flexible and transparent, with pure blacks and extremely high contrast. OLED is the future of display technology; screens from phones to TVs are increasingly brilliant. | mechanical_electronic_029.jpg | 15×15 |
| 31 | 第2章 | 第2章 | 锂电池储能 | 锂离子在正负极间嵌入脱出实现充放电，能量密度高循环寿命长。锂电池是移动设备的动力源，从手机到电动车改变了能源格局。 | Lithium Battery Energy Storage | Lithium ions intercalate and deintercalate between cathode and anode for charging and discharging; high energy density and long cycle life. Lithium batteries are the power source for mobile devices, transforming the energy landscape from phones to electric vehicles. | mechanical_electronic_030.jpg | 15×15 |
| 32 | 第2章 | 第2章 | 无线充电感应 | 无线充电利用电磁感应原理，发射线圈产生交变磁场在接收线圈中感应电流。无线充电让设备摆脱线缆束缚，磁共振技术还能实现远距离充电。 | Wireless Charging Induction | Wireless charging uses electromagnetic induction; transmitting coils generate alternating magnetic fields that induce current in receiving coils. Wireless charging frees devices from cables; magnetic resonance technology enables longer-distance charging. | mechanical_electronic_031.jpg | 15×15 |

### 第3章：自动化控制 Automation Control（17张）

| 序号 | 章节 | 章节 | 标题 | 描述 | 英文标题 | 英文描述 | 文件名 | 难度 |
| ---- | ---- | ---- | ---- | ---- | -------- | -------- | ------ | ---- |
| 33 | 第3章 | 第3章 | PCB贴片工艺 | 贴片机以每小时数万颗的速度将元器件贴装到PCB上，回流焊将锡膏熔化焊接。表面贴装技术让电子产品越来越小越来越轻。 | PCB SMT Process | Pick-and-place machines mount components onto PCBs at tens of thousands per hour; reflow soldering melts solder paste for joining. Surface mount technology makes electronic products increasingly smaller and lighter. | mechanical_electronic_032.jpg | 15×15 |
| 34 | 第3章 | 第3章 | 电磁兼容EMC | 电子设备既要抵抗外部电磁干扰又不能对外发射过多干扰，EMC设计确保兼容共存。电磁兼容是电子产品的必修课，屏蔽滤波接地是三大法宝。 | Electromagnetic Compatibility (EMC) | Electronic devices must resist external electromagnetic interference while not emitting excessive interference; EMC design ensures compatible coexistence. EMC is a required course for electronic products; shielding, filtering, and grounding are the three magic weapons. | mechanical_electronic_033.jpg | 15×15 |
| 35 | 第3章 | 第3章 | 信号完整性 | 高速数字信号在PCB走线中传输时，阻抗匹配和信号完整性决定数据是否正确。信号完整性是高速设计的核心，反射串扰和抖动是三大敌人。 | Signal Integrity | When high-speed digital signals travel through PCB traces, impedance matching and signal integrity determine data correctness. Signal integrity is the core of high-speed design; reflection, crosstalk, and jitter are the three enemies. | mechanical_electronic_034.jpg | 20×20 |
| 36 | 第3章 | 第3章 | 电源管理芯片 | 电源管理芯片将输入电压转换为各元器件所需的不同电压，效率越高发热越少。电源管理是电子系统的心脏，LDO和开关稳压器各有适用场景。 | Power Management IC | Power management ICs convert input voltage to different voltages required by various components; higher efficiency means less heat. Power management is the heart of electronic systems; LDOs and switching regulators each have their applicable scenarios. | mechanical_electronic_035.jpg | 20×20 |
| 37 | 第3章 | 第3章 | FPGA可编程 | FPGA是可编程逻辑器件，工程师用硬件描述语言定义芯片内部逻辑功能。FPGA是硬件的软件化，原型验证和加速计算都离不开它。 | FPGA Programmable Logic | FPGAs are programmable logic devices; engineers define chip internal logic functions using hardware description languages. FPGAs represent the software-ization of hardware; indispensable for prototype verification and accelerated computing. | mechanical_electronic_036.jpg | 20×20 |
| 38 | 第3章 | 第3章 | 嵌入式系统 | 嵌入式系统将硬件和软件结合实现特定功能，从智能手环到汽车ABS都是嵌入式。嵌入式系统无处不在，专用高效是它的设计哲学。 | Embedded Systems | Embedded systems combine hardware and software to implement specific functions; from smart wristbands to automotive ABS, they are embedded. Embedded systems are ubiquitous; dedicated efficiency is their design philosophy. | mechanical_electronic_037.jpg | 20×20 |
| 39 | 第3章 | 第3章 | 机器人关节 | 六轴工业机器人每个关节由伺服电机驱动，控制器协调六轴运动完成焊接喷涂。工业机器人是制造业的钢铁工人，精度和速度远超人类。 | Robot Joints | Each joint of a six-axis industrial robot is driven by a servo motor; the controller coordinates six-axis motion for welding and painting. Industrial robots are the steel workers of manufacturing; their precision and speed far exceed humans. | mechanical_electronic_038.jpg | 20×20 |
| 40 | 第3章 | 第3章 | 机器视觉检测 | 工业相机拍摄产品图像，视觉算法检测缺陷和尺寸，替代人工目检。机器视觉是工业的眼睛，微米级精度和毫秒级速度让质检自动化。 | Machine Vision Inspection | Industrial cameras capture product images; vision algorithms detect defects and dimensions, replacing manual visual inspection. Machine vision is the eye of industry; micron-level precision and millisecond-level speed automate quality inspection. | mechanical_electronic_039.jpg | 20×20 |
| 41 | 第3章 | 第3章 | 柔性制造系统 | 柔性制造系统按订单自动切换生产不同产品，AGV小车在工位间运送物料。柔性制造是工业四点零的核心，小批量多品种也能高效生产。 | Flexible Manufacturing System | Flexible manufacturing systems automatically switch production between different products per orders; AGV carts transport materials between stations. Flexible manufacturing is the core of Industry 4.0; small batches and high variety can also be produced efficiently. | mechanical_electronic_040.jpg | 20×20 |
| 42 | 第3章 | 第3章 | 机电一体化 | 机电一体化将机械、电子、控制和软件融合，数控机床和机器人都是典型。机电一体化是现代装备的灵魂，学科交叉催生创新。 | Mechatronics Integration | Mechatronics integrates mechanical, electronic, control, and software systems; CNC machines and robots are typical examples. Mechatronics is the soul of modern equipment; interdisciplinary intersection breeds innovation. | mechanical_electronic_041.jpg | 20×20 |
| 43 | 第3章 | 第3章 | MEMS微机电 | MEMS在硅片上制造微米级机械结构，手机中的加速度计和陀螺仪就是MEMS器件。微机电系统是芯片与机械的融合，指甲盖上的微型机器。 | MEMS Micro-Electromechanical Systems | MEMS fabricate micron-scale mechanical structures on silicon wafers; accelerometers and gyroscopes in phones are MEMS devices. Micro-electromechanical systems are the fusion of chips and mechanics; miniature machines on a fingernail. | mechanical_electronic_042.jpg | 20×20 |
| 44 | 第3章 | 第3章 | 继电器电磁 | 电磁继电器用小电流控制大电流通断，线圈通电产生磁力吸合触点。继电器是电气控制的开关，从汽车闪光器到工业控制柜都在使用。 | Electromagnetic Relay | Electromagnetic relays use small current to control large current switching; energized coils generate magnetic force to close contacts. Relays are switches for electrical control; used from automotive flashers to industrial control cabinets. | mechanical_electronic_043.jpg | 20×20 |
| 45 | 第3章 | 第3章 | 变压器升降压 | 变压器利用电磁感应改变交流电压，升压减少输电损耗降压保障用电安全。变压器是电力系统的关键设备，铁芯中交变磁场传递能量。 | Transformer Step-Up/Step-Down | Transformers use electromagnetic induction to change AC voltage; step-up reduces transmission losses, step-down ensures safe electricity use. Transformers are key equipment in power systems; alternating magnetic fields in iron cores transfer energy. | mechanical_electronic_044.jpg | 20×20 |
| 46 | 第3章 | 第3章 | 电机驱动控制 | 电机驱动器将直流电转为交流电驱动无刷电机，FOC算法实现精确转矩控制。电机驱动是电动化的核心，从无人机到电动汽车都需要高效驱动。 | Motor Drive Control | Motor drives convert DC to AC to drive brushless motors; FOC algorithms achieve precise torque control. Motor drives are the core of electrification; from drones to electric vehicles, efficient drives are essential. | mechanical_electronic_045.jpg | 20×20 |
| 47 | 第3章 | 第3章 | 工业总线通信 | Profibus和EtherCAT等工业总线连接PLC与传感器执行器，实时可靠传输数据。工业总线是自动化系统的神经网络，毫秒级通信保证同步控制。 | Industrial Bus Communication | Industrial buses like Profibus and EtherCAT connect PLCs with sensors and actuators, transmitting data reliably in real time. Industrial buses are the neural network of automation systems; millisecond-level communication ensures synchronized control. | mechanical_electronic_046.jpg | 20×20 |
| 48 | 第3章 | 第3章 | 人机界面HMI | HMI触摸屏显示设备状态和报警信息，操作员点按按钮启停设备监控生产。人机界面是操作员与机器的对话窗口，直观友好是设计原则。 | Human-Machine Interface (HMI) | HMI touchscreens display equipment status and alarm information; operators tap buttons to start/stop equipment and monitor production. HMI is the dialogue window between operators and machines; intuitive and friendly design is the principle. | mechanical_electronic_047.jpg | 20×20 |
| 49 | 第3章 | 第3章 | 安全继电器保护 | 安全继电器监控急停按钮和安全光栅，一旦触发立即切断动力电源保护人员。安全是工业的第一要务，安全回路冗余设计确保万无一失。 | Safety Relay Protection | Safety relays monitor emergency stop buttons and safety light curtains; once triggered, they immediately cut power to protect personnel. Safety is industry's top priority; redundant safety circuit design ensures foolproof protection. | mechanical_electronic_048.jpg | 20×20 |

### 第4章：精密制造 Precision Manufacturing（16张）

| 序号 | 章节 | 章节 | 标题 | 描述 | 英文标题 | 英文描述 | 文件名 | 难度 |
| ---- | ---- | ---- | ---- | ---- | -------- | -------- | ------ | ---- |
| 50 | 第4章 | 第4章 | 气动元件气缸 | 气缸将压缩空气的压力能转为直线运动，电磁阀控制气缸伸缩动作。气动系统清洁快速，食品和医药行业首选气动驱动。 | Pneumatic Components: Cylinders | Cylinders convert compressed air pressure energy into linear motion; solenoid valves control cylinder extension and retraction. Pneumatic systems are clean and fast; the preferred drive for food and pharmaceutical industries. | mechanical_electronic_049.jpg | 20×20 |
| 51 | 第4章 | 第4章 | 密封技术防漏 | O型圈和机械密封防止液压油和冷却液泄漏，密封是机械可靠性的关键。密封技术看似简单实则精密，泄漏是机械故障的首要原因。 | Sealing Technology Leak Prevention | O-rings and mechanical seals prevent hydraulic oil and coolant leaks; sealing is key to mechanical reliability. Sealing technology seems simple but is actually precise; leakage is the primary cause of mechanical failure. | mechanical_electronic_050.jpg | 20×20 |
| 52 | 第4章 | 第4章 | 热处理淬火 | 将钢件加热到高温后快速冷却淬火提高硬度，再回火消除脆性获得强韧兼备。热处理是金属的炼金术，同样的钢材不同热处理性能天差地别。 | Heat Treatment Quenching | Steel parts are heated to high temperatures and rapidly cooled by quenching to increase hardness, then tempered to eliminate brittleness for combined strength and toughness. Heat treatment is the alchemy of metals; the same steel with different heat treatments yields vastly different properties. | mechanical_electronic_051.jpg | 20×20 |
| 53 | 第4章 | 第4章 | 表面处理防腐 | 电镀锌和阳极氧化在金属表面形成保护层，防止腐蚀延长使用寿命。表面处理是金属的铠甲，海洋和化工环境中防腐是生死攸关的问题。 | Surface Treatment Anti-Corrosion | Zinc electroplating and anodizing form protective layers on metal surfaces, preventing corrosion and extending service life. Surface treatment is metal's armor; anti-corrosion in marine and chemical environments is a life-or-death issue. | mechanical_electronic_052.jpg | 25×25 |
| 54 | 第4章 | 第4章 | 精密测量量具 | 千分尺测量精度达零点零一毫米，三坐标测量机检测复杂零件三维尺寸。精密测量是制造的标尺，没有测量就没有制造。 | Precision Measuring Instruments | Micrometers measure with 0.01 mm precision; coordinate measuring machines inspect complex part dimensions in 3D. Precision measurement is the ruler of manufacturing; without measurement, there is no manufacturing. | mechanical_electronic_053.jpg | 25×25 |
| 55 | 第4章 | 第4章 | 振动分析诊断 | 加速度传感器采集旋转机械振动信号，频谱分析诊断轴承和齿轮故障。振动分析是设备体检的听诊器，早期发现故障避免重大损失。 | Vibration Analysis Diagnosis | Accelerometers collect vibration signals from rotating machinery; spectral analysis diagnoses bearing and gear faults. Vibration analysis is the stethoscope for equipment checkups; early fault detection prevents major losses. | mechanical_electronic_054.jpg | 25×25 |
| 56 | 第4章 | 第4章 | 激光切割精密切割 | 激光束聚焦到微小光斑熔化或气化金属，计算机控制切割出任意形状。激光切割精度高速度快无刀具磨损，是钣金加工的首选工艺。 | Laser Precision Cutting | Laser beams focus onto tiny spots to melt or vaporize metal; computer control cuts arbitrary shapes. Laser cutting offers high precision, fast speed, and no tool wear; it is the preferred process for sheet metal fabrication. | mechanical_electronic_055.jpg | 25×25 |
| 57 | 第4章 | 第4章 | 水刀冷态切割 | 高压水混合磨料以三倍音速喷射切割材料，冷态切割不产生热变形。水刀切割适合热敏感材料，从钛合金到玻璃钢都能一刀两断。 | Waterjet Cold Cutting | High-pressure water mixed with abrasive cuts materials at three times the speed of sound; cold cutting produces no thermal deformation. Waterjet cutting suits heat-sensitive materials; from titanium alloys to fiberglass, it cuts through cleanly. | mechanical_electronic_056.jpg | 25×25 |
| 58 | 第4章 | 第4章 | 工业CT无损检测 | 工业CT用X射线扫描铸件内部，三维重建发现缩孔和裂纹等缺陷。无损检测让零件不开膛破肚就能看到内部，质量把关的透视眼。 | Industrial CT Non-Destructive Testing | Industrial CT uses X-rays to scan casting interiors; 3D reconstruction reveals defects like shrinkage cavities and cracks. Non-destructive testing lets parts be inspected internally without disassembly; the X-ray eye for quality control. | mechanical_electronic_057.jpg | 25×25 |
| 59 | 第4章 | 第4章 | 柔性机械手抓取 | 柔性夹具用气动手指和吸盘适应不同形状工件，快速换型无需更换夹具。柔性抓取是智能工厂的触手，一爪多用降低换线成本。 | Flexible Robotic Gripping | Flexible fixtures use pneumatic fingers and suction cups to adapt to different workpiece shapes; quick changeover without replacing fixtures. Flexible gripping is the tentacle of smart factories; one gripper for multiple uses reduces changeover costs. | mechanical_electronic_058.jpg | 25×25 |
| 60 | 第4章 | 第4章 | 丝杠精密传动 | 滚珠丝杠将旋转运动转为直线运动，钢珠在螺纹滚道中滚动摩擦极小。滚珠丝杠是数控机床进给系统的核心，微米级定位精度靠它保证。 | Ball Screw Precision Transmission | Ball screws convert rotational motion into linear motion; steel balls roll in threaded raceways with minimal friction. Ball screws are the core of CNC machine feed systems, ensuring micron-level positioning accuracy. | mechanical_electronic_059.jpg | 25×25 |
| 61 | 第4章 | 第4章 | 直线导轨导向 | 直线导轨用钢珠循环滚动实现低摩擦直线运动，承载大刚度高寿命长。直线导轨是精密平台的基础，从半导体光刻机到坐标测量机都离不开。 | Linear Guide Rail Guidance | Linear guides use recirculating steel balls for low-friction linear motion; high load capacity, rigidity, and long service life. Linear guides are the foundation of precision platforms; indispensable from semiconductor lithography machines to coordinate measuring machines. | mechanical_electronic_060.jpg | 25×25 |
| 62 | 第4章 | 第4章 | 谐波减速器柔轮 | 谐波减速器利用柔轮弹性变形实现大减速比，体积小精度高用于机器人关节。谐波传动是机器人关节的肌肉，紧凑结构中藏着精密减速。 | Harmonic Drive Reducer Flexspline | Harmonic drives use elastic deformation of the flexspline to achieve large reduction ratios; compact and high-precision, used in robot joints. Harmonic transmission is the muscle of robot joints; precise reduction hidden in a compact structure. | mechanical_electronic_061.jpg | 25×25 |
| 63 | 第4章 | 第4章 | RV减速器重载 | RV减速器用摆线针轮结构承受大扭矩，工业机器人基座和腰部关节首选。RV减速器是机器人的大力士，重载高精度长寿命三位一体。 | RV Reducer Heavy Load | RV reducers use cycloidal pinwheel structures to withstand large torque; preferred for industrial robot base and waist joints. RV reducers are the strongmen of robots; heavy load, high precision, and long life in one package. | mechanical_electronic_062.jpg | 25×25 |
| 64 | 第4章 | 第4章 | 光电编码器测角 | 光电编码器码盘上刻有精密光栅，光电信号读出旋转角度，分辨率可达数万线。编码器是运动控制的眼睛，闭环系统中精确反馈位置信息。 | Photoelectric Encoder Angle Measurement | Photoelectric encoder discs have precision gratings; photoelectric signals read rotation angles with resolution up to tens of thousands of lines. Encoders are the eyes of motion control, providing precise position feedback in closed-loop systems. | mechanical_electronic_063.jpg | 25×25 |
| 65 | 第4章 | 第4章 | 力矩传感器感知 | 协作机器人关节中力矩传感器实时检测受力，碰到人时自动停止保证安全。力矩传感器让机器人有了触觉，人机协作的前提是感知力量。 | Torque Sensor Perception | Torque sensors in collaborative robot joints detect forces in real time; automatically stop upon contact with humans for safety. Torque sensors give robots a sense of touch; the prerequisite for human-robot collaboration is sensing force. | mechanical_electronic_064.jpg | 25×25 |

**图片规格：**
- 分辨率：2496×1664（3:2宽高比）
- 分块方式：3×2 = 6块/图
- 常规谜题数：312个（前52张图每张6个分块谜题）
- **25×25专家谜题数**：78个（第53-65号图片各6个分块谜题）
- 谜题总数：403个

**像素图：**
- 命名规范：原图文件名 + `_pixel.jpg`
- 示例：`mechanical_electronic_000_pixel.jpg`

**关卡文件：**
- 目录：`data/puzzles/mechanical_electronic/`
- 常规关卡命名：`{图片ID}_{分块索引}.json`
  - 示例：`mechanical_electronic_000_0.json` ~ `mechanical_electronic_000_5.json`
- 专家关卡命名：`{图片ID}_expert.json`
  - 示例：`mechanical_electronic_052_expert.json`
  - 仅第53-65号图片包含专家关卡
