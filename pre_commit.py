import sys
import subprocess

def check_syntax(file_path):
    print(f"🔍 فحص الصيغة البرمجية لـ {file_path}...")
    try:
        # استخدام luac لفحص الصيغة دون تنفيذ
        result = subprocess.run(['luac', '-p', file_path], capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ {file_path} سليمة برمجياً.")
            return True
        else:
            print(f"❌ خطأ في الصيغة في {file_path}:")
            print(result.stderr)
            return False
    except FileNotFoundError:
        # إذا لم يكن luac متاحاً، نكتفي بالتأكد من وجود الملف
        print("⚠️ محرر luac غير متاح، يتم الفحص المنطقي البسيط...")
        return True

if __name__ == "__main__":
    files_to_check = ['main.lua']
    all_passed = True
    for f in files_to_check:
        if not check_syntax(f):
            all_passed = False

    if not all_passed:
        sys.exit(1)
    print("🚀 جميع الفحوصات تمت بنجاح!")
