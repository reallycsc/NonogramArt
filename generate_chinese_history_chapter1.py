import os
import time
import base64
from pathlib import Path
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

client = OpenAI(
    api_key=os.getenv("API_KEY"),
    base_url=os.getenv("API_BASE_URL"),
    timeout=120
)

chapter1_prompts = [
    {
        "id": "chapter1_01_yuanmou",
        "title": "元谋人遗址",
        "description": "中国最早的人类化石发现地",
        "prompt_text": "Chinese style cartoon of Yuanmou Man site, ancient prehistoric scene, early human ancestors in primitive clothing, discovering fossil remains, tropical forest environment, Yunnan province landscape, Q-version cute characters, warm earthy colors, educational illustration"
    },
    {
        "id": "chapter1_02_beijing_ape",
        "title": "北京猿人生活场景",
        "description": "原始人在山洞前使用石器",
        "prompt_text": "Chinese style cartoon of Peking Man living scene, primitive humans outside cave entrance, using stone tools, making fire, family group gathering, prehistoric landscape with mountains, Q-version cute characters, warm colors, educational illustration"
    },
    {
        "id": "chapter1_03_shandingdong_hunt",
        "title": "山顶洞人狩猎",
        "description": "原始人类围猎大型动物",
        "prompt_text": "Chinese style cartoon of Upper Cave Man hunting scene, primitive humans with spears and stone tools, surrounding a large mammoth, cave painting style elements, dramatic hunting action, Q-version cute characters, dynamic composition, warm earth tones"
    },
    {
        "id": "chapter1_04_hemudu",
        "title": "河姆渡文化",
        "description": "原始农耕和干栏式房屋建筑",
        "prompt_text": "Chinese style cartoon of Hemudu culture village, stilt houses on wooden pillars over water, rice paddies, primitive agriculture, early pottery, Yangtze River delta landscape, Q-version cute characters working in fields, green and blue color palette"
    },
    {
        "id": "chapter1_05_yangshao_pottery",
        "title": "仰韶文化彩陶",
        "description": "精美的彩陶器皿",
        "prompt_text": "Chinese style cartoon showing Yangshao culture pottery, beautiful painted pottery vessels with fish and spiral patterns, ancient craftspeople making pottery, kiln firing scene, Neolithic art style, earthy orange and red colors, Q-version cute characters"
    },
    {
        "id": "chapter1_06_liangzhu_city",
        "title": "良渚古城",
        "description": "长江流域早期文明",
        "prompt_text": "Chinese style cartoon of Liangzhu ancient city, massive stone walls, moat surrounding the city, jade artifacts, early urban civilization, Yangtze River basin, Q-version cute characters in ancient attire, grand architectural scene"
    },
    {
        "id": "chapter1_07_huangdi_tribe",
        "title": "黄帝部落联盟",
        "description": "炎黄二帝带领部落",
        "prompt_text": "Chinese style cartoon of Yellow Emperor tribal alliance, Emperor Yan and Emperor Huang leading their tribes, ancient Chinese leaders with crowns, tribal warriors with spears, meeting ceremony, mythological style, red and yellow imperial colors, Q-version cute characters"
    },
    {
        "id": "chapter1_08_dayu_flood",
        "title": "大禹治水",
        "description": "大禹带领民众治理洪水",
        "prompt_text": "Chinese style cartoon of Yu the Great controlling floods, Da Yu leading people building dams and canals, flood waters being diverted, ancient engineering scene, people working together, heroic leader figure, blue and brown color palette, Q-version cute characters"
    }
]

output_dir = Path("assets/images/illustrations/chinese_history/chapter1")
output_dir.mkdir(parents=True, exist_ok=True)

def save_base64_image(base64_data, save_path):
    try:
        img_bytes = base64.b64decode(base64_data)
        with open(save_path, 'wb') as f:
            f.write(img_bytes)
        return True
    except Exception as e:
        print(f"  保存失败: {e}")
        return False

def generate_image_with_retry(prompt, max_retries=3):
    for attempt in range(max_retries):
        try:
            response = client.images.generate(
                model="gpt-image-2",
                prompt=prompt,
                size="1024x1024",
                quality="low",
                n=1
            )
            
            if hasattr(response, 'data') and response.data and len(response.data) > 0:
                first_item = response.data[0]
                if hasattr(first_item, 'b64_json') and first_item.b64_json:
                    return first_item.b64_json
                elif hasattr(first_item, 'url') and first_item.url:
                    return first_item.url
            return None
                
        except Exception as e:
            wait_time = (2 ** attempt) * 5
            if attempt < max_retries - 1:
                time.sleep(wait_time)
    return None

print(f"开始生成《中国通史》第一章的8张故事插图...")
print(f"输出目录: {output_dir.resolve()}")
print("=" * 60)

success_count = 0
failed_items = []

for i, item in enumerate(chapter1_prompts, 1):
    print(f"\n[{i}/8] 正在生成: {item['title']}")
    print(f"描述: {item['description']}")
    
    image_data = generate_image_with_retry(item["prompt_text"])
    
    if image_data:
        filename = output_dir / f"{item['id']}.png"
        if save_base64_image(image_data, filename):
            print(f"✅ 成功保存: {filename.name}")
            success_count += 1
        else:
            print(f"❌ 保存失败")
            failed_items.append(item["title"])
    else:
        print(f"❌ 生成失败")
        failed_items.append(item["title"])

print("\n" + "=" * 60)
print(f"生成完成！成功: {success_count}/{len(chapter1_prompts)}")
if failed_items:
    print(f"失败的图片: {', '.join(failed_items)}")
print(f"保存位置: {output_dir.resolve()}")