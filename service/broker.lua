local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local log = require "log"
local staticfile = require "staticfile"
local json = require"json"

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

local userid_header = setmetatable({} , { __mode = "kv",
	__index = function(t,k)
		local v = {
			["Set-Cookie"] = string.format(
				"userid=%d; Path=/; Max-Age=2592000", k),
			["Content-Type"] = "text/html; charset=utf-8"
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
	local args = body
	if not args then
		return '{"status":"error","error":"Invalid Action"}'
	end
	local roomid = args.roomid
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

local function enter_room(room, userid, username, action)
    local room = tonumber(action:sub(2))
    local r = room and skynet.call(roomkeeper, "lua", "query", room)
	if not r then
		return "Invalid or closed room.", 404
	end
	return skynet.call(r, "lua", "web", userid, username), 200
end

local function handle_socket(id)
	-- limit request body size to 8192 (you can pass nil to unlimit)
	local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
    print("!!", body)
    if body and body ~= "" then
        body = json.decode(body)
    end
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
                local userid, username = get_userid(header)
				local f = action_method[action] or enter_room
                
                local ret, c = f(body, userid, username, action)
                if type(ret) ~= "string" then
                    ret = json.encode(ret or {})
                end
                c = c or 200
                response(id, c, ret, userid_header[userid])
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
		local ok,reason = xpcall(handle_socket, debug.traceback, id)
        if not ok then print(reason) end
		socket.close(id)
	end)
end)
