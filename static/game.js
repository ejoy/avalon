var AvalonGame = function(){
    this.status = "game";
    this.mission = 1; // 第几个任务, 总共5轮，也就最多5个任务
    this.plan = 1; // 第几个提案
    this.rules = {
        5: [2, 3, 2, 3, 3],
        6: [2, 3, 4, 3, 4],
        7: [2, 3, 3, 4, 4],
        8: [3, 4, 4, 5, 5],
    }
}

AvalonGame.fn = AvalonGame.prototype = {constructor: AvalonGame};

AvalonGame.fn.begin = function(resp){
    this.update_info(resp)
    this.render_players(resp.players, resp.gameinfo.stage)
    this.game_bind_action()
    this.render_role_info(resp)
    //this.set_game_content(0, true)
}

AvalonGame.fn.update_info = function(resp){
    this.mode = resp.gameinfo.mode
    this.is_leader = resp.gameinfo.leader == userid
}

AvalonGame.fn.set_game_history = function(v, poll_begin){
    var req = {
        roomid: room_number,
        status: 'game',
        action: 'request',
        version: v ? v : 0
    };

    Ejoy.postJSON('/room', req, function(resp){ 

    })
}

AvalonGame.fn.update_game = function (v, poll_begin) {
    var self = this
    var req = {
        roomid: room_number,
        status: 'game',
        action: 'request',
        version: v ? v : 0
    }
    Ejoy.postJSON("/room", req, function(resp){
        version = resp.version
        self.update_info(resp)

        if (resp.gameinfo.mode == "audit") {
            Ejoy("stage_prompt").html("请表决该提案")
            Document.getElementsByClassName("audit-action").style.display = "block"
            Document.getElementsByClassName("stage-action").style.display = "none"
            self.render_players(resp.players, resp.gameinfo.stage)
        }

        if (poll_begin) {
            self.update_game(version, true)
        }
    })
}

AvalonGame.fn.wait = function () {
    this.update_game(version, true)
}

AvalonGame.fn.leader_plan = function(resp) {
    var info = resp.gameinfo
    Ejoy("stage_desc").html("第 "+ info.round + " 个任务, 第 " + info.pass + " 次提案")
    Ejoy("stage_prompt").html("请选出 " + info.need + " 人")
    document.getElementsByClassName('stage-action')[0].style.display = "block"
    document.getElementsByClassName('audit-action')[0].style.display = "none"
}

AvalonGame.fn.wait_leader_plan = function (resp) {
    var info = resp.gameinfo
    Ejoy("stage_desc").html("第 "+ info.round + " 个任务, 第 " + info.pass + " 次提案")
    document.getElementsByClassName('stage-action')[0].style.display = "none"
    document.getElementsByClassName('audit-action')[0].style.display = "none"

    var leader
    for (var i=0;i<resp.players.length;i++) {
        if (resp.players[i].userid == info.leader) {
            leader = resp.players[i]
            break
        }
    }
    Ejoy("stage_prompt").html(leader.username + " 正在准备提案")

    this.wait()
}

AvalonGame.fn.game_bind_action = function(){
    self = this;
    Ejoy('role-button').on('click', function(e){
        var target = document.getElementsByClassName('role')[0]
        var ground = document.getElementsByClassName('ground')[0]
        if(target.className.indexOf('show') > -1){
            target.className = target.className.replace('show', '')
            ground.style.display = "block"

        }else{
            ground.style.display = "none"
            target.className += " show"
        }
    });  

    var stage_list = [] 
    Ejoy("game-people").on("click", "people_item", function(select_dom){
        var user_id = select_dom.id;
        if (self.mode == "plan" && self.is_leader) {
            if (stage_list.indexOf(user_id) == -1) 
                stage_list.push(user_id)
             else
                Ejoy.array_remove(stage_list, user_id)

            var status_mark = "status_0"
            if (stage_list.indexOf(user_id) == -1)
                status_mark = "status_1"
            var el = select_dom.children[0]
            el.className = el.className.replace(/status_\d/, status_mark)
            }
        }
    );

    Ejoy('stage-commit').on('click', function(){
        if (self.mode == "plan" && self.is_leader) {
            var req = {
                roomid: room_number,
                status: 'game',
                action: 'stage',
                version: version,
                stagelist: stage_list,
            }

            Ejoy.postJSON('/room', req, function(resp){
                console.log(resp)
                if(!resp.error){
                    self.wait()
                }
            })
        }
    });

    var genaudit = function (flag){
        return function ()  {
            if (self.mode == "audit") {
                var req = {
                    roomid: room_number,
                    status: 'game',
                    action: 'audit',
                    version: version,
                    approve: flag,
                }

                Ejoy.postJSON('/room', req, function(resp){
                    console.log(resp)
                    if(!resp.error){
                        Document.getElementsByClassName("audit-action").style.display = "none"
                        self.wait()
                    }
                })
            }
        }
    }
    Ejoy('audit-yes').on('click', genaudit(true));
    Ejoy('audit-no').on('click', genaudit(false));
}

AvalonGame.fn.render_role_info = function(resp){
    self = this
    if (!resp.error) {
        var identity = resp.identity
        Ejoy('role_name').html(identity.name)
        Ejoy('role-desc').html(identity.desc)
        var friends = resp.information
        var friends_html = ""
        for(var i=0; i<friends.length; i++){
            var v = friends[i]
            friends_html += '<span>' + v.username + " : " + v.identity  + '</span>' 
        } 

        Ejoy("role-visible").html(friends_html)

        if (userid == resp.gameinfo.leader) {
            self.leader_plan(resp)
        } else {
            self.wait_leader_plan(resp)
        }
    }
}

AvalonGame.fn.render_players = function(players, stage){
    var players_str = ""
    for(var i=0; i < players.length; i++){
        var player = players[i]
        var mark = 1
        if (stage.indexOf(player.userid) != -1)
            mark = 0
        var player_str = '<div class="people_item" id="' + 
            player.userid + 
            '"><span class="status_mark status_' + 
            mark +
            '" style="color:' +
            player.color +
            '">' +
            player.username +
            '</span></div>';
        players_str += player_str;
    } 
    Ejoy('game-people').html(players_str);

}

