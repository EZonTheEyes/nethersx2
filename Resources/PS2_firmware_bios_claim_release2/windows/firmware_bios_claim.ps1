function Get-Bytes([string]$InFile) {
    if ((Get-Host).version.major -ge 6) {
        (Get-Content $InFile -AsByteStream -ReadCount 0)
    }
    else
    {
        (Get-Content $InFile -encoding byte -ReadCount 0)
    }
}

function Set-Bytes([string]$OutFile, [byte[]] $Data) {
    if ((Get-Host).version.major -ge 6) {
        (Set-Content $OutFile -AsByteStream -Value $Data)
    }
    else
    {
        (Set-Content $OutFile -encoding byte -Value $Data)
    }
}

# https://stackoverflow.com/a/62511302/3192263
function Find-Bytes([byte[]]$Bytes, [byte[]]$Search, [int]$Start, [Switch]$All) {
    For ($Index = $Start; $Index -le $Bytes.Length - $Search.Length ; $Index++) {
        For ($i = 0; $i -lt $Search.Length -and $Bytes[$Index + $i] -eq $Search[$i]; $i++) {}
        If ($i -ge $Search.Length) { 
            $Index
            If (!$All) { Return }
        } 
    }
}

function Extract-BIOS([string]$InFile, [string]$OutFile) {
    $InData = (Get-Bytes $InFile)
    $StartMarkerBytes = [byte[]]("compatible mode".ToCharArray())
    $EndMarkerBytes = [byte[]]("Parity error".ToCharArray())
    $Start = (Find-Bytes $InData $StartMarkerBytes 0) - 0x12F
    $End = (Find-Bytes $InData $EndMarkerBytes $Start) + 0x262
    $BIOS = $InData[$Start .. ($End - 1)] + [byte[]]::new(4*1024*1024 - ($End - $Start))
    Set-Bytes $OutFile $BIOS
}

function Retail-Patch-BIOS([string]$InFile, [string]$OutFile) {
    $BIOS = (Get-Bytes $InFile)
    $VersionMarkerBytes = [byte[]]("0220JD".ToCharArray())
    $Version = (Find-Bytes $BIOS $VersionMarkerBytes 0)
    # 0220JD -> 0220JC
    $BIOS[$Version + 5] = 67
    Set-Bytes $OutFile $BIOS
}

if (!(Test-Path ".\dev_flash\ps1emu\ps1_rom.bin"))
{
    if (!(Test-Path ".\dev_flash\ps1emu\ps1_emu.self"))
    {
        "PS1 BIOS or emulator not found! Reinstall the firmware inside RPCS3!"
        pause
        exit 14
    }
    "Decrypting PS1 emulator..."

    # emu and netemu seem to have the same bios; we only need one
    .\rpcs3.exe --headless --decrypt ".\dev_flash\ps1emu\ps1_emu.self" | Out-Host

    if (!(Test-Path ".\dev_flash\ps1emu\ps1_emu.elf"))
    {
        "PS1 emulator decryption failed? decrypted elf not found"
        pause
        exit 15
    }
    Extract-BIOS ".\dev_flash\ps1emu\ps1_emu.elf" ".\ps3_ps1_emu_ps2_bios.bin"
    if (!(Test-Path ".\ps3_ps1_emu_ps2_bios.bin"))
    {
        "Failed to extract PS1 emulator PS2 BIOS!"
        pause
        exit 16
    }
    $InData = (Get-Bytes ".\ps3_ps1_emu_ps2_bios.bin")
    $PS3PS1PS1BIOS = $InData[0 .. (512*1024 - 1)]
    Set-Bytes ".\ps3_ps1_emu_ps1_bios.bin" $PS3PS1PS1BIOS
    if (!(Test-Path ".\ps3_ps1_emu_ps1_bios.bin"))
    {
        "Failed to copy PS1 emulator PS1 BIOS!"
        pause
        exit 17
    }
    "PS1 emu PS1 BIOS extracted to 'ps3_ps1_emu_ps1_bios.bin'!"
    "PS1 emu PS2 BIOS extracted to 'ps3_ps1_emu_ps2_bios.bin'!"
}
else
{
    "Checking PS1 BIOS..."
    $Size = (Get-Item ".\dev_flash\ps1emu\ps1_rom.bin").Length
    if ($Size -gt (512*1024))
    {
        "Copying large older PS1/PS2 BIOS..."
        $InData = (Get-Bytes ".\dev_flash\ps1emu\ps1_rom.bin")
        $PS3PS1PS1BIOS = $InData[0 .. (512*1024 - 1)]
        Set-Bytes ".\ps3_ps1_emu_ps1_bios.bin" $PS3PS1PS1BIOS

        if (!(Test-Path ".\ps3_ps1_emu_ps1_bios.bin"))
        {
            "Failed to copy PS1 emulator PS1 BIOS!"
            pause
            exit 12
        }

        $PS3PS1PS2BIOS = $InData + [byte[]]::new(4*1024*1024 - ($InData.Length))
        Set-Bytes ".\ps3_ps1_emu_ps2_bios.bin" $PS3PS1PS2BIOS

        if (!(Test-Path ".\ps3_ps1_emu_ps2_bios.bin"))
        {
            "Failed to copy PS1 emulator PS2 BIOS!"
            pause
            exit 13
        }

        "PS1 emu PS1 BIOS extracted to 'ps3_ps1_emu_ps1_bios.bin'!"
        "PS1 emu PS2 BIOS extracted to 'ps3_ps1_emu_ps2_bios.bin'!"
    }
    else
    {
        "Copying small newer PS1 BIOS..."
        Copy-Item ".\dev_flash\ps1emu\ps1_rom.bin" ".\ps3_ps1_bios.bin"

        if (!(Test-Path ".\ps3_ps1_bios.bin"))
        {
            "Failed to copy PS1 BIOS!"
            pause
            exit 11
        }

        "PS1 BIOS extracted to 'ps3_ps1_bios.bin'!"
    }
}

