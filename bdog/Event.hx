package bdog;

/*
 * public function remove(h : T -> Void) : T -> Void {
		for(i in 0...handlers.length)
			if(Reflect.compareMethods(handlers[i], h))
				return handlers.splice(i, 1)[0];
		return null;
	}
	*/

class Event<T> {
	var handlers:Array<T->Void>;

	public function new() {
		handlers = [];
	}

	public function addHandler(fn:T->Void) {
		handlers.push(fn);
	}

	public function raise(p:T) {
		for (h in handlers) {
			try {
				h(p);
			} catch(e:Dynamic) {
				trace("error raising event "+e);
			}
		}
	}
}

class Event0 {
	var handlers:Array<Void->Void>;

	public function new() {
		handlers = [];
	}

	public function addHandler(fn:Void->Void) {
		handlers.push(fn);
	}

	public function raise() {
		for (h in handlers) {
			try {
				h();
			} catch(e:Dynamic) {
				trace("error raising event "+e);
			}
		}
	}
}
