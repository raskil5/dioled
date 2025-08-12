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

-- Helper function to set LED value
local function set_led(path, value)
    local f = io.open(path, "w")
    if f then
        f:write(tostring(value))
        f:close()
    end
end

-- Set signal LEDs based on percentage (0-100)
local function set_signal_leds(percent)
    local value = math.floor((percent - 1) / 20) + 1
    for i = 1, 5 do
        set_led(leds["sig"..i], i <= value and 1 or 0)
    end
end

-- Main function to check signal and update LEDs
local function update_leds()
    -- Check if device exists
    local f = io.open(DEVICE, "r")
    if not f then
        return false
    end
    f:close()

    -- Get signal quality using sms_tool
    local handle = io.popen(string.format('sms_tool -d %s at AT+CSQ 2>/dev/null', DEVICE))
    local output = handle:read("*a")
    handle:close()

    -- Parse CSQ value
    local csq = output:match("%+CSQ:%s*(%d+)")
    if not csq then
        return false
    end

    csq = tonumber(csq)
    if csq == 99 then  -- special case for unknown signal
        csq = 0
    end

    -- Calculate percentage (0-100)
    local csq_per = math.floor((csq * 100) / 31)

    -- Update signal LEDs
    set_signal_leds(csq_per)

    -- Simple modem status (could be enhanced)
    set_led(leds.modem_blue, 1)  -- assume connected
    set_led(leds.modem_red, 0)

    return true
end

-- Main loop
while true do
    update_leds()
    os.execute("sleep 5")
end
