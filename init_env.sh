#!/bin/bash
# شركة البرمجيات المستقلة - سكربت إعداد البيئة المتكامل
echo "🚀 جاري إعداد بيئة التطوير والتبعيات..."

# 1. تحديث النظام وتثبيت Lua و LuaRocks
if ! command -v lua5.4 &> /dev/null || ! command -v luarocks &> /dev/null; then
    echo "📦 تثبيت Lua 5.4 و LuaRocks..."
    sudo apt-get update && sudo apt-get install -y lua5.4 luarocks
else
    echo "✅ Lua 5.4 و LuaRocks مثبتان بالفعل."
fi

# 2. إعداد المسارات المحلية لـ LuaRocks
export PATH=$PATH:$HOME/.luarocks/bin

# 3. تثبيت Luacheck للفحص الاستاتيكي
if ! command -v luacheck &> /dev/null; then
    echo "🔍 تثبيت Luacheck..."
    luarocks install luacheck --local
else
    echo "✅ Luacheck جاهز للعمل."
fi

# 4. إنشاء المجلدات اللازمة
mkdir -p .bin

echo "✨ تم إعداد البيئة بنجاح! يمكنك الآن تشغيل أدوات الاختبار."
