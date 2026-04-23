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
  currentRepeatCount = 0
}

local allSurahsData = {}
local BaseURL = "https://api.alquran.cloud/v1"

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
    { TextView, text = "المحفظ القرآني", textSize = "24sp", textColor = "#FFFFFF", style = "bold", layout_weight = 1, id = "toolbar_title" },
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
    
    -- PAGE 1: SURAH LIST
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
        {
          LinearLayout,
          id = "resumeCard",
          orientation = "vertical",
          layout_width = "fill",
          padding = "16dp",
          layout_marginBottom = "12dp",
          visibility = View.GONE,
          { TextView, id = "resumeTitle", text = "استئناف الحفظ", textSize = "18sp", style = "bold" },
          { TextView, id = "resumeInfo", text = "", textSize = "16sp", layout_marginTop = "4dp" },
          { Button, id = "btnResume", text = "متابعة من حيث توقفت", layout_width = "fill", layout_marginTop = "12dp", onClick = function() resumeLastProgress() end }
        },
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

    -- PAGE 2: PLAYER
    {
      LinearLayout,
      orientation = "vertical",
      layout_width = "fill",
      layout_height = "fill",
      padding = "16dp",
      gravity = "center_horizontal",
      id = "playerPage",
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
      {
        LinearLayout,
        layout_width = "fill",
        layout_height = "0",
        layout_weight = 1,
        id = "ayahCard",
        gravity = "center",
        padding = "8dp",
        { ScrollView, layout_width = "fill", layout_height = "wrap_content", fillViewport = true, { TextView, id = "ayahText", text = "...", textSize = config.font_size .. "sp", gravity = "center", typeface = Typeface.DEFAULT_BOLD, padding = "16dp" } }
      },
      { LinearLayout, orientation = "horizontal", layout_width = "fill", gravity = "center", layout_marginTop = "8dp", { TextView, id = "progressText", text = "0 / 0", textSize = "14sp", gravity = "center" } },
      {
        LinearLayout,
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
      { Button, text = "عودة للقائمة", id = "btnBack", layout_marginTop = "16dp", elevation = "0", onClick = function() stopAudio(); mainFlipper.showPrevious() end }
    }
  }
}

-- ==========================================
-- 🚀 5. MAIN EXECUTION & STYLING
-- ==========================================

activity.setContentView(loadlayout(layout))

function applyTheme()
  local colors = theme.colors
  rootLayout.setBackgroundColor(Color.parseColor(colors.background))
  setDesign(toolbarLayout, colors.primary, 0)
  setDesign(resumeCard, colors.card_bg, dimens.radius)
  if resumeTitle then resumeTitle.setTextColor(Color.parseColor(colors.text_title)) end
  if resumeInfo then resumeInfo.setTextColor(Color.parseColor(colors.text_body)) end
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

applyTheme()

setAccessibility(toolbar_title, "المحفظ القرآني، الصفحة الرئيسية", "heading")
setAccessibility(btn_settings, "فتح الإعدادات", "button")
setAccessibility(btn_theme, "تبديل الوضع الليلي", "button")
setAccessibility(btn_bookmarks, "عرض الإشارات المرجعية", "button")
setAccessibility(searchEdt, "مربع بحث، اكتب اسم السورة أو رقمها", "edit")
setAccessibility(btnPlay, "تشغيل المقطع الصوتي", "button")
setAccessibility(btnAddBookmark, "إضافة إشارة مرجعية", "button")
setAccessibility(btnShare, "مشاركة الآية", "button")
setAccessibility(btnRetry, "إعادة محاولة تحميل قائمة السور", "button")

pcall(function() ayahText.setLineSpacing(0, 1.4) end)

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
    announceAccess("جاري تحميل قائمة السور")
  elseif state == "error" then
    loadingIndicator.setVisibility(View.GONE)
    errorContainer.setVisibility(View.VISIBLE)
    surahListContainer.setVisibility(View.GONE)
    announceAccess("حدث خطأ في التحميل")
  elseif state == "content" then
    loadingIndicator.setVisibility(View.GONE)
    errorContainer.setVisibility(View.GONE)
    surahListContainer.setVisibility(View.VISIBLE)
    announceAccess("تم تحميل القائمة بنجاح")
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
        allSurahsData = {} 
        for i = 1, #data do
          table.insert(allSurahsData, {
            title = data[i].number .. ". " .. data[i].name,
            subtitle = data[i].englishName .. " | " .. data[i].numberOfAyahs .. " آية",
            number = data[i].number,
            numberOfAyahs = data[i].numberOfAyahs, 
            englishName = data[i].name
          })
        end
        updateList("")
        showResumeCard()
        searchEdt.addTextChangedListener{ onTextChanged = function(s) updateList(tostring(s)) end }
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
      LinearLayout, orientation = "vertical", layout_width = "fill", padding = "16dp", backgroundColor = colors.card_bg, elevation = "2dp",
      { TextView, id = "tv_title", textSize = "20sp", style = "bold", textColor = colors.text_title },
      { TextView, id = "tv_subtitle", textSize = "16sp", textColor = colors.text_body, layout_marginTop = "4dp" }
    }
  }

  local f = filter or ""
  for i = 1, #allSurahsData do
    local s = allSurahsData[i]
    if f == "" or string.find(s.title, f, 1, true) or string.find(tostring(s.number), f, 1, true) then
      table.insert(filteredSurahs, s)
      table.insert(listData, { tv_title = s.title, tv_subtitle = s.subtitle })
    end
  end

  local adapter = LuaAdapter(activity, listData, itemLayout)
  surahList.setAdapter(adapter)

  surahList.setOnItemClickListener(AdapterView.OnItemClickListener{
    onItemClick = function(parent, view, position, id)
      showRangeSelectionDialog(filteredSurahs[position + 1])
    end
  })
