// 简单的selector + manipulation  + evnet bind 类似jquery 的 链式写法
// ajax

var Ejoy = function(selector){
  return new Ejoy.fn.init(selector);
}

Ejoy.array_remove = function(array, target){
    var index = array.indexOf(target);
    if (index > -1) {
        array.splice(index, 1);
    }
}

Ejoy.url_params = function(dict){
  var str = ""
  for( k in dict){
    str += k + "=" + dict[k] + "&"; 
  }
  return str.slice(0, -1)
}
Ejoy.postJSON = function(url, req, callback){
    var xmlhttp = new XMLHttpRequest();   // new HttpRequest instance 
    xmlhttp.open("POST", url);
    //xmlhttp.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
    xmlhttp.onreadystatechange = function() {
       if (xmlhttp.readyState == 4) {
           try{
               var data = JSON.parse(xmlhttp.responseText)
           }
           catch(e){
               return console.log(e)
           }
           callback(data)
       }
    }
    xmlhttp.send(JSON.stringify(req));
    //xmlhttp.send(Ejoy.url_params(req));

}

Ejoy.getCookie = function(sKey){
    if (!sKey) { return null; }
    return decodeURIComponent(
        document.cookie.replace(new RegExp("(?:(?:^|.*;)\\s*" + encodeURIComponent(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=\\s*([^;]*).*$)|^.*$"), "$1")
    ) || null;
} 

Ejoy.fn = Ejoy.prototype = {constructor: Ejoy};


var init = Ejoy.fn.init = function(selector){
 this.dom = document.getElementsByClassName(selector)  
 this.len = this.dom.length
 this.selector = selector
}

init.prototype = Ejoy.fn;


Ejoy.fn.html = function(val){
  for(var i = 0; i< this.len; i++){
    this.dom[i].innerHTML = val
  }
  return this
};

Ejoy.fn.css = function(css){
  for(var i = 0; i< this.len; i++){
    this.dom[i].style.cssText = css
  }
  return this

}

Ejoy.fn.on = function(event, selector, data, fn){
  var self = this;
  if ( data == null && fn == null ) {
    // ( types, fn )
    fn = selector;
    data = selector = undefined;
  } else if ( fn == null ) {
    if ( typeof selector === "string" ) {
      // ( types, selector, fn )
      fn = data;
      data = undefined;
    } else {
      // ( types, data, fn )
      fn = data;
      data = selector;
      selector = undefined;
    }
  }
  for(var i = 0; i < this.len; i++){
    var dom = this.dom[i]
    dom.addEventListener(event, function(e) {
      if(selector){
        var select_dom = filter_selector(selector, e.target, dom)
        if(select_dom){
          e.preventDefault();
          fn(select_dom, data)
        }
      }else{
          e.preventDefault();
          fn(e, data)
      }
    });
  }
  return this
};

function filter_selector(selector, dom, end){
    if(dom.className.indexOf(selector) > -1){
        return dom;
    }else if(dom == end){
        return false
    }else if(dom.parentElement == end){
        return false;
    }else{
       return filter_selector(selector, dom.parentElement, end) 
    }
    
}
