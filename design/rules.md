游戏可选规则
============

* 梅林（正）/刺客（邪） : 此条是根规则. 默认必须选 true , 一旦不选, 所有其它规则为 false 。梅林可以看见邪恶阵营里除莫德雷德外所有人。
* 派西维尔（正) : 一旦选上，他可以看见梅林和莫甘娜。
* 莫甘娜（邪）: 可以看见除奥伯伦之外的所有邪恶阵营。
* 莫德雷德（邪）: 可以看见除奥伯伦之外的所有邪恶阵营。
* 奥伯伦（邪）: 谁也看不见。
* 兰斯洛特（正邪）1. 第三任务转变：随机 5 张卡，3 张为空白，2 张为转变。在第三个任务的每个阶段做一次揭示。
* 兰斯洛特（正邪）2 .每个任务转变：随机 7 张卡，其中 5 张为空白，2 张为转变。选前 5 张，一开始全部揭示。
* 兰斯洛特（正邪）3.：相互可见。
* 王者之剑。

兰斯洛特规则只能三选一，如果选了 3 ，那么正邪兰斯洛特相互可见。

所有角色如下：

正义：梅林、派西维尔、兰斯洛特（正）、其他圆桌骑士。

邪恶：莫德雷德、莫甘娜、奥伯伦、刺客、兰斯洛特（邪）、其他走狗。

邪恶方，奥伯伦和兰斯洛特看不见任何同伴。其他人相互看见，（在前两个选项中）并可以看见兰斯洛特（邪）；
或在第三个选项中，兰斯洛特（邪）可以看见奥伯伦之外的所有邪恶阵营。

分配角色时，先按总人数查下表：

人数 | 邪恶 | 正义
-----|------|-----
5    | 2    | 3
6    | 2    | 4
7    | 3    | 4
8    | 3    | 5
9    | 4    | 5
10   | 4    | 6

如果邪恶方选的特殊角色数量超过了人数，则游戏不能开始。

在 兰斯洛特 2 规则中，兰斯洛特（正）必须在任务中投成功票；
兰斯洛特（邪）必须在任务中投失败票。

除兰斯洛特外的正义角色，参加任务都必须投成功票。


------

角色分配
========

当所有玩家选定规则以及参加人数后, 进入角色分配阶段.

梅林和刺客是一起上场的，属于同一条规则。且如果没有这条规则，其它规则都不可选。
其它规则一共有 4 加 3 选 1 条（王者之剑暂时不实现）。

兰斯洛特(正)(邪) 是一起上场的, 属于同一条规则。有三个变体，只可以选其中之一，或不选择。

当正方特殊角色不够时，应加入若干正派无特殊身份角色，直到数量达到需要的人数。如果特殊角色数量超过人数，应该提示失败，重新选规则。

当反方特殊角色不够时，应该加入若干邪恶无特殊身份角色，直到数量达到需要的人数。如果特殊角色数量超过人数，应该提示失败，重新选规则。

身份随机分配完毕后，可以查下表来决定每个角色可以看到其它哪些角色。表中“正”和“邪”两类角色都有可能不只一人。查到自己所属角色行时，
同一行 x 表示不可见，V 表示可见。? 表示只在兰斯洛特3号可选规则时才可见，否则不可见。


             | 梅林 | 派西维尔 | 兰斯洛特(正) | 正 | 刺客 | 莫德雷德 | 莫甘娜 | 兰斯洛特(邪) | 奥伯伦 | 邪
-------------|------|----------|--------------|----|------|----------|--------|--------------|--------|----
梅林         |  .   |   x      |      x       | x  |  V   |    x     |   V    |     V        |    V   | V
派西维尔     |  V   |   .      |      x       | x  |  x   |    x     |   V    |     x        |    x   | x
兰斯洛特(正) |  x   |   x      |      .       | x  |  x   |    x     |   x    |     ?        |    x   | x
正           |  x   |   x      |      x       | .  |  x   |    x     |   x    |     x        |    x   | x
刺客         |  x   |   x      |      x       | x  |  .   |    V     |   V    |     V        |    x   | V
莫德雷德     |  x   |   x      |      x       | x  |  V   |    .     |   V    |     V        |    x   | V
莫甘娜       |  x   |   x      |      x       | x  |  V   |    V     |   .    |     V        |    x   | V
兰斯洛特(邪) |  x   |   x      |      ?       | x  |  ?   |    ?     |   ?    |     ?        |    x   | ?
奥伯伦       |  x   |   x      |      x       | x  |  x   |    x     |   x    |     x        |    .   | x
邪           |  x   |   x      |      x       | x  |  V   |    V     |   V    |     V        |    x   | V


