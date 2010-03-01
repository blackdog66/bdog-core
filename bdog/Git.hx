package bdog;

import bdog.Os;

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
        Os.process("git init");
      });
  }

  public function
  log() {
    return inRepo(function() {
        return Os.process("git log");
      });
  }
}
