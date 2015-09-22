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
    this.update_game(0)
}

AvalonGame.fn.update_info = function(resp){
    this.mode = resp.gameinfo.mode
    this.is_leader = resp.gameinfo.leader == userid
    this.stage = resp.gameinfo.stage
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

AvalonGame.fn.update_game = function (v) {
    var self = this
    var req = {
        roomid: room_number,
        status: 'game',
        action: 'request',
        version: v ? v : 0
    }
    Ejoy.postJSON("/room", req, function(resp){
        console.log(resp)
        if (resp.error){
            return
        }

        gameinfo = resp.gameinfo
        version = resp.version
        self.update_info(resp)

        Ejoy("stage_title").html("共" + resp.evil_count + "个反方")
        Ejoy("stage_desc").html("第 "+ resp.gameinfo.round + " 个任务, 第 " + resp.gameinfo.pass + " 次提案" + " 已成功" + gameinfo.round_success + "个任务")

        if (resp.gameinfo.history) {
            var hist = ""
            for (var i=0;i<resp.gameinfo.history.length;i++) {
                hist += "<pre>" + resp.gameinfo.history[i] + "</pre>"
            }
            Ejoy("game-history").html(hist)
        }

        if (resp.gameinfo.mode == "plan") {
            self.render_players(resp.players, resp.gameinfo.stage)
            if (userid == resp.gameinfo.leader) {
                var info = resp.gameinfo
                Ejoy("stage_prompt").html("请选出 " + info.need + " 人")
                document.getElementsByClassName('stage-action')[0].style.display = "block"
                document.getElementsByClassName('vote-action')[0].style.display = "none"
                return
            } else {
                var info = resp.gameinfo
                Ejoy("stage_desc").html("第 "+ info.round + " 个任务, 第 " + info.pass + " 次提案")
                document.getElementsByClassName('stage-action')[0].style.display = "none"
                document.getElementsByClassName('vote-action')[0].style.display = "none"

                var leader
                for (var i=0;i<resp.players.length;i++) {
                    if (resp.players[i].userid == info.leader) {
                        leader = resp.players[i]
                        break
                    }
                }
                Ejoy("stage_prompt").html(leader.username + " 正在准备提案")

                self.wait()
            }
        }

        if (resp.gameinfo.mode == "audit") {
            var leader
            for (var i=0;i<resp.players.length;i++) {
                if (resp.players[i].userid == resp.gameinfo.leader) {
                    leader = resp.players[i]
                    break
                }
            }

            Ejoy("stage_prompt").html("请表决 " + leader.username + " 的提案")
            document.getElementsByClassName("vote-action")[0].style.display = "block"
            document.getElementsByClassName("stage-action")[0].style.display = "none"
            self.render_players(resp.players, resp.gameinfo.stage)
            return
        }

        if (resp.gameinfo.mode == "quest") {
            document.getElementsByClassName("stage-action")[0].style.display = "none"
            self.render_players(resp.players, resp.gameinfo.stage)

            if (resp.gameinfo.stage.indexOf(userid) == -1) {
                Ejoy("stage_prompt").html("请等待投票结果")
                document.getElementsByClassName("vote-action")[0].style.display = "none"
                self.wait()
            } else {
                Ejoy("stage_prompt").html("请投票决定任务成功或失败")
                document.getElementsByClassName("vote-action")[0].style.display = "block"
                return
            }
        }

        if (resp.gameinfo.mode == "end") {
            var prompt = "游戏结束! "
            if (resp.gameinfo.round_success >= 3)
                prompt += "正方胜利"
            else
                prompt += "反方胜利"
            Ejoy("stage_prompt").html(prompt)

            self.render_players(resp.players, resp.gameinfo.stage)            
        }
    })
}

AvalonGame.fn.wait = function () {
    this.update_game(version)
}

AvalonGame.fn.leader_plan = function(resp) {
}

AvalonGame.fn.wait_leader_plan = function (resp) {
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
            if (stage_list.indexOf(user_id) == -1) {
                if (stage_list.length >= Math.abs(gameinfo.need)) {
                    return
                }
                stage_list.push(user_id);
            }
            else {
                Ejoy.array_remove(stage_list, user_id)
            }

            var status_mark = "status_0"
            if (stage_list.indexOf(user_id) == -1)
                status_mark = "status_1"
            var el = select_dom.children[0]
            el.className = el.className.replace(/status_\d/, status_mark)
            }
        }
    );

    Ejoy('stage-commit').on('click', function(){
        if (self.mode == "plan" && self.is_leader && stage_list.length == Math.abs(gameinfo.need)) {
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

    var genvote = function (flag){
        return function ()  {
            if (self.mode == "audit" || (self.mode == "quest" && self.stage.indexOf(userid) != -1)) {
                var req = {
                    roomid: room_number,
                    status: 'game',
                    action: 'vote',
                    version: version,
                    approve: flag,
                }

                Ejoy.postJSON('/room', req, function(resp){
                    console.log(resp)
                    if(!resp.error){
                        document.getElementsByClassName("vote-action")[0].style.display = "none"
                        self.wait()
                    }
                })
            }
        }
    }
    Ejoy('vote-yes').on('click', genvote(true));
    Ejoy('vote-no').on('click', genvote(false));
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
    }
}

AvalonGame.fn.render_players = function(players, stage){
    var players_str = ""
    for(var i=0; i < players.length; i++){
        var player = players[i]
        var mark = 1
        if (stage.indexOf(player.userid) > -1)
            mark = 0
        var content = player.username
        if (player.identity)
            content += "[" + player.identity + "]"
        players_str += '<div class="people_item" id="' + 
            player.userid + 
            '"><span class="status_mark status_' + 
            mark +
            '" style="color:' +
            player.color +
            '">' +
            content +
            '</span></div>';
    } 
    Ejoy('game-people').html(players_str);
}
