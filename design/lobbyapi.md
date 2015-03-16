URL
====

用户通过 /　访问大厅。

所有和房间通讯的 xmlhttprequest 请求都发到 /lobby 这个 url 上。

Cookie
====

每个用户都带有一个 unique userid 。cookie 名为 userid 。
如果用户没有 userid 的 cookie ，服务器主动生成一个设为 cookie 。

API
====
通过向 /lobby 发送请求。请求必须使用 x-www-form-urlencoded 格式，Content-Type 可以不填（会被忽略）。

必须有一个 action 字段，表示发起的动作，它可以是：

* getname : 获取名字。可以用来获取自己的用户名。
* setname : 设置名字。可以用来修改自己的用户名。需要额外字段 username 。
* create : 创建一个新房间。
* join : 进入一个房间。需要额外字段 roomid 。

服务器返回 json 格式。status 字段表示状态，可以是

* ok : 表示操作成功。另外有字段 username 表示当前用户名。
* error : 表示操作失败，还会有一个额外的 error 字段描述具体信息。
* join : 表示应该进入一个房间, 还会有一个额外的字段 room 表示房间号(一个整数)。
