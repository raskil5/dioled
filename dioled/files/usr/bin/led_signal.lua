#!/usr/bin/lua

-- Configuration
local CONFIG = {
    LED_PATHS = {
        SIGNAL = {
            "/sys/class/leds/blue:signal1",
            "/sys/class/leds/blue:signal2",
            "/sys/class/leds/blue:signal3",
            "/sys/class/leds/blue:signal4",
            "/sys/class/leds/blue:signal5"
        },
        MODEM_BLUE = "/sys/class/leds/blue:modem",
        MODEM_RED  = "/sys/class/leds/red:modem"
    },
    MODEM_PORTS = {"/dev/ttyUSB2", "/dev/ttyUSB3", "/dev/ttyUSB0", "/dev/ttyUSB1"},
    POLL_DELAY = 5
}

-- Simple LED control
local function set_led(path, state)
    local cmd = string.format("echo %s > %s/brightness 2>/dev/null", state, path)
    return os.execute(cmd) == 0
end

-- Find working modem port
local function find_modem_port()
    for _, port in ipairs(CONFIG.MODEM_PORTS) do
        local test_file = os.tmpname()
        local cmd = string.format('gcom -d %s -s /etc/gcom/check_port.gcom > %s 2>&1', port, test_file)
        
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
    return nil
end

-- Get signal quality
local function get_signal(port)
    if not port then return nil end
    
    local tmpfile = os.tmpname()
    local cmd = string.format('gcom -d %s -s /etc/gcom/signal.gcom > %s 2>/dev/null', port, tmpfile)
    
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

    return tonumber(data:match("%+CSQ:%s*(%d+)")) or nil
end

-- Convert CSQ to bars (0-5)
local function signal_to_bars(csq)
    if not csq or csq == 99 then return 0 end
    if csq >= 20 then return 5 end
    if csq >= 16 then return 4 end
    if csq >= 12 then return 3 end
    if csq >= 8 then return 2 end
    return 1
end

-- Main function
local function main()
    -- Initialize modem port
    local modem_port = find_modem_port() or CONFIG.MODEM_PORTS[1]
    print("Using modem port: " .. (modem_port or "none"))
    
    -- Initialize all LEDs to off
    for _, led in ipairs(CONFIG.LED_PATHS.SIGNAL) do
        set_led(led, 0)
    end
    set_led(CONFIG.LED_PATHS.MODEM_BLUE, 0)
    set_led(CONFIG.LED_PATHS.MODEM_RED, 0)

    -- Main loop
    while true do
        local csq = get_signal(modem_port)
        local bars = signal_to_bars(csq)
        
        -- Update signal LEDs
        for i = 1, 5 do
            set_led(CONFIG.LED_PATHS.SIGNAL[i], i <= bars and 1 or 0)
        end
        
        -- Update status LEDs
        if bars > 0 then
            set_led(CONFIG.LED_PATHS.MODEM_BLUE, 1)
            set_led(CONFIG.LED_PATHS.MODEM_RED, 0)
        else
            set_led(CONFIG.LED_PATHS.MODEM_BLUE, 0)
            set_led(CONFIG.LED_PATHS.MODEM_RED, 1)
        end
        
        os.execute("sleep " .. CONFIG.POLL_DELAY)
    end
end

-- Start the application
main()
