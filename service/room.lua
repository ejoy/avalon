local skynet = require "skynet"
local log = require "log"
local table = table
local staticfile = require "staticfile"
local rule = require "rule"
local json = require"json"
local objproxy = require"objproxy"

local content = staticfile["room.html"]

local ALIVETIME = 100 * 60 * 10 -- 10 minutes

local R = {
    version = 1,
    push_tbl={},
    info = objproxy.new{user_tbl = {}, rules = {}}
}

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
	local u = R.info.user_tbl[userid]
	if u then
		u.timestamp = skynet.now()
		if u.username == username then
			return
		end
		u.username = username
	else
		R.info.user_tbl[userid] = {
			userid = userid,
			username = username,
			timestamp = skynet.now(),
			status = NOTREADY,	-- not ready
		}
	end
end

local function checkrule()
    local ready_num = 0
    for _, u in pairs(R.info.user_tbl) do
        if u.status == READY then
            ready_num = ready_num + 1
        end
    end

    return rule.checkrules(R.info.rules, ready_num)
end

local function prepareinfo(_)
    local info = {status = "prepare", player = {}, rule = {}, version = R.version}
    info.can_game, result = checkrule()
    info.reason = info.can_game and "" or result

    for _, v in pairs(R.info.user_tbl) do
        table.insert(info.player, {
                         userid = v.userid,
                         username = v.username,
                         status = v.status})
    end
    for rule in pairs(R.info.rules) do
        table.insert(info.rule, rule)
    end

    return info
end

local function gameinfo(userid)
    assert (R.status == "game")
    local u = R.info.user_tbl[userid]
    if not u.identity then
        return {error = "您未分配角色"}
    end
    local identity_name = rule.role[u.identity]
    local role_visible = rule.visible[u.identity]
    local tmp_information = {}
    for _, u in pairs(R.info.user_tbl) do
        local visible = role_visible[u.identity]
        if visible then
            local identity_name
            if visible == true then
                identity_name = rule.role[u.identity]
            elseif visible == 4 then
                identity_name = rule.camp_name[u.identity]
            elseif visible == 3 and R.info.rules[8] then
                identity_name = rule.role[u.identity]
            end
            if identity_name then
                table.insert(tmp_information, {username = u.username, identity = identity_name})
            end
        end
    end

    local players = {}
    for _, uid in ipairs(R.info.uidlist) do
        local u = R.info.user_tbl[uid]
        table.insert(players, {userid = u.userid, username=u.username, color = "#ffffff"})
    end

    local stagel = {}
    for uid in pairs(R.info.stage) do
        table.insert(stagel, uid)
    end
    return {
        players = players,
        identity = {name = identity_name, desc = ""},
        information = tmp_information,
        gameinfo = {round = R.info.round, pass = R.info.pass, leader = R.info.leader,
                    stage = stagel, mode = R.info.mode},
        status = "game",
        version = R.version,
    }
end

local function roominfo(userid)
    local info = R.status == "prepare" and prepareinfo(userid) or gameinfo(userid)
    R.cache = json.encode(info)
    return R.cache
end

function room.web(userid, username)
	enter_room(userid, username)
	return content
end

local api = {}

function api.setname(args)
	local userid = args.userid
	local username = args.username
	local u = R.info.user_tbl[userid]
	if u.username ~= username then
		skynet.call(userservice, "lua", userid, username)
		u.username = username
	end
end

