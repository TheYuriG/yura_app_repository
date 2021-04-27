import 'dart:io' show Platform;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:yura_trophy/pull_all_trophies.dart';
import 'exophase_profile.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:web_scraper/web_scraper.dart';

//! This project assumes you are using VS Code and with the Todo Tree extension.
void main() async {
  //? Initializes flutter depending on proper platform
  await Hive.initFlutter();
  //? Open database with proper settings
  await Hive.openBox("settings").then((box) {
    if (box.get("language") == null) {
      //? Sets default language as english
      box.put("language", "us");
      //? Sets default theme as pink. This is later use to pull the color schemes from Map themeSelector
      box.put("theme", 'pink');
      //? Sets default trophy icons as Yura's icons
      box.put("trophyType", 'yura');
      //? Sets level type as new
      box.put('levelType', 'new');
      //? Enables fetching information from all websites
      box.put("psnp", true);
      box.put("psntl", true);
      box.put("trueTrophies", true);
      box.put("exophase", true);
      box.put("psn100", true);
      //? Picks the loading widget to be used
      box.put('loading', "wave");
      //? Picks the font to be used
      box.put('font', "Oxygen");
      //? Save app localization as true.
      box.put('localization', true);
    }
  });
  initializeDateFormatting(Platform.localeName);
  runApp(MyApp());
}

//? Default BoxDecoration used
BoxDecoration boxDeco([String option, String premium]) {
  if (option == "thin") {
    return BoxDecoration(
        color: themeSelector["primary"][settings.get("theme")],
        borderRadius: BorderRadius.all(Radius.circular(15)),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black, blurRadius: 5)]);
  }
  Color colored;
  if (premium == "psnp") {
    colored = Colors.yellow;
  } else if (premium == "psntl") {
    colored = Colors.blue;
  } else if (premium == "trueTrophies") {
    colored = Colors.black;
  } else {
    colored = Colors.white;
  }
  return BoxDecoration(
      color: themeSelector["primary"][settings.get("theme")].withOpacity(0.85),
      borderRadius: BorderRadius.all(Radius.circular(15)),
      border: Border.all(color: colored, width: 3),
      boxShadow: [BoxShadow(color: Colors.black, blurRadius: 5)]);
}

//? These Strings displays update information in conjunction with the loadingIcon
String psnProfilesUpdateProgress = regionalText['home']['updating'];
String psnTrophyLeadersUpdateProgress = regionalText['home']['updating'];
String exophaseUpdateProgress = regionalText['home']['updating'];
String trueTrophiesUpdateProgress = regionalText['home']['updating'];
String psn100UpdateProgress = regionalText['home']['updating'];

//? This will save the settings for the app in this Hive box
//? Examples of settings saved are the theme colors and language.
Box settings = Hive.box("settings");

//? WebScraper instance for all websites.
final WebScraper ws = WebScraper();

BoxDecoration backgroundDecoration() {
  return BoxDecoration(
    gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomRight,
        colors: [
          if (settings.get('psnID') != null)
            themeSelector["primary"][settings.get("theme")],
          if (settings.get('psnID') == null)
            themeSelector["secondary"][settings.get("theme")],
          themeSelector["secondary"][settings.get("theme")],
        ]),
  );
}

//? This is a general loader function to use the compute functions later.
Future<String> parsePage(String page) async {
  WebScraper pageLoader = WebScraper();
  await pageLoader.loadFullURL(page);
  return pageLoader.getPageContent();
}

