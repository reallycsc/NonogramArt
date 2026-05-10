import sys
sys.path.insert(0, 'tools')
from generate_chinese_history_all import *

pool = APIAccountPool(ACCOUNTS_FILE)

for i, acc in enumerate(pool.accounts):
    if 'Kolors' in acc.get('model', ''):
        pool.current_index = i
        break

pic = PICTURES[104]
prompt = build_prompt(pic["scene"])
print("使用Kolors生成:", pic["title"])
print("提示词:", prompt)

image_url = generate_jimeng_image(pool, prompt, size="2496x1664")
if image_url and image_url != "CONTENT_BLOCKED":
    save_path = str(IMAGES_DIR / f'{pic["id"]}.png')
    download_image(image_url, save_path, target_size=(2496, 1664))
    print("成功!")
else:
    print("Kolors也被拦截，尝试更安全的提示词...")
    safe_prompt = build_prompt("天安门广场上红旗飘扬，人们欢庆新中国成立，礼花绽放")
    image_url = generate_jimeng_image(pool, safe_prompt, size="2496x1664")
    if image_url and image_url != "CONTENT_BLOCKED":
        save_path = str(IMAGES_DIR / f'{pic["id"]}.png')
        download_image(image_url, save_path, target_size=(2496, 1664))
        print("安全提示词成功!")
    else:
        print("完全失败")
