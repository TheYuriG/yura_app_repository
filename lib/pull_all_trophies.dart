import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'main.dart';
import 'package:flutter/material.dart';

class PullTrophies extends StatefulWidget {
  final List pullTrophiesData;

  PullTrophies({this.pullTrophiesData}) {
    assert(pullTrophiesData != null);
  }
  @override
  _PullTrophiesState createState() => _PullTrophiesState(pullTrophiesData);
}

//? Stores first/last timestamp data for this game
Map gameTrophyData = settings.get('gameTrophyData') ??
    {
      'psnProfiles': {},
      'psnTrophyLeaders': {},
      'exophase': {},
      'trueTrophies': {},
      'psn100': {}
    };

//? This private function processes the parsed string from requestWebsite() and returns useful data
Map<String, dynamic> _trophyData(String parsedHTMLasString,
    {Map<String, dynamic> timestamps}) {
  ws.loadFromString(parsedHTMLasString);
  Map<String, dynamic> information = {};

  //? This integer stores the number of trophies fetched
  int trophyIDNumber = 0;

  //? Checks if the page is exophase.
  if (ws.getElementAttribute("a.logo", 'title').contains("Exophase.com")) {
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
              break;
            case "30":
              trophyData[trophyNumber]['type'] = 'silver';
              break;
            case "90":
              trophyData[trophyNumber]['type'] = 'gold';
              break;
            case "300":
              trophyData[trophyNumber]['type'] = 'platinum';
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
          trophyData[trophyNumber]['description'] = element.trim();
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
        trophyIDNumber++;
      }
      information['gamePack${countDLC}TrophyData'] = trophyData;
    }
  }
  return information;
}

class _PullTrophiesState extends State<PullTrophies> {
  List pullTrophiesData;

  bool running = false;

  //? Number of games retrieved
  int gamesScanned = 0;

  //? This variable stores what is the update situation for all games
  Map games = settings.get('updatedGames') ?? {};

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

