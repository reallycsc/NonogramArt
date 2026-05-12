import json
import os
import sys
from pathlib import Path
from PIL import Image

BASE_DIR = Path("h:/Work/MyProject/NonogramArt")
IMAGES_DIR = BASE_DIR / "assets" / "images" / "illustrations" / "chinese_history"
PUZZLES_DIR = BASE_DIR / "data" / "puzzles" / "chinese_history"
PICTURES_FILE = BASE_DIR / "data" / "pictures" / "chinese_history.json"

PYTHON = r"C:\Users\Administrator\AppData\Local\Programs\Python\Python314\python.exe"

GRID_X = 3
GRID_Y = 2

PICTURES = [
    {"id": "chapter1_01_yuanmou", "title": "元谋人遗址", "grid_size": 5, "difficulty": "tutorial"},
    {"id": "chapter1_02_beijing_ape", "title": "北京猿人生活场景", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter1_03_shandingdong", "title": "山顶洞人狩猎", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter1_04_hemudu", "title": "河姆渡文化", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter1_05_yangshao", "title": "仰韶文化彩陶", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter1_06_liangzhu", "title": "良渚古城", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter1_07_huangdi", "title": "黄帝部落联盟", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter1_08_dayu", "title": "大禹治水", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter2_09_xia_gongdian", "title": "夏朝宫殿想象图", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter2_10_erlitou", "title": "二里头遗址", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter2_11_jiaguwen", "title": "甲骨文", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter2_12_simuwu", "title": "司母戊鼎", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter2_13_qingtongqi", "title": "商周青铜器", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter2_14_wenwang", "title": "周文王推演周易", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter2_15_wuwang", "title": "周武王伐纣", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter2_16_zhougong", "title": "周公旦辅政", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter2_17_wuba", "title": "春秋五霸", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter2_18_kongzi", "title": "孔子讲学", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter2_19_laozi", "title": "老子骑牛出关", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter2_20_sunzi", "title": "孙子兵法", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter2_21_shangyang", "title": "商鞅变法", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter2_22_quyuan", "title": "屈原投江", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter2_23_jingke", "title": "荆轲刺秦王", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter3_24_qinshihuang", "title": "秦始皇统一六国", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter3_25_changcheng", "title": "秦长城", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter3_26_bingmayong", "title": "兵马俑", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter3_27_chensheng", "title": "陈胜吴广起义", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter3_28_chuhan", "title": "刘邦项羽楚汉相争", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter3_29_liubang", "title": "汉高祖刘邦", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter3_30_zhangqian", "title": "张骞出使西域", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter3_31_hanwudi", "title": "汉武帝刘彻", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter3_32_huoqubing", "title": "霍去病北击匈奴", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter3_33_simaqian", "title": "司马迁写史记", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter3_34_zhaojun", "title": "昭君出塞", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter3_35_wangmang", "title": "王莽改制", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter3_36_guangwu", "title": "光武中兴", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter3_37_cailun", "title": "蔡伦造纸", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter3_38_zhangheng", "title": "张衡与地动仪", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter4_39_taoyuan", "title": "桃园三结义", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter4_40_guandu", "title": "官渡之战", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter4_41_chibi", "title": "赤壁之战", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter4_42_zhugeliang", "title": "诸葛亮北伐", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter4_43_simayi", "title": "司马懿", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter4_44_wangxizhi", "title": "王羲之书法", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter4_45_gukaizhi", "title": "顾恺之绘画", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter4_46_taoyuanming", "title": "陶渊明归隐", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter4_47_xiaowendi", "title": "北魏孝文帝改革", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter4_48_longmen", "title": "龙门石窟", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter4_49_zuchongzhi", "title": "祖冲之与圆周率", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter4_50_feishui", "title": "淝水之战", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter5_51_suiwendi", "title": "隋文帝统一中国", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter5_52_yunhe", "title": "隋炀帝开凿大运河", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter5_53_zhaozhou", "title": "李春与赵州桥", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter5_54_taizong", "title": "唐太宗李世民", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter5_55_zhenguan", "title": "贞观之治", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter5_56_wuzetian", "title": "武则天称帝", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter5_57_xuanzang", "title": "玄奘取经", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter5_58_wencheng", "title": "文成公主入藏", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter5_59_jianzhen", "title": "鉴真东渡", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter5_60_libai", "title": "李白醉酒作诗", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter5_61_dufu", "title": "杜甫", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter5_62_yanzhenqing", "title": "颜真卿书法", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter5_63_wudaozi", "title": "吴道子绘画", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter5_64_anshi", "title": "安史之乱", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter5_65_dunhuang", "title": "敦煌莫高窟", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter6_66_zhaokuangyin", "title": "赵匡胤陈桥兵变", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter6_67_beijiu", "title": "杯酒释兵权", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter6_68_sushi", "title": "苏轼游赤壁", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter6_69_wanganshi", "title": "王安石变法", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter6_70_yuefei", "title": "岳飞抗金", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter6_71_xinqiji", "title": "辛弃疾", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter6_72_liqingzhao", "title": "李清照", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter6_73_xixia", "title": "西夏王陵", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter6_74_liaobihua", "title": "辽代壁画", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter6_75_jinducheng", "title": "金朝都城", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter6_76_bisheng", "title": "毕昇与活字印刷", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter6_77_qingmingtu", "title": "张择端清明上河图", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter7_78_genghis", "title": "成吉思汗西征", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter7_79_hubilie", "title": "忽必烈建元", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter7_80_marco", "title": "马可波罗来华", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter7_81_yuandadu", "title": "元大都", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter7_82_guanhanqing", "title": "关汉卿创作杂剧", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter7_83_guoshoujing", "title": "郭守敬与授时历", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter7_84_zhaomengfu", "title": "赵孟頫书法", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter7_85_wentianxiang", "title": "文天祥抗元", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter8_86_zhuyuanzhang", "title": "朱元璋建立明朝", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter8_87_zhenghe", "title": "郑和下西洋", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter8_88_zijincheng", "title": "紫禁城", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter8_89_mingchangcheng", "title": "明长城", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter8_90_lishizhen", "title": "李时珍与本草纲目", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter8_91_xuxiake", "title": "徐霞客游记", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter8_92_lizicheng", "title": "李自成起义", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter8_93_wusangui", "title": "吴三桂引清兵入关", "grid_size": 15, "difficulty": "medium"},
    {"id": "chapter9_94_kangxi", "title": "康熙皇帝", "grid_size": 20, "difficulty": "hard"},
    {"id": "chapter9_95_yongzheng", "title": "雍正皇帝", "grid_size": 20, "difficulty": "hard"},
    {"id": "chapter9_96_qianlong", "title": "乾隆下江南", "grid_size": 20, "difficulty": "hard"},
    {"id": "chapter9_97_siku", "title": "四库全书", "grid_size": 20, "difficulty": "hard"},
    {"id": "chapter9_98_caoxueqin", "title": "曹雪芹与红楼梦", "grid_size": 20, "difficulty": "hard"},
    {"id": "chapter10_99_yapian", "title": "鸦片战争", "grid_size": 20, "difficulty": "hard"},
    {"id": "chapter10_100_taiping", "title": "太平天国运动", "grid_size": 20, "difficulty": "hard"},
    {"id": "chapter10_101_yangwu", "title": "洋务运动", "grid_size": 20, "difficulty": "hard"},
    {"id": "chapter10_102_xinhai", "title": "辛亥革命", "grid_size": 20, "difficulty": "hard"},
    {"id": "chapter11_103_wusi", "title": "五四运动", "grid_size": 20, "difficulty": "hard"},
    {"id": "chapter11_104_kangri", "title": "抗日战争", "grid_size": 20, "difficulty": "hard"},
    {"id": "chapter11_105_xinzhongguo", "title": "新中国成立", "grid_size": 20, "difficulty": "hard"},
]


def generate_pixel_image(pic_info):
    pic_id = pic_info["id"]
    grid_size = pic_info["grid_size"]

    img_path = IMAGES_DIR / f"{pic_id}.jpg"
    if not img_path.exists():
        print(f"  原图不存在: {img_path}")
        return False

    img = Image.open(img_path).convert("RGB")
    img_width, img_height = img.size

    pixel_w = GRID_X * grid_size
    pixel_h = GRID_Y * grid_size

    block_width = img_width / GRID_X
    block_height = img_height / GRID_Y

    pixel_img = Image.new("RGB", (pixel_w, pixel_h))

    for y_block in range(GRID_Y):
        for y_pixel in range(grid_size):
            for x_block in range(GRID_X):
                for x_pixel in range(grid_size):
                    sample_x = int(x_block * block_width + block_width * (x_pixel + 0.5) / grid_size)
                    sample_y = int(y_block * block_height + block_height * (y_pixel + 0.5) / grid_size)
                    sample_x = min(sample_x, img_width - 1)
                    sample_y = min(sample_y, img_height - 1)

                    pixel_color = img.getpixel((sample_x, sample_y))
                    px = x_block * grid_size + x_pixel
                    py = y_block * grid_size + y_pixel
                    pixel_img.putpixel((px, py), pixel_color)

    upscaled = pixel_img.resize((img_width, img_height), Image.Resampling.NEAREST)

    output_path = IMAGES_DIR / f"{pic_id}_pixel.jpg"
    upscaled.save(output_path, "JPEG", quality=95)

    file_size = os.path.getsize(output_path)
    print(f"  已生成: {pic_id}_pixel.jpg ({pixel_w}x{pixel_h} -> {img_width}x{img_height}, {file_size // 1024}KB)")
    return True


def verify_puzzles():
    missing = []
    for pic in PICTURES:
        pic_id = pic["id"]
        for chunk_idx in range(6):
            puzzle_path = PUZZLES_DIR / f"{pic_id}_{chunk_idx}.json"
            if not puzzle_path.exists():
                missing.append(f"{pic_id}_{chunk_idx}")
    if missing:
        print(f"缺少 {len(missing)} 个关卡文件:")
        for m in missing[:10]:
            print(f"  {m}")
        if len(missing) > 10:
            print(f"  ... 还有 {len(missing) - 10} 个")
    else:
        print("所有630个关卡文件完整")
    return len(missing) == 0


def update_pictures_json():
    with open(PICTURES_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)

    for pic in data["pictures"]:
        pic_id = pic["id"]
        pic["pixel_image"] = f"res://assets/images/illustrations/chinese_history/{pic_id}_pixel.jpg"

    with open(PICTURES_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"已更新 {PICTURES_FILE}，添加 pixel_image 字段")


def main():
    import sys
    command = sys.argv[1] if len(sys.argv) > 1 else "all"

    if command == "pixel" or command == "all":
        print(f"\n=== 生成像素图 ({len(PICTURES)} 张) ===")
        success = 0
        failed = 0
        skipped = 0
        for i, pic in enumerate(PICTURES):
            pic_id = pic["id"]
            output_path = IMAGES_DIR / f"{pic_id}_pixel.jpg"
            if output_path.exists():
                skipped += 1
                continue

            print(f"[{i+1}/{len(PICTURES)}] {pic['title']} ({pic_id}) grid={pic['grid_size']}")
            if generate_pixel_image(pic):
                success += 1
            else:
                failed += 1

        print(f"\n像素图生成完成: 成功={success}, 跳过={skipped}, 失败={failed}")

    if command == "verify" or command == "all":
        print(f"\n=== 验证关卡文件 ===")
        verify_puzzles()

    if command == "update_json" or command == "all":
        print(f"\n=== 更新数据文件 ===")
        update_pictures_json()


if __name__ == "__main__":
    main()
