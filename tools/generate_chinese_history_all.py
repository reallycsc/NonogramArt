import os
import json
import random
import time
import requests
from PIL import Image
from io import BytesIO
from pathlib import Path
from datetime import datetime

BASE_DIR = Path("h:/Work/MyProject/NonogramArt")
PICTURES_DIR = BASE_DIR / "data" / "pictures"
PUZZLES_DIR = BASE_DIR / "data" / "puzzles" / "chinese_history"
IMAGES_DIR = BASE_DIR / "assets" / "images" / "illustrations" / "chinese_history"
ACCOUNTS_FILE = BASE_DIR / "tools" / "api_accounts.json"
USAGE_FILE = BASE_DIR / "tools" / "api_usage.json"

API_BASE_URL = "https://ark.cn-beijing.volces.com/api/v3/images/generations"

STYLE_PREFIX = "中国风卡通插画，Q版2-3头身比例人物，圆润流畅线条，色彩丰富多样，画面构图饱满，"
SHELF_COLOR_KEYWORDS = "色彩搭配和谐"
STYLE_SUFFIX = "，画面边缘有丰富细节，不要大面积纯色背景，不要出现任何中文文字或汉字"
NEGATIVE_PROMPT = "写实照片,3D渲染,暗色调,灰暗,恐怖,血腥,真实人物,photorealistic,dark,gloomy,写实风格,摄影,中文文字,汉字,书法字,文字水印"

ASPECT_RATIO_SIZES = {
    "1:1": "2048x2048",
    "4:3": "2304x1728",
    "3:4": "1728x2304",
    "16:9": "2848x1600",
    "9:16": "1600x2848",
    "3:2": "2496x1664",
    "2:3": "1664x2496",
    "21:9": "3136x1344",
}

SILICONFLOW_SIZE_MAP = {
    "3:2": "1536x1024",
    "2:3": "1024x1536",
    "1:1": "1024x1024",
    "4:3": "960x1280",
    "3:4": "768x1024",
    "16:9": "1024x576",
    "9:16": "576x1024",
}

QWEN_IMAGE_SIZE_MAP = {
    "3:2": "1584x1056",
    "2:3": "1056x1584",
    "1:1": "1328x1328",
    "4:3": "1472x1140",
    "3:4": "1140x1472",
    "16:9": "1664x928",
    "9:16": "928x1664",
}

