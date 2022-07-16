AddCSLuaFile()

g64sprites = {}

g64sprites.Dimensions = {
    UI = { 256, 16 },
    Health = { 1024, 64 }
}
g64sprites.UI = {
    tex_width = g64sprites.Dimensions.UI[1],
    tex_height = g64sprites.Dimensions.UI[2],
    num_0 = {
        w = 16,
        h = 16,
        u = 16/g64sprites.Dimensions.UI[1]*0,
        v = 16/g64sprites.Dimensions.UI[2]*0,
    },
    num_1 = {
        w = 16,
        h = 16,
        u = 16/g64sprites.Dimensions.UI[1]*1,
        v = 16/g64sprites.Dimensions.UI[2]*0,
    },
    num_2 = {
        w = 16,
        h = 16,
        u = 16/g64sprites.Dimensions.UI[1]*2,
        v = 16/g64sprites.Dimensions.UI[2]*0,
    },
    num_3 = {
        w = 16,
        h = 16,
        u = 16/g64sprites.Dimensions.UI[1]*3,
        v = 16/g64sprites.Dimensions.UI[2]*0,
    },
    num_4 = {
        w = 16,
        h = 16,
        u = 16/g64sprites.Dimensions.UI[1]*4,
        v = 16/g64sprites.Dimensions.UI[2]*0,
    },
    num_5 = {
        w = 16,
        h = 16,
        u = 16/g64sprites.Dimensions.UI[1]*5,
        v = 16/g64sprites.Dimensions.UI[2]*0,
    },
    num_6 = {
        w = 16,
        h = 16,
        u = 16/g64sprites.Dimensions.UI[1]*6,
        v = 16/g64sprites.Dimensions.UI[2]*0,
    },
    num_7 = {
        w = 16,
        h = 16,
        u = 16/g64sprites.Dimensions.UI[1]*7,
        v = 16/g64sprites.Dimensions.UI[2]*0,
    },
    num_8 = {
        w = 16,
        h = 16,
        u = 16/g64sprites.Dimensions.UI[1]*8,
        v = 16/g64sprites.Dimensions.UI[2]*0,
    },
    num_9 = {
        w = 16,
        h = 16,
        u = 16/g64sprites.Dimensions.UI[1]*9,
        v = 16/g64sprites.Dimensions.UI[2]*0,
    },
    times = {
        w = 16,
        h = 16,
        u = 16/g64sprites.Dimensions.UI[1]*10,
        v = 16/g64sprites.Dimensions.UI[2]*0,
    },
    coin = {
        w = 16,
        h = 16,
        u = 16/g64sprites.Dimensions.UI[1]*11,
        v = 16/g64sprites.Dimensions.UI[2]*0,
    },
    mario_head = {
        w = 16,
        h = 16,
        u = 16/g64sprites.Dimensions.UI[1]*12,
        v = 16/g64sprites.Dimensions.UI[2]*0,
    },
    star = {
        w = 16,
        h = 16,
        u = 16/g64sprites.Dimensions.UI[1]*13,
        v = 16/g64sprites.Dimensions.UI[2]*0,
    }
}

g64sprites.Health = {
    tex_width = g64sprites.Dimensions.Health[1],
    tex_height = g64sprites.Dimensions.Health[2],
    bg_0 = {
        w = 32,
        h = 64,
        u = 64/g64sprites.Dimensions.Health[1]*0,
        v = 64/g64sprites.Dimensions.Health[2]*0,
    },
    bg_1 = {
        w = 32,
        h = 64,
        u = 64/g64sprites.Dimensions.Health[1]*1,
        v = 64/g64sprites.Dimensions.Health[2]*0,
    },
    wedge_8 = {
        w = 32,
        h = 64,
        u = 64/g64sprites.Dimensions.Health[1]*2,
        v = 64/g64sprites.Dimensions.Health[2]*0,
    },
    wedge_7 = {
        w = 32,
        h = 64,
        u = 64/g64sprites.Dimensions.Health[1]*3,
        v = 64/g64sprites.Dimensions.Health[2]*0,
    },
    wedge_6 = {
        w = 32,
        h = 64,
        u = 64/g64sprites.Dimensions.Health[1]*4,
        v = 64/g64sprites.Dimensions.Health[2]*0,
    },
    wedge_5 = {
        w = 32,
        h = 64,
        u = 64/g64sprites.Dimensions.Health[1]*5,
        v = 64/g64sprites.Dimensions.Health[2]*0,
    },
    wedge_4 = {
        w = 32,
        h = 64,
        u = 64/g64sprites.Dimensions.Health[1]*6,
        v = 64/g64sprites.Dimensions.Health[2]*0,
    },
    wedge_3 = {
        w = 32,
        h = 64,
        u = 64/g64sprites.Dimensions.Health[1]*7,
        v = 64/g64sprites.Dimensions.Health[2]*0,
    },
    wedge_2 = {
        w = 32,
        h = 64,
        u = 64/g64sprites.Dimensions.Health[1]*8,
        v = 64/g64sprites.Dimensions.Health[2]*0,
    },
    wedge_1 = {
        w = 32,
        h = 64,
        u = 64/g64sprites.Dimensions.Health[1]*9,
        v = 64/g64sprites.Dimensions.Health[2]*0,
    },
    one_up = {
        w = 32,
        h = 64,
        u = 64/g64sprites.Dimensions.Health[1]*10,
        v = 64/g64sprites.Dimensions.Health[2]*0,
    },
}

g64sprites.Characters = {
    ["0"] = g64sprites.UI.num_0,
    ["1"] = g64sprites.UI.num_1,
    ["2"] = g64sprites.UI.num_2,
    ["3"] = g64sprites.UI.num_3,
    ["4"] = g64sprites.UI.num_4,
    ["5"] = g64sprites.UI.num_5,
    ["6"] = g64sprites.UI.num_6,
    ["7"] = g64sprites.UI.num_7,
    ["8"] = g64sprites.UI.num_8,
    ["9"] = g64sprites.UI.num_9
}