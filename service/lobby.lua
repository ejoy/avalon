local skynet = require "skynet"
local urllib = require "http.url"
local staticfile = require "staticfile"
local string = string

local userservice
local roomkeeper

local content = staticfile["index.html"]

local function main()
	return content
end

local action = {}

function action.getname(userid, username, args)
	return {username = username}
end

function action.setname(userid, username, args)
	local userid, username = skynet.call(userservice, "lua", userid, args.username)
    return {username = username}
end

function action.create(userid, username, args)
	local ok, roomid = skynet.call(roomkeeper, "lua", "open")
	return ok and {room = roomid} or {error = roomid}
end

function action.join(userid, username, args)
	local roomid = tonumber(args.roomid)
	if roomid and skynet.call(roomkeeper, "lua", "query", roomid) then
        return {roomid = roomid}
	else
        return {error = "invalid room id"}
	end
end

skynet.start(function()
	userservice = assert(skynet.uniqueservice "userid")
	roomkeeper = assert(skynet.uniqueservice "roomkeeper")
	skynet.dispatch("lua", function(_,_, cmd, userid, username, body)
		if cmd == "web" then
			skynet.ret(skynet.pack(main(httpheader)))
		elseif cmd == "api" then
			-- lobby api
			local args = urllib.parse_query(body)
            local ret = {username = username}
			if args then
				local f = action[args.action]
                if f then
                    ret = f(userid, username, args)
                else
                    ret = {error = "Invalid Action"}
                end
			end

			skynet.ret(skynet.pack(ret))
		end
	end)
end)
