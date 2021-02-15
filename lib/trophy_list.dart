import 'dart:convert';
import 'dart:ui';
import 'dart:io' show Platform;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:time_machine/time_machine.dart';
import 'main.dart';
import 'package:flutter/material.dart';

class TrophyList extends StatefulWidget {
  final Map trophyListData;

  TrophyList({this.trophyListData}) {
    assert(trophyListData != null);
  }
  @override
  _TrophyListState createState() => _TrophyListState(trophyListData);
}

//! Icon for the roadmap trophy list: Icons.account_tree

//? Stored list of pending trophies
Map trophyPending = settings.get('trophyPending') ??
    {
      'psnProfiles': {},
      'psnTrophyLeaders': {},
      'exophase': {},
      'trueTrophies': {},
      'psn100': {}
    };

//? Stored list of earned trophies
Map trophyEarned = settings.get('trophyEarned') ??
    {
      'psnProfiles': {},
      'psnTrophyLeaders': {},
      'exophase': {},
      'trueTrophies': {},
      'psn100': {}
    };

//? These integers will store how many games were filtered and how many are being displayed currently.
int _displayedTrophies = 0;

//? This private function processes the parsed string from requestWebsite() and returns useful data
Map<String, dynamic> _trophyData(String parsedHTMLasString,
    {Map<String, dynamic> timestamps}) {
  Map<String, dynamic> information = {
    'platinumCount': 0,
    'goldCount': 0,
    'silverCount': 0,
    'bronzeCount': 0,
    'podium': null
  };
  ws.loadFromString(parsedHTMLasString);
  // print("HTML loaded from string");

  //? This integer stores the number of trophies fetched
  int trophyIDNumber = 0;

  //? Checks if the page is exophase.
  if (ws.getElementAttribute("a.logo", 'title').contains("Exophase.com")) {
    // print("starting exophase data query");

    //? Retrieves banner link
    ws
        .getElementAttribute(
            "body > div.row.container-fluid.container-overlay.align-items-center.d-none.d-md-flex > div > div",
            'style')
        .forEach((element) {
      information['gameHeader'] =
          element.replaceAll("background-image: url(", "").split("?")[0];
    });
    //? Retrieves Exophase trophy earned count
    ws
        .getElementTitle(
            "#app > div > div.row.col-game-information.pb-3 > div:nth-child(3) > ul.row.justify-content-center > li:nth-child(1) > strong")
        .forEach((element) {
      information['gameTrophyEarnedCount'] = element;
    });

    //? Retrieves Exophase game owners
    ws
        .getElementTitle(
            "#app > div > div.row.col-game-information.pb-3 > div:nth-child(3) > ul.row.justify-content-center > li:nth-child(3) > strong")
        .forEach((element) {
      information['gameOwners'] = element;
    });

    //? Retrieves game max exp
    ws
        .getElementTitle(
            "#app > div > div.row.col-game-information.pb-3 > div:nth-child(3) > ul.row.justify-content-center > li:nth-child(7) > strong")
        .forEach((element) {
      information['gameMaxEXP'] = element;
    });

    //? Retrieves game Platinum Club
    ws
        .getElementTitle(
            "#app > div > div.row.col-game-information.pb-3 > div:nth-child(3) > ul.row.justify-content-center > li:nth-child(11) > strong")
        .forEach((element) {
      information['gameBaseGameCompletion'] = element;
    });

    //? Retrieves game Completist Club
    ws
        .getElementTitle(
            "#app > div > div.row.col-game-information.pb-3 > div:nth-child(3) > ul.row.justify-content-center > li:nth-child(11) > strong")
        .forEach((element) {
      information['gameFullCompletion'] = element;
    });

    //? Retrieves DLC count
    information['dlcPacksCount'] = ws
        .getElementTitle("div.row.game-page > div#awards > h3.listing")
        .length;

    for (int countDLC = 0;
        countDLC <= information['dlcPacksCount'];
        countDLC++) {
      if (countDLC == 0) {
        //? Sets the name of the first pack of trophies as "base"
        information['gamePack${countDLC}Title'] = "base";
      } else {
        //? Retrieves DLC pack title
        //! todo this the numbering for these is wrong. figure it out when possible, it's not fetching the titles properly
        ws
            .getElementTitle(
                "div.row.game-page > div#awards > h3.listing:nth-child(${(countDLC * 8) + 1})")
            .forEach((element) {
          information['gamePack${countDLC}Title'] =
              element.replaceAll(" DLC trophies", "").trim();
        });
      }
      information['gamePack${countDLC}TrophyCount'] = ws.getElement(
          "div.row.game-page > div#awards > ul:nth-child(${(countDLC * 8) + 5}) > li.award",
          []).length;

      //? Initializes a List to contain all trophy information for this pack.
      List<Map<String, dynamic>> trophyData = [];

      for (int trophyNumber = 0;
          trophyNumber < (information['gamePack${countDLC}TrophyCount'] ?? 0);
          trophyNumber++) {
        //? Initializes a map inside this pack to contain its trophy data
        trophyData.add({});

        //? Checks the trophy image class attribute to see if it has the 'visible' or 'hidden' property
        ws.getElement(
            "div.row.game-page > div#awards > ul:nth-child(${(countDLC * 8) + 5}) > li:nth-child(${(trophyNumber * 2) + 1})",
            ['class', 'data-award-id', 'data-points']).forEach((element) {
          if (element['attributes']['class'].contains('visible')) {
            trophyData[trophyNumber]['hidden'] = false;
          } else {
            trophyData[trophyNumber]['hidden'] = true;
          }
          switch (element['attributes']['data-points']) {
            case "15":
              trophyData[trophyNumber]['type'] = 'bronze';
              information['bronzeCount']++;
              break;
            case "30":
              trophyData[trophyNumber]['type'] = 'silver';
              information['silverCount']++;
              break;
            case "90":
              trophyData[trophyNumber]['type'] = 'gold';
              information['goldCount']++;
              break;
            case "300":
              trophyData[trophyNumber]['type'] = 'platinum';
              information['platinumCount']++;
              break;
          }
          trophyData[trophyNumber]['id'] = trophyIDNumber;
          if (countDLC > 0) {
            trophyData[trophyNumber]['dlc'] = true;
          }
        });

        //? Stores the trophy image
        ws
            .getElementAttribute(
                "div.row.game-page > div#awards > ul:nth-child(${(countDLC * 8) + 5}) > li:nth-child(${(trophyNumber * 2) + 1}) > div.row.align-items-center > div.col-auto.award-left > div.box.image > img",
                'src')
            .forEach((element) {
          trophyData[trophyNumber]['image'] = element;
        });

        //? Stores the trophy name
        ws.getElement(
            "div.row.game-page > div#awards > ul:nth-child(${(countDLC * 8) + 5}) > li:nth-child(${(trophyNumber * 2) + 1}) > div.row > div.award-details.snippet > div.award-title > a",
            ['href']).forEach((element) {
          trophyData[trophyNumber]['name'] = element['title'].trim();
          trophyData[trophyNumber]['link'] = element['attributes']['href'];
        });

        //? Stores the trophy description
        ws
            .getElementTitle(
                "div.row.game-page > div#awards > ul:nth-child(${(countDLC * 8) + 5}) > li:nth-child(${(trophyNumber * 2) + 1}) > div.row > div.award-details.snippet > div.award-description > p")
            .forEach((element) {
          trophyData[trophyNumber]['description'] = element;
        });

        // //? Stores the trophy rarity and EXP
        ws
            .getElementTitle(
                "div.row.game-page > div#awards > ul:nth-child(${(countDLC * 8) + 5}) > li:nth-child(${(trophyNumber * 2) + 1}) > div.row > div.award-average > span.tippy")
            .forEach((element) {
          trophyData[trophyNumber]['rarity'] =
              double.parse(element.split('%').first.trim());
          trophyData[trophyNumber]['exp'] =
              double.parse(element.split('(')[1].replaceAll(")", "").trim());
        });

        //? Fills the podium. If the podium is empty, put any trophy in it.
        //? If there is a plat on the podium, check if the comparing trophy is 5x rarer and if so, replace it.
        //? If there is no plat on the podium but the comparing trophy is rarer than the podium trophy, replace it.
        if (information['podium'] == null) {
          information['podium'] = trophyData[trophyNumber];
        } else if (trophyData[trophyNumber]['type'] == 'platinum') {
          information['podium'] = trophyData[trophyNumber];
        } else if (trophyData[trophyNumber]['rarity'] <
            information['podium']['rarity']) {
          if (information['podium']['type'] == 'platinum' &&
              trophyData[trophyNumber]['rarity'] * 5 <
                  information['podium']['rarity']) {
            information['podium'] = trophyData[trophyNumber];
          } else if (information['podium']['type'] != 'platinum') {
            information['podium'] = trophyData[trophyNumber];
          }
        }
        trophyIDNumber++;
      }
      information['gamePack${countDLC}TrophyData'] = trophyData;
    }
  }
  // print(information);
  // print("complete");
  return information;
}

