#!/bin/bash

function pause() {
    read -n1 -r -p "Press any key to continue..." key
}

function extract_bios() {
    INFILE="$1"
    OUTFILE="$2"
    START=$(grep -abo "compatible mode" "$INFILE" | head -n 1 | cut -d: -f 1)
    START=$((START - 0x12F))
    END=$(grep -abo "Parity error" "$INFILE" | head -n 1 | cut -d: -f 1)
    END=$((END + 0x262))
    dd if="$INFILE" of="$OUTFILE" bs=1 skip="$START" count=$((END - START)) 2>/dev/null
    # Some emulators check the size of the BIOS and require it to be 4-8MiB
    truncate -s $((4*1024*1024)) "$OUTFILE"
}

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

RPCS3="$SCRIPT_DIR/rpcs3.AppImage"
if [ -z "$XDG_CONFIG_HOME" ]; then
    if [ -d "$RPCS3.config" ]; then
        RPCS3_CONFIG_DIR="$RPCS3.config/rpcs3"
    else
        RPCS3_CONFIG_DIR="$HOME/.config/rpcs3"
    fi
else
    RPCS3_CONFIG_DIR="$XDG_CONFIG_HOME/rpcs3"
fi

if [ ! -f "$RPCS3_CONFIG_DIR/dev_flash/ps1emu/ps1_rom.bin" ]; then
    if [ ! -f "$RPCS3_CONFIG_DIR/dev_flash/ps1emu/ps1_emu.self" ]; then
        echo "PS1 BIOS or emulator not found! Reinstall the firmware inside RPCS3!"
        pause
        exit 14
    fi

    echo "Decrypting PS1 emulator..."
    "$RPCS3" --headless --decrypt "$RPCS3_CONFIG_DIR/dev_flash/ps1emu/ps1_emu.self"
    if [ ! -f "$RPCS3_CONFIG_DIR/dev_flash/ps1emu/ps1_emu.elf" ]; then
        echo "PS1 emulator decryption failed? decrypted elf not found"
        pause
        exit 15
    fi

    extract_bios "$RPCS3_CONFIG_DIR/dev_flash/ps1emu/ps1_emu.elf" "$SCRIPT_DIR/ps3_ps1_emu_ps2_bios.bin"
    if [ ! -f "$SCRIPT_DIR/ps3_ps1_emu_ps2_bios.bin" ]; then
        echo "Failed to extract PS1 emulator PS2 BIOS!"
        pause
        exit 16
    fi
    dd if="$SCRIPT_DIR/ps3_ps1_emu_ps2_bios.bin" of="$SCRIPT_DIR/ps3_ps1_emu_ps1_bios.bin" bs=512 count=1024 2>/dev/null
    if [ ! -f "$SCRIPT_DIR/ps3_ps1_emu_ps1_bios.bin" ]; then
        echo "Failed to copy PS1 emulator PS1 BIOS!"
        pause
        exit 17
    fi
    echo "PS1 emu PS1 BIOS extracted to 'ps3_ps1_emu_ps1_bios.bin'!"
    echo "PS1 emu PS2 BIOS extracted to 'ps3_ps1_emu_ps2_bios.bin'!"
else
    echo "Checking PS1 BIOS..."
    PS1ROMSIZE=$(wc -c < "$RPCS3_CONFIG_DIR/dev_flash/ps1emu/ps1_rom.bin")
    if [ "$PS1ROMSIZE" -gt $((512*1024)) ]; then
        echo "Copying large older PS1/PS2 BIOS..."
        head -c $((512*1024)) < "$RPCS3_CONFIG_DIR/dev_flash/ps1emu/ps1_rom.bin" > "$SCRIPT_DIR/ps3_ps1_emu_ps1_bios.bin"
        if [ ! -f "$SCRIPT_DIR/ps3_ps1_emu_ps1_bios.bin" ]; then
            echo "Failed to copy PS1 emulator PS1 BIOS!"
            pause
            exit 12
        fi
        cp "$RPCS3_CONFIG_DIR/dev_flash/ps1emu/ps1_rom.bin" "$SCRIPT_DIR/ps3_ps1_emu_ps2_bios.bin"
        truncate -s $((4*1024*1024)) "$SCRIPT_DIR/ps3_ps1_emu_ps2_bios.bin"
        if [ ! -f "$SCRIPT_DIR/ps3_ps1_emu_ps2_bios.bin" ]; then
            echo "Failed to copy PS1 emulator PS2 BIOS!"
            pause
            exit 13
        fi
        echo "PS1 emu PS1 BIOS extracted to 'ps3_ps1_emu_ps1_bios.bin'!"
        echo "PS1 emu PS2 BIOS extracted to 'ps3_ps1_emu_ps2_bios.bin'!"
    else
        echo "Copying small newer PS1 BIOS..."
        cp "$RPCS3_CONFIG_DIR/dev_flash/ps1emu/ps1_rom.bin" "$SCRIPT_DIR/ps3_ps1_bios.bin"
        if [ ! -f "$SCRIPT_DIR/ps3_ps1_bios.bin" ]; then
            echo "Failed to copy PS1 BIOS!"
            pause
            exit 11
        fi
        echo "PS1 BIOS extracted to 'ps3_ps1_bios.bin'!"
    fi