```lua
--[[ 规则列表
	"梅林",	-- 1
	"派西维尔", -- 2
	"莫甘娜", -- 3
	"莫德雷德", -- 4
	"奥伯伦", -- 5
	"兰斯洛特1", -- 6
	"兰斯洛特2", -- 7
	"兰斯洛特3", -- 8
]]

local role = {
	"梅林(正)",	-- 1
	"派西维尔(正)",	-- 2
	"兰斯洛特(正)", --3
	"圆桌骑士(正)",	--5
	"刺客(邪)", -- 5
	"莫德雷德(邪)", -- 6
	"莫甘娜(邪)", -- 7
	"兰斯洛特(邪)", --8
	"奥伯伦(邪)", -- 9
	"爪牙(邪)", -- 10
}

local visible = {
--   梅林 派西维尔 兰(正)  正    刺客  莫德雷德 莫甘娜  兰(邪) 奥伯伦  邪
   { false, false, false, false, true,  false,   true,   true,   true,  true },   --梅林
   { true,  false, false, false, true,  false,   true,   false,  false, false },  --派西维尔
   { false, false, false, false, false, false,   false,   3,     false, false },  --兰(正)
   { false, false, false, false, false, false,   false,  false,  false, false },  --正
   { false, false, false, false, false, true,    true,   true,   false, true },	  --刺客
   { false, false, false, false, true,  false,   true,   true,   false, true },   --莫德雷德
   { false, false, false, false, true,  true,    false,  true,   false, true },   --莫甘娜
   { false, false, 3,     false, 3,     3,       3,      false,  false, 3 },      --兰(邪)
   { false, false, false, false, false, false,   false,  false,  false, false },  --奥伯伦
   { false, false, false, false, false, true,    true,   true,   false, true },	  --刺客
}

local camp_good = {
	0,0,0,0,	-- can't below 4
	2,	-- 5
	2,	-- 6
	3,	-- 7
	3,	-- 8
	4,	-- 9
	4,	-- 10
}

local function randomrole(roles)
	local n = #roles
	for i=1, n-1 do
		local c = math.random(i,n)
		roles[i],roles[c] = roles[c],roles[i]
	end
	return roles
end

-- 本函数会返回一个 table ， 包含有所有参于的角色；或返回出错信息。
function checkrules(rules, n)
	if n <5 or n>10 then
		return false, "游戏人数必须在 5 到 10 人之间"
	end
	if not rules[1] then
		for i=2,8 do
			if rules[i] then
				return false, "当去掉梅林时，不可以选择其他角色"
			end
		end
		local ret = {}
		for i=1,camp_good[n] do
			table.insert(ret, 4)
		end
		for i=1,n-camp_good[n] do
			table.insert(ret, 10)
		end
		return randomrole(ret)
	end
	local lancelot = 0
	for i=6,8 do
		if rules[i] then
			lancelot = lancelot + 1
		end
	end
	if lancelot > 1 then
		return false,"请从兰斯洛特规则里选择其中一个，或则不选"
	end
	local ret = {1,3,5,8}

	local good = 1	-- 梅林
	local evil = 1	-- 刺客
	if rules[2] then
		good = good + 1	--派西维尔
		table.insert(ret,2)
	end
	if lancelot == 1 then
		good = good + 1
		evil = evil + 1
		table.insert(ret,3)
		table.insert(ret,8)
	end
	if rules[3] then	-- 莫甘娜
		evil = evil + 1
		table.insert(ret, 7)
	end
	if rules[4] then
		evil = evil + 1	-- 莫德雷德
		table.insert(ret, 6)
	end
	if rules[5] then
		evil = evil + 1	-- 奥伯伦
		table.insert(ret, 9)
	end
	if good > camp_good[n] then
		return false, "好人身份太多"
	end
	if evil > n-camp_good[n]  then
		return false, "坏人身份太多"
	end
	for i = 1,camp_good[n] -  good do
		table.insert(ret, 4)
	end
	for i = 1,n-camp_good[n] -  evil do
		table.insert(ret, 10)
	end
	return randomrole(ret)
end
```
