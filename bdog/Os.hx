
package bdog;

#if php
import php.Sys;
import php.FileSystem;
import php.io.File;
import php.io.Path;
import php.Lib;
import php.io.Process;
#elseif neko
import neko.Sys;
import neko.FileSystem;
import neko.io.File;
import neko.io.Process;
import neko.io.Path;
import neko.Lib;
import neko.zip.Reader;
#elseif nodejs
import bdog.nodejs.Node;
#end

using StringTools;

enum Answer {
  Yes;
  No;
  Always;
}

enum PathPart {
  EXT;
  NAME;
  FILE;
  DIR;
  PARENT;
}

class Os {

  public static var separator:String;
  static var mycwd:Array<String> = new Array();
  
  public static function __init__() {
	#if (neko || php)
    separator = (Sys.systemName() == "Windows" ) ? "\\" : "/";
    #else
    separator = "\\";
    #end
  }

  public static function
  textToArray(text:String,delimiter='\n'):Array<String> {
    var ar = text.split(delimiter),
      lastEl = ar.pop();
    if (StringTools.trim(lastEl) == "")
      return ar;
    ar.push(lastEl) ;
    return ar;
  }

  public static inline function
  slash(d:String) {
    return StringTools.endsWith(d,separator) ? d : (d + separator) ;
  }
  
  public static inline function
  print(s:String) {
#if (neko || php)
    Lib.print(s);
#elseif nodejs
    Node.sys.puts(s);
#end
  }

  public static inline function
  println(s:String) {
#if (neko || php)
    Lib.println(s);
#elseif nodejs
    Node.sys.puts(s);
#end
  }

  
  #if neko

  public static function
  env(n:String) {
    return neko.Sys.getEnv(n);
  }
  
  #end

  
  public static function
  exit(c:Int) {
#if neko
    neko.Sys.exit(c);
#elseif nodejs
    Node.process.exit(c);
#end
  }

#if (neko || php)

  public static
  function args(p:Int):String {
    return Sys.args()[p];
  }
  
  public static function
  safeDir( dir ) {
    if( FileSystem.exists(dir) ) {
     if( !FileSystem.isDirectory(dir) )
        throw ("A file is preventing "+dir+" to be created");
      return false;
    }
    try {
      FileSystem.createDirectory(dir);
    } catch( e : Dynamic ) {
      throw "You don't have enough user rights to create the directory "+dir;
    }
    return true;
  }

  public static function
  newer(src:String,dst:String) {
    if (!exists(dst)) return true;
    var s = FileSystem.stat(src),
      d = FileSystem.stat(dst);
    return (s.mtime.getTime() > d.mtime.getTime()) ;
  }
  
  public static function
  mkdir(path:String) {
    if (FileSystem.exists(path)) return;

    #if php
    untyped __php__('@mkdir($path, 0777,true);');
    #else
    
    var p = path.split(separator);
    var cur = p.splice(0,2),
      mydir = null;
    try	{
      while(true) {
        mydir = cur.join(separator) + separator;
        if (!FileSystem.exists(mydir))
          FileSystem.createDirectory(mydir);
        if (p.length == 0) break;
        cur.push(p.shift());
      }
    } catch(exc:Dynamic) {
      trace(exc);
      trace("MKDIR: problem with:"+mydir);
    }
    #end
  }

  public static function
  rm(f:String) {
    FileSystem.deleteFile(f);
  } 

  public static function
  cp(src,dst,ifNewer=false) {
    if (ifNewer && ! newer(src,dst)) return;
    File.copy(src,dst) ;
  }
  
  public static function
  rmdir(dir) {
    for( p in FileSystem.readDirectory(dir) ) {
      var path = slash(dir)+p;
      if( FileSystem.isDirectory(path) )
        rmdir(path);
      else
        Os.rm(path);
    }
    FileSystem.deleteDirectory(dir);
  }

  public static inline function
  mv(file:String,dst:String) {
    try {
    FileSystem.rename(file,dst);
    } catch(ex:Dynamic) {
      trace("error copying "+file+" to "+dst);
      throw ex;
    }
  }
  
  public static function
  fileOut(file:String,s:String,?ctx:Dynamic) {
    var f = File.write(file,false) ;
    try {
      f.writeString((ctx != null) ? template(s,ctx) : s);
      f.flush();
    } catch(exc:Dynamic) {
      f.close();
      throw exc;
    }
  }

