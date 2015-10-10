// 请求房间状态 ajax long pulling update 状态 
// 返回结果 更新 页面内容
// cookie 获取当前用户的user_id
// click 操作的 绑定

var room_number, version, userid, game_status;
var user_ready = false;

document.addEventListener("DOMContentLoaded", function(){
    userid = Ejoy.getCookie('userid');
    set_room_number();
    set_room_content(0, true);
    bind_action()

    function set_room_number(){
        var pathname = location.pathname.split('/')
        room_number = parseInt(pathname[pathname.length - 1], 10)
        Ejoy('room_number').html(room_number) 
    }

    function set_room_content(v, poll_begin){
        var req = {
            roomid: room_number,
            status: 'prepare',
            action: 'request',
            version: v ? v : 0
        }
        Ejoy.postJSON('/room', req, function(resp){
            console.log('request', resp)
            if(game_status == "game"){return}
            if (resp.error) {return}

            version = resp.version;
            if(resp.status){
                if(resp.status == "game"){

                    game_status = "game"
                    prepare_clear()
                    var avalon = new AvalonGame(userid)
                    version = 0
                    return avalon.begin(resp)
                }
            }
            if(resp.player){
                Ejoy('people_num').html(resp.player.length)

                render_players(resp.player)
                render_people_status(resp.player)
                render_prepare_action(resp.player)
            }
            if(resp.rule){
                render_rules(resp.rule)
            }

            render_game_status(resp.reason)
            render_begin_button(resp.can_game)


            if(poll_begin){
                console.log("polling")
                set_room_content(version, true)
            }
        })
    }

    function render_game_status(reason) {
        if (reason) {
            Ejoy("game-status").html(reason)
        } else {
            Ejoy("game-status").html("")
        }
    }

    function render_begin_button(can_game) {
        if (can_game) {
            Ejoy("begin_button").html("开始")
        } else {
            Ejoy("begin_button").html("")
        }
    }

    function prepare_clear(){
        var prepare = document.getElementsByClassName('prepare')[0]
        var game  = document.getElementsByClassName('game')[0]
        prepare.style.display = "none"
        game.style.display = "block"
    }

    function render_players(players){
        var players_str = ""
        for(var i=0; i < players.length; i++){
            var player = players[i]
            var player_str = '<div class="people_item" id="' + 
                             player.userid + 
                             '"><span class="status_mark status_' + 
                             player.status +
                             '" style="color:' +
                             player.color +
                             '">' +
                             player.username +
                             '</span></div>';
            players_str += player_str;
        } 
        Ejoy('people').html(players_str);
    }

    function render_rules(rules){
        if(!rules){
            rules = []
        }
        var rules_str = ""
        rules_dom = document.getElementsByClassName("room_rule")[0].children
        for(var i = 0; i < rules.length; i++){
            rules_dom[rules[i]-1].className += " rule_enabled"
        }
    }

    function render_people_status(players){
       var prepare=0, watch=0, ready=0; 
       for(var i=0; i< players.length; i++){
           switch(players[i].status){
                case 0:
                    ready++;
                    break;
                case 1:
                    prepare++;
                    break;
                case 2:
                    watch ++;
                    break
           } 
       }

       var status = "";
       status += '<div><span>' + ready   + '</span>人准备好</div>' +
                 '<div><span>' + prepare + '</span>人正在准备</div>' +
                 '<div><span>' + watch   + '</span>人旁观</div>'
       Ejoy('people_status').html(status)
    }

    function render_prepare_action(players){
        var username="";
        for(var i=0; i< players.length; i++){
            var player = players[i]
            if(player.userid == userid){
                user_ready = player.status
                username = player.username
                break;
            }
        }
        var action = user_ready == 0 ? "取消准备" :"准备";
        Ejoy('action_button').html(action)
        document.getElementsByClassName('action_value')[0].value = username
    }

    function bind_action(){
        Ejoy('people').on("click", "people_item", function(select_dom){
            var userid = select_dom.id;
            console.log(userid)
            kick_user(userid, select_dom.children[0])
        });

        Ejoy('room_rule').on('click', 'rule_item', function(select_dom){
            var rule_num = select_dom.dataset.rule
            var enabled  = !(select_dom.className.indexOf("rule_enabled") > -1)

            if(enabled){
                select_dom.className += " rule_enabled"
            }else{
                select_dom.className = "rule_item"
            }
            set_rule(rule_num, enabled)
        })
        
        Ejoy('action_button').on('click', function(e){
            var name = e.target.previousElementSibling.value
            if(!name){
                return alert("请输入名字");
            }
            set_user_name(name)
        })

        Ejoy("begin_button").on("click", function (e){
            begin_game()
        })
    }


    function kick_user(userid, select_dom){
        var req = {
            roomid: room_number,
            status: 'prepare',
            action: 'kick',
            version: version,

            id: userid
        }
        Ejoy.postJSON('/room', req, function(resp){
            if(!resp.error){
                select_dom.className = select_dom.className.replace(/status_\d/, 'status_2')
                set_room_content()
            }
        });
        
    }

    function set_user_name(username){
        var req = {
            roomid: room_number,
            status: 'prepare',
            action: 'setname',
            version: version,
            username: username
        }
        Ejoy.postJSON('/room', req, function(resp){
            if(!resp.error){
                name_span = document.getElementById(userid).children[0]            
                name_span.innerHTML = username
                set_ready()
            }
        });

    }

    function set_rule(rule_num, enable){
        var req = {
            roomid: room_number,
            status: 'prepare',
            action: 'set',
            version: version,

            rule: rule_num,
            enable: enable
        }
        Ejoy.postJSON('/room', req, function(resp){
            set_room_content()
        });

    }

    function set_ready(){
        var req = {
            roomid: room_number,
            status: 'prepare',
            action: 'ready',
            version: version,
            enable: !!user_ready,
        }
        Ejoy.postJSON('/room', req, function(resp){
           if(!resp.error){
               set_room_content();
           }
        })
    }

    function begin_game() {
        var req = {
            roomid: room_number,
            status: "prepare",
            action: "begin_game",
            version:version,
        }
        Ejoy.postJSON('/room', req, function(resp){
            if(!resp.error){
                set_room_content();
            }
        })
    }
});
