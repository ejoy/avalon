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

local M = {}

M.role = {
	"梅林(正)",	-- 1
	"派西维尔(正)",	-- 2
	"兰斯洛特(正)", --3
	"圆桌骑士(正)",	--4
	"刺客(邪)", -- 5
	"莫德雷德(邪)", -- 6
	"莫甘娜(邪)", -- 7
	"兰斯洛特(邪)", --8
	"奥伯伦(邪)", -- 9
	"爪牙(邪)", -- 10
}

M.camp_name = {
    "正", "正", "正", "正",  "邪", "邪", "邪", "邪","邪", "邪"
}

-- 4: 表示只能看见派别，不能看见身份
M.visible = {
--   梅林   派西维尔 兰(正)  骑士   刺客  莫德雷德  莫甘娜  兰(邪)  奥伯伦  爪牙
   { false, false,     false,   false, true,  false,       true,   true,     true,  true },   --梅林
   { 4,      false,     false,   false, true,  false,       4,       false,    false, false },  --派西维尔
   { false, false,     false,   false, false, false,       false,   3,        false, false },  --兰(正)
   { false, false,     false,   false, false, false,       false,  false,    false, false },  --正
   { false, false,     false,   false, false, 4,            4,       true,     false, 4 },	  --刺客
   { false, false,     false,   false, 4,      false,       4,       true,     false, 4 },   --莫德雷德
   { false, false,     false,   false, 4,      4,            false,  true,     false, 4 },   --莫甘娜
   { false, false,      3,       false, 3,      3,            3,       false,     false, 3 },      --兰(邪)
   { false, false,     false,   false, false, false,       false,  false,    false, false },  --奥伯伦
   { false, false,     false,   false, false, true,        true,   true,     false, true },	  --刺客
}

local camp_good = {
	0,0,0,0,	-- can't below 4
	3,	-- 5
	4,	-- 6
	4,	-- 7
	5,	-- 8
	6,	-- 9
	6,	-- 10
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
function M.checkrules(rules, n)
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
		return true, randomrole(ret)
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
	return true, randomrole(ret)
end

M.pass_limit = 4

M.stage_per_round = {
    [5] = {2,3,2,3,3},
    [6] = {2,3,4,3,4},
    [7] = {2,3,3,-4,4},
    [8] = {3,4,4,-5,5},
    [9] = {3,4,4,-5,5},
    [10] = {3,4,4,-5,5},
}

M.camp_good = camp_good
return M