  public static function
  fileAppend(file:String,s:String,?ctx:Dynamic) {
    var f = File.append(file,false) ;
    try {
      f.writeString((ctx != null) ? template(s,ctx) : s);
      f.flush();
    } catch(exc:Dynamic) {
      f.close();
      throw exc;
    }
  }

  public static function
  fileIn(file:String,?ctx:Dynamic) {
    var contents ;
    contents = File.getContent(file);
    return (ctx != null)
      ? template(contents,ctx)
      : contents;
  }
  
  public static function
  template(s:String,ctx:Dynamic) {
    var tmpl = new haxe.Template(s) ;
    return tmpl.execute(ctx);
  }

  public static function
  command(command:String,?ctx:Dynamic) {
    var a = getShellParameters(command,ctx);
    return Sys.command(a.shift(),a);
  }

  public static function
  path(dir:String,part:PathPart) {
    var p = new Path(dir);
    return switch(part) {
    case EXT: p.ext;
    case NAME: p.file;
    case DIR: p.dir;
    case FILE: p.file + "." + p.ext;
    case PARENT: Os.path(p.dir,DIR);
    }
  }
  
  public static function
  cd(path:String) {
    mycwd.push(Sys.getCwd()) ;
    Sys.setCwd(path);
  }

  public static inline function
  cwd() {
    return Sys.getCwd();
  }

  public static function
  cdpop() {
    var d = mycwd.pop();
    try {
      Sys.setCwd(d);
      //Log.tr("cdpop: "+d);
    } catch(exc:Dynamic) {
      trace("cdpop:"+exc);
    }
    return d;
  }
  
  public static inline function
  exists(f:String) {
    return FileSystem.exists(f);
  }

  public static inline function
  dir(d:String) {
    return FileSystem.readDirectory(d);
  }

  public static function
  isDir(d:String) {
    if (!exists(d)) return false;
    return FileSystem.isDirectory(d);
  }
  
  private static function
  readTree(dir:String,files:List<String>,?exclude:String->Bool) {
    var dirContent = null;
    
    try {
     dirContent = FileSystem.readDirectory(dir);
    }catch(ex:Dynamic) {
      trace("Exception reading directory "+dir);
    }
    
    if (dirContent == null) new List() ;
      
    for (f in dirContent) {
      if (exclude != null) {
        if (exclude(f)) {
          #if debug
          trace("excluding:"+slash(dir)+f);
          #end
          continue;
        }
      }
      var d = slash(dir) + f;
      try {
        if (FileSystem.isDirectory(d))
          readTree(d,files,exclude);
        else
          files.push(d);
      } catch(e:Dynamic) {
        // it's probably a link, isDirectory throws on a link
        //files.push(d);
        #if debug
        trace("ok got a link "+d);
        #end
        readTree(d,files,exclude);
      }
    }
    return files;
  }

  public static function
  files(dir:String,?exclude:String->Bool) {
    return readTree(dir,new List<String>(),exclude);
  }
  
  public static function
  copyTree(src:String,dst:String,?exclude:String->Bool):Void {    
    var stemLen = StringTools.endsWith(src,separator) ? src.length 
      :Path.directory(src).length,                    
      files = Os.files(src,exclude);
    
    Lambda.iter(files,function(f) {
        var
          dFile = Path.withoutDirectory(f),
          dDir = dst + Path.directory(f.substr(stemLen));
        Os.mkdir(dDir);
        File.copy(f,slash(dDir) +dFile) ;        
      });
  }

  #if neko
  public static function
  zip(fn:String,files:List<String>,root:String) {
    var
      zf = neko.io.File.write(fn,true),
      rootLen = root.length;

    try {
      var fl = new List<{fileTime : Date, fileName : String, data : haxe.io.Bytes}>();
      for (f in files) {
        if (f == "." || f == "..") continue;
        var dt = FileSystem.stat(f);
        fl.push({fileTime:dt.mtime,fileName:f.substr(rootLen),data:neko.io.File.getBytes(f)});
      }
      neko.zip.Writer.writeZip(zf,fl,1);
    } catch(exc:Dynamic) {
      trace("zip: problem "+exc) ;
    }
    zf.close();
  }

