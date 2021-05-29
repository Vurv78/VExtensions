export const net_prefix = "vex_netmsg";

export function start(name: string, unreliable: boolean = false) {
    net.Start(`${net_prefix}${name}`, unreliable);
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