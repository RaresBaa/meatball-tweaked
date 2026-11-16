#loader crafttweaker reloadable
#priority -9
import mods.ae2enhanced.BlackHole;
// 主控制器
BlackHole.addRecipe(
    <modularmachinery:numeron_network_factory_controller>, 
    [
       <twilightforest:lamp_of_cinders>,
       <draconicevolution:dragon_heart>*2,
       <ae2enhanced:stable_spacetime_manifold>*4,
       <contenttweaker:furnace_heart>*16
    ]
);
<modularmachinery:numeron_network_factory_controller>.addTooltip(format.gold("Comes with 64 threads"));
<modularmachinery:numeron_network_factory_controller>.addTooltip(format.gold("256 parallel per thread by default"));
<modularmachinery:numeron_network_factory_controller>.addTooltip(format.green("Can be fitted with submodule upgrades"));
<modularmachinery:numeron_network_factory_controller>.addTooltip(format.green("Submodule machines must form in their set positions"));
<modularmachinery:numeron_network_factory_controller>.addTooltip(format.green("Submodule positions are marked in the main controller's structure"));
<modularmachinery:numeron_network_factory_controller>.addTooltip(format.red("(beacon base blocks)"));

// 一阶
<modularmachinery:mythic_fractal_core_1_factory_controller>.addTooltip(format.gold("[Tier 1 Mythic Resonance Module]"));
<modularmachinery:mythic_fractal_core_1_factory_controller>.addTooltip(format.gold("Energy use x0.05, speed x20"));
mods.extendedcrafting.CombinationCrafting.addRecipe(<modularmachinery:mythic_fractal_core_1_factory_controller>, 
1000000, 
<modularmachinery:blockcontroller>, 
[<contenttweaker:eden_star>,<contenttweaker:eden_star>,<contenttweaker:eden_star>,<contenttweaker:eden_star>,
<contenttweaker:first_order_mythic_fractal>,<contenttweaker:first_order_mythic_fractal>,
<contenttweaker:first_order_mythic_fractal>,<contenttweaker:first_order_mythic_fractal>,
<tconstruct:large_plate>.withTag({Material: "berserk_steel"}),<tconstruct:large_plate>.withTag({Material: "berserk_steel"})]);
// 二阶
<modularmachinery:mythic_fractal_core_2_factory_controller>.addTooltip(format.gold("[Tier 2 Mythic Resonance Module]"));
<modularmachinery:mythic_fractal_core_2_factory_controller>.addTooltip(format.gold("Allows byproduct output"));
mods.extendedcrafting.CombinationCrafting.addRecipe(<modularmachinery:mythic_fractal_core_2_factory_controller>, 
1000000, 
<modularmachinery:blockcontroller>, 
[<contenttweaker:second_order_mythic_fractal>,<contenttweaker:second_order_mythic_fractal>,
<contenttweaker:second_order_mythic_fractal>,<contenttweaker:second_order_mythic_fractal>,
<contenttweaker:wildwood_star>,<contenttweaker:wildwood_star>,<contenttweaker:wildwood_star>,<contenttweaker:wildwood_star>,
<contenttweaker:crown_of_the_energy_queen>,<contenttweaker:crown_of_the_energy_queen>]);
// 三阶
<modularmachinery:mythic_fractal_core_3_factory_controller>.addTooltip(format.gold("[Tier 3 Mythic Resonance Module]"));
<modularmachinery:mythic_fractal_core_3_factory_controller>.addTooltip(format.gold("Parallel x16, main product x16"));
mods.extendedcrafting.CombinationCrafting.addRecipe(<modularmachinery:mythic_fractal_core_3_factory_controller>, 
1000000, 
<modularmachinery:blockcontroller>, 
[<contenttweaker:third_order_mythic_fractal>,<contenttweaker:third_order_mythic_fractal>,
<contenttweaker:third_order_mythic_fractal>,<contenttweaker:third_order_mythic_fractal>,
<contenttweaker:apalachia_star>,<contenttweaker:apalachia_star>,<contenttweaker:apalachia_star>,<contenttweaker:apalachia_star>,
<appliedenergistics2:creative_energy_cell>,<appliedenergistics2:creative_energy_cell>]);
// 四阶
<modularmachinery:mythic_fractal_core_4_factory_controller>.addTooltip(format.gold("[Tier 4 Mythic Resonance Module]"));
<modularmachinery:mythic_fractal_core_4_factory_controller>.addTooltip(format.gold("Byproduct output x8"));
mods.extendedcrafting.CombinationCrafting.addRecipe(<modularmachinery:mythic_fractal_core_4_factory_controller>, 
1000000, 
<modularmachinery:blockcontroller>, 
[<contenttweaker:fourth_order_mythic_fractal>,<contenttweaker:fourth_order_mythic_fractal>,
<contenttweaker:fourth_order_mythic_fractal>,<contenttweaker:fourth_order_mythic_fractal>,
<contenttweaker:skythern_star>,<contenttweaker:skythern_star>,<contenttweaker:skythern_star>,<contenttweaker:skythern_star>,
<contenttweaker:nightmare_block>,<contenttweaker:nightmare_block>]);
// 五阶
<modularmachinery:mythic_fractal_core_5_factory_controller>.addTooltip(format.gold("[Tier 5 Mythic Resonance Module]"));
<modularmachinery:mythic_fractal_core_5_factory_controller>.addTooltip(format.gold("Energy use x0.05, speed x2, parallel x256"));
mods.extendedcrafting.CombinationCrafting.addRecipe(<modularmachinery:mythic_fractal_core_5_factory_controller>, 
1000000, 
<modularmachinery:blockcontroller>, 
[<contenttweaker:fifth_order_mythic_fractal>,<contenttweaker:fifth_order_mythic_fractal>,
<contenttweaker:fifth_order_mythic_fractal>,<contenttweaker:fifth_order_mythic_fractal>,
<contenttweaker:mortum_star>,<contenttweaker:mortum_star>,<contenttweaker:mortum_star>,<contenttweaker:mortum_star>,
<contenttweaker:ascended_fluix_etcher>,<contenttweaker:ascended_fluix_etcher>]);