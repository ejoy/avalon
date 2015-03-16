URL
====

用户通过 /　访问大厅。

所有和房间通讯的 xmlhttprequest 请求都发到 /lobby 这个 url 上。

Cookie
====

每个用户都带有一个 unique userid 。cookie 名为 userid 。
如果用户没有 userid 的 cookie ，服务器主动生成一个设为 cookie 。

每个用户都可选一个 username 的 cookie ，不要求唯一。
如果用户没有 username 的 cookie ，服务器会先从历史中查找到这个 userid 用过的最后一个用户名，
如果没有，就生成一个 用户XXX 的名字。

名字会显示在大厅界面上左上角，并可以改变。

API
====
通过向 /lobby 发送 json 请求，可以发起几个可选动作。

* action 字段表示要做什么动作，它可以是：
** name : 名字。可以用来修改自己的用户名。
** create : 创建一个新房间。
** join : 进入一个房间。( room: id )

服务器可能返回：

* status : "ok" / "error" / "join"

ok 表示操作成功
error 表示操作失败。进一步的描述由 error 字段给出。
join 表示应该引导用户去一个房间。room 字段是房间号。