PICTURES = [
    {"id": "chapter1_01_yuanmou", "title": "元谋人遗址", "summary": "中国最早的人类化石发现地", "full_text": "在云南省元谋县的广袤土地上，考古学家们发现了距今约170万年的人类牙齿化石。这一重大发现将中国人类历史向前推进了一大步，元谋人也因此成为中国境内已知最早的人类代表。这些古老的化石静静地诉说着远古人类的生存故事。", "chapter": 1, "grid_size": 5, "difficulty": "tutorial", "scene": "远古人类在云南红土地上进行采集活动，手持简单石器，背景是茂密的原始森林和火山"},
    {"id": "chapter1_02_beijing_ape", "title": "北京猿人生活场景", "summary": "原始人在山洞前使用石器", "full_text": "周口店龙骨山的山洞里，曾经生活着一群北京猿人。他们用粗糙的石器狩猎采集，学会了使用天然火来取暖照明。这些原始人类在严酷的自然环境中顽强生存，为人类文明的发展奠定了基础。他们的故事就刻在龙骨山的岩壁上。", "chapter": 1, "grid_size": 10, "difficulty": "easy", "scene": "北京猿人在周口店山洞前使用石器，围坐在篝火旁，背景是连绵山脉和原始森林"},
    {"id": "chapter1_03_shandingdong", "title": "山顶洞人狩猎", "summary": "原始人类围猎大型动物", "full_text": "三万年前的山顶洞人已经掌握了高超的技艺。他们学会了磨光和钻孔，用兽骨制作精美的装饰品，甚至有了原始的宗教信仰。这些发现揭示了旧石器时代晚期人类精神世界的丰富内涵，展现了人类智慧的飞跃。", "chapter": 1, "grid_size": 10, "difficulty": "easy", "scene": "山顶洞人围猎大型动物，手持长矛追逐鹿群，背景是雪山和草原"},
    {"id": "chapter1_04_hemudu", "title": "河姆渡文化", "summary": "原始农耕和干栏式房屋建筑", "full_text": "长江流域的河姆渡遗址展现了一幅七千年前的繁荣景象。这里出土的稻谷遗迹证明中国是世界上最早种植水稻的国家之一。干栏式建筑的发现更是改写了中国建筑史，展现了古人卓越的建筑智慧和适应自然的能力。", "chapter": 1, "grid_size": 10, "difficulty": "easy", "scene": "河姆渡文化场景，干栏式房屋建筑，原始农耕种植水稻，人们在水田中劳作"},
    {"id": "chapter1_05_yangshao", "title": "仰韶文化彩陶", "summary": "精美的彩陶器皿", "full_text": "黄河岸边的仰韶文化以精美的彩陶闻名于世。这些色彩斑斓的陶器上绘制着鱼纹、蛙纹和几何图案，每一件都是艺术与实用的完美结合。透过这些彩陶，我们仿佛能看到远古先民们丰富的精神世界和对美的追求。", "chapter": 1, "grid_size": 10, "difficulty": "easy", "scene": "仰韶文化彩陶，精美的彩陶器皿展示，鱼纹和几何图案装饰，人们在制作陶器"},
    {"id": "chapter1_06_liangzhu", "title": "良渚古城", "summary": "长江流域早期文明", "full_text": "浙江杭州的良渚古城遗址震惊了世界。这座五千年前的古城规模宏大，水利系统完善，出土的精美玉器更是令人叹为观止。良渚文明的发现证明了长江流域同样是中华文明的重要发源地，改写了中国文明史。", "chapter": 1, "grid_size": 10, "difficulty": "easy", "scene": "良渚古城遗址，宏伟的古城墙和水利系统，精美的玉器展示"},
    {"id": "chapter1_07_huangdi", "title": "黄帝部落联盟", "summary": "炎黄二帝带领部落", "full_text": "黄帝被尊为中华民族的人文初祖。传说中他带领部落发展农业、制作衣冠、建造舟车，奠定了中华文明的基础。黄帝与炎帝部落的融合形成了华夏民族的雏形，他的故事永远铭刻在中华民族的记忆中。", "chapter": 1, "grid_size": 10, "difficulty": "easy", "scene": "黄帝部落联盟，炎黄二帝带领部落民众，旗帜飘扬，部落联盟大会"},
    {"id": "chapter1_08_dayu", "title": "大禹治水", "summary": "大禹带领民众治理洪水", "full_text": "大禹治水的故事流传千古。他采用疏导的方法，历时十三年终于平息了肆虐的洪水。三过家门而不入的忘我精神成为中华民族宝贵的精神财富。大禹建立的夏朝开启了中国历史上第一个王朝，成为华夏文明的重要里程碑。", "chapter": 1, "grid_size": 10, "difficulty": "easy", "scene": "大禹治水，大禹带领民众疏导洪水，手持耒耜，河流奔腾"},
    {"id": "chapter2_09_xia_gongdian", "title": "夏朝宫殿想象图", "summary": "夏王朝的都城建筑", "full_text": "夏朝的宫殿虽然已经湮没在历史长河中，但文献记载和考古发现勾勒出它的宏伟轮廓。这座古老的宫殿见证了中国早期国家形态的形成，展现了夏王朝的繁荣与威严，是中国宫殿建筑的源头。", "chapter": 2, "grid_size": 10, "difficulty": "easy", "scene": "夏朝宫殿想象图，宏伟的古代宫殿建筑，宫殿前有仪仗队"},
    {"id": "chapter2_10_erlitou", "title": "二里头遗址", "summary": "夏代晚期都城遗址", "full_text": "河南偃师的二里头遗址被认为是夏朝中晚期的都城。这里发现了宏伟的宫殿基址、青铜礼器和精美的玉器。二里头文化的发现为探索夏文化提供了重要线索，让我们得以窥见中国早期文明的灿烂面貌。", "chapter": 2, "grid_size": 10, "difficulty": "easy", "scene": "二里头遗址考古场景，宫殿基址遗迹，青铜礼器和玉器出土，考古学家在发掘"},
    {"id": "chapter2_11_jiaguwen", "title": "甲骨文", "summary": "刻有文字的龟甲兽骨", "full_text": "刻在龟甲兽骨上的甲骨文是中国最早的成熟文字。这些古老的文字记录了商王朝的祭祀、战争和日常生活。甲骨文的发现不仅证实了商王朝的存在，更为研究中国文字演变提供了珍贵的第一手资料。", "chapter": 2, "grid_size": 10, "difficulty": "easy", "scene": "甲骨文，刻有文字的龟甲和兽骨，商代占卜场景，贞人在甲骨上刻字"},
    {"id": "chapter2_12_simuwu", "title": "司母戊鼎", "summary": "商代青铜重器", "full_text": "司母戊鼎是中国古代青铜文化的巅峰之作。这件重达八百多公斤的青铜巨器造型庄严，纹饰精美，展现了商代青铜铸造技术的惊人成就。它不仅是一件礼器，更是中华民族青铜文明的象征。", "chapter": 2, "grid_size": 10, "difficulty": "easy", "scene": "司母戊鼎，巨大的青铜方鼎，纹饰精美，商代祭祀场景"},
    {"id": "chapter2_13_qingtongqi", "title": "商周青铜器", "summary": "精美的青铜礼器", "full_text": "商周时期的青铜器代表了中国古代青铜艺术的最高水平。从威严的礼器到精美的酒器，每一件青铜器都凝聚着工匠的智慧与心血。这些青铜器不仅是实用器具，更是权力、礼仪和信仰的象征。", "chapter": 2, "grid_size": 10, "difficulty": "easy", "scene": "商周青铜器，各种精美的青铜礼器展示，鼎、簋、爵等"},
    {"id": "chapter2_14_wenwang", "title": "周文王推演周易", "summary": "周文王在狱中推演八卦", "full_text": "周文王在羑里狱中推演八卦，创造了博大精深的《周易》。这部古老的经典蕴含着深邃的哲学思想，成为中国传统文化的重要源头。周文王的智慧和毅力为后人留下了宝贵的精神财富。", "chapter": 2, "grid_size": 10, "difficulty": "easy", "scene": "周文王在羑里狱中推演八卦，伏案思考，八卦图案环绕"},
    {"id": "chapter2_15_wuwang", "title": "周武王伐纣", "summary": "牧野之战场景", "full_text": "周武王率领正义之师在牧野之战中击败商纣王，建立了周王朝。这场历史性的变革开启了中国历史上一个重要的时代，确立了周礼制度，对中国文化产生了深远影响。", "chapter": 2, "grid_size": 10, "difficulty": "easy", "scene": "周武王伐纣牧野之战，战车冲锋，将士奋勇作战，战旗飘扬"},
    {"id": "chapter2_16_zhougong", "title": "周公旦辅政", "summary": "周公辅佐成王", "full_text": "周公旦辅佐成王，制定了完备的礼乐制度。他的治国理念和道德规范成为后世儒家思想的重要源头。周公吐哺、天下归心的故事成为千古美谈，展现了贤臣辅佐君王的崇高理想。", "chapter": 2, "grid_size": 10, "difficulty": "easy", "scene": "周公旦辅佐成王，年幼的成王坐在王位上，周公在旁辅政，朝廷议事"},
    {"id": "chapter2_17_wuba", "title": "春秋五霸", "summary": "齐桓公、晋文公等霸主", "full_text": "春秋时期，齐桓公、晋文公、楚庄王、吴王阖闾、越王勾践先后称霸天下。他们或尊王攘夷，或改革图强，在诸侯争霸的舞台上上演了一幕幕波澜壮阔的历史剧，共同书写了春秋时代的辉煌篇章。", "chapter": 2, "grid_size": 10, "difficulty": "easy", "scene": "春秋五霸，齐桓公晋文公等霸主齐聚，各国旗帜飘扬，诸侯会盟"},
    {"id": "chapter2_18_kongzi", "title": "孔子讲学", "summary": "孔子在杏坛讲学", "full_text": "孔子在杏坛讲学，开创了私学的先河。他的思想核心是仁与礼，强调道德修养和社会秩序。孔子的教诲被弟子们记录在《论语》中，成为中国传统文化的重要基石，影响了中国两千多年的历史。", "chapter": 2, "grid_size": 10, "difficulty": "easy", "scene": "孔子在杏坛讲学，弟子们围坐聆听，杏花盛开"},
    {"id": "chapter2_19_laozi", "title": "老子骑牛出关", "summary": "老子西出函谷关", "full_text": "老子骑青牛西出函谷关，留下了五千言的《道德经》。这部哲学经典阐述了无为而治的思想，探讨了宇宙万物的本源。老子的智慧深刻影响了中国的哲学、宗教和文化发展。", "chapter": 2, "grid_size": 10, "difficulty": "easy", "scene": "老子骑青牛西出函谷关，紫气东来，关隘巍峨"},
    {"id": "chapter2_20_sunzi", "title": "孙子兵法", "summary": "孙武著兵法", "full_text": "孙武所著的《孙子兵法》是世界上最早的军事著作之一。这部兵法十三篇蕴含着深刻的战略思想和战术智慧，不仅在军事领域影响深远，更被广泛应用于商业、管理等多个领域。", "chapter": 2, "grid_size": 10, "difficulty": "easy", "scene": "孙武著兵法，竹简展开，兵法十三篇，军事阵法图"},
    {"id": "chapter2_21_shangyang", "title": "商鞅变法", "summary": "商鞅在秦国推行变法", "full_text": "商鞅在秦国推行变法，废井田、开阡陌，奖励耕战。这场深刻的变革使秦国迅速强大起来，为后来秦始皇统一六国奠定了坚实基础。商鞅变法的魄力和远见令人赞叹。", "chapter": 2, "grid_size": 10, "difficulty": "easy", "scene": "商鞅变法，徙木立信场景，民众围观，秦国朝堂"},
    {"id": "chapter2_22_quyuan", "title": "屈原投江", "summary": "屈原怀抱石头投汨罗江", "full_text": "屈原是中国历史上第一位伟大的诗人。他的《离骚》开创了浪漫主义文学的先河，表达了对国家和人民的深切热爱。屈原投江的故事催生了端午节的传统，他的爱国精神永远为后人所敬仰。", "chapter": 2, "grid_size": 10, "difficulty": "easy", "scene": "屈原投江，屈原站在汨罗江边，怀抱石头，悲愤表情，江水滔滔"},
    {"id": "chapter2_23_jingke", "title": "荆轲刺秦王", "summary": "荆轲在咸阳宫行刺", "full_text": "荆轲刺秦王的故事惊心动魄。这位勇敢的刺客为了报答太子丹的知遇之恩，毅然前往秦国行刺。虽然最终失败，但荆轲不畏强权、舍生取义的精神成为千古传颂的佳话。", "chapter": 2, "grid_size": 10, "difficulty": "easy", "scene": "荆轲刺秦王，咸阳宫大殿上荆轲追击秦王，图穷匕见，群臣惊慌"},
    {"id": "chapter3_24_qinshihuang", "title": "秦始皇统一六国", "summary": "秦始皇登基称帝", "full_text": "秦始皇横扫六国，完成了中国历史上第一次大一统。他统一文字、度量衡和货币，修建万里长城，确立郡县制。这些举措对中国历史产生了深远影响，奠定了中国两千多年封建社会的基础。", "chapter": 3, "grid_size": 10, "difficulty": "easy", "scene": "秦始皇统一六国，秦始皇登基称帝，六国旗帜倒下，统一文字度量衡"},
    {"id": "chapter3_25_changcheng", "title": "秦长城", "summary": "秦始皇修建的万里长城", "full_text": "万里长城是中华民族的象征。秦始皇将各国的长城连接起来，形成了一道绵延万里的军事防线。这座伟大的建筑工程凝聚着无数劳动人民的血汗，成为世界奇迹之一。", "chapter": 3, "grid_size": 10, "difficulty": "easy", "scene": "秦长城，万里长城蜿蜒在崇山峻岭间，劳工修筑场景，烽火台耸立"},
    {"id": "chapter3_26_bingmayong", "title": "兵马俑", "summary": "壮观的秦兵马俑坑", "full_text": "秦始皇陵兵马俑震惊了世界。这些栩栩如生的陶俑排列成庞大的军阵，仿佛随时准备出征。每一个兵马俑都有着独特的面容和姿态，展现了秦朝高超的雕塑艺术和强大的国力。", "chapter": 3, "grid_size": 10, "difficulty": "easy", "scene": "秦始皇兵马俑，壮观的兵马俑军阵，陶俑排列整齐，战车和战马"},
    {"id": "chapter3_27_chensheng", "title": "陈胜吴广起义", "summary": "大泽乡起义", "full_text": "陈胜吴广在大泽乡揭竿而起，喊出了'王侯将相宁有种乎'的豪迈口号。这场中国历史上第一次大规模农民起义虽然失败，但它揭开了秦末农民战争的序幕，敲响了秦朝灭亡的丧钟。", "chapter": 3, "grid_size": 10, "difficulty": "easy", "scene": "陈胜吴广起义，大泽乡揭竿而起，农民手持农具和旗帜"},
    {"id": "chapter3_28_chuhan", "title": "刘邦项羽楚汉相争", "summary": "垓下之战", "full_text": "楚汉相争是中国历史上一段波澜壮阔的史诗。刘邦和项羽两大英雄人物在战场上展开激烈角逐。最终刘邦凭借知人善任和战略远见取得胜利，建立了大汉王朝。", "chapter": 3, "grid_size": 10, "difficulty": "easy", "scene": "楚汉相争垓下之战，刘邦和项羽对峙，四面楚歌，战马奔腾"},
    {"id": "chapter3_29_liubang", "title": "汉高祖刘邦", "summary": "汉朝开国皇帝", "full_text": "汉高祖刘邦从一个市井无赖成长为一代帝王。他知人善任，豁达大度，最终战胜项羽建立汉朝。刘邦的故事告诉我们，英雄不问出处，只要胸怀大志并为之奋斗，就能成就一番伟业。", "chapter": 3, "grid_size": 10, "difficulty": "easy", "scene": "汉高祖刘邦，刘邦登基称帝，汉朝宫殿，群臣朝拜"},
    {"id": "chapter3_30_zhangqian", "title": "张骞出使西域", "summary": "张骞带领使团西行", "full_text": "张骞肩负使命出使西域，开辟了著名的丝绸之路。他两次出使西域，历经艰险，促进了东西方文化和经济的交流。张骞的开拓精神成为后世探险家的榜样。", "chapter": 3, "grid_size": 10, "difficulty": "easy", "scene": "张骞出使西域，张骞带领使团骑骆驼西行，丝绸之路上的沙漠和绿洲"},
    {"id": "chapter3_31_hanwudi", "title": "汉武帝刘彻", "summary": "汉武帝接见群臣", "full_text": "汉武帝刘彻在位期间，汉朝达到鼎盛。他罢黜百家、独尊儒术，派卫青霍去病北击匈奴，拓展了中国的疆域。汉武帝的雄才大略使汉朝成为当时世界上最强大的国家之一。", "chapter": 3, "grid_size": 10, "difficulty": "easy", "scene": "汉武帝刘彻，汉武帝接见群臣，宫殿宏伟，文治武功"},
    {"id": "chapter3_32_huoqubing", "title": "霍去病北击匈奴", "summary": "骠骑将军出征", "full_text": "霍去病是西汉名将，十七岁就率军出征匈奴。他六次出击匈奴，屡建奇功，被封为冠军侯。霍去病的勇猛和军事才能令人惊叹，他的故事成为千古美谈。", "chapter": 3, "grid_size": 10, "difficulty": "easy", "scene": "霍去病北击匈奴，骠骑将军率骑兵冲锋，马踏匈奴，战旗飘扬"},
    {"id": "chapter3_33_simaqian", "title": "司马迁写史记", "summary": "司马迁伏案写作", "full_text": "司马迁忍辱负重，历时十余年完成了《史记》这部不朽巨著。这部史书记载了从上古到汉武帝时期的历史，开创了纪传体史书的先河，被誉为'史家之绝唱，无韵之离骚'。", "chapter": 3, "grid_size": 10, "difficulty": "easy", "scene": "司马迁写史记，司马迁伏案书写竹简，烛光映照，史书堆积"},
    {"id": "chapter3_34_zhaojun", "title": "昭君出塞", "summary": "王昭君远嫁匈奴", "full_text": "王昭君远嫁匈奴，为汉匈和平作出了巨大贡献。她的故事成为民族团结的象征，展现了一位弱女子的勇气和担当。昭君出塞的故事被后人传颂不衰。", "chapter": 3, "grid_size": 10, "difficulty": "easy", "scene": "昭君出塞，王昭君骑马远行，琵琶相伴，塞外风光"},
    {"id": "chapter3_35_wangmang", "title": "王莽改制", "summary": "新朝改革", "full_text": "王莽推行新政，试图改革社会弊端。虽然他的改革最终失败，但其中包含了许多超前的理念。王莽改制的尝试反映了当时社会矛盾的尖锐和改革的艰难。", "chapter": 3, "grid_size": 10, "difficulty": "easy", "scene": "王莽改制，新朝朝堂，颁布新政诏书，改革场景"},
    {"id": "chapter3_36_guangwu", "title": "光武中兴", "summary": "刘秀建立东汉", "full_text": "光武帝刘秀重建汉朝，开创了光武中兴的局面。他减轻赋税、整顿吏治，使社会经济得到恢复和发展。光武帝的文治武功使东汉初期呈现出一片繁荣景象。", "chapter": 3, "grid_size": 10, "difficulty": "easy", "scene": "光武中兴，刘秀建立东汉，洛阳宫殿，百废待兴"},
    {"id": "chapter3_37_cailun", "title": "蔡伦造纸", "summary": "改进造纸术", "full_text": "蔡伦改进造纸术，用树皮、破布等原料制造出廉价而优质的纸张。这一发明对人类文明的传播和发展产生了深远影响，成为中国古代四大发明之一。", "chapter": 3, "grid_size": 10, "difficulty": "easy", "scene": "蔡伦造纸，蔡伦在工坊中制作纸张，树皮和破布原料，造纸工序"},
    {"id": "chapter3_38_zhangheng", "title": "张衡与地动仪", "summary": "汉代科学家", "full_text": "张衡是东汉杰出的科学家和文学家。他发明了浑天仪和地动仪，在天文学和地震学领域做出了卓越贡献。张衡的科学精神和创新思维令人敬佩。", "chapter": 3, "grid_size": 10, "difficulty": "easy", "scene": "张衡与地动仪，张衡观测天象，浑天仪和地动仪，汉代科学场景"},
    {"id": "chapter4_39_taoyuan", "title": "桃园三结义", "summary": "刘备、关羽、张飞结拜", "full_text": "刘备、关羽、张飞在桃园结义，誓言同心协力共扶汉室。这个故事成为中国传统文化中兄弟情义的典范，展现了古人重情重义的高尚品德。", "chapter": 4, "grid_size": 10, "difficulty": "easy", "scene": "桃园三结义，刘备关羽张飞在桃花树下结拜，桃花盛开"},
    {"id": "chapter4_40_guandu", "title": "官渡之战", "summary": "曹操击败袁绍", "full_text": "官渡之战是中国历史上著名的以少胜多的战役。曹操以两万兵力击败袁绍十万大军，奠定了统一北方的基础。这场战役充分展示了曹操的军事才能和战略眼光。", "chapter": 4, "grid_size": 10, "difficulty": "easy", "scene": "官渡之战，曹操率军击败袁绍，火烧乌巢，战马奔腾"},
    {"id": "chapter4_41_chibi", "title": "赤壁之战", "summary": "三国时期的著名战役", "full_text": "赤壁之战是三国时期最著名的战役之一。孙刘联军以火攻大败曹军，奠定了三国鼎立的局面。这场战役中的草船借箭、火烧连环船等故事成为千古佳话。", "chapter": 4, "grid_size": 10, "difficulty": "easy", "scene": "赤壁之战，孙刘联军火攻曹军战船，长江上火光冲天，战船燃烧"},
    {"id": "chapter4_42_zhugeliang", "title": "诸葛亮北伐", "summary": "诸葛亮六出祁山", "full_text": "诸葛亮是智慧的化身。他辅佐刘备建立蜀汉，六出祁山北伐中原。诸葛亮的忠诚、智慧和鞠躬尽瘁的精神成为后世贤臣的典范。", "chapter": 4, "grid_size": 10, "difficulty": "easy", "scene": "诸葛亮北伐，诸葛亮乘坐四轮车指挥作战，羽扇纶巾，六出祁山"},
    {"id": "chapter4_43_simayi", "title": "司马懿", "summary": "曹魏权臣", "full_text": "司马懿是三国时期杰出的政治家和军事家。他隐忍待时，最终掌握了曹魏大权。司马懿的谋略和权术为后来司马家族建立晋朝奠定了基础。", "chapter": 4, "grid_size": 10, "difficulty": "easy", "scene": "司马懿，曹魏权臣司马懿，隐忍谋划，军帐中运筹帷幄"},
    {"id": "chapter4_44_wangxizhi", "title": "王羲之书法", "summary": "王羲之书写兰亭序", "full_text": "王羲之被尊为'书圣'，他的书法飘逸灵动，被誉为天下第一行书。王羲之的《兰亭集序》成为书法艺术的巅峰之作，影响了后世无数书法家。", "chapter": 4, "grid_size": 10, "difficulty": "easy", "scene": "王羲之书法，王羲之在兰亭挥毫书写，曲水流觞，文人雅集"},
    {"id": "chapter4_45_gukaizhi", "title": "顾恺之绘画", "summary": "东晋画家", "full_text": "顾恺之是东晋著名画家，擅长人物画。他提出的'以形写神'理论对中国绘画产生了深远影响。顾恺之的画作注重传神，展现了高超的艺术造诣。", "chapter": 4, "grid_size": 10, "difficulty": "easy", "scene": "顾恺之绘画，东晋画家顾恺之在画室作画，洛神赋图"},
    {"id": "chapter4_46_taoyuanming", "title": "陶渊明归隐", "summary": "陶渊明在田园耕作", "full_text": "陶渊明不为五斗米折腰，归隐田园过着简朴的生活。他的田园诗清新自然，表达了对自由和自然的热爱。陶渊明的隐逸精神成为后世文人的精神寄托。", "chapter": 4, "grid_size": 10, "difficulty": "easy", "scene": "陶渊明归隐田园，陶渊明在菊花丛中饮酒，田园风光，南山远眺"},
    {"id": "chapter4_47_xiaowendi", "title": "北魏孝文帝改革", "summary": "孝文帝推行汉化政策", "full_text": "北魏孝文帝推行汉化改革，促进了民族融合。他迁都洛阳，改汉姓，穿汉服，说汉语。这场改革加速了北方少数民族的封建化进程，对中国历史产生了深远影响。", "chapter": 4, "grid_size": 10, "difficulty": "easy", "scene": "北魏孝文帝改革，孝文帝推行汉化，改穿汉服，迁都洛阳"},
    {"id": "chapter4_48_longmen", "title": "龙门石窟", "summary": "佛教艺术的瑰宝", "full_text": "龙门石窟是中国古代石窟艺术的瑰宝。这些精美的佛像雕刻展现了古代工匠的高超技艺和虔诚的信仰。龙门石窟不仅是宗教圣地，更是艺术殿堂。", "chapter": 4, "grid_size": 10, "difficulty": "easy", "scene": "龙门石窟，巨大的佛像雕刻，石窟艺术，信徒朝拜"},
    {"id": "chapter4_49_zuchongzhi", "title": "祖冲之与圆周率", "summary": "南朝科学家", "full_text": "祖冲之是南北朝时期杰出的数学家。他精确计算出圆周率在3.1415926和3.1415927之间，这一精度在当时世界上是领先的。祖冲之的数学成就展现了中国古代科学的辉煌。", "chapter": 4, "grid_size": 10, "difficulty": "easy", "scene": "祖冲之与圆周率，南朝科学家祖冲之计算圆周率，算筹铺开，天文观测"},
    {"id": "chapter4_50_feishui", "title": "淝水之战", "summary": "东晋以少胜多", "full_text": "淝水之战是中国历史上又一次以少胜多的著名战役。东晋以八万兵力击败前秦百万大军。这场战役不仅保住了东晋的江山，更留下了'风声鹤唳，草木皆兵'的典故。", "chapter": 4, "grid_size": 10, "difficulty": "easy", "scene": "淝水之战，东晋以少胜多击败前秦，淝水岸边激战，风声鹤唳"},
    {"id": "chapter5_51_suiwendi", "title": "隋文帝统一中国", "summary": "杨坚建立隋朝", "full_text": "隋文帝杨坚结束了南北朝的分裂局面，统一了中国。他推行均田制和三省六部制，开创了开皇之治的繁荣局面。隋文帝的文治武功为隋朝的强盛奠定了基础。", "chapter": 5, "grid_size": 10, "difficulty": "easy", "scene": "隋文帝统一中国，杨坚建立隋朝，统一南北，朝堂议事"},
    {"id": "chapter5_52_yunhe", "title": "隋炀帝开凿大运河", "summary": "大运河开凿场景", "full_text": "隋炀帝开凿大运河，加强了南北交通和经济交流。这条贯穿南北的运河成为中国古代重要的交通命脉，对经济发展和国家统一产生了深远影响。", "chapter": 5, "grid_size": 10, "difficulty": "easy", "scene": "隋炀帝开凿大运河，运河上船只往来，劳工开凿河道，南北贯通"},
    {"id": "chapter5_53_zhaozhou", "title": "李春与赵州桥", "summary": "隋代建筑奇迹", "full_text": "李春设计建造的赵州桥是世界上现存最古老的石拱桥。这座桥梁设计巧妙，结构坚固，历经千年依然屹立。赵州桥展现了中国古代桥梁建筑的高超水平。", "chapter": 5, "grid_size": 10, "difficulty": "easy", "scene": "李春与赵州桥，赵州桥横跨河流，石拱桥结构精巧，行人过桥"},
    {"id": "chapter5_54_taizong", "title": "唐太宗李世民", "summary": "唐太宗与群臣议事", "full_text": "唐太宗李世民开创了贞观之治的盛世。他知人善任，虚心纳谏，轻徭薄赋，使唐朝成为当时世界上最强大的国家。唐太宗的治国理念成为后世帝王的典范。", "chapter": 5, "grid_size": 10, "difficulty": "easy", "scene": "唐太宗李世民，唐太宗与群臣议事，魏征进谏，贞观之治"},
    {"id": "chapter5_55_zhenguan", "title": "贞观之治", "summary": "唐朝盛世", "full_text": "贞观之治是中国历史上少有的盛世。政治清明、经济繁荣、文化昌盛，四方来朝。这个时期的唐朝展现出强大的国力和开放的胸襟，成为中国历史上的黄金时代。", "chapter": 5, "grid_size": 10, "difficulty": "easy", "scene": "贞观之治，唐朝盛世繁华，长安城街道热闹，万国来朝"},
    {"id": "chapter5_56_wuzetian", "title": "武则天称帝", "summary": "武则天登基为帝", "full_text": "武则天是中国历史上唯一的女皇帝。她在位期间，政治稳定，经济发展，文化繁荣。武则天的统治展现了女性的智慧和魄力，打破了男权社会的传统观念。", "chapter": 5, "grid_size": 10, "difficulty": "easy", "scene": "武则天称帝，武则天登基为帝，女皇威严，朝堂之上"},
    {"id": "chapter5_57_xuanzang", "title": "玄奘取经", "summary": "玄奘西行印度取经", "full_text": "玄奘西行取经，历经艰险到达印度。他带回了大量佛经，并翻译了其中的一部分。玄奘的壮举促进了中印文化交流，他的故事被改编成《西游记》流传后世。", "chapter": 5, "grid_size": 10, "difficulty": "easy", "scene": "玄奘取经，玄奘西行穿越沙漠，翻越雪山，到达印度"},
    {"id": "chapter5_58_wencheng", "title": "文成公主入藏", "summary": "唐蕃和亲", "full_text": "文成公主入藏，促进了汉藏两族的友好交往。她带去了先进的文化和技术，帮助吐蕃发展经济和文化。文成公主成为民族团结的象征，深受藏族人民爱戴。", "chapter": 5, "grid_size": 10, "difficulty": "easy", "scene": "文成公主入藏，文成公主骑马前往吐蕃，携带经书和工匠，汉藏和亲"},
    {"id": "chapter5_59_jianzhen", "title": "鉴真东渡", "summary": "鉴真和尚赴日传法", "full_text": "鉴真六次东渡日本，终于成功将中国文化传到日本。他在日本建立了唐招提寺，传播佛教和中国文化。鉴真的执着和奉献精神令人敬佩。", "chapter": 5, "grid_size": 10, "difficulty": "easy", "scene": "鉴真东渡，鉴真和尚乘船赴日，海上风浪，日本唐招提寺"},
    {"id": "chapter5_60_libai", "title": "李白醉酒作诗", "summary": "李白在月光下饮酒作诗", "full_text": "李白是中国文学史上最伟大的诗人之一。他的诗歌豪放飘逸，充满浪漫主义色彩。李白被誉为'诗仙'，他的诗篇千古传诵，成为中国文学的瑰宝。", "chapter": 5, "grid_size": 10, "difficulty": "easy", "scene": "李白醉酒作诗，李白在月光下举杯饮酒，诗兴大发，月下独酌"},
    {"id": "chapter5_61_dufu", "title": "杜甫", "summary": "唐代诗圣", "full_text": "杜甫的诗歌深刻反映了社会现实，被誉为'诗史'。他的诗作沉郁顿挫，表达了对人民的深切同情和对国家命运的忧虑。杜甫被尊为'诗圣'，他的诗歌具有永恒的艺术价值。", "chapter": 5, "grid_size": 10, "difficulty": "easy", "scene": "杜甫诗圣，杜甫在草堂中写诗，忧国忧民，秋风茅屋"},
    {"id": "chapter5_62_yanzhenqing", "title": "颜真卿书法", "summary": "唐代书法家", "full_text": "颜真卿的书法雄浑有力，开创了'颜体'楷书。他的书法端庄大气，具有很高的艺术成就。颜真卿不仅是书法大家，更是一位忠臣义士。", "chapter": 5, "grid_size": 10, "difficulty": "easy", "scene": "颜真卿书法，颜真卿挥毫书写大字，楷书雄浑有力"},
    {"id": "chapter5_63_wudaozi", "title": "吴道子绘画", "summary": "画圣", "full_text": "吴道子是唐代著名画家，被誉为'画圣'。他的画作线条流畅，人物生动传神。吴道子的绘画风格对后世产生了深远影响。", "chapter": 5, "grid_size": 10, "difficulty": "easy", "scene": "吴道子绘画，画圣吴道子在墙壁上作画，线条流畅，天王送子图"},
    {"id": "chapter5_64_anshi", "title": "安史之乱", "summary": "唐朝由盛转衰", "full_text": "安史之乱是唐朝由盛转衰的转折点。这场叛乱持续八年，给社会带来了巨大破坏。虽然最终被平定，但唐朝的盛世一去不复返。", "chapter": 5, "grid_size": 10, "difficulty": "easy", "scene": "安史之乱，唐朝叛乱战火纷飞，长安城破，百姓逃难"},
    {"id": "chapter5_65_dunhuang", "title": "敦煌莫高窟", "summary": "唐代佛教艺术", "full_text": "敦煌莫高窟是世界上现存规模最大、内容最丰富的佛教艺术圣地。这些精美的壁画和雕塑展现了中国古代艺术的辉煌成就，是人类文化的珍贵遗产。", "chapter": 5, "grid_size": 10, "difficulty": "easy", "scene": "敦煌莫高窟，飞天壁画，佛教艺术，石窟中的精美彩绘"},
    {"id": "chapter6_66_zhaokuangyin", "title": "赵匡胤陈桥兵变", "summary": "赵匡胤黄袍加身", "full_text": "赵匡胤发动陈桥兵变，建立了宋朝。他杯酒释兵权，加强了中央集权。赵匡胤建立的宋朝在文化、科技等方面取得了辉煌成就。", "chapter": 6, "grid_size": 15, "difficulty": "medium", "scene": "赵匡胤陈桥兵变，赵匡胤黄袍加身，将士拥戴，兵变场景"},
    {"id": "chapter6_67_beijiu", "title": "杯酒释兵权", "summary": "宋太祖集权", "full_text": "宋太祖杯酒释兵权，巧妙地解除了功臣的兵权。这一举措既巩固了中央集权，又避免了血腥屠杀，展现了宋太祖的政治智慧。", "chapter": 6, "grid_size": 15, "difficulty": "medium", "scene": "杯酒释兵权，宋太祖设宴，将领们交出兵权，酒宴场景"},
    {"id": "chapter6_68_sushi", "title": "苏轼游赤壁", "summary": "苏轼泛舟赤壁", "full_text": "苏轼是宋代文学艺术的全才。他的诗词豪放洒脱，书法绘画也堪称一绝。苏轼的人生经历跌宕起伏，但他始终保持豁达乐观的心态。", "chapter": 6, "grid_size": 15, "difficulty": "medium", "scene": "苏轼游赤壁，苏轼泛舟赤壁之下，月夜江上，赋诗饮酒"},
    {"id": "chapter6_69_wanganshi", "title": "王安石变法", "summary": "北宋改革", "full_text": "王安石推行变法，试图解决北宋的社会问题。他的新法涉及政治、经济、军事等多个方面，虽然最终失败，但其中的改革精神值得肯定。", "chapter": 6, "grid_size": 15, "difficulty": "medium", "scene": "王安石变法，王安石在朝堂上推行新法，变法诏书"},
    {"id": "chapter6_70_yuefei", "title": "岳飞抗金", "summary": "岳飞率领岳家军抗金", "full_text": "岳飞是南宋著名抗金英雄。他率领岳家军英勇抗击金兵，收复失地。岳飞精忠报国的精神成为中华民族的宝贵财富，他的故事千古传颂。", "chapter": 6, "grid_size": 15, "difficulty": "medium", "scene": "岳飞抗金，岳飞率领岳家军英勇作战，精忠报国，战旗飘扬"},
    {"id": "chapter6_71_xinqiji", "title": "辛弃疾", "summary": "南宋词人", "full_text": "辛弃疾是南宋著名词人。他的词作慷慨激昂，充满爱国情怀。辛弃疾不仅是文学大家，更是一位渴望收复失地的爱国将领。", "chapter": 6, "grid_size": 15, "difficulty": "medium", "scene": "辛弃疾，南宋词人辛弃疾，壮志未酬，挑灯看剑"},
    {"id": "chapter6_72_liqingzhao", "title": "李清照", "summary": "宋代女词人", "full_text": "李清照是宋代著名女词人。她的词作婉约细腻，情感真挚。李清照的才华和勇气令人敬佩，她被誉为'千古第一才女'。", "chapter": 6, "grid_size": 15, "difficulty": "medium", "scene": "李清照，宋代女词人李清照，婉约细腻，诗词书卷"},
    {"id": "chapter6_73_xixia", "title": "西夏王陵", "summary": "西夏王朝的皇家陵园", "full_text": "西夏王陵是西夏王朝的皇家陵园。这些独特的建筑见证了西夏文明的辉煌。西夏王陵的发现为研究西夏历史和文化提供了重要线索。", "chapter": 6, "grid_size": 15, "difficulty": "medium", "scene": "西夏王陵，独特的陵墓建筑，西夏文字，皇家陵园"},
    {"id": "chapter6_74_liaobihua", "title": "辽代壁画", "summary": "契丹民族的艺术成就", "full_text": "辽代壁画展现了契丹民族的生活风貌和艺术成就。这些壁画内容丰富，色彩鲜艳，具有很高的历史和艺术价值。", "chapter": 6, "grid_size": 15, "difficulty": "medium", "scene": "辽代壁画，契丹民族骑射生活，色彩鲜艳的壁画，草原风光"},
    {"id": "chapter6_75_jinducheng", "title": "金朝都城", "summary": "金中都遗址", "full_text": "金朝都城展现了女真民族的建筑成就。这座都城规划严谨，建筑宏伟，反映了金朝的强盛和文化特色。", "chapter": 6, "grid_size": 15, "difficulty": "medium", "scene": "金朝都城，金中都遗址，宏伟的都城建筑，女真民族特色"},
    {"id": "chapter6_76_bisheng", "title": "毕昇与活字印刷", "summary": "宋代科技发明", "full_text": "毕昇发明了活字印刷术，这是印刷史上的重大革命。活字印刷术的发明大大提高了印刷效率，对文化传播产生了深远影响。", "chapter": 6, "grid_size": 15, "difficulty": "medium", "scene": "毕昇与活字印刷，毕昇制作泥活字，印刷工序，宋代科技发明"},
    {"id": "chapter6_77_qingmingtu", "title": "张择端清明上河图", "summary": "宋代风俗画", "full_text": "张择端的《清明上河图》描绘了北宋都城汴京的繁华景象。这幅画卷展现了当时的社会生活和城市风貌，是中国绘画史上的不朽之作。", "chapter": 6, "grid_size": 15, "difficulty": "medium", "scene": "清明上河图，北宋汴京繁华街市，虹桥上人来人往，商贩叫卖"},
    {"id": "chapter7_78_genghis", "title": "成吉思汗西征", "summary": "蒙古骑兵西征", "full_text": "成吉思汗统一蒙古各部，建立了庞大的蒙古帝国。他率领蒙古铁骑横扫欧亚大陆，展现了卓越的军事才能和领导能力。成吉思汗成为世界历史上杰出的军事家。", "chapter": 7, "grid_size": 15, "difficulty": "medium", "scene": "成吉思汗西征，蒙古骑兵横扫欧亚，铁骑冲锋，草原帝国"},
    {"id": "chapter7_79_hubilie", "title": "忽必烈建元", "summary": "忽必烈建立元朝", "full_text": "忽必烈建立元朝，统一了中国。他推行一系列改革，促进了民族融合和经济发展。忽必烈的统治使元朝成为一个疆域辽阔的强大帝国。", "chapter": 7, "grid_size": 15, "difficulty": "medium", "scene": "忽必烈建元，忽必烈建立元朝，大都宫殿，统一中国"},
    {"id": "chapter7_80_marco", "title": "马可波罗来华", "summary": "马可波罗拜见元世祖", "full_text": "马可·波罗来到中国，在元朝宫廷任职多年。他的游记向欧洲人展示了东方的繁华和神秘，激发了欧洲人对东方的向往。", "chapter": 7, "grid_size": 15, "difficulty": "medium", "scene": "马可波罗来华，马可波罗拜见元世祖，东西方交流，元朝宫廷"},
    {"id": "chapter7_81_yuandadu", "title": "元大都", "summary": "元代都城", "full_text": "元大都的规划和建设展现了元朝的强盛。这座都城规模宏大，布局严谨，成为当时世界上最繁华的城市之一。元大都的遗址为研究元代历史提供了重要资料。", "chapter": 7, "grid_size": 15, "difficulty": "medium", "scene": "元大都，元代都城宏伟建筑，城市规划严谨，繁华市井"},
    {"id": "chapter7_82_guanhanqing", "title": "关汉卿创作杂剧", "summary": "元曲大家", "full_text": "关汉卿是元代著名杂剧作家。他创作的《窦娥冤》等作品深刻反映了社会现实，具有很高的艺术成就。关汉卿被誉为'曲圣'，他的作品至今仍在舞台上上演。", "chapter": 7, "grid_size": 15, "difficulty": "medium", "scene": "关汉卿创作杂剧，元曲大家关汉卿编写剧本，舞台演出窦娥冤"},
    {"id": "chapter7_83_guoshoujing", "title": "郭守敬与授时历", "summary": "元代天文学家", "full_text": "郭守敬是元代杰出的天文学家和数学家。他编制的《授时历》精度极高，一年为365.2425天，与现行公历几乎相同但早了三百年。郭守敬还制造了简仪等精密天文仪器，对中国天文学发展做出了重大贡献。", "chapter": 7, "grid_size": 15, "difficulty": "medium", "scene": "郭守敬与授时历，元代天文学家郭守敬观测星空，天文仪器，编制历法"},
    {"id": "chapter7_84_zhaomengfu", "title": "赵孟頫书法", "summary": "元代书画家", "full_text": "赵孟頫是元代最杰出的书画家。他的书法各体皆精，绘画开创了元代文人画的新风。赵孟頫主张'书画同源'，他的艺术理论和实践对后世产生了深远影响。", "chapter": 7, "grid_size": 15, "difficulty": "medium", "scene": "赵孟頫书法，元代书画家赵孟頫挥毫作画，文人画风格"},
    {"id": "chapter7_85_wentianxiang", "title": "文天祥抗元", "summary": "南宋忠臣", "full_text": "文天祥是南宋末年著名的抗元英雄。他兵败被俘后坚贞不屈，写下了'人生自古谁无死，留取丹心照汗青'的千古名句。文天祥的忠义精神成为中华民族气节的象征。", "chapter": 7, "grid_size": 15, "difficulty": "medium", "scene": "文天祥抗元，南宋忠臣文天祥狱中写正气歌，坚贞不屈"},
    {"id": "chapter8_86_zhuyuanzhang", "title": "朱元璋建立明朝", "summary": "朱元璋登基", "full_text": "朱元璋从一个贫苦农民成长为开国皇帝，建立了大明王朝。他废除丞相制度，加强皇权，推行一系列改革措施。朱元璋的传奇人生展现了草根逆袭的壮丽史诗。", "chapter": 8, "grid_size": 15, "difficulty": "medium", "scene": "朱元璋身披龙袍登基称帝，金銮殿上文武百官朝贺"},
    {"id": "chapter8_87_zhenghe", "title": "郑和下西洋", "summary": "郑和船队航行海上", "full_text": "郑和率领庞大的船队七次下西洋，到达了东南亚、南亚、西亚和东非等地区。这些远航比哥伦布发现新大陆早了近一个世纪，展现了明朝强大的航海实力和开放的外交姿态。", "chapter": 8, "grid_size": 15, "difficulty": "medium", "scene": "郑和站在宝船船头远眺，身后浩荡船队航行在大海上"},
    {"id": "chapter8_88_zijincheng", "title": "紫禁城", "summary": "北京故宫全景", "full_text": "紫禁城是明清两代的皇宫，是世界上现存规模最大、保存最完整的古代宫殿建筑群。这座宏伟的宫殿凝聚着无数工匠的智慧和心血，是中国古代建筑的巅峰之作。", "chapter": 8, "grid_size": 15, "difficulty": "medium", "scene": "紫禁城全景，红墙黄瓦宫殿层层叠叠，宫门石狮威严"},
    {"id": "chapter8_89_mingchangcheng", "title": "明长城", "summary": "明代长城", "full_text": "明长城是中国历史上修筑规模最大、保存最完好的长城。它东起鸭绿江畔，西至嘉峪关，绵延万里。明长城是中华民族智慧和力量的结晶，也是世界建筑史上的奇迹。", "chapter": 8, "grid_size": 15, "difficulty": "medium", "scene": "明长城蜿蜒盘旋于崇山峻岭之间，烽火台矗立山巅"},
    {"id": "chapter8_90_lishizhen", "title": "李时珍与本草纲目", "summary": "明代医药学家", "full_text": "李时珍历时二十七年编写了《本草纲目》，这部医药学巨著记载了一千八百多种药物和一万多个药方。《本草纲目》被翻译成多种文字，对世界医药学发展产生了深远影响。", "chapter": 8, "grid_size": 15, "difficulty": "medium", "scene": "李时珍背着药篓在深山采药，身边草药繁茂"},
    {"id": "chapter8_91_xuxiake", "title": "徐霞客游记", "summary": "明代地理学家", "full_text": "徐霞客用三十余年的时间走遍大半个中国，写下了著名的《徐霞客游记》。这部游记详细记录了各地的地理、地貌和风土人情，是中国地理学的珍贵文献。", "chapter": 8, "grid_size": 15, "difficulty": "medium", "scene": "徐霞客手持竹杖攀登山崖，奇峰异石林立"},
    {"id": "chapter8_92_lizicheng", "title": "李自成起义", "summary": "明末农民起义", "full_text": "李自成领导农民起义军攻入北京，推翻了明朝统治。虽然大顺政权很快被清军击败，但这场农民起义深刻反映了明末社会矛盾的尖锐，成为中国历史上的重要事件。", "chapter": 8, "grid_size": 15, "difficulty": "medium", "scene": "李自成骑马率军入城，义军旗帜飘扬"},
    {"id": "chapter8_93_wusangui", "title": "吴三桂引清兵入关", "summary": "明朝灭亡", "full_text": "吴三桂打开山海关引清兵入关，改变了中国的历史走向。清军入关后迅速统一全国，建立了中国最后一个封建王朝。这一事件标志着明朝的彻底灭亡和清朝统治的开始。", "chapter": 8, "grid_size": 15, "difficulty": "medium", "scene": "山海关城门大开，清军骑兵列队入关，战旗飘扬"},
    {"id": "chapter9_94_kangxi", "title": "康熙皇帝", "summary": "康熙亲政", "full_text": "康熙帝是中国历史上在位时间最长的皇帝。他平定三藩之乱，收复台湾，抵御沙俄入侵，开创了康乾盛世的局面。康熙帝的文治武功使清朝走向鼎盛。", "chapter": 9, "grid_size": 20, "difficulty": "hard", "scene": "康熙帝端坐龙椅批阅奏折，殿内文臣武将分列两侧"},
    {"id": "chapter9_95_yongzheng", "title": "雍正皇帝", "summary": "清代帝王", "full_text": "雍正帝在位期间推行了一系列重要改革。他实行摊丁入亩，整顿吏治，设立军机处加强皇权。雍正帝的改革为乾隆盛世的到来奠定了坚实基础。", "chapter": 9, "grid_size": 20, "difficulty": "hard", "scene": "雍正帝在养心殿烛光下批阅奏章，案上堆满文书"},
    {"id": "chapter9_96_qianlong", "title": "乾隆下江南", "summary": "乾隆南巡", "full_text": "乾隆帝六次南巡江南，沿途考察民情，巡视河工。康乾盛世在乾隆时期达到顶峰，但繁荣的背后也隐藏着衰落的种子。乾隆南巡既是盛世的象征，也加速了国力的消耗。", "chapter": 9, "grid_size": 20, "difficulty": "hard", "scene": "乾隆帝乘龙舟沿大运河南巡，两岸垂柳桃花盛开"},
    {"id": "chapter9_97_siku", "title": "四库全书", "summary": "清代大型丛书", "full_text": "《四库全书》是清代乾隆年间编纂的中国历史上规模最大的丛书。全书收录三千四百多种图书，近八亿字。这部浩瀚的文献宝库保存了大量珍贵的古代典籍，是中华文化的集大成之作。", "chapter": 9, "grid_size": 20, "difficulty": "hard", "scene": "四库全书编纂场景，学者们在藏书阁中抄校典籍，书架林立"},
    {"id": "chapter9_98_caoxueqin", "title": "曹雪芹与红楼梦", "summary": "清代文学名著", "full_text": "曹雪芹倾尽毕生心血创作了《红楼梦》，这部小说以贾宝玉和林黛玉的爱情悲剧为主线，深刻揭示了封建社会的衰败。《红楼梦》被誉为中国古典小说的巅峰之作，是世界文学的瑰宝。", "chapter": 9, "grid_size": 20, "difficulty": "hard", "scene": "曹雪芹在茅屋中伏案创作红楼梦，窗外大观园亭台楼阁"},
    {"id": "chapter10_99_yapian", "title": "鸦片战争", "summary": "虎门销烟", "full_text": "林则徐在虎门销烟，展现了中华民族反抗外来侵略的决心。鸦片战争的爆发打开了中国的大门，签订的《南京条约》使中国开始沦为半殖民地半封建社会。这是中国近代史的开端。", "chapter": 10, "grid_size": 20, "difficulty": "hard", "scene": "林则徐指挥虎门销烟，浓烟滚滚，民众围观称快"},
    {"id": "chapter10_100_taiping", "title": "太平天国运动", "summary": "洪秀全起义", "full_text": "洪秀全领导太平天国运动，建立了与清政府对峙的政权。这场持续十四年的农民战争虽然最终失败，但它沉重打击了清朝统治，推动了中国近代化的进程。", "chapter": 10, "grid_size": 20, "difficulty": "hard", "scene": "太平军将士列阵行进，旗帜飘扬号角齐鸣"},
    {"id": "chapter10_101_yangwu", "title": "洋务运动", "summary": "近代化开端", "full_text": "洋务运动是中国近代化的开端。以李鸿章、曾国藩为代表的洋务派创办近代工业、建立新式军队、兴办新式学堂。虽然洋务运动未能改变中国落后的根本面貌，但它开启了中国近代化的进程。", "chapter": 10, "grid_size": 20, "difficulty": "hard", "scene": "洋务运动场景，江南制造总局厂房烟囱林立，蒸汽机运转"},
    {"id": "chapter10_102_xinhai", "title": "辛亥革命", "summary": "武昌起义", "full_text": "辛亥革命推翻了清朝统治，结束了中国两千多年的封建帝制。孙中山领导的革命党人在武昌起义，建立了中华民国。辛亥革命是中国近代史上具有划时代意义的伟大革命。", "chapter": 10, "grid_size": 20, "difficulty": "hard", "scene": "武昌起义场景，革命军攻占总督署，五色旗飘扬城头"},
    {"id": "chapter11_103_wusi", "title": "五四运动", "summary": "新文化运动", "full_text": "五四运动是一场伟大的爱国民主运动。青年学生走上街头，高呼'外争国权，内惩国贼'的口号。五四运动促进了马克思主义在中国的传播，标志着中国新民主主义革命的开端。", "chapter": 11, "grid_size": 20, "difficulty": "hard", "scene": "青年学生集会演讲，手持横幅标语，群情激昂"},
    {"id": "chapter11_104_kangri", "title": "抗日战争", "summary": "全民抗战", "full_text": "抗日战争是中华民族为抵抗日本侵略而进行的伟大民族解放战争。经过十四年艰苦卓绝的斗争，中国人民终于取得了抗战的胜利。这是近代以来中国反抗外敌入侵第一次取得完全胜利的民族解放战争。", "chapter": 11, "grid_size": 20, "difficulty": "hard", "scene": "抗日战士守卫长城关口，烽火台上旗帜飘扬"},
    {"id": "chapter11_105_xinzhongguo", "title": "新中国成立", "summary": "开国大典", "full_text": "1949年10月1日，毛泽东在天安门城楼上庄严宣告中华人民共和国成立。中国人民从此站起来了，开辟了中国历史的新纪元。开国大典是中华民族历史上最伟大的时刻之一。", "chapter": 11, "grid_size": 20, "difficulty": "hard", "scene": "开国大典场景，天安门城楼上领导人挥手致意，广场红旗飘扬"},
]