class _TrophyListState extends State<TrophyList> {
  //? Sets the settings here to be used throughout the trophy page.
  Map trophySettings = settings.get('trophySettings') ??
      {
        //? Filter options
        "earned": true, //? This will hide earned trophies
        "unearned": true, //? This will hide unearned trophies
        "showHidden": true, //? This will force secret trophies to not display
        'urOnly': //? This will only display trophies with rarity lower than 5%
            false,
        'noCommons': //? This will only display trophies with rarity lower than 50%
            false,
        //? Sorting setting
        "sorting": "original",
        //? Settings options
        "hidden": false,
        "description": true,
        "DLCseparator": true,
        'localization': true,
        //? Options menu
        "filter": false,
        "sort": false,
        "display": false,
        "settings": false,
        //? Display setting
        "trophyDisplay": "grid",
      };

  Map trophyListData;

  //! Load a webpage, parse it as a string and then computes the result and returns a map
  Future<Map<String, dynamic>> requestWebsite(String link) async {
    //? Initializes the String variable
    String parsedHTML;

    //? Checks if the requested page is from Exophase
    if (link.contains('www.exophase.com')) {
      // print('exophase link');
      if (trophySettings['localization'] == true) {
        String country = settings.get('exophaseDump')['country'];
        //? Does country checking to retrieve properly translated trophy lists
        if (country == "cn") {
          country = "zh-CN";
        } else if (country == "br") {
          country = "pt-BR";
        } else if (country == "gb") {
          country = "en-GB";
        } else if (country == "mx") {
          country = "es-MX";
        } else if (country == "ar") {
          country = "es";
        }
        //? Loads the webpage considering the translated list
        await ws.loadFullURL(link.split("#")[0] + country + "/");
        //? Returns the webpage as a string
        parsedHTML = ws.getPageContent();
      } else {
        //? Loads the english/default webpage
        await ws.loadFullURL(link.split("#")[0]);
        //? Returns the webpage as a string
        parsedHTML = ws.getPageContent();
      }

      //? Returns the webpage as a string
      parsedHTML = ws.getPageContent();

      Map finalData = await compute(_trophyData, parsedHTML);

      if (trophyListData['gamePercentage'] > 0) {
        List earnedTrophyData;
        //? Loads the trophy data URL and returns the parsed information.
        await ws.loadFullURL(
            'https://api.exophase.com/public/player/${link.split("#")[1]}/game/${trophyListData['gameID']}/earned');
        earnedTrophyData = json.decode(ws.getPageContent())['list'];
        earnedTrophyData
            .sort((a, b) => a['canonical_id'] > b['canonical_id'] ? 1 : -1);
        int dlcPack = 0;
        int totalSkipped = 0;
        for (Map trophy in earnedTrophyData) {
          while (trophy['canonical_id'] >
              (finalData['gamePack${dlcPack}TrophyCount'] ?? 1000) +
                  totalSkipped) {
            totalSkipped += (finalData['gamePack${dlcPack}TrophyCount'] ?? 0);
            dlcPack++;
          }
          if (finalData['gamePack${dlcPack}TrophyData'] != null &&
              finalData['gamePack${dlcPack}TrophyData']
                      [trophy['canonical_id'] - 1 - totalSkipped] !=
                  null) {
            finalData['gamePack${dlcPack}TrophyData']
                    [trophy['canonical_id'] - 1 - totalSkipped]['timestamp'] =
                trophy['timestamp'];
          }
          try {
            if (trophySettings['localization'] == true) {
              finalData['gamePack${dlcPack}TrophyData']
                      [trophy['canonical_id'] - 1 - totalSkipped]
                  ['parsedTimestamp'] = Instant.dateTime(
                DateTime.fromMillisecondsSinceEpoch(trophy['timestamp'] * 1000),
              ).inLocalZone().toString('MMMM d, yyyy (dddd) - H:mm');
            } else {
              finalData['gamePack${dlcPack}TrophyData']
                      [trophy['canonical_id'] - 1 - totalSkipped]
                  ['parsedTimestamp'] = Instant.dateTime(
                DateTime.fromMillisecondsSinceEpoch(trophy['timestamp'] * 1000),
              ).toString('MMMM d, yyyy (dddd) - H:mm');
            }
          } catch (e) {
            finalData['gamePack${dlcPack}TrophyData']
                    [trophy['canonical_id'] - 1 - totalSkipped]
                ['parsedTimestamp'] = trophy['earned'];
          }
        }
      }

      // print(finalData);

      //? Gives the parsed HTML to the compute function which will run in the background
      return finalData;
    } else {
      throw Error;
    }
  }

