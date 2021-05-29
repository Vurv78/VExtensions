
export class Cooldown {
    public global: number;
    public local: number;
    public last_used_g: number;
    public last_used: LuaTable<Player, number>;

    constructor(global: number = 0.25, local: number = 1) {
        this.global = global;
        this.local = local;
        this.last_used_g = 0;
        this.last_used = new LuaTable();
    }

    public available(ply: Player) {
        let now = CurTime();
        if ( ply != undefined && IsValid(ply) ) {
            let expected = (this.last_used.get(ply) ?? 0) + this.local;
            if (now < expected) return false;
        }
        return now > this.last_used_g + this.global;
    }

    public use(ply: Player) {
        if ( !this.available(ply) ) return false;

        let ct = CurTime();
        if ( IsValid(ply) ) {
            this.last_used.set(ply, ct);
        }
        this.last_used_g = ct;
        return true;
    }
}