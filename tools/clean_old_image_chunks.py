import os
import re

def clean_old_image_chunks():
    illustrations_dir = "h:/Work/MyProject/ChineseMemory/assets/images/illustrations"
    
    print("=" * 60)
    print("清理不符合数字编号命名规范的旧图片分块")
    print("=" * 60)
    
    pattern = re.compile(r'^[a-z]+_[0-9]+\.png$')
    
    deleted_count = 0
    
    for era_dir in os.listdir(illustrations_dir):
        era_path = os.path.join(illustrations_dir, era_dir)
        if not os.path.isdir(era_path):
            continue
        
        for filename in os.listdir(era_path):
            if not filename.endswith('.png'):
                continue
            
            if not pattern.match(filename):
                file_path = os.path.join(era_path, filename)
                os.remove(file_path)
                print(f"删除: {filename}")
                deleted_count += 1
    
    print(f"\n共删除 {deleted_count} 个旧图片分块")
    print("\n" + "=" * 60)
    print("清理完成！")
    print("=" * 60)

if __name__ == "__main__":
    clean_old_image_chunks()