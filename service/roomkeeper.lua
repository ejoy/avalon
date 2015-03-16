local skynet = require "skynet"
local log = require "log"

local MAXROOM = 4096
local MAXROOMID = 999999
local house = { n = 0 }
local roomkeeper = {}

function roomkeeper.query(room)
	if house[room] then
		return house[room]
	end
end

function roomkeeper.open()
	if house.n >= MAXROOM then
		return false, "Not enough empty rooms"
	end
	local room
	repeat
		room = math.random(MAXROOMID)
	until house[room] == nil
	local r = assert(skynet.newservice "room")
	skynet.call(r, "lua", "init", room)
	house.n = house.n + 1
	house[room] = r
	return true, room
end

function roomkeeper.close(room)
	if house[room] then
		house[room] = nil
		house.n = house.n - 1
		log.printf("[Room:%d] closed", room)
	end
end

skynet.start(function()
	math.randomseed(skynet.time())
	skynet.dispatch("lua", function(_,_,cmd,...)
		local f = roomkeeper[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		end
	end)
end)
