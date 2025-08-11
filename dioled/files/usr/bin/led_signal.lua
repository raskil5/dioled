#!/usr/bin/lua

local led = {}

-- Read signal strength via AT+CSQ
function led.get_signal()
  local f = io.popen("gcom -d /dev/ttyUSB2 -s /etc/gcom/signal.gcom 2>&1")
  local output = f:read("*a")
  f:close()
  local csq = output:match("CSQ: (%d+)")
  return tonumber(csq or 0)
end

-- Check modem attachment via AT+CGATT
function led.is_modem_connected()
  local f = io.popen("gcom -d /dev/ttyUSB2 -s /etc/gcom/attach.gcom 2>&1")
  local output = f:read("*a")
  f:close()
  return output:match("CGATT: 1") ~= nil
end

-- Set signal LEDs (1–5 bars)
function led.set_signal_leds(level)
  for i = 1, 5 do
    local path = "/sys/class/leds/blue:signal" .. i .. "/brightness"
    local value = (i <= level) and "1" or "0"
    os.execute("echo " .. value .. " > " .. path)
  end
end

-- Set modem LEDs: blue for connected, red for disconnected
function led.set_modem_leds(connected)
  local blue_path = "/sys/class/leds/blue:modem/brightness"
  local red_path = "/sys/class/leds/red:modem/brightness"
  if connected then
    os.execute("echo 1 > " .. blue_path)
    os.execute("echo 0 > " .. red_path)
  else
    os.execute("echo 0 > " .. blue_path)
    os.execute("echo 1 > " .. red_path)
  end
end

-- Main logic
local signal = led.get_signal()
local bars = math.min(math.floor(signal / 6), 5)
led.set_signal_leds(bars)

local modem_connected = led.is_modem_connected()
led.set_modem_leds(modem_connected)

return led
