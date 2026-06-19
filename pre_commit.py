import sys
import subprocess
import os

def run_tests():
    print("🔄 جاري تشغيل كافة فحوصات الجودة قبل الإيداع...")
    try:
        # تشغيل أداة الفحص الجديدة
        result = subprocess.run(['python3', 'check_code.py'], capture_output=True, text=True)

        # طباعة التقرير العربي للمستخدم في كل الأحوال
        print(result.stdout)

        if result.returncode == 0:
            print("🚀 جميع الفحوصات تمت بنجاح! الكود جاهز للإيداع.")
            return True
        else:
            print("❌ فشلت بعض الفحوصات الأساسية. يرجى مراجعة التقرير أعلاه وإصلاح الأخطاء.")
            return False

    except FileNotFoundError:
        print("❌ خطأ: لم يتم العثور على أداة check_code.py")
        return False

if __name__ == "__main__":
    if not run_tests():
        sys.exit(1)
