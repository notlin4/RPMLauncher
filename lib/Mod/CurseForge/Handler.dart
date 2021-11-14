import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;

class CurseForgeHandler {
  static Future<List<dynamic>> getModList(
      String versionID,
      String loader,
      TextEditingController search,
      List beforeModList,
      int index,
      int sort) async {
    String searchFilter = "";
    if (search.text.isNotEmpty) {
      searchFilter = "&searchFilter=${search.text}";
    }
    late List<dynamic> modList = beforeModList;

    final url = Uri.parse(
        "$curseForgeModAPI/addon/search?gameId=432&index=$index&pageSize=20&gameVersion=$versionID&modLoaderType=${getLoaderIndex(ModLoaderUttily.getByString(loader))}$searchFilter&sort=$sort");
    Response response = await get(url);
    List<dynamic> body = await json.decode(response.body.toString());

    /*
    過濾相同 [curseID]
    */

    body.forEach((mod) {
      if (!(beforeModList.any((mod_) => mod_["id"] == mod["id"]))) {
        modList.add(mod);
      }
    });
    return modList;
  }

  /// 4471 -> ModPack Section ID
  static Future<List<dynamic>> getModPackList(
      String versionID,
      TextEditingController search,
      List beforeList,
      int index,
      int sort) async {
    String gameVersion = versionID == I18n.format('modpack.all_version')
        ? ""
        : "&gameVersion=$versionID";
    String searchFilter = "";
    if (search.text.isNotEmpty) {
      searchFilter = "&searchFilter=${search.text}";
    }
    late List<dynamic> modPackList = beforeList;
    final url = Uri.parse(
        "$curseForgeModAPI/addon/search?categoryId=0&gameId=432&index=$index$gameVersion&pageSize=20$searchFilter&sort=$sort&sectionId=4471");
    Response response = await get(url);
    List<dynamic> body = await json.decode(response.body.toString());
    body.forEach((pack) {
      if (!(beforeList.any((pack_) => pack_["id"] == pack["id"]))) {
        modPackList.add(pack);
      }
    });
    return modPackList.toSet().toList();
  }

  static Future<List<String>> getMCVersionList() async {
    late List<String> versionList = [];

    final url = Uri.parse("$curseForgeModAPI/minecraft/version");
    Response response = await get(url);
    List<dynamic> body = await json.decode(response.body.toString());
    body.forEach((version) {
      versionList.add(version["versionString"]);
    });

    return versionList.toList();
  }

  static Future<String> getMCVersionMetaUrl(versionID) async {
    late String url;
    Response response =
        await get(Uri.parse("$curseForgeModAPI/minecraft/version"));
    List<dynamic> body = await json.decode(response.body.toString());
    body.forEach((version) {
      if (version["versionString"] == versionID) {
        url = version["jsonDownloadUrl"];
        return;
      }
    });
    return url;
  }

  static int getLoaderIndex(ModLoaders loader) {
    int index = 4;
    if (loader == ModLoaders.fabric) {
      index = 4;
    } else if (loader == ModLoaders.forge) {
      index = 1;
    }
    return index;
  }

  static Future<Map?> getFileInfoByVersion(int curseID, String versionID,
      String loader, int fileLoader, int fileID) async {
    final url = Uri.parse("$curseForgeModAPI/addon/$curseID/file/$fileID");
    Response response = await get(url);
    Map fileInfo = json.decode(response.body.toString());
    if (!(fileInfo["gameVersion"].any((element) => element == versionID) &&
        fileLoader == getLoaderIndex(ModLoaderUttily.getByString(loader)))) {
      return null;
    }
    return fileInfo;
  }

  static Future<Map> getFileInfo(curseID, fileID) async {
    final url = Uri.parse("$curseForgeModAPI/addon/$curseID/file/$fileID");
    Response response = await get(url);
    Map fileInfo = json.decode(response.body.toString());
    return fileInfo;
  }

  static Future<List> getAddonFilesByVersion(
      int curseID, String versionID, String loader, int fileLoader) async {
    final url = Uri.parse("$curseForgeModAPI/addon/$curseID/files");
    Response response = await get(url);
    List fileInfos = [];
    List<Map> body = json.decode(response.body.toString()).cast<Map>();
    body.forEach((fileInfo) {
      if (fileInfo["gameVersion"].any((element) => element == versionID) &&
          fileLoader == getLoaderIndex(ModLoaderUttily.getByString(loader))) {
        fileInfos.add(fileInfo);
      }
    });
    fileInfos.sort((a, b) =>
        DateTime.parse(a["fileDate"]).compareTo(DateTime.parse(b["fileDate"])));
    return fileInfos.reversed.toList();
  }

  static Future<dynamic> getAddonFiles(int curseID) async {
    final url = Uri.parse("$curseForgeModAPI/addon/$curseID/files");
    Response response = await get(url);
    List body = json.decode(response.body.toString());
    return body.reversed.toList();
  }

  static Text parseReleaseType(int releaseType) {
    late Text releaseTypeString;
    if (releaseType == 1) {
      releaseTypeString = Text(I18n.format("edit.instance.mods.release"),
          style: TextStyle(color: Colors.lightGreen));
    } else if (releaseType == 2) {
      releaseTypeString = Text(I18n.format("edit.instance.mods.beta"),
          style: TextStyle(color: Colors.lightBlue));
    } else if (releaseType == 3) {
      releaseTypeString = Text(I18n.format("edit.instance.mods.alpha"),
          style: TextStyle(color: Colors.red));
    }
    return releaseTypeString;
  }

  static Future<int> checkFingerPrint(File file) async {
    int curseID = 0;
    final response = await http.post(
      Uri.parse("$curseForgeModAPI/fingerprint"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode([Uttily.murmurhash2(file)]),
    );

    Map body = json.decode(response.body);
    if (body["exactMatches"].length >= 1) {
      //如果完全雜湊值匹配
      curseID = body["exactMatches"][0]["id"];
    }
    return curseID;
  }

  static Widget? getAddonIconWidget(List? data) {
    if (data != null && data.isNotEmpty) {
      return Image.network(
        data[0]["url"],
        width: 50,
        height: 50,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded.toInt() /
                    loadingProgress.expectedTotalBytes!.toInt()
                : null,
          );
        },
      );
    }
  }
}
