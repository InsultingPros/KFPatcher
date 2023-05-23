class TestCast extends Object;

public final static function TestNativeCasts(Level Level) {
    // TestNetDriver(Level);
    // TestExporter(Level);
    TestFileConnection(Level);
}

public final static function GetPackageMapInfo(Level Level) {
    local ULevelCast ULevelCast;
    local ULevel ULevel;
    local UNetDriver UNetDriver;

    ULevelCast = new() class'ULevelCast';
    ULevel = ULevelCast.Cast(Level);
    UNetDriver = ULevel.NetDriver;
    warn("package map size: " $ UNetDriver.MasterMap.List.Length);
}

private final static function TestFileConnection(Level Level) {
    local UNetDriverCast UNetDriverCast;
    local UNetDriver UNetDriver;
    local UNetConnection UNetConnection;
    local UChannel UChannel;
    local UFileChannel UFileChannel;
    local UFileChannelCast UFileChannelCast;
    local object obj;

    foreach level.allObjects(class'object', obj) {
        if (obj.IsA('NetDriver')) {
            warn("GOTCHA NetDriver!");
            break;
        }
    }

    UNetDriverCast = new() class'UNetDriverCast';
    UNetDriver = UNetDriverCast.Cast(NetDriver(obj));

    warn("ClientConnections.length=" $ UNetDriver.ClientConnections.length);
    UNetConnection = UNetDriver.ClientConnections[0];

    UFileChannelCast = new() class'UFileChannelCast';
    UChannel = UNetConnection.GetChannel(0);
    UFileChannel = UFileChannelCast.Cast(UChannel);
    warn("UFileChannel status: " $ UFileChannel != none);
    warn(UFileChannel.SendFileAr);
    warn(UFileChannel.PackageIndex);
    warn(UFileChannel.SentData);
}

private final static function TestNetDriver(Level Level) {
    local UNetDriverCast UNetDriverCast;
    local UNetDriver UNetDriver;
    local UPackageMap UPackageMap;
    local object obj;
    local bool bFound;
    local int i;
    // local ULevelCast ULevelCast;
    // local ULevel ULevel;
    // local UNetConnection.FURL FURL;

    // method #1
    // ULevelCast = new() class'ULevelCast';
    // ULevel = ULevelCast.Cast(Level);
    // warn("ULevel is: " $ ULevel != none);
    // log(ULevel.Actors.Length);
    // for (i = 0; i < ULevel.Actors.length; i++) {
    //     log(i $ ". " $ ULevel.Actors[i]);
    // }
    // FURL = ULevel.URL;
    // log("FURL.Protocol: " $ FURL.Protocol);
    // log("FURL.Host: " $ FURL.Host);
    // log("FURL.Port: " $ FURL.Port);
    // log("FURL.Map: " $ FURL.Map);
    // log("FURL.Op.Length: " $ FURL.Op.length);
    // for (i = 0; i < FURL.Op.length; i++) {
    //     log(i $ ". option - " $ FURL.Op[i]);
    // }
    // log("FURL.Portal: " $ FURL.Portal);
    // log("FURL.Valid: " $ FURL.Valid);

    // UNetDriver = ULevel.NetDriver;

    // method #2
    foreach level.allObjects(class'object', obj) {
        if (obj.IsA('NetDriver')) {
            warn("GOTCHA NetDriver!");
            bFound = true;
            break;
        }
    }

    warn("START test netdriver");

    log("creating UNetDriverCaster");
    UNetDriverCast = new() class'UNetDriverCast';
    log("casting UNetDriver");
    UNetDriver = UNetDriverCast.Cast(NetDriver(obj));
    log("getting UPackageMap");
    UPackageMap = UNetDriver.MasterMap;
    log("UPackageMap.List length: " $ UPackageMap.List.Length);

    for (i = 0; i < UPackageMap.List.length; i++) {
        log(i $ ". package - " $ UPackageMap.List[i].Parent.name);
    }
    log("client connections: " $ UNetDriver.ClientConnections.length);
    warn("END test netdriver");
    UPackageMap.List.length = 0;
}

private final static function TestExporter(Level Level) {
    // local UExporterCast UExporterCast;
    // local class<UExporter> UExporter;
    // local Commandlet CMD;
    // local object obj;

    // foreach level.allObjects(class'object', obj)
    // {
    //     if (obj.IsA('Exporter'))
    //     {
    //         warn("QQQQQQQQQQQ GOTCHA Exporter!");
    //         break;
    //     }
    // }

    // UExporterCast = new() class'UExporterCast';
    // UExporter = UExporterCast.Cast(class(DynamicLoadObject("Editor.SoundExporterWAV", class'Class')));

    // warn("UExporter is: " $ UExporter != none);
    // warn(UExporter.default.SupportedClass);
    // // warn(UExporter.Extension.length);
    // warn(UExporter.default.Extension[0]);
    // // warn(UExporter.Extension[1]);
    // UExporter.default.Extension[0] = "DLL";
    // warn(UExporter.default.Extension[0]);

    // warn(UExporter.default.TextIndent);
    // warn(UExporter.default.bText);
    // warn(UExporter.default.bSelectedOnly);

    // CMD = new (None) Class<Commandlet>(DynamicLoadObject("Editor.BatchExportCommandlet", class'Class'));
	// CMD.Main("MusicLoaderDLL.u Sound dll ");
}