end

function showRangeSelectionDialog(surahMap)
  local colors = theme.colors
  local rangeLayout = {
    LinearLayout, orientation = "vertical", padding = "24dp", layout_width = "fill", backgroundColor = colors.card_bg,
    { TextView, text = "تحديد الآيات: " .. surahMap.englishName, textSize = "22sp", style = "bold", textColor = colors.primary, layout_marginBottom = "24dp", gravity = "center" },
    {
      LinearLayout, orientation = "horizontal", layout_width = "fill", gravity = "center",
      { TextView, text = "من آية:", textSize = "18sp", textColor = colors.text_title },
      { EditText, id = "fromAyahEdt", inputType = "number", text = "1", width = "80dp", gravity = "center" },
      { TextView, text = "إلى آية:", textSize = "18sp", textColor = colors.text_title, layout_marginLeft = "16dp" },
      { EditText, id = "toAyahEdt", inputType = "number", text = tostring(surahMap.numberOfAyahs), width = "80dp", gravity = "center" }
    }
  }

  local dlg = AlertDialog.Builder(activity)
  dlg.setView(loadlayout(rangeLayout))
  dlg.setPositiveButton("بدء الحفظ", function()
    local startA = tonumber(fromAyahEdt.text) or 1
    local endA = tonumber(toAyahEdt.text) or surahMap.numberOfAyahs
    if startA < 1 then startA = 1 end
    if endA > surahMap.numberOfAyahs then endA = surahMap.numberOfAyahs end
    if startA > endA then startA = endA end
    loadSurahDetails(surahMap.number, startA, endA)
  end)
  dlg.setNegativeButton("إلغاء", nil)
  dlg.show()
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
      mainFlipper.showNext()
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
  
  playerTitle.text = player.currentSurahName .. " (" .. ayah.numberInSurah .. ")"
  setAccessibility(playerTitle, playerTitle.text, "heading")
  
  local reciterName = "قارئ محدد"
  for k, v in pairs(reciters) do if v.id == config.current_reciter then reciterName = v.name; break end end
  reciterNameDisplay.text = "القارئ: " .. reciterName
  
  ayahText.text = ayah.text
  statusText.text = "جاهز للتشغيل"
  progressText.text = index .. " / " .. #player.currentSurahData
  saveCurrentProgress()
  
  announceAccess("الآية " .. ayah.numberInSurah .. ". جاهزة.")
  setupMediaPlayer(ayah.audio)
end

function setupMediaPlayer(url)
  stopAudio()
  local success, err = pcall(function() player.media.setDataSource(url); player.media.prepareAsync() end)
  if not success then statusText.text = "خطأ في رابط الصوت"; return end
  
  player.media.setOnPreparedListener{ onPrepared = function(mp) if player.isPlaying then mp.start(); updatePlayButton(true) end end }
  player.media.setOnCompletionListener{ onCompletion = function(mp) onAyahComplete() end }
end

function onAyahComplete()
  player.currentRepeatCount = player.currentRepeatCount + 1
  if player.currentRepeatCount < config.repeat_ayah then
    statusText.text = "تكرار (" .. player.currentRepeatCount .. " من " .. config.repeat_ayah .. ")"
    if config.delay_seconds > 0 then startDelay(function() player.media.start() end) else player.media.start() end
  else
    if player.currentAyahIndex < #player.currentSurahData then
      statusText.text = "الانتقال للآية التالية..."
      if config.delay_seconds > 0 then startDelay(function() playNext() end) else playNext() end
    else
      statusText.text = "تم الانتهاء من الحفظ 🎉"
      updatePlayButton(false); player.isPlaying = false
      announceAccess("تم الانتهاء من حفظ جميع الآيات المحددة")
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
  else
    player.media.start(); player.isPlaying = true; updatePlayButton(true)
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
  player.isPlaying = false; updatePlayButton(false)
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
    if mainFlipper.getDisplayedChild() == 1 then
      stopAudio()
      mainFlipper.showPrevious()
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

loadSurahs()