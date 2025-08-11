#!/usr/bin/lua

local led = {}

function led.get_signal()
  local f = io.popen("gcom -d /dev/ttyUSB2 -s /etc/gcom/signal.gcom")
  local output = f:read("*a")
  f:close()
  local csq = output:match("CSQ: (%d+)")
  return tonumber(csq or 0)
end

function led.is_modem_connected()
  local f = io.popen("gcom -d /dev/ttyUSB2 -s /etc/gcom/attach.gcom")
  local output = f:read("*a")
  f:close()
  return output:match("CGATT: 1") ~= nil
end

function led.set_signal_leds(level)
  for i = 1, 5 do
    local path = "/sys/class/leds/blue:signal" .. i .. "/brightness"
    local value = (i <= level) and "1" or "0"
    os.execute("echo " .. value .. " > " .. path)
  end
end

function led.set_modem_led(state)
  local path = "/sys/class/leds/green:modem/brightness"
  os.execute("echo " .. (state and "1" or "0") .. " > " .. path)
end

while true do
  local signal = led.get_signal()
  local bars = math.min(math.floor(signal / 6), 5)
  led.set_signal_leds(bars)

  local modem_connected = led.is_modem_connected()
  led.set_modem_led(modem_connected)

  os.execute("sleep 5")
end
