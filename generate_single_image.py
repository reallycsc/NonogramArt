import os
import time
import base64
from pathlib import Path
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

print("=== 环境配置检查 ===")
print(f"API_KEY: {'已配置' if os.getenv('API_KEY') and os.getenv('API_KEY') != 'your-apiyi-api-key-here' else '未配置'}")
print(f"API_BASE_URL: {os.getenv('API_BASE_URL')}")

client = OpenAI(
    api_key=os.getenv("API_KEY"),
    base_url=os.getenv("API_BASE_URL"),
    timeout=120
)

prompt = {
    "id": "chapter1_01_yuanmou",
    "title": "元谋人遗址",
    "description": "中国最早的人类化石发现地",
    "prompt_text": "Chinese style cartoon of ancient humans discovering fossils in a tropical forest, Yunnan landscape, cute Q-version characters, warm colors"
}

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
            print(f"  尝试 {attempt + 1}/{max_retries}...")
            response = client.images.generate(
                model="gpt-image-2",
                prompt=prompt,
                size="1024x1024",
                quality="low",
                n=1
            )
            
            print(f"  API响应成功")
            
            if hasattr(response, 'data') and response.data and len(response.data) > 0:
                first_item = response.data[0]
                
                if hasattr(first_item, 'b64_json') and first_item.b64_json:
                    print(f"  获取到base64图片数据")
                    return first_item.b64_json
                elif hasattr(first_item, 'url') and first_item.url:
                    print(f"  获取到URL: {first_item.url[:50]}...")
                    return first_item.url
                else:
                    print(f"  图片数据为空")
                    return None
            else:
                print("  response.data 为空")
                return None
                
        except Exception as e:
            wait_time = (2 ** attempt) * 5
            print(f"  错误: {type(e).__name__}: {e}")
            if attempt < max_retries - 1:
                print(f"  等待 {wait_time} 秒后重试...")
                time.sleep(wait_time)
    return None

print("\n=== 开始生成图片 ===")
print(f"标题: {prompt['title']}")
print(f"描述: {prompt['description']}")
print(f"提示词: {prompt['prompt_text'][:50]}...")
print("=" * 60)

image_data = generate_image_with_retry(prompt["prompt_text"])

if image_data:
    print(f"\n✅ 生成成功!")
    filename = output_dir / f"{prompt['id']}.png"
    
    if image_data.startswith('data:image') or len(image_data) > 1000:
        if save_base64_image(image_data, filename):
            print(f"✅ 成功保存: {filename.resolve()}")
        else:
            print(f"❌ 保存失败")
    else:
        print(f"❌ 未知的数据格式")
else:
    print("\n❌ 生成失败")