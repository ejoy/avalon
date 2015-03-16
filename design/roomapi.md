URL
====

用户访问的房间 URL 统一是 /123456 的形式，就是 /　加数字。

所有和房间通讯的 xmlhttprequest 请求都发到 /room 这个 url 上。

Cookie
====

每个用户都带有一个 unique userid 。cookie 名为 userid 。
如果用户没有 userid 的 cookie ，服务器主动生成一个设为 cookie 。

每个用户都可选一个 username 的 cookie ，不要求唯一。
如果用户没有 username 的 cookie ，服务器会先从历史中查找到这个 userid 用过的最后一个用户名，
如果没有，就生成一个 用户XXX 的名字。

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
如果 roomid 有效，但 status 无效或 action 无效，返回错误信息。应该引导用户刷新房间页面。
每次请求提交，都应该给出一个当前已知的状态版本号。0 表示获取全新版本。

action 可以是这些：

* name : 更换名字。name : 名字。
* ready : 准备确认。enable : true/false 。
* kick : 将某个用户设为旁观。id : 用户id 。
* set : 修改规则。rule : 规则编号。enable : ture/false 。注：修改规则会导致 ready 状态变化。
* request : 请求当前状态。

服务器对请求的返回就是当前房间的状态。

* status : "error" / "ok" / "prepare" / "game"
* version : 当前状态的版本号

* error : 出错了， errno : 出错号. error : 出错信息。
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
rule : {
  { rule: 编号, enable : true/false }
  { ... }
}






