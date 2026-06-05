local micro = import("micro")
local config = import("micro/config")
local buffer = import("micro/buffer")
local os = import("os")

local defaults = {
    Quit        = "Ctrl-q",
    Save        = "Ctrl-s",
    Undo        = "Ctrl-z",
    Redo        = "Ctrl-y",
    Find        = "Ctrl-f",
    FindNext    = "Ctrl-n",
    Copy        = "Ctrl-c",
    Cut         = "Ctrl-x",
    Paste       = "Ctrl-v",
    SelectAll   = "Ctrl-a",
    CommandMode = "Ctrl-e",
    ToggleHelp  = "Ctrl-g",
}

local order = {
    "Quit", "Save", "Undo", "Redo", "Find", "FindNext",
    "Copy", "Cut", "Paste", "SelectAll", "CommandMode", "ToggleHelp"
}

local function parseJson(path)
    local f = io.open(path, "r")
    if not f then return {} end
    local content = f:read("*a")
    f:close()
    local t = {}
    for k, v in content:gmatch('"([^"]+)"%s*:%s*"([^"]*)"') do t[k] = v end
    return t
end

local function formatKey(key)
    key = key:gsub("Ctrl%-(%a)", function(c) return "^" .. c:upper() end)
    key = key:gsub("Alt%-(%a)", function(c) return "Alt+" .. c:upper() end)
    return key
end

local function getBindings()
    local raw = parseJson(config.ConfigDir .. "/bindings.json")
    local unbound, rebound = {}, {}
    for key, action in pairs(raw) do
        if action == "None" or action == "" then unbound[key] = true
        else rebound[key] = action end
    end
    local result = {}
    for action, key in pairs(defaults) do
        if not unbound[key] and not rebound[key] then result[action] = key end
    end
    for key, action in pairs(rebound) do result[action] = key end
    return result
end

local function loadLang(code)
    local f = io.open(config.ConfigDir .. "/plug/hints/" .. code .. ".json", "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    local t = {}
    for k, v in content:gmatch('"(%w+)"%s*:%s*"([^"]*)"') do t[k] = v end
    return t
end

local function getLang()
    local lang = os.Getenv("LANG") .. os.Getenv("LC_ALL") .. os.Getenv("LC_MESSAGES")
    return lang:match("(%a%a)") or "en"
end

local function buildLines(width)
    local t = loadLang(getLang()) or loadLang("en")
    local b = getBindings()

    local parts = {}
    for _, action in ipairs(order) do
        local key = b[action]
        local label = t[action:lower()]
        if key and label then
            table.insert(parts, formatKey(key) .. " " .. label)
        end
    end

    local lines = {}
    local line = ""
    for _, part in ipairs(parts) do
        local sep = line == "" and "" or "  "
        if line ~= "" and #line + #sep + #part > width then
            table.insert(lines, line)
            line = part
        else
            line = line .. sep .. part
        end
    end
    if line ~= "" then table.insert(lines, line) end
    return lines
end

local statusCache = nil
local hintsPane = nil

function ShowHints(bp)
    if hintsPane ~= nil then
        hintsPane:ForceQuit()
        hintsPane = nil
        return
    end
    local view = bp:GetView()
    local lines = buildLines(view.Width)
    local totalHeight = view.Height
    local buf = buffer.NewBuffer(table.concat(lines, "\n"), "hints")
    buf.Type.Scratch = true
    buf.Type.Readonly = true
    buf.Settings["syntax"] = false
    buf.Settings["ruler"] = false
    buf.Settings["statusline"] = false
    hintsPane = bp:HSplitIndex(buf, true)
    hintsPane:ResizePane(totalHeight - #lines - 1)
end

function preQuit(bp)
    if hintsPane == nil then return end
    if bp == hintsPane then
        hintsPane = nil
    else
        hintsPane:ForceQuit()
        hintsPane = nil
    end
end

function hints(buf)
    if hintsPane ~= nil then return "" end
    if statusCache then return statusCache end
    local t = loadLang(getLang()) or loadLang("en")
    local b = getBindings()
    local parts = {}
    for _, action in ipairs({"Quit", "Save"}) do
        local key = b[action]
        local label = t[action:lower()]
        if key and label then
            table.insert(parts, formatKey(key) .. " " .. label)
        end
    end
    local hintsKey = b["lua:hints.ShowHints"]
    if hintsKey then
        table.insert(parts, formatKey(hintsKey) .. " " .. (t["showhints"] or "Hints"))
    end
    statusCache = table.concat(parts, "  ")
    return statusCache
end

local fmtl = " $(filename) $(modified)$(overwrite)($(line),$(col)) | ft:$(opt:filetype) | $(opt:fileformat) | $(opt:encoding)"
local fmtr = "$(hints.hints)  $(line),$(col) "

function onBufPaneOpen(bp)
    if bp.Buf:GetName() ~= "hints" then
        bp.Buf:SetOption("statusformatl", fmtl)
        bp.Buf:SetOption("statusformatr", fmtr)
    end
end

function init()
    micro.SetStatusInfoFn("hints.hints")
    config.SetGlobalOption("statusformatl", fmtl)
    config.SetGlobalOption("statusformatr", fmtr)
end
