#loader crafttweaker reloadable

import mods.zenutils.command.ZenCommand;
import mods.zenutils.command.CommandUtils;
import mods.zenutils.command.IGetTabCompletion;
import crafttweaker.player.IPlayer;
import crafttweaker.item.IItemStack;

// 你猜我为什么写这个
val validCodes as string[] = [
    "IGiveUp",
    "aeddddBlessing",
    "WheelchairPower",
    "WhatIsThis",
    "FriendFigurine",
    "FluidCleanup",
    "Friendship",
    "CoolBlocks",
    "MeatballTruth",
    "MMCE"
];

val codeRewards as IItemStack[][] = [
    [<minecraft:white_shulker_box>.withTag({BlockEntityTag: {Items: [{Slot: 13 as byte, id: "minecraft:paper", Count: 1, Damage: 0 as short, tag: {display: {Name: "§bHahahahaha, you got tricked"}}}]}, HideFlags: 32, display: {Lore: ["§dVirtual Parallel Card (Level 7)§f x64", "§7Central ME Interface  x64", "§7Sword of Cosmic Dominion  x1"]}})*1],
    [<mmceaddition:machine_data>.withTag({machine: "modularmachinery:seared_caster", count: 1024}) * 1],
    [<mmceaddition:machine_data>.withTag({machine: "modularmachinery:solar_array", count: 1, display: {Lore: ["§7Machine: §6Mythic Solar Array", "§7Stored amount: §e2,147,483,647", "§8Put in the machine's virtual parallel hatch to give it parallel"]}, HideFlags: 32})*1],
    [<thaumicaugmentation:rift_seed>.withTag({riftSize: 2000, grown: 1 as byte, display: {Name: "§4What is this and how do I get rid of it", Lore: ["§8§lDon't use this......"]}, HideFlags: 32})*1],
    [<draconicevolution:mob_soul> * 1],
    [<cyclicmagic:ender_water>.withTag({Unbreakable: 1 as byte, display: {Name: "§bAntimatter Evaporator", Lore: ["§l§6Unbreakable"]}, HideFlags: 4}) * 1],
    [<thermalexpansion:florb>.withTag({Fluid: "liquid_fertilizer", display: {Lore: ["§dRight-click to throw"], Name: "§fFluid Orb (Chocolate)§8§m(definitely)"}}) * 64],
    [<appliedenergistics2:facade>.withTag({item: "avaritia:block_resource", damage: 1, display: {Name: "§dInfinity Block - 1/6"}}) * 6],
    [<minecraft:skull:3>.withTag({SkullOwner: {Name: "sainagh", Id: "493f29bb-b31b-39fa-b972-fec5d901113a"}}) * 1,<extrabotany:cosmetic:9>*1],
    [<minecraft:written_book>.withTag({author: "shenkong1234567", title: "Better not open it", pages: ["{\"text\":\"Fun fact:\\nA regular MMCE controller can actually form a machine in place of its specific controller, so you can skip crafting the specific one and use a regular controller (though it will lag a lot)\"}"]})]
];

// ---------- 使用列表存储已使用记录 ----------
global usedCodes as [string] = [];
// 其实退出重进就再能领一次
val redeemCommand as ZenCommand = ZenCommand.create("SKT_redeemcode");

redeemCommand.getCommandUsage = function(sender) {
    return "commands.redeem.usage";
};

redeemCommand.requiredPermissionLevel = 0;

redeemCommand.execute = function(command, server, sender, args) {
    val player = CommandUtils.getCommandSenderAsPlayer(sender);
    if (isNull(player)) {
        return;
    }

    if (args.length != 1) {
        player.sendMessage("§cUsage: /SKT_redeemcode <code>");
        return;
    }

    val code = args[0];
    val playerUUID = player.uuid;

    // 1. 检查兑换码是否有效
    var codeIndex = -1;
    for i in 0 to validCodes.length  {
        if (validCodes[i] == code) {
            codeIndex = i;
            break;
        }
    }
    if (codeIndex == -1) {
        player.sendMessage("§cInvalid code!");
        return;
    }

    // 2. 检查是否已使用
    val usedKey = playerUUID + ":" + code;
    var alreadyUsed = false;
    for entry in usedCodes {
        if (entry == usedKey) {
            alreadyUsed = true;
            break;
        }
    }
    if (alreadyUsed) {
        player.sendMessage("§cYou have already used this code!");
        return;
    }

    // 3. 发放奖励
    val rewards = codeRewards[codeIndex];
    if (!isNull(rewards)) {
        for item in rewards {
            player.give(item);
        }
        // 使用 .add() 方法（不重新赋值字段）
        usedCodes.add(usedKey);
        player.sendMessage("§aRedeemed! You got the reward items.");
    } else {
        player.sendMessage("§cThis code has no reward yet, contact an admin.");
    }
};

redeemCommand.register();