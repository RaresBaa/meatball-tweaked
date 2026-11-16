# MeatballCraft Tweaked

An installer for an extended version of [MeatballCraft: Dimensional Ascension](https://www.curseforge.com/minecraft/modpacks/meatballcraft),
the Minecraft 1.12.2 progression pack by Sainagh, based on prerelease-0.18.6.4. On top of it, this adds:

- [SK-Tweaks](https://github.com/shenkongsk/SK-Tweaks): extra machines, quests and scripts, with the text translated to English.
- [QMD](https://github.com/RaresBaa/QMD): Quantum Minecraft Dynamics, ported to the plain NuclearCraft this pack uses.
- Around 80 other mods and libraries, among them new dimensions (Atum 2, The Midnight, Tropicraft, The Aurorian, Journey Into the
  Light, Lands of Icaria, NTM Space), tech mods (NTM Community Edition, Mekanism CE, PneumaticCraft, Immersive Intelligence, Logistics
  Pipes), magic mods (Roots, Psi, Nature's Aura, Embers), Macaw's building mods, Quark, Waystones and Distant Horizons.
- Config changes, quests and fixes to make it all work together, and patches so it runs on Cleanroom with Java 25.

In game, three books help you find your way:

- **MeatballCraft Guide** (crafted from a book, a paper and a cooked beef): tips for the pack, with chapter walkthroughs,
  automation, storage and the bigger mods, plus ready-made Super Factory Manager scripts from the community. Entries with spoilers
  start with a warning page.
- **Added Mods** (crafted from a book and 2 paper): describes each added mod.
- **Computer Programs** (crafted from a book and a ComputerCraft floppy disk, or a book and an OpenComputers keyboard): the
  games and tools that come installed on ComputerCraft computers, and good OpenComputers programs with how to install them.

Every dimension ID is listed in [DIMENSIONS.md](DIMENSIONS.md).

This repository contains none of MeatballCraft's or SK-Tweaks' files. The installer downloads the original pack from CurseForge
and SK-Tweaks from GitHub, then applies the changes kept here. All credit for the original pack goes to Sainagh and its
contributors, and for SK-Tweaks to shenkongsk.

## Requirements

- [Prism Launcher](https://prismlauncher.org/)
- A Java 25 **JDK**, for example [Azul Zulu 25](https://www.azul.com/downloads/?version=java-25-lts&package=jdk) or
  [Temurin 25](https://adoptium.net/temurin/releases/?version=25&package=jdk). A JRE isn't enough to run the installer. The
  game runs on the same Java.
- 32 GB of RAM. The game is given a 10 GB heap and uses up to about 16 GB in total.
- About 5 GB of free disk space: 1.5 GB of downloads kept in `.cache/`, and the instance itself.

## Installing

1. Download this repository, either with `git clone https://github.com/RaresBaa/meatball-tweaked.git`.

2. Open a terminal in the folder and run the installer. It is the same command on Windows and Linux:

   ```
   java Install.java
   ```

   On Windows, open the folder in File Explorer, type `cmd` in the address bar and press Enter to get a terminal there. If `java`
   isn't found, use the full path, for example `"C:\Program Files\Zulu\zulu-25\bin\java.exe" Install.java`.

   It downloads about 460 files, checks each against its hash, and creates the folder `MeatballCraft-Tweaked`. It takes a few
   minutes. If a download fails, run it again: finished downloads are kept.

3. Put the instance into Prism. Either:
   - move the `MeatballCraft-Tweaked` folder into Prism's instances folder (in Prism: **Folders > Instances**; it is
     `%APPDATA%\PrismLauncher\instances` on Windows and `~/.local/share/PrismLauncher/instances` on Linux), then restart Prism, or
   - run `java Install.java --zip` instead, and import `MeatballCraft-Tweaked.zip` with **Add Instance > Import**.

4. In the instance's **Settings > Java**, choose your Java 25 installation, then launch. The first start takes 4 to 5 minutes.

Options: `--out <folder>` builds the instance somewhere else. The installer never overwrites an existing folder.

On Windows, a Microsoft Defender exclusion for the instance folder makes startup noticeably faster. If the game window doesn't
open on Linux with Wayland, look at `FORCE_WAYLAND` in `minecraft/config/forge_early.cfg`.

## What is in here

| Path | What it is |
|---|---|
| `Install.java` | The installer |
| `pack.json` | The MeatballCraft zip and its hash, the SK-Tweaks files used, and pack files that are removed |
| `downloads.json` | Every mod, shader pack and resource pack, where it comes from and its hash |
| `overlay/diffs/` | Changes to MeatballCraft and SK-Tweaks files, as unified diffs |
| `overlay/files/` | Files that are added, and changed binary files |
| `instance/` | Prism's instance settings and the Cleanroom loader |
| `patchers/` | Small bytecode patches applied to some downloaded mods: NTM CE (Cleanroom mixin loading, a dimension memory leak), NTM Space, Distant Horizons (a memory leak) and Modular Machinery Addons (a crash) |
| `source-patches/` | The source changes behind the AE2Enhanced and MMCE Addition jars |

AE2Enhanced (GPL-3.0) and MMCE Addition (BSD-3-Clause) are built from source and attached to this repository's `jars-1`
release. Their source is [aeddddd/AE2Enhanced](https://github.com/aeddddd/AE2Enhanced) at commit `a267bf5` and
[aeddddd/MMCE-addition](https://github.com/aeddddd/MMCE-addition) at commit `411d44d`, each with the patch in `source-patches/`.

Two resource packs are enabled by default: New AE2 Textures for 1.12.2 v1.3,
downloaded from CurseForge, and a [Vanilla Tweaks](https://vanillatweaks.net) pack. Vanilla Tweaks builds each pack on request and
has no permanent link, so that zip is in `overlay/files/resourcepacks/`. `Selected Packs.txt` inside it lists the tweaks.

## Known problems

- Pressing an Immersive Intelligence keybind on the title screen crashes the game.
- NTM Space comes from a nightly build. If that build is ever deleted upstream, the installer can't download it.