function api.begin_game(args)
    local userid = args.userid
    local ok,result = checkrule()
    if ok then
        local i = 1
        local user_tbl = R.info.user_tbl
        local uidlist = {}
        for uid, u in pairs(user_tbl) do
            if u.status == READY then
                u.identity = result[i]
                i = i + 1
                table.insert(uidlist, uid)
            end
        end
        table.sort(uidlist)
        R.status = "game"
        R.info = objproxy.new{
            user_tbl = user_tbl,
            round = 1,          -- 第n轮
            pass =1,            -- 第n次提案
            rule = R.info.rules,
            leader = uidlist[math.random(#uidlist)],
            uidlist = uidlist,
            stage = {},         -- 被提名的人
            history = {},
            mode = "plan"      -- plan/audit/quest
        }
    end

    return roominfo(userid)
end

function api.audit(args)
    local userid = args.userid
    if R.info.mode ~= "audit" then
        return {error = "您不能表态"}
    end

    R.audit = {}
    R.audit[userid] = true

    local total,yes = 0,0
    for _,flag in pairs(R.audit) do
        total = total + 1
        if flag then yes = yes+1 end
    end

    if count == #R.info.uidlist then
        if yes > total/2 then
            R.info.mode = "quest"
        else
            R.info.mode = "stage"
            R.info.pass = R.info.pass + 1
            if R.info.pass > 100 then
                -- 自动流产
            else
            end
        end
    end
end

function api.stage(args)
    if R.info.mode ~= "plan" or R.info.leader ~= args.userid then
        return {error = "您不能提名"}
    end

    -- todo: check stagelist
    R.info.stage = args.stagelist
    R.info.mode = "audit"
end

function api.ready(args)
	local userid = args.userid
	local enable = args.enable
	local u = R.info.user_tbl[userid]
    u.status = enable and READY or NOTREADY
end

function api.kick(args)
	local id = tonumber(args.id)
	local u = R.info.user_tbl[id]
	if not u then
		return
	end
    u.status = BLOCK
end

function api.set(args)
	local rule = tonumber(args.rule)
	local enable = args.enable

    R.info.rules[rule] = enable and true or nil
end

function api.request(args)
	local userid = args.userid
	local version = tonumber(args.version)
	local co = R.push_tbl[userid]
	if co then
		skynet.wakeup(co)
        R.push_tbl[userid] = nil
	end
	if version ~= 0 and version == R.version then
		local co = coroutine.running()
		R.push_tbl[userid] = co
		skynet.sleep(PUSH_TIME)
		R.push_tbl[userid] = nil
		if version == R.version then
			return {version = version}
        end
	end
	return roominfo(userid)
end

function api.list(args)
	local userid = args.userid
	local u = R.info.user_tbl[userid]
	if not u.identity then
		return {error = "您未分配角色"}
	end
	local identity_name = rule.role[u.identity]
	local role_visible = rule.visible[u.identity]
	local tmp_information = {}
	for _, u in pairs(R.info.user_tbl) do
        local visible = role_visible[u.identity]
        if visible then
            local identity_name
            if visible == true then
                identity_name = rule.role[u.identity]
            elseif visible == 4 then
                identity_name = rule.camp_name[u.identity]
            elseif visible == 3 and R.info.rules[8] then
                identity_name = rule.role[u.identity]
            end
            if identity_name then
                table.insert(tmp_information, {username = u.username, identity = identity_name})
            end
        end
	end

	local players = {}
	for _, uid in ipairs(R.info.uidlist) do
        local u = R.info.user_tbl[uid]
		table.insert(players, {userid = u.userid, username=u.username, color = "#ffffff"})
	end

    return {
        players = players,
        identity = {name = identity_name, desc = ""},
        information = tmp_information,
        round = R.info.round,
        pass = R.info.pass,
        leader = R.info.leader
    }
end

function room.api(args)
	local f = args.action and api[args.action]
	if not f then
		return {error = "Invalid Action"}
	end
    print("request", args.action)
	if args.status ~= R.status then
		-- todo push status
		return roominfo(args.userid)
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

local function update_status()
	local idx, co = next(R.push_tbl)
	while(co) do
		skynet.wakeup(co)
		idx, co = next(R.push_tbl, idx)
	end
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

            if objproxy.is_dirty(R.info) then
                R.version = R.version + 1
                R.cache = nil
                objproxy.clean(R.info)
                update_status()
            end
		end
	end)
end)
