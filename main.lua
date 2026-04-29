require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.content.*"
import "android.view.inputmethod.InputMethodManager"
import "android.net.wifi.WifiManager"
import "android.media.MediaPlayer"
import "android.media.AudioManager"
import "android.graphics.Typeface" 
import "android.graphics.Color"
import "android.graphics.drawable.GradientDrawable" 
import "android.graphics.drawable.ColorDrawable"
import "android.view.accessibility.AccessibilityEvent"

local cjson = require "cjson"

-- ==========================================
-- 🎨 1. THEME & CONFIGURATION
-- ==========================================

local themes = {
  light = {
    name = "فاتح",
    colors = {
      primary = "#00897B", -- أخضر إسلامي حيوي
      primary_dark = "#00695C",
      accent = "#C49102", -- ذهبي غامق وواضح
      background = "#F1F8E9", -- خلفية مائلة للأخضر الفاتح جداً
      card_bg = "#FFFFFF",
      text_title = "#1B5E20", -- أخضر غامق جداً للنصوص
      text_body = "#4E342E", -- بني دافئ للنصوص الفرعية
      text_white = "#FFFFFF",
      bookmark_icon = "#E64A19",
      share_icon = "#1976D2",
      error_text = "#D32F2F"
    }
  },
  dark = {
    name = "داكن",
    colors = {
      primary = "#80CBC4", -- أخضر فاتح مريح للعين في الوضع الداكن
      primary_dark = "#004D40",
      accent = "#FFD54F", -- ذهبي مشرق
      background = "#121212",
      card_bg = "#1E1E1E",
      text_title = "#FFFFFF",
      text_body = "#B0B0B0",
      text_white = "#FFFFFF",
      bookmark_icon = "#FF7043",
      share_icon = "#64B5F6",
      error_text = "#EF9A9A"
    }
  }
}

local currentThemeMode = "light"
local theme = themes[currentThemeMode]

local dimens = {
  radius = 16,
  padding = 16
}

local config = {
  repeat_ayah = 1,
  delay_seconds = 0,
  font_size = 32,
  current_reciter = "ar.alafasy",
  dark_mode = false,
  auto_save_progress = true
}

local reciters = {
  {id="ar.alafasy", name="مشاري العفاسي"},
  {id="ar.husary", name="محمود خليل الحصري"},
  {id="ar.minshawi", name="محمد صديق المنشاوي"},
  {id="ar.abdulbasit", name="عبد الباسط عبد الصمد"},
  {id="ar.mahermuaiqly", name="ماهر المعيقلي"}
}

local quranSurahNames = {
  "الفاتحة","البقرة","آل عمران","النساء","المائدة","الأنعام","الأعراف","الأنفال","التوبة","يونس","هود","يوسف","الرعد","إبراهيم","الحجر","النحل","الإسراء","الكهف","مريم","طه","الأنبياء","الحج","المؤمنون","النور","الفرقان","الشعراء","النمل","القصص","العنكبوت","الروم","لقمان","السجدة","الأحزاب","سبأ","فاطر","يس","الصافات","ص","الزمر","غافر","فصلت","الشورى","الزخرف","الدخان","الجاثية","الأحقاف","محمد","الفتح","الحجرات","ق","الذاريات","الطور","النجم","القمر","الرحمن","الواقعة","الحديد","المجادلة","الحشر","الممتحنة","الصف","الجمعة","المنافقون","التغابن","الطلاق","التحريم","الملك","القلم","الحاقة","المعارج","نوح","الجن","المزمل","المدثر","القيامة","الإنسان","المرسلات","النبأ","النازعات","عبس","التكوير","الانفطار","المطففين","الانشقاق","البروج","الطارق","الأعلى","الغاشية","الفجر","البلد","الشمس","الليل","الضحى","الشرح","التين","العلق","القدر","البينة","الزلزلة","العاديات","القارعة","التكاثر","العصر","الهمزة","الفيل","قريش","الماعون","الكوثر","الكافرون","النصر","المسد","الإخلاص","الفلق","الناس"
}

local inspirationalVerses = {
  "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ",
  "وَقُلْ رَبِّ زِدْنِي عِلْمًا",
  "إِنَّ مَعَ الْعُسْرِ يُسْرًا",
  "فَاذْكُرُونِي أَذْكُرْكُمْ",
  "لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ",
  "وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ",
  "وَأَحْسِنُوا إِنَّ اللَّهَ يُحِبُّ الْمُحْسِنِينَ",
  "رَبِّ اجْعَلْنِي مُقِيمَ الصَّلَاةِ وَمِن ذُرِّيَّتِي",
  "إِنَّ اللَّهَ مَعَ الصَّابِرِينَ",
  "وَاعْتَصِمُوا بِحَبْلِ اللَّهِ جَمِيعًا",
  "وَاسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ",
  "إِنَّ رَبِّي قَرِيبٌ مُّجِيبٌ",
  "وَكَانَ اللَّهُ عَلَىٰ كُلِّ شَيْءٍ مُّقْتَدِرًا",
  "وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ",
  "اللَّهُ نُورُ السَّمَاوَاتِ وَالْأَرْضِ",
  "وَقُل رَّبِّ اغْفِرْ وَارْحَمْ وَأَنتَ خَيْرُ الرَّاحِمِينَ",
  "يَا أَيُّهَا الَّذِينَ آمَنُوا اذْكُرُوا اللَّهَ ذِكْرًا كَثِيرًا",
  "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا (5) إِنَّ مَعَ الْعُسْرِ يُسْرًا",
  "ادْعُونِي أَسْتَجِبْ لَكُمْ",
  "وَرَحْمَتِي وَسِعَتْ كُلَّ شَيْءٍ"
}

