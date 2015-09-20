local skynet = require "skynet"
local log = require "log"
local table = table
local staticfile = require "staticfile"
local rule = require "rule"
local json = require"json"

local content = staticfile["room.html"]

local ALIVETIME = 100 * 60 * 10 -- 10 minutes

local R = { version = 1, user_tbl = {}, rules = {}, push_tbl={} }
local READY = 0
local NOTREADY = 1
local BLOCK = 2
local PUSH_TIME = 100 * 60

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

local function incversion()
    R.version = R.version + 1
    R.cache = nil
end

local function checkrule()
    local ready_num = 0
    for _, u in pairs(R.user_tbl) do
        if u.status == READY then
            ready_num = ready_num + 1
        end
    end

    return rule.checkrules(R.rules, ready_num)
end

function room.web(userid, username)
	enter_room(userid, username)
	return content
end

local function update_status()
	local idx, co = next(R.push_tbl)
	while(co) do
		skynet.wakeup(co)
		idx, co = next(R.push_tbl, idx)
	end
	if R.cache then
		return R.cache
	end
	if R.status == "prepare" then
        local info = {status = "prepare", player = {}, rule = {}, version = R.version}
        info.can_game, result = checkrule()
        info.reason = info.can_game and "" or result

		for _, v in pairs(R.user_tbl) do
            table.insert(info.player, {
                             userid = v.userid,
                             username = v.username,
                             status = v.status})
		end
		for rule in pairs(R.rules) do
			table.insert(info.rule, rule)
		end
		R.cache = json.encode(info)
	else
		-- todo game
		assert (R.status == "game")
        local info = {status = "game", version = R.version}
		R.cache = json.encode(info)
	end
	return R.cache
end

local api = {}

function api.setname(args)
	local userid = args.userid
	local username = args.username
	local u = R.user_tbl[userid]
	if u.username ~= username then
		skynet.call(userservice, "lua", userid, username)
		u.username = username
        incversion()
		update_status()
	end

	return '{"status":"ok"}'
end

function api.begin_game(_)
    local ok,result = checkrule()
    if ok then
        local i = 1
        for _, u in pairs(R.user_tbl) do
            if u.status == READY then
                u.identity = result[i]
                i = i + 1
            end
        end
        R.needs = ""
        R.status = "game"
        incversion()
    end

    return '{"status":"ok"}'
end

function api.ready(args)
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
		if enable then
			local can_game = true
			local ready_num = 0
			for _, u in pairs(R.user_tbl) do
				if u.status == READY then
					ready_num = ready_num + 1
				end
				if u.status ~= READY and u.status ~= BLOCK then
					can_game = false
					break
				end
			end
			if can_game then
			end
		end

        incversion()
	end
end

function api.kick(args)
	local id = tonumber(args.id)
	local u = R.user_tbl[id]
	if not u then
		return '{"status":"error"}'
	end
	if u.status ~= BLOCK then
		u.status = BLOCK
        incversion()
		update_status()
	end

	return '{"status":"ok"}'
end

function api.set(args)
	local rule = tonumber(args.rule)
	local enable = (args.enable == 'true')

	local updated = false
	if enable then
		if not R.rules[rule] then
			R.rules[rule] = true
			updated = true
		end
	else
		if R.rules[rule] then
			R.rules[rule] = nil
			updated = true
		end
	end

	if updated then
		for _, u in pairs(R.user_tbl) do
			if u.status == READY then
				u.status = NOTREADY
			end
		end
		R.version = R.version + 1
		R.cache = nil
		update_status()
	end
end

function api.request(args)
	local userid = args.userid
	local version = tonumber(args.version)
	local co = R.push_tbl[userid]
	if co then
		skynet.wakeup(co)
	end
	if version ~= 0 and version == R.version then
		local co = coroutine.running()
		R.push_tbl[userid] = co
		skynet.sleep(PUSH_TIME)
		R.push_tbl[userid] = nil
		if version == R.version then
			return {version = version}
		else
			return update_status()
		end
	end
	return update_status()
end

function api.list(args)
	local userid = args.userid
	local u = R.user_tbl[userid]
	if not u.identity then
		return {error = "您未分配角色"}
	end
	local identity_name = rule.role[u.identity]
	local role_visible = rule.visible[u.identity]
	local tmp_information = {}
	for _, u in pairs(R.user_tbl) do
		if u.identity then
			local visible = role_visible[u.identity]
			if visible == 3 and R.rules[3] or visible == true then
				local identity_name = rule.role[u.identity]
				table.insert(tmp_information, {[u.userid]=identity_name})
			end
		end
	end

	local tmp_player = {}
	for k, v in pairs(R.user_tbl) do
		table.insert(tmp_player, {userid = v.userid, username=v.username, color = "#ffffff"})
	end

    return {
        player = tmp_player,
        identity = {name = identity_name, desc = ""},
        information = tmp_information
    }
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
	R.needs = ""
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
            local ok, ret = xpcall(f, debug.traceback, ...)
            if not ok then
                print(ret)
                ret = {error = "server error"}
            end
			skynet.ret(skynet.pack(ret))
		end
	end)
end)
