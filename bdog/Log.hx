package bdog;

class Log {

	public static var logOn = true;
	public static var traceOn = false;
	static var logs:Hash<neko.io.FileOutput> = new Hash();
	static var logFile = "default";
	static var logDir ;

	public static
	function setDirFile(dir:String,lf:String) {
//		trace("making dir "+dir);
		bdog.Os.mkdir(dir);
		logDir = dir;
		logFile = lf;
	}

	public static
	function tr(s:String,?indent:Int=0) {

		var sb = new StringBuf();
		for (i in 0...indent) sb.add("\t");
		var f = sb.toString()+s;

		if (logDir != null && Os.exists(logDir)) {

			var log:neko.io.FileOutput,
				lf = logDir + "/" + logFile + ".log";

			if (!Os.exists(lf)) {
				var f = neko.io.File.write(lf,false) ;
				f.writeString("");
				f.flush();
				f.close();
			}

			if (!logs.exists(logFile)) {
				log = neko.io.File.append(lf,false);
				logs.set(logFile,log);
			} else
				log = logs.get(logFile);

			log.writeString(f+"\n");
		} else {
			//if (traceOn)
			neko.Lib.println(f);
		}
	}

	public static
	function print(msg:String,level=1) {
      if (msg == null) return;
      
      var m = switch(level) {
      case 0:
      msg;
      case 1:
      "["+msg+"]";
      case 2:
      "[["+msg+"]]";
      case 3:
      "[[["+msg+"]]]";
      }
      
      if (msg.length>0)
        neko.Lib.println(m);
	}

}
