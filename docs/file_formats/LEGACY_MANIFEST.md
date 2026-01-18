# Legacy Manifest

In use since Blue Hell Productions

> [!IMPORTANT]
> References to packages exclude `.zip`

Example `Full` manifest:

```xml

<BHP_Game_Manifest game="apb" version="0.9935.1.0" type="Full">
    <Dependency name="msvc-2015.zip"/>
    <Dependency name="directx-43.zip"/>
    <File name="game.exe" checksum="C7AE972A2B9CF6EFCADE7919323F048F5CFAF2D40BD5A67D5A91F8D8A3759CA4" package="binaries"/>
    <File name="MemoryManager.dll" checksum="B60A2B3F6A07D729EE5C2902CB9A6BEDAF55EEDB13F8514BAC0AD6F5D51DD0C2" package="binaries"/>
    <File name="scripts.dll" checksum="76CAAEBF21E4D6A34C3ABDD474D59580DD1EAB097C9585A1FFC0E28FF0FCAF56" package="binaries"/>
    <File name="Scripts2.dll" checksum="A0439B3BFE6CB497F402291548A312A9F43C0D38BDAF26C83E21DBD3F4D55702" package="binaries"/>
    <File name="shared.dll" checksum="17A8797EC5F4C34E241681F4AF76EEA93856D6A1854EC9838B263AEC89CDF036" package="binaries"/>
    <File name="ttle.dll" checksum="C005EB50D77675CE712B30A4402AB0D152D3993EB509E35AEDCB834CED54FADF" package="binaries"/>
    <File name="ttversion.txt" checksum="17A9E627A03E20AC33849330468BF8A80B48449C9D473DF45F1052A160083167" package="misc"/>
    <File name="Data/always.dat" checksum="D4D09149C7B5368AB3947AEC7B6E7781208F592FCA4390261F04A8E9C1887EB3" package="always"/>
    <File name="Data/RA_Volcano.mix" checksum="4F3CB80BCF200659B3B4B167CCB64ECB36A3BA917681F4AB8027568EC187B88D" package="RA_Volcano"/>
    <File name="Data/Movies/ea_ww.bik" checksum="065B8B0894CF9C1C09A940D26069C54A771EBB3092143BA37E97F8CA85B8CCAD" package="movies"/>
    <File name="Data/Movies/R_Intro.BIK" checksum="0D9A2B2ABFD9680DF1C8D0F876DA4B60F015CA5C56EC6C0593528A3F88E2A58F" package="movies"/>
</BHP_Game_Manifest>
```

Example `Patch` manifest:

```xml

<BHP_Game_Manifest game="apb" version="3.6.4.1" type="Patch" baseVersion="3.6.4.0">
    <Dependency name="msvc-2022.zip"/>
    <Dependency name="msvc-2015.zip" removedsince="3.6.4.1"/>
    <File name="data/Always.dat" checksum="7B27D547E5A50401C9CA2851ACD4AC3F3CDA104F34650E1C32EB63A4120E3C90">
        <Patch from="3.6.4.0" package="Always.patch.3.6.4.0"/>
    </File>
    <File name="data/Always_Emitters.dat" checksum="5C3EA8E5C4D7278F5EF1AF3CE1FC4F698C5A7D1FE7116DA0376A709E7CD3B2AE">
        <Patch from="3.6.3.0" package="Always_Emitters.patch.3.6.3.0"/>
    </File>
    <File name="data/Always_Vehicles.dat" checksum="C6D4F6B3412C26065DE9B9F739BEC041B49FD613DB2686D8F231C2F692B263C5">
        <Patch from="3.6.4.0" package="Always_Vehicles.patch.3.6.4.0"/>
    </File>
    <File name="data/RA_TestUnits.mix" removedsince="3.6.4.1"/>
    <File name="data/RA_RidgeWar.mix" checksum="C3438C532C27F535CD958BEA9702160E952BC6CE58F9B43778F91DA23C6AE9FE" package="RA_RidgeWar"/>
    <File name="data/RA_SwampOfIllusions.mix" checksum="A0787979664E5977A1949587382A3A84B9F1526F81934EBB7A3AC9334F9D4059">
        <Patch from="3.6.4.0" package="RA_SwampOfIllusions.patch.3.6.4.0"/>
    </File>
</BHP_Game_Manifest>
```

## SPECIFICATION
### BHP_GAME_MANIFEST (Root Element)
* **GAME** - Unique Application ID
* **VERSION** - Application Unique Version for Build
* **TYPE** - Type of Build
  * **Full** - Full Build
  * **Patch** - Patch Build
* **BASEVERSION** - *OPTIONAL* Version this build was based upon 

### DEPENDENCY
* **NAME** - Package name of dependency sans file extension
* **REMOVEDSINCE** - _OPTIONAL_ No data. Not used anymore?

### FILE
* **NAME** - Name of file
* **CHECKSUM** - _OPTIONAL_ SHA256 hash of file
* **PACKAGE** - _OPTIONAL_ Package that contains this file. Not present on removed files or files that have been patched.
* **REMOVEDSINCE** - _OPTIONAL_ Version this package was removed in. If present, only _NAME_ and _REMOVEDSINCE_ will be present.
  * **PATCH**
    * **FROM** - Version that the file last changed
    * **PACKAGE** - Name of package that contains this file.