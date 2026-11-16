import crafttweaker.item.IItemStack;

// Hall of Fame armor stand callstones, each paired with the block from the notes in
// SKTweaks/Hall_Of_Fame.zs. Where a note names no block in this pack, the closest fit is used.
val callstones as IItemStack[][] = [
    [<contenttweaker:summon_shigure_kirara>, <dimdoors:fabric:0>],
    [<contenttweaker:summon_iridumsky>, <immersiveintelligence:charred_log:0>],
    [<contenttweaker:summon_dinnerbond_1>, <botania:altgrass:1>],
    [<contenttweaker:summon_dinnerbond_2>, <botania:altgrass:1>],
    [<contenttweaker:summon_esteynum>, <minecraft:pumpkin>],
    [<contenttweaker:summon_pyromaniacal>, <divinerpg:dream_grass>],
    [<contenttweaker:summon_flxiowers_>, <minecraft:obsidian>],
    [<contenttweaker:summon_ping_su>, <bewitchment:scorned_bricks>],
    [<contenttweaker:summon_themyself>, <advancedrocketry:crystal:1>],
    [<contenttweaker:summon_x_zhangjun>, <advancedrocketry:moonturf>],
    [<contenttweaker:summon_dogegg_flower>, <minecraft:end_stone>],
    [<contenttweaker:summon_snodvii>, <divinerpg:arcanium_block>],
    [<contenttweaker:summon_fading_sky>, <twilightforest:aurora_block>],
    [<contenttweaker:summon_adrin58>, <appliedenergistics2:fluix_block>],
    [<contenttweaker:summon_puzitsa>, <minecraft:grass>],
    [<contenttweaker:summon_magickyy>, <dimdoors:stable_fabric>],
    [<contenttweaker:summon_greatheaven>, <minecraft:netherrack>],
    [<contenttweaker:summon_whizzball1>, <biomesoplenty:grass:4>],
    [<contenttweaker:summon_xplodous_>, <abyssalcraft:cobblestone:0>],
    [<contenttweaker:summon_origami10004>, <extrautils2:compressedcobblestone:7>],
    [<contenttweaker:summon_nerdyspider_1>, <botania:altgrass:4>],
    [<contenttweaker:summon_nerdyspider_2>, <botania:altgrass:4>]
];

val meatball = <contenttweaker:recursive_meatball>;
val armorStand = <minecraft:armor_stand>;

for callstone in callstones {
    val block = callstone[1];
    recipes.addShaped(callstone[0],
    [[block, meatball, block],
    [meatball, armorStand, meatball],
    [block, meatball, block]]);
}
