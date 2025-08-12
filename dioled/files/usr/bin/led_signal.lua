#!/usr/bin/lua

local signal_leds = {
    "/sys/class/leds/blue:signal1/brightness",
    "/sys/class/leds/blue:signal2/brightness",
    "/sys/class/leds/blue:signal3/brightness",
    "/sys/class/leds/blue:signal4/brightness",
    "/sys/class/leds/blue:signal5/brightness"
}

local modem_blue = "/sys/class/leds/blue:modem/brightness"
local modem_red  = "/sys/class/leds/red:modem/brightness"

-- AT port (same as OEM)
local at_port = "/dev/ttyUSB2"

local function run_cmd(cmd)
    local f = io.popen(cmd)
    if f then
        local res = f:read("*a") or ""
        f:close()
        return res
    end
    return ""
end

local function set_led(path, state)
    local f = io.open(path, "w")
    if f then
        f:write(state)
        f:close()
    end
end

while true do
    -- Get signal strength
    local csq = run_cmd(string.format("gcom -d %s -s /etc/gcom/signal.gcom", at_port))
    local rssi = tonumber(csq:match("%+CSQ:%s*(%d+)")) or 99

    -- Reset LEDs
    for _, led in ipairs(signal_leds) do set_led(led, "0") end

    if rssi >= 20 then
        set_led(signal_leds[5], "1")
    elseif rssi >= 15 then
        set_led(signal_leds[4], "1")
    elseif rssi >= 10 then
        set_led(signal_leds[3], "1")
    elseif rssi >= 5 then
        set_led(signal_leds[2], "1")
    elseif rssi > 0 and rssi < 99 then
        set_led(signal_leds[1], "1")
    end

    -- Check modem attach
    local attach = run_cmd(string.format("gcom -d %s -s /etc/gcom/attach.gcom", at_port))
    if attach:match("%+CGATT:%s*1") then
        set_led(modem_blue, "1")
        set_led(modem_red, "0")
    else
        set_led(modem_blue, "0")
        set_led(modem_red, "1")
    end

    os.execute("sleep 5")
end