fi

SOFTEMU_NAME="ps2_softemu"
if [ -f "$RPCS3_CONFIG_DIR/dev_flash/ps2emu/ps2_netemu.self" ]; then
    SOFTEMU_NAME="ps2_netemu"
fi

if [ ! -f "$RPCS3_CONFIG_DIR/dev_flash/ps2emu/ps2_emu.self" ]; then
    echo "PS2 emulator not found! Reinstall the firmware inside RPCS3!"
    pause
    exit 2
fi

echo "Decrypting PS2 emulators..."

"$RPCS3" --headless --decrypt "$RPCS3_CONFIG_DIR/dev_flash/ps2emu/ps2_emu.self"

if [ ! -f "$RPCS3_CONFIG_DIR/dev_flash/ps2emu/ps2_emu.elf" ]; then
    echo "PS2 emulator decryption failed? decrypted elfs not found"
    pause
    exit 21
fi

if [ -f "$RPCS3_CONFIG_DIR/dev_flash/ps2emu/ps2_gxemu.self" ]; then
    "$RPCS3" --headless --decrypt "$RPCS3_CONFIG_DIR/dev_flash/ps2emu/ps2_gxemu.self"
    if [ ! -f "$RPCS3_CONFIG_DIR/dev_flash/ps2emu/ps2_gxemu.elf" ]; then
        echo "PS2 emulator decryption failed? decrypted elf not found"
        pause
        exit 26
    fi
fi

if [ -f "$RPCS3_CONFIG_DIR/dev_flash/ps2emu/$SOFTEMU_NAME.self" ]; then
    "$RPCS3" --headless --decrypt "$RPCS3_CONFIG_DIR/dev_flash/ps2emu/$SOFTEMU_NAME.self"
    if [ ! -f "$RPCS3_CONFIG_DIR/dev_flash/ps2emu/$SOFTEMU_NAME.elf" ]; then
        echo "PS2 emulator decryption failed? decrypted elf not found"
        pause
        exit 25
    fi
fi

echo "PS2 emulators decrypted."

echo "Extracting ps2_emu.elf..."
extract_bios "$RPCS3_CONFIG_DIR/dev_flash/ps2emu/ps2_emu.elf" "$SCRIPT_DIR/ps3_ps2_emu_bios.bin"
if [ ! -f "$SCRIPT_DIR/ps3_ps2_emu_bios.bin" ]; then
    echo "Failed to copy ps2_emu BIOS!"
    pause
    exit 22
fi
echo "ps2_emu BIOS extracted to 'ps3_ps2_emu_bios.bin'!"


if [ -f "$RPCS3_CONFIG_DIR/dev_flash/ps2emu/ps2_gxemu.elf" ]; then
    echo "Extracting ps2_gxemu.elf..."
    extract_bios "$RPCS3_CONFIG_DIR/dev_flash/ps2emu/ps2_gxemu.elf" "$SCRIPT_DIR/ps3_ps2_gxemu_bios.bin"
    if [ ! -f "$SCRIPT_DIR/ps3_ps2_gxemu_bios.bin" ]; then
        echo "Failed to copy ps2_gxemu BIOS!"
        pause
        exit 23
    fi
    echo "ps2_gxemu BIOS extracted to 'ps3_ps2_gxemu_bios.bin'!"
fi

if [ -f "$RPCS3_CONFIG_DIR/dev_flash/ps2emu/$SOFTEMU_NAME.elf" ]; then
    echo "Extracting $SOFTEMU_NAME.elf..."
    extract_bios "$RPCS3_CONFIG_DIR/dev_flash/ps2emu/$SOFTEMU_NAME.elf" "$SCRIPT_DIR/ps3_${SOFTEMU_NAME}_bios.bin"
    if [ ! -f "$SCRIPT_DIR/ps3_${SOFTEMU_NAME}_bios.bin" ]; then
        echo "Failed to copy $SOFTEMU_NAME BIOS!"
        pause
        exit 24
    fi
    echo "$SOFTEMU_NAME BIOS extracted to 'ps3_${SOFTEMU_NAME}_bios.bin'!"
fi

echo "PS2 BIOS' Extracted!"

echo "Patching ps2_emu BIOS..."
# Do you really want to play this game?
sed 's/0220JD/0220JC/' "$SCRIPT_DIR/ps3_ps2_emu_bios.bin" > "$SCRIPT_DIR/ps3_ps2_emu_bios_retail_patched.bin"
echo "ps2_emu BIOS patched!"

pause

