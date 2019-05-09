package.cpath=package.cpath..";./lualib/?.so"

local remote_host = "127.0.0.1"
local remote_port = 8888

local LKcp = require "lkcp"
local LUtil = require("lutil")

local socket = require("socket")




local UDP = { data = {} ,curr_time = 0,order=0}
local udp = assert(socket.udp())

function UDP.connect()
	assert(udp:setpeername(remote_host,remote_port))
	udp:settimeout(0) -- make non blocking
	--udp:send("(ping)\n")
end

local function udp_output(buf, user)
	--print("udp_output ",#buf)
    udp:send(buf)
end

local kcp1 = LKcp.lkcp_create(2, function (buf)
        udp_output(buf, "111")
end)

kcp1:lkcp_wndsize(128, 128)
kcp1:lkcp_nodelay(1, 10, 2, 1)

index = 0

local current = LUtil.iclock()
local slap = current + 20

UDP.connect()
print("fd",udp:getfd())

while 1 do

	LUtil.isleep(1)
	current = LUtil.iclock()

	--[[
	current = LUtil.iclock()
    local nextt1 = kcp1:lkcp_check(current) 
    local diff = nextt1 - current
    if diff > 0 then
        LUtil.isleep(diff)
        current =  LUtil.iclock() 
    end
	]]

	kcp1:lkcp_update(current)

	while current >= slap do
		buf = "fuck "..tostring(index).."\n"
	 	kcp1:lkcp_send(buf)
        slap = slap + 20
        index = index + 1
    end

   	while 1 do
		s, status = udp:receive(1024)
		if s == nil then
        	break
        end
        kcp1:lkcp_input(s)
    end
end
