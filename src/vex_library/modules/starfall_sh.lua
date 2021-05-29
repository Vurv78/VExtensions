-- Some helpers for making Starfall modules.

local SFLib = {
    -- Register clientside permissions.
    -- 1 = Only you, 2 = Friends Only, 3 = Anyone, 4 = No one
    PermLevels = {
        OWNER = 1,
        FRIEND = 2,
        ANYONE = 3,
        NO_ONE = 4
    }
}

vex.SFLib = SFLib