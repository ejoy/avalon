// 请求房间状态 ajax long pulling update 状态 
// 返回结果 更新 页面内容
// cookie 获取当前用户的user_id
// click 操作的 绑定
var room_number;
var version;
document.addEventListener("DOMContentLoaded", function(){
    set_room_number();
    set_room_content();
});

function set_room_number(){
    var pathname = location.pathname.split('/')
    room_number = pathname[pathname.length - 1]
    Ejoy('room_number').html(room_number) 
}

function set_room_content(){
    var req = {
        roomid: room_number,
        status: 'prepare',
        action: 'request',
        version: 0
    }
    Ejoy.postJSON('/room', req, function(resp){
        //resp = {
            //player: [{userid: '1233', username: "xxx_name1", color: "green", status: 0 },
                //{userid: '1235', username: "xxx_name3", color: "red", status: 2 },],
                //rule: [ 2, 3 ]
        //} 

        Ejoy('people_num').html(resp.player.length)
        render_players(resp.player)
        render_people_status(resp.player)
        render_rules(resp.rule)

        bind_action()
    })
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
    var rules_str = ""
    rules_dom = document.getElementsByClassName("room_rule")[0].children
    for(var i = 0; i < rules.length; i++){
        rules_dom[rules[i]].className += " rule_enabled"
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

function bind_action(){
    Ejoy('people').on("click", "people_item", function(select_dom){
        var userid = select_dom.id;
        console.log(userid)
        //kick_user(userid)
    });

    Ejoy('room_rule').on('click', 'rule_item', function(select_dom){
        var rule_num = select_dom.dataset.rule
        var enabled  = !(select_dom.className.indexOf("rule_enabled") > -1)

        if(enabled){
            select_dom.className += " rule_enabled"
        }else{
            select_dom.className = "rule_item"
        }
        console.log(rule_num, enabled)
        //set_rule(rule_num, enabled)
    })
    
    Ejoy('action_button').on('click', function(e){
        var name = e.target.previousElementSibling.value
        console.log(name)
        //set_user_name(name)
    })
}


function kick_user(userid){
    var req = {
        roomid: room_number,
        status: 'prepare',
        action: 'kick',
        version: version,

        id: userid
    }
    Ejoy.postJSON('/room', req, function(resp){});
    
}

function set_user_name(username){
    var req = {
        roomid: room_number,
        status: 'prepare',
        action: 'set_name',
        version: version,

        username: username
    }
    Ejoy.postJSON('/room', req, function(resp){});

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
    Ejoy.postJSON('/room', req, function(resp){});

}
