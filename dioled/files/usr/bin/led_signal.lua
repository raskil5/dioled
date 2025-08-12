#!/usr/bin/lua

-- LED paths
local LED_SIGNAL = {
    "/sys/class/leds/blue:signal1/brightness",
    "/sys/class/leds/blue:signal2/brightness",
    "/sys/class/leds/blue:signal3/brightness",
    "/sys/class/leds/blue:signal4/brightness",
    "/sys/class/leds/blue:signal5/brightness"
}
local LED_MODEM_BLUE = "/sys/class/leds/blue:modem/brightness"
local LED_MODEM_RED  = "/sys/class/leds/red:modem/brightness"

-- Helper functions
local function led_on(path)
    local f = io.open(path, "w")
    if f then f:write("1\n") f:close() end
end

local function led_off(path)
    local f = io.open(path, "w")
    if f then f:write("0\n") f:close() end
end

local function set_signal_leds(count)
    for i = 1, 5 do
        if i <= count then
            led_on(LED_SIGNAL[i])
        else
            led_off(LED_SIGNAL[i])
        end
    end
end

-- Get signal level from modem
local function get_signal()
    local tmpfile = "/tmp/csq.txt"
    os.execute("gcom -d /dev/ttyUSB0 -s /etc/gcom/signal.gcom > " .. tmpfile .. " 2>/dev/null")
    local f = io.open(tmpfile, "r")
    if not f then return nil end

    local data = f:read("*a")
    f:close()

    -- Expected output: +CSQ: <rssi>,<ber>
    local rssi = data:match("%+CSQ:%s*(%d+)")
    if rssi then
        return tonumber(rssi)
    else
        return nil
    end
end

-- Convert CSQ value to signal bars (1-5)
local function csq_to_bars(csq)
    if not csq or csq == 99 then
        return 0
    elseif csq < 8 then
        return 1
    elseif csq < 12 then
        return 2
    elseif csq < 16 then
        return 3
    elseif csq < 20 then
        return 4
    else
        return 5
    end
end

-- Main loop
while true do
    local csq = get_signal()
    local bars = csq_to_bars(csq)

    if bars > 0 then
        set_signal_leds(bars)
        led_on(LED_MODEM_BLUE)
        led_off(LED_MODEM_RED)
    else
        set_signal_leds(0)
        led_off(LED_MODEM_BLUE)
        led_on(LED_MODEM_RED)
    end

    os.execute("sleep 5")
end
