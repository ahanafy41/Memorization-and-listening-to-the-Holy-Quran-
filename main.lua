require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.content.*"
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
      primary = "#00695C",
      primary_dark = "#004D40",
      accent = "#FDD835",
      background = "#F5F5F5",
      card_bg = "#FFFFFF",
      text_title = "#212121",
      text_body = "#424242",
      text_white = "#FFFFFF",
      bookmark_icon = "#FF5722",
      share_icon = "#2196F3",
      error_text = "#D32F2F"
    }
  },
  dark = {
    name = "داكن",
    colors = {
      primary = "#00897B",
      primary_dark = "#00695C",
      accent = "#FFD54F",
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

local player = {
  media = MediaPlayer(),
  isPlaying = false,
  currentSurahData = nil,
  currentSurahName = "",
  currentSurahNumber = 0,
  currentAyahIndex = 1,
  currentRepeatCount = 0,
  currentAudioUrl = nil,
  isIndividualZekr = false
}

local allSurahsData = {}
local currentSurahsList = {}
local currentAzkarCategories = {}
local currentAzkarItems = {}
local currentRadiosList = {}
local allAzkarData = {}
local allRadiosData = {}
local currentAzkarCategory = nil
local currentViewType = "surahs"
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
end

loadAppData()

-- ==========================================
-- 🛠️ 3. UI & ACCESSIBILITY HELPERS
-- ==========================================

function setDesign(view, colorHex, radius)
  if not view then return end
  local drawable = GradientDrawable()
  drawable.setShape(GradientDrawable.RECTANGLE)
  drawable.setColor(Color.parseColor(colorHex))
  drawable.setCornerRadius(radius or dimens.radius)
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

-- ==========================================
-- 📐 4. LAYOUT STRUCTURE
-- ==========================================

layout = {
  LinearLayout,
  orientation = "vertical",
  layout_width = "fill",
  layout_height = "fill",
  id = "rootLayout",
  
  --[TOOLBAR]
  {
    LinearLayout,
    layout_width = "fill",
    padding = "16dp",
    id = "toolbarLayout",
    gravity = "center_vertical",
    elevation = "4dp",
    { TextView, text = "تطبيق القرآن الكريم", textSize = "24sp", style = "bold", layout_weight = 1, id = "toolbar_title" },
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

    -- PAGE 0: MAIN MENU
    {
      LinearLayout,
      orientation = "vertical",
      layout_width = "fill",
      layout_height = "fill",
      padding = "16dp",
      id = "mainMenuPage",
      { TextView, text = "القائمة الرئيسية", textSize = "22sp", style = "bold", layout_marginTop = "16dp", layout_marginBottom = "24dp", id = "menuTitle", gravity = "center" },
      {
        LinearLayout,
        orientation = "horizontal",
        layout_width = "fill",
        layout_height = "140dp",
        {
          LinearLayout,
          id = "btnGoQuran",
          orientation = "vertical",
          layout_width = "0",
          layout_height = "fill",
          layout_weight = 1,
          gravity = "center",
          layout_margin = "8dp",
          { ImageView, src = "@android:drawable/ic_menu_book", layout_width = "48dp", layout_height = "48dp", id = "imgQuran" },
          { TextView, text = "المصحف", textSize = "18sp", style = "bold", layout_marginTop = "12dp", id = "txtQuran" }
        },
        {
          LinearLayout,
          id = "btnGoMemorize",
          orientation = "vertical",
          layout_width = "0",
          layout_height = "fill",
          layout_weight = 1,
          gravity = "center",
          layout_margin = "8dp",
          { ImageView, src = "@android:drawable/ic_btn_speak_now", layout_width = "48dp", layout_height = "48dp", id = "imgMemorize" },
          { TextView, text = "المحفظ", textSize = "18sp", style = "bold", layout_marginTop = "12dp", id = "txtMemorize" }
        }
      },
      {
        LinearLayout,
        orientation = "horizontal",
        layout_width = "fill",
        layout_height = "140dp",
        {
          LinearLayout,
          id = "btnGoAzkar",
          orientation = "vertical",
          layout_width = "0",
          layout_height = "fill",
          layout_weight = 1,
          gravity = "center",
          layout_margin = "8dp",
          { ImageView, src = "@android:drawable/btn_star_big_on", layout_width = "48dp", layout_height = "48dp", id = "imgAzkar" },
          { TextView, text = "الأذكار", textSize = "18sp", style = "bold", layout_marginTop = "12dp", id = "txtAzkar" }
        },
        {
          LinearLayout,
          id = "btnGoRadio",
          orientation = "vertical",
          layout_width = "0",
          layout_height = "fill",
          layout_weight = 1,
          gravity = "center",
          layout_margin = "8dp",
          { ImageView, src = "@android:drawable/ic_lock_silent_mode_off", layout_width = "48dp", layout_height = "48dp", id = "imgRadio" },
          { TextView, text = "الراديو", textSize = "18sp", style = "bold", layout_marginTop = "12dp", id = "txtRadio" }
        }
      },
      {
        LinearLayout,
        id = "resumeCard",
        orientation = "vertical",
        layout_width = "fill",
        padding = "16dp",
        layout_marginTop = "20dp",
        visibility = View.GONE,
        { TextView, id = "resumeTitle", text = "استئناف الحفظ", textSize = "18sp", style = "bold" },
        { TextView, id = "resumeInfo", text = "", textSize = "16sp", layout_marginTop = "4dp" },
        { Button, id = "btnResume", text = "متابعة من حيث توقفت", layout_width = "fill", layout_marginTop = "12dp", onClick = function() resumeLastProgress() end }
      },
    },
    
    -- PAGE 1: LIST VIEW
    {
      FrameLayout,
      layout_width = "fill",
      layout_height = "fill",
      
      -- واجهة قائمة السور مع البحث
      {
        LinearLayout,
        id = "surahListContainer",
        orientation = "vertical",
        layout_width = "fill",
        padding = "12dp",
        visibility = View.GONE,
        { TextView, id = "listTitle", text = "قائمة السور", textSize = "20sp", style = "bold", layout_marginBottom = "8dp", visibility = View.GONE },
        { EditText, id = "searchEdt", hint = "بحث باسم السورة أو الرقم...", layout_width = "fill", padding = "16dp", textSize = "18sp", singleLine = true, layout_marginBottom = "12dp" },
        { ListView, id = "surahList", layout_width = "fill", layout_height = "fill", dividerHeight = "0", selector = ColorDrawable(0), clipToPadding = false, paddingBottom = "24dp" }
      },
      
      -- مؤشر التحميل
      {
        ProgressBar,
        id = "loadingIndicator",
        layout_width = "wrap_content",
        layout_height = "wrap_content",
        layout_gravity = "center",
        visibility = View.VISIBLE
      },
      
      -- واجهة عرض الخطأ
      {
        LinearLayout,
        id = "errorContainer",
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "fill",
        gravity = "center",
        padding = "24dp",
        visibility = View.GONE,
        {
          TextView,
          id = "errorText",
          text = "حدث خطأ أثناء تحميل البيانات.\nيرجى التحقق من اتصالك بالإنترنت.",
          textSize = "18sp",
          gravity = "center",
          layout_marginBottom = "16dp"
        },
        {
          Button,
          id = "btnRetry",
          text = "إعادة المحاولة",
          layout_width = "wrap_content",
          paddingLeft = "32dp",
          paddingRight = "32dp",
          onClick = function() loadSurahs() end
        }
      }
    },

    -- PAGE 2: PLAYER / READING MODE
    {
      LinearLayout,
      orientation = "vertical",
      layout_width = "fill",
      layout_height = "fill",
      padding = "16dp",
      gravity = "center_horizontal",
      id = "playerPage",
      {
         ImageView,
         id = "sectionIcon",
         layout_width = "80dp",
         layout_height = "80dp",
         layout_marginTop = "10dp",
         layout_marginBottom = "10dp",
         visibility = View.GONE
      },
      {
        LinearLayout,
        orientation = "horizontal",
        layout_width = "fill",
        gravity = "center_vertical",
        layout_marginBottom = "8dp",
        { TextView, id = "playerTitle", text = "...", textSize = "24sp", style = "bold", layout_weight = 1, gravity = "center" },
        { ImageView, src = "@android:drawable/ic_input_add", layout_width = "36dp", layout_height = "36dp", id = "btnAddBookmark", layout_marginRight = "8dp", onClick = function() addCurrentBookmark() end },
        { ImageView, src = "@android:drawable/ic_menu_share", layout_width = "36dp", layout_height = "36dp", id = "btnShare", onClick = function() shareCurrentAyah() end }
      },
      { TextView, id = "reciterNameDisplay", text = "...", textSize = "16sp", gravity = "center", layout_marginBottom = "16dp" },

      -- CONTAINER FOR BOTH MODES
      {
        FrameLayout,
        layout_width = "fill",
        layout_height = "0",
        layout_weight = 1,
        {
          LinearLayout,
          id = "ayahCard",
          layout_width = "fill",
          layout_height = "fill",
          gravity = "center",
          padding = "8dp",
          { ScrollView, layout_width = "fill", layout_height = "wrap_content", fillViewport = true, { TextView, id = "ayahText", text = "...", textSize = config.font_size .. "sp", gravity = "center", typeface = Typeface.DEFAULT_BOLD, padding = "16dp" } }
        },
        {
          ListView,
          id = "continuousListView",
          layout_width = "fill",
          layout_height = "fill",
          dividerHeight = "0",
          visibility = View.GONE
        }
      },

      { LinearLayout, id = "progressContainer", orientation = "horizontal", layout_width = "fill", gravity = "center", layout_marginTop = "8dp", { TextView, id = "progressText", text = "0 / 0", textSize = "14sp", gravity = "center" } },
      {
        LinearLayout,
        id = "controlsContainer",
        orientation = "vertical",
        layout_width = "fill",
        gravity = "center",
        layout_marginTop = "12dp",
        { TextView, id = "statusText", text = "جاهز", textSize = "16sp", gravity = "center", layout_marginBottom = "16dp", style = "bold" },
        {
          LinearLayout,
          orientation = "horizontal",
          layout_width = "fill",
          gravity = "center",
          { Button, text = "السابق", id = "btnPrev", layout_width = "90dp", textColor = "#FFFFFF", style = "bold", onClick = function() playPrev() end },
          { Button, text = "▶", id = "btnPlay", layout_width = "70dp", layout_height = "70dp", textSize = "30sp", layout_marginLeft = "20dp", layout_marginRight = "20dp", onClick = function() togglePlay() end },
          { Button, text = "التالي", id = "btnNext", layout_width = "90dp", textColor = "#FFFFFF", style = "bold", onClick = function() playNext() end }
        }
      },
      { Button, text = "عودة للقائمة", id = "btnBack", layout_marginTop = "16dp", elevation = "0", onClick = function() stopAudio(); mainFlipper.setDisplayedChild(lastIndex or 1) end }
    },

    -- PAGE 3: INDEX TYPE SELECTION
    {
      LinearLayout,
      orientation = "vertical",
      layout_width = "fill",
      layout_height = "fill",
      padding = "24dp",
      gravity = "center",
      id = "indexTypePage",
      { TextView, text = "اختر طريقة التصفح", textSize = "24sp", style = "bold", layout_marginBottom = "30dp", id = "indexTitle" },
      { Button, id = "btnIndexSurah", text = "السور", layout_width = "fill", layout_marginBottom = "12dp", onClick = function() showQuranList("surahs") end },
      { Button, id = "btnIndexJuz", text = "الأجزاء", layout_width = "fill", layout_marginBottom = "12dp", onClick = function() showQuranList("juzs") end },
      { Button, id = "btnIndexPage", text = "الصفحات", layout_width = "fill", layout_marginBottom = "12dp", onClick = function() showQuranList("pages") end },
      { Button, id = "btnIndexRub", text = "أرباع الأحزاب", layout_width = "fill", layout_marginBottom = "12dp", onClick = function() showQuranList("rubs") end },
      { Button, text = "عودة", id = "btnBackFromIndex", layout_marginTop = "20dp", onClick = function() mainFlipper.setDisplayedChild(0) end },
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
  if menuTitle then menuTitle.setTextColor(Color.parseColor(colors.text_title)) end
  setDesign(btnGoQuran, colors.card_bg, dimens.radius)
  setDesign(btnGoMemorize, colors.card_bg, dimens.radius)
  setDesign(btnGoAzkar, colors.card_bg, dimens.radius)
  setDesign(btnGoRadio, colors.card_bg, dimens.radius)

  if txtQuran then txtQuran.setTextColor(Color.parseColor(colors.text_title)) end
  if txtMemorize then txtMemorize.setTextColor(Color.parseColor(colors.text_title)) end
  if txtAzkar then txtAzkar.setTextColor(Color.parseColor(colors.text_title)) end
  if txtRadio then txtRadio.setTextColor(Color.parseColor(colors.text_title)) end

  if imgQuran then imgQuran.setColorFilter(Color.parseColor(colors.primary)) end
  if imgMemorize then imgMemorize.setColorFilter(Color.parseColor(colors.primary)) end
  if imgAzkar then imgAzkar.setColorFilter(Color.parseColor(colors.primary)) end
  if imgRadio then imgRadio.setColorFilter(Color.parseColor(colors.primary)) end

  local function addLongClick(v, t)
    if not v then return end
    v.onLongClick = function() announceAccess(t); return true end
  end
  addLongClick(btnGoQuran, "قسم تصفح وقراءة القرآن الكريم")
  addLongClick(btnGoMemorize, "قسم المحفظ لتعليم وحفظ القرآن")
  addLongClick(btnGoAzkar, "قسم الأذكار وحصن المسلم")
  addLongClick(btnGoRadio, "قسم إذاعات القرآن الكريم المباشرة")

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
  if btnAddBookmark then btnAddBookmark.setColorFilter(Color.parseColor(colors.bookmark_icon)) end
  if btnShare then btnShare.setColorFilter(Color.parseColor(colors.share_icon)) end
  
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
    else 
      callback(false, "Error code: " .. tostring(code)) 
    end
  end)
end

function loadSurahs()
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
        searchEdt.addTextChangedListener{ onTextChanged = function(s)
          local txt = tostring(s)
          if currentViewType == "radio" then
            updateRadioList(txt)
          elseif currentViewType == "azkar_content" then
            updateAzkarList(txt)
          else
            updateList(txt)
          end
        end }
        setMainViewState("content")
      else
        setMainViewState("error")
      end
    else
      setMainViewState("error")
    end
  end)
end

function updateList(filter)
  local listData, filteredSurahs = {}, {}
  local colors = theme.colors
  local itemLayout = {
    LinearLayout, layout_width = "fill", padding = "6dp",
    {
      LinearLayout, orientation = "vertical", layout_width = "fill", padding = "16dp", backgroundColor = Color.parseColor(colors.card_bg), elevation = "2dp",
      { TextView, id = "tv_title", textSize = "20sp", style = "bold", textColor = Color.parseColor(colors.text_title) },
      { TextView, id = "tv_subtitle", textSize = "16sp", textColor = Color.parseColor(colors.text_body), layout_marginTop = "4dp" }
    }
  }

  local f = filter or ""
  local dataSource = (currentViewType == "surahs" or currentViewType == "quran_reading") and currentSurahsList or allSurahsData

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
      if currentViewType == "surahs" then
        showRangeSelectionDialog(item)
      elseif currentViewType == "juzs" or currentViewType == "pages" or currentViewType == "hizbs" or currentViewType == "rubs" or currentViewType == "quran_reading" then
        handleDivisionClick(item)
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
  end
end

function loadDivisionDetails(type, number)
  local url = BaseURL .. "/" .. type .. "/" .. number .. "/" .. config.current_reciter
  local pd = ProgressDialog.show(activity, "يرجى الانتظار", "جاري جلب الآيات...", true)

  httpGet(url, function(success, body)
    pd.dismiss()
    if not success then
      Toast.makeText(activity, "خطأ في الشبكة", Toast.LENGTH_LONG).show()
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
          surahName = ayahs[i].surah.name
        })
      end

      if #player.currentSurahData > 0 then
        lastIndex = mainFlipper.getDisplayedChild()
        mainFlipper.setDisplayedChild(2)
        setupPlayer(1)
      end
    else
      Toast.makeText(activity, "خطأ في تحميل البيانات", Toast.LENGTH_LONG).show()
    end
  end)
end

function showMemorizationSection()
  currentViewType = "surahs"
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
  setMainViewState("loading")
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
  setMainViewState("loading")
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
  setMainViewState("loading")
  local pages = {}
  for i=1, 604 do
    table.insert(pages, {
      title = "صفحة " .. i,
      subtitle = "تصفح الصفحة رقم " .. i,
      number = i,
      type = "page"
    })
  end
  allSurahsData = pages
  updateList("")
  setMainViewState("content")
end

function loadHizbs()
  setMainViewState("loading")
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
  local colors = theme.colors
  local itemLayout = {
    LinearLayout, layout_width = "fill", padding = "8dp",
    {
      LinearLayout, orientation = "vertical", layout_width = "fill", padding = "16dp", backgroundColor = Color.parseColor(colors.card_bg), elevation = "2dp",
      { TextView, id = "tv_title", textSize = "20sp", style = "bold", textColor = Color.parseColor(colors.text_title), gravity = "right" },
      { TextView, id = "tv_subtitle", textSize = "14sp", textColor = Color.parseColor(colors.primary), layout_marginTop = "8dp" }
    }
  }

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
      if player.currentAudioUrl == targetUrl then
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
  local colors = theme.colors
  local itemLayout = {
    LinearLayout, layout_width = "fill", padding = "8dp",
    {
      LinearLayout, orientation = "vertical", layout_width = "fill", padding = "16dp", backgroundColor = Color.parseColor(colors.card_bg), elevation = "2dp",
      { TextView, id = "tv_title", textSize = "20sp", style = "bold", textColor = Color.parseColor(colors.text_title), gravity = "right" },
      { TextView, id = "tv_subtitle", textSize = "14sp", textColor = Color.parseColor(colors.primary), layout_marginTop = "8dp" }
    }
  }

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
  local url = BaseURL .. "/surah/" .. number .. "/editions/quran-simple," .. config.current_reciter
  local pd = ProgressDialog.show(activity, "يرجى الانتظار", "جاري جلب الآيات...", true)
  
  httpGet(url, function(success, body)
    pd.dismiss()
    if not success then
      Toast.makeText(activity, "خطأ في الشبكة، لم يتم تحميل السورة", Toast.LENGTH_LONG).show()
      return
    end

    local decode_ok, json = pcall(cjson.decode, body)
    if not (decode_ok and json and json.code == 200 and json.data and #json.data >= 2) then
      Toast.makeText(activity, "خطأ: استجابة غير متوقعة من الخادم.", Toast.LENGTH_LONG).show()
      return
    end
    
    local d1, d2 = json.data[1], json.data[2]
    local dataText, dataAudio

    -- تحديد نسخة النص ونسخة الصوت بأمان
    if d1 and d1.edition and d1.edition.type == "audio" then
      dataAudio, dataText = d1, d2
    else
      dataText, dataAudio = d1, d2
    end
    
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
            numberInSurah = curNum
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

  if currentViewType == "surahs" or currentViewType == "juzs" or currentViewType == "pages" or currentViewType == "rubs" then
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
  else
    isContinuousMode = false
  end

  if isContinuousMode then
    ayahCard.setVisibility(View.GONE)
    continuousListView.setVisibility(View.VISIBLE)
    progressContainer.setVisibility(View.GONE)
    controlsContainer.setVisibility(View.GONE)
    updateContinuousList()
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
  else
    announceAccess("تم فتح وضع القراءة لـ " .. player.currentSurahName .. ". اسحب لأسفل لتصفح الآيات.")
  end
end

function updateContinuousList()
  local listData = {}
  local colors = theme.colors
  local itemLayout = {
    LinearLayout, layout_width = "fill", padding = "8dp", orientation = "vertical",
    {
      TextView, id = "tv_ayah", textSize = config.font_size .. "sp", textColor = Color.parseColor(colors.text_title),
      gravity = "right", padding = "16dp", layout_width = "fill"
    },
    {
       LinearLayout, layout_width = "fill", orientation = "horizontal", gravity = "left", padding = "8dp",
       { TextView, id = "tv_num", textSize = "14sp", textColor = Color.parseColor(colors.primary), style = "bold" },
       { View, layout_weight = 1 },
       { ImageView, id = "btnPlayAyah", src = "@android:drawable/ic_media_play", layout_width = "32dp", layout_height = "32dp", colorFilter = Color.parseColor(colors.primary) }
    }
  }

  for i, a in ipairs(player.currentSurahData) do
    table.insert(listData, { tv_ayah = a.text .. " ﴿ " .. a.numberInSurah .. " ﴾", tv_num = (a.surahName or player.currentSurahName) .. " - آية " .. a.numberInSurah })
  end

  local adapter = LuaAdapter(activity, listData, itemLayout)
  continuousListView.setAdapter(adapter)

  continuousListView.setOnItemClickListener(AdapterView.OnItemClickListener{
    onItemClick = function(parent, view, position, id)
      local item = player.currentSurahData[position+1]
      playAyahInContinuous(position+1)
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
  stopAudio()
  player.isPlaying = true
  player.currentAudioUrl = url
  local success, err = pcall(function() player.media.setDataSource(url); player.media.prepareAsync() end)
  if not success then
    statusText.text = "خطأ في رابط الصوت"
    Toast.makeText(activity, "خطأ في تشغيل الصوت: " .. tostring(err), Toast.LENGTH_LONG).show()
    return
  end

  player.media.setOnErrorListener{ onError = function(mp, what, extra)
    Toast.makeText(activity, "خطأ في مشغل الوسائط: " .. what, Toast.LENGTH_SHORT).show()
    return true
  end}
  
  player.media.setOnPreparedListener{ onPrepared = function(mp) if player.isPlaying then mp.start(); updatePlayButton(true) end end }
  player.media.setOnCompletionListener{ onCompletion = function(mp) onAyahComplete() end }
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
    if config.delay_seconds > 0 then startDelay(function() player.media.start() end) else player.media.start() end
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
  Handler().postDelayed(Runnable{ run = function() if player.isPlaying then callback() end end }, config.delay_seconds * 1000)
end

function togglePlay()
  if player.media.isPlaying() then
    player.media.pause(); player.isPlaying = false; updatePlayButton(false)
    announceAccess("تم الإيقاف المؤقت")
  else
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
  pcall(function() if player.media.isPlaying() then player.media.stop() end; player.media.reset() end)
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
      return true
    elseif current == 1 then -- List Page
      if currentViewType == "azkar_content" then
        showAzkarSection()
        return true
      end
      if currentViewType == "surahs" or currentViewType == "azkar_categories" or currentViewType == "radio" then
         mainFlipper.setDisplayedChild(0)
      else
         mainFlipper.setDisplayedChild(3) -- Back to Index Selection (Juz, Page, Rub)
      end
      return true
    elseif current == 3 then -- Index Selection
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

function startApp()
  applyTheme()
  if showResumeCard then showResumeCard() end

  -- Card Click Listeners
  if btnGoQuran then btnGoQuran.onClick = function() showQuranSection() end end
  if btnGoMemorize then btnGoMemorize.onClick = function() showMemorizationSection() end end
  if btnGoAzkar then btnGoAzkar.onClick = function() showAzkarSection() end end
  if btnGoRadio then btnGoRadio.onClick = function() showRadioSection() end end

setAccessibility(toolbar_title, "تطبيق القرآن الكريم، الصفحة الرئيسية", "heading")
setAccessibility(btn_settings, "فتح الإعدادات", "button")
setAccessibility(btn_theme, "تبديل الوضع الليلي", "button")
setAccessibility(btn_bookmarks, "عرض الإشارات المرجعية", "button")
setAccessibility(btnGoQuran, "المصحف: تصفح وقراءة القرآن الكريم", "button")
setAccessibility(btnGoMemorize, "المحفظ القرآني: قسم الحفظ والتكرار", "button")
setAccessibility(btnGoAzkar, "الأذكار: الأذكار النبوية وحصن المسلم", "button")
setAccessibility(btnGoRadio, "الراديو: إذاعات القرآن الكريم المباشرة", "button")
setAccessibility(btnIndexSurah, "عرض فهرس السور", "button")
setAccessibility(btnIndexJuz, "عرض فهرس الأجزاء", "button")
setAccessibility(btnIndexPage, "عرض فهرس الصفحات", "button")
setAccessibility(btnIndexRub, "عرض فهرس أرباع الأحزاب", "button")
setAccessibility(searchEdt, "مربع بحث، اكتب اسم السورة أو الرقم", "edit")
setAccessibility(btnPlay, "تشغيل المقطع الصوتي", "button")
setAccessibility(btnAddBookmark, "إضافة إشارة مرجعية", "button")
setAccessibility(btnShare, "مشاركة الآية الحالية كمتن نصي", "button")
setAccessibility(btnRetry, "إعادة محاولة تحميل البيانات", "button")
setAccessibility(btnBack, "زر العودة للقائمة السابقة", "button")
setAccessibility(btnBackFromIndex, "زر العودة للقائمة الرئيسية", "button")

  pcall(function() ayahText.setLineSpacing(0, 1.4) end)
  mainFlipper.setDisplayedChild(0)
  announceAccess("تطبيق القرآن الكريم، القائمة الرئيسية")
end

startApp()