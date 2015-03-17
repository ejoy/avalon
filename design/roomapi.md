URL
====

用户访问的房间 URL 统一是 /123456 的形式，就是 /　加数字。

所有和房间通讯的 xmlhttprequest 请求都发到 /room 这个 url 上。

Cookie
====

每个用户都带有一个 unique userid 。cookie 名为 userid 。
如果用户没有 userid 的 cookie ，服务器主动生成一个设为 cookie 。

状态
====
房间有多个状态，不同的状态对应不同的页面。但都是通过 /123456 这样形式的 URL 访问到的。

* 准备状态
* 游戏状态

下面先讨论准备状态

准备状态
====
通过向 /room 发送 json 请求，可以做准备状态的交互。每个请求都必须有几个必备项。

* roomid: 123456
* status: "prepare"
* action: "操作名"
* version: 当前已知的状态版本号

如果 roomid 无效，会返回错误信息。应该引导用户回到大厅界面。
如果 roomid 有效，但 status 无效或 action 无效，返回状态信息。
每次请求提交，都应该给出一个当前已知的状态版本号。0 表示获取全新版本。

action 可以是这些：

* setname : 更换名字。username : 名字。
* ready : 准备确认。enable : true/false 。
* kick : 将某个用户设为旁观。id : 用户id 。
* set : 修改规则。rule : 规则编号。enable : ture/false 。注：修改规则会导致 ready 状态变化。
* request : 请求当前房间状态。

服务器对请求的返回就是当前房间的状态。

* status : "error" / "ok" / "prepare" / "game"
* version : 当前状态的版本号

* error : 出错了. error : 出错信息。
* ok : 用于请求返回。表示没有状态变化。
* prepare : 目前处于准备状态, 并刷新成新版本。
* game : 目前处于游戏状态, 并刷新成新版本。

关于 prepare 的细节：

首先是玩家列表
player : {
  { userid : xxxx, username : xxxx , color: xxx, status : 0/1/2 准备好，正在准备, 旁观 }
  { ... }
}

然后是规则列表
rule : [ 2,3,4,5 ]
每个数字表示一条 enable 的规则.

最后是不可以开始游戏的原因
needs : "为什么还不能开始游戏"

游戏状态
======

当所有人的状态都为 0 或 2 时, (旁观或准备好). 房间有可能进入游戏状态.

进入游戏状态还需要满足几个条件:

游戏人数在 5~10 人. 规则需要匹配对应的人数. 如果规则不匹配, 或其它条件不满足.
返回的状态表中, 有一项 needs 表示了原因, 供 client 提示.

一旦条件满足, 房间状态自动进入游戏状态. status = "game"

游戏分五个阶段, 每个大阶段分多个小阶段.

小阶段有四个: 提案 , 投票 和任务 以及结束. 由于这个工具定义为辅助线下游戏,所以并不严格校验游戏规则.

任何人都可以提案,或修改提案. 任何人都可以对提案投票. 一旦投票通过, 提案中参与玩家必须进行任务. 依次循环.

在查询游戏中的房间状态时, 用一个数组下发游戏的历史进程.

"history" : [
	{ 
	"leader" : userid,	// 谁在提案
	"plan" : [ userid , userid , userid, ... ] ,
	"vote" : [userid, userid, userid, ... ] ,
	"result" : [true, false, true, ...] , // 可选
	"quest" : [userid, userid, userid, ...] ,
	"ending" : 几张失败票 }, 
	...
],

每个阶段都从 plan 开始, 一旦有一个人提交了提案, 其他玩家可以继续修改提案或对提案投票.
一个 plan 需要几个 id , 由规则决定. 规则是预先写在 client 的.

* 5 人局:  2/3/2/3/3 
* 6 人时，任务人数分别是 2/3/4/3/4 
* 7 人时，任务人数分别是 2/3/3/4/4 
* 8-10 人时，任务人数分别是 3/4/4/5/5 

对于 7 人+, 第四轮是特殊轮, 需要两张失败票,任务才失败.

客户端可以校验提交的提案人数是否符合要求, 服务器会再校验.

一旦有一个人提交了提案, 在 history 里就会有体现. 只要当前阶段没有进入 quest 环节,
所有人都在 client 显示 "修改提案", 同时显示投票.

一旦有人修改提案, 未完成的 vote 将被复位, 所有人必须重新投票.

如果所有玩家都提交了投票(赞成或反对), 就会进入投票环节,不再接受修改提案和投票.
并有 result 字段表示投票结果 (对应上面的投票 userid).

如果提案通过, 则有 quest 阶段. 除了参于玩家外, 其他玩家都不能提交任务. 
但可以看到那些玩家做了任务. 

任务完毕后,会到 ending 阶段,  显示当前任务中有几票失败票. 

一个房间状态的例子:

<pre>
"history" : [
	{ 
	  "leader" : id1,	// 提案由 id1 提出
	  "vote" : [id1, id2 ,id3 , ...],
	  "result", [true, false, false, ...],	// 议案被否决
	},
	{ "leader" : id2,	// 提案由 id2 提出
	  "vote" : [id1, id2 ,id3 , ...],
	  "result" : [true, true, true, ...],
	  "quest" : [id2, id3, ...],
	  "ending" : 0,		// 成功
	},
	{ "leader" : id3,
	  "plan" :[id1, id2, id3, id4],
	  "vote" : [id5, ...],	// 还在投票中, 尚未达成一致.
	}
]
</pre>

在游戏过程中,玩家可以提的操作有:

* plan : 提出一个提案, "list" : [id1, id2, ...]
* vote : 对当前提案投票. "ticket" : true/false
* quest : 进行一个任务, "ticket" : true/false
* list : 请求用户列表, 以及个人的身份, 还有其它额外的信息.

如果是发送 list, 那么将返回一个当前用户列表.

{
  "player" : [ { "userid" : id , "username" : "name", "color" : "#ffffff" }, ... ],
  "identity" : { "name" : 名称 , "desc" : "描述串"  },
  "information" : [ { "userid" : "身份" } , ...  ]	// 可以看见的 userid 的身份.
}