local skynet = require "skynet"

local content = [[
<html>
<header>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Game</title>
</header>
<body>
<ul>
<li>创建新房间</li>
<li>进入房间</li>
</ul>
</body>
</html>
]]

local function main(header)
	return content, {}
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, httpheader)
		skynet.ret(skynet.pack(main(httpheader)))
	end)
end)
