import crafttweaker.item.IItemStack;

// Matter replication is disabled: its matter-value calculation over every recipe
// pegged a CPU core for minutes on each world load. Fusion Reactor and Transporter
// matter costs are set to 0 in MatterOverdrive.cfg so they still run on energy.
val replicationItems = [
    <matteroverdrive:decomposer>,
    <matteroverdrive:replicator>,
    <matteroverdrive:matter_analyzer>,
    <matteroverdrive:matter_scanner>,
    <matteroverdrive:matter_recycler>,
    <matteroverdrive:pattern_storage>,
    <matteroverdrive:pattern_drive>,
    <matteroverdrive:pattern_monitor>,
    <matteroverdrive:matter_pipe>,
    <matteroverdrive:heavy_matter_pipe>,
    <matteroverdrive:network_pipe>,
    <matteroverdrive:network_router>,
    <matteroverdrive:network_switch>,
    <matteroverdrive:network_flash_drive>
] as IItemStack[];

for item in replicationItems {
    recipes.remove(item);
    mods.jei.JEI.hide(item);
}
