#priority -10

import crafttweaker.item.IItemStack;

// AEGating.zs removes the mod's recipes. These follow its molecular assembler recipes,
// and tiers 5 and 6 also need Singularities and a Quantum Ring.

val card = <appliedenergistics2:material:30>;
val singularity = <appliedenergistics2:material:47>;
val quantumRing = <appliedenergistics2:quantum_ring>;
val processor = <cells:singularity_processor:0>;
val assemblerGate = <threng:big_assembler:3>;
val coprocessorGate = <nae2:coprocessor_4x>;

// AEGating.zs removes tier 1 twice and misses tier 4.
recipes.remove(<ae2overclocked:export_bus_tier_4>);

// Each list starts with the item that tier 1 upgrades.
val families as IItemStack[][] = [
    [<appliedenergistics2:part:240>, <ae2overclocked:import_bus_tier_1>, <ae2overclocked:import_bus_tier_2>, <ae2overclocked:import_bus_tier_3>, <ae2overclocked:import_bus_tier_4>, <ae2overclocked:import_bus_tier_5>, <ae2overclocked:import_bus_tier_6>],
    [<appliedenergistics2:part:260>, <ae2overclocked:export_bus_tier_1>, <ae2overclocked:export_bus_tier_2>, <ae2overclocked:export_bus_tier_3>, <ae2overclocked:export_bus_tier_4>, <ae2overclocked:export_bus_tier_5>, <ae2overclocked:export_bus_tier_6>],
    [<appliedenergistics2:inscriber>, <ae2overclocked:inscriber_tier_1>, <ae2overclocked:inscriber_tier_2>, <ae2overclocked:inscriber_tier_3>, <ae2overclocked:inscriber_tier_4>, <ae2overclocked:inscriber_tier_5>, <ae2overclocked:inscriber_tier_6>],
    [<appliedenergistics2:interface>, <ae2overclocked:interface_tier_1>, <ae2overclocked:interface_tier_2>, <ae2overclocked:interface_tier_3>, <ae2overclocked:interface_tier_4>],
    [<ae2fc:dual_interface>, <ae2overclocked:fluid_interface_tier_1>, <ae2overclocked:fluid_interface_tier_2>, <ae2overclocked:fluid_interface_tier_3>, <ae2overclocked:fluid_interface_tier_4>],
    [<ae2fc:dual_interface>, <ae2overclocked:dual_interface_tier_1>, <ae2overclocked:dual_interface_tier_2>, <ae2overclocked:dual_interface_tier_3>, <ae2overclocked:dual_interface_tier_4>]
];

for family in families {
    for tier in 1 to family.length {
        val corner = tier >= 5 ? singularity : card;
        val gate = tier >= 5 ? quantumRing : assemblerGate;
        recipes.addShaped(family[tier],
        [[corner, gate, corner],
        [family[tier - 1], processor, family[tier - 1]],
        [corner, family[tier - 1], corner]]);
    }
}

val coprocessors as IItemStack[] = [<appliedenergistics2:crafting_accelerator>, <ae2overclocked:crafting_coprocessor_tier_1>, <ae2overclocked:crafting_coprocessor_tier_2>, <ae2overclocked:crafting_coprocessor_tier_3>, <ae2overclocked:crafting_coprocessor_tier_4>, <ae2overclocked:crafting_coprocessor_tier_5>, <ae2overclocked:crafting_coprocessor_tier_6>];

for tier in 1 to coprocessors.length {
    val corner = tier >= 5 ? singularity : card;
    val gate = tier >= 5 ? quantumRing : coprocessorGate;
    recipes.addShaped(coprocessors[tier],
    [[corner, gate, corner],
    [coprocessors[tier - 1], processor, coprocessors[tier - 1]],
    [corner, coprocessors[tier - 1], corner]]);
}

recipes.addShaped(<ae2overclocked:molecular_assembler_tier_5>,
[[singularity, quantumRing, singularity],
[<ae2overclocked:molecular_assembler_tier_4>, processor, <ae2overclocked:molecular_assembler_tier_4>],
[singularity, <ae2overclocked:molecular_assembler_tier_4>, singularity]]);

recipes.addShaped(<ae2overclocked:molecular_assembler_tier_6>,
[[singularity, quantumRing, singularity],
[<ae2overclocked:molecular_assembler_tier_5>, processor, <ae2overclocked:molecular_assembler_tier_5>],
[singularity, <ae2overclocked:molecular_assembler_tier_5>, singularity]]);
