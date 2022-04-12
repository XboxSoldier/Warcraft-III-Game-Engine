var TICK = 0.031250000;

var Data = {
    _storage: new Map(),
    get:(fill:boolean, fallBack:any, ...args:any[])=>{
        let key:any[] = args.pop();
        let current = Data._storage;
        for (let i:number = 0; i < args.length; i++){
            if (!current.has(args[i])){
                if (fill){
                    current.set(args[i], new Map());
                }
                else {
                    return undefined;
                }
            }
            if (current.get(args[i]) instanceof Map){
                return undefined;
            }
            current = current.get(args[i]);
        }
        if (!current.has(key)){
            current.set(key, fallBack);
        }
        return current.get(key);
    },
    set:(...args:any[])=>{
        let value = args.pop();
        let key = args.pop();
        let current = Data.get(true, new Map(), ...args);
        if (current && current instanceof Map){
            current.set(key, value);
        }
    },
}

var initFuncs:Set<any> = new Set();
function init(func:Function){
    initFuncs.add(func);
}

class Timer {
    private _status:Map<string, any> = new Map();
    static array:Set<Timer> = new Set();
    static active:Set<Timer> = new Set();
    static garbageBin:Set<Timer> = new Set();
    constructor(){ Timer.array.add(this); }
    public start(duration:number, period:boolean, parameters:Map<string, any>, func:Function){
        this._status.clear();
        this._status.set("duration", duration);
        this._status.set("durationRemaining", duration);
        this._status.set("period", period);
        this._status.set("parameters", parameters);
        this._status.set("func", func);
        this._status.set("flags", new Set());
        Timer.active.add(this);
    }
    public pause(){
        Timer.active.delete(this);
    }
    public resume(){
        Timer.active.add(this);
    }
    public setFlag(flag:string){
        this._status.get("flags").add(flag);
    }
    public clearFlag(flag:string){
        this._status.get("flags").delete(flag);
    }
    public finish(){
        Timer.active.delete(this);
        Timer.garbageBin.add(this);
    }
    public tick(){
        this._status.set("durationRemaining", this._status.get("durationRemaining") - TICK);
        if (this._status.get("durationRemaining") <= 0){
            this._status.get('func')(this._status.get("parameters"), this);
            if (this._status.get("period")){
                this._status.set("durationRemaining", this._status.get("duration"));
            }
            else {
                this.pause();
            }
        }
    }
    get duration(){ return this._status.get("duration"); }
    get durationRemaining(){ return this._status.get("durationRemaining"); }
    get period(){ return this._status.get("period"); }
    get parameters(){ return this._status.get("parameters"); }
    get func(){ return this._status.get("func"); }
    get flags(){ return this._status.get("flags"); }
}