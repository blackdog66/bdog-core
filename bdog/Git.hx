package bdog;

import bdog.Os;
import bdog.Tokenizer;
import bdog.Reader;

enum TLog {
  TCommit(id:String);
  TAuthor(a:String);
  TDate(d:String);
  TComment(c:String);
}

typedef LogEntry = {
  var commit:String;
  var author:String;
  var date:String;
  var comment:String;
}
  
class Git {

  public var dir(default,null):String;
  
  public function new(d:String) {
    dir = Os.slash(d);
    if (!Os.exists(dir))
      Os.mkdir(dir);
    
    if (!Os.exists(dir+".git")) {
      init();
    }
  }

  public function
  inRepo(f:Void->Dynamic) {
    Os.cd(dir);
    var o = f();
    Os.cdpop();
    return o;
  }

  public function
  commit(comment:String) {
    inRepo(function() {
        Os.process('git add .');
        Os.process('git commit -m "'+comment+'"');
      });
  }
  
  public function
  tag(name:String) {
    inRepo(function() {
        Os.process('git tag '+name);
      });
  }

  public function
  init() {
    inRepo(function() {        
        return Os.process("git init");
      });
  }

  static function
  parseLog(l:String) {
    var tk = new Tokenizer<TLog>(new StringReader(l));
    tk.match(~/^commit\s(.*?)\n/,function(re) { return TCommit(re.matched(1)); })
      .match(~/^Author:(.*?)\n/,function(re) {return TAuthor(re.matched(1)); })
      .match(~/^Date:(.*?)\n/,function(re) {return TDate(re.matched(1)); })
      .match(~/^\n(.*?)\n\n/s,function(re) {return TComment(re.matched(1)); });
    var
      state:Int = 0,
      a:Array<LogEntry> = new Array(),
      tok:TLog,
      tmp:LogEntry = { commit:null, author:null, date: null, comment:null };
    
    while((tok = tk.nextToken()) != null) {
      switch (tok) {
      case TCommit(c): tmp.commit = StringTools.trim(c);
      case TAuthor(a):tmp.author = StringTools.trim(a);
      case TDate(d):tmp.date = StringTools.trim(d);
      case TComment(c): tmp.comment = StringTools.trim(c);
      }
      state++;
      if (state == 4) {
        a.push(tmp);
        tmp = { commit:null, author:null, date: null, comment:null };
        state = 0;
      }
    }
    return a;
  }
  
  public function
  log():Array<LogEntry> {
    return inRepo(function() {
        return parseLog(Os.process("git log"));
      });
  }

  public function
  archive(name:String,commit:String,outputDir:String) {
    return inRepo(function() {
        var n = Os.slash(outputDir)+name+"-"+commit+".zip";
        return Os.process("git archive --format=zip --output "+n+" "+commit);
      });
  }
}
