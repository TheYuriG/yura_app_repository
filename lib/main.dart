import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';

import 'package:web_scraper/web_scraper.dart';

//! This project assumes you are using VS Code and have the Todo Tree extension installed.
void main() async {
  //? Initializes flutter depending on proper platform
  await Hive.initFlutter();
  //? Open database with proper settings
  await Hive.openBox("settings").then((box) {
    if (box.get("language") == null) {
      //? Sets default language as english
      box.put("language", "en-us");
      //? Sets default theme as pink. This is later use to pull the color schemes from "Map getColors"
      box.put("theme", 'pink');
    }
  });
  runApp(MyApp());
}

//? Scraper for PSN Profiles
final WebScraper psnp = WebScraper("https://psnprofiles.com/");
//? Scraper for PSN Trophy Leaders
final WebScraper psntl = WebScraper("https://psntrophyleaders.com/");
//? Scraper for True Trophies
final WebScraper tt = WebScraper("https://www.truetrophies.com/");
//? Scraper for Exophase
final WebScraper exo = WebScraper("https://www.exophase.com/");

//? This will make a request to PSNProfiles to retrieve a small clickable profile card
Future<Map> psnpInfo(String user) async {
  await psnp.loadWebPage('/$user');
  Map<String, dynamic> parsedData = {};
  //? Retrieves PSN ID
  psnp.getElement('#user-bar > ul > div > div.grow > div:nth-child(1) > span',
      []).forEach((element) {
    parsedData['psnID'] = element['title'].trim();
  });
  //? Retrieves About Me
  psnp.getElement('#user-bar > ul > div > div.grow > div > span.comment',
      []).forEach((element) {
    parsedData['about'] = element['title'];
  });
  //? Retrieves avatar
  psnp.getElement('#user-bar > div.avatar > div > img', ['src']).forEach(
      (element) {
    parsedData['avatar'] = element['attributes']['src'];
  });
  //? Retrieves country
  psnp.getElement('img#bar-country', ['class']).forEach((element) {
    parsedData['country'] = element['attributes']['class'].split(" ")[1];
  });
  //? Retrieves PSN Level
  psnp.getElement('#bar-level > ul > li.icon-sprite.level', []).forEach(
      (element) {
    parsedData['level'] = element['title'];
  });
  //? Retrieves PSN Level progress
  psnp.getElement('#bar-level > div > div', ['style']).forEach((element) {
    parsedData['levelProgress'] =
        element['attributes']['style'].split(" ")[1].split(";")[0];
  });
  //? Retrieves Total trophies
  psnp.getElement('#user-bar > ul > div > div > li.total', []).forEach(
      (element) {
    parsedData['total'] = element['title'].trim();
  });
  //? Retrieves bronze trophies
  psnp.getElement('#user-bar > ul > div > div > li.bronze', []).forEach(
      (element) {
    parsedData['bronze'] = element['title'].trim();
  });
  //? Retrieves silver trophies
  psnp.getElement('#user-bar > ul > div > div > li.silver', []).forEach(
      (element) {
    parsedData['silver'] = element['title'].trim();
  });
  //? Retrieves gold trophies
  psnp.getElement('#user-bar > ul > div > div > li.gold', []).forEach(
      (element) {
    parsedData['gold'] = element['title'].trim();
  });
  //? Retrieves platinum trophies
  psnp.getElement('#user-bar > ul > div > div > li.platinum', []).forEach(
      (element) {
    parsedData['platinum'] = element['title'].trim();
  });
  if (parsedData.isEmpty) {
    parsedData['psnpError'] = true;
  }
  // print(parsedData);
  return parsedData;
}

//? This class is created so the search for a profile can wait until the user stops typing.
class Debouncer {
  final int milliseconds;
  VoidCallback action;
  Timer _timer;

  Debouncer({this.milliseconds});

