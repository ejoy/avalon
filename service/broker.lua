local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local log = require "log"
local staticfile = require "staticfile"

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

action_method["/room"] = function(body, userid, username)
	local args = urllib.parse_query(body)
	if not args then
		return '{"status":"error","error":"Invalid Action"}'
	end
	local roomid = tonumber(args.roomid)
	if not roomid then
		return '{"status":"error","error":"Invalid Room id"}'
	end
	local r = skynet.call(roomkeeper, "lua", "query", roomid)
	if not r then
		return '{"status":"error","error":"Room not open"}'
	end
	args.userid = userid
	return skynet.call(r, "lua", "api", args)
end

local function dispatch_room(room, userid, username)
	local r = skynet.call(roomkeeper, "lua", "query", room)
	if not r then
		return 404, "Invalid or closed room."
	end
	local body = skynet.call(r, "lua", "web", userid, username)
	return 200, body
end

local function handle_socket(id)
	-- limit request body size to 8192 (you can pass nil to unlimit)
	local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
	if code then
		if code ~= 200 then
			response(id, code)
		else
			local action = urllib.parse(url)
			local offset = action:find("/",2,true)
			if offset then
				local path = action:sub(1,offset-1)
				local filename = action:sub(offset+1)
				if path == "/static" then
					local content = staticfile[filename]
					if content then
						response(id, 200, content)
					else
						response(id, 404, "404 Not found")
					end
				else
					response(id, 404, "404 Not found")
				end
			else
				local f = action_method[action]
				if not f then
					local room = tonumber(action:sub(2))
					if room then
						local userid, username = get_userid(header)
						local c, body = dispatch_room(room, userid, username)
						response(id, c, body, userid_cookie[userid])
					else
						response(id, 404, "404 Not found")
					end
				else
					local userid, username = get_userid(header)
					response(id, 200, f(body, userid, username), userid_cookie[userid])
				end
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