  //? Parses trophy list data and returns the trophy list in the proper display mode.
  Widget trophyListDisplay() {
    //? Returns the properly formatted list/grid of items to be displayed
    Widget listDisplay;

    //? Stores and organizes all trophies to be displayed inside listDisplay
    List trophiesArray = [];

    //? Stores how many trophies are currently being displayed using the filters applied
    _displayedTrophies = 0;

    //? Stores all the trophy widgets, being them in a List or Grid.
    List<Widget> trophyWidgets = [];

    //? Transforms the Map into a List for the sort functions.
    for (var i = 0; i <= trophyDataMap['dlcPacksCount'] ?? 0; i++) {
      if (trophySettings['sorting'] == "original") {
        trophiesArray.add([
          trophyDataMap['gamePack${i}Title'],
          trophyDataMap['gamePack${i}Image'] ?? null
        ]);
      }
      trophiesArray += trophyDataMap['gamePack${i}TrophyData'];
    }

    trophiesArray.forEach((element) {
      if (element is Map) {
        //? Attaches game name to trophy for the Trophy Log
        element['gameData'] = trophyListData;

        //? If this is an exophase page, store information on the exophase part of the database
        if (trophyListData['gameLink'].contains("exophase.com")) {
          //? If this trophy was earned (has a timestamp), save it on the earned trophies database
          if (element['timestamp'] != null) {
            if (trophyEarned['exophase'][element['gameLink']] == null) {
              trophyEarned['exophase'][element['gameLink']] = {};
            }
            trophyEarned['exophase'][element['gameLink']][element['link']] =
                element;
          }
          //? Stores the other trophies without timestamps in the other database
          else {
            if (trophyPending['exophase'][element['gameLink']] == null) {
              trophyPending['exophase'][element['gameLink']] = {};
            }
            trophyPending['exophase'][element['gameLink']][element['link']] =
                element;
          }
        }
      }
    });
    settings.put('trophyEarned', trophyEarned);
    settings.put('trophyPending', trophyPending);

    //? Alphabetical sorting in ascending manner (A trophies before Z trophies).
    if (trophySettings['sorting'] == "alphabetical") {
      trophiesArray.sort((a, b) => (a['name'] ?? "")
          .toLowerCase()
          .compareTo((b['name'] ?? "").toLowerCase()));
    }
    //? Rarity sorting in ascending manner (low % trophies before high % trophies).
    else if (trophySettings['sorting'] == "rarity") {
      trophiesArray.sort((a, b) =>
          //? If both trophies have the same rarity
          (a['rarity'] ?? 0) == (b['rarity'] ?? 0)
              //? Sort them out by their trophy ID. This will sort trophies by their original list position
              ? (a['id']) > (b['id'])
                  ? 1
                  : -1
              //? If they have different rarities, sort them by rarity
              : (a['rarity'] ?? 0) > (b['rarity'] ?? 0)
                  ? 1
                  : -1);
    }
    //? Trophy type sorting in descending manner (Platinum > Gold > Silver > Bronze).
    else if (trophySettings['sorting'] == "value") {
      trophiesArray.sort((a, b) {
        //? Checks the trophy type and returns a value based on that, so that the trophies can be sorted based on their weight.
        int _value(String type) {
          if (type == "platinum") {
            return 4;
          } else if (type == "gold") {
            return 3;
          } else if (type == "silver") {
            return 2;
          } else {
            return 1;
          }
        }

        int trophyA = _value(a['type']);
        int trophyB = _value(b['type']);
        return trophyA == trophyB
            ? a['id'] > b['id']
                ? 1
                : -1
            : trophyA > trophyB
                ? -1
                : 1;
      });
    }
    //? Rarity sorting in ascending manner (low % trophies before high % trophies).
    else if (trophySettings['sorting'] == "earnedTimestamp") {
      trophiesArray.sort((a, b) =>
          (a['timestamp'] ?? 999999999999) > (b['timestamp'] ?? 999999999999)
              ? 1
              : -1);
    }

    if (trophySettings['trophyDisplay'] == "grid") {
      for (var i = 0; i < trophiesArray.length; i++) {
        //? This adds DLC separators, if that option is enabled
        if (trophiesArray[i] is List) {
          if (trophySettings['DLCseparator'] != false &&
              trophiesArray[i][0] != "base") {
            trophyWidgets.add(
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: Platform.isWindows ? 10 : 3,
                    horizontal: Platform.isWindows ? 10 : 3),
                child: Container(
                  width: MediaQuery.of(context).size.width -
                      (Platform.isWindows ? 30 : 5),
                  child: Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        color: themeSelector["primary"][settings.get("theme")],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            width: Platform.isWindows ? 5 : 3,
                            color: themeSelector["secondary"]
                                [settings.get("theme")])),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (trophiesArray[i][1] != null)
                          CachedNetworkImage(
                              imageUrl: trophySettings['hidden'] != false ||
                                      trophiesArray[i]['hidden'] != true
                                  ? trophiesArray[i][1]
                                  : "https://www.exophase.com/assets/zeal/images/default_hidden.png",
                              fit: BoxFit.fill),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            child: Text(
                              trophiesArray[i][0],
                              style: textSelection(theme: "textLightBold"),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        } //? Trophy tiles
        else {
          if ( //? Skip if user is filtering earned and the trophy was earned
              (trophiesArray[i]['timestamp'] != null &&
                      trophySettings['earned'] == false) ||
                  //? Skip if the user is filtering unearned and the trophy wasn't earned yet
                  (trophiesArray[i]['timestamp'] == null &&
                      (trophySettings['unearned'] == false ||
                          trophySettings['sorting'] == 'earnedTimestamp')) ||
                  //? Skip if the user is filtering secret trophies and the trophy is marked as hidden
                  (trophiesArray[i]['hidden'] == true &&
                      trophySettings['showHidden'] == false) ||
                  //? Skip if the user is filtering non-UR trophies and the trophy has more than 5% rarity
                  (trophiesArray[i]['rarity'] > 5 &&
                      trophySettings['urOnly'] == true) ||
                  //? Skip if the user is filtering common trophies and the trophy has more than 50% rarity
                  (trophiesArray[i]['rarity'] > 50 &&
                      trophySettings['noCommons'] == true)) {
            continue;
          }
          _displayedTrophies++;
          trophyWidgets.add(Tooltip(
            message:
                '${trophySettings['hidden'] != false || trophiesArray[i]['hidden'] != true ? trophiesArray[i]['name'] : "???"} (${trophiesArray[i]['rarity']}%)',
            child: Container(
              margin: EdgeInsets.all(Platform.isWindows ? 2 : 0.5),
              decoration: BoxDecoration(
                  color: themeSelector["primary"][settings.get("theme")]
                      .withOpacity(0.8),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  border: Border.all(
                      width: Platform.isWindows ? 5 : 3,
                      color: trophiesArray[i]['timestamp'] != null
                          ? Colors.green
                          : Colors.red)),
              height: Platform.isWindows ? 80 : 50,
              width: Platform.isWindows ? 80 : 50,
              child: CachedNetworkImage(
                  imageUrl: trophySettings['hidden'] != false ||
                          trophiesArray[i]['hidden'] != true
                      ? trophiesArray[i]['image']
                      : "https://www.exophase.com/assets/zeal/images/default_hidden.png",
                  fit: BoxFit.fill),
            ),
          ));
        }
      }

      trophyWidgets = [
        //? This first item is meant to be a banner on the top of the screen
        //? Using the game image as blurred background and with one special trophy
        //? Usually the platinum or rarest in the list having the highlight in the middle as podium
        Container(
          width: MediaQuery.of(context).size.width,
          height: Platform.isWindows ? 220 : 115,
          decoration: BoxDecoration(
            // color: ,
            image: DecorationImage(
              fit: BoxFit.fitWidth,
              image: CachedNetworkImageProvider(
                trophyDataMap != null && trophyDataMap['gameHeader'] != null
                    ? trophyDataMap['gameHeader']
                    : "https://www.exophase.com/assets/zeal/logos/exologo_bw.png",
                maxWidth: MediaQuery.of(context).size.width.floor(),
              ),
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: SizedBox()),
                  if (trophyDataMap['podium'] != null)
                    Tooltip(
                      message:
                          "${trophyDataMap['podium']['name']} (${trophyDataMap['podium']['rarity']}%)",
                      child: CachedNetworkImage(
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                        imageUrl: trophyDataMap != null
                            ? trophyDataMap['podium']['image']
                            : "https://i.exophase.com/psn/awards/m/75d8eg.png",
                      ),
                    ),
                  SizedBox(height: 10)
                ],
              ),
            ),
          ),
        ),
        //? Just below the banner, display the trophy counter for the displayed game
        Container(
          color: themeSelector["secondary"][settings.get("theme")],
          width: MediaQuery.of(context).size.width,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (trophyDataMap['platinumCount'] > 0)
                Padding(
                  padding: EdgeInsets.all(5.0),
                  child: trophyType('platinum',
                      quantity:
                          '${trophyListData['gamePlatinum'] ?? 0}/${trophyDataMap['platinumCount']}',
                      style: textSelection(theme: "textDark")),
                ),
              if (trophyDataMap['goldCount'] > 0)
                Padding(
                  padding: EdgeInsets.all(5.0),
                  child: trophyType('gold',
                      quantity:
                          '${trophyListData['gameGold'] ?? 0}/${trophyDataMap['goldCount']}',
                      style: textSelection(theme: "textDark")),
                ),
              if (trophyDataMap['silverCount'] > 0)
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: trophyType('silver',
                      quantity:
                          '${trophyListData['gameSilver'] ?? 0}/${trophyDataMap['silverCount']}',
                      style: textSelection(theme: "textDark")),
                ),
              if (trophyDataMap['bronzeCount'] > 0)
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: trophyType('bronze',
                      quantity:
                          '${trophyListData['gameBronze'] ?? 0}/${trophyDataMap['bronzeCount']}',
                      style: textSelection(theme: "textDark")),
                ),
              Padding(
                padding: EdgeInsets.all(5.0),
                child: trophyType('total',
                    quantity: '${trophyListData['gameRatio']}',
                    style: textSelection(theme: "textDark")),
              ),
              SizedBox(width: Platform.isWindows ? 20 : 10),
              Text(
                "${regionalText["trophies"]["trophies"]} ${_displayedTrophies.toString()}",
                style: textSelection(theme: "textDark"),
              ),
            ],
          ),
        ),
        ...trophyWidgets
      ];
      listDisplay = SingleChildScrollView(
        child: Wrap(
          alignment: WrapAlignment.center,
          children: trophyWidgets,
        ),
      );
    } else if (trophySettings['trophyDisplay'] == "minimal") {
      for (var i = 0; i < trophiesArray.length; i++) {
        //? This adds a DLC separator tile with its image, if available
        if (trophiesArray[i] is List) {
          if (trophySettings['DLCseparator'] != false &&
              trophiesArray[i][0] != "base") {
            trophyWidgets.add(
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: Platform.isWindows ? 10 : 3,
                    horizontal: Platform.isWindows ? 10 : 3),
                child: Container(
                  width: MediaQuery.of(context).size.width -
                      (Platform.isWindows ? 30 : 5),
                  child: Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        color: themeSelector["primary"][settings.get("theme")],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            width: Platform.isWindows ? 5 : 3,
                            color: themeSelector["secondary"]
                                [settings.get("theme")])),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (trophiesArray[i][1] != null)
                          CachedNetworkImage(
                              imageUrl: trophySettings['hidden'] != false ||
                                      trophiesArray[i]['hidden'] != true
                                  ? trophiesArray[i][1]
                                  : "https://www.exophase.com/assets/zeal/images/default_hidden.png",
                              fit: BoxFit.fill),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            child: Text(
                              trophiesArray[i][0],
                              style: textSelection(theme: "textLightBold"),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        } //? This adds the trophy tile and all of its information.
        else {
          if ( //? Skip if user is filtering earned and the trophy was earned
              (trophiesArray[i]['timestamp'] != null &&
                      trophySettings['earned'] == false) ||
                  //? Skip if the user is filtering unearned and the trophy wasn't earned yet
                  (trophiesArray[i]['timestamp'] == null &&
                      (trophySettings['unearned'] == false ||
                          trophySettings['sorting'] == 'earnedTimestamp')) ||
                  //? Skip if the user is filtering secret trophies and the trophy is marked as hidden
                  (trophiesArray[i]['hidden'] == true &&
                      trophySettings['showHidden'] == false) ||
                  //? Skip if the user is filtering non-UR trophies and the trophy has more than 5% rarity
                  (trophiesArray[i]['rarity'] > 5 &&
                      trophySettings['urOnly'] == true) ||
                  //? Skip if the user is filtering common trophies and the trophy has more than 50% rarity
                  (trophiesArray[i]['rarity'] > 50 &&
                      trophySettings['noCommons'] == true)) {
            continue;
          }
          _displayedTrophies++;
          trophyWidgets.add(Container(
              margin: EdgeInsets.symmetric(
                  vertical: Platform.isWindows ? 2 : 1,
                  horizontal: Platform.isWindows ? 5 : 3),
              decoration: BoxDecoration(
                color: themeSelector["primary"][settings.get("theme")]
                    .withOpacity(0.8),
                borderRadius: BorderRadius.all(Radius.circular(10)),
                border: Border.all(
                    width: Platform.isWindows ? 5 : 3,
                    color: trophiesArray[i]['timestamp'] != null
                        ? Colors.green
                        : Colors.red),
              ),
              // width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: EdgeInsets.all(Platform.isWindows ? 7 : 5),
                  child: Row(
                    children: [
                      //? Trophy type
                      trophyType(trophiesArray[i]['type'], size: "small"),
                      SizedBox(width: 3),
                      //? Trophy name
                      Text(
                        trophySettings['hidden'] != false ||
                                trophiesArray[i]['hidden'] != true
                            ? trophiesArray[i]['name']
                            : "???",
                        style: textSelection(theme: "textLightBold"),
                        textAlign: TextAlign.left,
                      ),
                      //? Trophy rarity, if avaiable
                      if (trophiesArray[i]['rarity'] != null)
                        Text(
                          " (${trophiesArray[i]['rarity']}%)",
                          style: textSelection(theme: "textLightBold"),
                          textAlign: TextAlign.left,
                        ),
                    ],
                  ),
                ),
              )));
        }
      }
      trophyWidgets = [
        //? This first item is meant to be a banner on the top of the screen
        //? Using the game image as blurred background and with one special trophy
        //? Usually the platinum or rarest in the list having the highlight in the middle as podium
        Container(
          width: MediaQuery.of(context).size.width,
          height: Platform.isWindows ? 220 : 115,
          decoration: BoxDecoration(
            // color: ,
            image: DecorationImage(
              fit: BoxFit.fitWidth,
              image: CachedNetworkImageProvider(
                trophyDataMap != null && trophyDataMap['gameHeader'] != null
                    ? trophyDataMap['gameHeader']
                    : "https://www.exophase.com/assets/zeal/logos/exologo_bw.png",
                maxWidth: MediaQuery.of(context).size.width.floor(),
              ),
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: SizedBox()),
                  if (trophyDataMap['podium'] != null)
                    Tooltip(
                      message:
                          "${trophyDataMap['podium']['name']} (${trophyDataMap['podium']['rarity']}%)",
                      child: CachedNetworkImage(
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                        imageUrl: trophyDataMap != null
                            ? trophyDataMap['podium']['image']
                            : "https://i.exophase.com/psn/awards/m/75d8eg.png",
                      ),
                    ),
                  SizedBox(height: 10)
                ],
              ),
            ),
          ),
        ),
        //? Just below the banner, display the trophy counter for the displayed game
        Container(
          color: themeSelector["secondary"][settings.get("theme")],
          width: MediaQuery.of(context).size.width,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (trophyDataMap['platinumCount'] > 0)
                Padding(
                  padding: EdgeInsets.all(5.0),
                  child: trophyType('platinum',
                      quantity:
                          '${trophyListData['gamePlatinum'] ?? 0}/${trophyDataMap['platinumCount']}',
                      style: textSelection(theme: "textDark")),
                ),
              if (trophyDataMap['goldCount'] > 0)
                Padding(
                  padding: EdgeInsets.all(5.0),
                  child: trophyType('gold',
                      quantity:
                          '${trophyListData['gameGold'] ?? 0}/${trophyDataMap['goldCount']}',
                      style: textSelection(theme: "textDark")),
                ),
              if (trophyDataMap['silverCount'] > 0)
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: trophyType('silver',
                      quantity:
                          '${trophyListData['gameSilver'] ?? 0}/${trophyDataMap['silverCount']}',
                      style: textSelection(theme: "textDark")),
                ),
              if (trophyDataMap['bronzeCount'] > 0)
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: trophyType('bronze',
                      quantity:
                          '${trophyListData['gameBronze'] ?? 0}/${trophyDataMap['bronzeCount']}',
                      style: textSelection(theme: "textDark")),
                ),
              Padding(
                padding: EdgeInsets.all(5.0),
                child: trophyType('total',
                    quantity: '${trophyListData['gameRatio']}',
                    style: textSelection(theme: "textDark")),
              ),
              SizedBox(width: Platform.isWindows ? 20 : 10),
              Text(
                "${regionalText["trophies"]["trophies"]} ${_displayedTrophies.toString()}",
                style: textSelection(theme: "textDark"),
              ),
            ],
          ),
        ),
        ...trophyWidgets
      ];
      listDisplay = Container(
        height: MediaQuery.of(context).size.height,
        child: ListView.builder(
          itemCount: trophyWidgets.length,
          itemBuilder: (context, index) => trophyWidgets[index],
        ),
      );
    } else if (trophySettings['trophyDisplay'] == "list") {
      for (var i = 0; i < trophiesArray.length; i++) {
        //? This adds a DLC separator tile with its image, if available
        if (trophiesArray[i] is List) {
          if (trophySettings['DLCseparator'] != false &&
              trophiesArray[i][0] != "base") {
            trophyWidgets.add(
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: Platform.isWindows ? 10 : 3,
                    horizontal: Platform.isWindows ? 10 : 3),
                child: Container(
                  width: MediaQuery.of(context).size.width -
                      (Platform.isWindows ? 30 : 5),
                  child: Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        color: themeSelector["primary"][settings.get("theme")],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            width: Platform.isWindows ? 5 : 3,
                            color: themeSelector["secondary"]
                                [settings.get("theme")])),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (trophiesArray[i][1] != null)
                          CachedNetworkImage(
                              imageUrl: trophySettings['hidden'] != false ||
                                      trophiesArray[i]['hidden'] != true
                                  ? trophiesArray[i][1]
                                  : "https://www.exophase.com/assets/zeal/images/default_hidden.png",
                              fit: BoxFit.fill),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            child: Text(
                              trophiesArray[i][0],
                              style: textSelection(theme: "textLightBold"),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        } //? This adds the trophy tile and all of its information.
        else {
          if ( //? Skip if user is filtering earned and the trophy was earned
              (trophiesArray[i]['timestamp'] != null &&
                      trophySettings['earned'] == false) ||
                  //? Skip if the user is filtering unearned and the trophy wasn't earned yet
                  (trophiesArray[i]['timestamp'] == null &&
                      (trophySettings['unearned'] == false ||
                          trophySettings['sorting'] == 'earnedTimestamp')) ||
                  //? Skip if the user is filtering secret trophies and the trophy is marked as hidden
                  (trophiesArray[i]['hidden'] == true &&
                      trophySettings['showHidden'] == false) ||
                  //? Skip if the user is filtering non-UR trophies and the trophy has more than 5% rarity
                  (trophiesArray[i]['rarity'] > 5 &&
                      trophySettings['urOnly'] == true) ||
                  //? Skip if the user is filtering common trophies and the trophy has more than 50% rarity
                  (trophiesArray[i]['rarity'] > 50 &&
                      trophySettings['noCommons'] == true)) {
            continue;
          }
          _displayedTrophies++;
          trophyWidgets.add(Container(
              margin: EdgeInsets.symmetric(
                  vertical: Platform.isWindows ? 1 : 0.5,
                  horizontal: Platform.isWindows ? 5 : 3),
              decoration: BoxDecoration(
                  color: themeSelector["primary"][settings.get("theme")]
                      .withOpacity(0.8),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  border: Border.all(
                      width: Platform.isWindows ? 5 : 3,
                      color: trophiesArray[i]['timestamp'] != null
                          ? Colors.green
                          : Colors.red)),
              // width: MediaQuery.of(context).size.width,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  //? Trophy image
                  Container(
                    height: Platform.isWindows ? 80 : 60,
                    width: Platform.isWindows ? 80 : 60,
                    child: CachedNetworkImage(
                      fit: BoxFit.fill,
                      imageUrl: trophySettings['hidden'] != false ||
                              trophiesArray[i]['hidden'] != true
                          ? trophiesArray[i]['image']
                          : "https://www.exophase.com/assets/zeal/images/default_hidden.png",
                    ),
                  ),
                  //? Column with trophy type, name, rarity, exp + description + earned timestamp
                  Container(
                    width: MediaQuery.of(context).size.width -
                        (Platform.isWindows ? 105 : 80),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: EdgeInsets.all(Platform.isWindows ? 10.0 : 5),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //? Trophy type, name, rarity, exp
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                //? Trophy type
                                trophyType(trophiesArray[i]['type'],
                                    size: "small"),
                                SizedBox(width: 3),
                                //? Trophy name
                                Text(
                                  trophySettings['hidden'] != false ||
                                          trophiesArray[i]['hidden'] != true
                                      ? trophiesArray[i]['name']
                                      : "???",
                                  style: textSelection(theme: "textLightBold"),
                                  textAlign: TextAlign.left,
                                ),
                                //? Trophy rarity, if avaiable
                                if (trophiesArray[i]['rarity'] != null)
                                  Text(
                                    " (${trophiesArray[i]['rarity']}%)",
                                    style:
                                        textSelection(theme: "textLightBold"),
                                    textAlign: TextAlign.left,
                                  ),
                                //? Trophy EXP for exophase
                                if (trophiesArray[i]['exp'] != null)
                                  Row(
                                    children: [
                                      SizedBox(width: 3),
                                      CachedNetworkImage(
                                          imageUrl:
                                              "https://www.exophase.com/assets/zeal/_icons/favicon.ico",
                                          height: Platform.isWindows ? 15 : 10),
                                      Text(
                                        " ${trophiesArray[i]['exp']}",
                                        style: textSelection(
                                            theme: "textLightBold"),
                                        textAlign: TextAlign.left,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            //? Trophy description
                            Container(
                              child: Text(
                                trophySettings['hidden'] != false ||
                                        trophiesArray[i]['hidden'] != true
                                    ? trophiesArray[i]['description']
                                    : "?????",
                                style: textSelection(),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            //? Trophy timestamp
                            if (trophiesArray[i]['timestamp'] != null)
                              Container(
                                child: Text(
                                  trophiesArray[i]['parsedTimestamp']
                                      .toString(),
                                  style: textSelection(),
                                  textAlign: TextAlign.left,
                                ),
                              )
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              )));
        }
      }
      trophyWidgets = [
        //? This first item is meant to be a banner on the top of the screen
        //? Using the game image as blurred background and with one special trophy
        //? Usually the platinum or rarest in the list having the highlight in the middle as podium
        Container(
          width: MediaQuery.of(context).size.width,
          height: Platform.isWindows ? 220 : 115,
          decoration: BoxDecoration(
            // color: ,
            image: DecorationImage(
              fit: BoxFit.fitWidth,
              image: CachedNetworkImageProvider(
                trophyDataMap != null && trophyDataMap['gameHeader'] != null
                    ? trophyDataMap['gameHeader']
                    : "https://www.exophase.com/assets/zeal/logos/exologo_bw.png",
                maxWidth: MediaQuery.of(context).size.width.floor(),
              ),
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: SizedBox()),
                  if (trophyDataMap['podium'] != null)
                    Tooltip(
                      message:
                          "${trophyDataMap['podium']['name']} (${trophyDataMap['podium']['rarity']}%)",
                      child: CachedNetworkImage(
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                        imageUrl: trophyDataMap != null
                            ? trophyDataMap['podium']['image']
                            : "https://i.exophase.com/psn/awards/m/75d8eg.png",
                      ),
                    ),
                  SizedBox(height: 10)
                ],
              ),
            ),
          ),
        ),
        //? Just below the banner, display the trophy counter for the displayed game
        Container(
          color: themeSelector["secondary"][settings.get("theme")],
          width: MediaQuery.of(context).size.width,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (trophyDataMap['platinumCount'] > 0)
                Padding(
                  padding: EdgeInsets.all(5.0),
                  child: trophyType('platinum',
                      quantity:
                          '${trophyListData['gamePlatinum'] ?? 0}/${trophyDataMap['platinumCount']}',
                      style: textSelection(theme: "textDark")),
                ),
              if (trophyDataMap['goldCount'] > 0)
                Padding(
                  padding: EdgeInsets.all(5.0),
                  child: trophyType('gold',
                      quantity:
                          '${trophyListData['gameGold'] ?? 0}/${trophyDataMap['goldCount']}',
                      style: textSelection(theme: "textDark")),
                ),
              if (trophyDataMap['silverCount'] > 0)
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: trophyType('silver',
                      quantity:
                          '${trophyListData['gameSilver'] ?? 0}/${trophyDataMap['silverCount']}',
                      style: textSelection(theme: "textDark")),
                ),
              if (trophyDataMap['bronzeCount'] > 0)
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: trophyType('bronze',
                      quantity:
                          '${trophyListData['gameBronze'] ?? 0}/${trophyDataMap['bronzeCount']}',
                      style: textSelection(theme: "textDark")),
                ),
              Padding(
                padding: EdgeInsets.all(5.0),
                child: trophyType('total',
                    quantity: '${trophyListData['gameRatio']}',
                    style: textSelection(theme: "textDark")),
              ),
              SizedBox(width: Platform.isWindows ? 20 : 10),
              Text(
                "${regionalText["trophies"]["trophies"]} ${_displayedTrophies.toString()}",
                style: textSelection(theme: "textDark"),
              ),
            ],
          ),
        ),
        ...trophyWidgets
      ];
      listDisplay = Container(
        height: MediaQuery.of(context).size.height,
        child: ListView.builder(
          itemCount: trophyWidgets.length,
          itemBuilder: (context, index) => trophyWidgets[index],
        ),
      );
    }
    return listDisplay;
  }

  //? This Map holds the trophy list data to be used to populate the page
  Map<String, dynamic> trophyDataMap;

  //? This boolean stores if the update has started or not.
  bool updateStart = false;

  _TrophyListState(this.trophyListData);
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: trophyDataMap == null
          ? null
          : AppBar(
              titleSpacing: 0,
              toolbarHeight: 40,
              centerTitle: true,
              backgroundColor: themeSelector["primary"][settings.get("theme")],
              title: Text(
                "${settings.get('psnID')}'s ${trophyListData['gameName']} (${trophyListData['gamePercentage']}%)",
                style: textSelection(theme: "textLightBold"),
              ),
            ),
      body: Container(
        // height: MediaQuery.of(context).size.height + 220,
        decoration: backgroundDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //? This contains all trophy data, including the top banner and the trophy list.
            Container(
              child: Expanded(
                child: FutureBuilder(
                    future: Future(() => trophyDataMap),
                    builder: (context, snapshot) {
                      if (!updateStart) {
                        updateStart = true;
                        Future(() async {
                          trophyDataMap =
                              await requestWebsite(trophyListData['gameLink']);
                          setState(() {
                            trophyDataMap = trophyDataMap;
                          });
                        });
                      }
                      //? Display card info if all information is successfully fetched
                      if (snapshot.data != null) {
                        return trophyListDisplay();
                      } else {
                        return Center(
                            child: loadingSelector(
                                settings.get('loading'), "dark"));
                      }
                    }),
              ),
            ),
            //? This is the bottom bar containing the filters and sorting options for the trophy list.
            if (trophyDataMap != null)
              Container(
                width: MediaQuery.of(context).size.width,
                padding:
                    EdgeInsets.symmetric(vertical: Platform.isWindows ? 5 : 3),
                color: themeSelector["secondary"][settings.get("theme")],
                child: Column(
                  children: [
                    //? This Wrap contains the 3 rows of options: Filter, Sort and Display
                    if (trophySettings['filter'] == true)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Text(
                              regionalText['trophies']['filter'],
                              style: textSelection(theme: "textDark"),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              //? Filter out unearned trophies and add in earned trophies if they were filtered
                              Tooltip(
                                message: regionalText['trophies']['unearned'],
                                child: InkWell(
                                    child: Container(
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color:
                                                  trophySettings['unearned'] !=
                                                          true
                                                      ? Colors.red
                                                      : Colors.green,
                                              width:
                                                  Platform.isWindows ? 5 : 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child: Icon(
                                            Icons.check_box_outline_blank,
                                            color: themeSelector["primary"]
                                                [settings.get("theme")],
                                            size:
                                                Platform.isWindows ? 35 : 17)),
                                    onTap: () {
                                      setState(() {
                                        if (trophySettings['unearned'] !=
                                            true) {
                                          trophySettings['unearned'] = true;
                                        } else {
                                          //? since complete and incomplete filters are mutually exclusive,
                                          //? activating one on must turn off the other
                                          trophySettings['unearned'] = false;
                                          trophySettings['earned'] = true;
                                        }
                                      });
                                    }),
                              ),
                              //? Filter out earned trophies and add in unearned trophies if they were filtered
                              Tooltip(
                                message: regionalText['trophies']['earned'],
                                child: InkWell(
                                    child: Container(
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color: trophySettings['earned'] !=
                                                      true
                                                  ? Colors.red
                                                  : Colors.green,
                                              width:
                                                  Platform.isWindows ? 5 : 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child: Icon(Icons.check_box,
                                            color: themeSelector["primary"]
                                                [settings.get("theme")],
                                            size:
                                                Platform.isWindows ? 35 : 17)),
                                    onTap: () {
                                      setState(() {
                                        if (trophySettings['earned'] != true) {
                                          trophySettings['earned'] = true;
                                        } else {
                                          //? since complete and incomplete filters are mutually exclusive,
                                          //? activating one on must turn off the other
                                          trophySettings['earned'] = false;
                                          trophySettings['unearned'] = true;
                                        }
                                        settings.put(
                                            'trophySettings', trophySettings);
                                      });
                                    }),
                              ),
                              //? Filter hidden trophies
                              Tooltip(
                                message: regionalText['trophies']['hidden'],
                                child: InkWell(
                                    child: Container(
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color: trophySettings[
                                                          'showHidden'] !=
                                                      true
                                                  ? Colors.red
                                                  : Colors.green,
                                              width:
                                                  Platform.isWindows ? 5 : 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child: Icon(
                                            trophySettings['showHidden'] != true
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: themeSelector["primary"]
                                                [settings.get("theme")],
                                            size:
                                                Platform.isWindows ? 35 : 17)),
                                    onTap: () {
                                      setState(() {
                                        if (trophySettings['showHidden'] !=
                                            true) {
                                          trophySettings['showHidden'] = true;
                                        } else {
                                          trophySettings['showHidden'] = false;
                                        }
                                        settings.put(
                                            'trophySettings', trophySettings);
                                      });
                                    }),
                              ),
                              //? Filter non-UR trophies
                              Tooltip(
                                message: regionalText['trophies']['urOnly'],
                                child: InkWell(
                                    child: Container(
                                      // width: Platform.isWindows ? 35 : 17,
                                      decoration: BoxDecoration(
                                        //? To paint the border, we check the value of the settings for this website is true.
                                        //? If it's false or null (never set), we will paint red.
                                        border: Border.all(
                                            color:
                                                trophySettings['urOnly'] == true
                                                    ? Colors.green
                                                    : Colors.red,
                                            width: Platform.isWindows ? 5 : 2),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      child: Image.asset(
                                        img['rarity6'],
                                        fit: BoxFit.fitHeight,
                                        height: Platform.isWindows ? 35 : 17,
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        if (trophySettings['urOnly'] != true) {
                                          trophySettings['urOnly'] = true;
                                        } else {
                                          trophySettings['urOnly'] = false;
                                        }
                                        settings.put(
                                            'trophySettings', trophySettings);
                                      });
                                    }),
                              ),
                              //? Filter common trophies
                              Tooltip(
                                message: regionalText['trophies']['noCommons'],
                                child: InkWell(
                                    child: Container(
                                      // width: 40,
                                      decoration: BoxDecoration(
                                        //? To paint the border, we check the value of the settings for this website is true.
                                        //? If it's false or null (never set), we will paint red.
                                        border: Border.all(
                                            color:
                                                trophySettings['noCommons'] ==
                                                        true
                                                    ? Colors.red
                                                    : Colors.green,
                                            width: Platform.isWindows ? 5 : 2),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      child: Stack(
                                          alignment:
                                              AlignmentDirectional.center,
                                          children: [
                                            Image.asset(
                                              img['rarity1'],
                                              fit: BoxFit.fitHeight,
                                              height:
                                                  Platform.isWindows ? 35 : 17,
                                            ),
                                            Icon(
                                              Icons.not_interested,
                                              color: Colors.red,
                                              size:
                                                  Platform.isWindows ? 35 : 17,
                                            )
                                          ]),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        if (trophySettings['noCommons'] !=
                                            true) {
                                          trophySettings['noCommons'] = true;
                                        } else {
                                          trophySettings['noCommons'] = false;
                                        }
                                        settings.put(
                                            'trophySettings', trophySettings);
                                      });
                                    }),
                              ),
                            ],
                          ),
                        ],
                      ),
                    //? This Row lets you sort trophies in a specific order.
                    if (trophySettings['sort'] == true)
                      Container(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: Text(
                                  regionalText['trophies']['sort'],
                                  style: textSelection(theme: "textDark"),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(width: 3),
                                  //? Sort trophies by original order
                                  Tooltip(
                                    message: regionalText['trophies']
                                        ['original'],
                                    child: Container(
                                      decoration: BoxDecoration(
                                        //? To paint the border, we check the value of the settings for this website is true.
                                        //? If it's false or null (never set), we will paint red.
                                        border: Border.all(
                                            color: trophySettings['sorting'] ==
                                                    'original'
                                                ? Colors.green
                                                : Colors.transparent,
                                            width: Platform.isWindows ? 5 : 2),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      child: InkWell(
                                        child: Text(
                                          "PSN",
                                          style:
                                              textSelection(theme: "textDark"),
                                          textAlign: TextAlign.center,
                                        ),
                                        onTap: () {
                                          if (trophySettings['sorting'] !=
                                              "original") {
                                            setState(() {
                                              trophySettings['sorting'] =
                                                  "original";
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  //? Sort trophies by trophy value (platinum > gold > silver > bronze)
                                  Tooltip(
                                    message: regionalText['trophies']['value'],
                                    child: Container(
                                      decoration: BoxDecoration(
                                        //? To paint the border, we check the value of the settings for this website is true.
                                        //? If it's false or null (never set), we will paint red.
                                        border: Border.all(
                                            color: trophySettings['sorting'] ==
                                                    'value'
                                                ? Colors.green
                                                : Colors.transparent,
                                            width: Platform.isWindows ? 5 : 2),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      child: InkWell(
                                        child:
                                            trophyType("platinum", size: "big"),
                                        onTap: () {
                                          if (trophySettings['sorting'] !=
                                              "value") {
                                            setState(() {
                                              trophySettings['sorting'] =
                                                  "value";
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  //? Sort trophies by ascending Alphabetical (A to Z)
                                  Tooltip(
                                    message: regionalText['trophies']
                                        ['alphabetical'],
                                    child: InkWell(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color:
                                                  trophySettings['sorting'] ==
                                                          'alphabetical'
                                                      ? Colors.green
                                                      : Colors.transparent,
                                              width:
                                                  Platform.isWindows ? 5 : 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child: Text(
                                          "ABC",
                                          style:
                                              textSelection(theme: "textDark"),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      onTap: () {
                                        if (trophySettings['sorting'] !=
                                            "alphabetical") {
                                          setState(() {
                                            trophySettings['sorting'] =
                                                "alphabetical";
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  //? Sort games by descending Alphabetical (Z to A)
                                  Tooltip(
                                    message: regionalText['trophies']['rarity'],
                                    child: InkWell(
                                      child: Container(
                                        height: Platform.isWindows ? 35 : 17,
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color:
                                                  trophySettings['sorting'] ==
                                                          'rarity'
                                                      ? Colors.green
                                                      : Colors.transparent,
                                              width:
                                                  Platform.isWindows ? 5 : 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child: Image.asset(
                                          img['rarity7'],
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                      onTap: () {
                                        if (trophySettings['sorting'] !=
                                            "rarity") {
                                          setState(() {
                                            trophySettings['sorting'] =
                                                "rarity";
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  //? Sort trophies by earned timestamp
                                  Tooltip(
                                    message: regionalText['trophies']
                                        ['earnedTimestamp'],
                                    child: Container(
                                      decoration: BoxDecoration(
                                        //? To paint the border, we check the value of the settings for this website is true.
                                        //? If it's false or null (never set), we will paint red.
                                        border: Border.all(
                                            color: trophySettings['sorting'] ==
                                                    'earnedTimestamp'
                                                ? Colors.green
                                                : Colors.transparent,
                                            width: Platform.isWindows ? 5 : 2),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      child: InkWell(
                                        child: Text(
                                          "🆕",
                                          style: textSelection(
                                            theme: "textDarkBold",
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        onTap: () {
                                          if (trophySettings['sorting'] !=
                                              "earnedTimestamp") {
                                            setState(() {
                                              trophySettings['sorting'] =
                                                  "earnedTimestamp";
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    //? This Row lets you filter in and out specific types of trophies.
                    if (trophySettings['settings'] == true)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Text(
                              regionalText['trophies']['settings'],
                              style: textSelection(theme: "textDark"),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              //? Hide hidden trophies
                              Tooltip(
                                message: regionalText['trophies']['hidden'],
                                child: InkWell(
                                    child: Container(
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color: trophySettings['hidden'] !=
                                                      true
                                                  ? Colors.red
                                                  : Colors.green,
                                              width:
                                                  Platform.isWindows ? 5 : 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child: Icon(
                                            trophySettings['hidden'] != true
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: themeSelector["primary"]
                                                [settings.get("theme")],
                                            size:
                                                Platform.isWindows ? 35 : 17)),
                                    onTap: () {
                                      setState(() {
                                        if (trophySettings['hidden'] != true) {
                                          trophySettings['hidden'] = true;
                                        } else {
                                          trophySettings['hidden'] = false;
                                        }
                                        settings.put(
                                            'trophySettings', trophySettings);
                                      });
                                    }),
                              ),
                              //? Disable DLC separators (group all trophies together as one big list)
                              if (trophySettings['sorting'] == 'original')
                                Tooltip(
                                  message: regionalText['trophies']
                                      ['DLCseparator'],
                                  child: InkWell(
                                      child: Container(
                                        // height: Platform.isWindows ? 50 : 25,
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color: trophySettings[
                                                          'DLCseparator'] !=
                                                      false
                                                  ? Colors.green
                                                  : Colors.red,
                                              width:
                                                  Platform.isWindows ? 5 : 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child: Icon(
                                            trophySettings['DLCseparator'] !=
                                                    true
                                                ? Icons.view_comfy
                                                : Icons.list,
                                            color: themeSelector["primary"]
                                                [settings.get("theme")],
                                            size: Platform.isWindows ? 35 : 17),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          if (trophySettings['DLCseparator'] !=
                                              true) {
                                            trophySettings['DLCseparator'] =
                                                true;
                                          } else {
                                            trophySettings['DLCseparator'] =
                                                false;
                                          }
                                          settings.put(
                                              'trophySettings', trophySettings);
                                        });
                                      }),
                                ),
                              Tooltip(
                                message: regionalText['trophies']
                                    ['localization'],
                                child: InkWell(
                                    child: Container(
                                      // height: 40,
                                      // height: Platform.isWindows ? 50 : 25,
                                      decoration: BoxDecoration(
                                        //? To paint the border, we check the value of the settings for this website is true.
                                        //? If it's false or null (never set), we will paint red.
                                        border: Border.all(
                                            color: trophySettings[
                                                        'localization'] ==
                                                    true
                                                ? Colors.green
                                                : Colors.red,
                                            width: Platform.isWindows ? 5 : 2),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      child: Icon(Icons.public,
                                          color: themeSelector["primary"]
                                              [settings.get("theme")],
                                          size: Platform.isWindows ? 35 : 17),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        if (trophySettings['localization'] !=
                                            true) {
                                          trophySettings['localization'] = true;
                                        } else {
                                          trophySettings['localization'] =
                                              false;
                                        }
                                        settings.put(
                                            'trophySettings', trophySettings);
                                        Navigator.pop(context);
                                      });
                                    }),
                              ),
                            ],
                          ),
                        ],
                      ),
                    //? This Row lets you change the view style for the trophy lists
                    if (trophySettings['display'] == true)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 10),
                          Text(
                            regionalText['trophies']['display'],
                            style: textSelection(theme: "textDark"),
                            textAlign: TextAlign.center,
                          ),
                          //? Option to use view trophy lists as a list
                          if (trophySettings['trophyDisplay'] != "list")
                            Tooltip(
                              message: regionalText['trophies']['list'],
                              child: InkWell(
                                  child: Icon(Icons.list,
                                      color: themeSelector["primary"]
                                          [settings.get("theme")],
                                      size: Platform.isWindows ? 35 : 17),
                                  hoverColor: Colors.transparent,
                                  splashColor: Colors.transparent,
                                  onTap: () => {
                                        setState(() {
                                          trophySettings['trophyDisplay'] =
                                              "list";
                                        }),
                                        settings.put(
                                            'trophySettings', trophySettings)
                                      }),
                            ),
                          //? Option to use view trophy lists as a minimalist
                          if (trophySettings['trophyDisplay'] != "minimal")
                            Tooltip(
                              message: regionalText['trophies']['minimal'],
                              child: InkWell(
                                  child: Icon(
                                    Icons.more_vert,
                                    color: themeSelector["primary"]
                                        [settings.get("theme")],
                                    size: Platform.isWindows ? 35 : 17,
                                  ),
                                  hoverColor: Colors.transparent,
                                  splashColor: Colors.transparent,
                                  onTap: () => {
                                        setState(() {
                                          trophySettings['trophyDisplay'] =
                                              "minimal";
                                        }),
                                        settings.put(
                                            'trophySettings', trophySettings)
                                      }),
                            ),
                          //? Option to use view trophy lists as a grid
                          if (trophySettings['trophyDisplay'] != "grid")
                            Tooltip(
                              message: regionalText['trophies']['grid'],
                              child: InkWell(
                                  child: Icon(Icons.view_comfy,
                                      color: themeSelector["primary"]
                                          [settings.get("theme")],
                                      size: Platform.isWindows ? 35 : 17),
                                  hoverColor: Colors.transparent,
                                  splashColor: Colors.transparent,
                                  onTap: () => {
                                        setState(() {
                                          trophySettings['trophyDisplay'] =
                                              "grid";
                                        }),
                                        settings.put(
                                            'trophySettings', trophySettings)
                                      }),
                            ),
                        ],
                      ),
                    //? This Row contains the toggles to display the items above
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          regionalText['trophies']['options'],
                          style: textSelection(theme: "textDark"),
                          textAlign: TextAlign.center,
                        ),
                        //? Filter
                        Tooltip(
                          message: regionalText['trophies']['filter'],
                          child: InkWell(
                              child: Container(
                                decoration: BoxDecoration(
                                  //? To paint the border, we check the value of the settings for this website is true.
                                  //? If it's false or null (never set), we will paint red.
                                  border: Border.all(
                                      color: trophySettings['filter'] != true
                                          ? Colors.transparent
                                          : Colors.green,
                                      width: Platform.isWindows ? 5 : 2),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
                                ),
                                child: Icon(Icons.filter_alt,
                                    color: themeSelector["primary"]
                                        [settings.get("theme")],
                                    size: Platform.isWindows ? 30 : 17),
                              ),
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onTap: () => {
                                    setState(() {
                                      if (trophySettings['filter'] != true) {
                                        trophySettings['filter'] = true;
                                        trophySettings['sort'] = false;
                                        trophySettings['settings'] = false;
                                        trophySettings['display'] = false;
                                      } else {
                                        trophySettings['filter'] = false;
                                      }
                                    }),
                                    settings.put(
                                        'trophySettings', trophySettings)
                                  }),
                        ),
                        //? Sorting
                        Tooltip(
                          message: regionalText['trophies']['sort'],
                          child: InkWell(
                              child: Container(
                                decoration: BoxDecoration(
                                  //? To paint the border, we check the value of the settings for this website is true.
                                  //? If it's false or null (never set), we will paint red.
                                  border: Border.all(
                                      color: trophySettings['sort'] != true
                                          ? Colors.transparent
                                          : Colors.green,
                                      width: Platform.isWindows ? 5 : 2),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
                                ),
                                child: Icon(Icons.sort_by_alpha,
                                    color: themeSelector["primary"]
                                        [settings.get("theme")],
                                    size: Platform.isWindows ? 30 : 17),
                              ),
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onTap: () => {
                                    setState(() {
                                      if (trophySettings['sort'] != true) {
                                        trophySettings['filter'] = false;
                                        trophySettings['sort'] = true;
                                        trophySettings['settings'] = false;
                                        trophySettings['display'] = false;
                                      } else {
                                        trophySettings['sort'] = false;
                                      }
                                    }),
                                    settings.put(
                                        'trophySettings', trophySettings)
                                  }),
                        ),
                        //? Settings
                        Tooltip(
                          message: regionalText['trophies']['settings'],
                          child: InkWell(
                              child: Container(
                                decoration: BoxDecoration(
                                  //? To paint the border, we check the value of the settings for this website is true.
                                  //? If it's false or null (never set), we will paint red.
                                  border: Border.all(
                                      color: trophySettings['settings'] != true
                                          ? Colors.transparent
                                          : Colors.green,
                                      width: Platform.isWindows ? 5 : 2),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
                                ),
                                child: Icon(Icons.settings,
                                    color: themeSelector["primary"]
                                        [settings.get("theme")],
                                    size: Platform.isWindows ? 30 : 17),
                              ),
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onTap: () => {
                                    setState(() {
                                      if (trophySettings['settings'] != true) {
                                        trophySettings['filter'] = false;
                                        trophySettings['sort'] = false;
                                        trophySettings['settings'] = true;
                                        trophySettings['display'] = false;
                                      } else {
                                        trophySettings['settings'] = false;
                                      }
                                    }),
                                    settings.put(
                                        'trophySettings', trophySettings)
                                  }),
                        ),
                        //? Display
                        Tooltip(
                          message: regionalText['trophies']['display'],
                          child: InkWell(
                              child: Container(
                                decoration: BoxDecoration(
                                  //? To paint the border, we check the value of the settings for this website is true.
                                  //? If it's false or null (never set), we will paint red.
                                  border: Border.all(
                                      color: trophySettings['display'] != true
                                          ? Colors.transparent
                                          : Colors.green,
                                      width: Platform.isWindows ? 5 : 2),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
                                ),
                                child: Icon(
                                    trophySettings['trophyDisplay'] == "list"
                                        ? Icons.list
                                        : trophySettings['trophyDisplay'] ==
                                                "minimal"
                                            ? Icons.more_vert
                                            : Icons.view_comfy,
                                    color: themeSelector["primary"]
                                        [settings.get("theme")],
                                    size: Platform.isWindows ? 30 : 17),
                              ),
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onTap: () => {
                                    setState(() {
                                      if (trophySettings['display'] != true) {
                                        trophySettings['filter'] = false;
                                        trophySettings['sort'] = false;
                                        trophySettings['settings'] = false;
                                        trophySettings['display'] = true;
                                      } else {
                                        trophySettings['display'] = false;
                                      }
                                    }),
                                    settings.put(
                                        'trophySettings', trophySettings)
                                  }),
                        ),
                        SizedBox(width: 5),
                        //? Reset settings button
                        Tooltip(
                          message: regionalText['home']['undo'],
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                trophySettings = {
                                  "earned": true,
                                  "unearned": true,
                                  "showHidden": true,
                                  'urOnly': false,
                                  'noCommons': false,
                                  "sorting": "original",
                                  "hidden": trophySettings['hidden'],
                                  "description": true,
                                  "DLCseparator": true,
                                  'localization': true,
                                  "trophyDisplay":
                                      trophySettings['trophyDisplay'],
                                  "filter": false,
                                  "sort": false,
                                  "settings": false,
                                  "display": false,
                                };
                              });
                              settings.put('trophySettings', trophySettings);
                            },
                            child: Container(
                              child: Icon(Icons.undo,
                                  color: themeSelector["primary"]
                                      [settings.get("theme")],
                                  size: Platform.isWindows ? 30 : 17),
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: trophyDataMap == null
          ? null
          : FloatingActionButton(
              child: Icon(
                Icons.refresh,
                color: themeSelector["secondary"][settings.get("theme")]
                    .withOpacity(1),
              ),
              backgroundColor: themeSelector["primary"][settings.get("theme")]
                  .withOpacity(1),
              onPressed: () async {
                setState(() {
                  isUpdating = true;
                  trophyDataMap = null;
                });
                trophyDataMap =
                    await requestWebsite(trophyListData['gameLink']);
                setState(() {
                  trophyDataMap = trophyDataMap;
                });
              },
            ),
    ));
  }
}