  run(VoidCallback action) {
    if (null != _timer) {
      _timer.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

//? ALl image assets are declared in this Map so they can be easily referenced on Image.asset() functions
Map<String, String> img = {
  "oldLevel": "assets/ps_old_level.png",
  "bronze1": "assets/bronzelevel1.png",
  "bronze2": "assets/bronzelevel2.png",
  "bronze3": "assets/bronzelevel3.png",
  "silver1": "assets/silverlevel1.png",
  "silver2": "assets/silverlevel2.png",
  "silver3": "assets/silverlevel3.png",
  "gold1": "assets/goldlevel1.png",
  "gold2": "assets/goldlevel2.png",
  "gold3": "assets/goldlevel3.png",
  "platinumlevel": "assets/platinumlevel.png",
  "bronzeOut": "assets/bronze_outline.png",
  "bronzeFill": "assets/bronze_fill.png",
  "silverOut": "assets/silver_outline.png",
  "silverFill": "assets/silver_fill.png",
  "goldOut": "assets/gold_outline.png",
  "goldFill": "assets/gold_fill.png",
  "platOut": "assets/platinum_outline.png",
  "platFill": "assets/platinum_fill.png",
  "ps": "assets/playstation.png",
  "allTrophies": "trophy_cluster.png",
  "r1": "assets/rarity1.png",
  "r2": "assets/rarity2.png",
  "r3": "assets/rarity3.png",
  "r4": "assets/rarity4.png",
  "r5": "assets/rarity5.png",
  "r6": "assets/rarity6.png",
  "r7": "assets/rarity7.png",
  "ps3": "assets/ps3.png",
  "ps4": "assets/ps4.png",
  "ps5": "assets/ps5.png",
  "psv": "assets/psv.png",
};

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //? Desativa o banner de debug
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  // MyHomePage({Key key, this.title}) : super(key: key);
  // final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    //? This will save the settings for the app in this Hive box
    //? Examples of settings saved are the theme colors and language.
    Box settings = Hive.box("settings");

    //? The Debouncer (class created above) is now instantiated here so the search is delayed until the user stops typing.
    Debouncer debounce = Debouncer(milliseconds: 800);

    //? This will translate Yura to the languages avaiable. This can be changed on the settings wheel
    Map regionSelect() {
      //? By default, this loads Yura in English. This is done so new updates can be released without needing
      //? to wait for updated translation. Yura will use english text on those new features while a language patch isn't done
      Map<String, Map<String, String>> avaiableText = {
        "home": {
          "appBar": "Welcome to Yura - A Playstation-based trophy app!",
          "inputID": "Please, provide your PSN ID:",
          "IDhere": "PSN ID goes here...",
          "removePSN": "Remove the saved PSN ID?",
          "settings": "Settings",
          "supportedWebsites": "Avaiable websites:",
          "languagePicker": "Change Yura's language:",
          "themePicker": "Change Yura's theme:",
          'refresh': "Refresh trophy data",
          "pink": "Wednesday",
          "orange": "Nature's Will",
          "blue": "Deep Ocean",
          "black": "Before Dawn"
        }
      };
      //? This changes language to Brazilian Portuguese
      if (settings.get("language") == "pt-br") {
        avaiableText["home"] = {
          "appBar":
              "Bem vindo a Yura - Um aplicativo para troféus Playstation!",
          "inputID": "Por favor, informe sua ID PSN:",
          "IDhere": "ID da PSN vai aqui...",
          "removePSN": "Remover a ID PSN salva?",
          "settings": "Configurações",
          "supportedWebsites": "Sites disponíveis:",
          "languagePicker": "Mude o idioma de Yura:",
          "themePicker": "Mude o tema de Yura:",
          'refresh': "Atualizar informação de troféus",
          "pink": "Quarta-Feira",
          "orange": "Desejo da Natureza",
          "blue": "Oceano Profundo",
          "black": "Antes do Amanhecer"
        };
      }
      return avaiableText;
    }

    Map<String, Map<String, Color>> themeSelector = {
      "primary": {
        "pink": Colors.pink[300],
        "black": Colors.black87,
        "blue": Colors.blueAccent[700],
        "orange": Colors.orange[900],
      },
      "secondary": {
        "pink": Colors.pink[50],
        "black": Colors.indigo[100],
        "blue": Colors.blue[100],
        "orange": Colors.red[100],
      }
    };
    Map<String, Map<String, String>> regionalText = regionSelect();

    //? Option for light text
    TextStyle textLight = TextStyle(
      color: themeSelector["secondary"][settings.get("theme")],
    );
    //? Option for dark text
    TextStyle textDark = TextStyle(
      color: themeSelector["primary"][settings.get("theme")],
    );

    TextStyle textDarkBold = TextStyle(
        color: themeSelector["primary"][settings.get("theme")],
        fontSize: 20,
        fontWeight: FontWeight.bold);

    BoxDecoration boxDeco() => BoxDecoration(
          color: themeSelector["secondary"][settings.get("theme")],
          borderRadius: BorderRadius.all(Radius.circular(15)),
          border: Border.all(
              color: themeSelector["primary"][settings.get("theme")], width: 5),
        );

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            regionalText["home"]["appBar"],
            style: textLight,
          ),
          backgroundColor: themeSelector["primary"][settings.get("theme")],
          //? This instantiate the settings box.
          actions: [
            Tooltip(
              message: regionalText["home"]["settings"],
              child: IconButton(
                  icon: Icon(
                    Icons.settings,
                    size: 20,
                    color: themeSelector["secondary"][settings.get("theme")],
                  ),
                  onPressed: () => showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          titlePadding: EdgeInsets.all(0),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20.0))),
                          contentPadding: EdgeInsets.all(0),
                          content: ConstrainedBox(
                            constraints: BoxConstraints.loose(
                              Size(
                                //? Limita o tamanho da caixa de configurações para 60% do tamanho da tela
                                MediaQuery.of(context).size.width * 0.6,
                                MediaQuery.of(context).size.height * 0.6,
                              ),
                            ),
                            child: Container(
                              color: themeSelector["secondary"]
                                  [settings.get("theme")],
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppBar(
                                    title: Text(
                                      regionalText["home"]["settings"],
                                      style: textLight,
                                    ),
                                    centerTitle: true,
                                    automaticallyImplyLeading: false,
                                    backgroundColor: themeSelector["primary"]
                                        [settings.get("theme")],
                                  ),
                                  //? Permite que o usuário troque o idioma do aplicativo.
                                  //? O usuário não verá a opção de trocar para o mesmo idioma que estiver ativo
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Center(
                                      child: Text(
                                        regionalText["home"]["languagePicker"],
                                        style: textDark,
                                      ),
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 5,
                                    children: [
                                      if (settings.get('language') != "pt-br")
                                        Tooltip(
                                          message: 'Português - Brasil',
                                          child: MaterialButton(
                                              hoverColor: Colors.transparent,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              child: Image.network(
                                                  "https://psntrophyleaders.com/images/countries/br_large.png",
                                                  height: 50),
                                              onPressed: () => {
                                                    setState(() {
                                                      settings.put(
                                                          'language', 'pt-br');
                                                    }),
                                                    Navigator.pop(context)
                                                  }),
                                        ),
                                      if (settings.get('language') != "en-us")
                                        Tooltip(
                                          message:
                                              "English - United States of America",
                                          child: MaterialButton(
                                              hoverColor: Colors.transparent,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              child: Image.network(
                                                  "https://psntrophyleaders.com/images/countries/us_large.png",
                                                  height: 50),
                                              onPressed: () => {
                                                    setState(() {
                                                      settings.put(
                                                          'language', 'en-us');
                                                    }),
                                                    Navigator.pop(context)
                                                  }),
                                        ),
                                    ],
                                  ),
                                  //? Permite que o usuário troque o tema do aplicativo.
                                  //? O usuário não verá a opção de trocar para o mesmo tema que estiver ativo
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Center(
                                      child: Text(
                                        regionalText["home"]["themePicker"],
                                        style: textDark,
                                      ),
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 5,
                                    children: [
                                      if (settings.get('theme') != "pink")
                                        Tooltip(
                                          message: regionalText["home"]["pink"],
                                          child: MaterialButton(
                                              hoverColor: Colors.transparent,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 25,
                                                    height: 50,
                                                    color:
                                                        themeSelector["primary"]
                                                            ["pink"],
                                                  ),
                                                  Container(
                                                    width: 25,
                                                    height: 50,
                                                    color: themeSelector[
                                                        "secondary"]["pink"],
                                                  )
                                                ],
                                              ),
                                              onPressed: () => {
                                                    setState(() {
                                                      settings.put(
                                                          'theme', 'pink');
                                                    }),
                                                    Navigator.pop(context)
                                                  }),
                                        ),
                                      if (settings.get('theme') != "orange")
                                        Tooltip(
                                          message: regionalText["home"]
                                              ["orange"],
                                          child: MaterialButton(
                                              hoverColor: Colors.transparent,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 25,
                                                    height: 50,
                                                    color:
                                                        themeSelector["primary"]
                                                            ["orange"],
                                                  ),
                                                  Container(
                                                    width: 25,
                                                    height: 50,
                                                    color: themeSelector[
                                                        "secondary"]["orange"],
                                                  )
                                                ],
                                              ),
                                              onPressed: () => {
                                                    setState(() {
                                                      settings.put(
                                                          'theme', 'orange');
                                                    }),
                                                    Navigator.pop(context)
                                                  }),
                                        ),
                                      if (settings.get('theme') != "blue")
                                        Tooltip(
                                          message: regionalText["home"]["blue"],
                                          child: MaterialButton(
                                              hoverColor: Colors.transparent,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 25,
                                                    height: 50,
                                                    color:
                                                        themeSelector["primary"]
                                                            ["blue"],
                                                  ),
                                                  Container(
                                                    width: 25,
                                                    height: 50,
                                                    color: themeSelector[
                                                        "secondary"]["blue"],
                                                  )
                                                ],
                                              ),
                                              onPressed: () => {
                                                    setState(() {
                                                      settings.put(
                                                          'theme', 'blue');
                                                    }),
                                                    Navigator.pop(context)
                                                  }),
                                        ),
                                      if (settings.get('theme') != "black")
                                        Tooltip(
                                          message: regionalText["home"]
                                              ["black"],
                                          child: MaterialButton(
                                              hoverColor: Colors.transparent,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 25,
                                                    height: 50,
                                                    color:
                                                        themeSelector["primary"]
                                                            ["black"],
                                                  ),
                                                  Container(
                                                    width: 25,
                                                    height: 50,
                                                    color: themeSelector[
                                                        "secondary"]["black"],
                                                  )
                                                ],
                                              ),
                                              onPressed: () => {
                                                    setState(() {
                                                      settings.put(
                                                          'theme', 'black');
                                                    }),
                                                    Navigator.pop(context)
                                                  }),
                                        ),
                                    ],
                                  ),
                                  if (settings.get("psnID") != null)
                                    Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Center(
                                        child: Text(
                                          regionalText["home"]["removePSN"],
                                          style: textDark,
                                        ),
                                      ),
                                    ),
                                  if (settings.get("psnID") != null)
                                    RawMaterialButton(
                                      hoverColor: Colors.transparent,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      child: Icon(
                                        Icons.delete,
                                        color: themeSelector["primary"]
                                            [settings.get("theme")],
                                        size: 50,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          settings.delete("psnID");
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      })),
            )
          ],
        ),
        body: Center(
          child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    stops: [
                  0,
                  0.25,
                  0.75,
                  1
                ],
                    colors: [
                  Colors.white,
                  themeSelector["secondary"][settings.get("theme")],
                  themeSelector["secondary"][settings.get("theme")],
                  Colors.white
                ])),
            width: MediaQuery.of(context).size.width,
            child: Column(
              //? Max main axis size to use the entire avaiable soace left from the appBar and Safe Area.
              mainAxisSize: MainAxisSize.max,
              //? Using spaceBetween as alignment so i can have the Translation / Discord buttons and
              //?version to always display on the bottom. An empry SizedBox is created at the start of the
              //? widget's list to space out properly
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(),
                if (settings.get("psnID") == null)
                  Column(
                    children: [
                      //? If user doesn't have a set PSN ID, display the fields for them to input one.
                      Text(regionalText['home']['inputID'],
                          style: textDarkBold),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: TextFormField(
                            decoration: InputDecoration(
                                hintText: regionalText['home']['IDhere']),
                            textAlign: TextAlign.center,
                            autocorrect: false,
                            autofocus: true,
                            onChanged: (text) {
                              debounce.run(() {
                                //! Perform search here later to validate the ID provided
                                setState(() {
                                  psnpInfo(text);
                                  settings.put('psnID', text);
                                });
                              });
                            }),
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      //? Spaces for PSNProfiles and PSN Trophy Leaders
                      Text(
                        regionalText['home']['supportedWebsites'],
                        style: textDarkBold,
                      ),
                      //? Spaces for True Trophies and Exophase
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 50,
                              width: 200,
                              decoration: boxDeco(),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Image.network(
                                      "https://psnprofiles.com/favicon.ico",
                                      scale: 0.4,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Text(
                                      "PSNProfiles",
                                      style: textDark,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Container(
                              height: 50,
                              width: 200,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5)),
                                border: Border.all(
                                    color: themeSelector["primary"]
                                        [settings.get("theme")],
                                    width: 3),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Image.network(
                                      "https://psntl.com/favicon.ico",
                                      scale: 0.4,
                                      // scale: 2,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Text(
                                      "PSN Trophy Leaders",
                                      style: textDark,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 50,
                              width: 200,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5)),
                                border: Border.all(
                                    color: themeSelector["primary"]
                                        [settings.get("theme")],
                                    width: 3),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Image.network(
                                      "https://truetrophies.com/favicon.ico",
                                      scale: 0.4,
                                      // scale: 2,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Text(
                                      "True Trophies",
                                      style: textDark,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Container(
                              height: 50,
                              width: 200,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5)),
                                border: Border.all(
                                    color: themeSelector["primary"]
                                        [settings.get("theme")],
                                    width: 3),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Image.network(
                                      "https://www.exophase.com/assets/zeal/_icons/favicon.ico",
                                      scale: 0.4,
                                      // scale: 2,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Text(
                                      "Exophase",
                                      style: textDark,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                if (settings.get("psnID") != null)
                  Expanded(
                    child: ListView(
                      children: [
                        Container(
                          margin: EdgeInsets.all(15),
                          padding: EdgeInsets.all(15),
                          width: MediaQuery.of(context).size.width,
                          height: 200,
                          decoration: boxDeco(),
                          child: FutureBuilder(
                            future: psnpInfo(settings.get("psnID")),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.data['psnpError'] != true) {
                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        //? Avatar PSN Profiles
                                        Image.network(
                                          snapshot.data['avatar'],
                                          height: 100,
                                        ),
                                        //? Column with PSN ID, About Me (on hover), trophy count
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            //? COuntry flag and PSN ID
                                            Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  //? Country flag using PSNTL's large flags
                                                  Image.network(
                                                      "https://psntrophyleaders.com/images/countries/${snapshot.data['country']}_large.png",
                                                      height: 20),
                                                  SizedBox(
                                                    width: 10,
                                                  ),
                                                  Tooltip(
                                                    message: snapshot
                                                            .data['about'] ??
                                                        snapshot.data['psnID'],
                                                    child: Text(
                                                        snapshot.data["psnID"],
                                                        style: textDarkBold),
                                                  )
                                                ]),
                                            SizedBox(),
                                            Text(
                                                "${snapshot.data['level']} (${snapshot.data['levelProgress']})",
                                                style: textDark),
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    //Image.asset(platinum),
                                                    Text(
                                                      snapshot.data['platinum'],
                                                      style: textDark,
                                                    )
                                                  ],
                                                ),
                                                SizedBox(
                                                  width: 20,
                                                ),
                                                Row(
                                                  children: [
                                                    //Image.asset(gold),
                                                    Text(
                                                      snapshot.data['gold'],
                                                      style: textDark,
                                                    )
                                                  ],
                                                ),
                                                SizedBox(
                                                  width: 20,
                                                ),
                                                Row(
                                                  children: [
                                                    //Image.asset(silver),
                                                    Text(
                                                      snapshot.data['silver'],
                                                      style: textDark,
                                                    )
                                                  ],
                                                ),
                                                SizedBox(
                                                  width: 20,
                                                ),
                                                Row(
                                                  children: [
                                                    //Image.asset(bronze),
                                                    Text(
                                                      snapshot.data['bronze'],
                                                      style: textDark,
                                                    )
                                                  ],
                                                ),
                                                SizedBox(
                                                  width: 20,
                                                ),
                                                Row(
                                                  children: [
                                                    //Image.asset(total),
                                                    Text(
                                                      snapshot.data['total'],
                                                      style: textDark,
                                                    )
                                                  ],
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                      ],
                                    )
                                  ],
                                );
                              } else if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.data['psnpError'] == true) {
                                settings.put('psnp', false);
                                return Row(
                                  children: [
                                    Icon(
                                      Icons.error,
                                      color: themeSelector["primary"]
                                          [settings.get("theme")],
                                      size: 30,
                                    ),
                                    Text(
                                      "PSNProfiles",
                                      style: textDarkBold,
                                    )
                                  ],
                                );
                              } else {
                                return Center(
                                    child: CircularProgressIndicator(
                                        backgroundColor:
                                            themeSelector["primary"]
                                                [settings.get("theme")]));
                              }
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    //! Translation spreadsheet:
                    //! https://docs.google.com/spreadsheets/d/1Ul3bgFmimL_kZ33A1Onzq8bWswIePYFaLnbHCfaI_U4/edit?usp=sharing
                    Text("Translation"),
                    Text("Version"),
                    Text("Privacy")
                  ],
                )
              ],
            ),
          ),
        ),
        floatingActionButton: settings.get("psnID") != null
            ? FloatingActionButton(
                onPressed: () {
                  setState(() {
                    psnpInfo(settings.get("psnID"));
                    // ttInfo(settings.get("psnID"));
                    // psntlInfo(settings.get("psnID"));
                    // exophaseInfo(settings.get("psnID"));
                  });
                },
                tooltip: regionalText["home"]["refresh"],
                child: Icon(Icons.refresh),
                backgroundColor: themeSelector["primary"]
                    [settings.get("theme")],
              )
            : null,
      ),
    );
  }
}