class APIAccountPool:
    def __init__(self, accounts_file):
        self.accounts_file = Path(accounts_file)
        self.accounts = []
        self.current_index = 0
        self.usage = {}
        self._load_accounts()
        self._load_usage()

    def _load_accounts(self):
        if self.accounts_file.exists():
            with open(self.accounts_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            self.accounts = data.get("accounts", [])
            self.settings = data.get("settings", {})
        else:
            self.accounts = []
            self.settings = {}

    def _load_usage(self):
        if USAGE_FILE.exists():
            with open(USAGE_FILE, 'r', encoding='utf-8') as f:
                self.usage = json.load(f)
        else:
            self.usage = {}

    def _save_usage(self):
        with open(USAGE_FILE, 'w', encoding='utf-8') as f:
            json.dump(self.usage, f, ensure_ascii=False, indent=2)

    def _get_today_key(self):
        return datetime.now().strftime("%Y-%m-%d")

    def _get_account_usage_today(self, account_name):
        today = self._get_today_key()
        return self.usage.get(today, {}).get(account_name, 0)

    def _increment_usage(self, account_name):
        today = self._get_today_key()
        if today not in self.usage:
            self.usage[today] = {}
        self.usage[today][account_name] = self.usage[today].get(account_name, 0) + 1
        self._save_usage()

    def get_active_account(self):
        for i, account in enumerate(self.accounts):
            if account.get("status") != "active":
                continue
            daily_limit = account.get("daily_limit", 50)
            used = self._get_account_usage_today(account["name"])
            if used < daily_limit:
                self.current_index = i
                return account
        return None

    def switch_to_next_account(self):
        for i in range(len(self.accounts)):
            idx = (self.current_index + 1 + i) % len(self.accounts)
            account = self.accounts[idx]
            if account.get("status") != "active":
                continue
            daily_limit = account.get("daily_limit", 50)
            used = self._get_account_usage_today(account["name"])
            if used < daily_limit:
                self.current_index = idx
                print(f"  切换到账户: {account['name']} (今日已用: {used}/{daily_limit})")
                return account
        print("  所有账户均已达到每日限额！")
        return None

    def mark_account_limited(self, account_name):
        today = self._get_today_key()
        if today not in self.usage:
            self.usage[today] = {}
        for account in self.accounts:
            if account["name"] == account_name:
                self.usage[today][account_name] = account.get("daily_limit", 50)
                break
        self._save_usage()

    def report_usage(self):
        today = self._get_today_key()
        print(f"\n=== API使用报告 ({today}) ===")
        for account in self.accounts:
            used = self._get_account_usage_today(account["name"])
            limit = account.get("daily_limit", 50)
            status = account.get("status", "active")
            print(f"  {account['name']}: {used}/{limit} ({status})")
        total_used = sum(self._get_account_usage_today(a["name"]) for a in self.accounts)
        total_limit = sum(a.get("daily_limit", 50) for a in self.accounts if a.get("status") == "active")
        print(f"  总计: {total_used}/{total_limit}")


def build_prompt(scene):
    return f"{STYLE_PREFIX}{scene}，{SHELF_COLOR_KEYWORDS}{STYLE_SUFFIX}"


def get_size_for_grid(x_cells, y_cells):
    from math import gcd
    g = gcd(x_cells, y_cells)
    ratio_w = x_cells // g
    ratio_h = y_cells // g
    ratio_key = f"{ratio_w}:{ratio_h}"
    if ratio_key in ASPECT_RATIO_SIZES:
        return ASPECT_RATIO_SIZES[ratio_key]
    return "2K"


def generate_jimeng_image(pool, prompt, size="2K"):
    settings = pool.settings
    max_retries = settings.get("max_retries_per_account", 3)
    retry_wait = settings.get("retry_wait_seconds", 60)

    for attempt in range(max_retries):
        account = pool.get_active_account()
        if not account:
            account = pool.switch_to_next_account()
        if not account:
            return None

        provider = account.get("provider", "volcengine")
        api_url = account.get("api_url", API_BASE_URL)
        headers = {
            "Authorization": f"Bearer {account['api_key']}",
            "Content-Type": "application/json"
        }

        if provider == "siliconflow":
            model_name = account.get("model", "Kwai-Kolors/Kolors")
            ratio_key = "3:2"
            for k, v in ASPECT_RATIO_SIZES.items():
                if v == size:
                    ratio_key = k
                    break
            if "Qwen" in model_name:
                sf_size = QWEN_IMAGE_SIZE_MAP.get(ratio_key, "1584x1056")
            else:
                sf_size = SILICONFLOW_SIZE_MAP.get(ratio_key, "1024x1024")
            payload = {
                "model": model_name,
                "prompt": prompt,
                "image_size": sf_size,
                "batch_size": 1,
            }
            if "Kolors" in model_name:
                payload["negative_prompt"] = NEGATIVE_PROMPT
                payload["guidance_scale"] = 10
                payload["num_inference_steps"] = 25
            elif "Qwen" in model_name:
                payload["num_inference_steps"] = 50
                payload["cfg"] = 4.0
        else:
            payload = {
                "model": account.get("model", "doubao-seedream-4-5-251128"),
                "prompt": prompt,
                "sequential_image_generation": "disabled",
                "response_format": "url",
                "size": size,
                "stream": False,
                "watermark": False
            }

        try:
            print(f"  [使用账户: {account['name']} ({provider})]")
            response = requests.post(api_url, headers=headers, json=payload, timeout=120)
            response.raise_for_status()
            result = response.json()

            if provider == "siliconflow":
                if result.get("images") and isinstance(result["images"], list) and len(result["images"]) > 0:
                    img_url = result["images"][0].get("url")
                    if img_url:
                        pool._increment_usage(account["name"])
                        return img_url
            else:
                if result.get("data") and isinstance(result["data"], list) and len(result["data"]) > 0:
                    if result["data"][0].get("url"):
                        pool._increment_usage(account["name"])
                        return result["data"][0]["url"]
            return None
        except requests.exceptions.HTTPError as e:
            if e.response is not None and e.response.status_code == 403:
                print(f"  账户 {account['name']} 被限流(403)")
                pool.mark_account_limited(account["name"])
                if settings.get("auto_switch_on_limit", True):
                    next_account = pool.switch_to_next_account()
                    if next_account:
                        wait = retry_wait
                        print(f"  等待{wait}秒后使用新账户重试...")
                        time.sleep(wait)
                        continue
                else:
                    wait = retry_wait * (attempt + 1)
                    print(f"  等待{wait}秒后重试({attempt+1}/{max_retries})...")
                    time.sleep(wait)
            elif e.response is not None and e.response.status_code == 402:
                print(f"  账户 {account['name']} 余额不足(402)")
                pool.mark_account_limited(account["name"])
                if settings.get("auto_switch_on_limit", True):
                    next_account = pool.switch_to_next_account()
                    if next_account:
                        print(f"  切换到新账户重试...")
                        continue
                return None
            elif e.response is not None and e.response.status_code == 429:
                wait = 60
                print(f"  请求频率超限(429)，等待{wait}秒后重试({attempt+1}/{max_retries})...")
                time.sleep(wait)
                continue
            elif e.response is not None and e.response.status_code == 451:
                print(f"  内容审核未通过(451)，跳过此图片")
                return "CONTENT_BLOCKED"
            else:
                print(f"API请求异常: {str(e)}")
                if e.response is not None:
                    print(f"  响应内容: {e.response.text[:200]}")
                return None
        except Exception as e:
            print(f"API请求异常: {str(e)}")
            if attempt < max_retries - 1:
                time.sleep(10)
            else:
                return None
    return None


def download_image(url, save_path, target_size=None):
    try:
        response = requests.get(url, timeout=60)
        response.raise_for_status()
        img = Image.open(BytesIO(response.content))
        if target_size:
            img = img.resize(target_size, Image.LANCZOS)
        img.save(save_path)
        print(f"图片已保存: {save_path} ({img.size[0]}x{img.size[1]})")
        return True
    except Exception as e:
        print(f"下载图片失败: {str(e)}")
        return False


def generate_images(start_from=0):
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)
    pool = APIAccountPool(ACCOUNTS_FILE)
    api_size = get_size_for_grid(3, 2)
    request_delay = pool.settings.get("request_delay_seconds", 5)

    for i, pic in enumerate(PICTURES):
        if i < start_from:
            continue
        pic_id = pic["id"]
        save_path = IMAGES_DIR / f"{pic_id}.jpg"
        if save_path.exists():
            print(f"[{i+1}/105] 已存在，跳过: {pic_id}")
            continue

        prompt = build_prompt(pic["scene"])
        print(f"\n[{i+1}/105] 正在生成: {pic['title']} ({pic_id})")
        print(f"  提示词: {prompt[:80]}...")

        image_url = generate_jimeng_image(pool, prompt, size=api_size)
        if image_url and image_url != "CONTENT_BLOCKED":
            account = pool.get_active_account()
            provider = account.get("provider", "volcengine") if account else "volcengine"
            target_size = (2496, 1664) if provider == "siliconflow" else None
            download_image(image_url, str(save_path), target_size=target_size)
            time.sleep(request_delay)
        elif image_url == "CONTENT_BLOCKED":
            safe_scene = pic["scene"].replace("战争", "故事").replace("起义", "事件").replace("革命", "变革").replace("焚烧", "处理").replace("作战", "行动").replace("抗战", "卫国").replace("游行", "集会")
            safe_prompt = build_prompt(safe_scene)
            print(f"  尝试安全提示词: {safe_prompt[:80]}...")
            image_url2 = generate_jimeng_image(pool, safe_prompt, size=api_size)
            if image_url2 and image_url2 != "CONTENT_BLOCKED":
                account = pool.get_active_account()
                provider = account.get("provider", "volcengine") if account else "volcengine"
                target_size = (2496, 1664) if provider == "siliconflow" else None
                download_image(image_url2, str(save_path), target_size=target_size)
                time.sleep(request_delay)
            else:
                print(f"  安全提示词也未通过，跳过: {pic_id}")
                time.sleep(request_delay)
        else:
            print(f"  生成失败: {pic_id}")
            time.sleep(request_delay * 2)

    pool.report_usage()
    print("\n图片生成完成！")


