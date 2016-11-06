--[[
    Lua script to use with dinaj.ini Rainmeter skin
    FlyingHyrax
    2014-11-15
--]]

--[[ LOCAL VARIABLES =========================================================]]

-- lists the options the script measure can take
local Settings_Meta = {
    String_Options = {
        "TempMeasureName",
        "WindMeasureName",
        "FirstString",
        "SecondString",
        "Unit"
    },
    Number_Options = {
        "JacketThreshold",
        "CoatThreshold"
    },
    Defaults = {
        JacketThreshold = 60,
        CoatThreshold = 30,
        Unit = "f"
    }
}

-- things which should not change
local Constants = {
    ADVERBS = {
        "damn cold",
        "darn cold",
        "bone chilling",
        "glacial",
        "frigid",
        "freezing",
        "frosty",
        "pretty cold",
        "chilly",
        "brisk",
        "cool",
        "quite temperate",
        "rather mild",
        "pretty nice",
        "positively balmy",
        "extra warm",
        "kinda hot",
        "roasting",
        "scorching",
        "oven-like",
        "your hair is on FIRE",
    },
    RANGE_MIN = -10,
    RANGE_MAX = 120,
}

-- measure and meter references
local Handles = {}
Handles.init = function(props)
    Handles.Temperature_Measure = SKIN:GetMeasure(props.TempMeasureName)
    Handles.Wind_Measure = SKIN:GetMeasure(props.WindMeasureName)
    Handles.Main_Meter = SKIN:GetMeter(props.FirstString)
    Handles.Sub_Meter = SKIN:GetMeter(props.SecondString)
end

-- script measure settings
local Settings = {}
Settings.init = function(props)
    Settings.Jacket_Limit = SELF:GetNumberOption(props.JacketThreshold, 60)
    Settings.Coat_Limit = SELF:GetNumberOption(props.CoatThreshold, 35)

    local metric = { m = true, c = true }
    local unit = string.lower(string.sub(props.Unit, 1, 1))
    Settings.Unit =  metric[unit] and 'c' or 'f'
end

--[[ LOCAL FUNCTIONS =========================================================]]

--[[ printf shortcut ]]
local function printf(format, ...)
    print(string.format(format, ...))
end

local function print_table( t )
    local str = "[ "
    for k, v in pairs(t) do
        str = str .. string.format("'%s' = %s, ", tostring(k), tostring(v))
    end
    str = str .. "]"
    print(str)
end

--[[ Given a measure handle an metadata about the measures options,
  return a table of Option=Value pairs. ]]
local function getMeasureOptions( measure, meta )
    local options = {}

    local function grabOptions( list, getter )
        for _, v in pairs(list) do
            options[v] = getter(measure, v, meta.Defaults[v])
        end
    end

    grabOptions( meta.String_Options, measure.GetOption)
    grabOptions( meta.Number_Options, measure.GetNumberOption)

    return options
end

--[[ Keeps a value inside the given range ]]
local function clamp( value, min, max )
    local clamped = value
    if value < min then
        clamped = min
    elseif value > max then
        clamped = max
    end
    return clamped
end

--[[ Adjusts a value and its defined range if the value is negative ]]
local function normalize( value, min, max )
    local excess = min < 0 and 0 - min or 0
    return value + excess, min + excess, max + excess
end

--[[ Return a value as a percentage of its range ]]
local function percentOfRange( value, min, max )
    -- normalize
    local value, min, max = normalize( value, min, max)
    -- maths
    local percent = (value / max - min)
    -- clamping
    return clamp( percent, 0.0, 1.0)
end

--[[ Convert a number from fahrenheit to celsius ]]
local function f2c( fahrenheit )
    return (((fahrenheit - 32) * 5) / 9)
end

--[[ Convert a number from celsius to fahrenheit (unused) ]]
local function c2f( celsius )
    return (((celsius * 9) / 5) + 32)
end

--[[ Given the current temperature and its scale,
  return a descriptor for that temperature ]]
local function getTempWord( temp, unit )
    -- convert our range bounds to celsius if necessary
    local unit = unit or 'f'
    local tmin = unit == 'f' and Constants.RANGE_MIN or f2c(Constants.RANGE_MIN)
    local tmax = unit == 'f' and Constants.RANGE_MAX or f2c(Constants.RANGE_MAX)
    -- percentage of our temperature range
    local tempPer = percentOfRange( temp, tmin, tmax )
    -- index in array of descriptors, based on that percentage
    local index = math.ceil( #Constants.ADVERBS * tempPer )
    -- if temp is 0% of our range, index will be off by one
    if index < 1 then index = 1 end
    -- return that word
    return Constants.ADVERBS[index]
end

--[[ Given the current temperature, return the appropriate
  string for the main string meter ]]
local function getMainString( temp )
    local negation = (temp > Settings.Jacket_Limit) and " don't" or ""
    local outerwear = (temp < Settings.Coat_Limit) and "coat" or "jacket"
    return string.format("You%s need a %s", negation, outerwear)
end

--[[ Given the current temperature and its unit, return the appropriate string
  for the secondary string meter ]]
local function getSubString( temp, unit )
    return string.format("It's %s outside", getTempWord(temp, unit))
end

--[[ Sets the Text value of the specified meter with a SetOption bang ]]
local function setMeterText( meter, text )
    SKIN:Bang('!SetOption', meter:GetName(), 'Text', text)
end

--[[ Log the descriptor which is returned for various temperatures ]]
local function test()
    for i = -20, 100, 5 do
        printf("t=%d, s=%s", i, getTempWord(i))
    end
end

--[[ GLOBAL SKIN FUNCTIONS ===================================================]]

--[[ Run on Refresh (or on update if DynamicVariables is set on the script measure)
  Retrieves user specified values from variables and handles to measures and meters ]]
function Initialize()
    -- grab script measure options
    local opts = getMeasureOptions( SELF, Settings_Meta )
    -- read settings
    Settings.init(opts)
    -- get measure/meter refs
    Handles.init(opts)
    -- run some tests
    -- test()
end

--[[ Run on Update - We need to update two different string meters on every tick,
  So we use a bang for both and do not return a value. ]]
function Update()
    -- get current temp
    local temp = tonumber(Handles.Temperature_Measure:GetStringValue())
    -- WebParser will not have returned values for the first few update ticks
    if temp ~= nil then
        setMeterText(Handles.Main_Meter, getMainString(temp))
        setMeterText(Handles.Sub_Meter, getSubString(temp, Settings.Unit))
    end
end
