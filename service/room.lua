local skynet = require "skynet"
local log = require "log"
local table = table

local ALIVETIME = 100 * 60 * 10 -- 10 minutes

local R = { version = 1, userlist = {}, rulelist = {} }
local READY = 0
local NOTREADY = 1
local BLOCK = 2

local roomkeeper
local alive
local userservice
local room = {}

local function exit()
	if R.roomid then
		local id = R.roomid
		R.roomid = nil
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

local function enter_room(userid, username)
	local u = R.userlist[userid]
	if u then
		u.timestamp = skynet.now()
		if u.username == username then
			return
		end
		u.username = username
	else
		R.userlist[userid] = {
			userid = userid,
			username = username,
			timestamp = skynet.now(),
			status = NOTREADY,	-- not ready
		}
	end
	R.version = R.version + 1
	R.cache = nil
end

function room.web(userid, username)
	enter_room(userid, username)
	return string.format("你好 %d %s", userid, username)
end

local function update_status()
	if R.cache then
		return R.cache
	end
	if R.status == "prepare" then
		local tmp = {}
		for k,v in pairs(R.userlist) do
			table.insert(tmp,string.format(
				'{"userid":%d,"username":"%s","status":%d}',
				v.userid, v.username, v.status))
		end
		R.cache = string.format('"status":"prepare","player":{%s}',
			table.concat(tmp,","))
	else
		-- todo game
		assert (R.status == "game")
	end
	return R.cache
end

local api = {}

function api.setname(args)
	local userid, username = skynet.call(userservice, "lua", args.userid, args.username)
	if username ~= args.username then
		R.version = R.version + 1
		R.cache = nil
		return update_status()
	else
		return '{"status":"ok"}'
	end
end

function api.request(args)
	return update_status()
end

function room.api(args)
	local f = args.action and api[args.action]
	if not f then
		return '{"status":"error","error":"Invalid Action"}'
	end
	if args.status ~= R.status then
		-- todo push status
		return update_status()
	end
	return f(args)
end

function room.init(id)
	assert(R.roomid == nil, "Already Init")
	R.roomid = id
	R.status = "prepare"
	log.printf("[Room:%d] open", id)
end

skynet.start(function()
	roomkeeper = assert(skynet.uniqueservice "roomkeeper")
	userservice = assert(skynet.uniqueservice "userid")
	skynet.fork(heartbeat)
	skynet.dispatch("lua", function (_,_,cmd,...)
		alive = skynet.now()
		local f = room[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		end
	end)
end)