def generate_row_clues(row):
    clues = []
    count = 0
    for cell in row:
        if cell == 1:
            count += 1
        else:
            if count > 0:
                clues.append(count)
            count = 0
    if count > 0:
        clues.append(count)
    if not clues:
        clues = [0]
    return clues


def generate_puzzle_pattern(grid_size, seed):
    rng = random.Random(seed)
    density = rng.uniform(0.3, 0.6)
    grid = []
    for i in range(grid_size):
        row = []
        for j in range(grid_size):
            if rng.random() < density:
                row.append(1)
            else:
                row.append(0)
        grid.append(row)
    for i in range(grid_size):
        if all(cell == 0 for cell in grid[i]):
            j = rng.randint(0, grid_size - 1)
            grid[i][j] = 1
        if all(cell == 1 for cell in grid[i]):
            j = rng.randint(0, grid_size - 1)
            grid[i][j] = 0
    for j in range(grid_size):
        col = [grid[i][j] for i in range(grid_size)]
        if all(cell == 0 for cell in col):
            i = rng.randint(0, grid_size - 1)
            grid[i][j] = 1
        if all(cell == 1 for cell in col):
            i = rng.randint(0, grid_size - 1)
            grid[i][j] = 0
    return grid


UNKNOWN = 0
FILLED = 1
EMPTY = 2


