local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local log = require "log"

local roomkeeper
local userservice
local lobby
local address_table = {}
local action_method = {}

local function response(id, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
	if not ok then
		if err ~= sockethelper.socket_error then
			log.printf("%s error : %s", address_table[id], err)
		end
	end
end

-- get userid from cookies, and query username from userservice
local function get_userid(header)
	local cookie = header.cookie
	local userid
	if cookie then
		for k,v in cookie:gmatch " *(.-)=([^;]*);?" do
			if k == "userid" then
				userid = tonumber(v)
				break
			end
		end
	end
	return skynet.call(userservice, "lua", userid)
end

local userid_cookie = setmetatable({} , { __mode = "kv",
	__index = function(t,k)
		local v = {
			["Set-Cookie"] = string.format(
				"userid=%d; Path=/; Max-Age=2592000", k)
		}
		t[k] = v
		return v
	end,
})

action_method["/"] = function(body, userid, username)
	return skynet.call(lobby, "lua", "web", userid, username)
end

action_method["/lobby"] = function(body, userid, username)
	return skynet.call(lobby, "lua", "api", userid, username, body)
end

local function dispatch_room(room, userid, username)
	local r = skynet.call(roomkeeper, "lua", "query", room)
	if not r then
		return 404, "Invalid or closed room."
	end
	return 200, skynet.call(r, "lua", "web", userid, username), userid_cookie[userid]
end

local function handle_socket(id)
	-- limit request body size to 8192 (you can pass nil to unlimit)
	local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
	if code then
		if code ~= 200 then
			response(id, code)
		else
			local action = urllib.parse(url)
			local f = action_method[action]
			if not f then
				local room = tonumber(action:sub(2))
				if room then
					local userid, username = get_userid(header)
					response(id, dispatch_room(room, userid, username), userid_cookie[userid])
				else
					response(id, 404, "404 Not found")
				end
			else
				local userid, username = get_userid(header)
				response(id, 200, f(body, userid, username), userid_cookie[userid])
			end
		end
	else
		if url ~= sockethelper.socket_error then
			log.printf("%s error: %s", address_table[id], url)
		end
	end
end

skynet.start(function()
	roomkeeper = assert(skynet.uniqueservice "roomkeeper")
	userservice = assert(skynet.uniqueservice "userid")
	lobby = assert(skynet.uniqueservice "lobby")
	skynet.dispatch("lua", function(_,_,id, ipaddr)
		address_table[id] = ipaddr
		socket.start(id)
		pcall(handle_socket, id)
		socket.close(id)
	end)
end)
