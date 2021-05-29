// Typescript bindings for an E2 Chip.

declare interface Context {
    entity: Entity,
    prfbench: number,
    prfcount: number,
    timebench: number,
    player: Player,
    data: any,
}

// WHY??? TYPESCRIPT...???
// You can easily infer that we're using the type 'Entity' and NOT the function Entity above, so why not here?????
// Ugh....
class E2Chip extends Entity {
    constructor(...args: any[]) {
        super(args)
    }
}