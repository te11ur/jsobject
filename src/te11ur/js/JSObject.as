package te11ur.js
{
    import flash.external.ExternalInterface;
    import flash.utils.Proxy;
    import flash.utils.flash_proxy;

    use namespace flash_proxy;

    public dynamic class JSObject extends Proxy
    {
        private static var inited:Boolean = false;
        private static var c:int = 0;
        private static var instanse:Object = {};
        private static var windowInstanse:JSObject;

        private var index:uint;

        public function JSObject(i:uint)
        {
            if(!(i in instanse)) {
                throw new Error("No instanse");
            }
            index = i;
        }

        public static function get window():JSObject
        {
            if(windowInstanse) {
                return windowInstanse;
            }

            if(!inited) {
                if(!init()) {
                    throw new Error("Can`t init js instanse");
                }
            }

            windowInstanse = instanse[ExternalInterface.call('(function() {' +
                    '   var flashjs = window.flashjs;' +
                    '   return flashjs.createInstanse(window);' +
                    '})')];
            return windowInstanse;
        }

        private static function createInstanse():uint
        {
            var index:uint = (++c);
            instanse[index] = null;
            instanse[index] = new JSObject(index);
            return index;
        }

        private static function removeInstanse(index:uint):Boolean
        {
            if(index in instanse) {
                //todo: remove jsobject
                delete instanse[index];
                return true;
            }
            return false;
        }

        private static function init():Boolean
        {
            if (ExternalInterface.available) {
                ExternalInterface.addCallback('flashjscreate', createInstanse);
                ExternalInterface.addCallback('flashjsremove', removeInstanse);
                inited = ExternalInterface.call('(function(objectID) { ' +
                        '   var that = window.flashjs = arguments.callee;' +
                        '   that.id = objectID;' +
                        '   that.client = document.getElementById(objectID);' +
                        '   that.instanse = {};' +
                        '   that.createInstanse = function(subject) {' +
                        '       var index = that.client.flashjscreate();' +
                        '       that.instanse[index] = subject;' +
                        '       return index;' +
                        '   };' +
                        '   that.removeInstanse = function(index) {' +
                        '       if(index in that.instanse) {' +
                        '           if(that.client.flashjsremove(index)) {' +
                        '               delete that.instanse[index];' +
                        '               return true;' +
                        '           }' +
                        '       }' +
                        '       return false;' +
                        '   };' +
                        '   return !!that.client;' +
                        '})', ExternalInterface.objectID
                );
            }
            return inited;
        }

        flash_proxy override function getProperty(name:*):*
        {
            var newIndex:uint = ExternalInterface.call('(function(index, name, undefined) {' +
                    '   var flashjs = window.flashjs;' +
                    '   var ins = flashjs.instanse[index];' +
                    '   return flashjs.createInstanse(ins ? (name in ins ? ins[name] : undefined): undefined);' +
                    '})', index, String(name));
            return instanse[newIndex];
        }

        flash_proxy override function callProperty(name:*, ... rest):*
        {
            var params:Array = rest.slice();
            params.unshift('(function(index, name) {' +
                    '   var args = Array.prototype.slice.call(arguments, 2);' +
                    '   var flashjs = window.flashjs;' +
                    '   var ins = flashjs.instanse[index];' +
                    '   if(ins && name in ins && typeof ins[name] == "function") {' +
                    '       return flashjs.createInstanse(ins[name].apply(ins, args));' +
                    '   }' +
                    '   return flashjs.createInstanse(undefined);;' +
                    '})', index, String(name));

            var newIndex:int = ExternalInterface.call.apply(this, params);
            return instanse[newIndex];
        }

        public function get data():*
        {
            var typeOf:String = ExternalInterface.call('(function(index, undefined) {' +
                    '   return typeof window.flashjs.instanse[index];' +
                    '})', index);

            switch(typeOf) {
                case "number":
                case "boolean":
                case "string":
                    return ExternalInterface.call('(function(index) {return window.flashjs.instanse[index];})', index);
            }
            return this;
        }
    }
}