//? This will make a request to PSNProfiles to retrieve a small clickable profile card
Future<Map> psnpInfo(String user) async {
  await ws.loadFullURL('https://psnprofiles.com/$user');
  Map<String, dynamic> parsedData = {};
  //? https://psnprofiles.com/
  //! parsedData['psnID']
  //? ?ajax=1&completion=
  //! all / incomplete / platinum-only / complete
  //? &order=
  //! last-played / percent / last-trophy / a-z
  //? &pf=
  //! all / psvr / vita / ps3 / ps4 / ps5
  //? &page=
  //! 1
  try {
    //! Retrieves basic profile information, like avatar, about me, PSN ID, level, etc
    //? Retrieves PSN ID
    ws
        .getElementTitle(
            '#user-bar > ul > div > div.grow > div:nth-child(1) > span')
        .forEach((element) {
      parsedData['psnID'] = element.trim();
      if (parsedData['psnID'] != user && !parsedData['psnID'].contains(' ')) {
        settings.put('psnID', parsedData['psnID']);
      }
    });
    if (parsedData['psnID'] == null) {
      throw Error;
    }
    //? Retrieves About Me
    ws
        .getElementTitle('#user-bar > ul > div > div.grow > div > span.comment')
        .forEach((element) {
      parsedData['about'] = element;
    });
    //? Retrieves Premium Status
    ws.getElement('#premium', ['class']).forEach((element) {
      parsedData['premium'] = true;
    });
    //? Retrieves avatar if user doesn't have PS+
    ws
        .getElementAttribute('#user-bar > div.avatar > img', 'src')
        .forEach((element) {
      parsedData['avatar'] = element;
      parsedData['psPlus'] = false;
    });
    //? Retrieves avatar if user has PS+
    ws
        .getElementAttribute('#user-bar > div.avatar > div > img', 'src')
        .forEach((element) {
      parsedData['avatar'] = element;
      parsedData['psPlus'] = true;
    });
    //? Retrieves country
    ws.getElementAttribute('img#bar-country', 'class').forEach((element) {
      parsedData['country'] = element.split(" ")[1];
    });
    //? Retrieves PSN Level
    ws
        .getElementTitle('#bar-level > ul > li.icon-sprite.level')
        .forEach((element) {
      parsedData['level'] = int.parse(element.replaceAll(",", ""));
    });
    //? Retrieves PSN Level progress
    ws
        .getElementAttribute('#bar-level > div > div', 'style')
        .forEach((element) {
      parsedData['levelProgress'] = element.split(" ")[1].split(";")[0];
    });
    //! Retrieves trophy data
    //? Retrieves Total trophies
    ws
        .getElementTitle('#user-bar > ul > div > div > li.total')
        .forEach((element) {
      parsedData['total'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves bronze trophies
    ws
        .getElementTitle('#user-bar > ul > div > div > li.bronze')
        .forEach((element) {
      parsedData['bronze'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves silver trophies
    ws
        .getElementTitle('#user-bar > ul > div > div > li.silver')
        .forEach((element) {
      parsedData['silver'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves gold trophies
    ws
        .getElementTitle('#user-bar > ul > div > div > li.gold')
        .forEach((element) {
      parsedData['gold'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves platinum trophies
    ws
        .getElementTitle('#user-bar > ul > div > div > li.platinum')
        .forEach((element) {
      parsedData['platinum'] = int.parse(element.replaceAll(",", "").trim());
    });
    //! Retrieves rarity data
    //? Retrieves ultra rare trophies
    ws
        .getElementTitle(
            '#content > div.row > div.sidebar.col-xs-4 > div.box.no-top-border > div.xs-hide.lg-show > div > div:nth-child(1) > a > center > span.typo-top')
        .forEach((element) {
      parsedData['ultraRare'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves very rare trophies
    ws
        .getElementTitle(
            '#content > div.row > div.sidebar.col-xs-4 > div.box.no-top-border > div.xs-hide.lg-show > div > div:nth-child(5) > a > center > span.typo-top')
        .forEach((element) {
      parsedData['veryRare'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves rare trophies
    ws
        .getElementTitle(
            '#content > div.row > div.sidebar.col-xs-4 > div.box.no-top-border > div.xs-hide.lg-show > div > div:nth-child(9) > a > center > span.typo-top')
        .forEach((element) {
      parsedData['rare'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves uncommon trophies
    ws
        .getElementTitle(
            '#content > div.row > div.sidebar.col-xs-4 > div.box.no-top-border > div.xs-hide.lg-show > div > div:nth-child(13) > a > center > span.typo-top')
        .forEach((element) {
      parsedData['uncommon'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves common trophies
    ws
        .getElementTitle(
            '#content > div.row > div.sidebar.col-xs-4 > div.box.no-top-border > div.xs-hide.lg-show > div > div:nth-child(17) > a > center > span.typo-top')
        .forEach((element) {
      parsedData['common'] = int.parse(element.replaceAll(",", "").trim());
    });
    //! Retrieves profile statistic data like games played, completion %, rankings, etc
    //? Retrieves total ganes
    ws
        .getElementTitle(
            '#banner > div.banner-overlay > div > div.stats.flex > span:nth-child(1)')
        .forEach((element) {
      parsedData['games'] = int.parse(
          element.replaceAll("Games Played", "").replaceAll(",", "").trim());
    });
    //? Retrieves complete ganes
    ws
        .getElementTitle(
            '#banner > div.banner-overlay > div > div.stats.flex > span:nth-child(3)')
        .forEach((element) {
      parsedData['complete'] = int.parse(
          element.replaceAll("Completed Games", "").replaceAll(",", "").trim());
      parsedData['incomplete'] = parsedData['games'] - parsedData['complete'];
      parsedData['completePercentage'] =
          (parsedData['complete'] / parsedData['games'] * 100)
              .toStringAsFixed(3);
      parsedData['incompletePercentage'] =
          (parsedData['incomplete'] / parsedData['games'] * 100)
              .toStringAsFixed(3);
    });
    //? Retrieves completion
    ws
        .getElementTitle(
            '#banner > div.banner-overlay > div > div.stats.flex > span:nth-child(5)')
        .forEach((element) {
      parsedData['completion'] = element.replaceAll("Completion", "").trim();
    });
    //? Retrieves unearned trophies
    ws
        .getElementTitle(
            '#banner > div.banner-overlay > div > div.stats.flex > span:nth-child(7)')
        .forEach((element) {
      parsedData['unearned'] = int.parse(element
          .replaceAll("Unearned Trophies", "")
          .replaceAll(",", "")
          .trim());

      parsedData['unearnedPercentage'] = (parsedData['unearned'] /
              (parsedData['total'] + parsedData['unearned']) *
              100)
          .toStringAsFixed(3);
      parsedData['totalPercentage'] = ((parsedData['total']) /
              (parsedData['total'] + parsedData['unearned']) *
              100)
          .toStringAsFixed(3);
    });
    //? Retrieves world rank and world rank increase by checking if the span class is "grow green" or "grow red"
    ws.getElement(
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
    ws.getElement(
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
    settings.put('psnpDump', parsedData);
  } catch (e) {
    print("error scanning PSN Profiles");
    parsedData = null;
    settings.put('psnp', false);
  }
  // print(parsedData);
  return parsedData;
}

//? This will make a request to PSN Trophy Leaders to retrieve a small clickable profile card
Future<Map> psntlInfo(String user) async {
  await ws.loadFullURL('https://psntrophyleaders.com/user/view/$user');
  Map<String, dynamic> parsedData = {};
  //? To get trophy log by rarity, make a HTTP POST request to
  //! https://psntrophyleaders.com/user/get_rare_trophies
  //? and as body, send the following
  //! {earned: earnedNumber, page: pageNumber, platform: platformNumber, psnid: psnIDrequested, rare: rareNumber, trophy_sort: EITHER "percent_earned-desc" OR "percent_earned-asc", type: typeNumber}
  //? earnedNumber is a binary choice if you want to display earned trophies or unearned trophies
  //? earned trophies = 1, unearned trophies = 0
  //? pageNumber is the range of trophies you wanna fetch. every page has a max of 50 trophies, so just search for (trophyNumber/50).ceil
  //? platformNumber is a number from 0 to 17 where you have to add up the numbers to get which platforms you want added.
  //? vita = 1, ps3 = 2, ps4 = 4, ps5 = 8. sending 0 means sending no platform and therefore you are dumb
  //? psnIDrequested is the PSN ID you want to pull trophies from, pretty self explanatory
  //? rareNumber is like platformNumber, but ranging from 0 to 127
  //? common = 1, slightly common = 2, uncommon = 4, rare = 8, very rare = 16, ultra rare = 32, prestige = 64. sending 0 means sending no rarity and therefore you are dumb
  //? to have it noted down, these are the rarity ranges:
  //? common = 50,00% - 100,00%, slightly common = 35,00% - 49,99%, uncommon = 20,00% - 34,99%,
  //? rare = 10,00%- 19,99%, very rare = 5,00% - 9,99%, ultra rare = 1,00% - 4,99%, prestige = 0,00% - 0,99%
  //? trophy_sort is an optional body field, but there is no reason not to use it and make yourself do the manual calculation
  //? the 2 most relevant options are percent_earned-desc (high % to low %) and percent_earned-asc (low % to high %)
  //? lastly, typeNumber like platformNumber, provide the number which is the sum of the types you want to have displayed
  //? bronze = 1, silver = 2, gold = 4, platinum = 8, sending 0 means sending no type and therefore you are dumb

  try {
    //! Retrieves basic profile information, like avatar, about me, PSN ID, level, etc
    //? Retrieves PSN ID
    ws.getElementTitle('#id-handle').forEach((element) {
      parsedData['psnID'] = element.trim();
      if (parsedData['psnID'] != user && !parsedData['psnID'].contains(' ')) {
        settings.put('psnID', parsedData['psnID']);
      }
    });
    if (parsedData['psnID'] == null) {
      throw Error;
    }
    //? Retrieves PSN country
    ws.getElement(
        '#userPage > div.userRight > div.userHeader > table > tbody > tr > td.userInfo > h1 > span > img',
        ['src']).forEach((element) {
      parsedData['country'] = element['attributes']['src']
          .replaceAll("https://psntrophyleaders.com/images/countries/", "")
          .replaceAll("_small.png", "")
          .trim();
    });
    //? Retrieves PSN avatar
    ws
        .getElementAttribute('#id-avatar > img.avatar-large', 'src')
        .forEach((element) {
      parsedData['avatar'] = element;
    });
    //? Retrieves Platinum Member status
    ws.getElement('#id-avatar > div > span.usergrouper.lifetime-member',
        []).forEach((element) {
      parsedData['premium'] = true;
    });

    //
    //? Retrieves how many tracked players share the same avatar
    ws.getElementTitle('#avatarstat > span.white').forEach((element) {
      parsedData['sameAvatar'] = int.parse(element.trim());
    });
    //? Retrieves PSN Level
    ws.getElementTitle('#leveltext > big').forEach((element) {
      parsedData['level'] = int.parse(element.replaceAll(",", ""));
    });
    //? Retrieves PSN Level progress
    ws
        .getElementAttribute(
            '#toprightstats > td > div > div > div.prog > div > div.progressbar',
            'style')
        .forEach((element) {
      parsedData['levelProgress'] =
          element.replaceAll("width: ", "").replaceAll(";", "").trim();
    });
    //! Retrieves trophy data
    //? Retrieves Total trophies
    ws
        .getElementTitle('#toprightstats > td:nth-child(5) > big')
        .forEach((element) {
      parsedData['total'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves bronze trophies
    ws
        .getElementTitle('#ranksummary > table > tbody > tr > td.bronze > big')
        .forEach((element) {
      parsedData['bronze'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves silver trophies
    ws
        .getElementTitle('#ranksummary > table > tbody > tr > td.silver > big')
        .forEach((element) {
      parsedData['silver'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves gold trophies
    ws
        .getElementTitle('#ranksummary > table > tbody > tr > td.gold > big')
        .forEach((element) {
      parsedData['gold'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves platinum trophies
    ws
        .getElementTitle(
            '#ranksummary > table > tbody > tr > td.platinum > big')
        .forEach((element) {
      parsedData['platinum'] = int.parse(element.replaceAll(",", "").trim());
    });
    //! Retrieves profile information data
    //? Retrieves total ganes
    ws
        .getElementTitle('#toprightstats > td:nth-child(3) > big')
        .forEach((element) {
      parsedData['games'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves completion
    ws
        .getElementAttribute(
            '#toprightstats > td:nth-child(9) > big > span', 'title')
        .forEach((element) {
      parsedData['completion'] =
          element.replaceAll(" average completion", "").trim();
    });
    //! Retrieves ranking data
    //? Retrieves Standard rank
    ws
        .getElementTitle(
            '#ranksummary > table > tbody > tr:nth-child(12) > td:nth-child(1)')
        .forEach((element) {
      parsedData['standard'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves Standard rank status change
    ws
        .getElementTitle(
            '#ranksummary > table > tbody > tr:nth-child(12) > td:nth-child(3)')
        .forEach((element) {
      if (element.contains("+")) {
        parsedData['standardChange'] = "⬆️";
      } else if (element.contains("-")) {
        parsedData['standardChange'] = "⬇️";
      } else {
        parsedData['standardChange'] = "🟨";
      }
    });
    //? Retrieves Adjusted rank
    ws
        .getElementTitle(
            '#ranksummary > table > tbody > tr:nth-child(13) > td:nth-child(1)')
        .forEach((element) {
      parsedData['adjusted'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves Adjusted rank status change
    ws
        .getElementTitle(
            '#ranksummary > table > tbody > tr:nth-child(13) > td:nth-child(3)')
        .forEach((element) {
      if (element.contains("+")) {
        parsedData['adjustedChange'] = "⬆️";
      } else if (element.contains("-")) {
        parsedData['adjustedChange'] = "⬇️";
      } else {
        parsedData['adjustedChange'] = "🟨";
      }
    });
    //? Retrieves Completist rank
    ws
        .getElementTitle(
            '#ranksummary > table > tbody > tr:nth-child(14) > td:nth-child(1)')
        .forEach((element) {
      parsedData['completist'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves Completist rank status change
    ws
        .getElementTitle(
            '#ranksummary > table > tbody > tr:nth-child(14) > td:nth-child(3)')
        .forEach((element) {
      if (element.contains("+")) {
        parsedData['completistChange'] = "⬆️";
      } else if (element.contains("-")) {
        parsedData['completistChange'] = "⬇️";
      } else {
        parsedData['completistChange'] = "🟨";
      }
    });
    //? Retrieves Rarity rank
    ws
        .getElementTitle(
            '#ranksummary > table > tbody > tr:nth-child(15) > td:nth-child(1)')
        .forEach((element) {
      parsedData['rarity'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves Rarity rank status change
    ws
        .getElementTitle(
            '#ranksummary > table > tbody > tr:nth-child(15) > td:nth-child(3)')
        .forEach((element) {
      if (element.contains("+")) {
        parsedData['rarityChange'] = "⬆️";
      } else if (element.contains("-")) {
        parsedData['rarityChange'] = "⬇️";
      } else {
        parsedData['rarityChange'] = "🟨";
      }
    });
    settings.put('psntlDump', parsedData);
  } catch (e) {
    print("error scanning PSN Trophy Leaders");
    parsedData = null;
    settings.put('psntl', false);
  }
  // print(parsedData);
  return parsedData;
}

//? This will make a request to Exophase to retrieve a small clickable profile card
Map exophaseInfo(String parsedHTML) {
  ws.loadFromString(parsedHTML);
  //! parsedData holds player data only
  Map<String, dynamic> parsedData = {};
  try {
    // https://api.exophase.com/public/player/(data-playerid)/game/(data-game)/earned
    // data-game = #app > div > div.row.col-game-information.pb-3
    //! Retrieves basic profile information, like avatar, about me, PSN ID, level, etc
    //? Retrieves PSN ID
    ws
        .getElementTitle(
            '#sub-user-info > section > div.col.col-md-auto.column-username.me-lg-4.pb-3.pt-3 > h2')
        .forEach((element) {
      parsedData['psnID'] = element.trim();
    });
    if (parsedData['psnID'] == null) {
      throw Error;
    }
    //? Exophase's unique account ID
    ws
        .getElementAttribute('#app > div > section > div', 'data-playerid')
        .forEach((element) {
      parsedData['exophaseID'] = element.trim();
    });
    //? Retrieve Exophase Premium status when available
    ws
        .getElementAttribute(
            '#sub-user-info > section > div.col.col-md-auto.column-username.me-lg-4.pb-3.pt-3 > span',
            'data-tippy-content')
        .forEach((element) {
      if (element ==
          "This user has supported the site by subscribing to Exophase Premium") {
        parsedData['premium'] = true;
      }
    });
    //? Retrieves PSN country
    ws
        .getElementAttribute(
            '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div:nth-child(1) > span > span.country-ranking.mb-1 > img',
            'src')
        .forEach((element) {
      parsedData['country'] = element
          .replaceAll("https://www.exophase.com/assets/zeal/images/flags/", "")
          .replaceAll(".png", "")
          .trim();
    });
    //? Retrieves PSN avatar
    ws
        .getElementAttribute(
            '#app > div > section > div > div.col-auto.profile-overflow-top.ps-md-3.pe-md-0.mx-auto.mt-3.mt-md-0 > div > img',
            'src')
        .forEach((element) {
      parsedData['avatar'] = element;
    });
    //? Retrieves PSN Level
    ws
        .getElementTitle(
            '#sub-user-info > section > div.col-auto > div > div:nth-child(1) > span')
        .forEach((element) {
      parsedData['level'] = int.parse(element.replaceAll(",", ""));
    });
    //? Retrieves PSN Level progress
    ws
        .getElementAttribute(
            '#sub-user-info > section > div.col-auto > div > div:nth-child(1) > div > div',
            'style')
        .forEach((element) {
      parsedData['levelProgress'] =
          element.replaceAll("width: ", "").replaceAll(";", "").trim();
    });
    //? Retrieves completion
    ws
        .getElementTitle(
            '#sub-user-info > section > div.col-auto > div > div:nth-child(3) > span')
        .forEach((element) {
      parsedData['completion'] =
          element.replaceAll(" average completion", "").trim();
    });
    //? Retrieves world rank
    ws
        .getElementTitle(
            '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div:nth-child(1) > span > span.global-ranking.tippy.mb-1')
        .forEach((element) {
      parsedData['worldRank'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves country rank
    ws
        .getElementTitle(
            '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div:nth-child(1) > span > span.country-ranking.mb-1')
        .forEach((element) {
      parsedData['countryRank'] = int.parse(element.replaceAll(",", "").trim());
    });
    //! Retrieves trophy data
    //? Retrieves Total trophies
    ws
        .getElementTitle(
            '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div.col > span.tippy.total-value')
        .forEach((element) {
      parsedData['total'] = int.parse(element
          .replaceAll(",", "")
          .replaceAll("Trophies (", "")
          .replaceAll(")", "")
          .trim());
    });
    //? Retrieves bronze trophies
    ws
        .getElementTitle(
            '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div:nth-child(3) > span:nth-child(1)')
        .forEach((element) {
      parsedData['bronze'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves silver trophies
    ws
        .getElementTitle(
            '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div:nth-child(3) > span:nth-child(3)')
        .forEach((element) {
      parsedData['silver'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves gold trophies
    ws
        .getElementTitle(
            '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div:nth-child(5) > span:nth-child(1)')
        .forEach((element) {
      parsedData['gold'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves platinum trophies
    ws
        .getElementTitle(
            '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div:nth-child(5) > span:nth-child(3)')
        .forEach((element) {
      parsedData['platinum'] = int.parse(element.replaceAll(",", "").trim());
    });
    //! Retrieves Profile overall statistics
    //? Retrieves total ganes
    ws
        .getElementTitle(
            '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div.col > span[data-tippy-content="Games owned"]')
        .forEach((element) {
      parsedData['games'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves complete games
    ws
        .getElementTitle(
            '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div.col > span[data-tippy-content="Completed games"]')
        .forEach((element) {
      parsedData['complete'] = int.parse(element.replaceAll(",", "").trim());
      parsedData['incomplete'] = parsedData['games'] - parsedData['complete'];
      parsedData['completePercentage'] =
          (parsedData['complete'] / parsedData['games'] * 100)
              .toStringAsFixed(3);
      parsedData['incompletePercentage'] =
          (parsedData['incomplete'] / parsedData['games'] * 100)
              .toStringAsFixed(3);
    });
    //? Retrieves tracked gameplay time
    ws
        .getElementTitle(
            '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div.col > span.tippy.playtime')
        .forEach((element) {
      parsedData['hours'] = int.parse(
          element.replaceAll(",", "").replaceAll(" hours", "").trim());
    });
    //? Retrieves earned EXP
    ws
        .getElementTitle(
            '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div.col > span.tippy')
        .forEach((element) {
      if (element.contains("hour") == false) {
        parsedData['exp'] = int.parse(element.replaceAll(",", "").trim());
      }
    });
  } catch (e) {
    print("error scanning Exophase");
    parsedData = null;
  }
  // print(parsedData);
  return parsedData;
}

List<Map<String, dynamic>> fetchExophaseGames(Map<String, dynamic> data) {
  String parsedHTML = data['html'];
  int games = data['games'];
  int position = data['position'];

  //! parsedGames holds player games only
  List<Map<String, dynamic>> parsedGames = [];

  if (position == 0) {
    //? Loads the page from String parsed HTML
    if (!ws.loadFromString(parsedHTML)) {
      throw Error;
    }

    //! Games data
    //? if the user has more than 50 (default initial game display for exophase) games on their profile, scan for 50
    //? otherwise scan the number of games.
    for (var i = 1; i < (games > 50 ? 52 : games + 2); i++) {
      Map<String, dynamic> first50 = {};
      //? Retrieves game name and link
      ws.getElement(
          '#app > div > div.row.user-container > div.col-12.col-xl-9 > ul > li:nth-child(${(i * 2) - 1}) > div.row.gx-0.align-items-center > div.col.col-game.game-info.pe-3 > div > h3 > a',
          ['href']).forEach((element) {
        String link = element['attributes']['href'].trim();
        first50['gameLink'] = link.contains('#') ? link.split('#')[0] : link;
        first50['gameName'] = element['title'].trim();
      });
      if (first50['gameName'] == null) {
        continue;
      }

      //? Retrieves game image
      ws
          .getElementAttribute(
              '#app > div > div.row.user-container > div.col-12.col-xl-9 > ul > li:nth-child(${(i * 2) - 1}) > div > div > div.box.image > img',
              'src')
          .forEach((element) {
        first50['gameImage'] = element.trim();
      });

      //? Retrieves game platforms
      ws
          .getElementTitle(
              '#app > div > div.row.user-container > div.col-12.col-xl-9 > ul > li:nth-child(${(i * 2) - 1}) > div.row.gx-0.align-items-center > div.col.col-game.game-info.pe-3 > div > div')
          .forEach((element) {
        if (element.toLowerCase().contains("ps3")) {
          first50['gamePS3'] = true;
        }
        if (element.toLowerCase().contains("ps4")) {
          first50['gamePS4'] = true;
        }
        if (element.toLowerCase().contains("ps5")) {
          first50['gamePS5'] = true;
        }
        if (element.toLowerCase().contains("vita")) {
          first50['gameVita'] = true;
        }
      });
      //? Retrieves game playtime
      ws
          .getElementTitle(
              '#app > div > div.row.user-container > div.col-12.col-xl-9 > ul > li:nth-child(${(i * 2) - 1}) > div.row.gx-0.align-items-center > div.col.col-game.game-info.pe-3 > div > span.hours')
          .forEach((element) {
        first50['gameTime'] = element.trim();
      });
      //? Retrieves game ID, game Last Played timestamp and game Completed timestamp (when available)
      ws.getElement(
          '#app > div > div.row.user-container > div.col-12.col-xl-9 > ul > li:nth-child(${(i * 2) - 1}).col-12.game-visible.psn',
          [
            'data-gameid',
            'data-lastplayed',
            'data-completion'
          ]).forEach((element) {
        first50['gameID'] = element['attributes']['data-gameid'].trim();
        first50['gameLastPlayedTimestamp'] =
            int.parse(element['attributes']['data-lastplayed'].trim());
        first50['gameCompletionTimestamp'] =
            int.parse(element['attributes']['data-completion'].trim());
      });
      //? Retrieves game trophy ratio (trophies earned / trophy total)
      ws
          .getElementTitle(
              '#app > div > div.row.user-container > div.col-12.col-xl-9 > ul > li:nth-child(${(i * 2) - 1}) > div.row.gx-0.align-items-center > div.col-12.col-md.px-3.pb-4.pe-md-0.pb-md-0.game-progress > div.row.gx-0.progress-units-top.pb-2 > div:first-child')
          .forEach((element) {
        first50['gameRatio'] = element.trim();
      });
      //? Retrieves game EXP
      ws
          .getElementTitle(
              '#app > div > div.row.user-container > div.col-12.col-xl-9 > ul > li:nth-child(${(i * 2) - 1}) > div.row.gx-0.align-items-center > div.col-12.col-md.px-3.pb-4.pe-md-0.pb-md-0.game-progress > div.row.gx-0.progress-units-top.pb-2 > div:nth-child(3)')
          .forEach((element) {
        first50['gameEXP'] = int.parse(element.replaceAll(",", "").trim());
      });
      //? Retrieves game bronze trophies
      ws
          .getElementTitle(
              '#app > div > div.row.user-container > div.col-12.col-xl-9 > ul > li:nth-child(${(i * 2) - 1}) > div.row.gx-0.align-items-center > div.col-12.col-md.px-3.pb-4.pe-md-0.pb-md-0.game-progress > div.holders > div > span.bronze')
          .forEach((element) {
        first50['gameBronze'] = int.parse(element.trim());
      });
      //? Retrieves game silver trophies
      ws
          .getElementTitle(
              '#app > div > div.row.user-container > div.col-12.col-xl-9 > ul > li:nth-child(${(i * 2) - 1}) > div.row.gx-0.align-items-center > div.col-12.col-md.px-3.pb-4.pe-md-0.pb-md-0.game-progress > div.holders > div > span.silver')
          .forEach((element) {
        first50['gameSilver'] = int.parse(element.trim());
      });
      //? Retrieves game gold trophies
      ws
          .getElementTitle(
              '#app > div > div.row.user-container > div.col-12.col-xl-9 > ul > li:nth-child(${(i * 2) - 1}) > div.row.gx-0.align-items-center > div.col-12.col-md.px-3.pb-4.pe-md-0.pb-md-0.game-progress > div.holders > div > span.gold')
          .forEach((element) {
        first50['gameGold'] = int.parse(element.trim());
      });
      //? Retrieves game platinum trophies
      ws.getElement(
          '#app > div > div.row.user-container > div.col-12.col-xl-9 > ul > li:nth-child(${(i * 2) - 1}) > div.row.gx-0.align-items-center > div.col-12.col-md.px-3.pb-4.pe-md-0.pb-md-0.game-progress > div.holders > div > span.platinum',
          []).forEach((element) {
        first50['gamePlatinum'] = 1;
      });
      //? Retrieves game percentage progress
      ws
          .getElementAttribute(
              '#app > div > div.row.user-container > div.col-12.col-xl-9 > ul > li:nth-child(${(i * 2) - 1}) > div.row.gx-0.align-items-center > div.col-12.col-md.px-3.pb-4.pe-md-0.pb-md-0.game-progress > div.progress > div',
              'style')
          .forEach((element) {
        first50['gamePercentage'] = int.parse(
            element.replaceAll("%;", "").replaceAll("width: ", "").trim());
      });
      //? Retrieves game last played date
      ws
          .getElementTitle(
              '#app > div > div.row.user-container > div.col-12.col-xl-9 > ul > li:nth-child(${(i * 2) - 1}) > div.row.gx-0.align-items-center > div.col-12.col-md.col-lastplayed.text-center.text-md-end.mb-2.mb-md-0 > div.lastplayed')
          .forEach((element) {
        first50['gameLastPlayed'] = element.trim();
      });
      parsedGames.add(first50);
    }
  } else {
    if (ws.loadFragment(parsedHTML) != true) {
      throw Error;
    }

    int listLength = ws
        .getElementAttribute('li > div > div > div.box.image > img', 'src')
        .length;

    //! Games data
    //? if the user has more than 50 (default initial game display for exophase) games on their profile, scan for 50
    //? otherwise scan the number of games.
    for (var i = 0; i <= listLength; i++) {
      Map<String, dynamic> next50 = {};
      //? Retrieves game name and link
      ws.getElement(
          'li:nth-child(${(i * 2) + 1}) > div.row.gx-0.align-items-center > div.col.col-game.game-info.pe-3 > div > h3 > a',
          ['href']).forEach((element) {
        String link = element['attributes']['href'].trim();
        next50['gameLink'] = link.contains('#') ? link.split('#')[0] : link;
        next50['gameName'] = element['title'].trim();
      });
      if (next50['gameName'] == null) {
        continue;
      }

      //? Retrieves game image
      ws
          .getElementAttribute(
              'li:nth-child(${(i * 2) + 1}) > div > div > div.box.image > img',
              'src')
          .forEach((element) {
        next50['gameImage'] = element.trim();
      });

      //? Retrieves game platforms
      ws
          .getElementTitle(
              'li:nth-child(${(i * 2) + 1}) > div.row.gx-0.align-items-center > div.col.col-game.game-info.pe-3 > div > div')
          .forEach((element) {
        if (element.toLowerCase().contains("ps3")) {
          next50['gamePS3'] = true;
        }
        if (element.toLowerCase().contains("ps4")) {
          next50['gamePS4'] = true;
        }
        if (element.toLowerCase().contains("ps5")) {
          next50['gamePS5'] = true;
        }
        if (element.toLowerCase().contains("vita")) {
          next50['gameVita'] = true;
        }
      });
      //? Retrieves game playtime
      ws
          .getElementTitle(
              'li:nth-child(${(i * 2) + 1}) > div.row.gx-0.align-items-center > div.col.col-game.game-info.pe-3 > div > span.hours')
          .forEach((element) {
        next50['gameTime'] = element.trim();
      });
      //? Retrieves game ID, game Last Played timestamp and game Completed timestamp (when available)
      ws.getElement('li:nth-child(${(i * 2) + 1}).col-12.game-visible.psn', [
        'data-gameid',
        'data-lastplayed',
        'data-completion'
      ]).forEach((element) {
        next50['gameID'] = element['attributes']['data-gameid'].trim();
        next50['gameLastPlayedTimestamp'] =
            int.parse(element['attributes']['data-lastplayed'].trim());
        next50['gameCompletionTimestamp'] =
            int.parse(element['attributes']['data-completion'].trim());
      });
      //? Retrieves game trophy ratio (trophies earned / trophy total)
      ws
          .getElementTitle(
              'li:nth-child(${(i * 2) + 1}) > div.row.gx-0.align-items-center > div.col-12.col-md.px-3.pb-4.pe-md-0.pb-md-0.game-progress > div.row.gx-0.progress-units-top.pb-2 > div:first-child')
          .forEach((element) {
        next50['gameRatio'] = element.trim();
      });
      //? Retrieves game EXP
      ws
          .getElementTitle(
              'li:nth-child(${(i * 2) + 1}) > div.row.gx-0.align-items-center > div.col-12.col-md.px-3.pb-4.pe-md-0.pb-md-0.game-progress > div.row.gx-0.progress-units-top.pb-2 > div:nth-child(3)')
          .forEach((element) {
        next50['gameEXP'] = int.parse(element.replaceAll(",", "").trim());
      });
      //? Retrieves game bronze trophies
      ws
          .getElementTitle(
              'li:nth-child(${(i * 2) + 1}) > div.row.gx-0.align-items-center > div.col-12.col-md.px-3.pb-4.pe-md-0.pb-md-0.game-progress > div.holders > div > span.bronze')
          .forEach((element) {
        next50['gameBronze'] = int.parse(element.trim());
      });
      //? Retrieves game silver trophies
      ws
          .getElementTitle(
              'li:nth-child(${(i * 2) + 1}) > div.row.gx-0.align-items-center > div.col-12.col-md.px-3.pb-4.pe-md-0.pb-md-0.game-progress > div.holders > div > span.silver')
          .forEach((element) {
        next50['gameSilver'] = int.parse(element.trim());
      });
      //? Retrieves game gold trophies
      ws
          .getElementTitle(
              'li:nth-child(${(i * 2) + 1}) > div.row.gx-0.align-items-center > div.col-12.col-md.px-3.pb-4.pe-md-0.pb-md-0.game-progress > div.holders > div > span.gold')
          .forEach((element) {
        next50['gameGold'] = int.parse(element.trim());
      });
      //? Retrieves game platinum trophies
      ws.getElement(
          'li:nth-child(${(i * 2) + 1}) > div.row.gx-0.align-items-center > div.col-12.col-md.px-3.pb-4.pe-md-0.pb-md-0.game-progress > div.holders > div > span.platinum',
          []).forEach((element) {
        next50['gamePlatinum'] = 1;
      });
      //? Retrieves game percentage progress
      ws
          .getElementAttribute(
              'li:nth-child(${(i * 2) + 1}) > div.row.gx-0.align-items-center > div.col-12.col-md.px-3.pb-4.pe-md-0.pb-md-0.game-progress > div.progress > div',
              'style')
          .forEach((element) {
        next50['gamePercentage'] = int.parse(
            element.replaceAll("%;", "").replaceAll("width: ", "").trim());
      });
      //? Retrieves game last played date
      ws
          .getElementTitle(
              'li:nth-child(${(i * 2) + 1}) > div.row.gx-0.align-items-center > div.col-12.col-md.col-lastplayed.text-center.text-md-end.mb-2.mb-md-0 > div.lastplayed')
          .forEach((element) {
        next50['gameLastPlayed'] = element.trim();
      });
      parsedGames.add(next50);
    }
  }
  return parsedGames;
}

//? This will make a request to True Trophies to retrieve a small clickable profile card
Future<Map> trueTrophiesInfo(String user) async {
  await ws.loadFullURL('https://www.truetrophies.com/gamer/$user/');
  Map<String, dynamic> parsedData = {};
  try {
    //? True Trophies games list:
    //? https://www.truetrophies.com/gamer/
    //! ${parsedData['psnID']}
    //? /gamecollection?executeformfunction&function=AjaxList&params=oGameCollection%7C%26ddlSortBy%3DLastunlock%26ddlDLCInclusionSetting%3D
    //! "DLCIOwn" or "NoDLC" or "AllDLC"
    //? %26ddlPlatformIDs%3D%26sddOwnerShipStatusIDs%3D%26sddPlayStatusIDs%3D%26ddlContestStatus%3DAny%20status%26ddlGenreIDs%3D%26sddGameMediaID%3D%20%26ddlStartedStatus%3D0%26asdGamePropertyID%3D-1%26GameView%3DoptImageView%26chkColTitleimage%3DTrue%26chkColTitlename%3DTrue%26chkColPlatform%3DTrue%26chkColSiteScore%3DTrue%26chkColItems%3DTrue%26chkColCompletionpercentage%3DTrue%26chkColMyrating%3DTrue%26chkColLastunlock%3DTrue%26chkColOwnershipstatus%3DTrue%26chkColPlaystatus%3DTrue%26chkColNotforcontests%3DTrue%26txtBaseComparisonGamerID%3D13566%26oGameCollection_Order%3DLastunlock%26oGameCollection_Page%3D
    //! "1" leave oage as 1 if you are going to request all of the games as shown below
    //? %26oGameCollection_ItemsPerPage%3D
    //! ${parsedData['games'].toString()}
    //? %26oGameCollection_ShowAll%3DFalse%26txtGamerID%3D
    //! ${parsedData['gamerUniqueIDnumber']} this can be found in several profile links, including the user flag and the user buttons below their trophy count
    //? %26txtGameRegionID%3D1%26txtUseAchievementsForProgress%3DTrue

    //! Retrieves basic profile information, like avatar, about me, PSN ID, level, etc
    //? Retrieves PSN ID
    ws
        .getElementTitle(
            '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > span > h1 > a')
        .forEach((element) {
      parsedData['psnID'] = element.trim();
      if (parsedData['psnID'] != user && !parsedData['psnID'].contains(' ')) {
        settings.put('psnID', parsedData['psnID']);
      }
    });

    if (parsedData['psnID'] == null) {
      throw Error;
    }
    //? Retrieves PSN country
    ws
        .getElementAttribute(
            '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > span > a > img',
            'src')
        .forEach((element) {
      parsedData['country'] = "https://www.truetrophies.com/" + element.trim();
    });
    //? Retrieves PSN avatar
    ws
        .getElementAttribute(
            '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > img',
            'src')
        .forEach((element) {
      parsedData['avatar'] = "https://www.truetrophies.com/" + element;
    });
    //? Retrieves Pro Status
    ws
        .getElementAttribute(
            '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > span > span > a',
            'href')
        .forEach((element) {
      if (element == "/gopro") {
        parsedData['premium'] = true;
      }
    });
    //
    //? Retrieves PSN Level and TrueTrophy level
    ws.getElement(
        '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > div.scores > span:nth-child(2)',
        ['title']).forEach((element) {
      if (element['attributes']['title'].contains("TrueLevel:")) {
        parsedData['level'] = int.parse(element['attributes']['title']
            .split("PSN Level: ")[1]
            .replaceAll(",", ""));
        parsedData['trueTrophyLevel'] =
            int.parse(element['title'].replaceAll(",", ""));
      }
    });
    //! Retrieves trophy data
    //? Retrieves Total trophies
    ws
        .getElementTitle(
            '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > div.scores > a')
        .forEach((element) {
      parsedData['total'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves bronze trophies
    ws
        .getElementAttribute(
            '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > div.stats > a:nth-child(3)',
            'title')
        .forEach((element) {
      parsedData['bronze'] =
          int.parse(element.split(" ")[0].replaceAll(",", "").trim());
    });
    //? Retrieves silver trophies
    ws
        .getElementAttribute(
            '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > div.stats > a:nth-child(2)',
            'title')
        .forEach((element) {
      parsedData['silver'] =
          int.parse(element.split(" ")[0].replaceAll(",", "").trim());
    });
    //? Retrieves gold trophies
    ws
        .getElementAttribute(
            '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > div.stats > a:nth-child(1)',
            'title')
        .forEach((element) {
      parsedData['gold'] =
          int.parse(element.split(" ")[0].replaceAll(",", "").trim());
    });
    //? Retrieves platinum trophies
    ws
        .getElementAttribute(
            '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > div.stats > a:first-child',
            'title')
        .forEach((element) {
      parsedData['platinum'] =
          int.parse(element.split(" ")[0].replaceAll(",", "").trim());
    });
    //! Retrieves Profile overall statistics
    //? Retrieves total ganes
    ws
        .getElementAttribute(
            '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > div.stats > a:nth-child(4)',
            'title')
        .forEach((element) {
      parsedData['games'] =
          int.parse(element.split(" ")[0].replaceAll(",", "").trim());
    });
    //? Retrieves complete ganes
    ws.getElement(
        '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > div.badges > div > div > a',
        ['title']).forEach((element) {
      if (element['attributes']['title'] != null &&
          element['attributes']['title'].contains("completed games")) {
        parsedData['complete'] =
            int.parse(element['title'].replaceAll(",", "").trim());
        parsedData['incomplete'] = parsedData['games'] - parsedData['complete'];
        parsedData['completePercentage'] =
            (parsedData['complete'] / parsedData['games'] * 100)
                .toStringAsFixed(3);
        parsedData['incompletePercentage'] =
            (parsedData['incomplete'] / parsedData['games'] * 100)
                .toStringAsFixed(3);
      }
    });
    //? Retrieves TrueTrophy Ratio
    ws.getElement(
        '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > div.badges > div > div > a',
        ['title']).forEach((element) {
      if (element['attributes']['title'] != null &&
          element['attributes']['title'].contains("Ratio:")) {
        parsedData['ratio'] =
            double.parse(element['title'].replaceAll(",", "").trim());
      }
    });
    //? Retrieves completion and how many trophies to increase it
    ws.getElement(
        '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > div.badges > div > div > a',
        ['title']).forEach((element) {
      if (element['attributes']['title'] != null &&
          element['attributes']['title'].contains("Percentage: ")) {
        parsedData['completion'] = double.parse(element['title'].trim());
        parsedData['completionIncrease'] = int.parse(element['attributes']
                ['title']
            .split(" - ")[1]
            .split("more")[0]
            .trim());
        parsedData['nextCompletion'] =
            element['attributes']['title'].split("reach ")[1].trim();
      }
    });
    //? Retrieves TrueScore
    ws
        .getElementTitle(
            '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > div.scores > span:first-child')
        .forEach((element) {
      parsedData['trueScore'] = int.parse(element.replaceAll(",", "").trim());
    });
    settings.put('trueTrophiesDump', parsedData);
  } catch (e) {
    print("error scanning True Trophies");
    parsedData = null;
    settings.put('trueTrophies', false);
  }
  // print(parsedData);
  return parsedData;
}

//? This will make a request to PSN 100% to retrieve a small clickable profile card
Future<Map> psn100Info(String user) async {
  await ws.loadFullURL('https://psn100.net/player/$user');
  Map<String, dynamic> parsedData = {};
  try {
    //! Retrieves basic profile information, like avatar, about me, PSN ID, level, etc
    //? Retrieves PSN ID
    ws
        .getElementTitle(
            'body > main > div > div:nth-child(1) > div.col-8 > h1')
        .forEach((element) {
      parsedData['psnID'] = element.trim();
      if (parsedData['psnID'] != user && !parsedData['psnID'].contains(' ')) {
        settings.put('psnID', parsedData['psnID']);
      }
    });
    if (parsedData['psnID'] == null) {
      throw Error;
    }
    //? Retrieves PSN country
    ws
        .getElementAttribute(
            'body > main > div > div:nth-child(1) > div.col-2.text-right > img',
            'src')
        .forEach((element) {
      parsedData['country'] =
          element.replaceAll("/img/country/", "").replaceAll(".svg", "").trim();
    });
    //? Retrieves PSN avatar
    ws
        .getElementAttribute(
            'body > main >  div.container >div.row > div.col-2 > div > img',
            'src')
        .forEach((element) {
      if (element.contains("avatar")) {
        parsedData['avatar'] = 'https://psn100.net/' + element;
      } else if (element.contains("plus")) {
        parsedData['plus'] = true;
      }
    });
    //? Retrieves PSN Level progress first and then the level itself
    //? This is done because there is no individual DIV for the level, so you gotta
    //? fetch both and then remove the progress text from the level
    ws
        .getElementTitle(
            'body > main > div.container > div:nth-child(3) > div:first-child > div')
        .forEach((element) {
      parsedData['levelProgress'] = element.trim();
    });
    //? Retrieves PSN Level
    ws
        .getElementTitle(
            'body > main > div.container > div:nth-child(3) > div:first-child')
        .forEach((element) {
      parsedData['level'] = int.parse(element
          .replaceAll(parsedData['levelProgress'], "")
          .replaceAll(",", ""));
    });
    //! Retrieves trophy data
    //? Retrieves Total trophies
    ws
        .getElementTitle(
            'body > main > div.container > div:nth-child(3) > div:nth-child(11)')
        .forEach((element) {
      // print(element);
      parsedData['total'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves bronze trophies
    ws
        .getElementTitle(
            'body > main > div.container > div:nth-child(3) > div:nth-child(3)')
        .forEach((element) {
      parsedData['bronze'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves silver trophies
    ws
        .getElementTitle(
            'body > main > div.container > div:nth-child(3) > div:nth-child(5)')
        .forEach((element) {
      parsedData['silver'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves gold trophies
    ws
        .getElementTitle(
            'body > main > div.container > div:nth-child(3) > div:nth-child(7)')
        .forEach((element) {
      parsedData['gold'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves platinum trophies
    ws
        .getElementTitle(
            'body > main > div.container > div:nth-child(3) > div:nth-child(9)')
        .forEach((element) {
      parsedData['platinum'] = int.parse(element.replaceAll(",", "").trim());
    });
    //! Retrieves Profile overall statistics
    //? Retrieves total ganes
    ws
        .getElementTitle(
            'body > main > div > div:nth-child(5) > div:first-child > h5')
        .forEach((element) {
      parsedData['games'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves complete ganes
    ws
        .getElementTitle(
            'body > main > div > div:nth-child(5) > div:nth-child(3) > h5')
        .forEach((element) {
      parsedData['complete'] = int.parse(element.replaceAll(",", "").trim());
      parsedData['incomplete'] = parsedData['games'] - parsedData['complete'];
      parsedData['completePercentage'] =
          (parsedData['complete'] / parsedData['games'] * 100)
              .toStringAsFixed(3);
      parsedData['incompletePercentage'] =
          (parsedData['incomplete'] / parsedData['games'] * 100)
              .toStringAsFixed(3);
    });
    //? Retrieves completion
    ws
        .getElementTitle(
            'body > main > div > div:nth-child(5) > div:nth-child(5) > h5')
        .forEach((element) {
      parsedData['completion'] =
          element.replaceAll(" average completion", "").trim();
    });
    //? Retrieves unearned trophies
    ws
        .getElementTitle(
            'body > main > div > div:nth-child(5) > div:nth-child(7) > h5')
        .forEach((element) {
      parsedData['unearned'] = int.parse(element.replaceAll(",", "").trim());

      parsedData['unearnedPercentage'] = (parsedData['unearned'] /
              (parsedData['total'] + parsedData['unearned']) *
              100)
          .toStringAsFixed(3);
      parsedData['totalPercentage'] = ((parsedData['total']) /
              (parsedData['total'] + parsedData['unearned']) *
              100)
          .toStringAsFixed(3);
    });
    //? Retrieves world rank by trophy points
    ws
        .getElementTitle(
            'body > main > div > div:nth-child(5) > div:nth-child(9) > h5 > a:first-child')
        .forEach((element) {
      parsedData['worldRank'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves world rank by rarity
    ws
        .getElementTitle(
            'body > main > div > div:nth-child(5) > div:nth-child(9) > h5 > a:nth-child(3)')
        .forEach((element) {
      parsedData['worldRarity'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves country rank by points
    ws
        .getElementTitle(
            'body > main > div > div:nth-child(5) > div:nth-child(11) > h5 > a:first-child')
        .forEach((element) {
      parsedData['countryRank'] = int.parse(element.replaceAll(",", "").trim());
    });
    //? Retrieves country rank by rarity
    ws
        .getElementTitle(
            'body > main > div > div:nth-child(5) > div:nth-child(11) > h5 > a:nth-child(3)')
        .forEach((element) {
      parsedData['countryRarity'] =
          int.parse(element.replaceAll(",", "").trim());
    });
    settings.put('psn100Dump', parsedData);
  } catch (e) {
    print("error scanning PSN 100%");
    parsedData = null;
    settings.put('psn100', false);
  }
  // print(parsedData);
  return parsedData;
}

//? This function contains all translated strings to be used.
//? If a language isn't fully supported, it will use the english words instead.
Map<String, Map<String, String>> regionSelect() {
  //? By default, this loads Yura in English. This is done so new updates can be released without needing
  //? to wait for updated translation. Yura will use english text on those new features while a language patch isn't done
  Map<String, Map<String, String>> availableText = {
    "home": {
      "appBar": "Yura: A Playstation-based trophy app!",
      "inputTitle": "Please, provide your PSN ID:",
      "inputText": "PSN ID goes here...",
      "updating": "Requesting profile info...",
      "settings": "Settings",
      'errorPSN':
          'No cards to display!\nThis happens because either you disabled all cards or provided a PSN ID that no website is tracking. You can fix either of those issues on the settings menu.',
      "supportedWebsites": "available websites:",
      "games": "Games:",
      "complete": "Games\nCompleted:",
      "incomplete": "Incomplete\nGames:",
      "completion": "Completion:",
      "hours": "Tracked\nHours:",
      "exp": "Exp\nEarned:",
      "unearned": "Unearned\nTrophies:",
      "worldRank": "World\nRank:",
      "countryRarity": "Country by\nRarity:",
      "countryRank": "Country\nRank:",
      "mimic":
          "Number of PSN Trophy Leaders tracked profiles that also share this avatar",
      "standard": "Standard\nRank:",
      "adjusted": "Adjusted\nRank:",
      "completist": "Completist\nRank:",
      "rarity": "Rarity\nRank:",
      "translation": "Translation",
      "version": "Version",
      "privacy": "Privacy",
      'undo': "Revert all settings"
    },
    "settings": {
      "trophyPicker": "Change trophy type display:",
      "yuraTrophies": "Use Yura's icons for trophies",
      "oldTrophies": "Use pre-PS5 trophy icons",
      "newTrophies": "Use post-PS5 trophy icons",
      "levelPicker": "Change level type calculation:",
      "oldLevel": "Use pre-PS5 leveling system",
      "newLevel": "Use post-PS5 leveling system",
      "languagePicker": "Change Yura's language:",
      "websitePicker": "Choose which sites to enable/disable:",
      "loadingPicker": "Change Yura's loading icon:",
      "themePicker": "Change Yura's theme:",
      "fontPicker": "Change Yura's font:",
      'refresh': "Refresh trophy data",
      "pink": "Wednesday",
      "orange": "Nature's Will",
      "blue": "Deep Ocean",
      "black": "Before Dawn",
      "white": "Dog Vision",
      "boredom": "True Royalty",
      "removePSN": "Remove the saved PSN ID?",
    },
    "trophy": {
      "total": "Total",
      "platinum": "Platinum",
      "gold": "Gold",
      "silver": "Silver",
      "bronze": "Bronze",
      "rarity7": "Prestige (0% - 1%)",
      "rarity6": "Ultra Rare (1% - 5%)",
      "rarity5": "Very Rare (5% - 10%)",
      "rarity4": "Rare (10% - 25%)",
      "rarity3": "Uncommon (25% - 50%)",
      "rarity1": "Common (50% - 100%)"
    },
    'bottomButtons': {
      'translationText':
          "Yura's translation is crowd-sourced. Know a language yet to be supported?\n\nIf you wish to help, the link below takes to a spreadsheet with the text used in Yura. Feel free to use the support Discord server to let us know that you are sending a translation sheet.",
      "translationButton": "Contribute!",
      "latestversion": "Most recent release:",
      "update": "Update now!",
      "updateGif":
          "Accurate representation of the coding process for this app.",
      'privacyText':
          "There is no privacy agreement for you to accept. Yura doesn't take or store any of your information outside of your device, everything you see on screen is exclusively processed locally and belongs exclusively to you.\n\nIf, in the future, some sort of feature gets added that requires PSN account information (a leaderboard, per example), you will be prompted if you wish to participate before any of your PSN data gets sent (personal information like device model, age, location, etc., will NEVER be sent!).\n\nEnjoy your total anonymity!"
    },
    "games": {
      'getAllTrophies': 'Update trophy data',
      'trophyLog': "Log",
      'trophyAdvisor': "Advisor",
      'overview': 'Overview',
      "backlog": "Backlog",
      'gameSearch': 'Game Search',
      "search": "Search:",
      "searchText": "Game",
      "filter": "Filter games:",
      'filteredGames': 'Number of games displayed (and filtered)',
      "incomplete": "Remove incomplete games",
      "complete": "Remove complete games",
      "timed": "Display only games with tracked time",
      "mustNotPlatinum": "Remove games where a platinum trophy was earned",
      "mustPlatinum": "Remove games where a platinum trophy was not earned",
      "togglePlatforms": "Filter systems:",
      "psv": "Remove PS Vita games",
      "ps3": "Remove PS3 games",
      "ps4": "Remove PS4 games",
      "ps5": "Remove PS5 games",
      "sort": "Sort games:",
      'lastPlayed': "Most recent",
      'firstPlayed': "Least recent",
      'expAscending': "Ascending EXP",
      'expDescending': "Descending EXP",
      'timeAscending': "Ascending tracked time",
      'timeDescending': "Descending tracked time",
      'completionAscending': "Ascending completion",
      'completionDescending': "Descending completion",
      'alphabeticalAscending': "Alphabetically",
      'alphabeticalDescending': "Alphabetically (reversed)",
      "options": "Options:",
      "display": "Change display:",
      "grid": "Enable grid view",
      "block": "Enable block view",
      "list": "Enable list view",
    },
    'gameSearch': {
      'appBar': 'Game Search',
      'notPSN': 'Show only Playstation games',
      'players': "Tracked players",
      'sortPlayer': "Sort by player count",
      'sortRatio': "Sort by number of unlockables",
      'sortPoints': "Sort by points",
      'achievements': "Achievements",
      'trophies': "Trophies",
      'points': "Points",
    },
    "trophies": {
      'trophies': 'Trophies:',
      "filter": "Filter trophies:",
      "options": "Options:",
      'settings': 'Settings:',
      "sort": "Sort trophies by:",
      "display": "Change view type:",
      "gap": "Gap",
      // filters
      "earned": "Display earned trophies",
      "unearned": "Display unearned trophies",
      "showHidden": "Display hidden trophies information",
      "urOnly": "Display only ultra rare trophies or better (0% - 5%)",
      "noCommons": "Display common trophies (50+%)",
      "hiddenTrophy":
          "This is a hidden trophy! To see it, earn it or change the setting on the cogwheel icon below.",
      // settings
      "hidden": "Display hidden trophies",
      "description": "Display trophies description",
      "DLCseparator": "Display DLC separate from main game trophies",
      "localization":
          "Enable/Disable localization for trophies (translated trophy names/description and translated timestamps)",
      // sorting
      "original": "Sort trophies by their original PSN order",
      "value": "Sort trophies by their PSN points",
      "alphabetical": "Sort trophies by alphabetical order",
      "rarity": "Sort trophies by their rarity",
      "exp": "Sort trophies by their exp",
      "earnedTimestamp": "Sort trophies by earned date",
      // display
      "grid": "Enable grid view",
      "minimal": "Enable minimalist view",
      "list": "Enable list view",
      // pull all trophies text
      "updating": "Now updating your trophy data.\nPlease wait...",
    },
    "log": {
      //? appBar
      'earnedTitle': "PSNID's Trophy Log",
      'unearnedTitle': "PSNID's Trophy Advisor",
      //? Distribution
      'exp': 'EXP',
      //? Search
      "searchText": "Trophy",
      //? Sorting
      "sortByRecentGame":
          "Sort trophies by how long ago you have last played the game",
      "type": "Sort by type:",
      "rarity": "Sort by rarity:",
      "platform": "Sort by platform",
      //? Date filtering
      "date": "Filter trophies by a specific date format",
      'years': "Year",
      'months': "Month",
      'days': "Day",
      'weekdays': "Weekday",
      'hours': "Hour",
      'minutes': "Minute",
      'seconds': 'Second',
      //? Rarity sorting
      'prestige': "Display Prestige (1-%) trophies",
      'ultraRare': "Display Ultra Rare (1% - 5%) trophies",
      'veryRare': 'Display Very Rare (5% - 10%) trophies',
      'rare': "Display Rare (10% - 25%) trophies",
      'uncommon': 'Display Uncommon (25% - 50%) trophies',
      'common': 'Display Common (50+%) trophies',
      //? Type sorting
      'platinum': "Display Platinum trophies",
      'gold': 'Display Gold trophies',
      'silver': 'Display Silver trophies',
      'bronze': 'Display Bronze trophies',
      //? Platform sorting
      'psv': 'Display Vita trophies',
      'ps3': 'Display PS3 trophies',
      'ps4': 'Display PS4 trophies',
      'ps5': 'Display PS5 trophies'
    },
    'overview': {
      'appBar': "PSNID's Overview",
      'rarestTrophy': 'Rarest Trophy',
      'totalTrophies': 'Trophies earned',
      'period': 'Time Span:',
      'currentMonth': 'Current Month',
      'currentYear': 'Current Year',
      'previousMonth': 'Previous Month',
      'previousYear': 'Previous Year',
      'YoY': 'Display Year over Year summary',
      'MoM': 'Display Month over Month summary (last 12 months only)',
      'trophyScore': 'Bronze: 1, Silver: 2, Gold: 6, Platinum: 12 or 20',
      'rarityScore':
          'Common: 0, Uncommon: 1, Rare: 2, Very Rare: 4, Ultra Rare: 8, Prestige: 16'
    },
    'backlog': {
      //? appBar
      'title': "PSNID's Backlog",
    },
    "time": {
      'second': 'second(s)',
      'minute': 'minute(s)',
      'hour': "hour(s)",
      'day': 'day(s)',
      'month': 'month(s)',
      'year': 'year(s)'
    },
    //? Since this is just the version number, this doesn't get translated regardless of chosen language.
    "version": {"version": "v0.61.130"}
  };
  //? This changes language to Brazilian Portuguese
  if (settings.get("language") == "br") {
    availableText["home"] = {
      "appBar": "Yura: Um aplicativo para troféus Playstation!",
      "inputTitle": "Por favor, informe sua ID PSN:",
      "inputText": "ID da PSN vai aqui...",
      "updating": "Pedindo informação do perfil...",
      "settings": "Configurações",
      'errorPSN':
          'Nenhum cartão para mostrar!\nIsso acontece porque ou você desativou todos os cartões ou a ID usada não é registrada em nenhum dos sites suportados. Você pode resolver qualquer uma dessas situações nas configurações.',
      "supportedWebsites": "Sites disponíveis:",
      "games": "Jogos:",
      "complete": "Jogos\nConcluídos:",
      "incomplete": "Jogos\nPendentes:",
      "completion": "Conclusão:",
      "hours": "Horas\nRegistradas:",
      "exp": "Exp\nAcumulada:",
      "unearned": "Troféus\nPendentes:",
      "countryRank": "Rank\nNacional:",
      "countryRarity": "Nacional por\nRaridade:",
      "worldRank": "Rank\nMundial:",
      "mimic":
          "Número de jogadores rastreados em PSN Trophy Leaders que também usam esse avatar",
      "standard": "Rank\nPadrão:",
      "adjusted": "Rank\nAjustado:",
      "completist": "Rank\nConclusão:",
      "rarity": "Rank\nRaridade:",
      "translation": "Tradução",
      "version": "Versão",
      "privacy": "Privacidade",
      'undo': "Desfazer todas as mudanças"
    };
    availableText["settings"] = {
      "trophyPicker": "Mude a aparência dos troféus:",
      "yuraTrophies": "Use os ícones padrões",
      "oldTrophies": "Use ícones anteriores ao PS5",
      "newTrophies": "Use ícones posteriores ao PS5",
      "levelPicker": "Mude como seu nível é calculado:",
      "oldLevel": "Use cálculo pré-PS5",
      "newLevel": "Use cálculo pós-PS5",
      "languagePicker": "Mude o idioma de Yura:",
      "websitePicker": "Escolha quais sites ativar/desativar:",
      "loadingPicker": "Mude o ícone de carregamento de Yura:",
      "themePicker": "Mude o tema de Yura:",
      "fontPicker": "Mude a fonte de Yura:",
      'refresh': "Atualizar informação de troféus",
      "pink": "Quarta-Feira",
      "orange": "Desejo da Natureza",
      "blue": "Oceano Profundo",
      "black": "Antes do Amanhecer",
      "white": "Visão de Cão",
      "boredom": "Verdadeira Realeza",
      "removePSN": "Remover a ID PSN salva?",
    };
    availableText["trophy"] = {
      "total": "Total",
      "platinum": "Platina",
      "gold": "Ouro",
      "silver": "Prata",
      "bronze": "Bronze",
      "rarity7": "Prestígio (0% - 1%)",
      "rarity6": "Ultra Raro (1% - 5%)",
      "rarity5": "Muito Raro (5% - 10%)",
      "rarity4": "Raro (10% - 25%)",
      "rarity3": "Incomum (25% - 50%)",
      "rarity1": "Comum (50% - 100%)"
    };
    availableText['bottomButtons'] = {
      'translationText':
          "Yura é traduzida através de contribuição colaborativa. Fala alguma lingua que ainda não tem suporte?\n\nO botão abaixo leva para a planilha com os textos usados dentro do aplicativo. Sinta-se livre para usar o servidor suporte de Discord para nos informar que você está mandando uma planilha de traduções.",
      "translationButton": "Contribua!",
      "latestversion": "Atualização mais recente:",
      "update": "Atualize agora!",
      "updateGif":
          "Representação precisa do processo de programar esse aplicativo.",
      "privacyText":
          "Não existe um contrato de privacidade que você precisa aceitar. Yura não envia ou guarda sua informação fora do seu aparelho, tudo o que você vê na tela é processado localmente e pertence exclusivamente a você.\n\nSe no futuro forem adicionadas funções que precisam de informações de jogadores (um placar de líderes, por exemplo), você será perguntado se deseja participar antes que qualquer informação da sua conta PSN seja enviada (informação pessoal como modelo do aparelho, idade, localização, etc., NUNCA será enviada!).\n\nAproveite sua anonimidade!"
    };
    availableText["games"] = {
      'getAllTrophies': 'Atualizar informação de troféus',
      'trophyLog': "Registro",
      'trophyAdvisor': "Pendentes",
      'overview': 'Resumo',
      'backlog': 'Projetos',
      'gameSearch': 'Pesquisa de Jogos',
      "search": "Pesquisa:",
      "searchText": "Jogo",
      "filter": "Filtre jogos:",
      'filteredGames': 'Quantidade de jogos mostrados (e filtrados)',
      "incomplete": "Remova jogos incompletos",
      "complete": "Remova jogos concluídos",
      "timed": "Mostrar apenas jogos com tempo registrado",
      "mustNotPlatinum": "Remova jogos platinados",
      "mustPlatinum": "Remova jogos não platinados",
      "togglePlatforms": "Filtre sistemas:",
      "psv": "Remova jogos de PS Vita",
      "ps3": "Remova jogos de PS3",
      "ps4": "Remova jogos de PS4",
      "ps5": "Remove jogos de PS5",
      "sort": "Reordene jogos:",
      'lastPlayed': "Jogado recentemente",
      'firstPlayed': "Jogado primeiro",
      'expAscending': "EXP crescente",
      'expDescending': "EXP decrescente",
      'timeAscending': "Tempo registrado crescente",
      'timeDescending': "Tempo registrado decrescente",
      'completionAscending': "Taxa de conclusão crescente",
      'completionDescending': "Taxa de conclusão decrescente",
      'alphabeticalAscending': "Alfabeticamente",
      'alphabeticalDescending': "Alfabeticamente (inverso)",
      "options": "Opções:",
      "display": "Mude a aparência:",
      "grid": "Ativar visualização por tela",
      "block": "Ativar visualização por blocos",
      "list": "Ativar visualização por lista",
    };
    availableText['gameSearch'] = {
      'appBar': 'Pesquisa de Jogos',
      'notPSN': 'Mostrar apenas jogos Playstation',
      'players': "Jogadores registrados",
      'sortPlayer': "Organizar por jogadores",
      'sortRatio': "Organizar por número de desbloqueáveis",
      'sortPoints': "Organizar por pontos",
      'achievements': "Conquistas",
      'trophies': "Troféus",
      'points': "Pontos",
    };
    availableText["trophies"] = {
      "options": "Opções:",
      'trophies': 'Troféus:',
      "filter": "Filtre troféus:",
      "sort": "Rearranjar troféus:",
      'settings': 'Configurações:',
      "display": "Mude a aparência:",
      "gap": "Tempo",
      // filters
      "earned": "Mostrar troféus conquistados",
      "unearned": "Mostrar troféus pendentes",
      "showHidden": "Mostrar informação de troféus secretos",
      "urOnly": "Mostrar apenas troféus ultra raros ou melhor (0% - 5%)",
      "noCommons": "Mostrar troféus comuns (50+%)",
      "hiddenTrophy":
          "Esse troféu é secreto! Para vê-lo, conquiste-o ou altere essa configuração clicando no botão de engrenagem abaixo.",
      // settings
      "hidden": "Mostrar troféus secretos",
      "description": "Mostrar descrições",
      "DLCseparator": "Separar troféus DLC de troféus jogo base",
      "localization":
          "Ativar/desativar localização para troféus (data de troféu, troféus e descrições traduzidas)",
      // sorting
      "original": "Organizar troféus por sua ordem original PSN",
      "value": "Organizar troféus por sua pontuação PSN",
      "alphabetical": "Organizar troféus alfabeticamente",
      "rarity": "Organizar troféus por sua raridade",
      "exp": "Organizar troféus por sua experiência",
      "earnedTimestamp": "Organizar troféus por data de conquista",
      // display
      "grid": "Ativar visualização por tela",
      "minimal": "Ativar visualização minimalista",
      "list": "Ativar visualização por lista",
      // pull all trophies text
      "updating":
          "Atualizando sua informação de troféus.\nPor favor, aguarde...",
    };
    availableText["log"] = {
      //? appBar
      'earnedTitle': "Registro de troféus obtidos de PSNID",
      'unearnedTitle': "Registro de troféus pendentes de PSNID",
      //? Distribution
      'exp': 'EXP',
      //? Search
      "searchText": "Troféu",
      //? Sorting
      "sortByRecentGame":
          "Organizar troféus de acordo com o tempo desde última vez que o jogo foi jogado",
      "type": "Organizar por tipo:",
      "rarity": "Organizar por raridade:",
      "platform": "Organizar por plataforma:",
      //? Date filtering
      "date": "Filtre troféus num formato específico de data",
      'years': "Ano",
      'months': "Mês",
      'days': "Dia",
      'weekdays': "Dias da semana",
      'hours': "Hora",
      'minutes': "Minuto",
      'seconds': 'Segundo',
      //? Rarity sorting
      'prestige': "Mostrar troféus Prestigiosos (0% - 1%)",
      'ultraRare': "Mostrar troféus Ultra Raros (1% - 5%)",
      'veryRare': 'Mostrar troféus Muito Raros (5% - 10%)',
      'rare': "Mostrar troféus Raros (10% - 25%)",
      'uncommon': 'Mostrar troféus Incomuns (25% - 50%)',
      'common': 'Mostrar troféus Comuns (50% - 100%)',
      //? Type sorting
      'platinum': "Mostrar troféus de Platina",
      'gold': 'Mostrar troféus de Ouro',
      'silver': 'Mostrar troféus de Prata',
      'bronze': 'Mostrar troféus de Bronze',
      //? Platform sorting
      'psv': 'Mostrar troféus de Vita',
      'ps3': 'Mostrar troféus de PS3',
      'ps4': 'Mostrar troféus de PS4',
      'ps5': 'Mostrar troféus de PS5'
    };
    availableText["overview"] = {
      'appBar': "Resumo de PSNID",
      'rarestTrophy': 'Troféu mais raro',
      'totalTrophies': 'Troféus conquistados',
      'period': 'Período:',
      'currentMonth': 'Mês atual',
      'currentYear': 'Ano atual',
      'previousMonth': 'Mês anterior',
      'previousYear': 'Ano anterior',
      'YoY': 'Mostrar um resumo de Ano sobre Ano',
      'MoM': 'Mostrar um resumo de Mês sobre Mês (apenas últimos 12 meses)',
      'trophyScore': 'Bronze: 1, Prata: 2, Ouro: 6, Platina: 12 ou 20',
      'rarityScore':
          'Comum: 0, Incomum: 1, Raro: 2, Muito Raro: 4, Ultra Raro: 8, Prestígio: 16'
    };
    availableText["backlog"] = {
      //? appBar
      'title': "Projetos de PSNID",
    };
    availableText["time"] = {
      'second': 'segundo(s)',
      'minute': 'minuto(s)',
      'hour': "hora(s)",
      'day': 'dia(s)',
      'month': 'mês/meses',
      'year': 'ano(s)'
    };
  }
  return availableText;
}

Map<String, Map<String, String>> regionalText = regionSelect();

//? This map stores all of the color scheming data to be used in the app
final Map<String, Map<String, Color>> themeSelector = {
  "primary": {
    "pink": Colors.pink[300],
    "blue": Colors.blueAccent[700],
    "orange": Colors.orange[800],
    "boredom": Colors.deepPurple[900],
    "white": Colors.black87,
    "black": Colors.blueGrey[900],
  },
  "secondary": {
    "pink": Colors.pink[50],
    "blue": Colors.lightBlue[200],
    "boredom": Colors.purple[100],
    "orange": Colors.amber[50],
    "white": Colors.white,
    "black": Colors.indigo[100],
  }
};

//? This will return what is the textStyle to be used.
//? It had to become a function because it was not properly updating on language change.
TextStyle textSelection({String theme, String family}) {
  if (family == null) {
    family = settings.get('font') ?? 'Oxygen';
  }
  if (theme == "textDark") {
    //? Option for dark thin text
    return TextStyle(
        color: themeSelector["primary"][settings.get("theme")],
        fontSize: Platform.isWindows ? 16 : 10,
        fontWeight: FontWeight.normal,
        decoration: TextDecoration.none,
        fontFamily: family);
  } else if (theme == "textDarkBold") {
    //? Option for dark bold text
    return TextStyle(
        color: themeSelector["primary"][settings.get("theme")],
        fontSize: Platform.isWindows ? 20 : 12,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.none,
        fontFamily: family);
  } else if (theme == "textLightBold") {
    //? Option for light bold text
    return TextStyle(
        color: themeSelector["secondary"][settings.get("theme")],
        fontSize: Platform.isWindows ? 20 : 12,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.none,
        fontFamily: family);
  } else {
    //? Option for light thin text
    return TextStyle(
        color: themeSelector["secondary"][settings.get("theme")],
        fontSize: Platform.isWindows ? 16 : 10,
        fontWeight: FontWeight.normal,
        decoration: TextDecoration.none,
        fontFamily: family);
  }
}

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
  'psntl': "images/psntl.png",
  'trueTrophies': "images/truetrophies.png",
  "psn100": "images/psn100.png",
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

Text timeGap(int recentTrophy, int oldTrophy, [bool plus]) {
  return Text(
    (plus == false ? "Gap: " : " (+ ") +
        [
          if ((Duration(seconds: oldTrophy - recentTrophy).inDays / 365)
                  .floor() >
              0)
            (Duration(seconds: oldTrophy - recentTrophy).inDays / 365)
                    .floor()
                    .toString() +
                " " +
                regionalText['time']['year'],
          if (((Duration(seconds: oldTrophy - recentTrophy).inDays / 30) % 12)
                  .floor() >
              0)
            ((Duration(seconds: oldTrophy - recentTrophy).inDays / 30) % 12)
                    .floor()
                    .toString() +
                " " +
                regionalText['time']['month'],
          if ((Duration(seconds: oldTrophy - recentTrophy).inDays % 30)
                  .floor() >
              0)
            (Duration(seconds: oldTrophy - recentTrophy).inDays % 30)
                    .floor()
                    .toString() +
                " " +
                regionalText['time']['day'],
          if ((Duration(seconds: oldTrophy - recentTrophy).inHours % 24)
                  .floor() >
              0)
            (Duration(seconds: oldTrophy - recentTrophy).inHours % 24)
                    .floor()
                    .toString() +
                " " +
                regionalText['time']['hour'],
          if ((Duration(seconds: oldTrophy - recentTrophy).inMinutes % 60)
                  .floor() >
              0)
            (Duration(seconds: oldTrophy - recentTrophy).inMinutes % 60)
                    .floor()
                    .toString() +
                " " +
                regionalText['time']['minute'],
          if ((Duration(seconds: oldTrophy - recentTrophy).inSeconds % 60)
                  .floor() >
              0)
            (Duration(seconds: oldTrophy - recentTrophy).inSeconds % 60)
                    .floor()
                    .toString() +
                " " +
                regionalText['time']['second'],
        ].join(', ') +
        (plus == false ? "" : ")"),
    style: textSelection(),
    textAlign: TextAlign.left,
  );
}

//? This returns a properly named and formatted Tooltip or Row() of trophy icon + spacing + number of trophies
//? Number of trophies and formatting is optional. If not provided, only the proper Image.asset()
//? will be returned, without spacing and without number of trophies.
//? If style is not provided, it will use default textLight formatting
Widget trophyType(String type,
    {quantity = -1,
    TextStyle style,
    String size = "big",
    bool tooltip = true}) {
  Row displayedTrophies = Row(
    children: [
      Image.asset(trophyStyle(type),
          //? checks if a size was provided. if yes, retuns smaller trophies
          //? if not, checks if it's a trophy cluster and returns a slightly smaller image if so
          height: size == "small"
              ? Platform.isWindows
                  ? 20
                  : 10
              : type == 'total'
                  ? Platform.isWindows
                      ? 25
                      : 14
                  : Platform.isWindows
                      ? 30
                      : 15),
      if (quantity != -1) SizedBox(width: Platform.isWindows ? 5 : 3),
      if (quantity != -1)
        Text(quantity != double.nan ? quantity.toString() : quantity,
            style: style ?? textSelection()),
    ],
  );
  //? If tooltip is true (default), returns the Row within a tooltip
  if (tooltip == true) {
    return Tooltip(
      message: regionalText['trophy'][type],
      child: displayedTrophies,
    );
  }
  //? If tooltip is false, does not return the tooltip
  //? (useful when using the trophy icon in a menu that already has another tooltip)
  return displayedTrophies;
}

//? This returns a properly named and formatted Tooltip or Row() of rarity icon + spacing + number of trophies
//? Number of trophies and formatting is optional. If not provided, only the proper Image.asset()
//? will be returned, without spacing and without number of trophies.
//? If style is not provided, it will use default textLight formatting
Widget rarityType(
    {String type,
    quantity = -1,
    double rarity,
    TextStyle style,
    String size = "big",
    bool tooltip = true}) {
  if (rarity != null) {
    //? Tracks if this trophy is prestige
    if (rarity < 1) {
      type = 'rarity7';
    }
    //? Tracks if this trophy is ultra rare
    else if (rarity >= 1 && rarity < 5) {
      type = 'rarity6';
    }
    //? Tracks if this trophy is very rare
    else if (rarity >= 5 && rarity < 10) {
      type = 'rarity5';
    }
    //? Tracks if this trophy is rare
    else if (rarity >= 10 && rarity < 25) {
      type = 'rarity4';
    }
    //? Tracks if this trophy is uncommon
    else if (rarity >= 25 && rarity < 50) {
      type = 'rarity3';
    }
    //? Tracks if this trophy is common
    else if (rarity >= 50) {
      type = 'rarity1';
    }
  }
  Row displayedRarity = Row(
    children: [
      if (rarity != null) Text(" (", style: style ?? textSelection()),
      Image.asset(img[type],
          //? checks if a size was provided. if yes, retuns smaller trophies
          //? if not, checks if it's a trophy cluster and returns a slightly smaller image if so
          height: size == "small"
              ? Platform.isWindows
                  ? 20
                  : 10
              : Platform.isWindows
                  ? 30
                  : 15),
      if (quantity != -1) SizedBox(width: 3),
      if (quantity != -1)
        Text(quantity != double.nan ? quantity.toString() : quantity,
            style: style ?? textSelection()),
      if (rarity != null)
        Text(" " + rarity.toString() + "%)", style: style ?? textSelection()),
    ],
  );
  //? If tooltip is true (default), returns the Row within a tooltip
  if (tooltip == true) {
    return Tooltip(
      message: regionalText['trophy'][type],
      child: displayedRarity,
    );
  }
  //? If tooltip is false, does not return the tooltip
  //? (useful when using the trophy icon in a menu that already has another tooltip)
  return displayedRarity;
}

Row levelType(int plat, int gold, int silver, int bronze) {
  Row newPsnLevel(int plat, int gold, int silver, int bronze) {
    int totalExp = 0 * (plat ?? 0) +
        90 * (gold ?? 0) +
        30 * (silver ?? 0) +
        15 * (bronze ?? 0);
    int gap;
    int tier;
    int fromPreviousTier;
    if (totalExp < 5940) {
      // range = 1-99
      gap = 60;
      tier = 1;
      fromPreviousTier = 0;
    } else if (totalExp < 14940) {
      // range = 100-199
      gap = 90;
      tier = 2;
      fromPreviousTier = 5940;
    } else if (totalExp < 59940) {
      // range = 200-299
      gap = 450;
      tier = 3;
      fromPreviousTier = 14940;
    } else if (totalExp < 149940) {
      // range = 300-399
      gap = 900;
      tier = 4;
      fromPreviousTier = 59940;
    } else if (totalExp < 284940) {
      // range = 400-499
      gap = 1350;
      tier = 5;
      fromPreviousTier = 149940;
    } else if (totalExp < 464940) {
      // range = 500-599
      gap = 1800;
      tier = 6;
      fromPreviousTier = 284940;
    } else if (totalExp < 689940) {
      // range = 600-699
      gap = 2250;
      tier = 7;
      fromPreviousTier = 464940;
    } else if (totalExp < 959940) {
      // range = 700-799
      gap = 2700;
      tier = 8;
      fromPreviousTier = 689940;
    } else if (totalExp < 1274940) {
      // range = 800-899
      gap = 3150;
      tier = 9;
      fromPreviousTier = 959940;
    } else if (totalExp < 1634940) {
      // range = 900-999
      gap = 3600;
      tier = 10;
      fromPreviousTier = 1274940;
    } else if (totalExp < 1994940) {
      // range = 1000-1099
      // Note: these are not actually enabled on PSN, but rather projected on trophy websites.
      gap = 4050;
      tier = 11;
      fromPreviousTier = 1634940;
    } else if (totalExp < 2399940) {
      // range = 1100-1199
      // Note: these are not actually enabled on PSN, but rather projected on trophy websites.
      gap = 4500;
      tier = 12;
      fromPreviousTier = 1994940;
    } else if (totalExp < 2894940) {
      // range = 1200-1299
      // Note: these are not actually enabled on PSN, but rather projected on trophy websites.
      gap = 4950;
      tier = 13;
      fromPreviousTier = 2399940;
    } else if (totalExp < 3434940) {
      // range = 1300-1399
      // Note: these are not actually enabled on PSN, but rather projected on trophy websites.
      gap = 5400;
      tier = 14;
      fromPreviousTier = 2894940;
    } else if (totalExp < 4019940) {
      // range = 1400-1499
      // Note: these are not actually enabled on PSN, but rather projected on trophy websites.
      gap = 5850;
      tier = 15;
      fromPreviousTier = 3434940;
    } else if (totalExp < 4649940) {
      // range = 1500-1599
      // Note: these are not actually enabled on PSN, but rather projected on trophy websites.
      gap = 6300;
      tier = 16;
      fromPreviousTier = 4019940;
    } else if (totalExp < 5324940) {
      // range = 1600-1699
      // Note: these are not actually enabled on PSN, but rather projected on trophy websites.
      gap = 6750;
      tier = 17;
      fromPreviousTier = 4649940;
    } else if (totalExp < 6034940) {
      // range = 1700-1799
      // Note: these are not actually enabled on PSN, but rather projected on trophy websites.
      gap = 7100;
      tier = 18;
      fromPreviousTier = 5324940;
    } else if (totalExp < 6789940) {
      // range = 1800-1899
      // Note: these are not actually enabled on PSN, but rather projected on trophy websites.
      gap = 7550;
      tier = 19;
      fromPreviousTier = 6034940;
    } else if (totalExp < 7589940) {
      // range = 1900-1999
      // Note: these are not actually enabled on PSN, but rather projected on trophy websites.
      gap = 8000;
      tier = 20;
      fromPreviousTier = 6789940;
    } else {
      // range = 2000+
      // Note: these are not actually enabled on PSN, but rather projected on trophy websites.
      return Row(children: [
        Image.asset(img['platinumlevel'], scale: Platform.isWindows ? 3 : 4),
        SizedBox(width: Platform.isWindows ? 5 : 3),
        Text("2000 (100%)", style: textSelection())
      ]);
    }

    int extraEXP = totalExp - fromPreviousTier;
    String progressPercentage =
        (((extraEXP % gap) / gap) * 100).toStringAsFixed(2);
    String currentLevel =
        ((extraEXP / gap).floor() + (tier - 1) * 100).toString();

    String levelTier(int bracket) {
      if (bracket == 1) {
        return img['bronze1'];
      }
      if (bracket == 2) {
        return img['bronze2'];
      }
      if (bracket == 3) {
        return img['bronze3'];
      }
      if (bracket == 4) {
        return img['silver1'];
      }
      if (bracket == 5) {
        return img['silver2'];
      }
      if (bracket == 6) {
        return img['silver3'];
      }
      if (bracket == 7) {
        return img['gold1'];
      }
      if (bracket == 8) {
        return img['gold2'];
      }
      if (bracket == 9 || bracket == 10) {
        if (bracket == 10 && (extraEXP / gap).floor() == 99) {
          return img['platinumlevel'];
        }
        return img['gold3'];
      } else {
        return img['platinumlevel'];
      }
    }

    return Row(children: [
      Image.asset(levelTier(tier), scale: Platform.isWindows ? 3 : 4),
      SizedBox(width: Platform.isWindows ? 5 : 3),
      Text("$currentLevel ($progressPercentage%)", style: textSelection())
    ]);
  }

  Row oldPsnLevel(plat, gold, silver, bronze) {
    int totalExp = 0 * (plat ?? 0) +
        90 * (gold ?? 0) +
        30 * (silver ?? 0) +
        15 * (bronze ?? 0);
    if (totalExp == 0) {
      return Row(children: [
        Image.asset(img['oldLevel'], scale: Platform.isWindows ? 1 : 1.3),
        Text("1", style: textSelection())
      ]);
    } else if (totalExp < 200) {
      return Row(children: [
        Image.asset(img['oldLevel'], scale: Platform.isWindows ? 1 : 1.3),
        Text("2", style: textSelection())
      ]);
    } else if (totalExp < 600) {
      return Row(children: [
        Image.asset(img['oldLevel'], scale: Platform.isWindows ? 1 : 1.3),
        Text("3", style: textSelection())
      ]);
    } else if (totalExp < 1200) {
      return Row(children: [
        Image.asset(img['oldLevel'], scale: Platform.isWindows ? 1 : 1.3),
        Text("4", style: textSelection())
      ]);
    } else if (totalExp < 2400) {
      return Row(children: [
        Image.asset(img['oldLevel'], scale: Platform.isWindows ? 1 : 1.3),
        Text("5", style: textSelection())
      ]);
    } else if (totalExp < 4000) {
      return Row(children: [
        Image.asset(img['oldLevel'], scale: Platform.isWindows ? 1 : 1.3),
        Text("6", style: textSelection())
      ]);
    } else if (totalExp < 16000) {
      int extraEXP = totalExp - 4000;
      int gap = 2000;
      double progressPercentage =
          double.parse((((extraEXP % gap) / gap) * 100).toStringAsFixed(2));
      int currentLevel = (extraEXP / gap).floor() + 6;
      return Row(children: [
        Image.asset(img['oldLevel'], scale: Platform.isWindows ? 1 : 1.3),
        Text("$currentLevel ($progressPercentage%)", style: textSelection())
      ]);
    } else if (totalExp < 128000) {
      int extraEXP = totalExp - 16000;
      int gap = 8000;
      double progressPercentage =
          double.parse((((extraEXP % gap) / gap) * 100).toStringAsFixed(2));
      int currentLevel = (extraEXP / gap).floor() + 12;
      return Row(children: [
        Image.asset(img['oldLevel'], scale: Platform.isWindows ? 1 : 1.3),
        Text("$currentLevel ($progressPercentage%)", style: textSelection())
      ]);
    } else {
      int extraEXP = totalExp - 128000;
      int gap = 10000;
      double progressPercentage =
          double.parse((((extraEXP % gap) / gap) * 100).toStringAsFixed(2));
      int currentLevel = (extraEXP / gap).floor() + 26;
      return Row(children: [
        Image.asset(img['oldLevel'], scale: Platform.isWindows ? 1 : 1.3),
        Text("$currentLevel ($progressPercentage%)", style: textSelection())
      ]);
    }
  }

  if (settings.get('levelType') == "new") {
    return newPsnLevel(plat, gold, silver, bronze);
  } else {
    return oldPsnLevel(plat, gold, silver, bronze);
  }
}

//? This function takes your earned trophies and returns a List of how much
//? each trophy type is giving you of your points total. It can also be used to
//? calculate points distribution when totals are below 100%, like an incomplete trophy list.
List<double> trophyPointsDistribution(
    int plat, int gold, int silver, int bronze, int total) {
  int p = plat * (settings.get('levelType') == "new" ? 20 : 12);
  int g = gold * 6;
  int s = silver * 2;
  int b = bronze;
  int sum = p + g + s + b;
  if (total == 0) {
    total = 1;
    sum = 1;
  }
  double pValue = (100 * p / sum * 100 * total / 100).ceil() / 100;
  double gValue = (100 * g / sum * 100 * total / 100).floor() / 100;
  double sValue = (100 * s / sum * 100 * total / 100).floor() / 100;
  double bValue = (100 * b / sum * 100 * total / 100).floor() / 100;
  List<double> numbers = [pValue, gValue, sValue, bValue];
  // print(numbers);
  // print(numbers.reduce((value, element) => value + element));
  return numbers;
}

//? This function will return a loading selector, you just need to provide the theme
Widget loadingSelector([String loader, String color = "light", double size]) {
  if (loader == null) {
    loader = settings.get('loading');
  }
  Color pickedColor = themeSelector['secondary'][settings.get('theme')];
  if (color == "dark") {
    pickedColor = themeSelector['primary'][settings.get('theme')];
  }
  if (loader == "wave") {
    return SpinKitWave(
      size: size ?? 35,
      duration: Duration(milliseconds: 1000),
      itemBuilder: (BuildContext context, int index) {
        return DecoratedBox(
          decoration: BoxDecoration(color: pickedColor),
        );
      },
    );
  } else if (loader == "foldingCube") {
    //fadingFour
    return SpinKitFoldingCube(
      size: size ?? 30,
      duration: Duration(milliseconds: 2000),
      itemBuilder: (BuildContext context, int index) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: pickedColor,
          ),
        );
      },
    );
  } else if (loader == "fadingGrid") {
    return SpinKitFadingGrid(
      size: size ?? 35,
      duration: Duration(milliseconds: 600),
      itemBuilder: (BuildContext context, int index) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: pickedColor,
          ),
        );
      },
    );
  } else if (loader == "cubeGrid") {
    return SpinKitCubeGrid(
      size: size ?? 40,
      duration: Duration(milliseconds: 1200),
      itemBuilder: (BuildContext context, int index) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: pickedColor,
          ),
        );
      },
    );
  }
  return SpinKitPouringHourglass(
    size: size ?? 45,
    duration: Duration(milliseconds: 3000),
    color: pickedColor,
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
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //? This bool will store the status of the update and disable the FloatingActionButton from rendering
  bool isUpdating = false;

  //? The Debouncer (class created above) is now instantiated here so the search is delayed until the user stops typing.
  Debouncer debounce = Debouncer(milliseconds: 2000);

  //? These are the bits of information, they are processed by each individual function if there is no error and
  //? then stored on the database on the user's device. This is done to save resources and not request every time
  //? the user performs an update to the UI.
  Map psnpDump = settings.get('psnpDump');
  Map psntlDump = settings.get('psntlDump');
  Map trueTrophiesDump = settings.get('trueTrophiesDump');
  Map exophaseDump = settings.get('exophaseDump');
  Map psn100Dump = settings.get('psn100Dump');

  //? This function will update every enabled profile in order
  void updateProfiles() async {
    //? First it changes the information on every document to be as updating, so every block displays a loading icon
    isUpdating = true;

    //? then, if it's enabled, it updates PSNP first while waiting the result to not start the other websites yet.
    if (settings.get("psnp") == true) {
      setState(() {
        psnpDump = {'update': true};
      });
      psnpDump = await psnpInfo(settings.get("psnID"));
      setState(() {
        psnpDump = settings.get("psnpDump");
      });
    }

    //? then, if it's enabled, it updates PSN Trophy Leaders and waits the result.
    if (settings.get("psntl") == true) {
      setState(() {
        psntlDump = {'update': true};
      });
      psntlDump = await psntlInfo(settings.get("psnID"));
      setState(() {
        psntlDump = settings.get("psntlDump");
      });
    }

    //? then, if it's enabled, it updates Exophase and waits the result.
    if (settings.get("exophase") == true) {
      setState(() {
        //? Sets this Map to make the loading icon appear.
        exophaseDump = {'update': true};
      });

      //? This will return a HTML parsed as String to be used in the compute() function below.
      String exophaseHTML = await parsePage(
          'https://www.exophase.com/psn/user/${settings.get("psnID")}/');

      int oldGames = settings.get('exophaseDump') == null
          ? 0
          : settings.get('exophaseDump')['games'];
      int oldTrophies = settings.get('exophaseDump') == null
          ? 0
          : settings.get('exophaseDump')['total'];

      try {
        //? Uses the string above to run the compute() function and avoid jank.
        //? This compute function will pull user profile data like total number of trophies, number of games played, etc..
        exophaseDump = await compute(exophaseInfo, exophaseHTML);

        //? If the ID is valid and uses better uppercase formating than the ID provided, save it as actual PSN ID in the settings.
        if (exophaseDump['psnID'] != settings.get('psnID') &&
            !exophaseDump['psnID'].contains(' ')) {
          settings.put('psnID', exophaseDump['psnID']);
        }

        //? Checks if the user has new trophies and games, otherwise skip updating game stats.
        //? This is done to save on resources/improve waiting times.
        if (oldGames != 0 &&
            oldGames == exophaseDump['games'] &&
            oldTrophies == exophaseDump['total']) {
        } else {
          List oldExophaseGames = settings.get('exophaseGames');

          //? This Map temporarily stores data to pass into another compute() function as the body to get ther remaining games.
          Map<String, dynamic> exophaseData = {
            'html': exophaseHTML,
            'games': exophaseDump['games'],
            'position': 0
          };

          if (oldExophaseGames != null &&
              (exophaseDump['games'] ?? 0) - oldExophaseGames.length < 50) {
            //? Run another compute() function using the Map exophaseData to process games information.
            //? This compute function will pull game data for up to 50 games at a time.
            List<Map<String, dynamic>> newExophaseGames =
                await compute(fetchExophaseGames, exophaseData);

            //? Separates only the links from the new games into another list to be used as filter in filteredOldGamesList.
            List newGamesLink = [];
            for (var i = 0; i < newExophaseGames.length; i++) {
              newGamesLink.add(newExophaseGames[i]['gameLink']);
            }

            //? Filters the old list saved in the database to return a new list where repeated game links will not be returned.
            List filteredOldGamesList = oldExophaseGames
                    .where((element) =>
                        !newGamesLink.contains(element['gameLink']))
                    .toList() ??
                [];

            //? Stores the new updated games and the old untouched games together in a single list.
            List exophaseGames = [...newExophaseGames, ...filteredOldGamesList];

            //? Save the new list into the database for future use.
            settings.put('exophaseGames', exophaseGames);
          } else {
            //? Run another compute() function using the Map exophaseData to process games information.
            //? This compute function will pull game data for up to 50 games at a time.
            List exophaseGames =
                await compute(fetchExophaseGames, exophaseData);

            for (int i = 1; (i * 50) < exophaseData['games']; i++) {
              setState(() {
                exophaseUpdateProgress =
                    "${regionalText['home']['games']} ${i * 50}/${exophaseData['games']}";
              });
              //! Define a variable and make the main screen display how many games were fetched so far
              dynamic extraGames = await (await ws.poster(
                  Uri.parse(
                      'https://api.exophase.com/public/user/get_latest_games'),
                  body: {
                    'env': 'psn',
                    'playerid': exophaseDump['exophaseID'],
                    'sort': '1',
                    'start': '${i * 50}'
                  }))['renderedHtml'];

              // print(extraGames);

              exophaseData['position'] = i;
              exophaseData['html'] = extraGames.toString();
              List<Map<String, dynamic>> newData =
                  await compute(fetchExophaseGames, exophaseData);
              exophaseGames.addAll(newData);
            }

            exophaseUpdateProgress = regionalText['home']['updating'];

            //? Once successful, save the retrived games in the database to avoid spamming network requests.
            settings.put('exophaseGames', exophaseGames);

            print(exophaseGames);
          }
        }
      } catch (e) {
        print("error scanning Exophase");
        exophaseDump = null;
        settings.put('exophase', false);
      }

      //? Save all the received information from the compute() function in the database.
      //? This is done to avoid sending repeated data requests unnecessarily.
      settings.put('exophaseDump', exophaseDump);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          List data = [];
          settings.get('exophaseGames').forEach((element) {
            if (element['gamePercentage'] > 0) {
              data.add({
                'gameWebsite': 'exophase',
                'gameLink': element['gameLink'],
                'gamePercentage': element['gamePercentage'],
                'gameID': element['gameID'],
                'gameName': element['gameName'],
                'gameImage': element['gameImage'],
                'gamePS3': element['gamePS3'] == true ? true : false,
                'gamePS4': element['gamePS4'] == true ? true : false,
                'gamePS5': element['gamePS5'] == true ? true : false,
                'gameVita': element['gameVita'] == true ? true : false,
              });
            }
          });
          return PullTrophies(pullTrophiesData: data.reversed.toList());
        }),
      );
    }

    //? then, if it's enabled, it updates True Trophies and waits the result.
    if (settings.get("trueTrophies") == true) {
      setState(() {
        trueTrophiesDump = {'update': true};
      });
      trueTrophiesDump = await trueTrophiesInfo(settings.get("psnID"));
      setState(() {
        trueTrophiesDump = settings.get("trueTrophiesDump");
      });
    }

    //? then, if it's enabled, it updates PSN100 and waits the result.
    if (settings.get("psn100") == true) {
      setState(() {
        psn100Dump = {'update': true};
      });
      psn100Dump = await psn100Info(settings.get("psnID"));
      setState(() {
        psn100Dump = settings.get("psn100Dump");
      });
    }
    setState(() {
      //? After it finishes updating every enabled card, allow the floating action button to reappear.
      isUpdating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: isUpdating == true
            ? null
            : AppBar(
                toolbarHeight: 40,
                centerTitle: true,
                title: Text(
                  regionalText["home"]["appBar"],
                  style: textSelection(),
                ),
                backgroundColor: themeSelector["primary"]
                    [settings.get("theme")],
                //? This instantiate the settings box.
                actions: [
                  Builder(
                    builder: (context) => Tooltip(
                      message: regionalText["home"]["settings"],
                      child: IconButton(
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          icon: Icon(
                            Icons.settings,
                            size: 20,
                            color: themeSelector["secondary"]
                                [settings.get("theme")],
                          ),
                          onPressed: () =>
                              Scaffold.of(context).openEndDrawer()),
                    ),
                  )
                ],
              ),
        endDrawer: Center(
          child: Container(
            decoration: BoxDecoration(
                color: themeSelector["secondary"][settings.get("theme")],
                borderRadius: BorderRadius.all(Radius.circular(25))),
            width: 350,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBar(
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(25))),
                    title: Text(
                      regionalText["home"]["settings"],
                      style: textSelection(),
                    ),
                    centerTitle: true,
                    automaticallyImplyLeading: false,
                    backgroundColor: themeSelector["primary"]
                        [settings.get("theme")],
                    actions: [
                      IconButton(
                          splashColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          icon: Icon(
                            Icons.close,
                            color: themeSelector["secondary"]
                                [settings.get("theme")],
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          })
                    ],
                  ),
                  //? Allows the user to change the trophy type
                  //? User cannot change to the currently chosen type
                  Padding(
                    padding: EdgeInsets.all(Platform.isWindows ? 10.0 : 5.0),
                    child: Center(
                      child: Text(
                        regionalText["settings"]["trophyPicker"],
                        style: textSelection(theme: "textDark"),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Wrap(
                    children: [
                      //? Option to use Yura's trophies as default display
                      if (settings.get('trophyType') != "yura")
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: Platform.isWindows ? 10.0 : 5.0),
                          child: Tooltip(
                            message: regionalText["settings"]["yuraTrophies"],
                            child: InkWell(
                                child: Image.asset(
                                  img['platFill'],
                                  height: Platform.isWindows ? 50 : 30,
                                ),
                                onTap: () {
                                  setState(() {
                                    settings.put('trophyType', 'yura');
                                  });
                                }),
                          ),
                        ),
                      //? Option to use old PSN trophies as default display
                      if (settings.get('trophyType') != "old")
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: Platform.isWindows ? 10.0 : 5.0),
                          child: Tooltip(
                            message: regionalText["settings"]["oldTrophies"],
                            child: InkWell(
                                child: Image.asset(
                                  img['oldPlatinum'],
                                  height: Platform.isWindows ? 50 : 30,
                                ),
                                onTap: () {
                                  setState(() {
                                    settings.put('trophyType', 'old');
                                  });
                                }),
                          ),
                        ),
                      //? Option to use new PSN trophies as default display
                      if (settings.get('trophyType') != "new")
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: Platform.isWindows ? 10.0 : 5.0),
                          child: Tooltip(
                            message: regionalText["settings"]["newTrophies"],
                            child: InkWell(
                                child: Image.asset(
                                  img['newPlatinum'],
                                  height: Platform.isWindows ? 50 : 30,
                                ),
                                onTap: () {
                                  setState(() {
                                    settings.put('trophyType', 'new');
                                  });
                                }),
                          ),
                        ),
                    ],
                  ),
                  //? Allows the user to change the leveling system used
                  //? User cannot change to the currently chosen system
                  Padding(
                    padding: EdgeInsets.all(Platform.isWindows ? 10.0 : 5.0),
                    child: Center(
                      child: Text(
                        regionalText["settings"]["levelPicker"],
                        style: textSelection(theme: "textDark"),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: Platform.isWindows ? 10.0 : 5.0),
                    child: Wrap(
                      children: [
                        //? Option to use Yura's trophies as default display
                        if (settings.get('levelType') != "new")
                          Tooltip(
                            message: regionalText["settings"]["newLevel"],
                            child: InkWell(
                                child: Image.asset(
                                  img['platinumlevel'],
                                  height: Platform.isWindows ? 50 : 30,
                                ),
                                onTap: () {
                                  setState(() {
                                    settings.put('levelType', 'new');
                                  });
                                }),
                          ),
                        //? Option to use old PSN trophies as default display
                        if (settings.get('levelType') == "new")
                          Tooltip(
                            message: regionalText["settings"]["oldLevel"],
                            child: InkWell(
                                child: Container(
                                  height: Platform.isWindows ? 50 : 30,
                                  child: Image.asset(
                                    img['oldLevel'],
                                    scale: 0.5,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    settings.put('levelType', 'old');
                                  });
                                }),
                          ),
                      ],
                    ),
                  ),
                  //? Permite que o usuário troque o idioma do aplicativo.
                  //? O usuário não verá a opção de trocar para o mesmo idioma que estiver ativo
                  Padding(
                    padding: EdgeInsets.all(Platform.isWindows ? 10.0 : 5.0),
                    child: Center(
                      child: Text(
                        regionalText["settings"]["languagePicker"],
                        style: textSelection(theme: "textDark"),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: Platform.isWindows ? 10.0 : 5.0),
                    child: Wrap(
                      spacing: 5,
                      children: [
                        if (settings.get('language') != "br")
                          Tooltip(
                            message: 'Português - Brasil',
                            child: MaterialButton(
                                hoverColor: Colors.transparent,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                child: CachedNetworkImage(
                                  imageUrl:
                                      "https://raw.githubusercontent.com/hjnilsson/country-flags/master/png100px/br.png",
                                  height: Platform.isWindows ? 50 : 30,
                                ),
                                onPressed: () {
                                  setState(() {
                                    settings.put('language', 'br');
                                    regionalText = regionSelect();
                                    psnProfilesUpdateProgress =
                                        regionalText['home']['updating'];
                                    psnTrophyLeadersUpdateProgress =
                                        regionalText['home']['updating'];
                                    exophaseUpdateProgress =
                                        regionalText['home']['updating'];
                                    trueTrophiesUpdateProgress =
                                        regionalText['home']['updating'];
                                    psn100UpdateProgress =
                                        regionalText['home']['updating'];
                                  });
                                }),
                          ),
                        if (settings.get('language') != "us")
                          Tooltip(
                            message: "English - United States of America",
                            child: MaterialButton(
                                hoverColor: Colors.transparent,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                child: CachedNetworkImage(
                                  imageUrl:
                                      "https://raw.githubusercontent.com/hjnilsson/country-flags/master/png100px/us.png",
                                  height: Platform.isWindows ? 50 : 30,
                                ),
                                onPressed: () {
                                  setState(() {
                                    settings.put('language', 'us');
                                    regionalText = regionSelect();
                                    psnProfilesUpdateProgress =
                                        regionalText['home']['updating'];
                                    psnTrophyLeadersUpdateProgress =
                                        regionalText['home']['updating'];
                                    exophaseUpdateProgress =
                                        regionalText['home']['updating'];
                                    trueTrophiesUpdateProgress =
                                        regionalText['home']['updating'];
                                    psn100UpdateProgress =
                                        regionalText['home']['updating'];
                                  });
                                }),
                          ),
                      ],
                    ),
                  ),
                  //? Permite que o usuário selecione quais sites vão ser carregados na aba principal
                  //? Sites selecionados terão uma borda verde, sites desativados terão uma borda vermelha,
                  //? sites problemáticos terão uma borda amarela, quando ativa.
                  Padding(
                    padding: EdgeInsets.all(Platform.isWindows ? 10.0 : 5.0),
                    child: Center(
                      child: Text(
                        regionalText["settings"]["websitePicker"],
                        style: textSelection(theme: "textDark"),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: Platform.isWindows ? 10.0 : 5.0),
                    child: Wrap(
                      spacing: 3,
                      children: [
                        Tooltip(
                          message: 'PSN Profiles',
                          child: InkWell(
                              child: Container(
                                decoration: BoxDecoration(
                                  //? To paint the border, we check the value of the settings for this website is true.
                                  //? If it's false or null (never set), we will paint red.
                                  border: Border.all(
                                      color: settings.get('psnp') != false
                                          ? Colors.green
                                          : Colors.red,
                                      width: 5),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
                                ),
                                child: CachedNetworkImage(
                                    imageUrl:
                                        "https://psnprofiles.com/favicon.ico",
                                    width: Platform.isWindows ? 40 : 25,
                                    height: Platform.isWindows ? 40 : 25),
                              ),
                              onTap: () {
                                setState(() {
                                  if (settings.get('psnp') != false) {
                                    settings.put('psnp', false);
                                  } else {
                                    settings.put('psnp', true);
                                  }
                                });
                              }),
                        ),
                        Tooltip(
                          message: 'PSN Trophy Leaders',
                          child: InkWell(
                              child: Container(
                                decoration: BoxDecoration(
                                  //? To paint the border, we check the value of the settings for this website is true.
                                  //? If it's false or null (never set), we will paint red.
                                  border: Border.all(
                                      color: settings.get('psntl') != false
                                          ? Colors.green
                                          : Colors.red,
                                      width: 5),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
                                ),
                                child: Image.asset(img['psntl'],
                                    width: Platform.isWindows ? 40 : 25,
                                    height: Platform.isWindows ? 40 : 25),
                              ),
                              onTap: () {
                                setState(() {
                                  if (settings.get('psntl') != false) {
                                    settings.put('psntl', false);
                                  } else {
                                    settings.put('psntl', true);
                                  }
                                });
                              }),
                        ),
                        Tooltip(
                          message: 'Exophase',
                          child: InkWell(
                              child: Container(
                                decoration: BoxDecoration(
                                  //? To paint the border, we check the value of the settings for this website is true.
                                  //? If it's false or null (never set), we will paint red.
                                  border: Border.all(
                                      color: settings.get('exophase') != false
                                          ? Colors.green
                                          : Colors.red,
                                      width: 5),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
                                ),
                                child: CachedNetworkImage(
                                    imageUrl:
                                        "https://www.exophase.com/assets/dist/images/icon-exo-large-55px.2af9b014.png",
                                    width: Platform.isWindows ? 40 : 25,
                                    height: Platform.isWindows ? 40 : 25),
                              ),
                              onTap: () {
                                setState(() {
                                  if (settings.get('exophase') != false) {
                                    settings.put('exophase', false);
                                  } else {
                                    settings.put('exophase', true);
                                  }
                                });
                              }),
                        ),
                        Tooltip(
                          message: 'True Trophies',
                          child: InkWell(
                              child: Container(
                                decoration: BoxDecoration(
                                  //? To paint the border, we check the value of the settings for this website is true.
                                  //? If it's false or null (never set), we will paint red.
                                  border: Border.all(
                                      color:
                                          settings.get('trueTrophies') != false
                                              ? Colors.green
                                              : Colors.red,
                                      width: 5),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
                                ),
                                child: Image.asset(img['trueTrophies'],
                                    width: Platform.isWindows ? 40 : 25,
                                    height: Platform.isWindows ? 40 : 25),
                              ),
                              onTap: () {
                                setState(() {
                                  if (settings.get('trueTrophies') != false) {
                                    settings.put('trueTrophies', false);
                                  } else {
                                    settings.put('trueTrophies', true);
                                  }
                                });
                              }),
                        ),
                        Tooltip(
                          message: 'PSN100',
                          child: InkWell(
                              child: Container(
                                decoration: BoxDecoration(
                                  //? To paint the border, we check the value of the settings for this website is true.
                                  //? If it's false or null (never set), we will paint red.
                                  border: Border.all(
                                      color: settings.get('psn100') != false
                                          ? Colors.green
                                          : Colors.red,
                                      width: 5),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
                                ),
                                child: Image.asset(img['psn100'],
                                    width: Platform.isWindows ? 40 : 25,
                                    height: Platform.isWindows ? 40 : 25),
                              ),
                              onTap: () {
                                setState(() {
                                  if (settings.get('psn100') != false) {
                                    settings.put('psn100', false);
                                  } else {
                                    settings.put('psn100', true);
                                  }
                                });
                              }),
                        ),
                      ],
                    ),
                  ),
                  //? Permite que o usuário selecione estilo de carregamento o usuário quer visualizar no aplicativo
                  Padding(
                    padding: EdgeInsets.all(Platform.isWindows ? 10.0 : 5.0),
                    child: Center(
                      child: Text(
                        regionalText["settings"]["loadingPicker"],
                        style: textSelection(theme: "textDark"),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: Platform.isWindows ? 10.0 : 5.0),
                    child: Wrap(
                      spacing: 5,
                      children: [
                        if ((settings.get('loading') ?? "wave") != "wave")
                          InkWell(
                              child: Container(
                                  width: 50,
                                  height: 50,
                                  child: loadingSelector("wave", "dark")),
                              onTap: () {
                                setState(() {
                                  if (settings.get('loading') != "wave") {
                                    settings.put('loading', "wave");
                                  }
                                });
                              }),
                        if (settings.get('loading') != "foldingCube")
                          InkWell(
                              child: Container(
                                  width: 50,
                                  height: 50,
                                  child:
                                      loadingSelector("foldingCube", "dark")),
                              onTap: () {
                                setState(() {
                                  if (settings.get('loading') !=
                                      "foldingCube") {
                                    settings.put('loading', "foldingCube");
                                  }
                                });
                              }),
                        if (settings.get('loading') != "fadingGrid")
                          InkWell(
                              child: Container(
                                  width: 50,
                                  height: 50,
                                  child: loadingSelector("fadingGrid", "dark")),
                              onTap: () {
                                setState(() {
                                  if (settings.get('loading') != "fadingGrid") {
                                    settings.put('loading', "fadingGrid");
                                  }
                                });
                              }),
                        if (settings.get('loading') != "cubeGrid")
                          InkWell(
                              child: Container(
                                  width: 50,
                                  height: 50,
                                  child: loadingSelector("cubeGrid", "dark")),
                              onTap: () {
                                setState(() {
                                  if (settings.get('loading') != "cubeGrid") {
                                    settings.put('loading', "cubeGrid");
                                  }
                                });
                              }),
                        if (settings.get('loading') != "pouringHourglass")
                          InkWell(
                              child: Container(
                                  width: 50,
                                  height: 50,
                                  child: loadingSelector(
                                      "pouringHourglass", "dark")),
                              onTap: () {
                                setState(() {
                                  if (settings.get('loading') !=
                                      "pouringHourglass") {
                                    settings.put('loading', "pouringHourglass");
                                  }
                                });
                              }),
                      ],
                    ),
                  ),
                  //? Permite que o usuário troque o tema do aplicativo.
                  //? O usuário não verá a opção de trocar para o mesmo tema que estiver ativo
                  Padding(
                    padding: EdgeInsets.all(Platform.isWindows ? 10.0 : 5.0),
                    child: Center(
                      child: Text(
                        regionalText["settings"]["themePicker"],
                        style: textSelection(theme: "textDark"),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: Platform.isWindows ? 10.0 : 5.0),
                    child: Wrap(
                      spacing: 5,
                      runSpacing: 10,
                      children: [
                        if ((settings.get('theme') ?? "pink") != "pink")
                          Tooltip(
                            message: regionalText["settings"]["pink"],
                            child: InkWell(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: Platform.isWindows ? 25 : 15,
                                      height: Platform.isWindows ? 50 : 30,
                                      color: themeSelector["primary"]["pink"],
                                    ),
                                    Container(
                                      width: Platform.isWindows ? 25 : 15,
                                      height: Platform.isWindows ? 50 : 30,
                                      color: themeSelector["secondary"]["pink"],
                                    )
                                  ],
                                ),
                                onTap: () {
                                  setState(() {
                                    settings.put('theme', 'pink');
                                  });
                                }),
                          ),
                        if (settings.get('theme') != "orange")
                          Tooltip(
                            message: regionalText["settings"]["orange"],
                            child: InkWell(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: Platform.isWindows ? 25 : 15,
                                      height: Platform.isWindows ? 50 : 30,
                                      color: themeSelector["primary"]["orange"],
                                    ),
                                    Container(
                                      width: Platform.isWindows ? 25 : 15,
                                      height: Platform.isWindows ? 50 : 30,
                                      color: themeSelector["secondary"]
                                          ["orange"],
                                    )
                                  ],
                                ),
                                onTap: () {
                                  setState(() {
                                    settings.put('theme', 'orange');
                                  });
                                }),
                          ),
                        if (settings.get('theme') != "blue")
                          Tooltip(
                            message: regionalText["settings"]["blue"],
                            child: InkWell(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: Platform.isWindows ? 25 : 15,
                                      height: Platform.isWindows ? 50 : 30,
                                      color: themeSelector["primary"]["blue"],
                                    ),
                                    Container(
                                      width: Platform.isWindows ? 25 : 15,
                                      height: Platform.isWindows ? 50 : 30,
                                      color: themeSelector["secondary"]["blue"],
                                    )
                                  ],
                                ),
                                onTap: () {
                                  setState(() {
                                    settings.put('theme', 'blue');
                                  });
                                }),
                          ),
                        if (settings.get('theme') != "boredom")
                          Tooltip(
                            message: regionalText["settings"]["boredom"],
                            child: InkWell(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: Platform.isWindows ? 25 : 15,
                                      height: Platform.isWindows ? 50 : 30,
                                      color: themeSelector["primary"]
                                          ["boredom"],
                                    ),
                                    Container(
                                      width: Platform.isWindows ? 25 : 15,
                                      height: Platform.isWindows ? 50 : 30,
                                      color: themeSelector["secondary"]
                                          ["boredom"],
                                    )
                                  ],
                                ),
                                onTap: () {
                                  setState(() {
                                    settings.put('theme', 'boredom');
                                  });
                                }),
                          ),
                        if (settings.get('theme') != "black")
                          Tooltip(
                            message: regionalText["settings"]["black"],
                            child: InkWell(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: Platform.isWindows ? 25 : 15,
                                      height: Platform.isWindows ? 50 : 30,
                                      color: themeSelector["primary"]["black"],
                                    ),
                                    Container(
                                      width: Platform.isWindows ? 25 : 15,
                                      height: Platform.isWindows ? 50 : 30,
                                      color: themeSelector["secondary"]
                                          ["black"],
                                    )
                                  ],
                                ),
                                onTap: () {
                                  setState(() {
                                    settings.put('theme', 'black');
                                  });
                                }),
                          ),
                        if (settings.get('theme') != "white")
                          Tooltip(
                            message: regionalText["settings"]["white"],
                            child: InkWell(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: Platform.isWindows ? 25 : 15,
                                      height: Platform.isWindows ? 50 : 30,
                                      color: themeSelector["primary"]["white"],
                                    ),
                                    Container(
                                      width: Platform.isWindows ? 25 : 15,
                                      height: Platform.isWindows ? 50 : 30,
                                      color: themeSelector["secondary"]
                                          ["white"],
                                    )
                                  ],
                                ),
                                onTap: () {
                                  setState(() {
                                    settings.put('theme', 'white');
                                  });
                                }),
                          ),
                      ],
                    ),
                  ),
                  //? O usuário não verá a opção de trocar para o mesmo tema que estiver ativo
                  Padding(
                    padding: EdgeInsets.all(Platform.isWindows ? 10.0 : 5.0),
                    child: Center(
                      child: Text(
                        regionalText["settings"]["fontPicker"],
                        style: textSelection(theme: "textDark"),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: Platform.isWindows ? 10.0 : 5.0),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if ((settings.get('font') ?? "Oxygen") != "Oxygen")
                          Tooltip(
                            message: "Oxygen",
                            child: InkWell(
                                child: Text("AaBb",
                                    style: textSelection(
                                        theme: "textDark", family: "Oxygen")),
                                onTap: () {
                                  setState(() {
                                    settings.put('font', 'Oxygen');
                                  });
                                }),
                          ),
                        if (settings.get('font') != "Archivo")
                          Tooltip(
                            message: "Archivo",
                            child: InkWell(
                                child: Text("AaBb",
                                    style: textSelection(
                                        theme: "textDark", family: "Archivo")),
                                onTap: () {
                                  setState(() {
                                    settings.put('font', 'Archivo');
                                  });
                                }),
                          ),
                        if (settings.get('font') != "Arvo")
                          Tooltip(
                            message: "Arvo",
                            child: InkWell(
                                child: Text("AaBb",
                                    style: textSelection(
                                        theme: "textDark", family: "Arvo")),
                                onTap: () {
                                  setState(() {
                                    settings.put('font', 'Arvo');
                                  });
                                }),
                          ),
                        if (settings.get('font') != "Goldman")
                          Tooltip(
                            message: "Goldman",
                            child: InkWell(
                                child: Text("AaBb",
                                    style: textSelection(
                                        theme: "textDark", family: "Goldman")),
                                onTap: () {
                                  setState(() {
                                    settings.put('font', 'Goldman');
                                  });
                                }),
                          ),
                        if (settings.get('font') != "LibreBaskerville")
                          Tooltip(
                            message: "LibreBaskerville",
                            child: InkWell(
                                child: Text("AaBb",
                                    style: textSelection(
                                        theme: "textDark",
                                        family: "LibreBaskerville")),
                                onTap: () {
                                  setState(() {
                                    settings.put('font', 'LibreBaskerville');
                                  });
                                }),
                          ),
                        if (settings.get('font') != "LobsterTwo")
                          Tooltip(
                            message: "LobsterTwo",
                            child: InkWell(
                                child: Text("AaBb",
                                    style: textSelection(
                                        theme: "textDark",
                                        family: "LobsterTwo")),
                                onTap: () {
                                  setState(() {
                                    settings.put('font', 'LobsterTwo');
                                  });
                                }),
                          ),
                        if (settings.get('font') != "TurretRoad")
                          Tooltip(
                            message: "TurretRoad",
                            child: InkWell(
                                child: Text("AaBb",
                                    style: textSelection(
                                        theme: "textDark",
                                        family: "TurretRoad")),
                                onTap: () {
                                  setState(() {
                                    settings.put('font', 'TurretRoad');
                                  });
                                }),
                          ),
                      ],
                    ),
                  ),
                  if (settings.get("psnID") != null)
                    Padding(
                      padding: EdgeInsets.all(Platform.isWindows ? 10.0 : 5.0),
                      child: Center(
                        child: Text(
                          regionalText["settings"]["removePSN"],
                          style: textSelection(theme: "textDark"),
                        ),
                      ),
                    ),
                  //! This option allows the user to delete their PSN data off the application
                  if (settings.get("psnID") != null)
                    InkWell(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete,
                            color: themeSelector["primary"]
                                [settings.get("theme")],
                            size: 30,
                          ),
                          SizedBox(width: Platform.isWindows ? 10.0 : 5.0),
                          Text(
                            settings.get('psnID'),
                            style: textSelection(theme: "textDark"),
                          )
                        ],
                      ),
                      onTap: () {
                        settings.delete('psnpDump');
                        settings.delete('psntlDump');
                        settings.delete('exophaseDump');
                        settings.delete('exophaseGames');
                        settings.delete('trueTrophiesDump');
                        settings.delete('psn100Dump');
                        settings.delete('trophyPending');
                        settings.delete('trophyEarned');
                        settings.delete('updatedGames');
                        settings.delete('gameTrophyData');
                        settings.put('psnp', true);
                        settings.put('psntl', true);
                        settings.put('exophase', true);
                        settings.put('trueTrophies', true);
                        settings.put('psn100', true);
                        settings.put('trophyDataUpToDate', false);
                        setState(() {
                          settings.delete("psnID");
                          psnpDump = null;
                          psntlDump = null;
                          exophaseDump = null;
                          // exophaseGames = null;
                          trueTrophiesDump = null;
                          psn100Dump = null;
                        });
                      },
                    ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        body: Center(
          child: Container(
            decoration: backgroundDecoration(),
            width: MediaQuery.of(context).size.width,
            child: Column(
              //? Max main axis size to use the entire available soace left from the appBar and Safe Area.
              mainAxisSize: MainAxisSize.max,
              //? Using spaceBetween as alignment so i can have the Translation / Discord buttons and
              //?version to always display on the bottom. An empty SizedBox is created at the start of the
              //? widget's list to space out properly
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(),
                //? This is the stuff that shows up when you haven't set a PSN ID.
                if (settings.get("psnID") == null)
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            //? If user doesn't have a set PSN ID, display the fields for them to input one.
                            Text(regionalText['home']['inputTitle'],
                                style: textSelection(theme: "textDarkBold")),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.5,
                              child: TextFormField(
                                  decoration: InputDecoration(
                                      hintText: regionalText['home']
                                          ['inputText'],
                                      hintStyle:
                                          textSelection(theme: "textDark")),
                                  textAlign: TextAlign.center,
                                  autocorrect: false,
                                  autofocus: Platform.isWindows ? true : false,
                                  onChanged: (text) {
                                    debounce.run(() {
                                      setState(() {
                                        settings.put('psnID', text);
                                        updateProfiles();
                                      });
                                    });
                                  }),
                            ),
                            SizedBox(height: 30),
                            Text(
                              regionalText['home']['supportedWebsites'],
                              style: textSelection(theme: "textDarkBold"),
                            ),
                            //? Spaces for PSN Profiles and PSN Trophy Leaders
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Tooltip(
                                    message: "PSN Profiles",
                                    child: Container(
                                      height: 50,
                                      width: Platform.isWindows ? 200 : 150,
                                      decoration: boxDeco(),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  "https://psnprofiles.com/favicon.ico",
                                              height: 30,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Text(
                                              "PSN Profiles",
                                              style: textSelection(),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Tooltip(
                                    message: 'PSN Trophy Leaders',
                                    child: Container(
                                      height: 50,
                                      width: Platform.isWindows ? 200 : 150,
                                      decoration: boxDeco(),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(5.0),
                                              child: Image.asset(img['psntl'],
                                                  height: 30),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(5.0),
                                              child: Text(
                                                'PSN Trophy Leaders',
                                                style: textSelection(),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
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
                                  Tooltip(
                                    message: "True Trophies",
                                    child: Container(
                                      height: 50,
                                      width: Platform.isWindows ? 200 : 150,
                                      decoration: boxDeco(),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Image.asset(
                                                img['trueTrophies'],
                                                height: 32),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Text(
                                              "True Trophies",
                                              style: textSelection(),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Tooltip(
                                    message: "Exophase",
                                    child: Container(
                                      height: 50,
                                      width: Platform.isWindows ? 200 : 150,
                                      decoration: boxDeco(),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  "https://www.exophase.com/assets/zeal/_icons/favicon.ico",
                                              height: 30,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Text(
                                              "Exophase",
                                              style: textSelection(),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            //? Spaces for PSN100 and something, probably PsNine
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Tooltip(
                                    message: "PSN 100%",
                                    child: Container(
                                      height: 50,
                                      width: Platform.isWindows ? 200 : 150,
                                      decoration: boxDeco(),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Image.asset(
                                              img['psn100'],
                                              scale: 0.5,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Text(
                                              "PSN 100%",
                                              style: textSelection(),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  // SizedBox(
                                  //   width: 10,
                                  // ),
                                  // Tooltip(
                                  //   message: "Exophase",
                                  //   child: Container(
                                  //     height: 50,
                                  //     width: 220,
                                  //     decoration: boxDeco(),
                                  //     child: Row(
                                  //       mainAxisAlignment:
                                  //           MainAxisAlignment.spaceEvenly,
                                  //       children: [
                                  //         Padding(
                                  //           padding: const EdgeInsets.all(5.0),
                                  //           child: CachedNetworkImage(imageUrl:
                                  //             "https://www.exophase.com/assets/zeal/_icons/favicon.ico",
                                  //             scale: 0.5,
                                  //           ),
                                  //         ),
                                  //         Padding(
                                  //           padding: const EdgeInsets.all(5.0),
                                  //           child: Text(
                                  //             "Exophase",
                                  //             style: textSelection(),
                                  //           ),
                                  //         )
                                  //       ],
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                //? Cards are displayed when you set a PSN ID with success.
                //! Needs error handling for bad IDs.
                if (settings.get("psnID") != null)
                  Expanded(
                    child: ListView(
                      children: [
                        // //! PSN Profiles card display
                        if (settings.get("psnp") != false)
                          Column(
                            children: [
                              //? Website name
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: Platform.isWindows ? 10 : 3),
                                child: Container(
                                  child: Container(
                                    padding: EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                        color: themeSelector["primary"]
                                            [settings.get("theme")],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            width: Platform.isWindows ? 5 : 3,
                                            color: psnpDump != null &&
                                                    psnpDump['premium'] == true
                                                ? Colors.yellow
                                                : themeSelector["secondary"]
                                                    [settings.get("theme")])),
                                    child: Center(
                                      child: Text(
                                        "PSN Profiles" +
                                            (psnpDump != null &&
                                                    psnpDump['premium'] == true
                                                ? " (Premium)"
                                                : ""),
                                        style: textSelection(
                                            theme: "textLightBold"),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              FutureBuilder(
                                future: Future(() => psnpDump),
                                builder: (context, snapshot) {
                                  //? Display card info if all information is successfully fetched
                                  if (snapshot.data != null &&
                                      snapshot.data['update'] != true) {
                                    return Container(
                                      margin: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 5),
                                      padding: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 10),
                                      width: MediaQuery.of(context).size.width,
                                      decoration: boxDeco(
                                          '',
                                          snapshot.data['premium'] == true
                                              ? 'psnp'
                                              : null),
                                      child: Column(
                                        children: [
                                          //? Contains your basic information about profile name, PSN level,
                                          //? trophy count, avatar, country flag, etc
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              //? Avatar PSN Profiles
                                              CachedNetworkImage(
                                                placeholder: (context, url) =>
                                                    loadingSelector(),
                                                imageUrl: snapshot
                                                        .data['avatar'] ??
                                                    "https://i.psnprofiles.com/avatars/m/Gfba90ec21.png",
                                                height: Platform.isWindows
                                                    ? 60
                                                    : 50,
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
                                                        Tooltip(
                                                          message: snapshot
                                                                      .data[
                                                                  'about'] ??
                                                              snapshot.data[
                                                                  'psnID'],
                                                          child: Text(
                                                            snapshot
                                                                .data["psnID"],
                                                            style: textSelection(
                                                                theme:
                                                                    "textLightBold"),
                                                          ),
                                                        ),
                                                        SizedBox(width: 5),
                                                        //? Country flag
                                                        CachedNetworkImage(
                                                            imageUrl:
                                                                "https://raw.githubusercontent.com/hjnilsson/country-flags/master/png100px/${snapshot.data['country']}.png",
                                                            height: 20),
                                                      ]),
                                                  //? Level, level progress and level icon
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: levelType(
                                                        snapshot.data[
                                                                'platinum'] ??
                                                            0,
                                                        snapshot.data['gold'] ??
                                                            0,
                                                        snapshot.data[
                                                                'silver'] ??
                                                            0,
                                                        snapshot.data[
                                                                'bronze'] ??
                                                            0),
                                                  ),
                                                ],
                                              ),
                                              InkWell(
                                                child: Tooltip(
                                                  message: "PSN Profiles",
                                                  child: CachedNetworkImage(
                                                      imageUrl:
                                                          "https://psnprofiles.com/favicon.ico",
                                                      height: 25,
                                                      width: 25),
                                                ),
                                                onTap: () async {
                                                  String userProfile =
                                                      "https://psnprofiles.com/${snapshot.data['psnID']}";
                                                  if (await canLaunch(
                                                      userProfile)) {
                                                    await launch(userProfile);
                                                  }
                                                },
                                              ),
                                            ],
                                          ), //? This row contains the trophy icons and the quantity the user has acquired of them
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                trophyType('platinum',
                                                    quantity: snapshot
                                                            .data['platinum'] ??
                                                        0),
                                                SizedBox(
                                                    width: Platform.isWindows
                                                        ? 20
                                                        : 5),
                                                trophyType('gold',
                                                    quantity:
                                                        snapshot.data['gold'] ??
                                                            0),
                                                SizedBox(
                                                    width: Platform.isWindows
                                                        ? 20
                                                        : 5),
                                                trophyType('silver',
                                                    quantity: snapshot
                                                            .data['silver'] ??
                                                        0),
                                                SizedBox(
                                                    width: Platform.isWindows
                                                        ? 20
                                                        : 5),
                                                trophyType('bronze',
                                                    quantity: snapshot
                                                            .data['bronze'] ??
                                                        0),
                                                SizedBox(
                                                    width: Platform.isWindows
                                                        ? 20
                                                        : 5),
                                                trophyType('total',
                                                    quantity:
                                                        "${snapshot.data['total'].toString()} (${snapshot.data['totalPercentage']}%)"),
                                              ],
                                            ),
                                          ),
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                rarityType(
                                                    type: 'rarity6',
                                                    quantity: snapshot
                                                        .data['ultraRare']
                                                        .toString()),
                                                SizedBox(
                                                    width: Platform.isWindows
                                                        ? 10
                                                        : 5),
                                                rarityType(
                                                    type: 'rarity4',
                                                    quantity: snapshot
                                                        .data['veryRare']
                                                        .toString()),
                                                SizedBox(
                                                    width: Platform.isWindows
                                                        ? 10
                                                        : 5),
                                                rarityType(
                                                    type: 'rarity4',
                                                    quantity: snapshot
                                                        .data['rare']
                                                        .toString()),
                                                SizedBox(
                                                    width: Platform.isWindows
                                                        ? 10
                                                        : 5),
                                                rarityType(
                                                    type: 'rarity3',
                                                    quantity: snapshot
                                                        .data['uncommon']
                                                        .toString()),
                                                SizedBox(
                                                    width: Platform.isWindows
                                                        ? 10
                                                        : 5),
                                                rarityType(
                                                    type: 'rarity1',
                                                    quantity: snapshot
                                                        .data['common']
                                                        .toString())
                                              ],
                                            ),
                                          ),
                                          Divider(
                                            color: themeSelector['secondary']
                                                [settings.get('theme')],
                                            thickness: 3,
                                          ),
                                          //? Bottom row without avatar, has information about games played,
                                          //? completion, unearned trophies, country/world rankings, etc
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["games"]}\n${snapshot.data['games'].toString()}",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["complete"]}\n${(snapshot.data['complete'] ?? 0).toString()} (${(snapshot.data['completePercentage'] ?? 0).toString()}%)",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal:
                                                          Platform.isWindows ==
                                                                  true
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["incomplete"]}\n${(snapshot.data['incomplete'] ?? snapshot.data['games']).toString()} (${(snapshot.data['incompletePercentage'] ?? 100)}%)",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["completion"]}\n${snapshot.data['completion']}",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["unearned"]}\n${snapshot.data['unearned'].toString()} (${snapshot.data['unearnedPercentage']}%)",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["countryRank"]}\n${snapshot.data['countryRank'] != null ? snapshot.data['countryRank'].toString() + " " : "❌"}${snapshot.data['countryUp'] ?? ""}",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["worldRank"]}\n${snapshot.data['worldRank'] != null ? snapshot.data['worldRank'].toString() + " " : "❌"}${snapshot.data['worldUp'] ?? ""}",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  } //? Display error screen if fails to fetch information
                                  else if (snapshot.data == null) {
                                    return Container(
                                      margin: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 5),
                                      padding: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 10),
                                      width: MediaQuery.of(context).size.width,
                                      decoration: boxDeco(),
                                      child: Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.error,
                                              color: themeSelector["secondary"]
                                                  [settings.get("theme")],
                                              size: 30,
                                            ),
                                            SizedBox(
                                                width: Platform.isWindows
                                                    ? 10.0
                                                    : 5.0),
                                            Text(
                                              "PSN Profiles",
                                              style: textSelection(
                                                  theme: "textLightBold"),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  } //? Display loading circle while Future is being processed
                                  else {
                                    return Container(
                                      margin: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 5),
                                      padding: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 10),
                                      width: MediaQuery.of(context).size.width,
                                      decoration: boxDeco(),
                                      child: Center(
                                        child: Column(
                                          children: [
                                            Text(psnProfilesUpdateProgress,
                                                style: textSelection()),
                                            loadingSelector(),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        // ! PSN Trophy Leaders card display
                        if (settings.get("psntl") != false)
                          Column(
                            children: [
                              //? Website name
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    // vertical: Platform.isWindows ? 10 : 3,
                                    horizontal: Platform.isWindows ? 10 : 3),
                                child: Container(
                                  // width: MediaQuery.of(context).size.width -
                                  //     (Platform.isWindows ? 30 : 5),
                                  child: Container(
                                    padding: EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                        color: themeSelector["primary"]
                                            [settings.get("theme")],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            width: Platform.isWindows ? 5 : 3,
                                            color: psntlDump != null &&
                                                    psntlDump['premium'] == true
                                                ? Colors.blue
                                                : themeSelector["secondary"]
                                                    [settings.get("theme")])),
                                    child: Center(
                                      child: Text(
                                        "PSN Trophy Leaders" +
                                            (psntlDump != null &&
                                                    psntlDump['premium'] == true
                                                ? " (Platinum)"
                                                : ""),
                                        style: textSelection(
                                            theme: "textLightBold"),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              FutureBuilder(
                                future: Future(() => psntlDump),
                                builder: (context, snapshot) {
                                  //? Display card info if all information is successfully fetched
                                  if (snapshot.data != null &&
                                      snapshot.data['update'] != true) {
                                    return Container(
                                      margin: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 5),
                                      padding: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 10),
                                      width: MediaQuery.of(context).size.width,
                                      decoration: boxDeco(
                                          '',
                                          snapshot.data['premium'] == true
                                              ? 'psntl'
                                              : null),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          //? Contains your basic information about profile name, PSN level,
                                          //? trophy count, avatar, country flag, etc
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              //? Avatar PSN Trophy Leaders
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  //? PSNTL avatar
                                                  CachedNetworkImage(
                                                    placeholder:
                                                        (context, url) =>
                                                            loadingSelector(),
                                                    imageUrl: snapshot
                                                            .data['avatar'] ??
                                                        "https://i.psnprofiles.com/avatars/m/Gfba90ec21.png",
                                                    height: Platform.isWindows
                                                        ? 60
                                                        : 50,
                                                  ),
                                                  //? PSNTL Mimic feature
                                                  Tooltip(
                                                    message:
                                                        regionalText['home']
                                                            ['mimic'],
                                                    child: Text(
                                                      "+" +
                                                          snapshot.data[
                                                                  "sameAvatar"]
                                                              .toString(),
                                                      style: textSelection(
                                                          theme:
                                                              "textLightBold"),
                                                    ),
                                                  )
                                                ],
                                              ),
                                              //? Column with PSN ID, trophy count
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
                                                        Text(
                                                          snapshot
                                                              .data["psnID"],
                                                          style: textSelection(
                                                              theme:
                                                                  "textLightBold"),
                                                        ),
                                                        SizedBox(width: 5),
                                                        //? Country flag
                                                        CachedNetworkImage(
                                                            imageUrl:
                                                                "https://raw.githubusercontent.com/hjnilsson/country-flags/master/png100px/${snapshot.data['country']}.png",
                                                            height: 20),
                                                      ]),
                                                  //? Level, level progress and level icon
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: levelType(
                                                        snapshot.data[
                                                                'platinum'] ??
                                                            0,
                                                        snapshot.data['gold'] ??
                                                            0,
                                                        snapshot.data[
                                                                'silver'] ??
                                                            0,
                                                        snapshot.data[
                                                                'bronze'] ??
                                                            0),
                                                  ),
                                                  //? This row contains the trophy icons and the quantity the user has acquired of them
                                                ],
                                              ),
                                              InkWell(
                                                child: Tooltip(
                                                  message: 'PSN Trophy Leaders',
                                                  child: Image.asset(
                                                      img['psntl'],
                                                      height: 30),
                                                ),
                                                onTap: () async {
                                                  String userProfile =
                                                      "https://psntrophyleaders.com/user/view/${snapshot.data['psnID']}";
                                                  if (await canLaunch(
                                                      userProfile)) {
                                                    await launch(userProfile);
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              trophyType('platinum',
                                                  quantity: snapshot
                                                          .data['platinum'] ??
                                                      0),
                                              SizedBox(
                                                  width: Platform.isWindows
                                                      ? 20
                                                      : 5),
                                              trophyType('gold',
                                                  quantity:
                                                      snapshot.data['gold'] ??
                                                          0),
                                              SizedBox(
                                                  width: Platform.isWindows
                                                      ? 20
                                                      : 5),
                                              trophyType('silver',
                                                  quantity:
                                                      snapshot.data['silver'] ??
                                                          0),
                                              SizedBox(
                                                  width: Platform.isWindows
                                                      ? 20
                                                      : 5),
                                              trophyType('bronze',
                                                  quantity:
                                                      snapshot.data['bronze'] ??
                                                          0),
                                              SizedBox(
                                                  width: Platform.isWindows
                                                      ? 20
                                                      : 5),
                                              trophyType('total',
                                                  quantity:
                                                      "${snapshot.data['total'].toString()}"),
                                            ],
                                          ),
                                          Divider(
                                            color: themeSelector['secondary']
                                                [settings.get('theme')],
                                            height: 20,
                                            thickness: 3,
                                          ),
                                          //? Bottom row without avatar, has information about games played,
                                          //? completion, unearned trophies, country/world rankings, etc
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["games"]}\n${snapshot.data['games'].toString()}",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["completion"]}\n${snapshot.data['completion']}",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["standard"]}\n${snapshot.data['standard'].toString()} ${snapshot.data['standardChange']}",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["adjusted"]}\n${snapshot.data['adjusted'].toString()} ${snapshot.data['adjustedChange']}",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["completist"]}\n${snapshot.data['completist'].toString()} ${snapshot.data['completistChange']}",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["rarity"]}\n${snapshot.data['rarity'].toString()} ${snapshot.data['rarityChange']}",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  } //? Display error screen if fails to fetch information
                                  else if (snapshot.data == null) {
                                    return Container(
                                      margin: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 5),
                                      padding: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 10),
                                      width: MediaQuery.of(context).size.width,
                                      //! Height undefined until all items are added to avoid overflow error.
                                      // height: 220,
                                      decoration: boxDeco(),
                                      child: Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.error,
                                              color: themeSelector["secondary"]
                                                  [settings.get("theme")],
                                              size: 30,
                                            ),
                                            SizedBox(
                                                width: Platform.isWindows
                                                    ? 10.0
                                                    : 5.0),
                                            Text(
                                              'PSN Trophy Leaders',
                                              style: textSelection(
                                                  theme: "textLightBold"),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  //? Display loading circle while Future is being processed
                                  else {
                                    return Container(
                                      margin: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 5),
                                      padding: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 10),
                                      width: MediaQuery.of(context).size.width,
                                      //! Height undefined until all items are added to avoid overflow error.
                                      // height: 220,
                                      decoration: boxDeco(),
                                      child: Center(
                                        child: Column(
                                          children: [
                                            Text(psnTrophyLeadersUpdateProgress,
                                                style: textSelection()),
                                            loadingSelector(),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        //! Exophase card display
                        if (settings.get("exophase") != false)
                          Column(
                            children: [
                              //? Website name
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    // vertical: Platform.isWindows ? 10 : 3,
                                    horizontal: Platform.isWindows ? 10 : 3),
                                child: Container(
                                  // width: MediaQuery.of(context).size.width -
                                  //     (Platform.isWindows ? 30 : 5),
                                  child: Container(
                                    padding: EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                        color: themeSelector["primary"]
                                            [settings.get("theme")],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            width: Platform.isWindows ? 5 : 3,
                                            color: exophaseDump != null &&
                                                    exophaseDump['premium'] ==
                                                        true
                                                ? Colors.yellow
                                                : themeSelector["secondary"]
                                                    [settings.get("theme")])),
                                    child: Center(
                                      child: Text(
                                        "Exophase" +
                                            (exophaseDump != null &&
                                                    exophaseDump['premium'] ==
                                                        true
                                                ? " (Premium)"
                                                : ""),
                                        style: textSelection(
                                            theme: "textLightBold"),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              FutureBuilder(
                                future: Future(() => exophaseDump),
                                builder: (context, snapshot) {
                                  //? Display card info if all information is successfully fetched
                                  if (snapshot.data != null &&
                                      snapshot.data['update'] != true &&
                                      exophaseUpdateProgress ==
                                          regionalText['home']['updating']) {
                                    return Container(
                                      margin: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 5),
                                      padding: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 10),
                                      width: MediaQuery.of(context).size.width,
                                      //! Height undefined until all items are added to avoid overflow error.
                                      // height: 220,
                                      decoration: boxDeco(
                                          '',
                                          snapshot.data['premium'] == true
                                              ? 'psnp'
                                              : null),
                                      child: InkWell(
                                        onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    ExophaseProfile())),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            //? Contains your basic information about profile name, PSN level,
                                            //? trophy count, avatar, country flag, etc
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                //? Avatar Exophase
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    CachedNetworkImage(
                                                      placeholder:
                                                          (context, url) =>
                                                              loadingSelector(),
                                                      imageUrl: snapshot
                                                              .data['avatar'] ??
                                                          "https://i.psnprofiles.com/avatars/m/Gfba90ec21.png",
                                                      height: Platform.isWindows
                                                          ? 60
                                                          : 50,
                                                    )
                                                  ],
                                                ),
                                                //? Column with PSN ID, trophy count
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
                                                          Text(
                                                            snapshot
                                                                .data["psnID"],
                                                            style: textSelection(
                                                                theme:
                                                                    "textLightBold"),
                                                          ),
                                                          SizedBox(width: 5),
                                                          //? Country flag
                                                          CachedNetworkImage(
                                                              imageUrl:
                                                                  "https://raw.githubusercontent.com/hjnilsson/country-flags/master/png100px/${snapshot.data['country']}.png",
                                                              height: 20),
                                                        ]),
                                                    //? Level, level progress and level icon
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5.0),
                                                      child: levelType(
                                                          snapshot.data[
                                                                  'platinum'] ??
                                                              0,
                                                          snapshot.data[
                                                                  'gold'] ??
                                                              0,
                                                          snapshot.data[
                                                                  'silver'] ??
                                                              0,
                                                          snapshot.data[
                                                                  'bronze'] ??
                                                              0),
                                                    ),
                                                  ],
                                                ),
                                                InkWell(
                                                  child: Tooltip(
                                                    message: "Exophase",
                                                    child: CachedNetworkImage(
                                                      imageUrl:
                                                          "https://www.exophase.com/assets/zeal/_icons/favicon.ico",
                                                      height: 30,
                                                    ),
                                                  ),
                                                  onTap: () async {
                                                    String userProfile =
                                                        "https://www.exophase.com/psn/user/${snapshot.data['psnID']}/";
                                                    if (await canLaunch(
                                                        userProfile)) {
                                                      await launch(userProfile);
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                            //? This row contains the trophy icons and the quantity the user has acquired of them
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                trophyType('platinum',
                                                    quantity: snapshot
                                                            .data['platinum'] ??
                                                        0),
                                                SizedBox(
                                                    width: Platform.isWindows
                                                        ? 20
                                                        : 5),
                                                trophyType('gold',
                                                    quantity:
                                                        snapshot.data['gold'] ??
                                                            0),
                                                SizedBox(
                                                    width: Platform.isWindows
                                                        ? 20
                                                        : 5),
                                                trophyType('silver',
                                                    quantity: snapshot
                                                            .data['silver'] ??
                                                        0),
                                                SizedBox(
                                                    width: Platform.isWindows
                                                        ? 20
                                                        : 5),
                                                trophyType('bronze',
                                                    quantity: snapshot
                                                            .data['bronze'] ??
                                                        0),
                                                SizedBox(
                                                    width: Platform.isWindows
                                                        ? 20
                                                        : 5),
                                                trophyType('total',
                                                    quantity:
                                                        "${snapshot.data['total'].toString()}"),
                                              ],
                                            ),
                                            SizedBox(height: 5),
                                            Divider(
                                                color:
                                                    themeSelector['secondary']
                                                        [settings.get('theme')],
                                                thickness: 3),
                                            //? Bottom row without avatar, has information about games played,
                                            //? completion, gameplay hours, country/world rankings, etc
                                            SingleChildScrollView(
                                              padding: EdgeInsets.all(0),
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 0,
                                                            horizontal: Platform
                                                                    .isWindows
                                                                ? 10.0
                                                                : 5.0),
                                                    child: Text(
                                                      "${regionalText["home"]["games"]}\n${snapshot.data['games'].toString()}",
                                                      style: textSelection(),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 0,
                                                            horizontal: Platform
                                                                    .isWindows
                                                                ? 10.0
                                                                : 5.0),
                                                    child: Text(
                                                      "${regionalText["home"]["complete"]}\n${(snapshot.data['complete'] ?? 0).toString()} (${(snapshot.data['completePercentage'] ?? 0).toString()}%)",
                                                      style: textSelection(),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 0,
                                                            horizontal: Platform
                                                                    .isWindows
                                                                ? 10.0
                                                                : 5.0),
                                                    child: Text(
                                                      "${regionalText["home"]["incomplete"]}\n${(snapshot.data['incomplete'] ?? snapshot.data['games']).toString()} (${(snapshot.data['incompletePercentage'] ?? 100).toString()}%)",
                                                      style: textSelection(),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 0,
                                                            horizontal: Platform
                                                                    .isWindows
                                                                ? 10.0
                                                                : 5.0),
                                                    child: Text(
                                                      "${regionalText["home"]["completion"]}\n${snapshot.data['completion']}",
                                                      style: textSelection(),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                  if (snapshot.data['hours'] !=
                                                      null)
                                                    Tooltip(
                                                      message: "PS4/PS5",
                                                      child: Padding(
                                                        padding: EdgeInsets.symmetric(
                                                            vertical: 0,
                                                            horizontal: Platform
                                                                    .isWindows
                                                                ? 10.0
                                                                : 5.0),
                                                        child: Text(
                                                          "${regionalText["home"]["hours"]}\n${snapshot.data['hours']}",
                                                          style:
                                                              textSelection(),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 0,
                                                            horizontal: Platform
                                                                    .isWindows
                                                                ? 10.0
                                                                : 5.0),
                                                    child: Text(
                                                      "${regionalText["home"]["exp"]}\n${snapshot.data['exp']}",
                                                      style: textSelection(),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 0,
                                                            horizontal: Platform
                                                                    .isWindows
                                                                ? 10.0
                                                                : 5.0),
                                                    child: Text(
                                                      "${regionalText["home"]["countryRank"]}\n${snapshot.data['countryRank'] != null ? snapshot.data['countryRank'].toString() + " " : "❌"}${snapshot.data['countryUp'] ?? ""}",
                                                      style: textSelection(),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 0,
                                                            horizontal: Platform
                                                                    .isWindows
                                                                ? 10.0
                                                                : 5.0),
                                                    child: Text(
                                                      "${regionalText["home"]["worldRank"]}\n${snapshot.data['worldRank'] != null ? snapshot.data['worldRank'].toString() + " " : "❌"}${snapshot.data['worldUp'] ?? ""}",
                                                      style: textSelection(),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  } //? Display error screen if fails to fetch information
                                  else if (snapshot.data == null) {
                                    return Container(
                                      margin: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 5),
                                      padding: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 10),
                                      width: MediaQuery.of(context).size.width,
                                      //! Height undefined until all items are added to avoid overflow error.
                                      // height: 220,
                                      decoration: boxDeco(),
                                      child: Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.error,
                                              color: themeSelector["secondary"]
                                                  [settings.get("theme")],
                                              size: 30,
                                            ),
                                            SizedBox(
                                                width: Platform.isWindows
                                                    ? 10.0
                                                    : 5.0),
                                            Text(
                                              "Exophase",
                                              style: textSelection(
                                                  theme: "textLightBold"),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  } //? Display loading circle while Future is being processed
                                  else {
                                    return Container(
                                      margin: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 5),
                                      padding: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 10),
                                      width: MediaQuery.of(context).size.width,
                                      //! Height undefined until all items are added to avoid overflow error.
                                      // height: 220,
                                      decoration: boxDeco(),
                                      child: Center(
                                        child: Column(
                                          children: [
                                            Text(exophaseUpdateProgress,
                                                style: textSelection()),
                                            loadingSelector(),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        //! True Trophies card display
                        if (settings.get("trueTrophies") != false)
                          Column(
                            children: [
                              //? Website name
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    // vertical: Platform.isWindows ? 10 : 3,
                                    horizontal: Platform.isWindows ? 10 : 3),
                                child: Container(
                                  // width: MediaQuery.of(context).size.width -
                                  //     (Platform.isWindows ? 30 : 5),
                                  child: Container(
                                    padding: EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                        color: themeSelector["primary"]
                                            [settings.get("theme")],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            width: Platform.isWindows ? 5 : 3,
                                            color: trueTrophiesDump != null &&
                                                    trueTrophiesDump[
                                                            'premium'] ==
                                                        true
                                                ? Colors.black
                                                : themeSelector["secondary"]
                                                    [settings.get("theme")])),
                                    child: Center(
                                      child: Text(
                                        "True Trophies" +
                                            (trueTrophiesDump != null &&
                                                    trueTrophiesDump[
                                                            'premium'] ==
                                                        true
                                                ? " (PRO)"
                                                : ""),
                                        style: textSelection(
                                            theme: "textLightBold"),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              FutureBuilder(
                                future: Future(() => trueTrophiesDump),
                                builder: (context, snapshot) {
                                  //? Display card info if all information is successfully fetched
                                  if (snapshot.data != null &&
                                      snapshot.data['update'] != true) {
                                    return Container(
                                      margin: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 5),
                                      padding: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 10),
                                      width: MediaQuery.of(context).size.width,
                                      //! Height undefined until all items are added to avoid overflow error.
                                      // height: 220,
                                      decoration: boxDeco(
                                          '',
                                          snapshot.data['premium'] == true
                                              ? 'trueTrophies'
                                              : null),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          //? Contains your basic information about profile name, PSN level,
                                          //? trophy count, avatar, country flag, etc
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              //? Avatar True Trophies
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  CachedNetworkImage(
                                                    placeholder:
                                                        (context, url) =>
                                                            loadingSelector(),
                                                    imageUrl: snapshot
                                                            .data['avatar'] ??
                                                        "https://i.psnprofiles.com/avatars/m/Gfba90ec21.png",
                                                    height: Platform.isWindows
                                                        ? 60
                                                        : 50,
                                                  )
                                                ],
                                              ),
                                              //? Column with PSN ID, trophy count
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  //? Country flag and PSN ID
                                                  Row(
                                                      key: UniqueKey(),
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          snapshot
                                                              .data["psnID"],
                                                          style: textSelection(
                                                              theme:
                                                                  "textLightBold"),
                                                        ),
                                                        if (snapshot.data[
                                                                'country'] !=
                                                            null)
                                                          SizedBox(width: 5),
                                                        //? Country flag
                                                        if (snapshot.data[
                                                                'country'] !=
                                                            null)
                                                          CachedNetworkImage(
                                                              imageUrl: snapshot
                                                                      .data[
                                                                  'country'],
                                                              height: 20),
                                                      ]),
                                                  //? Level, level progress and level icon
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: levelType(
                                                        snapshot.data[
                                                                'platinum'] ??
                                                            0,
                                                        snapshot.data['gold'] ??
                                                            0,
                                                        snapshot.data[
                                                                'silver'] ??
                                                            0,
                                                        snapshot.data[
                                                                'bronze'] ??
                                                            0),
                                                  ),
                                                ],
                                              ),
                                              InkWell(
                                                child: Tooltip(
                                                  message: "True Trophies",
                                                  child: Image.asset(
                                                      img['trueTrophies'],
                                                      height: 30),
                                                ),
                                                onTap: () async {
                                                  String userProfile =
                                                      "https://www.truetrophies.com/gamer/${snapshot.data['psnID']}";
                                                  if (await canLaunch(
                                                      userProfile)) {
                                                    await launch(userProfile);
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          //? This row contains the trophy icons and the quantity the user has acquired of them
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              trophyType('platinum',
                                                  quantity: snapshot
                                                          .data['platinum'] ??
                                                      0),
                                              SizedBox(
                                                  width: Platform.isWindows
                                                      ? 20
                                                      : 5),
                                              trophyType('gold',
                                                  quantity:
                                                      snapshot.data['gold'] ??
                                                          0),
                                              SizedBox(
                                                  width: Platform.isWindows
                                                      ? 20
                                                      : 5),
                                              trophyType('silver',
                                                  quantity:
                                                      snapshot.data['silver'] ??
                                                          0),
                                              SizedBox(
                                                  width: Platform.isWindows
                                                      ? 20
                                                      : 5),
                                              trophyType('bronze',
                                                  quantity:
                                                      snapshot.data['bronze'] ??
                                                          0),
                                              SizedBox(
                                                  width: Platform.isWindows
                                                      ? 20
                                                      : 5),
                                              trophyType('total',
                                                  quantity:
                                                      "${snapshot.data['total'].toString()}"),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Tooltip(
                                                message: "TrueScore",
                                                child: Row(children: [
                                                  CachedNetworkImage(
                                                      imageUrl:
                                                          "https://www.truetrophies.com/images/badges/tt-emblem-mono.png",
                                                      color: themeSelector[
                                                              "secondary"][
                                                          settings
                                                              .get("theme")],
                                                      height: 20),
                                                  SizedBox(width: 5),
                                                  Text(
                                                      snapshot.data['trueScore']
                                                          .toString(),
                                                      style: textSelection())
                                                ]),
                                              ),
                                              SizedBox(
                                                  width: Platform.isWindows
                                                      ? 20
                                                      : 5),
                                              Tooltip(
                                                message: "TrueLevel",
                                                child: Row(children: [
                                                  Icon(Icons.star,
                                                      color: themeSelector[
                                                              "secondary"][
                                                          settings
                                                              .get("theme")],
                                                      size: 20),
                                                  SizedBox(width: 5),
                                                  Text(
                                                      snapshot.data[
                                                              'trueTrophyLevel']
                                                          .toString(),
                                                      style: textSelection())
                                                ]),
                                              ),
                                              SizedBox(
                                                  width: Platform.isWindows
                                                      ? 20
                                                      : 5),
                                              Tooltip(
                                                message: "TrueRatio",
                                                child: Row(children: [
                                                  Icon(Icons.donut_large,
                                                      color: themeSelector[
                                                              "secondary"][
                                                          settings
                                                              .get("theme")],
                                                      size: 20),
                                                  SizedBox(width: 5),
                                                  Text(
                                                      snapshot.data['ratio']
                                                          .toString(),
                                                      style: textSelection())
                                                ]),
                                              ),
                                            ],
                                          ),
                                          Divider(
                                            color: themeSelector['secondary']
                                                [settings.get('theme')],
                                            height: 20,
                                            thickness: 3,
                                          ),
                                          //? Bottom row without avatar, has information about games played,
                                          //? completion, gameplay hours, country/world rankings, etc
                                          SingleChildScrollView(
                                            padding: EdgeInsets.all(0),
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              key: UniqueKey(),
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["games"]}\n${snapshot.data['games'].toString()}",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["complete"]}\n${(snapshot.data['complete'] ?? 0).toString()} (${(snapshot.data['completePercentage'] ?? 0).toString()}%)",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["incomplete"]}\n${(snapshot.data['incomplete'] ?? snapshot.data['games']).toString()} (${(snapshot.data['incompletePercentage'] ?? 100).toString()}%)",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["completion"]}\n${snapshot.data['completion'].toString()}%\n(+${snapshot.data['completionIncrease']} ➡️ ${snapshot.data['nextCompletion'] ?? snapshot.data['completion'].ceil().toString() + "%"})",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  } //? Display error screen if fails to fetch information
                                  else if (snapshot.data == null) {
                                    return Container(
                                      margin: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 5),
                                      padding: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 10),
                                      width: MediaQuery.of(context).size.width,
                                      //! Height undefined until all items are added to avoid overflow error.
                                      // height: 220,
                                      decoration: boxDeco(),
                                      child: Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.error,
                                              color: themeSelector["secondary"]
                                                  [settings.get("theme")],
                                              size: 30,
                                            ),
                                            SizedBox(
                                                width: Platform.isWindows
                                                    ? 10.0
                                                    : 5.0),
                                            Text(
                                              "True Trophies",
                                              style: textSelection(
                                                  theme: "textLightBold"),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  } //? Display loading circle while Future is being processed
                                  else {
                                    return Container(
                                      margin: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 5),
                                      padding: EdgeInsets.all(
                                          Platform.isWindows ? 15 : 10),
                                      width: MediaQuery.of(context).size.width,
                                      decoration: boxDeco(),
                                      child: Center(
                                        child: Column(
                                          children: [
                                            Text(trueTrophiesUpdateProgress,
                                                style: textSelection()),
                                            loadingSelector(),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        //! PSN 100% card display
                        if (settings.get("psn100") != false)
                          Column(
                            children: [
                              //? Website name
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    // vertical: Platform.isWindows ? 10 : 3,
                                    horizontal: Platform.isWindows ? 10 : 3),
                                child: Container(
                                  // width: MediaQuery.of(context).size.width -
                                  //     (Platform.isWindows ? 30 : 5),
                                  child: Container(
                                    padding: EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                        color: themeSelector["primary"]
                                            [settings.get("theme")],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            width: Platform.isWindows ? 5 : 3,
                                            color: themeSelector["secondary"]
                                                [settings.get("theme")])),
                                    child: Center(
                                      child: Text(
                                        "PSN 100",
                                        style: textSelection(
                                            theme: "textLightBold"),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                margin:
                                    EdgeInsets.all(Platform.isWindows ? 15 : 5),
                                padding: EdgeInsets.all(
                                    Platform.isWindows ? 15 : 10),
                                width: MediaQuery.of(context).size.width,
                                //! Height undefined until all items are added to avoid overflow error.
                                // height: 220,
                                decoration: boxDeco(),
                                child: FutureBuilder(
                                  future: Future(() => psn100Dump),
                                  builder: (context, snapshot) {
                                    //? Display card info if all information is successfully fetched
                                    if (snapshot.data != null &&
                                        snapshot.data['update'] != true) {
                                      return Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          //? Contains your basic information about profile name, PSN level,
                                          //? trophy count, avatar, country flag, etc
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              //? Avatar PSN Trophy Leaders
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  CachedNetworkImage(
                                                    placeholder:
                                                        (context, url) =>
                                                            loadingSelector(),
                                                    imageUrl: snapshot
                                                            .data['avatar'] ??
                                                        "https://i.psnprofiles.com/avatars/m/Gfba90ec21.png",
                                                    height: Platform.isWindows
                                                        ? 60
                                                        : 50,
                                                  )
                                                ],
                                              ),
                                              //? Column with PSN ID, trophy count
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
                                                        Text(
                                                          snapshot
                                                              .data["psnID"],
                                                          style: textSelection(
                                                              theme:
                                                                  "textLightBold"),
                                                        ),
                                                        SizedBox(width: 5),
                                                        //? Country flag
                                                        CachedNetworkImage(
                                                            imageUrl:
                                                                "https://raw.githubusercontent.com/hjnilsson/country-flags/master/png100px/${snapshot.data['country']}.png",
                                                            height: 20),
                                                      ]),
                                                  //? Level, level progress and level icon
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: levelType(
                                                        snapshot.data[
                                                                'platinum'] ??
                                                            0,
                                                        snapshot.data['gold'] ??
                                                            0,
                                                        snapshot.data[
                                                                'silver'] ??
                                                            0,
                                                        snapshot.data[
                                                                'bronze'] ??
                                                            0),
                                                  ),
                                                ],
                                              ),
                                              InkWell(
                                                child: Tooltip(
                                                  message: "PSN 100%",
                                                  child: Image.asset(
                                                    img['psn100'],
                                                    height: 35,
                                                  ),
                                                ),
                                                onTap: () async {
                                                  String userProfile =
                                                      "https://www.psn100.net/player/${snapshot.data['psnID']}";
                                                  if (await canLaunch(
                                                      userProfile)) {
                                                    await launch(userProfile);
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          //? This row contains the trophy icons and the quantity the user has acquired of them
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                trophyType('platinum',
                                                    quantity: snapshot
                                                            .data['platinum'] ??
                                                        0),
                                                SizedBox(
                                                    width: Platform.isWindows
                                                        ? 20
                                                        : 5),
                                                trophyType('gold',
                                                    quantity:
                                                        snapshot.data['gold'] ??
                                                            0),
                                                SizedBox(
                                                    width: Platform.isWindows
                                                        ? 20
                                                        : 5),
                                                trophyType('silver',
                                                    quantity: snapshot
                                                            .data['silver'] ??
                                                        0),
                                                SizedBox(
                                                    width: Platform.isWindows
                                                        ? 20
                                                        : 5),
                                                trophyType('bronze',
                                                    quantity: snapshot
                                                            .data['bronze'] ??
                                                        0),
                                                SizedBox(
                                                    width: Platform.isWindows
                                                        ? 20
                                                        : 5),
                                                trophyType('total',
                                                    quantity:
                                                        "${snapshot.data['total'].toString()} (${snapshot.data['totalPercentage']}%)"),
                                              ],
                                            ),
                                          ),
                                          Divider(
                                              color: themeSelector['secondary']
                                                  [settings.get('theme')],
                                              height: 20,
                                              thickness: 3),
                                          //? Bottom row without avatar, has information about games played,
                                          //? completion, gameplay hours, country/world rankings, etc
                                          SingleChildScrollView(
                                            padding: EdgeInsets.all(0),
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["games"]}\n${snapshot.data['games'].toString()}",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["complete"]}\n${(snapshot.data['complete'] ?? 0).toString()} (${(snapshot.data['completePercentage'] ?? 0).toString()}%)",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["incomplete"]}\n${(snapshot.data['incomplete'] ?? snapshot.data['games']).toString()} (${(snapshot.data['incompletePercentage'] ?? 100).toString()}%)",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["completion"]}\n${snapshot.data['completion']}",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["unearned"]}\n${snapshot.data['unearned']}",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["worldRank"]}\n${snapshot.data['worldRank'] != null ? snapshot.data['worldRank'].toString() + " " : "❌"}${snapshot.data['worldUp'] ?? ""}",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["rarity"]}\n${snapshot.data['worldRarity'] != null ? snapshot.data['worldRarity'].toString() + " " : "❌"}${snapshot.data['worldUp'] ?? ""}",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["countryRank"]}\n${snapshot.data['countryRank'] != null ? snapshot.data['countryRank'].toString() + " " : "❌"}${snapshot.data['countryUp'] ?? ""}",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal:
                                                          Platform.isWindows
                                                              ? 10.0
                                                              : 5.0),
                                                  child: Text(
                                                    "${regionalText["home"]["countryRarity"]}\n${snapshot.data['countryRarity'] != null ? snapshot.data['countryRarity'].toString() + " " : "❌"}${snapshot.data['countryUp'] ?? ""}",
                                                    style: textSelection(),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      );
                                    } //? Display error screen if fails to fetch information
                                    else if (snapshot.data == null) {
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
                                            SizedBox(
                                                width: Platform.isWindows
                                                    ? 10.0
                                                    : 5.0),
                                            Text(
                                              "PSN 100%",
                                              style: textSelection(
                                                  theme: "textLightBold"),
                                            )
                                          ],
                                        ),
                                      );
                                    } //? Display loading circle while Future is being processed
                                    else {
                                      return Center(
                                        child: Column(
                                          children: [
                                            Text(psn100UpdateProgress,
                                                style: textSelection()),
                                            loadingSelector(),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        if (settings.get("psnp") == false &&
                            settings.get("psntl") == false &&
                            settings.get("exophase") == false &&
                            settings.get("trueTrophies") == false &&
                            settings.get("psn100") == false)
                          Container(
                            width: MediaQuery.of(context).size.width,
                            margin: EdgeInsets.all(Platform.isWindows ? 15 : 5),
                            padding:
                                EdgeInsets.all(Platform.isWindows ? 15 : 10),
                            child: Center(
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.error,
                                        size: 70,
                                        color: themeSelector['secondary']
                                            [settings.get('theme')]),
                                    SizedBox(width: 10),
                                    Container(
                                      width: MediaQuery.of(context).size.width -
                                          150,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            regionalText["home"]["errorPSN"],
                                            style: textSelection(),
                                            softWrap: true,
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: 10),
                                          Builder(
                                            builder: (context) => InkWell(
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(7)),
                                                child: Container(
                                                  color: themeSelector[
                                                          'secondary']
                                                      [settings.get('theme')],
                                                  padding: EdgeInsets.all(5),
                                                  child: Text(
                                                      regionalText["home"]
                                                          ["settings"],
                                                      style: textSelection(
                                                          theme: 'textDark')),
                                                ),
                                              ),
                                              onTap: () {
                                                Scaffold.of(context)
                                                    .openEndDrawer();
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ]),
                            ),
                            decoration: boxDeco(),
                          )
                      ],
                    ),
                  ),
                //? This is the bottom row with the buttons for Translation/Discord/Version/Privacy
                Container(
                  padding: EdgeInsets.symmetric(
                      vertical: Platform.isWindows ? 5 : 3),
                  width: MediaQuery.of(context).size.width,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          SizedBox(height: Platform.isWindows ? 30 : 25),
                          //? Translation button
                          InkWell(
                            highlightColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://raw.githubusercontent.com/hjnilsson/country-flags/master/png100px/${settings.get('language')}.png",
                                  height: 15,
                                  // width: 22.5,
                                ),
                                SizedBox(width: 5),
                                Text(regionalText['home']['translation'],
                                    style: textSelection(theme: "textDark")),
                              ],
                            ),
                            onTap: () => showDialog(
                              context: context,
                              builder: (context) => Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: themeSelector["secondary"]
                                          [settings.get("theme")],
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(25))),
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AppBar(
                                          toolbarHeight: 40,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      top:
                                                          Radius.circular(25))),
                                          title: Text(
                                            regionalText["home"]["translation"],
                                            style: textSelection(),
                                          ),
                                          centerTitle: true,
                                          automaticallyImplyLeading: false,
                                          backgroundColor:
                                              themeSelector["primary"]
                                                  [settings.get("theme")],
                                          actions: [
                                            IconButton(
                                                splashColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                icon: Icon(
                                                  Icons.close,
                                                  color: themeSelector[
                                                          "secondary"]
                                                      [settings.get("theme")],
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                })
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            children: [
                                              Text(
                                                regionalText["bottomButtons"]
                                                    ["translationText"],
                                                style: textSelection(
                                                    theme: "textDark"),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(
                                                height: 20,
                                              ),
                                              MaterialButton(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(7),
                                                ),
                                                child: Text(
                                                  regionalText["bottomButtons"]
                                                      ["translationButton"],
                                                  style: textSelection(),
                                                ),
                                                color: themeSelector["primary"]
                                                    [settings.get("theme")],
                                                onPressed: () async {
                                                  final String spreadsheetLink =
                                                      "https://docs.google.com/spreadsheets/d/1Ul3bgFmimL_kZ33A1Onzq8bWswIePYFaLnbHCfaI_U4/edit?usp=sharing";
                                                  if (await canLaunch(
                                                      spreadsheetLink)) {
                                                    launch(spreadsheetLink);
                                                  }
                                                },
                                              )
                                            ],
                                          ),
                                        )
                                      ]),
                                ),
                              ),
                            ),
                          ),
                          //? Discord button
                          InkWell(
                            highlightColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CachedNetworkImage(
                                    imageUrl:
                                        "https://discord.com/assets/2c21aeda16de354ba5334551a883b481.png",
                                    height: 22),
                                Text("Discord",
                                    style: textSelection(theme: "textDark")),
                              ],
                            ),
                            onTap: () async {
                              String discordURL = "https://discord.gg/j55v7pD";
                              if (await canLaunch(discordURL)) {
                                await launch(discordURL);
                              }
                            },
                          ),
                          //? Version button
                          InkWell(
                            highlightColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info,
                                    size: 22,
                                    color: themeSelector["primary"]
                                        [settings.get("theme")]),
                                SizedBox(width: 5),
                                Text(
                                    "${regionalText['home']['version']} ${regionalText['version']['version']}",
                                    style: textSelection(theme: "textDark")),
                              ],
                            ),
                            onTap: () => showDialog(
                                context: context,
                                builder: (context) {
                                  //? The function that will fetch the latest GitHub update will be declared here
                                  //? to be used on the FutureBuilder() below
                                  Future<Map<String, dynamic>>
                                      yuraUpdate() async {
                                    Map<String, dynamic> update = {};
                                    if (await ws.loadFullURL(
                                        "https://github.com/TheYuriG/Yura/releases")) {
                                      try {
                                        ws
                                            .getElementTitle(
                                                'body > div.application-main > div > main > div.container-xl.clearfix.new-discussion-timeline.px-3.px-md-4.px-lg-5 > div > div.position-relative.border-top.clearfix > div:nth-child(1) > div > div.col-12.col-md-9.col-lg-10.px-md-3.py-md-4.release-main-section.commit.open.float-left > div.release-header > div > div > a')
                                            .forEach((element) {
                                          if (element.contains('v')) {
                                            update['lastVersion'] =
                                                element.split(' ')[1].trim();
                                          }
                                        });
                                        if (update['lastVersion'] == null) {
                                          throw Error;
                                        }
                                        //? Gets the 'datetime' attribute, converts it to UNIX
                                        //? then use that to retrieve the timestamp of the update
                                        //? I have not yet found a way to translate this to locale
                                        //! No easy way to do dd/mm/yyyy for the right countries and mm/dd/yyyy for the rest
                                        //! This was working before and now it isn't. I don't know why
                                        ws.getElement(
                                            'div:nth-child(1) > div > div > div.release-header > p > relative-time',
                                            ['datetime']).forEach((element) {
                                          try {
                                            initializeDateFormatting(
                                                    Platform.localeName)
                                                .then((_) {
                                              update['when'] = DateFormat.Hm(
                                                      Platform.localeName)
                                                  .add_yMMMMEEEEd()
                                                  .format(DateTime.parse(
                                                      element['attributes']
                                                          ['datetime']));
                                            });
                                          } catch (e) {
                                            update['when'] = element['title'];
                                          }
                                        });
                                        ws
                                            .getElementAttribute(
                                                'body > div.application-main > div > main > div.container-xl.clearfix.new-discussion-timeline.px-3.px-md-4.px-lg-5 > div > div.position-relative.border-top.clearfix > div:nth-child(1) > div > div.col-12.col-md-9.col-lg-10.px-md-3.py-md-4.release-main-section.commit.open.float-left > details > div > div > div.d-flex.flex-justify-between.flex-items-center.py-1.py-md-2.Box-body.px-2 > a',
                                                'href')
                                            .forEach((element) {
                                          if (element.contains('.rar')) {
                                            update['updateLinkDesktop'] =
                                                "https://github.com" +
                                                    element.trim();
                                            update['updateLinkAndroid'] =
                                                "https://github.com" +
                                                    element
                                                        .trim()
                                                        .split("download/")[0];
                                          }
                                        });
                                        ws
                                            .getElementTitle(
                                                'body > div.application-main > div > main > div.container-xl.clearfix.new-discussion-timeline.px-3.px-md-4.px-lg-5 > div > div.position-relative.border-top.clearfix > div:nth-child(1) > div > div.col-12.col-md-9.col-lg-10.px-md-3.py-md-4.release-main-section.commit.open.float-left > div.markdown-body > ul > li')
                                            .forEach((element) {
                                          if (update['updateNotes'] == null) {
                                            update['updateNotes'] =
                                                "\n⦿ " + element.trim();
                                          } else {
                                            update['updateNotes'] +=
                                                ("\n\n⦿ " + element.trim());
                                          }
                                        });
                                      } catch (e) {
                                        print(update);
                                        update['lastVersion'] = 'error';
                                        update['updateNotes'] = 'error';
                                      }
                                    }
                                    // print(update);
                                    return update;
                                  }

                                  return StatefulBuilder(builder:
                                      (BuildContext context, setState) {
                                    return Center(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(25)),
                                        child: Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.7,
                                          decoration: BoxDecoration(
                                            color: themeSelector["secondary"]
                                                [settings.get("theme")],
                                          ),
                                          child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                AppBar(
                                                  toolbarHeight: 40,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.vertical(
                                                              top: Radius
                                                                  .circular(
                                                                      25))),
                                                  title: Text(
                                                    "Yura ${regionalText['home']['version']} ${regionalText['version']['version']}",
                                                    style: textSelection(),
                                                  ),
                                                  centerTitle: true,
                                                  automaticallyImplyLeading:
                                                      false,
                                                  backgroundColor:
                                                      themeSelector["primary"][
                                                          settings
                                                              .get("theme")],
                                                  actions: [
                                                    IconButton(
                                                        splashColor:
                                                            Colors.transparent,
                                                        hoverColor:
                                                            Colors.transparent,
                                                        icon: Icon(
                                                          Icons.close,
                                                          color: themeSelector[
                                                                  "secondary"][
                                                              settings.get(
                                                                  "theme")],
                                                        ),
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                        })
                                                  ],
                                                ),
                                                ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    maxHeight:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.7,
                                                  ),
                                                  child: SingleChildScrollView(
                                                    scrollDirection:
                                                        Axis.vertical,
                                                    child: FutureBuilder(
                                                        future: yuraUpdate(),
                                                        builder: (context,
                                                            snapshot) {
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(15),
                                                            child: Column(
                                                              children: [
                                                                if (snapshot
                                                                        .connectionState ==
                                                                    ConnectionState
                                                                        .waiting)
                                                                  loadingSelector(
                                                                      settings.get(
                                                                          'loading'),
                                                                      "dark"),
                                                                if (snapshot.connectionState ==
                                                                        ConnectionState
                                                                            .done &&
                                                                    snapshot.data[
                                                                            'updateNotes'] !=
                                                                        "error")
                                                                  Text(
                                                                    //? This will fetch information from the website. If it works, display the latest version.
                                                                    //? If it doesn't, display a cross mark. While it's loading, should have a "..." text.
                                                                    '${regionalText["bottomButtons"]["latestversion"]} ${snapshot.data['lastVersion']} (${snapshot.data['when']})',
                                                                    style: textSelection(
                                                                        theme:
                                                                            "textDark"),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                  ),
                                                                if (snapshot.connectionState ==
                                                                        ConnectionState
                                                                            .done &&
                                                                    snapshot.data[
                                                                            'updateNotes'] !=
                                                                        "error")
                                                                  SizedBox(
                                                                      height:
                                                                          5),
                                                                if (snapshot.connectionState ==
                                                                        ConnectionState
                                                                            .done &&
                                                                    snapshot.data[
                                                                            'updateNotes'] !=
                                                                        "error")
                                                                  Text(
                                                                    snapshot.data[
                                                                        'updateNotes'],
                                                                    style: textSelection(
                                                                        theme:
                                                                            "textDark"),
                                                                  ),
                                                                SizedBox(
                                                                    height: 10),
                                                                if (snapshot.connectionState ==
                                                                        ConnectionState
                                                                            .done &&
                                                                    snapshot.data[
                                                                            'updateNotes'] !=
                                                                        "error")
                                                                  Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      MaterialButton(
                                                                        shape:
                                                                            RoundedRectangleBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(7),
                                                                        ),
                                                                        child:
                                                                            Text(
                                                                          "Trello",
                                                                          style:
                                                                              textSelection(theme: ""),
                                                                        ),
                                                                        color: themeSelector["primary"]
                                                                            [
                                                                            settings.get("theme")],
                                                                        onPressed:
                                                                            () async {
                                                                          final String
                                                                              updateLink =
                                                                              "https://trello.com/b/EK0M1sl8/yuras-development-board";
                                                                          if (await canLaunch(
                                                                              updateLink)) {
                                                                            launch(updateLink);
                                                                          }
                                                                        },
                                                                      ),
                                                                      if (snapshot.data[
                                                                              'lastVersion'] !=
                                                                          regionalText["version"]
                                                                              [
                                                                              "version"])
                                                                        Padding(
                                                                          padding:
                                                                              const EdgeInsets.only(left: 5),
                                                                          child:
                                                                              MaterialButton(
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(7),
                                                                            ),
                                                                            child:
                                                                                Text(
                                                                              regionalText["bottomButtons"]["update"],
                                                                              style: textSelection(),
                                                                            ),
                                                                            color:
                                                                                themeSelector["primary"][settings.get("theme")],
                                                                            onPressed:
                                                                                () async {
                                                                              final String updateLink = Platform.isWindows ? snapshot.data['updateLinkDesktop'] : snapshot.data['updateLinkAndroid'];
                                                                              if (await canLaunch(updateLink)) {
                                                                                launch(updateLink);
                                                                              }
                                                                            },
                                                                          ),
                                                                        ),
                                                                    ],
                                                                  ),
                                                              ],
                                                            ),
                                                          );
                                                        }),
                                                  ),
                                                )
                                              ]),
                                        ),
                                      ),
                                    );
                                  });
                                }),
                          ),
                          //? Privacy button
                          InkWell(
                            enableFeedback: false,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.remove_red_eye,
                                    size: 22,
                                    color: themeSelector["primary"]
                                        [settings.get("theme")]),
                                SizedBox(width: 5),
                                Text(regionalText['home']['privacy'],
                                    style: textSelection(theme: "textDark")),
                              ],
                            ),
                            onTap: () => showDialog(
                              context: context,
                              builder: (context) => Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: themeSelector["secondary"]
                                          [settings.get("theme")],
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(25))),
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AppBar(
                                          toolbarHeight: 40,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      top:
                                                          Radius.circular(25))),
                                          title: Text(
                                            regionalText["home"]["privacy"],
                                            style: textSelection(),
                                          ),
                                          centerTitle: true,
                                          automaticallyImplyLeading: false,
                                          backgroundColor:
                                              themeSelector["primary"]
                                                  [settings.get("theme")],
                                          actions: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 10),
                                              child: InkWell(
                                                  enableFeedback: false,
                                                  splashColor:
                                                      Colors.transparent,
                                                  child: Icon(
                                                    Icons.close,
                                                    color: themeSelector[
                                                            "secondary"]
                                                        [settings.get("theme")],
                                                  ),
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                  }),
                                            )
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            children: [
                                              Text(
                                                regionalText["bottomButtons"]
                                                    ["privacyText"],
                                                style: textSelection(
                                                    theme: "textDark"),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        )
                                      ]),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        floatingActionButton: settings.get("psnID") == null ||
                isUpdating == true ||
                (settings.get('psnp') != true &&
                    settings.get('psntl') != true &&
                    settings.get('exophase') != true &&
                    settings.get('trueTrophies') != true &&
                    settings.get('psn100') != true)
            ? null
            : FloatingActionButton(
                onPressed: () {
                  settings.put('trophyDataUpToDate', false);
                  updateProfiles();
                },
                tooltip: regionalText["home"]["refresh"],
                child: Icon(
                  Icons.refresh,
                  color: themeSelector["secondary"][settings.get("theme")],
                ),
                backgroundColor: themeSelector["primary"]
                    [settings.get("theme")],
              ),
      ),
    );
  }
}
