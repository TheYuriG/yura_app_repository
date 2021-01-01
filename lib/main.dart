import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

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
      //? Sets default trophy icons as Yura's icons
      box.put("trophyType", 'yura');
    }
  });
  runApp(MyApp());
}

//? This will save the settings for the app in this Hive box
//? Examples of settings saved are the theme colors and language.
Box settings = Hive.box("settings");

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
  try {
    //! Retrieves basic profile information, like avatar, about me, PSN ID, level, etc
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
      parsedData['level'] = int.parse(element['title'].replaceAll(",", ""));
    });
    //? Retrieves PSN Level progress
    psnp.getElement('#bar-level > div > div', ['style']).forEach((element) {
      parsedData['levelProgress'] =
          element['attributes']['style'].split(" ")[1].split(";")[0];
    });
    //! Retrieves trophy data
    //? Retrieves Total trophies
    psnp.getElement('#user-bar > ul > div > div > li.total', []).forEach(
        (element) {
      parsedData['total'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves bronze trophies
    psnp.getElement('#user-bar > ul > div > div > li.bronze', []).forEach(
        (element) {
      parsedData['bronze'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves silver trophies
    psnp.getElement('#user-bar > ul > div > div > li.silver', []).forEach(
        (element) {
      parsedData['silver'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves gold trophies
    psnp.getElement('#user-bar > ul > div > div > li.gold', []).forEach(
        (element) {
      parsedData['gold'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves platinum trophies
    psnp.getElement('#user-bar > ul > div > div > li.platinum', []).forEach(
        (element) {
      parsedData['platinum'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //! Retrieves rarity data
    //? Retrieves ultra rare trophies
    psnp.getElement(
        '#content > div.row > div.sidebar.col-xs-4 > div.box.no-top-border > div.xs-hide.lg-show > div > div:nth-child(1) > a > center > span.typo-top',
        []).forEach((element) {
      parsedData['ultraRare'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves very rare trophies
    psnp.getElement(
        '#content > div.row > div.sidebar.col-xs-4 > div.box.no-top-border > div.xs-hide.lg-show > div > div:nth-child(5) > a > center > span.typo-top',
        []).forEach((element) {
      parsedData['veryRare'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves rare trophies
    psnp.getElement(
        '#content > div.row > div.sidebar.col-xs-4 > div.box.no-top-border > div.xs-hide.lg-show > div > div:nth-child(9) > a > center > span.typo-top',
        []).forEach((element) {
      parsedData['rare'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves uncommon trophies
    psnp.getElement(
        '#content > div.row > div.sidebar.col-xs-4 > div.box.no-top-border > div.xs-hide.lg-show > div > div:nth-child(13) > a > center > span.typo-top',
        []).forEach((element) {
      parsedData['uncommon'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves common trophies
    psnp.getElement(
        '#content > div.row > div.sidebar.col-xs-4 > div.box.no-top-border > div.xs-hide.lg-show > div > div:nth-child(17) > a > center > span.typo-top',
        []).forEach((element) {
      parsedData['common'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //! Retrieves profile statistic data like games played, completion %, rankings, etc
    //? Retrieves total ganes
    psnp.getElement(
        '#banner > div.banner-overlay > div > div.stats.flex > span:nth-child(1)',
        []).forEach((element) {
      parsedData['games'] = int.parse(element['title']
          .replaceAll("Games Played", "")
          .replaceAll(",", "")
          .trim());
    });
//? Retrieves complete ganes
    psnp.getElement(
        '#banner > div.banner-overlay > div > div.stats.flex > span:nth-child(3)',
        []).forEach((element) {
      parsedData['complete'] = int.parse(element['title']
          .replaceAll("Completed Games", "")
          .replaceAll(",", "")
          .trim());
      parsedData['incomplete'] = parsedData['games'] - parsedData['complete'];
      parsedData['completePercentage'] =
          (parsedData['complete'] / parsedData['games'] * 100)
              .toStringAsFixed(3);
      parsedData['incompletePercentage'] =
          (parsedData['incomplete'] / parsedData['games'] * 100)
              .toStringAsFixed(3);
    });
    //? Retrieves completion
    psnp.getElement(
        '#banner > div.banner-overlay > div > div.stats.flex > span:nth-child(5)',
        []).forEach((element) {
      parsedData['completion'] =
          element['title'].replaceAll("Completion", "").trim();
    });
    //? Retrieves unearned trophies
    psnp.getElement(
        '#banner > div.banner-overlay > div > div.stats.flex > span:nth-child(7)',
        []).forEach((element) {
      parsedData['unearned'] = int.parse(element['title']
          .replaceAll("Unearned Trophies", "")
          .replaceAll(",", "")
          .trim());

      parsedData['unearnedPercentage'] =
          (parsedData['unearned'] / parsedData['total'] * 100)
              .toStringAsFixed(3);
      parsedData['totalPercentage'] =
          (100 - (parsedData['unearned'] / parsedData['total'] * 100))
              .toStringAsFixed(3);
    });
    //? Retrieves world rank and world rank increase by checking if the span class is "grow green" or "grow red"
    psnp.getElement(
        '#banner > div.banner-overlay > div > div.stats.flex > span:nth-child(13)',
        ['class']).forEach((element) {
      parsedData['worldRank'] = int.parse(element['title']
          .replaceAll("World Rank", "")
          .replaceAll(",", "")
          .trim());
      //? This if/else statement checks if the span containing this information
      //? has a "grow green" or "grow red" class and defines as a rank increase or not
      if (element['attributes']['class'].contains("green")) {
        parsedData['worldUp'] = "⬆️";
      } else {
        parsedData['worldUp'] = "⬇️";
      }
    });
    //? Retrieves country rank and country rank increase by checking if the span class is "grow green" or "grow red"
    psnp.getElement(
        '#banner > div.banner-overlay > div > div.stats.flex > span:nth-child(15)',
        ['class']).forEach((element) {
      parsedData['countryRank'] = int.parse(element['title']
          .replaceAll("Country Rank", "")
          .replaceAll(",", "")
          .trim());
      //? This if/else statement checks if the span containing this information
      //? has a "grow green" or "grow red" class and defines as a rank increase or not
      if (element['attributes']['class'].contains("green")) {
        parsedData['countryUp'] = "⬆️";
      } else {
        parsedData['countryUp'] = "⬇️";
      }
    });
  } catch (e) {
    print(parsedData.isEmpty);
    if (parsedData.isEmpty) {
      parsedData['psnpError'] = true;
    }
  }
  // print(parsedData);
  return parsedData;
}

//? This function contains all translated strings to be used.
//? If a language isn't fully supported, it will use the english words instead.
Map<String, Map<String, String>> regionSelect() {
  //? By default, this loads Yura in English. This is done so new updates can be released without needing
  //? to wait for updated translation. Yura will use english text on those new features while a language patch isn't done
  Map<String, Map<String, String>> avaiableText = {
    "home": {
      "appBar": "Welcome to Yura - A Playstation-based trophy app!",
      "inputID": "Please, provide your PSN ID:",
      "IDhere": "PSN ID goes here...",
      "settings": "Settings",
      "supportedWebsites": "Avaiable websites:",
      "games": "Games\nTracked:",
      "complete": "Games\nCompleted:",
      "incomplete": "Incomplete Games:",
      "completion": "Completion:",
      "unearned": "Unearned\nTrophies:",
      "countryRank": "Country\nRank:",
      "worldRank": "World\nRank:",
      "translation": "Translation",
      "version": "Version",
      "privacy": "Privacy",
    },
    "settings": {
      "trophyPicker": "Change trophy type display:",
      "yuraTrophies": "Use Yura's icons for trophies",
      "oldTrophies": "Use pre-PS5 trophy icons",
      "newTrophies": "Use post-PS5 trophy icons",
      "languagePicker": "Change Yura's language:",
      "themePicker": "Change Yura's theme:",
      'refresh': "Refresh trophy data",
      "pink": "Wednesday",
      "orange": "Nature's Will",
      "blue": "Deep Ocean",
      "black": "Before Dawn",
      "removePSN": "Remove the saved PSN ID?",
    },
    "trophy": {
      "total": "Total",
      "platinum": "Platinum",
      "gold": "Gold",
      "silver": "Silver",
      "bronze": "Bronze",
      "prestige": "Prestige",
      "ultraRare": "Ultra Rare",
      "veryRare": "Very Rare",
      "rare": "Rare",
      "uncommon": "Uncommon",
      "common": "Common"
    },
    //? Since this is just the version number, this doesn't get translated regardless of chosen language.
    "version": {"version": "v0.3.0"}
  };
  //? This changes language to Brazilian Portuguese
  if (settings.get("language") == "br") {
    avaiableText["home"] = {
      "appBar": "Bem vindo a Yura - Um aplicativo para troféus Playstation!",
      "inputID": "Por favor, informe sua ID PSN:",
      "IDhere": "ID da PSN vai aqui...",
      "settings": "Configurações",
      "supportedWebsites": "Sites disponíveis:",
      "games": "Jogos\nregistrados:",
      "complete": "Jogos\nConcluídos:",
      "incomplete": "Jogos Pendentes:",
      "completion": "Conclusão:",
      "unearned": "Troféus\nPendentes:",
      "countryRank": "Rank\nNacional:",
      "worldRank": "Rank\nMundial:",
      "translation": "Tradução",
      "version": "Versão",
      "privacy": "Privacidade",
    };
    avaiableText["settings"] = {
      "trophyPicker": "Mude a aparência dos troféus:",
      "yuraTrophies": "Use os ícones padrões",
      "oldTrophies": "Use ícones anteriores ao PS5",
      "newTrophies": "Use ícones posteriores ao PS5",
      "languagePicker": "Mude o idioma de Yura:",
      "themePicker": "Mude o tema de Yura:",
      'refresh': "Atualizar informação de troféus",
      "pink": "Quarta-Feira",
      "orange": "Desejo da Natureza",
      "blue": "Oceano Profundo",
      "black": "Antes do Amanhecer",
      "removePSN": "Remover a ID PSN salva?",
    };
    avaiableText["trophy"] = {
      "total": "Total",
      "platinum": "Platina",
      "gold": "Ouro",
      "silver": "Prata",
      "bronze": "Bronze",
      "prestige": "Prestígio",
      "ultraRare": "Ultra Raro",
      "veryRare": "Muito Raro",
      "rare": "Raro",
      "uncommon": "Incomum",
      "common": "Comum"
    };
  }
  return avaiableText;
}

Map<String, Map<String, String>> regionalText = regionSelect();

final Map<String, Map<String, Color>> themeSelector = {
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
    "orange": Colors.red[50],
  }
};

//? Option for light thin text
TextStyle textLight = TextStyle(
  color: themeSelector["secondary"][settings.get("theme")],
  fontSize: 16,
);
//? Option for light bold text
TextStyle textLightBold = TextStyle(
    color: themeSelector["secondary"][settings.get("theme")],
    fontSize: 20,
    fontWeight: FontWeight.bold);

//? Option for dark thin text
TextStyle textDark = TextStyle(
  color: themeSelector["primary"][settings.get("theme")],
  fontSize: 16,
);
//? Option for dark bold text
TextStyle textDarkBold = TextStyle(
    color: themeSelector["primary"][settings.get("theme")],
    fontSize: 20,
    fontWeight: FontWeight.bold);

//? All image assets are declared in this Map so they can be easily referenced on Image.asset() functions
final Map<String, String> img = {
  "oldLevel": "images/ps_level_old.png",
  "bronze1": "images/bronzelevel1.png",
  "bronze2": "images/bronzelevel2.png",
  "bronze3": "images/bronzelevel3.png",
  "silver1": "images/silverlevel1.png",
  "silver2": "images/silverlevel2.png",
  "silver3": "images/silverlevel3.png",
  "gold1": "images/goldlevel1.png",
  "gold2": "images/goldlevel2.png",
  "gold3": "images/goldlevel3.png",
  "platinumlevel": "images/platinumlevel.png",
  "bronzeOut": "images/bronze_outline.png",
  "bronzeFill": "images/bronze_fill.png",
  "silverOut": "images/silver_outline.png",
  "silverFill": "images/silver_fill.png",
  "goldOut": "images/gold_outline.png",
  "goldFill": "images/gold_fill.png",
  "platOut": "images/platinum_outline.png",
  "platFill": "images/platinum_fill.png",
  "oldPlatinum": "images/old_platinum.png",
  "oldGold": "images/old_gold.png",
  "oldSilver": "images/old_silver.png",
  "oldBronze": "images/old_bronze.png",
  "newPlatinum": "images/new_platinum.png",
  "newGold": "images/new_gold.png",
  "newSilver": "images/new_silver.png",
  "newBronze": "images/new_bronze.png",
  "ps": "images/playstation.png",
  "allTrophies": "images/trophy_cluster.png",
  "rarity1": "images/rarity1.png",
  "rarity2": "images/rarity2.png",
  "rarity3": "images/rarity3.png",
  "rarity4": "images/rarity4.png",
  "rarity5": "images/rarity5.png",
  "rarity6": "images/rarity6.png",
  "rarity7": "images/rarity7.png",
  "ps3": "images/ps3.png",
  "ps4": "images/ps4.png",
  "ps5": "images/ps5.png",
  "psv": "images/psv.png",
};

//? This defines a function to return the Image.asset() path to the proper emote icon, based on
//? user preference to use Yura's / Old / New emote types. The selector can be found in the settings
String trophyStyle(String type) {
  if (type == "platinum") {
    if (settings.get('trophyType') == "new") {
      return img['newPlatinum'];
    } else if (settings.get('trophyType') == "old") {
      return img['oldPlatinum'];
    } else {
      return img["platFill"];
    }
  } else if (type == "gold") {
    if (settings.get('trophyType') == "new") {
      return img['newGold'];
    } else if (settings.get('trophyType') == "old") {
      return img['oldGold'];
    } else {
      return img["goldFill"];
    }
  } else if (type == "silver") {
    if (settings.get('trophyType') == "new") {
      return img['newSilver'];
    } else if (settings.get('trophyType') == "old") {
      return img['oldSilver'];
    } else {
      return img["silverFill"];
    }
  } else if (type == "bronze") {
    if (settings.get('trophyType') == "new") {
      return img['newBronze'];
    } else if (settings.get('trophyType') == "old") {
      return img['oldBronze'];
    } else {
      return img["bronzeFill"];
    }
  } else {
    if (settings.get('trophyType') == "old") {
      return img['allTrophies'];
    } else {
      return img["ps"];
    }
  }
}

//? This returns a properly named and formatted Tooltip'd Row() of trophy icon + spacing + number of trophies
//? Number of trophies and formatting is optional. If not provided, only the proper Image.asset()
//? will be returned, without spacing and without number of trophies. If not provided, it will use default textLight formatting
Tooltip trophyType(String type, {quantity = -1, TextStyle style}) {
  return Tooltip(
    message: regionalText['trophy'][type],
    child: Row(
      children: [
        Image.asset(trophyStyle(type), height: 20),
        if (quantity != -1)
          SizedBox(
            width: 5,
          ),
        if (quantity != -1)
          Text(
            quantity != double.nan ? quantity.toString() : quantity,
            style: style ??
                TextStyle(
                  color: themeSelector["secondary"][settings.get("theme")],
                  fontSize: 16,
                ),
          ),
      ],
    ),
  );
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
    //? The Debouncer (class created above) is now instantiated here so the search is delayed until the user stops typing.
    Debouncer debounce = Debouncer(milliseconds: 800);

    //? Default BoxDecoration used
    BoxDecoration boxDeco() => BoxDecoration(
        color:
            themeSelector["primary"][settings.get("theme")].withOpacity(0.85),
        borderRadius: BorderRadius.all(Radius.circular(15)),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: Colors.black, blurRadius: 5)]);

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
                                //? Limita o tamanho da caixa de configurações para um máximo de 60% do tamanho da tela
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
                                  //? Permite que o usuário troque o tipo de troféus do aplicativo.
                                  //? O usuário não verá a opção de trocar para o tipo de troféu que estiver ativo
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Center(
                                      child: Text(
                                        regionalText["settings"]
                                            ["trophyPicker"],
                                        style: textDark,
                                      ),
                                    ),
                                  ),
                                  Wrap(
                                    children: [
                                      //? Option to use Yura's trophies as default display
                                      if (settings.get('trophyType') != "yura")
                                        Tooltip(
                                          message: regionalText["settings"]
                                              ["yuraTrophies"],
                                          child: MaterialButton(
                                              hoverColor: Colors.transparent,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              child: Image.asset(
                                                img['platFill'],
                                                height: 50,
                                                width: 75,
                                              ),
                                              onPressed: () => {
                                                    setState(() {
                                                      settings.put(
                                                          'trophyType', 'yura');
                                                    }),
                                                    Navigator.pop(context)
                                                  }),
                                        ),
                                      //? Option to use old PSN trophies as default display
                                      if (settings.get('trophyType') != "old")
                                        Tooltip(
                                          message: regionalText["settings"]
                                              ["oldTrophies"],
                                          child: MaterialButton(
                                              hoverColor: Colors.transparent,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              child: Image.asset(
                                                img['oldPlatinum'],
                                                height: 50,
                                                width: 75,
                                              ),
                                              onPressed: () => {
                                                    setState(() {
                                                      settings.put(
                                                          'trophyType', 'old');
                                                    }),
                                                    Navigator.pop(context)
                                                  }),
                                        ),
                                      //? Option to use new PSN trophies as default display
                                      if (settings.get('trophyType') != "new")
                                        Tooltip(
                                          message: regionalText["settings"]
                                              ["newTrophies"],
                                          child: MaterialButton(
                                              hoverColor: Colors.transparent,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              child: Image.asset(
                                                img['newPlatinum'],
                                                height: 50,
                                                width: 75,
                                              ),
                                              onPressed: () => {
                                                    setState(() {
                                                      settings.put(
                                                          'trophyType', 'new');
                                                    }),
                                                    Navigator.pop(context)
                                                  }),
                                        ),
                                    ],
                                  ),
                                  //? Permite que o usuário troque o idioma do aplicativo.
                                  //? O usuário não verá a opção de trocar para o mesmo idioma que estiver ativo
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Center(
                                      child: Text(
                                        regionalText["settings"]
                                            ["languagePicker"],
                                        style: textDark,
                                      ),
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 5,
                                    children: [
                                      if (settings.get('language') != "br")
                                        Tooltip(
                                          message: 'Português - Brasil',
                                          child: MaterialButton(
                                              hoverColor: Colors.transparent,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              child: Image.network(
                                                "https://raw.githubusercontent.com/hjnilsson/country-flags/master/png100px/br.png",
                                                height: 50,
                                                width: 75,
                                              ),
                                              onPressed: () => {
                                                    setState(() {
                                                      settings.put(
                                                          'language', 'br');
                                                    }),
                                                    Navigator.pop(context)
                                                  }),
                                        ),
                                      if (settings.get('language') != "us")
                                        Tooltip(
                                          message:
                                              "English - United States of America",
                                          child: MaterialButton(
                                              hoverColor: Colors.transparent,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              child: Image.network(
                                                "https://raw.githubusercontent.com/hjnilsson/country-flags/master/png100px/us.png",
                                                height: 50,
                                                width: 75,
                                              ),
                                              onPressed: () => {
                                                    setState(() {
                                                      settings.put(
                                                          'language', 'us');
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
                                        regionalText["settings"]["themePicker"],
                                        style: textDark,
                                      ),
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 5,
                                    children: [
                                      if (settings.get('theme') != "pink")
                                        Tooltip(
                                          message: regionalText["settings"]
                                              ["pink"],
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
                                          message: regionalText["settings"]
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
                                          message: regionalText["settings"]
                                              ["blue"],
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
                                          message: regionalText["settings"]
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
                                          regionalText["settings"]["removePSN"],
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
                gradient: RadialGradient(colors: [
              Colors.white,
              themeSelector["secondary"][settings.get("theme")],
            ])),
            width: MediaQuery.of(context).size.width,
            child: Column(
              //? Max main axis size to use the entire avaiable soace left from the appBar and Safe Area.
              mainAxisSize: MainAxisSize.max,
              //? Using spaceBetween as alignment so i can have the Translation / Discord buttons and
              //?version to always display on the bottom. An empty SizedBox is created at the start of the
              //? widget's list to space out properly
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(),
                //? This is the stuff that shows up when you haven't set a PSN ID.
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
                                  // psnpInfo(text);
                                  settings.put('psnID', text);
                                });
                              });
                            }),
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      Text(
                        regionalText['home']['supportedWebsites'],
                        style: textDarkBold,
                      ),
                      //? Spaces for PSNProfiles and PSN Trophy Leaders
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 50,
                              width: 220,
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
                                      style: textLight,
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
                              width: 220,
                              decoration: boxDeco(),
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
                                      style: textLight,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      //? Spaces for True Trophies and Exophase
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 50,
                              width: 220,
                              decoration: boxDeco(),
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
                                      style: textLight,
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
                              width: 220,
                              decoration: boxDeco(),
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
                                      style: textLight,
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
                //? Cards are displayed when you set a PSN ID with success.
                //! Needs error handling for bad IDs.
                if (settings.get("psnID") != null)
                  Expanded(
                    child: ListView(
                      children: [
                        Container(
                          margin: EdgeInsets.all(15),
                          padding: EdgeInsets.all(15),
                          width: MediaQuery.of(context).size.width,
                          //! Height undefined until all items are added to avoid overflow error.
                          // height: 220,
                          decoration: boxDeco(),
                          child: FutureBuilder(
                            future: psnpInfo(settings.get("psnID")),
                            builder: (context, snapshot) {
                              //? Display card info if all information is successfully fetched
                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.data['psnpError'] != true) {
                                return Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    //? Contains your basic information about profile name, PSN level,
                                    //? trophy count, avatar, country flag, etc
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          //? Avatar PSN Profiles
                                          Image.network(
                                            snapshot.data['avatar'] ??
                                                "https://i.psnprofiles.com/avatars/m/Gfba90ec21.png",
                                            height: 100,
                                          ),
                                          //? Column with PSN ID, About Me (on hover), trophy count
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              //? Country flag and PSN ID
                                              Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    //? Country flag using PSNTL's large flags
                                                    Image.network(
                                                        "https://raw.githubusercontent.com/hjnilsson/country-flags/master/png100px/${snapshot.data['country']}.png",
                                                        height: 20),
                                                    SizedBox(
                                                      width: 10,
                                                    ),
                                                    Tooltip(
                                                      message: snapshot
                                                              .data['about'] ??
                                                          snapshot
                                                              .data['psnID'],
                                                      child: Text(
                                                        snapshot.data["psnID"],
                                                        style: textLightBold,
                                                      ),
                                                    )
                                                  ]),
                                              SizedBox(),
                                              //? Level, level progress and level icon
                                              //TODO Update this with the actual current icons and also add the foruma for the old leveling system.
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(5.0),
                                                child: Row(
                                                  children: [
                                                    Image.asset(
                                                      img['oldLevel'],
                                                      height: 25,
                                                    ),
                                                    SizedBox(
                                                      width: 5,
                                                    ),
                                                    Text(
                                                        "${snapshot.data['level'].toString()} (${snapshot.data['levelProgress']})",
                                                        style: textLight),
                                                  ],
                                                ),
                                              ),
                                              //? This row contains the trophy icons and the quantity the user has acquired of them
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  trophyType('platinum',
                                                      quantity: snapshot
                                                          .data['platinum']),
                                                  SizedBox(
                                                    width: 20,
                                                  ),
                                                  trophyType('gold',
                                                      quantity: snapshot
                                                          .data['gold']),
                                                  SizedBox(
                                                    width: 20,
                                                  ),
                                                  trophyType('silver',
                                                      quantity: snapshot
                                                          .data['silver']),
                                                  SizedBox(
                                                    width: 20,
                                                  ),
                                                  trophyType('bronze',
                                                      quantity: snapshot
                                                          .data['bronze']),
                                                  SizedBox(
                                                    width: 20,
                                                  ),
                                                  trophyType('total',
                                                      quantity:
                                                          "${snapshot.data['total'].toString()} (${snapshot.data['totalPercentage']}%)"),
                                                ],
                                              ),
                                              SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Tooltip(
                                                      message:
                                                          regionalText['trophy']
                                                              ['ultraRare'],
                                                      child: Row(
                                                        children: [
                                                          Image.asset(
                                                              img['rarity6'],
                                                              height: 15),
                                                          SizedBox(
                                                            width: 5,
                                                          ),
                                                          Text(
                                                            snapshot.data[
                                                                    'ultraRare']
                                                                .toString(),
                                                            style: textLight,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 20,
                                                    ),
                                                    Tooltip(
                                                      message:
                                                          regionalText['trophy']
                                                              ['veryRare'],
                                                      child: Row(
                                                        children: [
                                                          Image.asset(
                                                              img['rarity5'],
                                                              height: 15),
                                                          SizedBox(
                                                            width: 5,
                                                          ),
                                                          Text(
                                                            snapshot.data[
                                                                    'veryRare']
                                                                .toString(),
                                                            style: textLight,
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 20,
                                                    ),
                                                    Tooltip(
                                                      message:
                                                          regionalText['trophy']
                                                              ['rare'],
                                                      child: Row(
                                                        children: [
                                                          Image.asset(
                                                              img['rarity4'],
                                                              height: 15),
                                                          SizedBox(
                                                            width: 5,
                                                          ),
                                                          Text(
                                                            snapshot
                                                                .data['rare']
                                                                .toString(),
                                                            style: textLight,
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 20,
                                                    ),
                                                    Tooltip(
                                                      message:
                                                          regionalText['trophy']
                                                              ['uncommon'],
                                                      child: Row(
                                                        children: [
                                                          Image.asset(
                                                              img['rarity3'],
                                                              height: 15),
                                                          SizedBox(
                                                            width: 5,
                                                          ),
                                                          Text(
                                                            snapshot.data[
                                                                    'uncommon']
                                                                .toString(),
                                                            style: textLight,
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 20,
                                                    ),
                                                    Tooltip(
                                                      message:
                                                          regionalText['trophy']
                                                              ['common'],
                                                      child: Row(
                                                        children: [
                                                          Image.asset(
                                                              img['rarity1'],
                                                              height: 20),
                                                          SizedBox(
                                                            width: 5,
                                                          ),
                                                          Text(
                                                            snapshot
                                                                .data['common']
                                                                .toString(),
                                                            style: textLight,
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                          SizedBox(
                                            height: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                    //? Bottom row without avatar, has information about games played,
                                    //? completion, unearned trophies, country/world rankings, etc
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Text(
                                              "${regionalText["home"]["games"]}\n${snapshot.data['games'].toString()}",
                                              style: textLight,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Text(
                                              "${regionalText["home"]["complete"]}\n${snapshot.data['complete'].toString()} (${snapshot.data['completePercentage']}%)",
                                              style: textLight,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Text(
                                              "${regionalText["home"]["incomplete"]}\n${snapshot.data['incomplete'].toString()} (${snapshot.data['incompletePercentage']}%)",
                                              style: textLight,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Text(
                                              "${regionalText["home"]["completion"]}\n${snapshot.data['completion']}",
                                              style: textLight,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Text(
                                              "${regionalText["home"]["unearned"]}\n${snapshot.data['unearned'].toString()} (${snapshot.data['unearnedPercentage']}%)",
                                              style: textLight,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Text(
                                              "${regionalText["home"]["countryRank"]}\n${snapshot.data['countryRank'] != null ? snapshot.data['countryRank'].toString() + " " : "❌"}${snapshot.data['countryUp'] ?? ""}",
                                              style: textLight,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Text(
                                              "${regionalText["home"]["worldRank"]}\n${snapshot.data['worldRank'] != null ? snapshot.data['worldRank'].toString() + " " : "❌"}${snapshot.data['worldUp'] ?? ""}",
                                              style: textLight,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                );
                              } //? Display error screen if fails to fetch information
                              else if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.data['psnpError'] == true) {
                                settings.put('psnp', false);
                                return Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.error,
                                        color: themeSelector["secondary"]
                                            [settings.get("theme")],
                                        size: 30,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "PSNProfiles",
                                        style: textLightBold,
                                      )
                                    ],
                                  ),
                                );
                              } //? Display loading circle while Future is being processed
                              else {
                                return Center(
                                    child: CircularProgressIndicator(
                                        backgroundColor: Colors.transparent
                                        // themeSelector["secondary"]
                                        //     [settings.get("theme")],
                                        ));
                              }
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      //? Translation spreadsheet:
                      //? https://docs.google.com/spreadsheets/d/1Ul3bgFmimL_kZ33A1Onzq8bWswIePYFaLnbHCfaI_U4/edit?usp=sharing
                      RawMaterialButton(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.network(
                              "https://raw.githubusercontent.com/hjnilsson/country-flags/master/png100px/${settings.get('language')}.png",
                              height: 15,
                              width: 22.5,
                            ),
                            SizedBox(width: 5),
                            Text(regionalText['home']['translation'],
                                style: textDark),
                          ],
                        ),
                        onPressed: null,
                      ),
                      RawMaterialButton(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.network(
                                "https://discord.com/assets/2c21aeda16de354ba5334551a883b481.png",
                                height: 25),
                            Text("Discord", style: textDark),
                          ],
                        ),
                        onPressed: () async {
                          if (await canLaunch("https://discord.gg/j55v7pD")) {
                            launch("https://discord.gg/j55v7pD");
                          } else {
                            return null;
                          }
                        },
                      ),
                      RawMaterialButton(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info,
                                size: 20,
                                color: themeSelector["primary"]
                                    [settings.get("theme")]),
                            SizedBox(width: 5),
                            Text(
                                "${regionalText['home']['version']} ${regionalText['version']['version']}",
                                style: textDark),
                          ],
                        ),
                        onPressed: null,
                      ),
                      RawMaterialButton(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.privacy_tip,
                                size: 20,
                                color: themeSelector["primary"]
                                    [settings.get("theme")]),
                            SizedBox(width: 5),
                            Text(regionalText['home']['privacy'],
                                style: textDark),
                          ],
                        ),
                        onPressed: null,
                      ),
                      // if ()
                    ],
                  ),
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
