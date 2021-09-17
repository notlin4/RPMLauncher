import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:no_context_navigation/no_context_navigation.dart';
import 'package:rpmlauncher/Account/Account.dart';
import 'package:rpmlauncher/Screen/Edit.dart';
import 'package:rpmlauncher/Screen/MojangAccount.dart';
import 'package:rpmlauncher/Utility/Updater.dart';
import 'package:rpmlauncher/Widget/CheckDialog.dart';
import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:flutter/material.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:split_view/split_view.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Launcher/GameRepository.dart';
import 'Launcher/InstanceRepository.dart';
import 'LauncherInfo.dart';
import 'Screen/About.dart';
import 'Screen/Account.dart';
import 'Screen/RefreshMSToken.dart';
import 'Screen/Settings.dart';
import 'Screen/VersionSelection.dart';
import 'Utility/Config.dart';
import 'Utility/Loggger.dart';
import 'Utility/Theme.dart';
import 'Utility/i18n.dart';
import 'Utility/utility.dart';
import 'Widget/CheckAssets.dart';
import 'path.dart';

bool isInit = false;
late final Logger logger;

final NavigatorState navigator = NavigationService.navigationKey.currentState!;

class MainIntent extends Intent {}

class PushTransitions<T> extends MaterialPageRoute<T> {
  PushTransitions({required WidgetBuilder builder}) : super(builder: builder);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return new FadeTransition(opacity: animation, child: child);
  }
}

void main() async {
  await WidgetsFlutterBinding.ensureInitialized();
  await path().init();
  await i18n.init();
  logger = Logger();
  logger.send("Starting");
  runApp(LauncherHome());
  logger.send("Start Done");
}

class LauncherHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeCollection = ThemeCollection(themes: {
      ThemeUtility.toInt(Themes.Light): ThemeData(
          colorScheme: ColorScheme.fromSwatch(
              primarySwatch: MaterialColor(
            Color.fromRGBO(51, 51, 204, 1.0).value,
            <int, Color>{
              50: Color.fromRGBO(51, 51, 204, 1.0),
              100: Color.fromRGBO(51, 51, 204, 1.0),
              200: Color.fromRGBO(51, 51, 204, 1.0),
              300: Color.fromRGBO(51, 51, 204, 1.0),
              400: Color.fromRGBO(51, 51, 204, 1.0),
              500: Color.fromRGBO(51, 51, 204, 1.0),
              600: Color.fromRGBO(51, 51, 204, 1.0),
              700: Color.fromRGBO(51, 51, 204, 1.0),
              800: Color.fromRGBO(51, 51, 204, 1.0),
              900: Color.fromRGBO(51, 51, 204, 1.0),
            },
          )),
          scaffoldBackgroundColor: Color.fromRGBO(225, 225, 225, 1.0),
          fontFamily: 'font',
          textTheme: new TextTheme(
            bodyText1: new TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
                color: Color.fromRGBO(51, 51, 204, 1.0)),
          )),
      ThemeUtility.toInt(Themes.Dark): ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'font',
          textTheme: new TextTheme(
              bodyText1: new TextStyle(
            fontFeatures: [FontFeature.tabularFigures()],
          ))),
    });
    return DynamicTheme(
        themeCollection: themeCollection,
        defaultThemeId: ThemeUtility.toInt(Themes.Dark),
        builder: (context, theme) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorKey: NavigationService.navigationKey,
            title: LauncherInfo.getUpperCaseName(),
            theme: theme,
            home: HomePage(),
            shortcuts: <LogicalKeySet, Intent>{
              LogicalKeySet(LogicalKeyboardKey.escape): MainIntent(),
            },
            actions: <Type, Action<Intent>>{
              MainIntent:
                  CallbackAction<MainIntent>(onInvoke: (MainIntent intent) {
                if (navigator.canPop()) {
                  navigator.pop(true);
                }
              }),
            },
          );
        });
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static Directory LauncherFolder = dataHome;
  Directory InstanceRootDir = GameRepository.getInstanceRootDir();

  Future<List<FileSystemEntity>> GetInstanceList() async {
    var list = await InstanceRootDir.list().toList();
    return list;
  }

  late Future<List<FileSystemEntity>> InstanceList;

  @override
  void initState() {
    super.initState();
    InstanceList = GetInstanceList();
    InstanceRootDir.watch().listen((event) {
      InstanceList = GetInstanceList();
      setState(() {});
    });
  }

  String? choose;
  late String name;
  bool start = true;
  int chooseIndex = -1;

  @override
  Widget build(BuildContext context) {
    InstanceList = GetInstanceList();
    if (!isInit) {
      if (Config.getValue('init') == false) {
        Future.delayed(Duration.zero, () {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  StatefulBuilder(builder: (context, setState) {
                    return AlertDialog(
                        title: Text("快速設定", textAlign: TextAlign.center),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("歡迎您使用 RPMLauncher\n"),
                            i18n.SelectorWidget()
                          ],
                        ),
                        actions: [
                          OkClose(
                            onOk: () {
                              Config.change('init', true);
                            },
                          )
                        ]);
                  }));
        });
      } else {
        VersionTypes UpdateChannel =
            Updater.getVersionTypeFromString(Config.getValue('update_channel'));

        Updater.checkForUpdate(UpdateChannel).then((VersionInfo info) {
          if (info.needUpdate == true) {
            Future.delayed(Duration.zero, () {
              TextStyle _title = TextStyle(fontSize: 20);
              showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      StatefulBuilder(builder: (context, setState) {
                        return AlertDialog(
                            title: Text("更新 RPMLauncher",
                                textAlign: TextAlign.center),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SelectableText.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              "偵測到您的 RPMLauncher 版本過舊，您是否需要更新，我們建議您更新以獲得更佳體驗\n",
                                          style: TextStyle(fontSize: 18),
                                        ),
                                        TextSpan(
                                          text:
                                              "最新版本: ${info.version}.${info.versionCode}\n",
                                          style: _title,
                                        ),
                                        TextSpan(
                                          text:
                                              "目前版本: ${LauncherInfo.getVersion()}.${LauncherInfo.getVersionCode()}\n",
                                          style: _title,
                                        ),
                                        TextSpan(
                                          text: "變更日誌: \n",
                                          style: _title,
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                    toolbarOptions: ToolbarOptions(
                                        copy: true,
                                        selectAll: true,
                                        cut: true)),
                                Container(
                                    width:
                                        MediaQuery.of(context).size.width / 2,
                                    height:
                                        MediaQuery.of(context).size.height / 3,
                                    child: Markdown(
                                      selectable: true,
                                      styleSheet: MarkdownStyleSheet(
                                          textAlign: WrapAlignment.center,
                                          textScaleFactor: 1.5,
                                          h1Align: WrapAlignment.center,
                                          unorderedListAlign:
                                              WrapAlignment.center),
                                      data: info.changelog.toString(),
                                      onTapLink: (text, url, title) {
                                        if (url != null) {
                                          launch(url);
                                        }
                                      },
                                    ))
                              ],
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text("不要更新")),
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Updater.download(info, context);
                                  },
                                  child: Text("更新"))
                            ]);
                      }));
            });
          }
        });
      }

      isInit = true;
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        titleSpacing: 0.0,
        title: Row(
          children: <Widget>[
            FloatingActionButton(
                heroTag: null,
                backgroundColor: Colors.transparent,
                onPressed: () async {
                  await utility.OpenUrl(LauncherInfo.HomePageUrl);
                },
                child: Image.asset("images/Logo.png", scale: 4),
                tooltip: i18n.Format("homepage.website")),
            IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    PushTransitions(builder: (context) => SettingScreen()),
                  );
                },
                tooltip: i18n.Format("gui.settings")),
            IconButton(
              icon: Icon(Icons.folder),
              onPressed: () {
                utility.OpenFileManager(InstanceRootDir);
              },
              tooltip: i18n.Format("homepage.instance.folder.open"),
            ),
            IconButton(
                icon: Icon(Icons.info),
                onPressed: () {
                  Navigator.push(
                    context,
                    PushTransitions(builder: (context) => AboutScreen()),
                  );
                },
                tooltip: i18n.Format("homepage.about")),
            Flexible(
              child: Container(
                padding: EdgeInsets.all(410.0),
                child: Text(LauncherInfo.getUpperCaseName()),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.manage_accounts),
            onPressed: () {
              Navigator.push(
                context,
                PushTransitions(builder: (context) => AccountScreen()),
              );
            },
            tooltip: i18n.Format("account.title"),
          ),
        ],
      ),
      body: FutureBuilder(
        builder: (context, AsyncSnapshot<List<FileSystemEntity>> snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return SplitView(
                gripSize: 0,
                controller: SplitViewController(weights: [0.7]),
                children: [
                  Builder(
                    builder: (context) {
                      return GridView.builder(
                        itemCount: snapshot.data!.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 8),
                        physics: ScrollPhysics(),
                        itemBuilder: (context, index) {
                          var InstanceConfig = {};
                          try {
                            InstanceConfig = json.decode(
                                InstanceRepository.getInstanceConfigFile(
                                        snapshot.data![index].path)
                                    .readAsStringSync());
                          } on FileSystemException catch (err) {}
                          Color color = Colors.white10;
                          var photo;
                          try {
                            if (FileSystemEntity.typeSync(join(
                                    snapshot.data![index].path, "icon.png")) !=
                                FileSystemEntityType.notFound) {
                              photo = Image.file(File(join(
                                  snapshot.data![index].path, "icon.png")));
                            } else {
                              photo = Icon(Icons.image);
                            }
                          } on FileSystemException catch (err) {}
                          if ((snapshot.data![index].path.replaceAll(
                                      join(LauncherFolder.absolute.path,
                                          "instances"),
                                      "")) ==
                                  choose ||
                              start == true) {
                            color = Colors.white30;
                            chooseIndex = index;
                            start = false;
                          }
                          return Card(
                            color: color,
                            child: InkWell(
                              splashColor: Colors.blue.withAlpha(30),
                              onTap: () {
                                choose = snapshot.data![index].path.replaceAll(
                                    join(LauncherFolder.absolute.path,
                                        "instances"),
                                    "");
                                setState(() {});
                              },
                              child: GridTile(
                                child: Column(
                                  children: [
                                    Expanded(child: photo),
                                    Text(
                                        InstanceConfig["name"] ??
                                            "Name not found",
                                        textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  Builder(builder: (context) {
                    if (chooseIndex == -1) {
                      return Container();
                    } else {
                      return Builder(
                        builder: (context) {
                          Widget photo;
                          var InstanceConfig = {};
                          if ((snapshot.data!.length - 1) < chooseIndex)
                            return Container();
                          var ChooseIndexPath =
                              snapshot.data![chooseIndex].path;
                          try {
                            InstanceConfig = json.decode(
                                InstanceRepository.getInstanceConfigFile(
                                        ChooseIndexPath)
                                    .readAsStringSync());
                          } on FileSystemException catch (err) {}
                          if (FileSystemEntity.typeSync(
                                  join(ChooseIndexPath, "icon.png")) !=
                              FileSystemEntityType.notFound) {
                            photo = Image.file(
                                File(join(ChooseIndexPath, "icon.png")));
                          } else {
                            photo = const Icon(
                              Icons.image,
                              size: 100,
                            );
                          }

                          return Column(
                            children: [
                              Container(
                                child: photo,
                                width: 200,
                                height: 160,
                              ),
                              Text(InstanceConfig["name"] ?? "Name not found",
                                  textAlign: TextAlign.center),
                              SizedBox(height: 12),
                              TextButton(
                                  onPressed: () async {
                                    if (account.getCount() == 0) {
                                      return showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (context) => AlertDialog(
                                            title: Text(
                                                i18n.Format('gui.error.info')),
                                            content: Text(
                                                i18n.Format('account.null')),
                                            actions: [
                                              ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      PushTransitions(
                                                          builder: (context) =>
                                                              AccountScreen()),
                                                    );
                                                  },
                                                  child: Text(
                                                      i18n.Format('gui.login')))
                                            ]),
                                      );
                                    }
                                    Map Account =
                                        account.getByIndex(account.getIndex());
                                    showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (context) => FutureBuilder(
                                            future: utility.ValidateAccount(
                                                Account),
                                            builder: (context,
                                                AsyncSnapshot snapshot) {
                                              if (snapshot.hasData) {
                                                if (!snapshot.data) {
                                                  //如果帳號已經過期
                                                  return AlertDialog(
                                                      title: Text(i18n.Format(
                                                          'gui.error.info')),
                                                      content: Text(i18n.Format(
                                                          'account.expired')),
                                                      actions: [
                                                        ElevatedButton(
                                                            onPressed: () {
                                                              if (Account[
                                                                      'Type'] ==
                                                                  account
                                                                      .Microsoft) {
                                                                showDialog(
                                                                    barrierDismissible:
                                                                        false,
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (context) =>
                                                                            RefreshMsTokenScreen());
                                                              } else if (Account[
                                                                      'Type'] ==
                                                                  account
                                                                      .Mojang) {
                                                                showDialog(
                                                                    barrierDismissible:
                                                                        false,
                                                                    context:
                                                                        context,
                                                                    builder: (context) =>
                                                                        MojangAccount(
                                                                            AccountEmail:
                                                                                Account["Account"]));
                                                              }
                                                            },
                                                            child: Text(i18n.Format(
                                                                'account.again')))
                                                      ]);
                                                } else {
                                                  return utility.JavaCheck(
                                                      InstanceConfig:
                                                          InstanceConfig,
                                                      hasJava: Builder(
                                                          builder: (context) =>
                                                              CheckAssetsScreen(
                                                                  InstanceDir:
                                                                      Directory(
                                                                          ChooseIndexPath))));
                                                }
                                              } else {
                                                return Center(
                                                    child:
                                                        CircularProgressIndicator());
                                              }
                                            }));
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.play_arrow,
                                      ),
                                      SizedBox(width: 5),
                                      Text(i18n.Format("gui.instance.launch")),
                                    ],
                                  )),
                              SizedBox(height: 12),
                              TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        PushTransitions(
                                            builder: (context) => EditInstance(
                                                  InstanceRepository
                                                          .getInstanceDir(snapshot
                                                              .data![
                                                                  chooseIndex]
                                                              .path)
                                                      .absolute
                                                      .path,
                                                )));
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.edit,
                                      ),
                                      SizedBox(width: 5),
                                      Text(i18n.Format("gui.edit")),
                                    ],
                                  )),
                              SizedBox(height: 12),
                              TextButton(
                                  onPressed: () {
                                    if (InstanceRepository.getInstanceConfigFile(
                                            "${ChooseIndexPath} (${i18n.Format("gui.copy")})")
                                        .existsSync()) {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: Text(
                                                i18n.Format("gui.copy.failed")),
                                            content: Text(
                                                "Can't copy file because file already exists"),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                    i18n.Format("gui.confirm")),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    } else {
                                      copyPathSync(
                                          join(InstanceRootDir.absolute.path,
                                              ChooseIndexPath),
                                          InstanceRepository.getInstanceDir(
                                                  "${ChooseIndexPath} (${i18n.Format("gui.copy")})")
                                              .absolute
                                              .path);
                                      var NewInstanceConfig = json.decode(
                                          InstanceRepository.getInstanceConfigFile(
                                                  "${ChooseIndexPath} (${i18n.Format("gui.copy")})")
                                              .readAsStringSync());
                                      NewInstanceConfig["name"] =
                                          NewInstanceConfig["name"] +
                                              "(${i18n.Format("gui.copy")})";
                                      InstanceRepository.getInstanceConfigFile(
                                              "${ChooseIndexPath} (${i18n.Format("gui.copy")})")
                                          .writeAsStringSync(
                                              json.encode(NewInstanceConfig));
                                      setState(() {});
                                    }
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.content_copy,
                                      ),
                                      SizedBox(width: 5),
                                      Text(i18n.Format("gui.copy")),
                                    ],
                                  )),
                              SizedBox(height: 12),
                              TextButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return CheckDialog(
                                          title: i18n.Format(
                                              "gui.instance.delete"),
                                          content: i18n.Format(
                                              'gui.instance.delete.tips'),
                                          onPressedOK: () {
                                            Navigator.of(context).pop();
                                            InstanceRepository.getInstanceDir(
                                                    snapshot.data![chooseIndex]
                                                        .path)
                                                .deleteSync(recursive: true);
                                          },
                                        );
                                      },
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.delete,
                                      ),
                                      SizedBox(width: 5),
                                      Text(i18n.Format("gui.delete")),
                                    ],
                                  )),
                            ],
                          );
                        },
                      );
                    }
                  }),
                ],
                viewMode: SplitViewMode.Horizontal);
          } else {
            return Transform.scale(
                child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                      Icon(
                        Icons.today,
                      ),
                      Text(i18n.Format("homepage.instance.found")),
                      Text(i18n.Format("homepage.instance.found.tips"))
                    ])),
                scale: 2);
          }
        },
        future: InstanceList,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          Navigator.push(
            context,
            PushTransitions(builder: (context) => new VersionSelection()),
          );
        },
        tooltip: i18n.Format("version.list.instance.add"),
        child: Icon(Icons.add),
      ),
    );
  }
}
