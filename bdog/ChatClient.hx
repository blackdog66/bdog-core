
package bdog;

import bdog.JSON;
import bdog.Http;
import bdog.Event;

/* this is the chat controller fires events to the UI whatever it is */

typedef Msg = {
  var nick:String;
  var type:String;
  var text:String;
  var timestamp:Float;
}

class ChatClient {

  var path:String;
  var channel:String;
  var sessionID:String;
  var lastMessageTime:Float;
  var pollingErrors:Int;

  public var events: {
  		join:Event<Msg>,
      	who:Event<Array<String>>,
      	msg:Event<Msg>,
      part:Event<Msg>,
      pollErr:Event0
  };
  
  public function new(host:String,port:Int) {
    path = "http://"+host+":"+port +"/chat/";
    lastMessageTime = 1;
    events = {
    	join:new Event<Msg>(),
        who:new Event<Array<String>>(),
        msg:new Event<Msg>(),
        part:new Event<Msg>(),
        pollErr:new Event0()
    };
  }

  function error(o:Dynamic) {
    var err = Reflect.field(o,"error");
    if (err != null) {
      trace("ERROR:"+err);
      return null;
    }

    return o;
  }

  function client(command:String,params:Dynamic,fn:Dynamic->Void) {
    var
      me = this,
      errHandler = null;

    if (command == "recv")
      errHandler = function(s) {
        me.pollingErrors++;
        if (me.pollingErrors < 5)
          me.poll();
        else
          me.events.pollErr.raise();
      };
    
    Http.get(path+command,params,function(json) {
        var o = JSON.decode(json);
        if (fn != null && me.error(o) != null)
          fn(o);
      },errHandler);
  }

  function params(?p:Dynamic) {
    if (p == null) p = {};
    Reflect.setField(p,"channel",channel);
    if (sessionID != null) {
      Reflect.setField(p,"id",sessionID);
    }
    return p;
  }
  
  public function
  join(chan:String,nick:String,fn:{id:String}->Void) {
    var me = this;
    channel = chan;
    client("join",params({nick:nick}),function(o) {
        me.sessionID = Reflect.field(o,"id");
        fn(o);
      });
  }
  
  public function
  send(text:String) {
    client("send",params({text:text}),null);
  }

  public function
  recv(prms:Dynamic,fn:Dynamic->Void) {
    client("recv",params(prms),fn);
  }

  public function
  who(fn:{nicks:Array<String>}->Void) {
    client("who",params(),fn);
  }

  public function
  part() {
    client("part",params(),null);
  }
  
  public function
  poll() {
    var
      me = this;
    
    recv({since:lastMessageTime},function(data:Dynamic) {
        if (data != null) {
          me.handlePoll(data);
        }
      });
  }

  public function
  handlePoll(data:Dynamic) {
    pollingErrors = 0;
    var messages:Array<Msg> = data.messages;
    for (m in messages) {
      lastMessageTime = Math.max(lastMessageTime,m.timestamp);
      switch(m.type) {
      case "join": events.join.raise(m);
      case "msg": events.msg.raise(m);
      }
    }
    poll();
  }

  
}
