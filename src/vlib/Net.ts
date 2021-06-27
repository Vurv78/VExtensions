export const net_prefix = "vex_netmsg";

function mangle(name: string): string {
    return `${net_prefix}${name}`;
}

export function start(name: string, unreliable: boolean = false) {
    net.Start( mangle(name), unreliable );
}

export function send(target?: Player) {
    if (CLIENT) {
        net.SendToServer();
    } else {
        if (target != undefined) net.Send(target);
    }
}

export function addNetString(name: string) {
    util.AddNetworkString(name);
}

export function receive(name: string, callback: Function) {
    net.Receive( mangle(name), callback );
}