  //! Load a webpage, parse it as a string and then computes the result and returns a map
  Future<void> requestWebsite(String link,
      [String gameID, int position]) async {
    //? Initializes the String variable
    String parsedHTML;

    //? Stores game information to save and reuse them later in other parts of the application
    //? First trophy earned, last trophy earned (can be the same as first if only 1 trophy earned)
    Map gameData = {'first': null, 'last': null};

    //? Checks if the requested page is from Exophase
    if (link.contains('www.exophase.com')) {
      if (settings.get('localization') ?? true) {
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
        await ws.loadFullURL(
            (link.contains("#") ? link.split("#")[0] : link) + country + "/");
        //? Returns the webpage as a string
        parsedHTML = ws.getPageContent();
      } else {
        //? Loads the english/default webpage
        await ws.loadFullURL((link.contains("#") ? link.split("#")[0] : link));
        //? Returns the webpage as a string
        parsedHTML = ws.getPageContent();
      }

      //? Returns the webpage as a string
      parsedHTML = ws.getPageContent();

      Map finalData = await compute(_trophyData, parsedHTML);
      List earnedTrophyData;
      //? Loads the trophy data URL and returns the parsed information.
      await ws.loadFullURL(
          'https://api.exophase.com/public/player/${link.split("#")[1]}/game/$gameID/earned');
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
      }

      //? Gives the parsed HTML to the compute function which will run in the background
      //? Stores and organizes all trophies to be displayed inside listDisplay
      List trophiesArray = [];

      //? Transforms the Map into a List for the sort functions.
      for (var i = 0; i <= finalData['dlcPacksCount'] ?? 0; i++) {
        trophiesArray += finalData['gamePack${i}TrophyData'];
      }
      //? Clears the pending trophies Map for this game. Resets if there are pending trophies and nuke it otherwise
      if ((finalData['gamePercentage'] ?? 0) < 100) {
        trophyPending['exophase'][link] = {};
      } else {
        trophyPending['exophase'].remove(link);
      }
      //? Clears the earned trophies map for this game
      trophyEarned['exophase'][link] = {};

      trophiesArray.forEach((element) {
        if (element is Map) {
          //? Attaches game name to trophy for the Trophy Log
          element['gameData'] = pullTrophiesData[position];

          //? If this is an exophase page, store information on the exophase part of the database
          if (link.contains("exophase.com")) {
            //? If this trophy was earned (has a timestamp), save it on the earned trophies database
            if (element['timestamp'] != null) {
              if (trophyEarned['exophase'][link] == null) {
                trophyEarned['exophase'][link] = {};
              }
              trophyEarned['exophase'][link][element['link']] = element;

              //? Stores first and last trophy data into this Map
              if (gameData['first'] == null ||
                  gameData['first'] < element['timestamp']) {
                gameData['first'] = element['timestamp'];
              }
              if (gameData['last'] == null ||
                  gameData['last'] > element['timestamp']) {
                gameData['last'] = element['timestamp'];
              }
            }
            //? Stores the other trophies without timestamps in the other database
            else {
              trophyPending['exophase'][link][element['link']] = element;
            }
          }
        }
      });

      //? Save this data in its own database to be used in other parts of the application
      gameTrophyData['exophase']
          [link.contains("#") ? link.split("#")[0] : link] = gameData;
      settings.put('gameTrophyData', gameTrophyData);
      //? Save trophies earned on the trophies earned database
      settings.put('trophyEarned', trophyEarned);
      //? Save pending trophies on the pending trophies database
      settings.put('trophyPending', trophyPending);
    } else {
      throw Error;
    }
  }

  //? This boolean stores if the update has started or not.
  bool updateStart = false;

  _PullTrophiesState(this.pullTrophiesData);
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        decoration: backgroundDecoration(),
        child: Center(
          child: FutureBuilder(
            builder: (context, snapshot) {
              if (running == false) {
                //? Changes the running variable to true here to avoid scanning games twice at
                running = true;
                //? Stores here the variable that will verify how many games were skipped.
                //? This variable is necessary to resume work on fetching trophy data
                //? without having to wait for all of the previous games to be skipped again.
                int skipped = 0;
                //? Loops through the entire list of games sent by Games
                for (var i = 0; i < pullTrophiesData.length; i++) {
                  //? Fetch trophy information should this game and percentage not be stored
                  //? or if this list is not stored in trophyEarned
                  if (games[pullTrophiesData[i]['gameLink']] !=
                          pullTrophiesData[i]['gamePercentage'] ||
                      trophyEarned[pullTrophiesData[i]['gameWebsite']][
                              pullTrophiesData[i]['gameLink'].contains("#")
                                  ? pullTrophiesData[i]['gameLink']
                                      .split('#')[0]
                                  : pullTrophiesData[i]['gameLink']] ==
                          null ||
                      gameTrophyData[pullTrophiesData[i]['gameWebsite']][
                              pullTrophiesData[i]['gameLink'].contains("#")
                                  ? pullTrophiesData[i]['gameLink']
                                      .split('#')[0]
                                  : pullTrophiesData[i]['gameLink']] ==
                          null) {
                    Future.delayed(Duration(seconds: (i - skipped) * 3),
                        () async {
                      //? Runs a try-catch function and stores the data if successful
                      try {
                        await requestWebsite(pullTrophiesData[i]['gameLink'],
                            pullTrophiesData[i]['gameID'], i);
                        //? If the requestWebsite function doesn't fail (and trigger the catch)
                        //? Save the data
                        if (trophyEarned[pullTrophiesData[i]['website'] ??
                                'exophase'][pullTrophiesData[i]['gameLink']] !=
                            null) {
                          games[pullTrophiesData[i]['gameLink']] =
                              pullTrophiesData[i]['gamePercentage'];
                          settings.put('updatedGames', games);
                        }
                      } catch (e) {
                        print('fetching data error');
                        print(pullTrophiesData[i]['gameName']);
                        print(e);
                      }

                      //? Update the UI with the number of games fetched so far
                      if (mounted) {
                        setState(() {
                          gamesScanned++;
                        });
                      }

                      //? Close the update page if it reaches the end of the list
                      if (gamesScanned == pullTrophiesData.length) {
                        if (mounted) {
                          settings.put('trophyDataUpToDate', true);
                          Navigator.pop(context);
                        }
                      }
                    });
                  } else {
                    //? Increases games skipped and games total if the previous if/else statement fails
                    skipped++;
                    gamesScanned++;
                    if (gamesScanned == pullTrophiesData.length) {
                      if (mounted) {
                        settings.put('trophyDataUpToDate', true);
                        Navigator.pop(context);
                      }
                    }
                  }
                }
              }
              return Container(
                width: Platform.isWindows ? 400 : 200,
                padding: EdgeInsets.all(10),
                decoration: boxDeco(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      regionalText['trophies']['updating'],
                      style: textSelection(theme: "textLight"),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "$gamesScanned/${pullTrophiesData.length}",
                      style: textSelection(theme: "textLight"),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ));
  }
}
