import subprocess
import os
import sys

def run_command(command, shell=True):
    try:
        result = subprocess.run(command, shell=shell, capture_output=True, text=True)
        return result.returncode, result.stdout, result.stderr
    except Exception as e:
        return -1, "", str(e)

def get_arabic_report():
    report = []
    report.append("📊 **تقرير فحص الكود البرمجي** 📊\n")

    # 1. Syntax Check
    report.append("🔍 **1. فحص الصيغة البرمجية (Syntax Check):**")
    rc_syntax, stdout_syntax, stderr_syntax = run_command("luac -p main.lua")
    if rc_syntax == 0:
        report.append("✅ لا توجد أخطاء في الصيغة البرمجية لملف `main.lua`.")
    else:
        report.append("❌ تم العثور على أخطاء في الصيغة (يجب إصلاحها فوراً):")
        report.append(f"```\n{stderr_syntax}```")

    report.append("\n" + "-"*30 + "\n")

    # 2. Linting (Luacheck)
    report.append("🛡️ **2. فحص جودة الكود (Quality & Linting):**")
    luacheck_path = os.path.expanduser("~/.luarocks/bin/luacheck")
    # تعاريف AndroLua+ الشائعة لتجنب التحذيرات غير الضرورية
    globals_list = "activity,service,luajava,import,loadlayout,Toast,AlertDialog,Color,Intent,Timer,TimerTask,Handler,Runnable,Bitmap,BitmapFactory,File,FileInputStream,FileOutputStream,Environment,Uri,View,LayoutParams,LinearLayout,RelativeLayout,FrameLayout,TextView,ImageView,ListView,Button,EditText,CardView,ColorStateList,PorterDuff,Typeface,InputMethodManager,Context,Vibrator,AudioAttributes,MediaPlayer,AudioManager,URL,HttpURLConnection,Thread,String,Integer,System,LuaAdapter,ArrayAdapter,HashMap,ArrayList,FileProvider,ClipData,ClipboardManager"

    rc_lint, stdout_lint, stderr_lint = run_command(f"{luacheck_path} main.lua --globals {globals_list} --ignore 212 213 113 --max-line-length 500")

    if rc_lint == 0:
        report.append("✅ الكود يتبع معايير الجودة بنجاح.")
    elif rc_lint == 1: # Warnings/Errors found
        report.append("⚠️ تم العثور على ملاحظات أو تحسينات ممكنة:")
        # نأخذ أول 20 سطر من التقرير لتجنب الإطالة
        lines = stdout_lint.split('\n')
        if len(lines) > 25:
            summary = "\n".join(lines[:20]) + f"\n... (هناك {len(lines) - 20} سطر آخر)"
        else:
            summary = stdout_lint
        report.append(f"```\n{summary}```")
    else:
        report.append("❌ فشل تشغيل أداة Luacheck.")
        report.append(f"```\n{stderr_lint}```")

    report.append("\n" + "-"*30 + "\n")

    # 3. Logic Tests
    report.append("🧪 **3. اختبارات المنطق (Logic Tests):**")
    rc_test, stdout_test, stderr_test = run_command("lua test.lua")
    if rc_test == 0:
        report.append("✅ جميع اختبارات الوحدات مرت بسلام.")
        report.append(f"```\n{stdout_test}```")
    else:
        report.append("❌ فشلت بعض اختبارات المنطق:")
        report.append(f"```\n{stdout_test}\n{stderr_test}```")

    report.append("\n" + "="*30)

    # النجاح يعتمد على السنتاكس واختبارات المنطق بشكل أساسي
    # السنتاكس يجب أن يكون 0
    # المنطق يجب أن يكون 0
    overall_success = (rc_syntax == 0) and (rc_test == 0)

    return "\n".join(report), overall_success

if __name__ == "__main__":
    report_text, success = get_arabic_report()
    print(report_text)
    if not success:
        sys.exit(1)