  public static function
  readFromZip( zip : List<ZipEntry>, file:String ) {
    for( entry in zip ) {
      if(entry.fileName == file) {
        return Reader.unzip(entry).toString();
      }
    }
    return null;
  }

  public static function
  unzip(zip:List<ZipEntry>,destination:String) {
    for( zipfile in zip ) {
      var n = zipfile.fileName;
      if( n.charAt(0) == separator || n.charAt(0) == "\\" || n.split("..").length > 1 )
        throw "Invalid filename : "+n;
      var
        dirs = ~/[\/\\]/g.split(n),
        path = "",
        file = dirs.pop();

      for( d in dirs ) {
        path += d;
        Os.safeDir(destination+path);
        path += separator;
      }

      if( file == "" ) {
        if( path != "" ) println("  Created "+path);
        continue; // was just a directory
      }

      path += file;
      println("  Install "+path);
      var data = neko.zip.Reader.unzip(zipfile);
      var f = neko.io.File.write(destination+path,true);
      f.write(data);
      f.close();
    }
  }
  
  /* http multipart upload */
  public static function
  filePost(filePath:String,dstUrl:String,binary:Bool,
		params:Dynamic,fn:String->Void) {

    if (!neko.FileSystem.exists(filePath))
      throw "file not found";
    
    trace("filePost: "+filePath+" to "+dstUrl);
    var req = new haxe.Http(dstUrl);
    
    var path = new neko.io.Path(filePath);
    var stat = neko.FileSystem.stat(filePath);
    req.fileTransfert("file",path.file+"."+path.ext,
                      neko.io.File.read(filePath,binary),stat.size);
    
    if (params != null) {
      var prms = Reflect.fields(params) ;
      for (p in prms)
        req.setParameter(p,Reflect.field(params,p));
    }
    
    req.onData = function(j:String) {
      if (fn != null)
        fn(j);
      else trace(j);
    }
    
    req.request(true);
  }

  public static function
  ask( question,always=false ) {
    while( true ) {
      if(always)
        Os.print(question+" [y/n/a] ? ");
      else
        Os.print(question+" [y/n] ? ");

      var a = switch( neko.io.File.stdin().readLine() ) {
      case "n":  No;
      case "y":  Yes;
      case "a":  Always;
      }

      if (a == Always && !always) continue;
      if (a == Yes || a == No || a == Always) return a;
     
    }
    return null;
  }
  
  #end

  public static function
  process(command:String,throwOnError=true,?ctx:Dynamic):String {
    var a = getShellParameters(command,ctx);
    #if debug
    trace(a);
    #end
    var p = new Process(a.shift(),a);
    if( p.exitCode() != 0) {
      if (throwOnError)
        throw p.stderr.readAll().toString();
      else
        return p.stderr.readAll().toString();
    }
    
    return StringTools.trim(p.stdout.readAll().toString());
  }

  
  public static function
  log(msg) {
    var f = "haxed.log";
    if (!Os.exists(f)) Os.fileOut(f,"date:"+Date.now().toString());
    Os.fileAppend(f,msg+"\n");
  }

  static function
  replaceQuotedSpace(s:String) {
    var sb = new StringBuf(),
      inString = false;
    for (i in 0...s.length) {
      var ch = s.charAt(i);
      if (ch == '"') inString = ! inString;
      if (inString && ch == ' ')
        sb.add('^^^');
      else
        sb.add(ch);
    }
    if (inString) throw "convertQuote: irregular number of quotes";
    return sb.toString();
  }

  static function
  getShellParameters(command:String,?ctx:Dynamic) {
    command = (ctx != null) ? template(command,ctx) : command;
    command = replaceQuotedSpace(command.trim());
    // make sure there's only one space between all items
    var r = ~/\s+/g;
    command = r.replace(command," ") ;
    
    var a = new Array<String>();
    for (i in command.split(" ")) {
      var s = StringTools.trim(i);
      if (s.charAt(0) == '"' && s.charAt(s.length-1) == '"') {
        s = StringTools.replace(s,'^^^',' ');
        a.push(s.substr(1,s.length-2));
      } else
        a.push(s);
      
    }
        
    return a;
  }
  #end
   
}