#modloaded defiledlands
#loader mixin

import native.net.minecraft.world.World;
import native.net.minecraft.util.math.BlockPos;
import native.net.minecraft.block.state.IBlockState;
import native.java.util.Random;

import mixin.CallbackInfo;

/*
Stop corrupted blocks from spreading corruption on random ticks.

Every corrupted block calls CorruptionHelper.spread from its random tick.
Worldgen (WorldGenCorruptionPost) and Defilement Powder use corrupt()
directly, so defiled biomes still generate and the powder still works.
*/
#mixin Mixin
#{targets: "lykrast.defiledlands.common.util.CorruptionHelper"}
zenClass MixinCorruptionHelper {
  #mixin Static
  #mixin Inject
  #{
  #  method: "spread",
  #  at: {value: "HEAD"},
  #  cancellable: true
  #}
  function mbc_noSpread(world as World, pos as BlockPos, state as IBlockState, rand as Random, ci as CallbackInfo) as void {
    ci.cancel();
  }
}