def line_solve(clues, current_states, line_length):
    if not clues or (len(clues) == 1 and clues[0] == 0):
        return [EMPTY] * line_length
    arrangements = generate_arrangements(clues, current_states, line_length)
    if not arrangements:
        return list(current_states)
    result = [UNKNOWN] * line_length
    for i in range(line_length):
        if current_states[i] != UNKNOWN:
            result[i] = current_states[i]
            continue
        all_filled = True
        all_empty = True
        for arr in arrangements:
            if arr[i] == FILLED:
                all_empty = False
            else:
                all_filled = False
        if all_filled:
            result[i] = FILLED
        elif all_empty:
            result[i] = EMPTY
    return result


def generate_arrangements(clues, current_states, line_length):
    results = []
    place_blocks(clues, 0, 0, current_states, line_length, [], results)
    return results


def place_blocks(clues, clue_idx, start_pos, current_states, line_length, partial, results):
    if clue_idx >= len(clues):
        arrangement = [EMPTY] * line_length
        for pos in partial:
            for i in pos:
                arrangement[i] = FILLED
        for i in range(line_length):
            if current_states[i] == FILLED and arrangement[i] != FILLED:
                return
            if current_states[i] == EMPTY and arrangement[i] != EMPTY:
                return
        results.append(arrangement)
        return
    block_size = clues[clue_idx]
    min_remaining = sum(clues[k] + 1 for k in range(clue_idx + 1, len(clues)))
    max_start = line_length - block_size - min_remaining
    for pos in range(start_pos, max_start + 1):
        can_place = True
        for i in range(start_pos, pos):
            if current_states[i] == FILLED:
                can_place = False
                break
        if not can_place:
            break
        block_valid = True
        for i in range(pos, pos + block_size):
            if current_states[i] == EMPTY:
                block_valid = False
                break
        if not block_valid:
            continue
        if pos + block_size < line_length and current_states[pos + block_size] == FILLED:
            if block_size == clues[clue_idx]:
                continue
        new_partial = list(partial)
        block_positions = list(range(pos, pos + block_size))
        new_partial.append(block_positions)
        next_start = pos + block_size + 1
        place_blocks(clues, clue_idx + 1, next_start, current_states, line_length, new_partial, results)


