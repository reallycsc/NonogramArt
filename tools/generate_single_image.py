import os
import json
import requests
from PIL import Image
from io import BytesIO

API_BASE_URL = "https://ark.cn-beijing.volces.com/api/v3/images/generations"
API_KEY = "ark-769a3f8a-9ceb-4556-ae95-d882f7966850-2be63"
MODEL = "doubao-seedream-4-5-251128"

def generate_jimeng_image(prompt, size="2K"):
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "model": MODEL,
        "prompt": prompt,
        "sequential_image_generation": "disabled",
        "response_format": "url",
        "size": size,
        "stream": False,
        "watermark": False
    }
    
    try:
        print(f"正在调用API生成图片...")
        response = requests.post(API_BASE_URL, headers=headers, json=payload, timeout=180)
        response.raise_for_status()
        result = response.json()
        print(f"API返回结果: {json.dumps(result, ensure_ascii=False, indent=2)}")
        
        if result.get("data") and isinstance(result["data"], list) and len(result["data"]) > 0:
            if result["data"][0].get("url"):
                return result["data"][0]["url"]
        
        print(f"API调用失败: {result.get('error', {}).get('message', '未知错误')}")
        return None
    except requests.exceptions.RequestException as e:
        print(f"请求异常: {str(e)}")
        return None

def download_image(url, save_path):
    try:
        response = requests.get(url)
        response.raise_for_status()
        img = Image.open(BytesIO(response.content))
        img.save(save_path)
        print(f"图片已保存: {save_path}")
        return True
    except Exception as e:
        print(f"下载图片失败: {str(e)}")
        return False

def main():
    prompt = "中国风太阳图标，简约风格，红色圆形，光芒四射，传统纹样，水墨风格，高分辨率"
    save_path = "h:/Work/MyProject/ChineseMemory/assets/images/puzzles/mythology_jimeng/pangu_sun.png"
    
    print(f"=== 正在生成缺失的图片: pangu_sun ===")
    print(f"提示词: {prompt}")
    
    image_url = generate_jimeng_image(prompt, size="2K")
    if image_url:
        print(f"生成成功: {image_url}")
        download_image(image_url, save_path)
    else:
        print(f"生成失败")

if __name__ == "__main__":
    main()