$SoftEmu_Name = "ps2_softemu"
if (Test-Path ".\dev_flash\ps2emu\ps2_netemu.self")
{
    $SoftEmu_Name = "ps2_netemu"
}

if (!(Test-Path ".\dev_flash\ps2emu\ps2_emu.self"))
{
    "PS2 emulator not found! Reinstall the firmware inside RPCS3!"
    pause
    exit 2
}

"Decrypting PS2 emulators..."

.\rpcs3.exe --headless --decrypt ".\dev_flash\ps2emu\ps2_emu.self" | Out-Host

if (!(Test-Path ".\dev_flash\ps2emu\ps2_emu.elf"))
{
    "PS2 emulator decryption failed? decrypted elfs not found"
    pause
    exit 21
}

if (Test-Path (".\dev_flash\ps2emu\ps2_gxemu.self"))
{
    .\rpcs3.exe --headless --decrypt ".\dev_flash\ps2emu\ps2_gxemu.self" | Out-Host

    if (!(Test-Path ".\dev_flash\ps2emu\ps2_gxemu.elf"))
    {
        "PS2 emulator decryption failed? decrypted elf not found"
        pause
        exit 26
    }
}

if (Test-Path (".\dev_flash\ps2emu\" + $SoftEmu_Name + ".self"))
{
    .\rpcs3.exe --headless --decrypt (".\dev_flash\ps2emu\" + $SoftEmu_Name + ".self") | Out-Host

    if (!(Test-Path (".\dev_flash\ps2emu\" + $SoftEmu_Name + ".elf")))
    {
        "PS2 emulator decryption failed? decrypted elf not found"
        pause
        exit 25
    }
}

"PS2 emulators decrypted."

"Extracting ps2_emu.elf..."
Extract-BIOS ".\dev_flash\ps2emu\ps2_emu.elf" ".\ps3_ps2_emu_bios.bin"
if (!(Test-Path ".\ps3_ps2_emu_bios.bin"))
{
    "Failed to copy ps2_emu BIOS!"
    pause
    exit 22
}
"ps2_emu BIOS extracted to 'ps3_ps2_emu_bios.bin'!"

if (Test-Path (".\dev_flash\ps2emu\ps2_gxemu.elf"))
{
    "Extracting ps2_gxemu.elf..."
    Extract-BIOS ".\dev_flash\ps2emu\ps2_gxemu.elf" ".\ps3_ps2_gxemu_bios.bin"
    if (!(Test-Path ".\ps3_ps2_gxemu_bios.bin"))
    {
        "Failed to copy ps2_gxemu BIOS!"
        pause
        exit 23
    }
    "ps2_gxemu BIOS extracted to 'ps3_ps2_gxemu_bios.bin'!"
}


if (Test-Path (".\dev_flash\ps2emu\" + $SoftEmu_Name + ".elf"))
{
    "Extracting " + $SoftEmu_Name + ".elf..."
    Extract-BIOS (".\dev_flash\ps2emu\" + $SoftEmu_Name + ".elf") (".\ps3_" + $SoftEmu_Name + "_bios.bin")
    if (!(Test-Path (".\ps3_" + $SoftEmu_Name + "_bios.bin")))
    {
        "Failed to copy " + $SoftEmu_Name + " BIOS!"
        pause
        exit 24
    }
    $SoftEmu_Name + " BIOS extracted to 'ps3_" + $SoftEmu_Name + "_bios.bin'!"
}

"PS2 BIOS' Extracted!"

"Patching ps2_emu BIOS..."
# Do you really want to play this game?
Retail-Patch-BIOS ".\ps3_ps2_emu_bios.bin" ".\ps3_ps2_emu_bios_retail_patched.bin"
"ps2_emu BIOS patched!"
