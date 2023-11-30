This script assumes you are using the RPCS3 AppImage, and that it is named 'rpcs3.AppImage' (feel free to edit the "RPCS3" variable in the script if not).

Download rpcs3 here: https://rpcs3.net/download
And be sure to read the Quickstart guide here: https://rpcs3.net/quickstart

How to extract the PS1/PS2 BIOS from the PS3 firmware:
1. Install the RPCS3 AppImage as well as a copy of the PS3 firmware PUP file [ Officially available at https://www.playstation.com/en-us/support/hardware/ps3/system-software/, a copy is also included on every PS3 disc, no EULA required if you have a compatible Blu-Ray drive ]
2. Copy 'firmware_bios_claim.sh' into the same folder as your 'rpcs3.AppImage'
3. Run rpcs3 at least once, install the PS3 firmware, and close it
4. Run 'firmware_bios_claim.sh'
5. Your Output bios will now be located in your RPCS3 install folder, enjoy


Different firmwares may give you different BIOS files:
PS3 Firmwares >= 1.00 && < 1.50:
    ps3_ps1_emu_ps1_bios.bin: Use this for PS1 emulators; PS2 BIOS trimmed to 512KiB, does not have the PS1 BIOS menu
    ps3_ps1_emu_ps2_bios.bin: Use this for PS2 emulators; PS2 BIOS padded to 4MiB, has the PS2 BIOS menu
    ps3_ps2_emu_bios.bin: Not recommended; PS2 dev BIOS padded to 4MiB, does not have the PS2 BIOS menu
    ps3_ps2_emu_bios_retail_patched.bin: Same as above, but patched for some emulators

PS3 Firmwares >= 1.50 && < 1.90:
    ps3_ps1_emu_ps1_bios.bin: Use this for PS1 emulators; PS2 BIOS trimmed to 512KiB, does not have the PS1 BIOS menu
    ps3_ps1_emu_ps2_bios.bin: Use this for PS2 emulators; PS2 BIOS padded to 4MiB, has the PS2 BIOS menu
    ps3_ps2_emu_bios.bin: Not recommended; PS2 dev BIOS padded to 4MiB, does not have the PS2 BIOS menu
    ps3_ps2_emu_bios_retail_patched.bin: Same as above, but patched for some emulators
    ps3_ps2_gxemu_bios.bin: Not recommended; PS2 dev BIOS padded to 4MiB, does not have the PS2 BIOS menu

PS3 Firmwares >= 1.90 && < 3.74:
    ps3_ps1_emu_ps1_bios.bin: Use this for PS1 emulators; PS2 BIOS trimmed to 512KiB, does not have the PS1 BIOS menu
    ps3_ps1_emu_ps2_bios.bin: Use this for PS2 emulators; PS2 BIOS padded to 4MiB, has the PS2 BIOS menu
    ps3_ps2_emu_bios.bin: Not recommended; PS2 dev BIOS padded to 4MiB, does not have the PS2 BIOS menu
    ps3_ps2_emu_bios_retail_patched.bin: Same as above, but patched for some emulators
    ps3_ps2_gxemu_bios.bin: Not recommended; PS2 dev BIOS padded to 4MiB, does not have the PS2 BIOS menu
    ps3_ps2_softemu_bios.bin: Not recommended; PS2 dev BIOS padded to 4MiB, does not have the PS2 BIOS menu

PS3 Firmwares >= 4.00 && < 4.10:
    ps3_ps1_bios.bin: Use this for PS1 emulators; PS2 BIOS trimmed to 512KiB, does not have the PS1 BIOS menu
    ps3_ps2_emu_bios.bin: Find an older firmware if possible, but any of these BIOS' technically work; PS2 dev BIOS padded to 4MiB, does not have the PS2 BIOS menu
    ps3_ps2_emu_bios_retail_patched.bin: Same as above, but patched for some emulators
    ps3_ps2_gxemu_bios.bin: --------; PS2 dev BIOS padded to 4MiB, does not have the PS2 BIOS menu
    ps3_ps2_softemu_bios.bin: --------; PS2 dev BIOS padded to 4MiB, does not have the PS2 BIOS menu

PS3 Firmwares >= 4.10:
    ps3_ps1_bios.bin: Use this for PS1 emulators; PS2 BIOS trimmed to 512KiB, does not have the PS1 BIOS menu
    ps3_ps2_emu_bios.bin: Find an older firmware if possible, but any of these BIOS' technically work; PS2 dev BIOS padded to 4MiB, does not have the PS2 BIOS menu
    ps3_ps2_emu_bios_retail_patched.bin: Same as above, but patched for some emulators
    ps3_ps2_gxemu_bios.bin: --------; PS2 dev BIOS padded to 4MiB, does not have the PS2 BIOS menu
    ps3_ps2_netemu_bios.bin: --------; PS2 dev BIOS padded to 4MiB, does not have the PS2 BIOS menu
