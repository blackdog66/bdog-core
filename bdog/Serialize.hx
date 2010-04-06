
package bdog;

import haxe.rtti.CType;

/*
  A simple serializer that converts a class to an object, in the process
  tweaking arrays to be arrays of objects (rather than classes) and enums to be
  string constructors. 

  mid = MongoDB.ID(o);

    if (mid != null) Reflect.setField(newObj,"_id",mid);

*/

class Serialize {
  static var rttis = new Hash<haxe.rtti.TypeTree>();

  static function
  getRTTI(c:Dynamic):haxe.rtti.TypeTree {
    var
      cn = Type.getClassName(c),
      rt = rttis.get(cn);

    if (rt == null) {
      var
        rtti : String = untyped c.__rtti;      
      if (rtti == null) throw "NO RTTI! for "+cn;
      rt = new haxe.rtti.XmlParser().processElement(Xml.parse(rtti).firstElement());
      rttis.set(cn,rt);
    }
    
    return rt;
  }
  
  public static function
  classToDoc(o:Dynamic):Dynamic {
    var final:Dynamic = null;
    switch(Type.typeof(o)) {
    case TNull: final = null;
    case TClass(kls):
      var z = {};
      for (f in Type.getInstanceFields(kls)) {
        var val:Dynamic = Reflect.field(o,f);
        if (val != null && !Reflect.isFunction(val)) {
          Reflect.setField(z,f,switch(Type.typeof(val)) {
            case TInt, TBool, TFloat:
              val;
            case TClass( c ):
              var cn = Type.getClassName(c);
              if (cn == "Array") {
                var na = new Array<Dynamic>();
                for (el in cast(val,Array<Dynamic>)) {
                  na.push(classToDoc(el));
                }
                na;
              } else {
                if (cn != "String")
                  classToDoc(val);
                else
                  val;
              }
            case TEnum(_):
              Type.enumConstructor(val);          
            default:
              val;
            });
        }
      }
      final = z;
    case TEnum(e):
      final = Type.enumConstructor(o);
    default:
      if (!Reflect.isFunction(o))
        final = o;
    }
    return final;
  }

  static function
  deserClass(o,resolved:Class<Dynamic>) {
    var
      newObj = Type.createEmptyInstance(resolved);
    
    switch(getRTTI(resolved)) {
    case TClassdecl(typeInfo):
      Lambda.iter(typeInfo.fields,function(el) {
          var val = Reflect.field(o,el.name);
          classFld(newObj,el.name,val,el.type);
        });
    default:
    }
    return newObj;
  }
  
  static function
  classFld(newObj:Dynamic,name:String,val:Dynamic,el:CType){
    switch(el) {
    case CClass(kls,subtype):
      switch(kls) {
      case "String","Float","Int":

        Reflect.setField(newObj,name,val);
      
      case "Array":
        var
          na = new Array<Dynamic>(),
          st = subtype.first();
        for (i in cast(val,Array<Dynamic>)) {
          switch(st) {
          case CClass(path,_):
            na.push(deserClass(i,Type.resolveClass(path)));
          case CEnum(enumPath,_):
            var e = Type.resolveEnum(enumPath);
            na.push(Type.createEnum(e,i));
          default:
            na.push(i);
          }
        }
        
        Reflect.setField(newObj,name,na);

      default:
        Reflect.setField(newObj,name,deserClass(val,Type.resolveClass(kls)));
      }
      
    case CEnum(enumPath,_):
      var e = Type.resolveEnum(enumPath);
      Reflect.setField(newObj,name,Type.createEnum(e,val));
      
    default:
      //      trace("other deser type"+el);
    }
  }  
  
  public static function
  docToClass(o,myclass:Class<Dynamic>):Dynamic {    
    if (o == null) return null;
    return deserClass(o,myclass);
  }


}
