#!/usr/bin/lua

-- Configuration
local DEVICE = "/dev/ttyUSB0"

-- LED paths (adjust as needed)
local leds = {
    modem_blue  = "/sys/class/leds/blue:modem/brightness",
    modem_red   = "/sys/class/leds/red:modem/brightness",
    sig1        = "/sys/class/leds/blue:signal1/brightness",
    sig2        = "/sys/class/leds/blue:signal2/brightness",
    sig3        = "/sys/class/leds/blue:signal3/brightness",
    sig4        = "/sys/class/leds/blue:signal4/brightness",
    sig5        = "/sys/class/leds/blue:signal5/brightness"
}

-- Helper: write to LED
local function set_led(path, value)
    local f = io.open(path, "w")
    if f then
        f:write(tostring(value))
        f:close()
    end
end

-- Helper: log events (optional)
local function log_event(msg)
    local f = io.open("/tmp/dioled.log", "a")
    if f then
        f:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. msg .. "\n")
        f:close()
    end
end

-- Set signal LEDs based on percentage
local function set_signal_leds(percent)
    local value = math.floor((percent - 1) / 20) + 1
    for i = 1, 5 do
        set_led(leds["sig"..i], i <= value and 1 or 0)
    end
end

-- Check SIM presence
local function has_sim()
    local handle = io.popen(string.format('sms_tool -d %s at AT+CPIN? 2>/dev/null', DEVICE))
    local output = handle:read("*a")
    handle:close()
    return output:match("READY") ~= nil
end

-- Check data connection
local function is_data_connected()
    local handle = io.popen(string.format('sms_tool -d %s at AT+CGATT? 2>/dev/null', DEVICE))
    local output = handle:read("*a")
    handle:close()
    return output:match("%+CGATT:%s*1") ~= nil
end

-- Get signal strength
local function get_signal_percent()
    local handle = io.popen(string.format('sms_tool -d %s at AT+CSQ 2>/dev/null', DEVICE))
    local output = handle:read("*a")
    handle:close()
    local csq = output:match("%+CSQ:%s*(%d+)")
    csq = tonumber(csq)
    if not csq or csq == 99 then return 0 end
    return math.floor((csq * 100) / 31)
end

-- Blink state toggle
local blink_state = 0

-- Update modem LEDs
local function update_modem_led()
    if not has_sim() then
        blink_state = 1 - blink_state
        set_led(leds.modem_red, blink_state)
        set_led(leds.modem_blue, 0)
        log_event("SIM missing → blinking red")
    elseif not is_data_connected() then
        set_led(leds.modem_red, 1)
        set_led(leds.modem_blue, 0)
        log_event("SIM OK, no data → solid red")
    else
        set_led(leds.modem_red, 0)
        set_led(leds.modem_blue, 1)
        log_event("SIM + data OK → solid blue")
    end
end

-- Main loop
while true do
    -- Check device
    local f = io.open(DEVICE, "r")
    if f then
        f:close()
        local percent = get_signal_percent()
        set_signal_leds(percent)
        update_modem_led()
        log_event("Signal: " .. percent .. "%")
    else
        log_event("Device not found: " .. DEVICE)
    end
    os.execute("sleep 5")
end
