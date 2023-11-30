---readme---

NetherSX2

AETHERSX2 COMMUNITY DISCORD:
https://discord.gg/V68Xt5Pyfk

==Notes:==

 -THE CORRECT SHA256 FILEHASH FOR 'aetherpatch-full.sh' IS :
4967C7F6F01678EE4955C13C032AFFBB9E967E34BE894926AF9126305E4A6CF5

Full Vanilla Installation Wipe:

 -BACKUP YOUR SAVE DATA + UNINSTALL VANILLA.

To copy your aethersx2 save data, copy “Mcd001.ps2” and “Mcd002.ps2” from
\Internal storage\Android\data\xyz.aethersx2.android\files\memcards\

 -Uninstall AetherSX2. DO NOT KEEP DATA

If you kept data, reinstall Aether from last source, delete;

\Android\data\xyz.aethersx2.android\

 -Uninstall Aether application



==SETUP TERMUX:==

 -Install Termux 1.18 from F-Droid (do not use from Playstore):  https://f-droid.org/en/packages/com.termux/

 -Update Packages:

apt update && apt upgrade

 -Change Termux Repo to 'Grimler.Se'

termux-change-repo

(Single Repositories; > Grimler.SE),

 -(Note: other repos may or may not work aswell, we have had best luck with this one)

 -Allow Storage Access

termux-setup-storage

>Allow

 -Backup your termux installation in case:

termux-backup ~/storage/shared/my-termux-backup-tar.gz



==Web Installations:==

 -CURL FROM WEB:

curl [URL] > aetherpatch-full.sh && bash aetherpatch-full.sh && rm aetherpatch-full.sh


 -ex; 

curl https://cdn.discordapp.com/attachments/1063822057319702621/1138248619015802990/aetherpatch-full.sh > aetherpatch-full.sh && bash aetherpatch-full.sh && rm aetherpatch-full.sh



==Local Installations:==

 -RUN FROM LOCAL:

bash /[FILELOCATION]/aetherpatch-full.sh


 -ex;

bash /storage/emulated/0/NetherSX2/aetherpatch-full.sh


 -ADJUST FILE NAME LOCALLY VIA TERMUX:

sed -i 's/NetherSX2/PlaceAppNameHere/g' /[FILELOCATION]/aetherpatch-full.sh


ex;

sed -i 's/NetherSX2/PlaceAppNameHere/g' /storage/emulated/0/NetherSX2/aetherpatch-full.sh