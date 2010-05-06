
package bdog;

class SeqRand {
  // First, all platform functions ...
  
  // Sequence tools ...
  
  public static function
  take<T>(it : Iterable<T>,num:Int) : List<T> {
    var l = new List<T>(),
      c = 0;
    for(i in it) {
      l.add(i);
      if (c++ == num-1) break;
    }
    return l;
  }  
  
  public static function
  groupBy(fld:String,recs:List<Dynamic>) {
    var h = new Hash<List<Dynamic>>(),
      l:List<Dynamic>;

    for (r in recs) {
      var f = Std.string(Reflect.field(r,fld)),
        l = h.get(f);
      if (l == null) {
        l = new List<Dynamic>();
        l.add(r);
        h.set(f,l);
      } else {
        l.add(r);
      }
    }
    return h;
  }

  // Array Tools ...
  
  public static
  function makeArray(len:Int,?to:Int=0) {
    var a = new Array<Int>();
    for (i in 0...len)
      a.push(to);
    return a;
  }

  public static
  function initRange(len:Int) {
    var a = new Array<Int>();
    for (i in 0...len)
      a.push(i);
    return a;
  }

  public static
  function binarySearch(c:Array<Int>,o:Int):Int {
    var lo = 0,
      hi = c.length - 1,
      mid;
    
    while(lo <= hi) {
      mid = Math.floor((lo + hi) / 2);
      if(o < c[mid]) hi = mid - 1;
      else if(o > c[mid]) lo = mid + 1;
      else return mid;
    }
    return -1;
  }

  // Random Tools ...

  public static function
  shuffle<T>(a:Array<T>):Array<T> {
    var f = new Array<T>(),
      c = a.copy(),
      l = a.length;
    
    while (l > 0) {
      var ri = Std.random(l);
      f.push(c[ri]);
      c.splice(ri,1);
      l--;
    }
    return f;
  }

  public static function
  uniqueInt(size:Int) {
    return new IntRandomiser(size);
  }

  public static function
  uniqueArray<T>(a:Array<T>) {
    return new ArrayRandomiser(a);
  }
}

private class IntRandomiser  {
    var sample:Array<Int>;

    public function
    new(size:Int) {
      sample = SeqRand.shuffle(SeqRand.initRange(size));
    }
  
    public function
    hasNext() { return sample.length > 0 ; }
  
    public function
    next() { return sample.shift() ;}

    public function
    iterator():Iterator<Int> { return this; }
  }

  private class ArrayRandomiser<T> {
    var sample:Array<T>;

    public function new(a:Array<T>) {
      sample = SeqRand.shuffle(a);
    }
  
    public function
    hasNext() { return sample.length > 0 ; }

    public function
    next() { return sample.shift() ;}

    public function
    iterator():Iterator<T> { return this; }
  }
