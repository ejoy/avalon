var AvalonGame = function(){
    this.status = "game";
    this.mission = 1; // 第几个任务, 总共5轮，也就最多5个任务
    this.plan = 1; // 第几个提案
    this.stage = ['plan', 'vote', 'quest', 'ending']
    this.rules = {
        5: [2, 3, 2, 3, 3],
        6: [2, 3, 4, 3, 4],
        7: [2, 3, 3, 4, 4],
        8: [3, 4, 4, 5, 5],
    }
}

AvalonGame.fn = AvalonGame.prototype = {constructor: AvalonGame};

AvalonGame.fn.begin = function(){
    this.render_role_info()    
    //this.set_game_content(0, true)
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

AvalonGame.fn.game_bind_action = function(){
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

    var plan_list = [] 
    Ejoy("game-people").on("click", "people_item", function(select_dom){
        var user_id = select_dom.id;
        if(true){
            select_dom.className ="selected"
            plan_list.push(user_id);
        }else{
            Ejoy.array_remove(plan_list, user_id)
        }

    });

    Ejoy('plan-button').on('click', function(){
        var req = {
            roomid: room_number,
            status: 'game',
            action: 'plan',
            version: version,
            list: plan_list,
        }

        Ejoy.postJSON('/room', req, function(resp){
            console.log(resp)
            if(!resp.error){
                // 进入投票阶段
            }
        })
    });

    Ejoy('plan-cancel').on('click', function(){
        plan_list = [] 
        // 取消选中的样式
    })
}

AvalonGame.fn.render_role_info = function(){
    var self = this;
    var req = {
        roomid: room_number,
        status: 'game',
        action: 'list',
        version: version
    };
    Ejoy.postJSON('/room', req, function(resp) {
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
           self.render_players(resp.player)
           self.game_bind_action()
       }
    });
}

AvalonGame.fn.render_players = function(players){
    
}

