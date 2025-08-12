#!/usr/bin/lua

-- LED paths (following OEM structure)
local LED_SIGNAL = {
    "/sys/class/leds/blue:signal1",
    "/sys/class/leds/blue:signal2",
    "/sys/class/leds/blue:signal3",
    "/sys/class/leds/blue:signal4",
    "/sys/class/leds/blue:signal5"
}
local LED_MODEM_BLUE = "/sys/class/leds/blue:modem"  -- Normal status
local LED_MODEM_RED  = "/sys/class/leds/red:modem"   -- Exception status

-- OEM-style LED control functions
local function led_on(path)
    os.execute(string.format("echo none > %s/trigger", path))
    return os.execute(string.format("echo 1 > %s/brightness", path)) == 0
end

local function led_off(path)
    os.execute(string.format("echo none > %s/trigger", path))
    return os.execute(string.format("echo 0 > %s/brightness", path)) == 0
end

local function led_blink_slow(path)
    return os.execute(string.format("echo timer > %s/trigger", path)) == 0
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

-- Dynamic modem port detection
local function find_modem_port()
    -- Common modem ports in order of likelihood
    local ports = {"/dev/ttyUSB2", "/dev/ttyUSB3", "/dev/ttyUSB0", "/dev/ttyUSB1"}
    
    for _, port in ipairs(ports) do
        -- Check if port exists and responds to AT commands
        local test_file = os.tmpname()
        local cmd = string.format('gcom -d %s -s /etc/gcom/check_port.gcom > %s 2>/dev/null', port, test_file)
        if os.execute(cmd) == 0 then
            local f = io.open(test_file, "r")
            if f then
                local content = f:read("*a")
                f:close()
                if content:find("OK") then
                    os.remove(test_file)
                    return port
                end
            end
        end
        os.remove(test_file)
    end
    return nil  -- No working port found
end

-- Initialize modem port (try dynamic detection, fallback to OEM default)
local MODEM_PORT = find_modem_port() or "/dev/ttyUSB2"

-- Get signal level from modem
local function get_signal()
    local tmpfile = os.tmpname()
    local cmd = string.format('gcom -d %s -s /etc/gcom/signal.gcom > %s 2>/dev/null', MODEM_PORT, tmpfile)
    if os.execute(cmd) ~= 0 then
        os.remove(tmpfile)
        return nil
    end

    local f = io.open(tmpfile, "r")
    if not f then
        os.remove(tmpfile)
        return nil
    end

    local data = f:read("*a")
    f:close()
    os.remove(tmpfile)

    -- Expected output: +CSQ: <rssi>,<ber>
    local rssi = data:match("%+CSQ:%s*(%d+)")
    return rssi and tonumber(rssi) or nil
end

-- Convert CSQ to signal bars (1-5) - OEM mapping
local function csq_to_bars(csq)
    if not csq or csq == 99 then
        return 0  -- No signal
    elseif csq < 8 then
        return 1
    elseif csq < 12 then
        return 2
    elseif csq < 16 then
        return 3
    elseif csq < 20 then
        return 4
    else
        return 5  -- Excellent signal
    end
end

-- Main control loop
while true do
    local csq = get_signal()
    local bars = csq_to_bars(csq)

    if bars > 0 then
        -- Good signal - blue LED on, red off (OEM pattern)
        set_signal_leds(bars)
        led_on(LED_MODEM_BLUE)
        led_off(LED_MODEM_RED)
    else
        -- No signal - red LED on, blue off (OEM pattern)
        set_signal_leds(0)
        led_off(LED_MODEM_BLUE)
        led_on(LED_MODEM_RED)
    end

    os.execute("sleep 5")  -- OEM-standard polling interval
end
