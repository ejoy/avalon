local skynet = require "skynet"

local users = {}
local lastid = 0

local function new_username(userid)
	local username = "u"..tostring(userid)
	users[userid] = username
	return username
end

local function create_userid()
	local ti = math.floor(skynet.time()) - 1420000000
	if ti > lastid then
		lastid = ti
	else
		lastid = ti + 1
	end
	return lastid, new_username(lastid)
end

local function get_username(userid)
	local username = users[userid]
	if not username then
		username = new_username(userid)
	end
	return username
end

-- todo: check username
local function set_username(userid, username)
	users[userid] = username
end

skynet.start(function()
	skynet.dispatch("lua", function (_,_,userid,username)
		if not userid then
			userid, username = create_userid()
		else
			if not username then
				username = get_username(userid)
			else
				set_username(userid, username)
				username = users[userid]
			end
		end
		skynet.ret(skynet.pack(userid, username))
	end)
end)
