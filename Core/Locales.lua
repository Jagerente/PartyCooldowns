local _, ns = ...

local L = {}
ns.L = L

local STRINGS = {}

STRINGS.enUS = {
    NAV_GENERAL = "General",
    NAV_DISPLAY = "Display",
    NAV_SPELLS = "Spells",
    NAV_SYNC = "Party",
    NAV_ABOUT = "About",

    PREVIEW = "Preview",
    PREVIEW_DRAG_HINT = "Preview, drag to move",
    PREVIEW_YOU = "You",

    SECTION_TRACKING = "Tracking",
    ENABLE = "Track party cooldowns",
    SHOW_SELF = "Include my own cooldowns",
    SHOW_SELF_DESC = "Works when your party frames show you.",
    SHOW_UNSYNCED = "Show players without the addon",
    SHOW_UNSYNCED_DESC = "Their icons stay dim and their timers can be off.",
    HIDE_READY = "Only show cooldowns in progress",

    SECTION_ASK = "Ask for a cooldown",
    ASK_ON_CLICK = "Click a ready icon to ask",
    ASK_ON_CLICK_DESC = "Writes in chat: Tanky, please use Shield Wall",
    ASK_CHANNEL = "Send to",
    ASK_CHANNEL_party = "Party chat",
    ASK_CHANNEL_whisper = "Whisper",
    ASK_MESSAGE_party = "%s, please use %s",
    ASK_MESSAGE_whisper = "Please use %s",
    ASK_PREVIEW = "Party Cooldowns preview, not sent: %s",
    ASK_LOCKED = "The game is blocking addon chat right now. Type the request yourself.",
    ASK_OFFLINE = "%s is offline.",

    SECTION_OTHER = "Other",
    TOOLTIPS = "Tooltips on icons",
    MINIMAP_BUTTON = "Minimap button",
    MINIMAP_LEFT_CLICK = "Click: settings",
    MINIMAP_RIGHT_CLICK = "Right-click: preview",
    MINIMAP_DRAG = "Drag: move around the minimap",
    LANGUAGE = "Language",
    LANGUAGE_auto = "Game",
    LANGUAGE_enUS = "English",
    LANGUAGE_ruRU = "Русский",
    RESET = "Reset all settings",
    RESET_CONFIRM = "Click again to reset everything",

    SECTION_POSITION = "Position",
    SECTION_ICONS = "Icons",
    PICKER_FRAME = "Party frame",
    SIDE_LEFT = "Left",
    SIDE_RIGHT = "Right",
    SIDE_TOP = "Above",
    SIDE_BOTTOM = "Below",
    ALIGN_START_V = "top edge",
    ALIGN_END_V = "bottom edge",
    ALIGN_START_H = "left edge",
    ALIGN_END_H = "right edge",
    ALIGN_CENTER = "centered",
    OFFSET_X = "Horizontal offset",
    OFFSET_Y = "Vertical offset",
    ICON_SKIN = "Look",
    SKIN_flat = "Flat",
    SKIN_blizzard = "Blizzard",
    ICON_SIZE = "Size",
    SPACING = "Spacing",
    PER_ROW = "Per row",

    SECTION_TIMER = "Cooldown",
    TIMER_TEXT = "Countdown text",
    TIMER_DECIMALS = "Tenths below 10 s",
    SWIPE = "Clock sweep",
    DESATURATE = "Grey on cooldown",
    PULSE = "Flash when ready",

    RACIALS = "Racials",
    BTN_DEFAULTS = "Defaults",
    BTN_ENABLE_ALL = "Enable all",
    BTN_DISABLE_ALL = "Disable all",
    TALENT_TAG = "Talent",
    CAT_interrupt = "Interrupt",
    CAT_cc = "Control",
    CAT_defensive = "Defensive",
    CAT_external = "Support",
    CAT_offensive = "Offensive",
    CAT_utility = "Utility",
    CUSTOM_SPELLS = "Custom spells",
    CUSTOM_ADD = "Add",
    CUSTOM_PLACEHOLDER = "Spell ID or name",
    CUSTOM_HINT = "Shows for players with the addon who know the spell.",
    CUSTOM_ERROR_NOT_FOUND = "No spell with this ID. Names work only for spells in your spellbook.",
    CUSTOM_ERROR_BUILTIN = "%s is already in the list on the %s tab.",
    CUSTOM_ERROR_ADDED = "%s is already added on the %s tab.",
    CUSTOM_ERROR_LIMIT = "You can add up to %d spells. Remove one first.",

    SYNC_STATUS_LOCKED = "Paused by the game during this fight. Resumes on its own.",
    SYNC_STATUS_SOLO = "You are not in a party.",
    SYNC_MEMBER_SYNCED = "Has the addon",
    SYNC_MEMBER_NONE = "No addon, timers can be off",
    SYNC_REQUEST = "Resync",

    TIP_READY_IN = "Ready in",
    TIP_LEFT_CLICK = "Left-click",
    TIP_RIGHT_CLICK = "Right-click",
    TIP_SETTINGS = "Settings",
    TIP_ASK_party = "Ask in party chat",
    TIP_ASK_whisper = "Ask in a whisper",

    SETTINGS_OPEN = "Open settings",

    ABOUT_AUTHOR = "Author",
    ABOUT_SHAPESHIFT = "Click to shapeshift",
    ABOUT_WEBSITE = "Website",
    ABOUT_COPY = "Copy",
    ABOUT_COPY_HINT = "Press Ctrl+C",
    ABOUT_COMMAND = "Chat command",
    ABOUT_COMMAND_DESC = "Opens this window",
    ABOUT_FONT_CREDIT = "Fira Sans font, SIL Open Font License 1.1.",
}

