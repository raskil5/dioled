#!/usr/bin/lua

-- Auto-detect modem AT port
local function detect_modem_port()
    local handle = io.popen([[
        for p in /dev/ttyUSB*; do
            echo -e "ATI\r" > $p
            sleep 1
            if head -n 3 < $p 2>/dev/null | grep -qi "manufacturer"; then
                echo $p
                break
            fi
        done
    ]])
    local port = handle:read("*l")
    handle:close()
    return port or "/dev/ttyUSB0"
end

local modem_port = detect_modem_port()
print("Using modem port: " .. modem_port)

-- LED paths (adjust names if different)
local leds = {
    modem_blue  = "/sys/class/leds/blue:modem/brightness",
    modem_red   = "/sys/class/leds/red:modem/brightness",
    sig1        = "/sys/class/leds/blue:signal1/brightness",
    sig2        = "/sys/class/leds/blue:signal2/brightness",
    sig3        = "/sys/class/leds/blue:signal3/brightness",
    sig4        = "/sys/class/leds/blue:signal4/brightness",
    sig5        = "/sys/class/leds/blue:signal5/brightness"
}

-- Helper: write LED
local function set_led(path, value)
    local f = io.open(path, "w")
    if f then
        f:write(tostring(value))
        f:close()
    end
end

-- Get signal strength via gcom
local function get_signal()
    local cmd = "gcom -d " .. modem_port .. " -s /etc/gcom/signal.gcom 2>/dev/null"
    local pipe = io.popen(cmd)
    local output = pipe:read("*a")
    pipe:close()

    local rssi = output:match("%+CSQ:%s*(%d+),")
    if rssi then
        rssi = tonumber(rssi)
        if rssi == 99 then
            return 0
        else
            return math.floor((rssi / 31) * 5)  -- Map to 1–5 bars
        end
    end
    return 0
end

-- Get connection state via gcom
local function is_connected()
    local cmd = "gcom -d " .. modem_port .. " -s /etc/gcom/attach.gcom 2>/dev/null"
    local pipe = io.popen(cmd)
    local output = pipe:read("*a")
    pipe:close()

    return output:match("STATE:%s*CONNECTED") ~= nil
end

-- Update LEDs
local function update_leds()
    local bars = get_signal()
    local connected = is_connected()

    -- Reset LEDs
    for i = 1, 5 do set_led(leds["sig" .. i], 0) end
    set_led(leds.modem_blue, 0)
    set_led(leds.modem_red, 0)

    -- Set signal LEDs
    for i = 1, bars do
        set_led(leds["sig" .. i], 1)
    end

    -- Set modem LED
    if connected then
        set_led(leds.modem_blue, 1)
    else
        set_led(leds.modem_red, 1)
    end
end

-- Main loop
while true do
    update_leds()
    os.execute("sleep 5")
end
