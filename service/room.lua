local skynet = require "skynet"
local log = require "log"
local table = table
local staticfile = require "staticfile"

local content = staticfile["room.html"]

local ALIVETIME = 100 * 60 * 10 -- 10 minutes

local R = { version = 1, user_tbl = {}, rulelist = {}, push_tbl={} }
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
	local u = R.user_tbl[userid]
	if u then
		u.timestamp = skynet.now()
		if u.username == username then
			return
		end
		u.username = username
	else
		R.user_tbl[userid] = {
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
	return content
end

local function update_status()
    if next(R.push_tbl) then
        for _, data in pairs(R.push_tbl) do
            local co = data[1]
            coroutine.resume(co)
        end
        R.push_tbl = {}
    end
	if R.cache then
		return R.cache
	end
	if R.status == "prepare" then
		local tmp = {}
		for k,v in pairs(R.user_tbl) do
			table.insert(tmp,string.format(
				'{"userid":%d,"username":"%s","status":%d}',
				v.userid, v.username, v.status))
		end
		R.cache = string.format('{"status":"prepare","player":[%s]}',
			table.concat(tmp,","))
	else
		-- todo game
		assert (R.status == "game")
	end
	return R.cache
end

local api = {}

function api.setname(args)
	local userid = args.userid
	local username = args.username
	local u = R.user_tbl[userid]
	print('--setname', args.username, username)
	if u.username ~= username then
		skynet.call(userservice, "lua", userid, username)
		u.username = username
		R.version = R.version + 1
		R.cache = nil
		return update_status()
	else
		return '{"status":"ok"}'
	end
end

function api.ready(args)
	print('--ready', args.enable)
	local userid = args.userid
	local enable = (args.enable == 'true')
	local u = R.user_tbl[userid]
	local updated = false
	if enable then
		if u.status ~= READY then
			u.status = READY
			updated = true
		end
	elseif u.status == READY then
		u.status = NOTREADY
		updated = true
	end

	if updated then
		R.version = R.version + 1
		R.cache = nil
		return update_status()
	else
		return '{"status":"ok"}'
	end
end

function api.kick(args)
	print('--kick', args.id)
	local id = tonumber(args.id)
	local u = R.user_tbl[id]
	if u.status ~= BLOCK then
		u.status = BLOCK
		R.version = R.version + 1
		R.cache = nil
		return update_status()
	else
		return '{"status":"ok"}'
	end
end

function api.set(args)
	print('--set', args.rule, args.enable)
	local rule = tonumber(args.rule)
	local enable = (args.enable == 'true')
	local index
	for i, r_id in ipairs(R.rulelist) do
		if rule == r_id then
			index = i
			break
		end
	end

	local updated = false
	if enable then
		if not index then
			table.insert(R.rulelist, rule)
			updated = true
		end
	elseif index then
		table.remove(R.rulelist, index)
		updated = true
	end

	if updated then
		for _, u in pairs(R.user_tbl) do
			if u.status == READY then
				u.status = NOTREADY
			end
		end
		R.version = R.version + 1
		R.cache = nil
		return update_status()
	else
		return '{"status":"ok"}'
	end
end

function api.request(args)
	local userid = args.userid
    local version = tonumber(args.version)
    print('--request', version, R.version)
    if version ~= 0 and version == R.version then
        local co = coroutine.running()
        R.push_tbl[userid] = {co, skynet.now()}
        coroutine.yield()
        return update_status()
    end
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
