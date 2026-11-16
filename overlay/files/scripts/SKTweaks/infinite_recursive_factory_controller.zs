#loader crafttweaker reloadable
import mods.modularmachinery.RecipeBuilder;
val Eternal_Glory = <minecraft:written_book>.withTag({author: "Sainagh", pages: ["{\"text\":\"Congratulations! You did it!\\nWas it all worth it? That's for you to decide...\\nWithout doubt it was a wild ride, with wins and losses along the way. So let's end on a win!\\n \"}", "{\"text\":\"If you can read this, you have earned eternal glory in the pantheon of the cosmos!\\nThe mark you left and your contribution to this universe will last forever!\"}", "{\"text\":\"If you wish, after finishing the matching quest you will be immortalized as a tooltip on a special endgame item.\\n \"}", "{\"text\":\"Note this can only be done once. Once you have your own tooltip, you can't apply again.\\n \"}", "{\"text\":\"After getting the endgame item of your choice, send me proof of completion on Discord (a screenshot of your base is recommended). The link is on the main menu!\"}", "{\"text\":\"Here is the list of eternal glory items!\\n-Stone of Universal Balance\\n-Sword of Cosmic Dominion\\n-Tome of Astral Mastery\\n-Sashimi of the Gate of Darkness\\n-Cleansed Cinnamon Apple\\n-Black Hole Juice\\n-Tardis Polyp\"}"], resolved: 1 as byte, title: "Eternal Glory"});
Recipe_Builder_SK_Chance(
    "infinite_recursive_factory_controller_make",
    "creation_altar",
    // inputs
    [
        Eternal_Glory*7,
        <contenttweaker:recursion_of_notbeinganoob>*1,
        <contenttweaker:recursion_of_worthiness>*1,
        <contenttweaker:ingot_of_infinite_wishes>*64,
        <contenttweaker:plate_clump_fractal>*32,
        <contenttweaker:infinite_processor>*16,
        <contenttweaker:cosmic_string_conduit>*8,
        <projectex:final_star_shard>*2048,
        <contenttweaker:galactic_power_unit>*1
    ],
    [0.0],
    // fluid inputs
    [
        <liquid:whisper_of_starvald_demelain>*1000,
        <liquid:galactic_plasma>*1000000
    ],
    [],
    // outputs
    [<modularmachinery:infinite_recursive_factory_factory_controller>],
    [],
    // fluid outputs
    [],
    [],
    // time, energy input, energy output
    40000, //
    40960000,
    0
);
