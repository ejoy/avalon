local skynet = require "skynet"
local log = require "log"

local ALIVETIME = 100 * 60 * 10 -- 10 minutes

local roomid
local roomkeeper
local alive
local room = {}

local function exit()
	if roomid then
		local id = roomid
		roomid = nil
		skynet.call(roomkeeper, "lua", "close", id)
	end
	skynet.exit()
end

local function heartbeat()
	alive = skynet.now()
	while true do
		skynet.sleep(ALIVETIME//2)
		if skynet.now() - alive > ALIVETIME then
			exit()
		end
	end
end

function room.web(httpheader)
	for k,v in pairs(httpheader) do
		print(k,v)
	end
	return "Hello player"
end

function room.init(id)
	assert(roomid == nil, "Already Init")
	roomid = id
	log.printf("[Room:%d] open", id)
	-- todo: init
end

skynet.start(function()
	roomkeeper = assert(skynet.uniqueservice "roomkeeper")
	skynet.fork(heartbeat)
	skynet.dispatch("lua", function (_,_,cmd,...)
		alive = skynet.now()
		local f = room[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		end
	end)
end)