function setRandomQuote()
  if not quoteText then return end
  math.randomseed(os.time())
  local verse = inspirationalVerses[math.random(#inspirationalVerses)]
  quoteText.text = verse
end

local player = {
  media = nil,
  isPlaying = false,
  currentSurahData = nil,
  currentSurahName = "",
  currentSurahNumber = 0,
  currentAyahIndex = 1,
  currentRepeatCount = 0,
  currentAudioUrl = nil,
  isIndividualZekr = false
}
pcall(function() player.media = MediaPlayer() end)

local allSurahsData = {}
local currentSurahsList = {}
local currentAzkarCategories = {}
local currentAzkarItems = {}
local currentRadiosList = {}
local allAzkarData = {}
local allRadiosData = {}
local currentAzkarCategory = nil
local currentAppVersion = "1.0.5" -- إصلاح أخطاء التشغيل والتصفح (OTA Update)
local currentViewType = "surahs"
local allRecitersData = {}
local currentRecitersList = {}
local currentSelectedReciter = nil
local lastIndex = 0
local BaseURL = "https://api.alquran.cloud/v1"
local AzkarURL = "https://raw.githubusercontent.com/ahanafy41/The-Holy-Quran/feat/refactor-hisn-al-muslim/azkar-data/azkar.json"
local AzkarAudioBaseURL = "https://raw.githubusercontent.com/ahanafy41/The-Holy-Quran/feat/refactor-hisn-al-muslim/azkar-data"


local bookmarks = {}
local lastProgress = {
  surahNumber = nil,
  ayahNumber = nil,
  surahName = ""
}

local quranOfflineData = nil
-- Using External Files Dir makes it visible in: Android/data/[pkg]/files/quran_offline.json
local quranOfflinePath = activity.getExternalFilesDir(nil).getPath() .. "/quran_offline.json"

-- Simple Migration from old internal path
local oldInternalPath = activity.getFilesDir().getPath() .. "/quran_offline.json"
pcall(function()
  if File(oldInternalPath).exists() and not File(quranOfflinePath).exists() then
     local oldFile = io.open(oldInternalPath, "r")
     local content = oldFile:read("*a")
     oldFile:close()
     local newFile = io.open(quranOfflinePath, "w")
     newFile:write(content)
     newFile:close()
     os.remove(oldInternalPath)
  end
end)

-- ==========================================
-- 💾 2. DATA PERSISTENCE (حفظ البيانات)
-- ==========================================

local dataPath = activity.getLuaDir() .. "/app_data.json"

function saveAppData()
  local data = {
    config = config,
    bookmarks = bookmarks,
    lastProgress = lastProgress,
    darkMode = currentThemeMode == "dark"
  }
  local success, jsonStr = pcall(cjson.encode, data)
  if success then
    local file = io.open(dataPath, "w")
    if file then
      file:write(jsonStr)
      file:close()
    end
  end
end

function loadAppData()
  local file = io.open(dataPath, "r")
  if file then
    local content = file:read("*a")
    file:close()
    local success, data = pcall(cjson.decode, content)
    if success and data then
      if data.config then for k, v in pairs(data.config) do config[k] = v end end
      if data.bookmarks then bookmarks = data.bookmarks end
      if data.lastProgress then lastProgress = data.lastProgress end
      if data.darkMode then
        currentThemeMode = "dark"
        theme = themes.dark
        config.dark_mode = true
      end
    end
  end

  -- Load Offline Quran Data if exists
  local offlineFile = io.open(quranOfflinePath, "r")
  if offlineFile then
    local content = offlineFile:read("*a")
    offlineFile:close()
    if #content > 1000 then
      local success, data = pcall(cjson.decode, content)
      if success and data and data.text and data.muyassar then
        quranOfflineData = data
      end
    end
  end
end

loadAppData()

function downloadQuranOffline(callback)
  local pd = ProgressDialog(activity)
  pd.setTitle("تحميل البيانات للأوفلاين")
  pd.setMessage("جاري تحميل المصحف والتفسير...")
  pd.setCancelable(false)
  pd.show()

  local results = {}
  local function checkComplete()
    if results.text and results.muyassar and results.jalalayn then
      local data = { text = results.text, muyassar = results.muyassar, jalalayn = results.jalalayn }
      local success_json, jsonStr = pcall(cjson.encode, data)
      if success_json then
        local file = io.open(quranOfflinePath, "w")
        if file then
          file:write(jsonStr)
          file:close()
          quranOfflineData = data
          pd.dismiss()
          if callback then callback(true) end
          Toast.makeText(activity, "تم تحميل البيانات بنجاح ✔", Toast.LENGTH_SHORT).show()
        else
          pd.dismiss()
          Toast.makeText(activity, "فشل حفظ الملف محلياً", Toast.LENGTH_LONG).show()
        end
      else
        pd.dismiss()
        Toast.makeText(activity, "خطأ في تشفير البيانات", Toast.LENGTH_LONG).show()
      end
    end
  end

  local function fetch(edition, key)
    httpGet("https://api.alquran.cloud/v1/quran/" .. edition, function(success, body)
      if success then
        local ok, json = pcall(cjson.decode, body)
        if ok and json.code == 200 then
          results[key] = json.data
          checkComplete()
        else
          pd.dismiss()
          Toast.makeText(activity, "خطأ في معالجة نسخة " .. edition, Toast.LENGTH_LONG).show()
        end
      else
        pd.dismiss()
        Toast.makeText(activity, "فشل تحميل نسخة " .. edition, Toast.LENGTH_LONG).show()
      end
    end)
  end

  fetch("quran-simple", "text")
  fetch("ar.muyassar", "muyassar")
  fetch("ar.jalalayn", "jalalayn")
end

-- ==========================================
-- 🛠️ 3. UI COMPONENTS & ACCESSIBILITY HELPERS (الجديد والمطور)
-- ==========================================

function setDesign(view, colorHex, radius, strokeWidth, strokeColor)
  if not view then return end
  local drawable = GradientDrawable()
  drawable.setShape(GradientDrawable.RECTANGLE)
  drawable.setColor(Color.parseColor(colorHex))
  drawable.setCornerRadius(radius or dimens.radius)
  if strokeWidth and strokeColor then
    drawable.setStroke(strokeWidth, Color.parseColor(strokeColor))
  end
  view.setBackground(drawable)
  if Build.VERSION.SDK_INT >= 21 then view.setElevation(4) end
end

function setCircleDesign(view, colorHex)
  if not view then return end
  local drawable = GradientDrawable()
  drawable.setShape(GradientDrawable.OVAL)
  drawable.setColor(Color.parseColor(colorHex))
  view.setBackground(drawable)
  if Build.VERSION.SDK_INT >= 21 then view.setElevation(8) end
end

function setAccessibility(view, description, role)
  if not view then return end
  if description then view.setContentDescription(description) end
  if role == "heading" and Build.VERSION.SDK_INT >= 28 then
    view.setAccessibilityHeading(true)
  end
end

function announceAccess(text)
  local manager = activity.getSystemService(Context.ACCESSIBILITY_SERVICE)
  if manager and manager.isEnabled() then
    local event = AccessibilityEvent.obtain(AccessibilityEvent.TYPE_ANNOUNCEMENT)
    event.getText().add(text)
    manager.sendAccessibilityEvent(event)
  end
end

-- دالة تصنع تدرج لوني إسلامي مبهج (Gradient)
function setGradientDesign(view, colorStart, colorEnd, radius)
  if not view then return end
  local colors = {Color.parseColor(colorStart), Color.parseColor(colorEnd)}
  local drawable = GradientDrawable(GradientDrawable.Orientation.TL_BR, colors)
  drawable.setCornerRadius(radius or 16)
  view.setBackground(drawable)
  if Build.VERSION.SDK_INT >= 21 then view.setElevation(6) end
end

-- 🌟 المكونات الذكية (Smart Components) لتخفيف الكود
local function MenuCard(cardId, iconId, textId, iconSrc, title)
  return {
    LinearLayout,
    id = cardId,
    orientation = "vertical",
    layout_width = "0",
    layout_height = "fill",
    layout_weight = 1,
    gravity = "center",
    layout_margin = "8dp",
    padding = "16dp", -- مسافة داخلية ليتنفس الكارت
    {
      -- حاوية دائرية للأيقونة
      LinearLayout,
      id = cardId .. "_icon_bg",
      layout_width = "64dp",
      layout_height = "64dp",
      gravity = "center",
      { ImageView, src = iconSrc, layout_width = "36dp", layout_height = "36dp", id = iconId }
    },
    { TextView, text = title, textSize = "18sp", style = "bold", layout_marginTop = "16dp", id = textId }
  }
end

local function IndexButton(btnId, title, action)
  return {
    Button, id = btnId, text = title, layout_width = "fill", layout_marginBottom = "12dp", onClick = action
  }
end

-- دالة مركزية لتصميم أي عنصر في أي قائمة (سور، أذكار، راديو)
function getStandardListItem()
  local colors = theme.colors
  return {
    LinearLayout, layout_width = "fill", padding = "6dp",
    {
      LinearLayout, orientation = "vertical", layout_width = "fill", padding = "16dp", backgroundColor = Color.parseColor(colors.card_bg), elevation = "2dp",
      { TextView, id = "tv_title", textSize = "20sp", style = "bold", textColor = Color.parseColor(colors.text_title), gravity = "right" },
      { TextView, id = "tv_subtitle", textSize = "14sp", textColor = Color.parseColor(colors.primary), layout_marginTop = "4dp", gravity = "right" }
    }
  }
end

-- ==========================================
-- 📱 4. LAYOUT STRUCTURE (الهيكل النظيف)
-- ==========================================

layout = {
  LinearLayout,
  orientation = "vertical",
  layout_width = "fill",
  layout_height = "fill",
  id = "rootLayout",
  
  --[TOOLBAR]
  {
    LinearLayout, layout_width = "fill", padding = "16dp", id = "toolbarLayout", gravity = "center_vertical", elevation = "4dp",
    { TextView, text = "تطبيق القرآن الكريم", textSize = "24sp", style = "bold", layout_weight = 1, id = "toolbar_title" },
    { ImageView, id = "btn_search", src = "@android:drawable/ic_menu_search", layout_width = "32dp", layout_height = "32dp", colorFilter = "#FFFFFF", layout_marginRight = "12dp", onClick = function() toggleSearch() end },
    { ImageView, src = "@android:drawable/ic_menu_day", layout_width = "32dp", layout_height = "32dp", colorFilter = "#FFFFFF", id = "btn_theme", layout_marginRight = "12dp", onClick = function() toggleDarkMode() end },
    { ImageView, src = "@android:drawable/ic_input_get", layout_width = "32dp", layout_height = "32dp", colorFilter = "#FFFFFF", id = "btn_bookmarks", layout_marginRight = "12dp", onClick = function() showBookmarksDialog() end },
    { ImageView, src = "@android:drawable/ic_menu_manage", layout_width = "32dp", layout_height = "32dp", colorFilter = "#FFFFFF", id = "btn_settings", onClick = function() showSettingsDialog() end }
  },

  --[MAIN CONTENT FLIPPER]
  {
    ViewFlipper,
    id = "mainFlipper",
    layout_width = "fill",
    layout_height = "fill",

    -- PAGE 0: MAIN MENU (الواجهة المبهجة الجديدة)
    {
      LinearLayout, orientation = "vertical", layout_width = "fill", layout_height = "fill", id = "mainMenuPage",
      { ScrollView, layout_width = "fill", layout_height = "fill", fillViewport = true, {
        LinearLayout, orientation = "vertical", layout_width = "fill", layout_height = "fill", padding = "16dp",

        -- البانر الإسلامي الترحيبي (Hero Banner)
        {
          LinearLayout, id = "welcomeBanner", orientation = "vertical", layout_width = "fill", padding = "24dp", layout_marginBottom = "24dp", gravity = "center",
          { TextView, id = "bismillahText", text = "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ", textSize = "24sp", style = "bold", layout_marginBottom = "8dp" },
          { TextView, id = "quoteText", text = "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ", textSize = "16sp" }
        },

        -- شبكة الكروت (Cards Grid) - تم تنظيفها ودمجها
        { LinearLayout, orientation = "horizontal", layout_width = "fill", layout_height = "150dp",
          MenuCard("btnGoQuranMain", "imgQuranMain", "txtQuranMain", "@android:drawable/ic_menu_book", "القرآن الكريم"),
          MenuCard("btnGoAzkar", "imgAzkar", "txtAzkar", "@android:drawable/btn_star_big_on", "الأذكار")
        },
        { LinearLayout, orientation = "horizontal", layout_width = "fill", layout_height = "150dp",
          MenuCard("btnGoRadio", "imgRadio", "txtRadio", "@android:drawable/ic_lock_silent_mode_off", "الراديو"),
          { View, layout_width = "0", layout_height = "fill", layout_weight = 1, layout_margin = "8dp" }
        },

        -- بطاقة الاستئناف
        {
          LinearLayout, id = "resumeCard", orientation = "vertical", layout_width = "fill", padding = "16dp", layout_marginTop = "20dp", visibility = View.GONE,
          { TextView, id = "resumeTitle", text = "مواصلة القراءة", textSize = "18sp", style = "bold" },
          { TextView, id = "resumeInfo", text = "", textSize = "16sp", layout_marginTop = "4dp" },
          { Button, id = "btnResume", text = "متابعة من حيث توقفت", layout_width = "fill", layout_marginTop = "12dp", onClick = function() resumeLastProgress() end }
        },
      }}
    },
    
    -- PAGE 1: LIST VIEW
    {
      FrameLayout, layout_width = "fill", layout_height = "fill",
      {
        LinearLayout, id = "surahListContainer", orientation = "vertical", layout_width = "fill", padding = "12dp", visibility = View.GONE,
        { TextView, id = "listTitle", text = "القائمة", textSize = "20sp", style = "bold", layout_marginBottom = "8dp", visibility = View.GONE },
        { EditText, id = "searchEdt", hint = "بحث...", layout_width = "fill", padding = "16dp", textSize = "18sp", singleLine = true, layout_marginBottom = "12dp" },
        { ListView, id = "surahList", layout_width = "fill", layout_height = "fill", dividerHeight = "0", selector = ColorDrawable(0), clipToPadding = false, paddingBottom = "24dp" }
      },
      { ProgressBar, id = "loadingIndicator", layout_width = "wrap_content", layout_height = "wrap_content", layout_gravity = "center", visibility = View.VISIBLE },
      {
        LinearLayout, id = "errorContainer", orientation = "vertical", layout_width = "fill", layout_height = "fill", gravity = "center", padding = "24dp", visibility = View.GONE,
        { TextView, id = "errorText", text = "حدث خطأ أثناء تحميل البيانات.\nيرجى التحقق من اتصالك بالإنترنت.", textSize = "18sp", gravity = "center", layout_marginBottom = "16dp" },
        { Button, id = "btnRetry", text = "إعادة المحاولة", layout_width = "wrap_content", paddingLeft = "32dp", paddingRight = "32dp", onClick = function() loadSurahs() end }
      }
    },

    -- PAGE 2: PLAYER / READING MODE
    {
      LinearLayout, orientation = "vertical", layout_width = "fill", layout_height = "fill", padding = "16dp", gravity = "center_horizontal", id = "playerPage",
      { ImageView, id = "sectionIcon", layout_width = "80dp", layout_height = "80dp", layout_marginTop = "10dp", layout_marginBottom = "10dp", visibility = View.GONE },
      {
        LinearLayout, orientation = "horizontal", layout_width = "fill", gravity = "center_vertical", layout_marginBottom = "8dp",
        { TextView, id = "playerTitle", text = "...", textSize = "24sp", style = "bold", layout_weight = 1, gravity = "center" },
        { ImageView, src = "@android:drawable/ic_menu_more", layout_width = "36dp", layout_height = "36dp", id = "btnMoreOptions", onClick = function() showAyahOptions(player.currentAyahIndex) end }
      },
      { TextView, id = "reciterNameDisplay", text = "...", textSize = "16sp", gravity = "center", layout_marginBottom = "16dp" },
      {
        FrameLayout, layout_width = "fill", layout_height = "0", layout_weight = 1,
        { LinearLayout, id = "ayahCard", layout_width = "fill", layout_height = "fill", gravity = "center", padding = "8dp", { ScrollView, layout_width = "fill", layout_height = "wrap_content", fillViewport = true, { TextView, id = "ayahText", text = "...", textSize = config.font_size .. "sp", gravity = "center", typeface = Typeface.DEFAULT_BOLD, padding = "16dp" } } },
        { ListView, id = "continuousListView", layout_width = "fill", layout_height = "fill", dividerHeight = "0", visibility = View.GONE }
      },
      { LinearLayout, id = "progressContainer", orientation = "horizontal", layout_width = "fill", gravity = "center", layout_marginTop = "8dp", { TextView, id = "progressText", text = "0 / 0", textSize = "14sp", gravity = "center" } },
      {
        LinearLayout, id = "controlsContainer", orientation = "vertical", layout_width = "fill", gravity = "center", layout_marginTop = "12dp",
        { TextView, id = "statusText", text = "جاهز", textSize = "16sp", gravity = "center", layout_marginBottom = "16dp", style = "bold" },
        {
          LinearLayout, orientation = "horizontal", layout_width = "fill", gravity = "center",
          { Button, text = "السابق", id = "btnPrev", layout_width = "90dp", textColor = "#FFFFFF", style = "bold", onClick = function() playPrev() end },
          { Button, text = "▶", id = "btnPlay", layout_width = "70dp", layout_height = "70dp", textSize = "30sp", layout_marginLeft = "20dp", layout_marginRight = "20dp", onClick = function() togglePlay() end },
          { Button, text = "التالي", id = "btnNext", layout_width = "90dp", textColor = "#FFFFFF", style = "bold", onClick = function() playNext() end }
        }
      },
      { Button, text = "عودة للقائمة", id = "btnBack", layout_marginTop = "16dp", elevation = "0", onClick = function() stopAudio(); mainFlipper.setDisplayedChild(lastIndex or 1) end }
    },

    -- PAGE 3: INDEX TYPE SELECTION (تم تبسيطه)
    {
      LinearLayout, orientation = "vertical", layout_width = "fill", layout_height = "fill", padding = "24dp", gravity = "center", id = "indexTypePage",
      { TextView, text = "اختر طريقة التصفح", textSize = "24sp", style = "bold", layout_marginBottom = "30dp", id = "indexTitle" },
      IndexButton("btnIndexSurah", "السور", function() showQuranList("surahs") end),
      IndexButton("btnIndexJuz", "الأجزاء", function() showQuranList("juzs") end),
      IndexButton("btnIndexPage", "الصفحات", function() showQuranList("pages") end),
      IndexButton("btnIndexRub", "أرباع الأحزاب", function() showQuranList("rubs") end),
      { Button, text = "عودة", id = "btnBackFromIndex", layout_marginTop = "20dp", onClick = function() mainFlipper.setDisplayedChild(4) end },
    },

    -- PAGE 4: QURAN HUB (المركز الجديد للقرآن)
    {
      LinearLayout, orientation = "vertical", layout_width = "fill", layout_height = "fill", padding = "24dp", gravity = "center", id = "quranHubPage",
      { TextView, text = "القرآن الكريم", textSize = "28sp", style = "bold", layout_marginBottom = "32dp", id = "quranHubTitle" },
      {
        LinearLayout, orientation = "horizontal", layout_width = "fill", layout_height = "160dp",
        MenuCard("btnHubRead", "imgHubRead", "txtHubRead", "@android:drawable/ic_menu_book", "قراءة وتصفح"),
        MenuCard("btnHubListen", "imgHubListen", "txtHubListen", "@android:drawable/ic_lock_silent_mode", "استماع للقراء")
      },
      {
        LinearLayout, orientation = "horizontal", layout_width = "fill", layout_height = "160dp",
        MenuCard("btnHubMemorize", "imgHubMemorize", "txtHubMemorize", "@android:drawable/ic_btn_speak_now", "المحفظ المعلم"),
        { View, layout_width = "0", layout_height = "fill", layout_weight = 1, layout_margin = "8dp" }
      },
      { Button, text = "عودة للقائمة الرئيسية", id = "btnBackFromHub", layout_marginTop = "24dp", onClick = function() mainFlipper.setDisplayedChild(0) end },
    }
  }
}

-- ==========================================
-- 🚀 5. MAIN EXECUTION & STYLING
-- ==========================================

activity.setContentView(loadlayout(layout))

local isContinuousMode = false

function applyTheme()
  local colors = theme.colors
  rootLayout.setBackgroundColor(Color.parseColor(colors.background))
  setDesign(toolbarLayout, colors.primary, 0)

  -- Main Menu Styling (Cards)
  if welcomeBanner then
    if currentThemeMode == "dark" then
      setGradientDesign(welcomeBanner, colors.primary_dark, "#000000", dimens.radius)
    else
      setGradientDesign(welcomeBanner, colors.primary, colors.primary_dark, dimens.radius)
    end
  end
  if bismillahText then bismillahText.setTextColor(Color.parseColor(colors.text_white)) end
  if quoteText then quoteText.setTextColor(Color.parseColor(colors.accent)) end

  -- تلوين دوائر الأيقونات داخل الكروت (لون شفاف خفيف من الـ Primary)
  local softIconBgColor = currentThemeMode == "dark" and "#2680CBC4" or "#2600695C" -- لون شبه شفاف
  if btnGoQuranMain_icon_bg then setCircleDesign(btnGoQuranMain_icon_bg, softIconBgColor) end
  if btnGoAzkar_icon_bg then setCircleDesign(btnGoAzkar_icon_bg, softIconBgColor) end
  if btnGoRadio_icon_bg then setCircleDesign(btnGoRadio_icon_bg, softIconBgColor) end

  if btnHubRead_icon_bg then setCircleDesign(btnHubRead_icon_bg, softIconBgColor) end
  if btnHubListen_icon_bg then setCircleDesign(btnHubListen_icon_bg, softIconBgColor) end
  if btnHubMemorize_icon_bg then setCircleDesign(btnHubMemorize_icon_bg, softIconBgColor) end

  local strokeColor = colors.primary .. "4D" -- 30% opacity of primary color
  setDesign(btnGoQuranMain, colors.card_bg, dimens.radius, 3, strokeColor)
  setDesign(btnGoAzkar, colors.card_bg, dimens.radius, 3, strokeColor)
  setDesign(btnGoRadio, colors.card_bg, dimens.radius, 3, strokeColor)

  setDesign(btnHubRead, colors.card_bg, dimens.radius, 3, strokeColor)
  setDesign(btnHubListen, colors.card_bg, dimens.radius, 3, strokeColor)
  setDesign(btnHubMemorize, colors.card_bg, dimens.radius, 3, strokeColor)
  if btnBackFromHub then btnBackFromHub.setBackgroundColor(0); btnBackFromHub.setTextColor(Color.parseColor(colors.text_body)) end
  if quranHubTitle then quranHubTitle.setTextColor(Color.parseColor(colors.text_title)) end

  if txtQuranMain then txtQuranMain.setTextColor(Color.parseColor(colors.text_title)) end
  if txtAzkar then txtAzkar.setTextColor(Color.parseColor(colors.text_title)) end
  if txtRadio then txtRadio.setTextColor(Color.parseColor(colors.text_title)) end

  if txtHubRead then txtHubRead.setTextColor(Color.parseColor(colors.text_title)) end
  if txtHubListen then txtHubListen.setTextColor(Color.parseColor(colors.text_title)) end
  if txtHubMemorize then txtHubMemorize.setTextColor(Color.parseColor(colors.text_title)) end

  if imgQuranMain then imgQuranMain.setColorFilter(Color.parseColor(colors.primary)) end
  if imgAzkar then imgAzkar.setColorFilter(Color.parseColor(colors.primary)) end
  if imgRadio then imgRadio.setColorFilter(Color.parseColor(colors.primary)) end

  if imgHubRead then imgHubRead.setColorFilter(Color.parseColor(colors.primary)) end
  if imgHubListen then imgHubListen.setColorFilter(Color.parseColor(colors.primary)) end
  if imgHubMemorize then imgHubMemorize.setColorFilter(Color.parseColor(colors.primary)) end

  local function addLongClick(v, t)
    if not v then return end
    v.onLongClick = function() announceAccess(t); return true end
  end
  addLongClick(btnGoQuranMain, "قسم القرآن الكريم: تصفح، استماع، وتحفيظ")
  addLongClick(btnGoAzkar, "قسم الأذكار وحصن المسلم")
  addLongClick(btnGoRadio, "قسم إذاعات القرآن الكريم المباشرة")

  addLongClick(btnHubRead, "تصفح وقراءة القرآن الكريم")
  addLongClick(btnHubListen, "الاستماع للقرآن الكريم كاملاً")
  addLongClick(btnHubMemorize, "المحفظ لتعليم وحفظ القرآن")

  if btnBackFromIndex then addLongClick(btnBackFromIndex, "العودة للقائمة السابقة") end
  if btnBack then addLongClick(btnBack, "العودة لقائمة السور أو الأقسام") end
  if btnPlay then addLongClick(btnPlay, "تشغيل أو إيقاف المقطع الصوتي") end
  if btnNext then addLongClick(btnNext, "الذهاب للآية أو العنصر التالي") end
  if btnPrev then addLongClick(btnPrev, "العودة للآية أو العنصر السابق") end

  -- Index Page Styling
  if indexTitle then indexTitle.setTextColor(Color.parseColor(colors.text_title)) end
  setDesign(btnIndexSurah, colors.card_bg, dimens.radius)
  btnIndexSurah.setTextColor(Color.parseColor(colors.text_title))
  setDesign(btnIndexJuz, colors.card_bg, dimens.radius)
  btnIndexJuz.setTextColor(Color.parseColor(colors.text_title))
  setDesign(btnIndexPage, colors.card_bg, dimens.radius)
  btnIndexPage.setTextColor(Color.parseColor(colors.text_title))
  setDesign(btnIndexRub, colors.card_bg, dimens.radius)
  btnIndexRub.setTextColor(Color.parseColor(colors.text_title))
  if btnBackFromIndex then btnBackFromIndex.setBackgroundColor(0); btnBackFromIndex.setTextColor(Color.parseColor(colors.text_body)) end

  setDesign(resumeCard, colors.card_bg, dimens.radius)
  if resumeTitle then resumeTitle.setTextColor(Color.parseColor(colors.text_title)) end
  if resumeInfo then resumeInfo.setTextColor(Color.parseColor(colors.text_body)) end
  if listTitle then listTitle.setTextColor(Color.parseColor(colors.primary)) end
  setDesign(btnResume, colors.accent, 24)
  setDesign(searchEdt, colors.card_bg, dimens.radius)
  searchEdt.setTextColor(Color.parseColor(colors.text_title))
  searchEdt.setHintTextColor(Color.parseColor(colors.text_body))
  setDesign(ayahCard, colors.card_bg, dimens.radius)
  if playerTitle then playerTitle.setTextColor(Color.parseColor(colors.primary)) end
  if reciterNameDisplay then reciterNameDisplay.setTextColor(Color.parseColor(colors.text_body)) end
  if ayahText then ayahText.setTextColor(Color.parseColor(colors.text_title)) end
  if statusText then statusText.setTextColor(Color.parseColor(colors.primary)) end
  if progressText then progressText.setTextColor(Color.parseColor(colors.text_body)) end
  setDesign(btnPrev, colors.primary, 24)
  setDesign(btnNext, colors.primary, 24)
  setCircleDesign(btnPlay, colors.accent)
  btnPlay.setTextColor(Color.parseColor(colors.text_title))
  if btnBack then btnBack.setBackgroundColor(0); btnBack.setTextColor(Color.parseColor(colors.text_body)) end
  if btnMoreOptions then btnMoreOptions.setColorFilter(Color.parseColor(colors.primary)) end
  
  if continuousListView then continuousListView.setBackgroundColor(Color.parseColor(colors.card_bg)) end

  if showResumeCard then showResumeCard() end

  if errorText then errorText.setTextColor(Color.parseColor(colors.error_text)) end
  if btnRetry then setDesign(btnRetry, colors.primary, 24); btnRetry.setTextColor(Color.parseColor(colors.text_white)) end
  
  if btn_theme then
    if currentThemeMode == "dark" then btn_theme.setImageResource(android.R.drawable.ic_menu_day)
    else btn_theme.setImageResource(android.R.drawable.ic_menu_day) end
  end
  if allSurahsData and #allSurahsData > 0 then updateList("") end
  
  local modeName = currentThemeMode == "dark" and "الوضع الداكن" or "الوضع الفاتح"
  announceAccess("تم تفعيل " .. modeName)
end


-- ==========================================
-- 🌙 6. DARK MODE FEATURE (ميزة 1)
-- ==========================================

function toggleDarkMode()
  if currentThemeMode == "light" then
    currentThemeMode = "dark"; theme = themes.dark; config.dark_mode = true
  else
    currentThemeMode = "light"; theme = themes.light; config.dark_mode = false
  end
  applyTheme()
  saveAppData()
  local msg = currentThemeMode == "dark" and "تم تفعيل الوضع الداكن" or "تم تفعيل الوضع الفاتح"
  Toast.makeText(activity, msg, Toast.LENGTH_SHORT).show()
end

function toggleSearch()
  if mainFlipper.getDisplayedChild() ~= 1 then
    lastIndex = mainFlipper.getDisplayedChild()
    mainFlipper.setDisplayedChild(1)
    if listTitle then listTitle.text = "البحث السريع" end
    if searchEdt then
      searchEdt.requestFocus()
      local imm = activity.getSystemService(Context.INPUT_METHOD_SERVICE)
      -- Use pcall and fallback to constant to prevent crash if class not found
      pcall(function()
        imm.showSoftInput(searchEdt, InputMethodManager.SHOW_IMPLICIT or 1)
      end)
    end
  else
    mainFlipper.setDisplayedChild(lastIndex or 0)
  end
end

-- ==========================================
-- 🔖 7. BOOKMARKS FEATURE (ميزة 2)
-- ==========================================

function addCurrentBookmark()
  if not player.currentSurahData or player.currentAyahIndex < 1 then
    Toast.makeText(activity, "لا توجد آية محددة", Toast.LENGTH_SHORT).show()
    return
  end
  local ayah = player.currentSurahData[player.currentAyahIndex]
  local bookmarkId = player.currentSurahNumber .. "_" .. ayah.numberInSurah
  for i, b in ipairs(bookmarks) do
    if b.id == bookmarkId then
      Toast.makeText(activity, "هذه الآية محفوظة مسبقاً", Toast.LENGTH_SHORT).show()
      return
    end
  end
  local newBookmark = {
    id = bookmarkId, surahNumber = player.currentSurahNumber, surahName = player.currentSurahName,
    ayahNumber = ayah.numberInSurah, ayahText = string.sub(ayah.text, 1, 100) .. "...", timestamp = os.time()
  }
  table.insert(bookmarks, 1, newBookmark)
  while #bookmarks > 50 do table.remove(bookmarks) end
  saveAppData()
  Toast.makeText(activity, "تمت إضافة الإشارة المرجعية ✔", Toast.LENGTH_SHORT).show()
  announceAccess("تمت إضافة إشارة مرجعية للآية " .. ayah.numberInSurah)
end

function showBookmarksDialog()
  if #bookmarks == 0 then
    Toast.makeText(activity, "لا توجد إشارات مرجعية محفوظة", Toast.LENGTH_SHORT).show()
    return
  end
  local items = {}
  for i, b in ipairs(bookmarks) do table.insert(items, b.surahName .. " - الآية " .. b.ayahNumber) end
  local builder = AlertDialog.Builder(activity)
  builder.setTitle("📑 الإشارات المرجعية")
  builder.setItems(items, DialogInterface.OnClickListener{
    onClick = function(dialog, which)
      loadSurahFromBookmark(bookmarks[which + 1])
    end
  })
  builder.setNeutralButton("حذف الكل", function() showDeleteAllBookmarksConfirm() end)
  builder.setNegativeButton("إغلاق", nil)
  builder.show()
end

function showDeleteAllBookmarksConfirm()
  local builder = AlertDialog.Builder(activity)
  builder.setTitle("تأكيد الحذف")
  builder.setMessage("هل تريد حذف جميع الإشارات المرجعية؟")
  builder.setPositiveButton("نعم، احذف الكل", function() bookmarks = {}; saveAppData(); Toast.makeText(activity, "تم حذف جميع الإشارات", Toast.LENGTH_SHORT).show() end)
  builder.setNegativeButton("إلغاء", nil)
  builder.show()
end

function loadSurahFromBookmark(bookmark)
  loadSurahDetails(bookmark.surahNumber, bookmark.ayahNumber, bookmark.ayahNumber + 10)
end

-- ==========================================
-- 📤 8. SHARE FEATURE (ميزة 3)
-- ==========================================

function shareCurrentAyah()
  if not player.currentSurahData or player.currentAyahIndex < 1 then
    Toast.makeText(activity, "لا توجد آية للمشاركة", Toast.LENGTH_SHORT).show()
    return
  end
  local ayah = player.currentSurahData[player.currentAyahIndex]
  local shareText = "﴿ " .. ayah.text .. " ﴾\n\n" .. "📖 " .. player.currentSurahName .. " - الآية " .. ayah.numberInSurah .. "\n" .. "───────────────\n" .. "📱 من تطبيق المحفظ القرآني"
  local intent = Intent(Intent.ACTION_SEND)
  intent.setType("text/plain")
  intent.putExtra(Intent.EXTRA_TEXT, shareText)
  activity.startActivity(Intent.createChooser(intent, "مشاركة الآية عبر..."))
end

-- ==========================================
-- 💾 9. AUTO SAVE PROGRESS (ميزة 4)
-- ==========================================

function saveCurrentProgress()
  if not config.auto_save_progress or not player.currentSurahData or player.currentAyahIndex < 1 then return end
  local ayah = player.currentSurahData[player.currentAyahIndex]
  lastProgress = { surahNumber = player.currentSurahNumber, surahName = player.currentSurahName, ayahNumber = ayah.numberInSurah }
  saveAppData()
end

function showResumeCard()
  if lastProgress.surahNumber and lastProgress.ayahNumber then
    resumeCard.setVisibility(View.VISIBLE)
    resumeInfo.text = "سورة " .. lastProgress.surahName .. " - الآية " .. lastProgress.ayahNumber
    setAccessibility(resumeCard, "بطاقة استئناف الحفظ: " .. resumeInfo.text, nil)
  else
    resumeCard.setVisibility(View.GONE)
  end
end

function resumeLastProgress()
  if lastProgress.surahNumber and lastProgress.ayahNumber then
    loadSurahDetails(lastProgress.surahNumber, lastProgress.ayahNumber, lastProgress.ayahNumber + 20)
  end
end

-- ==========================================
-- ⚙ 10. CORE LOGIC & FUNCTIONS
-- ==========================================

function setMainViewState(state) -- "loading", "error", "content"
  if state == "loading" then
    loadingIndicator.setVisibility(View.VISIBLE)
    errorContainer.setVisibility(View.GONE)
    surahListContainer.setVisibility(View.GONE)
    announceAccess("جاري تحميل البيانات، يرجى الانتظار")
  elseif state == "error" then
    loadingIndicator.setVisibility(View.GONE)
    errorContainer.setVisibility(View.VISIBLE)
    surahListContainer.setVisibility(View.GONE)
    announceAccess("حدث خطأ أثناء تحميل البيانات، يرجى التحقق من الإنترنت وإعادة المحاولة")
  elseif state == "content" then
    loadingIndicator.setVisibility(View.GONE)
    errorContainer.setVisibility(View.GONE)
    surahListContainer.setVisibility(View.VISIBLE)
    announceAccess("تم تحميل القائمة بنجاح، يمكنك التصفح الآن")
  end
end

function httpGet(url, callback)
  Http.get(url, function(code, body)
    if code == 200 and body then 
      callback(true, body) 
    elseif code == -1 then
      callback(false, "لا يوجد اتصال بالإنترنت")
    else 
      callback(false, "خطأ من الخادم: " .. tostring(code))
    end
  end)
end

function loadSurahs()
  -- Attempt to load from offline data first
  if quranOfflineData and quranOfflineData.text then
    local surahs = quranOfflineData.text.surahs
    currentSurahsList = {}
    for i, s in ipairs(surahs) do
      table.insert(currentSurahsList, {
        title = s.number .. ". " .. s.name,
        subtitle = s.englishName .. " | " .. #s.ayahs .. " آية",
        number = s.number,
        numberOfAyahs = #s.ayahs,
        englishName = s.englishName
      })
    end
    allSurahsData = currentSurahsList
    updateList("")
    showResumeCard()
    setMainViewState("content")
    return
  end

  setMainViewState("loading")

  local url = BaseURL .. "/surah"
  httpGet(url, function(success, body)
    if success then
      local decode_ok, json = pcall(cjson.decode, body)
      if decode_ok and json.code == 200 then
        local data = json.data
        currentSurahsList = {}
        for i = 1, #data do
          table.insert(currentSurahsList, {
            title = data[i].number .. ". " .. data[i].name,
            subtitle = data[i].englishName .. " | " .. data[i].numberOfAyahs .. " آية",
            number = data[i].number,
            numberOfAyahs = data[i].numberOfAyahs, 
            englishName = data[i].name
          })
        end
        allSurahsData = currentSurahsList
        updateList("")
        showResumeCard()
        setMainViewState("content")
      else
        setMainViewState("error")
        errorText.text = "فشل في تحليل البيانات (JSON Error)"
      end
    else
      setMainViewState("error")
      errorText.text = "فشل في التحميل: " .. tostring(body)
    end
  end)
end

function updateList(filter)
  local listData, filteredSurahs = {}, {}
  local itemLayout = getStandardListItem()

  local f = filter or ""
  local dataSource = (currentViewType == "surahs" or currentViewType == "quran_reading" or currentViewType == "memorization") and currentSurahsList or allSurahsData

  if currentViewType == "juzs" or currentViewType == "pages" or currentViewType == "hizbs" or currentViewType == "rubs" then
    dataSource = allSurahsData
  end

  for i = 1, #dataSource do
    local s = dataSource[i]
    if f == "" or string.find(s.title, f, 1, true) or (s.number and string.find(tostring(s.number), f, 1, true)) then
      table.insert(filteredSurahs, s)
      table.insert(listData, { tv_title = s.title, tv_subtitle = s.subtitle })
    end
  end

  local adapter = LuaAdapter(activity, listData, itemLayout)
  surahList.setAdapter(adapter)

  surahList.setOnItemClickListener(AdapterView.OnItemClickListener{
    onItemClick = function(parent, view, position, id)
      local item = filteredSurahs[position + 1]
      if currentViewType == "memorization" then
        showRangeSelectionDialog(item) -- يفتح واجهة تحديد الآيات للحفظ فقط
      elseif currentViewType == "surahs" or currentViewType == "juzs" or currentViewType == "pages" or currentViewType == "hizbs" or currentViewType == "rubs" or currentViewType == "quran_reading" then
        handleDivisionClick(item) -- يفتح القراءة مباشرة للتصفح
      elseif currentViewType == "azkar_categories" then
        showAzkarContent(item.index)
      end
    end
  })
end

function handleDivisionClick(item)
  if currentViewType == "surahs" or currentViewType == "quran_reading" then
    loadSurahDetails(item.number, 1, item.numberOfAyahs)
  elseif currentViewType == "juzs" then
    loadDivisionDetails("juz", item.number)
  elseif currentViewType == "pages" then
    loadDivisionDetails("page", item.number)
  elseif currentViewType == "rubs" then
    loadDivisionDetails("hizbQuarter", item.number)
  elseif currentViewType == "hizbs" then
    loadDivisionDetails("hizb", item.number)
  end
end

function loadDivisionDetails(type, number)
  setMainViewState("loading")
  -- Try offline first
  if quranOfflineData and quranOfflineData.text then
    local dText = quranOfflineData.text
    local dT1 = quranOfflineData.muyassar
    local dT2 = quranOfflineData.jalalayn

    player.currentSurahData = {}

    local titlePrefix = ""
    if type == "juz" then titlePrefix = "الجزء "
    elseif type == "page" then titlePrefix = "صفحة "
    elseif type == "hizbQuarter" then titlePrefix = "الربع "
    elseif type == "hizb" then titlePrefix = "الحزب " end

    player.currentSurahName = titlePrefix .. number
    player.currentSurahNumber = number

    for sIdx, surah in ipairs(dText.surahs) do
      for aIdx, ayah in ipairs(surah.ayahs) do
        local match = false
        if type == "juz" and ayah.juz == number then match = true
        elseif type == "page" and ayah.page == number then match = true
        elseif type == "hizbQuarter" and ayah.hizbQuarter == number then match = true
        -- The offline data has `hizbQuarter`. There are 4 quarters per hizb, so hizb 1 has quarters 1,2,3,4.
        -- We calculate hizb from hizbQuarter: math.ceil(ayah.hizbQuarter / 4)
        elseif type == "hizb" and math.ceil((ayah.hizbQuarter or 1) / 4) == number then match = true
        end

        if match then
          table.insert(player.currentSurahData, {
            text = ayah.text,
            audio = "https://cdn.islamic.network/quran/audio/128/" .. config.current_reciter .. "/" .. tostring(math.floor(tonumber(ayah.number) or 1)) .. ".mp3",
            numberInSurah = ayah.numberInSurah,
            surahName = surah.name,
            tafsir = dT1 and dT1.surahs[sIdx] and dT1.surahs[sIdx].ayahs[aIdx] and dT1.surahs[sIdx].ayahs[aIdx].text,
            tafsir2 = dT2 and dT2.surahs[sIdx] and dT2.surahs[sIdx].ayahs[aIdx] and dT2.surahs[sIdx].ayahs[aIdx].text
          })
        end
      end
    end

    if #player.currentSurahData > 0 then
      setMainViewState("content")
      lastIndex = mainFlipper.getDisplayedChild()
      mainFlipper.setDisplayedChild(2)
      setupPlayer(1)
      return
    end
  end

  local url = BaseURL .. "/" .. type .. "/" .. number .. "/" .. config.current_reciter
  local pd = ProgressDialog.show(activity, "يرجى الانتظار", "جاري جلب البيانات...", true)

  httpGet(url, function(success, body)
    pd.dismiss()
    if not success then
      Toast.makeText(activity, "خطأ في الاتصال", Toast.LENGTH_LONG).show()
      return
    end

    local decode_ok, json = pcall(cjson.decode, body)
    if decode_ok and json.code == 200 and json.data then
      local data = json.data
      player.currentSurahData = {}
      local typeName = (type == "juz" and "الجزء " or (type == "page" and "صفحة " or "الربع "))
      player.currentSurahName = typeName .. number
      player.currentSurahNumber = number

      local ayahs = data.ayahs
      for i=1, #ayahs do
        table.insert(player.currentSurahData, {
          text = ayahs[i].text,
          audio = ayahs[i].audio,
          numberInSurah = ayahs[i].numberInSurah,
          surahName = ayahs[i].surah.name,
          tafsir = "التفسير متوفر في وضع الأوفلاين حالياً لهذه الأقسام."
        })
      end

      if #player.currentSurahData > 0 then
        lastIndex = mainFlipper.getDisplayedChild()
        mainFlipper.setDisplayedChild(2)
        setupPlayer(1)
      end
    else
      Toast.makeText(activity, "خطأ في تحليل البيانات", Toast.LENGTH_LONG).show()
    end
  end)
end

function showMemorizationSection()
  currentViewType = "memorization"
  listTitle.setVisibility(View.VISIBLE)
  listTitle.text = "المحفظ القرآني - اختر سورة"
  mainFlipper.setDisplayedChild(1)
  loadSurahs()
end

function showQuranSection()
  mainFlipper.setDisplayedChild(3) -- Index Type Selection
  announceAccess("اختر طريقة تصفح القرآن الكريم")
end

function showQuranList(type)
  currentViewType = type
  listTitle.setVisibility(View.VISIBLE)
  if searchEdt then searchEdt.text = ""; searchEdt.setHint("بحث...") end
  mainFlipper.setDisplayedChild(1)

  if type == "surahs" then
    listTitle.text = "القرآن الكريم - السور"
    loadSurahs()
  elseif type == "juzs" then
    listTitle.text = "القرآن الكريم - الأجزاء"
    loadJuzs()
  elseif type == "pages" then
    listTitle.text = "القرآن الكريم - الصفحات"
    loadPages()
  elseif type == "rubs" then
    listTitle.text = "القرآن الكريم - أرباع الأحزاب"
    loadRubs()
  end
end

function loadJuzs()
  if not (quranOfflineData and quranOfflineData.text) then setMainViewState("loading") end
  local juzs = {}
  for i=1, 30 do
    table.insert(juzs, {
      title = "الجزء " .. i,
      subtitle = "تصفح الجزء رقم " .. i,
      number = i,
      type = "juz"
    })
  end
  allSurahsData = juzs
  updateList("")
  setMainViewState("content")
end

function loadRubs()
  if not (quranOfflineData and quranOfflineData.text) then setMainViewState("loading") end
  local rubs = {}
  for i=1, 240 do
    table.insert(rubs, {
      title = "الربع " .. i,
      subtitle = "تصفح الربع رقم " .. i,
      number = i,
      type = "rub"
    })
  end
  allSurahsData = rubs
  updateList("")
  setMainViewState("content")
end

function loadPages()
  if not (quranOfflineData and quranOfflineData.text) then setMainViewState("loading") end
  local pages = {}
  -- In offline data, we can find which surah is in which page easily
  for i=1, 604 do
    local sub = "تصفح الصفحة رقم " .. i
    if quranOfflineData and quranOfflineData.text then
       for sIdx, surah in ipairs(quranOfflineData.text.surahs) do
         if surah.ayahs[1].page == i then sub = "بداية سورة " .. surah.name; break end
       end
    end
    table.insert(pages, {
      title = "صفحة " .. i,
      subtitle = sub,
      number = i,
      type = "page"
    })
  end
  allSurahsData = pages
  updateList("")
  setMainViewState("content")
end

function loadHizbs()
  if not (quranOfflineData and quranOfflineData.text) then setMainViewState("loading") end
  local hizbs = {}
  for i=1, 60 do
    table.insert(hizbs, {
      title = "الحزب " .. i,
      subtitle = "تصفح الحزب رقم " .. i,
      number = i,
      type = "hizb"
    })
  end
  allSurahsData = hizbs
  updateList("")
  setMainViewState("content")
end

function showAzkarSection()
  currentViewType = "azkar_categories"
  listTitle.setVisibility(View.VISIBLE)
  listTitle.text = "الأذكار - حصن المسلم"
  if searchEdt then searchEdt.text = ""; searchEdt.setHint("ابحث عن قسم...") end
  mainFlipper.setDisplayedChild(1)
  loadAzkarCategories()
end

function loadAzkarCategories()
  setMainViewState("loading")
  if allAzkarData and next(allAzkarData) then
    displayAzkarCategories()
    return
  end

  httpGet(AzkarURL, function(success, body)
    if success then
      local decode_ok, json = pcall(cjson.decode, body)
      if decode_ok then
        allAzkarData = json
        displayAzkarCategories()
      else
        setMainViewState("error")
      end
    else
      setMainViewState("error")
    end
  end)
end

function displayAzkarCategories()
  currentAzkarCategories = {}
  -- The new JSON is an array of objects: { category = "...", array = [...] }
  for i, data in ipairs(allAzkarData) do
    table.insert(currentAzkarCategories, {
      title = data.category,
      subtitle = (data.array and #data.array or 0) .. " ذكر",
      index = i,
      type = "azkar_category"
    })
  end
  allSurahsData = currentAzkarCategories
  updateList("")
  setMainViewState("content")
end

function showAzkarContent(categoryIndex)
  local category = allAzkarData[categoryIndex]
  if not category then return end

  currentViewType = "azkar_content"
  currentAzkarCategoryIndex = categoryIndex
  listTitle.text = category.category

  -- Add a "Play All" option if category audio exists
  currentAzkarItems = {}
  if category.audio then
    table.insert(currentAzkarItems, {
      title = "▶ تشغيل الأذكار متتالية (صوت)",
      subtitle = "استمع لجميع أذكار " .. category.category,
      isPlayAll = true,
      audio = category.audio
    })
  end

  if category.array then
    for i, item in ipairs(category.array) do
      table.insert(currentAzkarItems, {
        title = item.text,
        subtitle = "العدد المطلـوب: " .. (item.count or 1),
        zekrText = item.text,
        audio = item.audio,
        targetCount = item.count or 1,
        index = i
      })
    end
  end

  updateAzkarList("")
end

function updateAzkarList(filter)
  local listData, filteredItems = {}, {}
  local itemLayout = getStandardListItem()

  local f = filter or ""
  for i, s in ipairs(currentAzkarItems) do
    if f == "" or string.find(s.title, f, 1, true) then
      table.insert(filteredItems, s)
      table.insert(listData, { tv_title = s.title, tv_subtitle = s.subtitle })
    end
  end

  local adapter = LuaAdapter(activity, listData, itemLayout)
  surahList.setAdapter(adapter)

  surahList.setOnItemClickListener(AdapterView.OnItemClickListener{
    onItemClick = function(parent, view, position, id)
      local item = filteredItems[position + 1]
      if item.isPlayAll then
        playAzkarAudio(item.audio, item.title)
      else
        showZekrCounter(item)
      end
    end
  })
end

function playAzkarAudio(audioPath, title)
  lastIndex = mainFlipper.getDisplayedChild()
  mainFlipper.setDisplayedChild(2)

  player.isIndividualZekr = false
  player.currentSurahName = title
  player.currentSurahNumber = 0
  player.currentAyahIndex = 1
  player.currentRepeatCount = 0
  player.currentSurahData = {{ audio = AzkarAudioBaseURL .. audioPath, numberInSurah = 1, text = "استماع للأذكار" }}

  playerTitle.text = title
  reciterNameDisplay.text = "حصن المسلم"
  ayahText.text = "جاري تشغيل الأذكار متتالية..."
  statusText.text = "جاري التشغيل..."
  progressText.text = "أذكار"

  player.isPlaying = true
  setupMediaPlayer(AzkarAudioBaseURL .. audioPath)
end

function showZekrCounter(zekrItem)
  local colors = theme.colors
  local count = 0
  local views = {}

  local counterLayout = {
    LinearLayout, orientation = "vertical", padding = "24dp", layout_width = "fill", backgroundColor = Color.parseColor(colors.card_bg), gravity="center",
    {
      TextView, text = "المسبحة الإلكترونية", textSize = "18sp", textColor = Color.parseColor(colors.primary), layout_marginBottom = "16dp"
    },
    { ScrollView, layout_width="fill", layout_height="180dp", layout_marginBottom="20dp",
      { TextView, text = zekrItem.zekrText, textSize = "22sp", style = "bold", textColor = Color.parseColor(colors.text_title), gravity = "center" }
    },
    {
      LinearLayout, orientation="horizontal", layout_width="fill", gravity="center", layout_marginBottom="20dp",
      { Button, id="btnPlayZekr", text="▶ تشغيل الصوت", visibility = (zekrItem.audio and View.VISIBLE or View.GONE), layout_marginRight="10dp" },
      {
        LinearLayout, orientation="vertical", gravity="center",
        { TextView, id = "txtCount", text = "0", textSize = "70sp", style = "bold", textColor = Color.parseColor(colors.primary) },
        { TextView, text = "العدد المطلوب: " .. (zekrItem.targetCount or 1), textSize = "12sp", textColor = Color.parseColor(colors.text_body) }
      }
    },
    {
       FrameLayout, layout_width = "220dp", layout_height = "220dp",
       { Button, id = "btnCount", text = "", layout_width = "fill", layout_height = "fill" },
       { TextView, text = "اضغط للعد", layout_gravity = "center", textColor = Color.parseColor(colors.text_white), textSize = "24sp", style = "bold", clickable = false }
    },
    { Button, text = "إغلاق", layout_marginTop="20dp", id="btnCloseCounter" }
  }

  local builder = AlertDialog.Builder(activity)
  local dlg = builder.show()
  dlg.setContentView(loadlayout(counterLayout, views))

  setCircleDesign(views.btnCount, colors.accent)

  views.btnCount.onClick = function()
    count = count + 1
    if views.txtCount then views.txtCount.text = tostring(count) end
    announceAccess("العدد الحالي " .. count)
    if count >= (zekrItem.targetCount or 1) then
       pcall(function()
         local vibrator = activity.getSystemService(Context.VIBRATOR_SERVICE)
         if vibrator then
           if Build.VERSION.SDK_INT >= 26 then
             vibrator.vibrate(VibrationEffect.createOneShot(200, VibrationEffect.DEFAULT_AMPLITUDE))
           else
             vibrator.vibrate(200)
           end
         end
       end)
    end
  end

  if views.btnPlayZekr then
    setDesign(views.btnPlayZekr, colors.primary, dimens.radius)
    views.btnPlayZekr.setTextColor(Color.parseColor("#FFFFFF"))

    local function updateZekrPlayBtn()
      if player.currentAudioUrl == (AzkarAudioBaseURL .. zekrItem.audio) and player.media.isPlaying() then
        views.btnPlayZekr.text = "⏸ إيقاف مؤقت"
      else
        views.btnPlayZekr.text = "▶ تشغيل الصوت"
      end
    end

    updateZekrPlayBtn()

    views.btnPlayZekr.onClick = function()
      local targetUrl = AzkarAudioBaseURL .. zekrItem.audio
      if player.currentAudioUrl == targetUrl and player.media then
        if player.media.isPlaying() then
          player.media.pause()
          player.isPlaying = false
          announceAccess("تم الإيقاف المؤقت")
        else
          player.media.start()
          player.isPlaying = true
          announceAccess("تم استئناف التشغيل")
        end
        updateZekrPlayBtn()
        updatePlayButton(player.isPlaying)
      else
        player.isIndividualZekr = true
        player.currentSurahName = zekrItem.zekrText:sub(1, 50) .. "..."
        player.currentSurahNumber = 0
        player.currentAyahIndex = 1
        player.currentRepeatCount = 0
        player.currentSurahData = {{ audio = targetUrl, numberInSurah = 1, text = zekrItem.zekrText }}

        playerTitle.text = "استماع للذكر"
        ayahText.text = zekrItem.zekrText
        reciterNameDisplay.text = "حصن المسلم"
        progressText.text = "1 / 1"

        player.isPlaying = true
        setupMediaPlayer(targetUrl)
        announceAccess("جاري تشغيل صوت الذكر")
        Toast.makeText(activity, "جاري تشغيل الصوت...", Toast.LENGTH_SHORT).show()

        -- Use a timer to wait for preparation before updating button
        Handler().postDelayed(Runnable{run=function()
          if player.currentAudioUrl == targetUrl then updateZekrPlayBtn() end
        end}, 1000)
      end
    end
  end

  views.btnCloseCounter.onClick = function()
    stopAudio()
    dlg.dismiss()
  end
end

function showRadioSection()
  currentViewType = "radio"
  listTitle.setVisibility(View.VISIBLE)
  listTitle.text = "إذاعات القرآن الكريم"
  if searchEdt then searchEdt.text = ""; searchEdt.setHint("ابحث عن إذاعة...") end
  mainFlipper.setDisplayedChild(1)
  loadRadios()
end

function loadRadios()
  setMainViewState("loading")
  if allRadiosData and #allRadiosData > 0 then
    displayRadios()
    return
  end

  local url = "https://www.mp3quran.net/api/v3/radios?language=ar"
  httpGet(url, function(success, body)
    if success then
      local decode_ok, json = pcall(cjson.decode, body)
      if decode_ok and json.radios then
        allRadiosData = json.radios
        displayRadios()
      else
        setMainViewState("error")
      end
    else
      setMainViewState("error")
    end
  end)
end

function displayRadios()
  currentRadiosList = {}

  -- Manually add Cairo Radio if not present in API
  local hasCairo = false
  for _, r in ipairs(allRadiosData) do
    if string.find(r.name, "القاهرة") then hasCairo = true; break end
  end
  if not hasCairo then
    table.insert(currentRadiosList, {
      title = "إذاعة القرآن الكريم من القاهرة",
      subtitle = "بث مباشر - القاهرة، مصر",
      url = "https://stream.radiojar.com/8s5u5tpdtwzuv"
    })
  end

  for i, r in ipairs(allRadiosData) do
    table.insert(currentRadiosList, {
      title = r.name,
      subtitle = "بث مباشر - انقر للتشغيل",
      url = r.url
    })
  end
  allSurahsData = currentRadiosList
  updateRadioList("")
  setMainViewState("content")
end

function updateRadioList(filter)
  local listData, filteredItems = {}, {}
  local itemLayout = getStandardListItem()

  local f = filter or ""
  for i, s in ipairs(currentRadiosList) do
    if f == "" or string.find(s.title, f, 1, true) then
      table.insert(filteredItems, s)
      table.insert(listData, { tv_title = s.title, tv_subtitle = s.subtitle })
    end
  end

  local adapter = LuaAdapter(activity, listData, itemLayout)
  surahList.setAdapter(adapter)

  surahList.setOnItemClickListener(AdapterView.OnItemClickListener{
    onItemClick = function(parent, view, position, id)
      playRadio(filteredItems[position + 1])
    end
  })
end

function playRadio(radioItem)
  player.currentSurahName = radioItem.title
  player.currentSurahNumber = 0
  player.currentSurahData = {}

  -- Use player page for radio too
  lastIndex = mainFlipper.getDisplayedChild()
  mainFlipper.setDisplayedChild(2)

  playerTitle.text = radioItem.title
  reciterNameDisplay.text = "بث مباشر من MP3Quran"
  ayahText.text = "جاري الاتصال بالبث المباشر..."
  statusText.text = "جاري التحميل..."
  progressText.text = "راديو مباشر"

  setupMediaPlayer(radioItem.url)
  player.isPlaying = true
  announceAccess("بدء تشغيل " .. radioItem.title)
end

function showListeningSection()
  currentViewType = "listening_reciters"
  listTitle.setVisibility(View.VISIBLE)
  listTitle.text = "الاستماع - اختر القارئ"
  if searchEdt then searchEdt.text = ""; searchEdt.setHint("ابحث عن قارئ...") end
  mainFlipper.setDisplayedChild(1)
  loadAllReciters()
end

function loadAllReciters()
  setMainViewState("loading")
  if allRecitersData and #allRecitersData > 0 then
    displayReciters("")
    return
  end

  local url = "https://www.mp3quran.net/api/v3/reciters?language=ar"
  httpGet(url, function(success, body)
    if success then
      local decode_ok, json = pcall(cjson.decode, body)
      if decode_ok and json.reciters then
        allRecitersData = json.reciters
        -- ترتيب القراء أبجدياً
        table.sort(allRecitersData, function(a, b)
          return (a.name or "") < (b.name or "")
        end)
        displayReciters("")
      else
        setMainViewState("error")
      end
    else
      setMainViewState("error")
    end
  end)
end

function displayReciters(filter)
  local listData, filteredItems = {}, {}
  local f = filter or ""
  for i, r in ipairs(allRecitersData) do
    if f == "" or string.find(r.name, f, 1, true) then
      local moshaf = r.moshaf and r.moshaf[1]
      if moshaf then
        table.insert(filteredItems, r)
        local sub = moshaf.name
        if #r.moshaf > 1 then
          sub = sub .. " (+ " .. (#r.moshaf - 1) .. " روايات أخرى)"
        end
        table.insert(listData, { tv_title = r.name, tv_subtitle = sub })
      end
    end
  end

  local adapter = LuaAdapter(activity, listData, getStandardListItem())
  surahList.setAdapter(adapter)

  surahList.setOnItemClickListener(AdapterView.OnItemClickListener{
    onItemClick = function(parent, view, position, id)
      local reciter = filteredItems[position + 1]
      if reciter.moshaf and #reciter.moshaf > 1 then
        showMoshafSelection(reciter)
      else
        showReciterSurahs(reciter, reciter.moshaf[1])
      end
    end
  })

  setMainViewState("content")
end

function showMoshafSelection(reciter)
  local names = {}
  for i, m in ipairs(reciter.moshaf) do
    table.insert(names, m.name)
  end

  local builder = AlertDialog.Builder(activity)
  builder.setTitle("اختر الرواية / المصحف لـ " .. reciter.name)
  builder.setItems(names, DialogInterface.OnClickListener{
    onClick = function(dialog, which)
      showReciterSurahs(reciter, reciter.moshaf[which + 1])
    end
  })
  builder.setNegativeButton("إلغاء", nil)
  builder.show()
end

local currentReciterSurahsData = {}

function showReciterSurahs(reciter, selectedMoshaf)
  currentSelectedReciter = reciter
  currentSelectedMoshaf = selectedMoshaf
  currentViewType = "listening_surahs"
  listTitle.text = reciter.name .. " (" .. selectedMoshaf.name .. ")"
  if searchEdt then searchEdt.text = ""; searchEdt.setHint("ابحث عن سورة...") end

  currentReciterSurahsData = {}
  -- Split string "1,2,3..." into numbers
  for s_num in string.gmatch(selectedMoshaf.surah_list, '([^,]+)') do
    local n = tonumber(s_num)
    table.insert(currentReciterSurahsData, {
      s_num = n,
      tv_title = "سورة " .. (quranSurahNames[n] or n),
      tv_subtitle = "انقر للاستماع بصوت " .. reciter.name
    })
  end

  updateReciterSurahsList("")
end

function updateReciterSurahsList(filter)
  local listData, filteredItems = {}, {}
  local f = filter or ""
  for i, item in ipairs(currentReciterSurahsData) do
    if f == "" or string.find(item.tv_title, f, 1, true) or string.find(tostring(item.s_num), f, 1, true) then
      table.insert(filteredItems, item)
      table.insert(listData, { tv_title = item.tv_title, tv_subtitle = item.tv_subtitle })
    end
  end

  local adapter = LuaAdapter(activity, listData, getStandardListItem())
  surahList.setAdapter(adapter)

  surahList.setOnItemClickListener(AdapterView.OnItemClickListener{
    onItemClick = function(parent, view, position, id)
      local item = filteredItems[position + 1]
      playFullSurah(currentSelectedReciter, currentSelectedMoshaf, item.s_num, item.tv_title)
    end
  })
end

function playFullSurah(reciter, selectedMoshaf, surah_num, surah_name)
  local moshaf = selectedMoshaf
  local server = moshaf.server
  -- Format surah number to 3 digits (001, 010, 114)
  local s_num_str = string.format("%03d", surah_num)
  local url = server .. s_num_str .. ".mp3"

  currentViewType = "listening_player"
  lastIndex = mainFlipper.getDisplayedChild()
  mainFlipper.setDisplayedChild(2)

  playerTitle.text = surah_name
  reciterNameDisplay.text = "القارئ: " .. reciter.name
  ayahText.text = "جاري تشغيل السورة كاملة بصوت " .. reciter.name .. "\n\n(بث مباشر مستمر)"
  statusText.text = "جاري التحميل..."
  progressText.text = "سورة كاملة"

  player.currentSurahName = surah_name
  player.currentSurahNumber = surah_num
  player.currentSurahData = {} -- Empty to avoid verse completion logic

  setupMediaPlayer(url)
  player.isPlaying = true
  announceAccess("بدء الاستماع لسورة " .. surah_name .. " بصوت " .. reciter.name)
end

function showRangeSelectionDialog(surahMap)
  local colors = theme.colors
  local rangeLayout = {
    LinearLayout, orientation = "vertical", padding = "24dp", layout_width = "fill", backgroundColor = colors.card_bg,
    { TextView, text = "تحديد الآيات: " .. surahMap.englishName, textSize = "22sp", style = "bold", textColor = colors.primary, layout_marginBottom = "24dp", gravity = "center", id="rangeTitle" },

    { TextView, text = "من آية:", textSize = "16sp", textColor = colors.text_body },
    {
      LinearLayout, orientation = "horizontal", layout_width = "fill", gravity = "center",
      { Button, text = "-", id = "btnDecFrom", layout_width = "60dp" },
      { EditText, id = "fromAyahEdt", inputType = "number", text = "1", layout_weight = 1, gravity = "center" },
      { Button, text = "+", id = "btnIncFrom", layout_width = "60dp" },
    },

    { TextView, text = "إلى آية:", textSize = "16sp", textColor = colors.text_body, layout_marginTop="16dp" },
    {
      LinearLayout, orientation = "horizontal", layout_width = "fill", gravity = "center",
      { Button, text = "-", id = "btnDecTo", layout_width = "60dp" },
      { EditText, id = "toAyahEdt", inputType = "number", text = tostring(surahMap.numberOfAyahs), layout_weight = 1, gravity = "center" },
      { Button, text = "+", id = "btnIncTo", layout_width = "60dp" },
    },

    {
      LinearLayout, orientation = "horizontal", layout_width = "fill", layout_marginTop = "24dp",
      { Button, id = "btnStartSave", text = "بدء الحفظ", layout_weight = 1 },
      { Button, id = "btnCancelSave", text = "إلغاء", layout_weight = 1, layout_marginLeft="8dp" },
    }
  }

  local builder = AlertDialog.Builder(activity)
  local dlg = builder.show()
  dlg.setContentView(loadlayout(rangeLayout))

  setDesign(btnStartSave, colors.primary, 12); btnStartSave.setTextColor(Color.parseColor("#FFFFFF"))
  setDesign(btnCancelSave, colors.card_bg, 12); btnCancelSave.setTextColor(Color.parseColor(colors.text_body))

  btnIncFrom.onClick = function() local n = (tonumber(fromAyahEdt.text) or 1) + 1; if n <= surahMap.numberOfAyahs then fromAyahEdt.text = tostring(n) end end
  btnDecFrom.onClick = function() local n = (tonumber(fromAyahEdt.text) or 1) - 1; if n >= 1 then fromAyahEdt.text = tostring(n) end end
  btnIncTo.onClick = function() local n = (tonumber(toAyahEdt.text) or 1) + 1; if n <= surahMap.numberOfAyahs then toAyahEdt.text = tostring(n) end end
  btnDecTo.onClick = function() local n = (tonumber(toAyahEdt.text) or 1) - 1; if n >= 1 then toAyahEdt.text = tostring(n) end end

  setAccessibility(btnIncFrom, "زيادة رقم آية البداية")
  setAccessibility(btnDecFrom, "نقص رقم آية البداية")
  setAccessibility(btnIncTo, "زيادة رقم آية النهاية")
  setAccessibility(btnDecTo, "نقص رقم آية النهاية")

  btnStartSave.onClick = function()
    local startA = tonumber(fromAyahEdt.text) or 1
    local endA = tonumber(toAyahEdt.text) or surahMap.numberOfAyahs
    if startA < 1 then startA = 1 end
    if endA > surahMap.numberOfAyahs then endA = surahMap.numberOfAyahs end
    if startA > endA then startA = endA end
    dlg.dismiss()
    loadSurahDetails(surahMap.number, startA, endA)
  end
  btnCancelSave.onClick = function() dlg.dismiss() end
end

-- =========================================
-- ✔ [تصحيح] الدالة المحصّنة ضد الأخطاء
-- =========================================
function loadSurahDetails(number, startAyah, endAyah)
  -- Try offline data first
  if quranOfflineData and quranOfflineData.text then
    local dText = quranOfflineData.text.surahs[number]
    local dT1 = quranOfflineData.muyassar.surahs[number]
    local dT2 = quranOfflineData.jalalayn.surahs[number]

    if dText then
      player.currentSurahData = {}
      player.currentSurahName = dText.name
      player.currentSurahNumber = number
      for i, ayah in ipairs(dText.ayahs) do
        if ayah.numberInSurah >= startAyah and ayah.numberInSurah <= endAyah then
          -- Construct Audio URL correctly for offline-text mode
          local audioUrl = "https://cdn.islamic.network/quran/audio/128/" .. config.current_reciter .. "/" .. tostring(math.floor(tonumber(ayah.number) or 1)) .. ".mp3"

          table.insert(player.currentSurahData, {
            text = ayah.text,
            audio = audioUrl,
            numberInSurah = ayah.numberInSurah,
            tafsir = dT1 and dT1.ayahs[i] and dT1.ayahs[i].text,
            tafsir2 = dT2 and dT2.ayahs[i] and dT2.ayahs[i].text
          })
        end
      end
      if #player.currentSurahData > 0 then
        lastIndex = mainFlipper.getDisplayedChild()
        mainFlipper.setDisplayedChild(2)
        setupPlayer(1)
        return
      end
    end
  end

  local url = BaseURL .. "/surah/" .. number .. "/editions/quran-simple,ar.muyassar," .. config.current_reciter
  local pd = ProgressDialog.show(activity, "يرجى الانتظار", "جاري جلب الآيات والتفسير...", true)
  
  httpGet(url, function(success, body)
    pd.dismiss()
    if not success then
      Toast.makeText(activity, "خطأ في الشبكة، لم يتم تحميل السورة", Toast.LENGTH_LONG).show()
      return
    end

    local decode_ok, json = pcall(cjson.decode, body)
    if not (decode_ok and json and json.code == 200 and json.data and #json.data >= 3) then
      Toast.makeText(activity, "خطأ: استجابة غير متوقعة من الخادم.", Toast.LENGTH_LONG).show()
      return
    end
    
    local dataText, dataTafsir, dataAudio
    for _, edition in ipairs(json.data) do
      if edition.edition.identifier == "quran-simple" then dataText = edition
      elseif edition.edition.identifier == "ar.muyassar" then dataTafsir = edition
      elseif edition.edition.type == "audio" then dataAudio = edition
      end
    end
    
    -- Fallback if specific identifiers not found
    dataText = dataText or json.data[1]
    dataTafsir = dataTafsir or json.data[2]
    dataAudio = dataAudio or json.data[3]

    -- التحقق الأهم: التأكد من وجود مصفوفة الآيات قبل استخدامها
    if not (dataText and dataText.ayahs and type(dataText.ayahs) == "table" and dataAudio and dataAudio.ayahs and type(dataAudio.ayahs) == "table") then
      Toast.makeText(activity, "خطأ: لم يتم العثور على بيانات الآيات لهذه السورة.", Toast.LENGTH_LONG).show()
      return
    end

    player.currentSurahData = {}
    player.currentSurahName = dataText.name
    player.currentSurahNumber = number
    
    for i = 1, #dataText.ayahs do
      -- إضافة تحقق إضافي لضمان تطابق البيانات
      if dataAudio.ayahs[i] then
        local curNum = dataText.ayahs[i].numberInSurah
        if curNum >= startAyah and curNum <= endAyah then
          table.insert(player.currentSurahData, {
            text = dataText.ayahs[i].text,
            audio = dataAudio.ayahs[i].audio,
            numberInSurah = curNum,
            tafsir = dataTafsir.ayahs[i].text
          })
        end
      end
    end
    
    if #player.currentSurahData > 0 then
      lastIndex = mainFlipper.getDisplayedChild()
      mainFlipper.setDisplayedChild(2)
      setupPlayer(1) 
    else
      Toast.makeText(activity, "لم يتم العثور على آيات في النطاق المحدد.", Toast.LENGTH_LONG).show()
    end
  end)
end

function setupPlayer(index)
  player.currentAyahIndex = index
  player.currentRepeatCount = 0
  local ayah = player.currentSurahData[index]

  -- Reset section icons
  sectionIcon.setVisibility(View.GONE)

  if (currentViewType == "surahs" or currentViewType == "juzs" or currentViewType == "pages" or currentViewType == "rubs") and currentViewType ~= "memorization" then
    isContinuousMode = true
  elseif currentViewType == "radio" then
    isContinuousMode = false
    sectionIcon.setVisibility(View.VISIBLE)
    sectionIcon.setImageResource(android.R.drawable.ic_lock_silent_mode_off)
    sectionIcon.setColorFilter(Color.parseColor(theme.colors.primary))
  elseif currentViewType == "azkar_content" then
    isContinuousMode = false
    sectionIcon.setVisibility(View.VISIBLE)
    sectionIcon.setImageResource(android.R.drawable.btn_star_big_on)
    sectionIcon.setColorFilter(Color.parseColor(theme.colors.primary))
  elseif currentViewType == "listening_player" then
    isContinuousMode = false
    sectionIcon.setVisibility(View.VISIBLE)
    sectionIcon.setImageResource(android.R.drawable.ic_lock_silent_mode)
    sectionIcon.setColorFilter(Color.parseColor(theme.colors.primary))
  else
    isContinuousMode = false
  end

  if isContinuousMode then
    ayahCard.setVisibility(View.GONE)
    continuousListView.setVisibility(View.VISIBLE)
    progressContainer.setVisibility(View.GONE)
    controlsContainer.setVisibility(View.GONE)
    updateContinuousList()
    -- Smooth scroll to current ayah if applicable
    if index > 1 then continuousListView.setSelection(index - 1) end

    -- In continuous mode, if player is already active, keep it going for the next ayah
    if player.isPlaying then
       setupMediaPlayer(ayah.audio)
    end
  else
    ayahCard.setVisibility(View.VISIBLE)
    continuousListView.setVisibility(View.GONE)
    progressContainer.setVisibility(View.VISIBLE)
    controlsContainer.setVisibility(View.VISIBLE)
  end
  
  playerTitle.text = player.currentSurahName .. (not isContinuousMode and (" (" .. ayah.numberInSurah .. ")") or "")
  setAccessibility(playerTitle, playerTitle.text, "heading")
  
  local reciterName = "قارئ محدد"
  for k, v in pairs(reciters) do if v.id == config.current_reciter then reciterName = v.name; break end end
  reciterNameDisplay.text = (isContinuousMode and "تصفح القراءة" or "القارئ: " .. reciterName)
  
  ayahText.text = ayah.text
  statusText.text = "جاهز للتشغيل"
  progressText.text = index .. " / " .. #player.currentSurahData
  saveCurrentProgress()
  
  if not isContinuousMode then
    local textToAnnounce = player.currentSurahName .. ". "
    if ayah.surahName then textToAnnounce = textToAnnounce .. "سورة " .. ayah.surahName .. ". " end
    textToAnnounce = textToAnnounce .. "الآية " .. ayah.numberInSurah .. ". جاهزة للتشغيل."
    announceAccess(textToAnnounce)
    setupMediaPlayer(ayah.audio)

    ayahText.onLongClick = function()
      showAyahOptions(index)
      return true
    end
  else
    announceAccess("تم فتح وضع القراءة لـ " .. player.currentSurahName .. ". اسحب لأسفل لتصفح الآيات.")
  end
end

function updateContinuousList()
  local listData = {}
  local colors = theme.colors
  local itemLayout = {
    LinearLayout, layout_width = "fill", padding = "12dp", orientation = "vertical",
    {
      TextView, id = "tv_ayah", textSize = (config.font_size + 2) .. "sp", textColor = Color.parseColor(colors.text_title),
      gravity = "right", padding = "16dp", layout_width = "fill",
      typeface = Typeface.DEFAULT_BOLD
    }
  }

  for i, a in ipairs(player.currentSurahData) do
    local ayahNumStr = tostring(math.floor(tonumber(a.numberInSurah) or 1))
    local surahNameStr = a.surahName or player.currentSurahName or "السورة"
    local accessibleText = surahNameStr .. "، الآية " .. ayahNumStr .. ". " .. a.text
    table.insert(listData, {
      tv_ayah = {
        text = a.text .. " ﴿ " .. ayahNumStr .. " ﴾",
        contentDescription = accessibleText
      }
    })
  end

  local adapter = LuaAdapter(activity, listData, itemLayout)
  continuousListView.setAdapter(adapter)

  continuousListView.setOnItemClickListener(AdapterView.OnItemClickListener{
    onItemClick = function(parent, view, position, id)
      local item = player.currentSurahData[position+1]
      playAyahInContinuous(position+1)
    end
  })

  continuousListView.setOnItemLongClickListener(AdapterView.OnItemLongClickListener{
    onItemLongClick = function(parent, view, position, id)
      showAyahOptions(position + 1)
      return true
    end
  })
end

function playAyahInContinuous(index)
  local ayah = player.currentSurahData[index]
  player.currentAyahIndex = index
  announceAccess("جاري تشغيل الآية " .. ayah.numberInSurah)
  setupMediaPlayer(ayah.audio)
end

function setupMediaPlayer(url)
  if not url or url == "" then
    Toast.makeText(activity, "رابط الصوت غير متوفر", Toast.LENGTH_SHORT).show()
    return
  end

  -- Check connectivity but don't block
  local cm = activity.getSystemService(Context.CONNECTIVITY_SERVICE)
  local info = cm.getActiveNetworkInfo()
  local isConnected = (info and info.isConnected())

  if url:match("^http") and not isConnected then
     Toast.makeText(activity, "التشغيل الصوتي يتطلب إنترنت 🌐", Toast.LENGTH_SHORT).show()
  end

  stopAudio()
  player.isPlaying = true
  player.currentAudioUrl = url

  local success, err = pcall(function()
    player.media = MediaPlayer()
    -- Background playback support
    player.media.setWakeMode(activity, PowerManager.PARTIAL_WAKE_LOCK)

    -- Maintain Wifi connection if streaming
    if url:match("^http") then
      if not player.wifiLock then
        local wm = activity.getSystemService(Context.WIFI_SERVICE)
        player.wifiLock = wm.createWifiLock(WifiManager.WIFI_MODE_FULL, "QuranAudioLock")
      end
      if player.wifiLock then player.wifiLock.acquire() end
    end

    player.media.setDataSource(url)
    player.media.prepareAsync()
  end)

  if not success then
    statusText.text = "خطأ في رابط الصوت"
    Toast.makeText(activity, "خطأ في تشغيل الصوت: " .. tostring(err), Toast.LENGTH_LONG).show()
    player.isPlaying = false
    return
  end

  player.media.setOnErrorListener{ onError = function(mp, what, extra)
    local errorMsg = "مشكلة في تحميل الصوت"
    if what == -38 or what == 1 then errorMsg = "خطأ في حالة مشغل الصوت" end
    Toast.makeText(activity, "خطأ في مشغل الوسائط: " .. errorMsg .. " (" .. what .. ")", Toast.LENGTH_SHORT).show()
    player.isPlaying = false
    updatePlayButton(false)
    return true
  end}
  
  player.media.setOnPreparedListener{ onPrepared = function(mp)
    if player.isPlaying and player.media then
      mp.start()
      updatePlayButton(true)
    end
  end}

  player.media.setOnCompletionListener{ onCompletion = function(mp)
    onAyahComplete()
  end}
end

function onAyahComplete()
  if not player.currentSurahData or #player.currentSurahData == 0 or player.isIndividualZekr then
    statusText.text = "تم الانتهاء"
    updatePlayButton(false); player.isPlaying = false
    player.currentRepeatCount = 0
    return
  end

  player.currentRepeatCount = player.currentRepeatCount + 1
  if player.currentRepeatCount < config.repeat_ayah then
    statusText.text = "تكرار (" .. player.currentRepeatCount .. " من " .. config.repeat_ayah .. ")"
    if config.delay_seconds > 0 then startDelay(function() if player.media then player.media.start() end end) else if player.media then player.media.start() end end
  else
    if player.currentAyahIndex < #player.currentSurahData then
      statusText.text = "الانتقال للتالي..."
      if config.delay_seconds > 0 then startDelay(function() playNext() end) else playNext() end
    else
      statusText.text = "تم الانتهاء 🎉"
      updatePlayButton(false); player.isPlaying = false
      announceAccess("تم الانتهاء من التشغيل")
    end
  end
end

function startDelay(callback)
  statusText.text = "انتظار " .. config.delay_seconds .. " ثانية..."
  Handler().postDelayed(Runnable{ run = function() if player.isPlaying and player.media then callback() end end }, config.delay_seconds * 1000)
end

function togglePlay()
  if player.media and player.media.isPlaying() then
    player.media.pause(); player.isPlaying = false; updatePlayButton(false)
    announceAccess("تم الإيقاف المؤقت")
  elseif player.media then
    player.media.start(); player.isPlaying = true; updatePlayButton(true)
    announceAccess("تم استئناف التشغيل")
  end
end

function updatePlayButton(isPlaying)
  if isPlaying then btnPlay.text = "⏸"; btnPlay.setContentDescription("إيقاف مؤقت")
  else btnPlay.text = "▶"; btnPlay.setContentDescription("تشغيل") end
end

function playNext()
  if player.currentAyahIndex < #player.currentSurahData then setupPlayer(player.currentAyahIndex + 1); player.isPlaying = true
  else Toast.makeText(activity, "نهاية التحديد", Toast.LENGTH_SHORT).show() end
end

function playPrev()
  if player.currentAyahIndex > 1 then setupPlayer(player.currentAyahIndex - 1); player.isPlaying = true end
end

function stopAudio()
  pcall(function()
    if player.media then
      if player.media.isPlaying() then player.media.stop() end
      player.media.reset()
      player.media.release()
      player.media = nil
    end
    if player.wifiLock and player.wifiLock.isHeld() then player.wifiLock.release() end
  end)
  player.isPlaying = false; player.currentAudioUrl = nil; updatePlayButton(false)
end

-- ==========================================
-- ⚙️ 11. SETTINGS DIALOG
-- ==========================================

function showSettingsDialog()
  local colors = theme.colors
  local reciterNames = {}; local selectedIndex = 0
  for i = 1, #reciters do table.insert(reciterNames, reciters[i].name); if reciters[i].id == config.current_reciter then selectedIndex = i - 1 end end

  local dl = {
    LinearLayout, orientation = "vertical", padding = "24dp", backgroundColor = colors.card_bg,
    { TextView, text = "⚙️ الإعدادات", textSize = "22sp", style = "bold", textColor = colors.primary, layout_marginBottom = "20dp" },
    { TextView, text = "القارئ:", textColor = colors.text_title },
    { Spinner, id = "spnReciter", layout_width = "fill", layout_marginBottom = "16dp" },
    { TextView, text = "عدد مرات التكرار:", textColor = colors.text_title },
    { EditText, id = "rptEdt", inputType = "number", text = tostring(config.repeat_ayah) },
    { TextView, text = "فاصل زمني (ثواني):", textColor = colors.text_title, layout_marginTop = "12dp" },
    { EditText, id = "dlyEdt", inputType = "number", text = tostring(config.delay_seconds) },
    { TextView, text = "حجم الخط:", textColor = colors.text_title, layout_marginTop = "12dp" },
    { SeekBar, id = "fontSeek", max = 60, progress = config.font_size, layout_width = "fill", layout_marginTop = "8dp" },
    {
      LinearLayout, orientation = "horizontal", layout_width = "fill", layout_marginTop = "16dp", gravity = "center_vertical",
      { CheckBox, id = "chkAutoSave", layout_marginRight = "8dp" },
      { TextView, text = "حفظ التقدم تلقائياً", textColor = colors.text_title, textSize = "16sp" }
    }
  }
  
  local builder = AlertDialog.Builder(activity)
  builder.setView(loadlayout(dl))
  spnReciter.setAdapter(ArrayAdapter(activity, android.R.layout.simple_spinner_dropdown_item, reciterNames))
  spnReciter.setSelection(selectedIndex)
  chkAutoSave.setChecked(config.auto_save_progress)
  fontSeek.setOnSeekBarChangeListener{ onProgressChanged = function(seek, progress, fromUser) if progress < 16 then progress = 16 end; if ayahText then ayahText.textSize = progress end end }

  builder.setPositiveButton("حفظ وإغلاق", function()
    config.repeat_ayah = tonumber(rptEdt.text) or 1
    config.delay_seconds = tonumber(dlyEdt.text) or 0
    config.font_size = fontSeek.progress < 16 and 16 or fontSeek.progress
    config.auto_save_progress = chkAutoSave.isChecked()
    local pos = spnReciter.getSelectedItemPosition() + 1
    config.current_reciter = reciters[pos].id
    if ayahText then ayahText.textSize = config.font_size end
    if reciterNameDisplay then reciterNameDisplay.text = "القارئ: " .. reciters[pos].name end
    saveAppData(); Toast.makeText(activity, "تم حفظ الإعدادات ✔", Toast.LENGTH_SHORT).show()
  end)
  builder.setNeutralButton("حذف بيانات الأوفلاين", function()
     os.remove(quranOfflinePath)
     quranOfflineData = nil
     Toast.makeText(activity, "تم حذف البيانات. يرجى إعادة تشغيل التطبيق.", Toast.LENGTH_LONG).show()
  end)
  builder.setNegativeButton("إلغاء", nil)
  builder.show()
end

-- ==========================================
-- 🔙 12. BACK BUTTON & CLEANUP
-- ==========================================

function onKeyDown(keyCode, event)
  if keyCode == KeyEvent.KEYCODE_BACK then
    local current = mainFlipper.getDisplayedChild()
    if current == 2 then -- Player Page
      stopAudio()
      mainFlipper.setDisplayedChild(lastIndex or 1)
      announceAccess("تم إيقاف القراءة، العودة للقائمة السابقة")
      return true
    elseif current == 1 then -- List Page
      if currentViewType == "azkar_content" then
        showAzkarSection()
        return true
      elseif currentViewType == "listening_surahs" then
        showListeningSection()
        return true
      end
      if currentViewType == "surahs" or currentViewType == "memorization" or currentViewType == "juzs" or currentViewType == "pages" or currentViewType == "rubs" or currentViewType == "hizbs" or currentViewType == "quran_reading" then
         mainFlipper.setDisplayedChild(4) -- Back to Quran Hub
      elseif currentViewType == "listening_reciters" then
         mainFlipper.setDisplayedChild(4) -- Back to Quran Hub
      else
         mainFlipper.setDisplayedChild(0) -- Back to Main Menu
      end
      announceAccess("العودة للقائمة السابقة")
      return true
    elseif current == 3 then -- Index Selection
      mainFlipper.setDisplayedChild(4) -- Back to Hub
      announceAccess("العودة للقائمة السابقة")
      return true
    elseif current == 4 then -- Quran Hub
      mainFlipper.setDisplayedChild(0) -- Back to Main Menu
      announceAccess("العودة للقائمة الرئيسية")
      return true
    elseif current == 4 then -- Quran Hub
      mainFlipper.setDisplayedChild(0)
      return true
    elseif current > 0 then
      mainFlipper.setDisplayedChild(0)
      announceAccess("العودة للقائمة الرئيسية")
      return true
    end
  end
  return false
end

function onDestroy() 
  saveAppData()
  if player.media then pcall(function() player.media.release() end) end 
end

function onPause()
  saveAppData()
end

-- ==========================================
-- 🚀 13. START APPLICATION
-- ==========================================

function searchQuranOffline(query)
  if not quranOfflineData or not quranOfflineData.text then
    if #query > 2 then Toast.makeText(activity, "يجب تحميل بيانات الأوفلاين أولاً للبحث", Toast.LENGTH_SHORT).show() end
    return
  end

  local results = {}
  local listData = {}
  local dText = quranOfflineData.text
  local dT1 = quranOfflineData.muyassar
  local dT2 = quranOfflineData.jalalayn

  -- Simple normalization for common Arabic letters
  local function normalize(t)
    if not t then return "" end
    -- Remove diacritics and common marks
    local res = t:gsub("[\217\139-\217\148]", "")
    res = res:gsub("[\217\154-\217\159]", "")
    res = res:gsub("[ًٌٍَُِّْ]", "")
    -- Normalize letters
    res = res:gsub("[أإآ]", "ا")
    res = res:gsub("ة", "ه")
    res = res:gsub("ى", "ي")
    return res
  end
  local normQuery = normalize(query)

  local count = 0
  for sIdx, surah in ipairs(dText.surahs) do
    for aIdx, ayah in ipairs(surah.ayahs) do
      local match = false
      if string.find(ayah.text, query, 1, true) or string.find(normalize(ayah.text), normQuery, 1, true) then
        match = true
      end

      if match then
        table.insert(results, {
          text = ayah.text,
          audio = "https://cdn.islamic.network/quran/audio/128/" .. config.current_reciter .. "/" .. tostring(math.floor(tonumber(ayah.number) or 1)) .. ".mp3",
          numberInSurah = ayah.numberInSurah,
          surahName = surah.name,
          surahNumber = sIdx,
          tafsir = dT1.surahs[sIdx].ayahs[aIdx].text,
          tafsir2 = dT2 and dT2.surahs[sIdx].ayahs[aIdx].text
        })
        table.insert(listData, {
          tv_title = surah.name .. " - آية " .. ayah.numberInSurah,
          tv_subtitle = string.sub(ayah.text, 1, 100) .. "..."
        })
      end
      if #results >= 50 then break end
    end
    if #results >= 50 then break end
  end

  local adapter = LuaAdapter(activity, listData, getStandardListItem())
  surahList.setAdapter(adapter)

  surahList.setOnItemClickListener(AdapterView.OnItemClickListener{
    onItemClick = function(parent, view, position, id)
      local res = results[position + 1]
      player.currentSurahData = {res}
      player.currentSurahName = res.surahName
      player.currentSurahNumber = res.surahNumber
      lastIndex = 1
      mainFlipper.setDisplayedChild(2)
      setupPlayer(1)

      -- If user was searching from Quran section, we might want to stay in Quran context
      -- But for now, single verse view is safer for search results.
    end
  })

  surahList.setOnItemLongClickListener(AdapterView.OnItemLongClickListener{
    onItemLongClick = function(parent, view, position, id)
      local res = results[position + 1]
      player.currentSurahData = {res} -- Set context
      player.currentSurahName = res.surahName
      player.currentSurahNumber = res.surahNumber
      showAyahOptions(1)
      return true
    end
  })
end

function showAyahOptions(index)
  local ayah = player.currentSurahData[index]
  if not ayah then return end

  local colors = theme.colors
  local ayahNumStr = tostring(math.floor(tonumber(ayah.numberInSurah) or 1))
  local options = {
    "📖 عرض التفسير",
    "ℹ️ معلومات الآية",
    "📋 نسخ الآية (بالتشكيل)",
    "📋 نسخ الآية (بدون تشكيل)",
    "🔁 تكرار الآية (للحفظ)",
    "🎧 تشغيل الآية",
    "📤 مشاركة",
    "🔖 إضافة للإشارات"
  }

  local builder = AlertDialog.Builder(activity)
  builder.setTitle("خيارات الآية " .. ayahNumStr)
  builder.setItems(options, function(dialog, which)
    if which == 0 then -- Tafsir
      showTafsirDialog(ayah)
    elseif which == 1 then -- Ayah Info
      local infoText = "سورة: " .. (ayah.surahName or player.currentSurahName or "غير معروف") .. "\n"
      infoText = infoText .. "الآية: " .. ayahNumStr .. "\n"
      if ayah.juz then infoText = infoText .. "الجزء: " .. tostring(ayah.juz) .. "\n" end
      if ayah.hizbQuarter then infoText = infoText .. "الربع: " .. tostring(ayah.hizbQuarter) .. "\n" end

      local infoBuilder = AlertDialog.Builder(activity)
      infoBuilder.setTitle("معلومات الآية")
      infoBuilder.setMessage(infoText)
      infoBuilder.setPositiveButton("موافق", nil)
      infoBuilder.show()
      announceAccess("تم فتح معلومات الآية: " .. infoText:gsub("\n", ". "))
    elseif which == 2 then -- Copy with Tashkeel
      local cm = activity.getSystemService(Context.CLIPBOARD_SERVICE)
      local cd = ClipData.newPlainText("Ayah", ayah.text)
      cm.setPrimaryClip(cd)
      Toast.makeText(activity, "تم نسخ الآية بالتشكيل ✔", Toast.LENGTH_SHORT).show()
      announceAccess("تم نسخ الآية")
    elseif which == 3 then -- Copy without Tashkeel
      local textNoTashkeel = ayah.text:gsub("[%z\1-\127\194-\244][\128-\191]*", function(c)
        -- Basic removal of Arabic diacritics (Harakat)
        local code = utf8.codepoint(c)
        if code and code >= 0x064B and code <= 0x0652 then return "" else return c end
      end)
      local cm = activity.getSystemService(Context.CLIPBOARD_SERVICE)
      local cd = ClipData.newPlainText("Ayah", textNoTashkeel)
      cm.setPrimaryClip(cd)
      Toast.makeText(activity, "تم نسخ الآية بدون تشكيل ✔", Toast.LENGTH_SHORT).show()
      announceAccess("تم نسخ الآية بدون تشكيل")
    elseif which == 4 then -- Repeat
      Toast.makeText(activity, "سيتم تكرار هذه الآية", Toast.LENGTH_SHORT).show()
      -- Future integration for repeat mode
    elseif which == 5 then -- Play Ayah
      playAyahInContinuous(index)
    elseif which == 6 then -- Share
      shareAyah(ayah)
    elseif which == 7 then -- Bookmark
      addAyahToBookmarks(ayah)
    end
  end)
  builder.show()
  announceAccess("تم فتح قائمة خيارات الآية " .. ayahNumStr)
end

function showTafsirDialog(ayah)
  local colors = theme.colors
  local views = {}

  local tafsirLayout = {
    LinearLayout, orientation = "vertical", padding = "24dp", backgroundColor = colors.card_bg,
    {
      LinearLayout, orientation = "horizontal", layout_width = "fill", layout_marginBottom = "16dp", gravity = "center_vertical",
      { TextView, text = "تفسير الآية " .. ayah.numberInSurah, textSize = "20sp", style = "bold", textColor = colors.primary, layout_weight = 1 },
      { Spinner, id = "spnTafsir", layout_width = "wrap_content" }
    },
    { ScrollView, layout_width = "fill", layout_height = "320dp",
      { TextView, id = "txtTafsir", text = ayah.tafsir or "التفسير غير متوفر.", textSize = "18sp", textColor = colors.text_title }
    },
    {
      LinearLayout, orientation = "horizontal", layout_width = "fill", layout_marginTop = "16dp",
      { Button, text = "إغلاق", id = "btnCloseTafsir", layout_weight = 1 },
      { Button, text = "مشاركة", id = "btnShareTafsir", layout_weight = 1, layout_marginLeft = "8dp" }
    }
  }

  local builder = AlertDialog.Builder(activity)
  local dlg = builder.show()
  dlg.setContentView(loadlayout(tafsirLayout, views))

  if views.txtTafsir then pcall(function() views.txtTafsir.setLineSpacing(0, 1.4) end) end

  local tafsirBooks = {"التفسير الميسر", "تفسير الجلالين"}
  views.spnTafsir.setAdapter(ArrayAdapter(activity, android.R.layout.simple_spinner_dropdown_item, tafsirBooks))

  views.spnTafsir.setOnItemSelectedListener(AdapterView.OnItemSelectedListener{
    onItemSelected = function(parent, view, pos, id)
      if pos == 0 then
        views.txtTafsir.text = ayah.tafsir or "غير متوفر"
      else
        views.txtTafsir.text = ayah.tafsir2 or "غير متوفر (يرجى تحميل بيانات الأوفلاين)"
      end
    end
  })

  setDesign(views.btnCloseTafsir, colors.card_bg, 12, 2, colors.primary); views.btnCloseTafsir.setTextColor(Color.parseColor(colors.primary))
  setDesign(views.btnShareTafsir, colors.primary, 12); views.btnShareTafsir.setTextColor(Color.parseColor("#FFFFFF"))

  views.btnCloseTafsir.onClick = function() dlg.dismiss() end
  views.btnShareTafsir.onClick = function()
    local book = tafsirBooks[views.spnTafsir.getSelectedItemPosition() + 1]
    local shareText = "﴿ " .. ayah.text .. " ﴾\n\n" .. book .. ":\n" .. views.txtTafsir.text .. "\n\n📖 " .. player.currentSurahName .. " - آية " .. ayah.numberInSurah
    local intent = Intent(Intent.ACTION_SEND)
    intent.setType("text/plain")
    intent.putExtra(Intent.EXTRA_TEXT, shareText)
    activity.startActivity(Intent.createChooser(intent, "مشاركة التفسير..."))
  end
end

function shareAyah(ayah)
  local shareText = "﴿ " .. ayah.text .. " ﴾\n\n" .. "تفسير الميسر:\n" .. (ayah.tafsir or "") .. "\n\n📖 " .. player.currentSurahName .. " - الآية " .. ayah.numberInSurah .. "\n" .. "───────────────\n" .. "📱 تطبيق القرآن الكريم"
  local intent = Intent(Intent.ACTION_SEND)
  intent.setType("text/plain")
  intent.putExtra(Intent.EXTRA_TEXT, shareText)
  activity.startActivity(Intent.createChooser(intent, "مشاركة الآية عبر..."))
end

function addAyahToBookmarks(ayah)
  local bookmarkId = player.currentSurahNumber .. "_" .. ayah.numberInSurah
  for i, b in ipairs(bookmarks) do
    if b.id == bookmarkId then
      Toast.makeText(activity, "هذه الآية محفوظة مسبقاً", Toast.LENGTH_SHORT).show()
      return
    end
  end
  local newBookmark = {
    id = bookmarkId, surahNumber = player.currentSurahNumber, surahName = player.currentSurahName,
    ayahNumber = ayah.numberInSurah, ayahText = string.sub(ayah.text, 1, 100) .. "...", timestamp = os.time()
  }
  table.insert(bookmarks, 1, newBookmark)
  saveAppData()
  Toast.makeText(activity, "تم الحفظ في الإشارات المرجعية ✔", Toast.LENGTH_SHORT).show()
end

function checkAppUpdates()
  local githubVersionUrl = "https://raw.githubusercontent.com/ahanafy41/Memorization-and-listening-to-the-Holy-Quran-/main/version.txt"
  local githubCodeUrl = "https://raw.githubusercontent.com/ahanafy41/Memorization-and-listening-to-the-Holy-Quran-/main/main.lua"

  httpGet(githubVersionUrl, function(success, body)
    if success then
      local latestVersion = body:gsub("%s+", "")
      if latestVersion ~= currentAppVersion then
        local builder = AlertDialog.Builder(activity)
        builder.setTitle("تحديث تلقائي متوفر 🚀")
        builder.setMessage("يتوفر إصدار جديد (" .. latestVersion .. "). هل تريد تحميل التحديث وتطبيقه الآن؟")
        builder.setPositiveButton("تحديث الآن", function()
          startDirectUpdate(githubCodeUrl, latestVersion)
        end)
        builder.setNegativeButton("لاحقاً", nil)
        builder.show()
      end
    end
  end)
end

function startDirectUpdate(url, newVersion)
  local pd = ProgressDialog(activity)
  pd.setTitle("جاري التحديث")
  pd.setMessage("جاري تحميل ملف الكود الجديد...")
  pd.setCancelable(false)
  pd.show()

  httpGet(url, function(success, body)
    if success and #body > 1000 then -- Ensure it's a valid lua file (not 404 or empty)
      local path = activity.getLuaDir() .. "/main.lua"
      local tempPath = path .. ".tmp"

      -- 1. Save to temp file
      local file = io.open(tempPath, "w")
      if file then
        file:write(body)
        file:close()

        -- 2. Verify syntax if possible (Simple check: starts with 'require' or 'import')
        if string.find(body, "import") or string.find(body, "require") then
           -- 3. Replace current file
           os.remove(path)
           os.rename(tempPath, path)

           pd.dismiss()
           local builder = AlertDialog.Builder(activity)
           builder.setTitle("تم التحديث بنجاح! 🎉")
           builder.setMessage("تم تطبيق الإصدار " .. newVersion .. " بنجاح. يرجى إعادة تشغيل التطبيق لتفعيل التعديلات.")
           builder.setPositiveButton("إعادة التشغيل الآن", function()
             local intent = activity.getBaseContext().getPackageManager().getLaunchIntentForPackage(activity.getBaseContext().getPackageName())
             intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
             activity.finish()
             activity.startActivity(intent)
           end)
           builder.setCancelable(false)
           builder.show()
        else
           pd.dismiss()
           Toast.makeText(activity, "فشل التحديث: الملف المحمل غير صالح", Toast.LENGTH_LONG).show()
           os.remove(tempPath)
        end
      else
        pd.dismiss()
        Toast.makeText(activity, "فشل في فتح ملف التحديث للكتابة", Toast.LENGTH_LONG).show()
      end
    else
      pd.dismiss()
      Toast.makeText(activity, "فشل تحميل ملف التحديث: " .. tostring(body), Toast.LENGTH_LONG).show()
    end
  end)
end

function startApp()
  applyTheme()
  setRandomQuote()
  checkAppUpdates()
  if showResumeCard then showResumeCard() end

  if searchEdt then
    searchEdt.addTextChangedListener{ onTextChanged = function(s)
      local txt = tostring(s)
      if #txt == 0 then
         if currentViewType == "radio" then updateRadioList("")
         elseif currentViewType == "azkar_content" then updateAzkarList("")
         elseif currentViewType == "listening_reciters" then displayReciters("")
         elseif currentViewType == "listening_surahs" then updateReciterSurahsList("")
         else updateList("") end
         return
      end

      -- Debounce search for performance
      if searchTimer then searchTimer.cancel() end
      searchTimer = Timer().schedule(TimerTask{run=function()
        activity.runOnUiThread(Runnable{run=function()
          if currentViewType == "radio" then
            updateRadioList(txt)
          elseif currentViewType == "azkar_content" then
            updateAzkarList(txt)
          elseif currentViewType == "listening_reciters" then
            displayReciters(txt)
          elseif currentViewType == "listening_surahs" then
            if updateReciterSurahsList then updateReciterSurahsList(txt) end
          elseif #txt > 2 then
            searchQuranOffline(txt)
          else
            updateList(txt)
          end
        end})
      end}, 500)
    end }
  end

  -- Check for offline data
  if not quranOfflineData then
    local builder = AlertDialog.Builder(activity)
    builder.setTitle("تشغيل الأوفلاين ⚡")
    builder.setMessage("هل تريد تحميل المصحف والتفسير الآن ليعمل التطبيق بدون إنترنت؟ (حجم الملف حوالي 10 ميجابايت)")
    builder.setPositiveButton("تحميل الآن", function()
      downloadQuranOffline(function(success)
        if success then
           local i = Intent(activity, activity.getClass())
           activity.finish()
           activity.startActivity(i)
        end
      end)
    end)
    builder.setNegativeButton("لاحقاً", nil)
    builder.show()
  end

  -- Card Click Listeners
  if btnGoQuranMain then btnGoQuranMain.onClick = function() mainFlipper.setDisplayedChild(4) end end
  if btnGoAzkar then btnGoAzkar.onClick = function() showAzkarSection() end end
  if btnGoRadio then btnGoRadio.onClick = function() showRadioSection() end end

  if btnHubRead then btnHubRead.onClick = function() showQuranSection() end end
  if btnHubListen then btnHubListen.onClick = function() showListeningSection() end end
  if btnHubMemorize then btnHubMemorize.onClick = function() showMemorizationSection() end end

setAccessibility(toolbar_title, "تطبيق القرآن الكريم، الصفحة الرئيسية", "heading")
setAccessibility(btn_settings, "فتح الإعدادات", "button")
setAccessibility(btn_theme, "تبديل الوضع الليلي", "button")
setAccessibility(btn_bookmarks, "عرض الإشارات المرجعية", "button")
setAccessibility(btn_search, "فتح البحث السريع", "button")
setAccessibility(btnGoQuranMain, "القرآن الكريم: تصفح، استماع، وتحفيظ", "button")
setAccessibility(btnGoAzkar, "الأذكار: الأذكار النبوية وحصن المسلم", "button")
setAccessibility(btnGoRadio, "الراديو: إذاعات القرآن الكريم المباشرة", "button")

setAccessibility(btnHubRead, "قراءة وتصفح القرآن", "button")
setAccessibility(btnHubListen, "الاستماع للقراء", "button")
setAccessibility(btnHubMemorize, "المحفظ المعلم", "button")
setAccessibility(btnBackFromHub, "العودة للقائمة الرئيسية", "button")

setAccessibility(btnIndexSurah, "عرض فهرس السور", "button")
setAccessibility(btnIndexJuz, "عرض فهرس الأجزاء", "button")
setAccessibility(btnIndexPage, "عرض فهرس الصفحات", "button")
setAccessibility(btnIndexRub, "عرض فهرس أرباع الأحزاب", "button")
setAccessibility(searchEdt, "مربع بحث، اكتب اسم السورة أو الرقم", "edit")
setAccessibility(btnPlay, "تشغيل المقطع الصوتي", "button")
setAccessibility(btnMoreOptions, "المزيد من الخيارات (تفسير، مشاركة، نسخ)", "button")
setAccessibility(btnRetry, "إعادة محاولة تحميل البيانات", "button")
setAccessibility(btnBack, "زر العودة للقائمة السابقة", "button")
setAccessibility(btnBackFromIndex, "زر العودة للقائمة الرئيسية", "button")

  pcall(function() ayahText.setLineSpacing(0, 1.4) end)
  mainFlipper.setDisplayedChild(0)
  announceAccess("تطبيق القرآن الكريم، القائمة الرئيسية")
end

startApp()