STRINGS.ruRU = {
    NAV_GENERAL = "Общие",
    NAV_DISPLAY = "Вид",
    NAV_SPELLS = "Заклинания",
    NAV_SYNC = "Группа",
    NAV_ABOUT = "Об аддоне",

    PREVIEW = "Превью",
    PREVIEW_DRAG_HINT = "Превью, можно перетащить",
    PREVIEW_YOU = "Вы",

    SECTION_TRACKING = "Отслеживание",
    ENABLE = "Отслеживать кулдауны группы",
    SHOW_SELF = "Показывать и свои кулдауны",
    SHOW_SELF_DESC = "Работает, если пати-фреймы показывают и вас.",
    SHOW_UNSYNCED = "Показывать игроков без аддона",
    SHOW_UNSYNCED_DESC = "Их иконки приглушены, таймеры могут быть неточными.",
    HIDE_READY = "Только идущие кулдауны",

    SECTION_ASK = "Просьба о кулдауне",
    ASK_ON_CLICK = "Просить по клику на готовую иконку",
    ASK_ON_CLICK_DESC = "Пишет в чат: Tanky, нажми Shield Wall, пожалуйста",
    ASK_CHANNEL = "Куда писать",
    ASK_CHANNEL_party = "Чат группы",
    ASK_CHANNEL_whisper = "Шёпот",
    ASK_MESSAGE_party = "%s, нажми %s, пожалуйста",
    ASK_MESSAGE_whisper = "Нажми %s, пожалуйста",
    ASK_PREVIEW = "Превью Party Cooldowns, не отправлено: %s",
    ASK_LOCKED = "Игра сейчас не даёт аддонам писать в чат. Напишите просьбу сами.",
    ASK_OFFLINE = "%s не в сети.",

    SECTION_OTHER = "Прочее",
    TOOLTIPS = "Подсказки на иконках",
    MINIMAP_BUTTON = "Кнопка у миникарты",
    MINIMAP_LEFT_CLICK = "Клик: настройки",
    MINIMAP_RIGHT_CLICK = "Правый клик: превью",
    MINIMAP_DRAG = "Перетаскивание: сдвинуть по краю карты",
    LANGUAGE = "Язык",
    LANGUAGE_auto = "Как в игре",
    LANGUAGE_enUS = "English",
    LANGUAGE_ruRU = "Русский",
    RESET = "Сбросить все настройки",
    RESET_CONFIRM = "Нажмите ещё раз, чтобы сбросить всё",

    SECTION_POSITION = "Позиция",
    SECTION_ICONS = "Иконки",
    PICKER_FRAME = "Пати-фрейм",
    SIDE_LEFT = "Слева",
    SIDE_RIGHT = "Справа",
    SIDE_TOP = "Сверху",
    SIDE_BOTTOM = "Снизу",
    ALIGN_START_V = "по верхнему краю",
    ALIGN_END_V = "по нижнему краю",
    ALIGN_START_H = "по левому краю",
    ALIGN_END_H = "по правому краю",
    ALIGN_CENTER = "по центру",
    OFFSET_X = "По горизонтали",
    OFFSET_Y = "По вертикали",
    ICON_SKIN = "Вид",
    SKIN_flat = "Плоский",
    SKIN_blizzard = "Blizzard",
    ICON_SIZE = "Размер",
    SPACING = "Отступ",
    PER_ROW = "В ряду",

    SECTION_TIMER = "Кулдаун",
    TIMER_TEXT = "Текст таймера",
    TIMER_DECIMALS = "Десятые до 10 с",
    SWIPE = "Затемнение",
    DESATURATE = "Серые на кулдауне",
    PULSE = "Вспышка в конце",

    RACIALS = "Расовые",
    BTN_DEFAULTS = "По умолчанию",
    BTN_ENABLE_ALL = "Включить все",
    BTN_DISABLE_ALL = "Выключить все",
    TALENT_TAG = "Талант",
    CAT_interrupt = "Прерывание",
    CAT_cc = "Контроль",
    CAT_defensive = "Защита",
    CAT_external = "Поддержка",
    CAT_offensive = "Урон",
    CAT_utility = "Полезное",
    CUSTOM_SPELLS = "Свои заклинания",
    CUSTOM_ADD = "Добавить",
    CUSTOM_PLACEHOLDER = "ID или название",
    CUSTOM_HINT = "Видно у игроков с аддоном, которые знают заклинание.",
    CUSTOM_ERROR_NOT_FOUND = "Нет заклинания с таким ID. Название работает только для заклинаний из вашей книги.",
    CUSTOM_ERROR_BUILTIN = "%s уже есть в списке на вкладке «%s».",
    CUSTOM_ERROR_ADDED = "%s уже добавлено на вкладке «%s».",
    CUSTOM_ERROR_LIMIT = "Можно добавить не больше %d заклинаний. Сначала уберите одно.",

    SYNC_STATUS_LOCKED = "Обмен таймерами приостановлен на время боя, продолжится сам.",
    SYNC_STATUS_SOLO = "Вы не в группе.",
    SYNC_MEMBER_SYNCED = "Есть аддон",
    SYNC_MEMBER_NONE = "Нет аддона, таймеры неточные",
    SYNC_REQUEST = "Синхронизировать",

    TIP_READY_IN = "Готово через",
    TIP_LEFT_CLICK = "ЛКМ",
    TIP_RIGHT_CLICK = "ПКМ",
    TIP_SETTINGS = "Настройки",
    TIP_ASK_party = "Попросить в чате группы",
    TIP_ASK_whisper = "Попросить шёпотом",

    SETTINGS_OPEN = "Открыть настройки",

    ABOUT_AUTHOR = "Автор",
    ABOUT_SHAPESHIFT = "Нажмите, чтобы сменить облик",
    ABOUT_WEBSITE = "Сайт",
    ABOUT_COPY = "Копировать",
    ABOUT_COPY_HINT = "Нажмите Ctrl+C",
    ABOUT_COMMAND = "Команда в чате",
    ABOUT_COMMAND_DESC = "Открывает это окно",
    ABOUT_FONT_CREDIT = "Шрифт Fira Sans, лицензия SIL Open Font License 1.1.",
}

ns.LANGUAGES = { "auto", "enUS", "ruRU" }

local function Resolve(choice)
    if choice and STRINGS[choice] then return choice end
    local gameLocale = GetLocale()
    return STRINGS[gameLocale] and gameLocale or "enUS"
end

function ns.ApplyLanguage(choice)
    local code = Resolve(choice)
    wipe(L)
    for key, text in pairs(STRINGS.enUS) do
        L[key] = text
    end
    if code ~= "enUS" then
        for key, text in pairs(STRINGS[code]) do
            L[key] = text
        end
    end
    ns.Fire("LOCALE_CHANGED")
end

ns.ApplyLanguage("auto")

ns.Listen("DB_READY", function()
    ns.ApplyLanguage(ns.db.locale)
end)

ns.Listen("SETTING_CHANGED", function(key)
    if key == "locale" or key == nil then
        ns.ApplyLanguage(ns.db.locale)
    end
end)
