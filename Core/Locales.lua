local _, ns = ...

local L = {}
ns.L = L

local STRINGS = {}

STRINGS.enUS = {
    NAV_GENERAL = "General",
    NAV_DISPLAY = "Display",
    NAV_SPELLS = "Spells",
    NAV_SYNC = "Sync",
    NAV_ABOUT = "About",

    PREVIEW = "Preview",
    PREVIEW_DESC = "Sample cooldowns on your party frames, or on stand-in frames when you are solo.",
    PREVIEW_DRAG_HINT = "Preview — drag to move",
    PREVIEW_YOU = "You",

    SECTION_BEHAVIOR = "Behavior",
    SECTION_FRAMES = "Attach to",
    ENABLE = "Track party cooldowns",
    ENABLE_DESC = "Show cooldown icons next to party frames.",
    SHOW_SELF = "Include my own cooldowns",
    SHOW_SELF_DESC = "Adds a row next to your own frame when the party frames show you.",
    SHOW_UNSYNCED = "Show members without the addon",
    SHOW_UNSYNCED_DESC = "Their icons stay dim until the game reveals a cast. Exact timers need Party Cooldowns on their side.",
    HIDE_READY = "Only show cooldowns in progress",
    HIDE_READY_DESC = "An icon appears when a cooldown starts and goes away when it is ready.",
    TOOLTIPS = "Tooltips on icons",
    TOOLTIPS_DESC = "Hover an icon to see the spell and the time left.",
    MINIMAP_BUTTON = "Minimap button",
    MINIMAP_BUTTON_DESC = "Click opens this window, right-click toggles the preview.",
    MINIMAP_LEFT_CLICK = "Click: settings",
    MINIMAP_RIGHT_CLICK = "Right-click: preview",
    MINIMAP_DRAG = "Drag: move around the minimap",
    PROVIDER_auto = "Auto",
    PROVIDER_ellesmere = "EllesmereUI",
    PROVIDER_compact = "Raid-style",
    PROVIDER_blizzard = "Blizzard",
    PROVIDER_preview = "Preview frames",
    LANGUAGE = "Language",
    LANGUAGE_auto = "Game",
    LANGUAGE_enUS = "English",
    LANGUAGE_ruRU = "Русский",
    SECTION_ASK = "Ask for a cooldown",
    ASK_ON_CLICK = "Click a ready icon to ask",
    ASK_ON_CLICK_DESC = "Sends a chat message asking that player to use the spell.",
    ASK_CHANNEL = "Send to",
    ASK_CHANNEL_party = "Party chat",
    ASK_CHANNEL_whisper = "Whisper",
    ASK_MESSAGE_party = "%s, please use %s",
    ASK_MESSAGE_whisper = "Please use %s",
    ASK_PREVIEW = "Party Cooldowns preview, not sent: %s",
    ASK_LOCKED = "The game is blocking addon chat messages right now.",
    ASK_OFFLINE = "%s is offline.",
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
    PICKER_HINT = "Click a dot to put the icons there. The offset from the frame is kept when you switch sides.",
    OFFSET_X = "Horizontal offset",
    OFFSET_Y = "Vertical offset",
    ICON_SIZE = "Icon size",
    SPACING = "Space between icons",
    PER_ROW = "Icons per row",
    ICON_SKIN = "Icon look",
    SKIN_flat = "Flat",
    SKIN_blizzard = "Blizzard",

    SECTION_TIMER = "Timer",
    SECTION_STYLE = "Style",
    TIMER_TEXT = "Countdown text",
    TIMER_TEXT_DESC = "Time left, printed over the icon.",
    TIMER_DECIMALS = "Tenths of a second below 10",
    TIMER_DECIMALS_DESC = "4.2 instead of 5 near the end.",
    SWIPE = "Clock sweep",
    SWIPE_DESC = "Dark sweep over the icon while it is on cooldown.",
    DESATURATE = "Grey out while on cooldown",
    DESATURATE_DESC = "Ready icons keep their color, the rest turn grey.",
    PULSE = "Flash when ready",
    PULSE_DESC = "A short flash when a cooldown comes back.",

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
    CUSTOM_PLACEHOLDER_DESC = "Type a spell ID and press Enter. Any rank works. A name works too, but only for spells in your own spellbook.",
    CUSTOM_HINT = "Shows for party members who have Party Cooldowns and know the spell.",
    CUSTOM_REMOVE = "Remove from the list",
    CUSTOM_ERROR_NOT_FOUND = "No spell with this ID. Names work only for spells in your spellbook.",
    CUSTOM_ERROR_BUILTIN = "%s is already in the list on the %s tab.",
    CUSTOM_ERROR_ADDED = "%s is already added on the %s tab.",
    CUSTOM_ERROR_LIMIT = "You can add up to %d spells. Remove one first.",

    SYNC_EXPLAIN = "WoW Forever hides other players' casts from addons. Exact timers come from members who run Party Cooldowns too; for everyone else only casts the game reveals are tracked.",
    SYNC_STATUS_OK = "Addon channel open",
    SYNC_STATUS_LOCKED = "Paused by the game during this encounter — updates resume on their own",
    SYNC_STATUS_SOLO = "Not in a party",
    SYNC_MEMBERS = "Party",
    SYNC_MEMBER_SYNCED = "Synced, %d spells",
    SYNC_MEMBER_NONE = "No addon",
    SYNC_NO_MEMBERS = "Nobody to sync with yet.",
    SYNC_REQUEST = "Resync",

    TOOLTIP_COOLDOWN = "Ready in %s",
    TOOLTIP_READY = "Ready",
    TOOLTIP_UNKNOWN = "Unknown — no addon on this player",
    TOOLTIP_NO_SYNC = "Without Party Cooldowns on their side only casts the game reveals are tracked.",
    TOOLTIP_ASK_party = "Click: ask in party chat",
    TOOLTIP_ASK_whisper = "Click: ask in a whisper",

    SETTINGS_DESC = "Party cooldowns next to the party frames.",
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
    PREVIEW_DESC = "Пример кулдаунов на пати-фреймах или на заглушках, если вы не в группе.",
    PREVIEW_DRAG_HINT = "Превью — перетащите, чтобы сдвинуть",
    PREVIEW_YOU = "Вы",

    SECTION_BEHAVIOR = "Поведение",
    SECTION_FRAMES = "Привязка",
    ENABLE = "Отслеживать кулдауны группы",
    ENABLE_DESC = "Иконки кулдаунов рядом с пати-фреймами.",
    SHOW_SELF = "Показывать и свои кулдауны",
    SHOW_SELF_DESC = "Ряд у вашего фрейма, если пати-фреймы показывают и вас.",
    SHOW_UNSYNCED = "Показывать игроков без аддона",
    SHOW_UNSYNCED_DESC = "Их иконки приглушены, пока игра не раскроет каст. Точные таймеры — только если аддон стоит и у них.",
    HIDE_READY = "Только идущие кулдауны",
    HIDE_READY_DESC = "Иконка появляется, когда кулдаун начался, и пропадает, когда он готов.",
    TOOLTIPS = "Подсказки на иконках",
    TOOLTIPS_DESC = "Наведите на иконку — покажет заклинание и остаток времени.",
    MINIMAP_BUTTON = "Кнопка у миникарты",
    MINIMAP_BUTTON_DESC = "Клик открывает это окно, правый клик включает превью.",
    MINIMAP_LEFT_CLICK = "Клик: настройки",
    MINIMAP_RIGHT_CLICK = "Правый клик: превью",
    MINIMAP_DRAG = "Перетаскивание: сдвинуть по краю карты",
    PROVIDER_auto = "Авто",
    PROVIDER_ellesmere = "EllesmereUI",
    PROVIDER_compact = "Рейдовые",
    PROVIDER_blizzard = "Blizzard",
    PROVIDER_preview = "Фреймы превью",
    LANGUAGE = "Язык",
    LANGUAGE_auto = "Как в игре",
    LANGUAGE_enUS = "English",
    LANGUAGE_ruRU = "Русский",
    SECTION_ASK = "Просьба о кулдауне",
    ASK_ON_CLICK = "Просить по клику на готовую иконку",
    ASK_ON_CLICK_DESC = "Отправляет в чат просьбу к этому игроку использовать заклинание.",
    ASK_CHANNEL = "Куда писать",
    ASK_CHANNEL_party = "Чат группы",
    ASK_CHANNEL_whisper = "Шёпот",
    ASK_MESSAGE_party = "%s, нажми %s, пожалуйста",
    ASK_MESSAGE_whisper = "Нажми %s, пожалуйста",
    ASK_PREVIEW = "Превью Party Cooldowns, не отправлено: %s",
    ASK_LOCKED = "Игра сейчас не даёт аддонам писать в чат.",
    ASK_OFFLINE = "%s не в сети.",
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
    PICKER_HINT = "Нажмите на точку — иконки встанут туда. Отступ от фрейма сохраняется при смене стороны.",
    OFFSET_X = "Смещение по горизонтали",
    OFFSET_Y = "Смещение по вертикали",
    ICON_SIZE = "Размер иконок",
    SPACING = "Отступ между иконками",
    PER_ROW = "Иконок в ряду",
    ICON_SKIN = "Вид иконок",
    SKIN_flat = "Плоский",
    SKIN_blizzard = "Blizzard",

    SECTION_TIMER = "Таймер",
    SECTION_STYLE = "Стиль",
    TIMER_TEXT = "Текст таймера",
    TIMER_TEXT_DESC = "Оставшееся время поверх иконки.",
    TIMER_DECIMALS = "Десятые меньше 10 секунд",
    TIMER_DECIMALS_DESC = "4.2 вместо 5 под конец.",
    SWIPE = "Затемнение по кругу",
    SWIPE_DESC = "Тёмная «стрелка часов» поверх иконки на кулдауне.",
    DESATURATE = "Серые иконки на кулдауне",
    DESATURATE_DESC = "Готовые иконки цветные, остальные серые.",
    PULSE = "Вспышка при готовности",
    PULSE_DESC = "Короткая вспышка, когда кулдаун восстановился.",

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
    CUSTOM_PLACEHOLDER_DESC = "Введите ID заклинания и нажмите Enter. Подойдёт любой ранг. Название тоже работает, но только для заклинаний из вашей книги.",
    CUSTOM_HINT = "Показывается у участников группы, у которых стоит Party Cooldowns и есть это заклинание.",
    CUSTOM_REMOVE = "Убрать из списка",
    CUSTOM_ERROR_NOT_FOUND = "Нет заклинания с таким ID. Название работает только для заклинаний из вашей книги.",
    CUSTOM_ERROR_BUILTIN = "%s уже есть в списке на вкладке «%s».",
    CUSTOM_ERROR_ADDED = "%s уже добавлено на вкладке «%s».",
    CUSTOM_ERROR_LIMIT = "Можно добавить не больше %d заклинаний. Сначала уберите одно.",

    SYNC_EXPLAIN = "WoW Forever скрывает от аддонов касты других игроков. Точные таймеры приходят от тех, у кого тоже стоит Party Cooldowns; у остальных отслеживаются только касты, которые раскрывает игра.",
    SYNC_STATUS_OK = "Канал аддона открыт",
    SYNC_STATUS_LOCKED = "Игра приостановила обмен на время энкаунтера — продолжится сам",
    SYNC_STATUS_SOLO = "Вы не в группе",
    SYNC_MEMBERS = "Группа",
    SYNC_MEMBER_SYNCED = "Синхронизирован, заклинаний: %d",
    SYNC_MEMBER_NONE = "Нет аддона",
    SYNC_NO_MEMBERS = "Пока не с кем синхронизироваться.",
    SYNC_REQUEST = "Синхронизировать",

    TOOLTIP_COOLDOWN = "Готово через %s",
    TOOLTIP_READY = "Готово",
    TOOLTIP_UNKNOWN = "Неизвестно — у игрока нет аддона",
    TOOLTIP_NO_SYNC = "Без Party Cooldowns на его стороне отслеживаются только касты, которые раскрывает игра.",
    TOOLTIP_ASK_party = "Клик: попросить в чате группы",
    TOOLTIP_ASK_whisper = "Клик: попросить шёпотом",

    SETTINGS_DESC = "Кулдауны группы рядом с пати-фреймами.",
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