def solve(row_clues, col_clues):
    num_rows = len(row_clues)
    num_cols = len(col_clues)
    grid = [[UNKNOWN] * num_cols for _ in range(num_rows)]
    changed = True
    while changed:
        changed = False
        for r in range(num_rows):
            current = [grid[r][c] for c in range(num_cols)]
            new_states = line_solve(row_clues[r], current, num_cols)
            for c in range(num_cols):
                if new_states[c] != UNKNOWN and grid[r][c] == UNKNOWN:
                    grid[r][c] = new_states[c]
                    changed = True
        for c in range(num_cols):
            current = [grid[r][c] for r in range(num_rows)]
            new_states = line_solve(col_clues[c], current, num_rows)
            for r in range(num_rows):
                if new_states[r] != UNKNOWN and grid[r][c] == UNKNOWN:
                    grid[r][c] = new_states[r]
                    changed = True
    solvable = all(cell != UNKNOWN for row in grid for cell in row)
    return solvable, grid


def find_hint_cells(row_clues, col_clues, solution, max_hints=10):
    num_rows = len(row_clues)
    num_cols = len(col_clues)
    grid = [[UNKNOWN] * num_cols for _ in range(num_rows)]
    changed = True
    while changed:
        changed = False
        for r in range(num_rows):
            current = [grid[r][c] for c in range(num_cols)]
            new_states = line_solve(row_clues[r], current, num_cols)
            for c in range(num_cols):
                if new_states[c] != UNKNOWN and grid[r][c] == UNKNOWN:
                    grid[r][c] = new_states[c]
                    changed = True
        for c in range(num_cols):
            current = [grid[r][c] for r in range(num_rows)]
            new_states = line_solve(col_clues[c], current, num_rows)
            for r in range(num_rows):
                if new_states[r] != UNKNOWN and grid[r][c] == UNKNOWN:
                    grid[r][c] = new_states[r]
                    changed = True
    stuck_cells = []
    for r in range(num_rows):
        for c in range(num_cols):
            if grid[r][c] == UNKNOWN:
                row_unknowns = sum(1 for cc in range(num_cols) if grid[r][cc] == UNKNOWN)
                col_unknowns = sum(1 for rr in range(num_rows) if grid[rr][c] == UNKNOWN)
                stuck_cells.append((r, c, row_unknowns + col_unknowns))
    stuck_cells.sort(key=lambda x: x[2])
    hint_cells = []
    for r, c, _ in stuck_cells:
        if len(hint_cells) >= max_hints:
            break
        hint_cells.append([r, c])
        test_grid = [row[:] for row in grid]
        for hr, hc in hint_cells:
            test_grid[hr][hc] = FILLED if solution[hr][hc] == 1 else EMPTY
        test_changed = True
        while test_changed:
            test_changed = False
            for rr in range(num_rows):
                current = [test_grid[rr][cc] for cc in range(num_cols)]
                new_states = line_solve(row_clues[rr], current, num_cols)
                for cc in range(num_cols):
                    if new_states[cc] != UNKNOWN and test_grid[rr][cc] == UNKNOWN:
                        test_grid[rr][cc] = new_states[cc]
                        test_changed = True
            for cc in range(num_cols):
                current = [test_grid[rr][cc] for rr in range(num_rows)]
                new_states = line_solve(col_clues[cc], current, num_rows)
                for rr in range(num_rows):
                    if new_states[rr] != UNKNOWN and test_grid[rr][cc] == UNKNOWN:
                        test_grid[rr][cc] = new_states[rr]
                        test_changed = True
        all_determined = all(cell != UNKNOWN for row in test_grid for cell in row)
        if all_determined:
            return hint_cells
    return hint_cells


