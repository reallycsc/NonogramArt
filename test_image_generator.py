import os
import sys
from dotenv import load_dotenv

def test_environment():
    print("=== 环境配置测试 ===")
    
    if not os.path.exists('.env'):
        print("❌ .env 文件不存在")
        return False
    
    load_dotenv()
    
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        print("❌ OPENAI_API_KEY 未设置")
        return False
    if api_key == "your-api-key-here":
        print("❌ 请在.env文件中设置您的API密钥")
        return False
    print("✅ API密钥已配置")
    
    return True

def test_dependencies():
    print("\n=== 依赖检查 ===")
    
    try:
        import openai
        print(f"✅ openai 已安装 (版本: {openai.__version__})")
    except ImportError:
        print("❌ openai 未安装，请运行: pip install openai")
        return False
    
    try:
        from dotenv import load_dotenv
        print("✅ python-dotenv 已安装")
    except ImportError:
        print("❌ python-dotenv 未安装，请运行: pip install python-dotenv")
        return False
    
    return True

def test_api_connection():
    print("\n=== API连接测试 ===")
    
    try:
        from openai import OpenAI
        
        client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        
        models = client.models.list()
        model_names = [m.id for m in models.data]
        
        if "gpt-image-2" in model_names:
            print("✅ gpt-image-2 模型可用")
        else:
            print("⚠️ gpt-image-2 模型未在列表中，但可能仍可访问")
        
        return True
    except Exception as e:
        print(f"❌ API连接失败: {e}")
        return False

def test_image_generation():
    print("\n=== 图片生成测试 ===")
    
    try:
        from openai import OpenAI
        
        client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        
        response = client.images.generate(
            model="gpt-image-2",
            prompt="A simple test image: colorful geometric shapes on white background",
            size="1024x1024",
            n=1,
            quality="standard"
        )
        
        if response.data:
            image_url = response.data[0].url
            print(f"✅ 图片生成成功!")
            print(f"   图片URL: {image_url}")
            print(f"   有效期: 1小时")
            return True, image_url
        else:
            print("❌ 响应数据为空")
            return False, None
            
    except Exception as e:
        print(f"❌ 图片生成失败: {e}")
        return False, None

def main():
    print("=" * 60)
    print("GPT Image 2 API 测试验证流程")
    print("=" * 60)
    
    tests = [
        ("环境配置", test_environment),
        ("依赖检查", test_dependencies),
        ("API连接", test_api_connection),
    ]
    
    all_passed = True
    for name, test_func in tests:
        if not test_func():
            all_passed = False
    
    if all_passed:
        print("\n" + "=" * 60)
        print("所有前置检查通过!")
        print("=" * 60)
        
        print("\n是否进行实际图片生成测试?")
        print("注意: 这将消耗您的API额度 (~$0.04)")
        choice = input("继续? (y/n): ").strip().lower()
        
        if choice == 'y':
            success, url = test_image_generation()
            if success:
                print("\n🎉 测试完成! 图片生成成功!")
                print(f"您可以访问此URL查看图片: {url}")
            else:
                print("\n测试失败，请检查API密钥和网络连接")
        else:
            print("跳过图片生成测试")
    else:
        print("\n请先修复上述问题，然后重新运行测试")
        sys.exit(1)

if __name__ == "__main__":
    main()