local skynet = require "skynet"
local math = math
local utf8 = utf8
local table = table

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
		lastid = lastid + 1
	end
	return tostring(lastid), new_username(lastid)
end

local function get_username(userid)
	local username = users[userid]
	if not username then
		username = new_username(userid)
	end
	return username
end

local function set_username(userid, username)
	-- verify username
	if #username > 16 or username:find "[^%w%.\128-\255]" then
		local temp = {}
		for p,c in utf8.codes(username) do
			if #temp > 8 then
				break
			end
			if c > 128 or string.char(c):find "[%w%.]" then
				table.insert(temp, c)
			end
		end
		if #temp > 1 then
			users[userid] = utf8.char(table.unpack(temp))
		else
			new_username(userid)
		end
	else
		users[userid] = username
	end
end

skynet.start(function()
	skynet.dispatch("lua", function (_,_,userid,username)
		if not userid then
			userid, username = create_userid()
		else
			if not username or username == "" then
				username = get_username(userid)
			else
				set_username(userid, username)
				username = users[userid]
			end
		end
		skynet.ret(skynet.pack(userid, username))
	end)
end)