def generate_puzzle(pic_info, chunk_index):
    pic_id = pic_info["id"]
    grid_size = pic_info["grid_size"]
    difficulty = pic_info["difficulty"]
    puzzle_id = f"{pic_id}_{chunk_index}"

    if chunk_index == 0 and pic_id == "chapter1_01_yuanmou":
        name = f"{pic_info['title']} - 分块{chunk_index}（新手引导）"
    else:
        name = f"{pic_info['title']}-分块{chunk_index}"

    seed = hash(puzzle_id) & 0xFFFFFFFF
    matrix = generate_puzzle_pattern(grid_size, seed)
    row_clues = [generate_row_clues(row) for row in matrix]
    col_clues = []
    for j in range(grid_size):
        col = [matrix[i][j] for i in range(grid_size)]
        col_clues.append(generate_row_clues(col))

    solvable, _ = solve(row_clues, col_clues)
    hint_cells = []
    if not solvable:
        hint_cells = find_hint_cells(row_clues, col_clues, matrix, max_hints=min(grid_size, 10))

    source_rect = {
        "x": (chunk_index % 3) * (2496 // 3),
        "y": (chunk_index // 3) * (1664 // 2),
        "w": 2496 // 3,
        "h": 1664 // 2
    }

    return {
        "id": puzzle_id,
        "name": name,
        "picture_id": pic_id,
        "size": {"rows": grid_size, "cols": grid_size},
        "difficulty": difficulty,
        "row_clues": row_clues,
        "col_clues": col_clues,
        "solution": matrix,
        "hint_cells": hint_cells,
        "source_rect": source_rect
    }


def generate_pictures_json():
    pictures = []
    for i, pic in enumerate(PICTURES):
        pic_id = pic["id"]
        puzzles_list = [f"{pic_id}_{j}" for j in range(6)]
        pictures.append({
            "id": pic_id,
            "title": pic["title"],
            "summary": pic["summary"],
            "full_text": pic["full_text"],
            "image": f"res://assets/images/illustrations/chinese_history/{pic_id}.jpg",
            "image_grid": {"x": 3, "y": 2},
            "puzzles": puzzles_list,
            "order": i
        })
    data = {"album_id": "chinese_history", "pictures": pictures}
    output_path = PICTURES_DIR / "chinese_history.json"
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"已生成图片数据文件: {output_path}")
    print(f"共 {len(pictures)} 张图片")


def generate_all_puzzles(start_from=0):
    PUZZLES_DIR.mkdir(parents=True, exist_ok=True)
    total = 0
    for i, pic in enumerate(PICTURES):
        if i < start_from:
            continue
        pic_id = pic["id"]
        existing = list(PUZZLES_DIR.glob(f"{pic_id}_*.json"))
        if len(existing) >= 6:
            print(f"[{i+1}/105] 已存在6个关卡，跳过: {pic_id}")
            continue
        print(f"\n[{i+1}/105] 生成关卡: {pic['title']} ({pic_id})")
        print(f"  网格: {pic['grid_size']}×{pic['grid_size']}, 难度: {pic['difficulty']}")
        for chunk_idx in range(6):
            puzzle = generate_puzzle(pic, chunk_idx)
            file_path = PUZZLES_DIR / f"{puzzle['id']}.json"
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(puzzle, f, ensure_ascii=False, indent=2)
            total += 1
            hint_info = f", 提示格: {len(puzzle['hint_cells'])}" if puzzle['hint_cells'] else ""
            print(f"  生成: {puzzle['id']}{hint_info}")
    print(f"\n关卡生成完成！共生成 {total} 个关卡")


def rename_old_files():
    OLD_TO_NEW = {}
    for i, pic in enumerate(PICTURES):
        pic_id = pic["id"]
        old_ids = []
        if pic_id.startswith("chapter2_"):
            num = int(pic_id.split("_")[1])
            short = pic_id.split("_", 2)[2] if "_" in pic_id[9:] else pic_id[9:]
        elif pic_id.startswith("chapter1_"):
            continue
        else:
            continue
        OLD_TO_NEW[pic_id] = pic_id

    old_name_map = {
        "xia_chao_gongdian": "chapter2_09_xia_gongdian",
        "erlitou": "chapter2_10_erlitou",
        "jiaguwen": "chapter2_11_jiaguwen",
        "simuwu_ding": "chapter2_12_simuwu",
        "shangzhou_qingtongqi": "chapter2_13_qingtongqi",
        "zhouwenwang": "chapter2_14_wenwang",
        "zhouwuwang": "chapter2_15_wuwang",
        "zhougongdan": "chapter2_16_zhougong",
        "chunqiu_wuba": "chapter2_17_wuba",
        "kongzi": "chapter2_18_kongzi",
        "laozi": "chapter2_19_laozi",
        "sunzi_bingfa": "chapter2_20_sunzi",
        "shangyang_bianfa": "chapter2_21_shangyang",
        "quyuan": "chapter2_22_quyuan",
        "jingke": "chapter2_23_jingke",
        "qinshihuang": "chapter3_24_qinshihuang",
        "qin_changcheng": "chapter3_25_changcheng",
        "bingmayong": "chapter3_26_bingmayong",
        "chensheng_wuguang": "chapter3_27_chensheng",
        "liubang_xiangyu": "chapter3_28_chuhan",
        "liubang": "chapter3_29_liubang",
        "zhangqian": "chapter3_30_zhangqian",
        "hanwudi": "chapter3_31_hanwudi",
        "huoqubing": "chapter3_32_huoqubing",
        "simaqian": "chapter3_33_simaqian",
        "zhaojun": "chapter3_34_zhaojun",
        "wangmang": "chapter3_35_wangmang",
        "guangwu": "chapter3_36_guangwu",
        "cailun": "chapter3_37_cailun",
        "zhangheng": "chapter3_38_zhangheng",
        "taoyuan_sanjieyi": "chapter4_39_taoyuan",
        "guandu": "chapter4_40_guandu",
        "chibi": "chapter4_41_chibi",
        "zhugekongming": "chapter4_42_zhugeliang",
        "simayi": "chapter4_43_simayi",
        "wangxizhi": "chapter4_44_wangxizhi",
        "gukaizhi": "chapter4_45_gukaizhi",
        "taoyuanming": "chapter4_46_taoyuanming",
        "xiaowen_di": "chapter4_47_xiaowendi",
        "longmen_shiku": "chapter4_48_longmen",
        "zuchongzhi": "chapter4_49_zuchongzhi",
        "feishui": "chapter4_50_feishui",
        "suiwendi": "chapter5_51_suiwendi",
        "suiyangdi": "chapter5_52_yunhe",
        "lichun_zhaozhouqiao": "chapter5_53_zhaozhou",
        "taizong": "chapter5_54_taizong",
        "zhenguan": "chapter5_55_zhenguan",
        "wuzetian": "chapter5_56_wuzetian",
        "xuanzang": "chapter5_57_xuanzang",
        "wencheng_gongzhu": "chapter5_58_wencheng",
        "jianzhen": "chapter5_59_jianzhen",
        "libai": "chapter5_60_libai",
        "dufu": "chapter5_61_dufu",
        "yanzhenqing": "chapter5_62_yanzhenqing",
        "wudaozi": "chapter5_63_wudaozi",
        "anshi": "chapter5_64_anshi",
        "dunhuang": "chapter5_65_dunhuang",
        "zhaokuangyin": "chapter6_66_zhaokuangyin",
        "beijiu_shibingquan": "chapter6_67_beijiu",
        "sushi": "chapter6_68_sushi",
        "wanganshi": "chapter6_69_wanganshi",
        "yuefei": "chapter6_70_yuefei",
        "xinqiji": "chapter6_71_xinqiji",
        "liqingzhao": "chapter6_72_liqingzhao",
        "xixia_wangling": "chapter6_73_xixia",
        "liao_dai_bihua": "chapter6_74_liaobihua",
        "jin_chao_ducheng": "chapter6_75_jinducheng",
        "bisheng": "chapter6_76_bisheng",
        "qingming_shanghetu": "chapter6_77_qingmingtu",
        "genghis_khan": "chapter7_78_genghis",
        "hubilie": "chapter7_79_hubilie",
        "marco_polo": "chapter7_80_marco",
        "yuandadu": "chapter7_81_yuandadu",
        "guanhanqing": "chapter7_82_guanhanqing",
        "guoshoujing": "chapter7_83_guoshoujing",
        "zhaomengfu": "chapter7_84_zhaomengfu",
        "wentianxiang": "chapter7_85_wentianxiang",
        "zhuyuanzhang": "chapter8_86_zhuyuanzhang",
        "zhenghe": "chapter8_87_zhenghe",
        "forbidden_city": "chapter8_88_zijincheng",
        "ming_changcheng": "chapter8_89_mingchangcheng",
        "lishizhen": "chapter8_90_lishizhen",
        "xuxiake": "chapter8_91_xuxiake",
        "lizicheng": "chapter8_92_lizicheng",
        "wusangui": "chapter8_93_wusangui",
        "kangxi": "chapter9_94_kangxi",
        "yongzheng": "chapter9_95_yongzheng",
        "qianlong": "chapter9_96_qianlong",
        "siku_quanshu": "chapter9_97_siku",
        "caoxueqin": "chapter9_98_caoxueqin",
        "yapian_zhanzheng": "chapter10_99_yapian",
        "taiping_tianguo": "chapter10_100_taiping",
        "yangwu_yundong": "chapter10_101_yangwu",
        "xinhai_geming": "chapter10_102_xinhai",
        "wusi_yundong": "chapter11_103_wusi",
        "kangri_zhanzheng": "chapter11_104_kangri",
        "xin_zhongguo": "chapter11_105_xinzhongguo",
    }

    renamed_images = 0
    renamed_puzzles = 0

    for old_id, new_id in old_name_map.items():
        old_img = IMAGES_DIR / f"{old_id}.jpg"
        new_img = IMAGES_DIR / f"{new_id}.jpg"
        if old_img.exists() and not new_img.exists():
            old_img.rename(new_img)
            renamed_images += 1
            print(f"  图片: {old_id}.jpg -> {new_id}.jpg")

        old_pixel = IMAGES_DIR / f"{old_id}_pixel.png"
        new_pixel = IMAGES_DIR / f"{new_id}_pixel.png"
        if old_pixel.exists() and not new_pixel.exists():
            old_pixel.rename(new_pixel)
            print(f"  像素图: {old_id}_pixel.png -> {new_id}_pixel.png")

        for chunk_idx in range(6):
            old_puzzle = PUZZLES_DIR / f"{old_id}_{chunk_idx}.json"
            new_puzzle = PUZZLES_DIR / f"{new_id}_{chunk_idx}.json"
            if old_puzzle.exists() and not new_puzzle.exists():
                with open(old_puzzle, 'r', encoding='utf-8') as f:
                    puzzle_data = json.load(f)
                puzzle_data["id"] = f"{new_id}_{chunk_idx}"
                puzzle_data["picture_id"] = new_id
                if chunk_idx == 0 and new_id == "chapter1_01_yuanmou":
                    puzzle_data["name"] = f"{puzzle_data['name'].split('-')[0].split('分块')[0]} - 分块{chunk_index}（新手引导）"
                else:
                    title = puzzle_data["name"].split("-")[0].strip() if "-" in puzzle_data["name"] else puzzle_data["name"].split("分块")[0].strip()
                    puzzle_data["name"] = f"{title}-分块{chunk_idx}"
                with open(new_puzzle, 'w', encoding='utf-8') as f:
                    json.dump(puzzle_data, f, ensure_ascii=False, indent=2)
                old_puzzle.unlink()
                renamed_puzzles += 1

    print(f"\n重命名完成！图片: {renamed_images}个，关卡: {renamed_puzzles}个")


def main():
    import sys
    if len(sys.argv) < 2:
        print("用法:")
        print("  python generate_chinese_history_all.py data      - 生成chinese_history.json数据文件")
        print("  python generate_chinese_history_all.py puzzles   - 生成所有数织关卡JSON")
        print("  python generate_chinese_history_all.py images    - 生成所有图片（调用API）")
        print("  python generate_chinese_history_all.py rename    - 重命名旧文件为新命名规范")
        print("  python generate_chinese_history_all.py all       - 执行全部（数据+关卡+图片）")
        print("  python generate_chinese_history_all.py usage     - 查看API使用报告")
        return

    command = sys.argv[1]
    start_from = int(sys.argv[2]) if len(sys.argv) > 2 else 0

    if command == "data":
        generate_pictures_json()
    elif command == "puzzles":
        generate_all_puzzles(start_from)
    elif command == "images":
        generate_images(start_from)
    elif command == "rename":
        rename_old_files()
    elif command == "usage":
        pool = APIAccountPool(ACCOUNTS_FILE)
        pool.report_usage()
    elif command == "all":
        generate_pictures_json()
        generate_all_puzzles(start_from)
        generate_images(start_from)
    else:
        print(f"未知命令: {command}")


if __name__ == "__main__":
    main()
