import 'dart:io';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Mod/CurseForge/ModPackHandler.dart';
import 'package:rpmlauncher/Model/Game/MinecraftVersion.dart';
import 'package:rpmlauncher/Screen/CurseForgeModPack.dart';
import 'package:rpmlauncher/Screen/FTBModPack.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:split_view/split_view.dart';

import '../main.dart';
import 'DownloadGameDialog.dart';

class _VersionSelectionState extends State<VersionSelection> {
  int _selectedIndex = 0;
  bool showRelease = true;
  bool showSnapshot = false;
  int chooseIndex = 0;
  TextEditingController versionsearchController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  String modLoaderName = I18n.format("version.list.mod.loader.vanilla");
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    versionsearchController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  late var borderColour = Colors.lightBlue;

  @override
  Widget build(BuildContext context) {
    _widgetOptions = <Widget>[
      SplitView(
        children: [
          FutureBuilder(
              future: Uttily.getVanillaVersionManifest(),
              builder: (BuildContext context,
                  AsyncSnapshot<MCVersionManifest> snapshot) {
                if (snapshot.hasData) {
                  List<MCVersion> versions = snapshot.data!.versions;
                  List<MCVersion> formatedVersions = [];
                  formatedVersions = versions.where((_version) {
                    bool inputVersionID =
                        _version.id.contains(versionsearchController.text);
                    switch (_version.type.name) {
                      case "release":
                        return showRelease && inputVersionID;
                      case "snapshot":
                        return showSnapshot && inputVersionID;
                      default:
                        return false;
                    }
                  }).toList();

                  return ListView.builder(
                      itemCount: formatedVersions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(formatedVersions[index].id),
                          tileColor: chooseIndex == index
                              ? Colors.white30
                              : Colors.white10,
                          onTap: () {
                            chooseIndex = index;
                            searchController.text =
                                formatedVersions[index].id.toString();
                            setState(() {});
                            if (File(join(
                                    GameRepository.getInstanceRootDir()
                                        .absolute
                                        .path,
                                    searchController.text,
                                    "instance.json"))
                                .existsSync()) {
                              borderColour = Colors.red;
                            }

                            showDialog(
                                context: context,
                                builder: (context) {
                                  return DownloadGameDialog(
                                    borderColour,
                                    searchController,
                                    formatedVersions[chooseIndex],
                                    ModLoaderUttily.getByIndex(ModLoaderUttily
                                        .i18nModLoaderNames
                                        .indexOf(modLoaderName)),
                                  );
                                });
                          },
                        );
                      });
                } else if (snapshot.hasError) {
                  return Text(snapshot.error.toString());
                } else {
                  return Center(child: RWLLoading());
                }
              }),
          Column(
            children: [
              SizedBox(height: 10),
              SizedBox(
                height: 45,
                width: 200,
                child: TextField(
                  controller: versionsearchController,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: I18n.format("version.list.filter"),
                  ),
                  onEditingComplete: () {
                    setState(() {});
                  },
                ),
              ),
              Text(
                I18n.format("version.list.mod.loader"),
                style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: modLoaderName,
                style: TextStyle(color: Colors.lightBlue),
                onChanged: (String? value) {
                  setState(() {
                    modLoaderName = value!;
                  });
                },
                items: ModLoaderUttily.i18nModLoaderNames
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value,
                        style: TextStyle(fontSize: 17.5, fontFamily: 'font')),
                  );
                }).toList(),
              ),
              Text(
                I18n.format("version.list.type"),
                style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
              ),
              ListTile(
                leading: Checkbox(
                  onChanged: (bool? value) {
                    setState(() {
                      showRelease = value!;
                    });
                  },
                  value: showRelease,
                ),
                title: Text(
                  I18n.format("version.list.show.release"),
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
              ListTile(
                leading: Checkbox(
                  onChanged: (bool? value) {
                    setState(() {
                      showSnapshot = value!;
                    });
                  },
                  value: showSnapshot,
                ),
                title: Text(
                  I18n.format("version.list.show.snapshot"),
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
        gripSize: 0,
        controller: SplitViewController(weights: [0.83]),
        viewMode: SplitViewMode.Horizontal,
      ),
      ListView(
        children: [
          Text(I18n.format('modpack.install'),
              style: TextStyle(fontSize: 30, color: Colors.lightBlue),
              textAlign: TextAlign.center),
          Text(I18n.format('modpack.sourse'),
              textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
          SizedBox(
            height: 12,
          ),
          Center(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 60,
                        height: 60,
                        child: Image.asset("images/CurseForge.png")),
                    SizedBox(
                      width: 12,
                    ),
                    Text(I18n.format('modpack.from.curseforge'),
                        style: TextStyle(fontSize: 20)),
                  ],
                ),
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (context) => CurseForgeModPack());
                },
              ),
              SizedBox(
                height: 12,
              ),
              InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 60,
                        height: 60,
                        child: Image.asset("images/FTB.png")),
                    SizedBox(
                      width: 12,
                    ),
                    Text(I18n.format('modpack.from.ftb'),
                        style: TextStyle(fontSize: 20)),
                  ],
                ),
                onTap: () {
                  showDialog(
                      context: context, builder: (context) => FTBModPack());
                },
              ),
              SizedBox(
                height: 12,
              ),
              InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                        backgroundColor: Colors.deepPurpleAccent,
                        onPressed: () {},
                        child: Icon(Icons.computer)),
                    SizedBox(
                      width: 12,
                    ),
                    Text(I18n.format('modpack.import'),
                        style: TextStyle(fontSize: 20)),
                  ],
                ),
                onTap: () async {
                  final file = await FileSelectorPlatform.instance
                      .openFile(acceptedTypeGroups: [
                    XTypeGroup(
                        label: I18n.format('modpack.file'),
                        extensions: ['zip']),
                  ]);

                  if (file == null) return;
                  showDialog(
                      context: context,
                      builder: (context) =>
                          CurseModPackHandler.setup(File(file.path)));
                },
              ),
            ],
          ))
        ],
      )
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text("請選擇安裝檔的類型"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          tooltip: I18n.format("gui.back"),
          onPressed: () {
            navigator.pop();
          },
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
              icon: SizedBox(
                  width: 30,
                  height: 30,
                  child: Image.asset("images/Minecraft.png")),
              label: 'Minecraft',
              tooltip: ''),
          BottomNavigationBarItem(
              icon: SizedBox(width: 30, height: 30, child: Icon(Icons.folder)),
              label: I18n.format('modpack.title'),
              tooltip: ''),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        onTap: _onItemTapped,
      ),
    );
  }
}

class VersionSelection extends StatefulWidget {
  @override
  _VersionSelectionState createState() => _VersionSelectionState();
}
