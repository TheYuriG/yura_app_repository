import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
// ignore: unused_import
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:web_scraper/web_scraper.dart';

//! This project assumes you are using VS Code and have the Todo Tree extension installed.
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
final WebScraper exophase = WebScraper("https://www.exophase.com/");

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
      if (parsedData['psnID'] != user) {
        settings.put('psnID', parsedData['psnID']);
      }
    });
    if (parsedData['psnID'] == null) {
      throw Error;
    }
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
    parsedData = {};
    settings.put('psnp', false);
  }
  // print(parsedData);
  settings.put('psnpDump', parsedData);
  return parsedData;
}

//? This will make a request to PSN Trophy Leaders to retrieve a small clickable profile card
Future<Map> psntlInfo(String user) async {
  await psntl.loadWebPage('/user/view/$user');
  Map<String, dynamic> parsedData = {};
  try {
    //! Retrieves basic profile information, like avatar, about me, PSN ID, level, etc
    //? Retrieves PSN ID
    psntl.getElement('#id-handle', []).forEach((element) {
      parsedData['psnID'] = element['title'].trim();
      if (parsedData['psnID'] != user) {
        settings.put('psnID', parsedData['psnID']);
      }
    });
    if (parsedData['psnID'] == null) {
      throw Error;
    }
    //? Retrieves PSN country
    psntl.getElement(
        '#userPage > div.userRight > div.userHeader > table > tbody > tr > td.userInfo > h1 > span > img',
        ['src']).forEach((element) {
      parsedData['country'] = element['attributes']['src']
          .replaceAll("https://psntrophyleaders.com/images/countries/", "")
          .replaceAll("_small.png", "")
          .trim();
    });
    //? Retrieves PSN avatar
    psntl.getElement('#id-avatar > img.avatar-large', ['src']).forEach(
        (element) {
      parsedData['avatar'] = element['attributes']['src'];
    });
    //? Retrieves how many tracked players share the same avatar
    psntl.getElement('#avatarstat > span.white', []).forEach((element) {
      parsedData['sameAvatar'] = int.parse(element['title'].trim());
    });
    //? Retrieves PSN Level
    psntl.getElement('#leveltext > big', []).forEach((element) {
      parsedData['level'] = int.parse(element['title'].replaceAll(",", ""));
    });
    //? Retrieves PSN Level progress
    psntl.getElement(
        '#toprightstats > td > div > div > div.prog > div > div.progressbar',
        ['style']).forEach((element) {
      parsedData['levelProgress'] = element['attributes']['style']
          .replaceAll("width: ", "")
          .replaceAll(";", "")
          .trim();
    });
    //! Retrieves trophy data
    //? Retrieves Total trophies
    psntl.getElement('#toprightstats > td:nth-child(5) > big', []).forEach(
        (element) {
      parsedData['total'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves bronze trophies
    psntl.getElement('#ranksummary > table > tbody > tr > td.bronze > big',
        []).forEach((element) {
      parsedData['bronze'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves silver trophies
    psntl.getElement('#ranksummary > table > tbody > tr > td.silver > big',
        []).forEach((element) {
      parsedData['silver'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves gold trophies
    psntl.getElement('#ranksummary > table > tbody > tr > td.gold > big',
        []).forEach((element) {
      parsedData['gold'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves platinum trophies
    psntl.getElement('#ranksummary > table > tbody > tr > td.platinum > big',
        []).forEach((element) {
      parsedData['platinum'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //! Retrieves profile information data
    //? Retrieves total ganes
    psntl.getElement('#toprightstats > td:nth-child(3) > big', []).forEach(
        (element) {
      parsedData['games'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves completion
    psntl.getElement('#toprightstats > td:nth-child(9) > big > span',
        ['title']).forEach((element) {
      parsedData['completion'] = element['attributes']['title']
          .replaceAll(" average completion", "")
          .trim();
    });
    //! Retrieves ranking data
    //? Retrieves Standard rank
    psntl.getElement(
        '#ranksummary > table > tbody > tr:nth-child(12) > td:nth-child(1)',
        []).forEach((element) {
      parsedData['standard'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves Standard rank status change
    psntl.getElement(
        '#ranksummary > table > tbody > tr:nth-child(12) > td:nth-child(3)',
        []).forEach((element) {
      if (element['title'].contains("+")) {
        parsedData['standardChange'] = "⬆️";
      } else if (element['title'].contains("-")) {
        parsedData['standardChange'] = "⬇️";
      } else {
        parsedData['standardChange'] = "🟨";
      }
    });
    //? Retrieves Adjusted rank
    psntl.getElement(
        '#ranksummary > table > tbody > tr:nth-child(13) > td:nth-child(1)',
        []).forEach((element) {
      parsedData['adjusted'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves Adjusted rank status change
    psntl.getElement(
        '#ranksummary > table > tbody > tr:nth-child(13) > td:nth-child(3)',
        []).forEach((element) {
      if (element['title'].contains("+")) {
        parsedData['adjustedChange'] = "⬆️";
      } else if (element['title'].contains("-")) {
        parsedData['adjustedChange'] = "⬇️";
      } else {
        parsedData['adjustedChange'] = "🟨";
      }
    });
    //? Retrieves Completist rank
    psntl.getElement(
        '#ranksummary > table > tbody > tr:nth-child(14) > td:nth-child(1)',
        []).forEach((element) {
      parsedData['completist'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves Completist rank status change
    psntl.getElement(
        '#ranksummary > table > tbody > tr:nth-child(14) > td:nth-child(3)',
        []).forEach((element) {
      if (element['title'].contains("+")) {
        parsedData['completistChange'] = "⬆️";
      } else if (element['title'].contains("-")) {
        parsedData['completistChange'] = "⬇️";
      } else {
        parsedData['completistChange'] = "🟨";
      }
    });
    //? Retrieves Rarity rank
    psntl.getElement(
        '#ranksummary > table > tbody > tr:nth-child(15) > td:nth-child(1)',
        []).forEach((element) {
      parsedData['rarity'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves Rarity rank status change
    psntl.getElement(
        '#ranksummary > table > tbody > tr:nth-child(15) > td:nth-child(3)',
        []).forEach((element) {
      if (element['title'].contains("+")) {
        parsedData['rarityChange'] = "⬆️";
      } else if (element['title'].contains("-")) {
        parsedData['rarityChange'] = "⬇️";
      } else {
        parsedData['rarityChange'] = "🟨";
      }
    });
  } catch (e) {
    parsedData = {};
    settings.put('psntl', false);
  }
  // print(parsedData);
  settings.put('psntlDump', parsedData);
  return parsedData;
}

//? This will make a request to PSN Trophy Leaders to retrieve a small clickable profile card
Future<Map> exophaseInfo(String user) async {
  await exophase.loadWebPage('psn/user/$user/');
  Map<String, dynamic> parsedData = {};
  try {
    //! Retrieves basic profile information, like avatar, about me, PSN ID, level, etc
    //? Retrieves PSN ID
    exophase.getElement(
        '#sub-user-info > section > div.col.col-md-auto.column-username.me-lg-4.pb-3.pt-3 > h2',
        []).forEach((element) {
      parsedData['psnID'] = element['title'].trim();
      if (parsedData['psnID'] != user) {
        settings.put('psnID', parsedData['psnID']);
      }
    });
    if (parsedData['psnID'] == null) {
      throw Error;
    }
    //? Retrieves PSN country
    exophase.getElement(
        '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div:nth-child(1) > span > span.country-ranking.mb-1 > img',
        ['src']).forEach((element) {
      parsedData['country'] = element['attributes']['src']
          .replaceAll("https://www.exophase.com/assets/zeal/images/flags/", "")
          .replaceAll(".png", "")
          .trim();
    });
    //? Retrieves PSN avatar
    exophase.getElement(
        '#app > div > section > div > div.col-auto.profile-overflow-top.ps-md-3.pe-md-0.mx-auto.mt-3.mt-md-0 > div > img',
        ['src']).forEach((element) {
      parsedData['avatar'] = element['attributes']['src'];
    });
    //? Retrieves PSN Level
    exophase.getElement(
        '#sub-user-info > section > div.col-auto > div > div:nth-child(1) > span',
        []).forEach((element) {
      parsedData['level'] = int.parse(element['title'].replaceAll(",", ""));
    });
    //? Retrieves PSN Level progress
    exophase.getElement(
        '#sub-user-info > section > div.col-auto > div > div:nth-child(1) > div > div',
        ['style']).forEach((element) {
      parsedData['levelProgress'] = element['attributes']['style']
          .replaceAll("width: ", "")
          .replaceAll(";", "")
          .trim();
    });
    //? Retrieves completion
    exophase.getElement(
        '#sub-user-info > section > div.col-auto > div > div:nth-child(3) > span',
        []).forEach((element) {
      parsedData['completion'] =
          element['title'].replaceAll(" average completion", "").trim();
    });
    //? Retrieves world rank
    exophase.getElement(
        '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div:nth-child(1) > span > span.global-ranking.tippy.mb-1',
        []).forEach((element) {
      parsedData['worldRank'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves country rank
    exophase.getElement(
        '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div:nth-child(1) > span > span.country-ranking.mb-1',
        []).forEach((element) {
      parsedData['countryRank'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //! Retrieves trophy data
    //? Retrieves Total trophies
    exophase.getElement(
        '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div.col > span.tippy.total-value',
        []).forEach((element) {
      parsedData['total'] = int.parse(element['title']
          .replaceAll(",", "")
          .replaceAll("Trophies (", "")
          .replaceAll(")", "")
          .trim());
    });
    //? Retrieves bronze trophies
    exophase.getElement(
        '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div:nth-child(3) > span:nth-child(1)',
        []).forEach((element) {
      parsedData['bronze'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves silver trophies
    exophase.getElement(
        '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div:nth-child(3) > span:nth-child(3)',
        []).forEach((element) {
      parsedData['silver'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves gold trophies
    exophase.getElement(
        '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div:nth-child(5) > span:nth-child(1)',
        []).forEach((element) {
      parsedData['gold'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves platinum trophies
    exophase.getElement(
        '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div:nth-child(5) > span:nth-child(3)',
        []).forEach((element) {
      parsedData['platinum'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //! Retrieves Profile overall statistics
    //? Retrieves total ganes
    exophase.getElement(
        '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div.col > span:nth-child(5)',
        []).forEach((element) {
      parsedData['games'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves complete ganes
    exophase.getElement(
        '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div.col > span:nth-child(7)',
        []).forEach((element) {
      parsedData['complete'] =
          int.parse(element['title'].replaceAll(",", "").trim());
      parsedData['incomplete'] = parsedData['games'] - parsedData['complete'];
      parsedData['completePercentage'] =
          (parsedData['complete'] / parsedData['games'] * 100)
              .toStringAsFixed(3);
      parsedData['incompletePercentage'] =
          (parsedData['incomplete'] / parsedData['games'] * 100)
              .toStringAsFixed(3);
    });
    //? Retrieves tracked gameplay time
    exophase.getElement(
        '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div.col > span.tippy.playtime',
        []).forEach((element) {
      parsedData['hours'] = int.parse(
          element['title'].replaceAll(",", "").replaceAll(" hours", "").trim());
    });
    //? Retrieves earned EXP
    exophase.getElement(
        '#sub-user-info > section > div.col-auto > div > div.col.col-last.column-units > div > div.col > span:nth-child(9)',
        []).forEach((element) {
      parsedData['exp'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
  } catch (e) {
    parsedData = {};
    settings.put('exophase', false);
  }
  // print(parsedData);
  settings.put('exophaseDump', parsedData);
  return parsedData;
}

//? This will make a request to PSN Trophy Leaders to retrieve a small clickable profile card
Future<Map> trueTrophiesInfo(String user) async {
  await tt.loadWebPage('gamer/$user/');
  Map<String, dynamic> parsedData = {};
  try {
    //! Retrieves basic profile information, like avatar, about me, PSN ID, level, etc
    //? Retrieves PSN ID
    tt.getElement(
        '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > span > h1 > a',
        []).forEach((element) {
      parsedData['psnID'] = element['title'].trim();
      if (parsedData['psnID'] != user) {
        settings.put('psnID', parsedData['psnID']);
      }
    });

    if (parsedData['psnID'] == null) {
      throw Error;
    }
    //? Retrieves PSN country
    tt.getElement(
        '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > span > a > img',
        ['src']).forEach((element) {
      parsedData['country'] =
          "https://www.truetrophies.com/" + element['attributes']['src'].trim();
    });
    //? Retrieves PSN avatar
    tt.getElement(
        '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > img',
        ['src']).forEach((element) {
      parsedData['avatar'] =
          "https://www.truetrophies.com/" + element['attributes']['src'];
    });
    //? Retrieves PSN Level and TrueTrophy level
    tt.getElement(
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
    tt.getElement(
        '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > div.scores > a',
        []).forEach((element) {
      parsedData['total'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
    //? Retrieves bronze trophies
    tt.getElement(
        '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > div.stats > a:nth-child(3)',
        ['title']).forEach((element) {
      parsedData['bronze'] = int.parse(element['attributes']['title']
          .split(" ")[0]
          .replaceAll(",", "")
          .trim());
    });
    //? Retrieves silver trophies
    tt.getElement(
        '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > div.stats > a:nth-child(2)',
        ['title']).forEach((element) {
      parsedData['silver'] = int.parse(element['attributes']['title']
          .split(" ")[0]
          .replaceAll(",", "")
          .trim());
    });
    //? Retrieves gold trophies
    tt.getElement(
        '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > div.stats > a:nth-child(1)',
        ['title']).forEach((element) {
      parsedData['gold'] = int.parse(element['attributes']['title']
          .split(" ")[0]
          .replaceAll(",", "")
          .trim());
    });
    //? Retrieves platinum trophies
    tt.getElement(
        '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > div.stats > a:first-child',
        ['title']).forEach((element) {
      parsedData['platinum'] = int.parse(element['attributes']['title']
          .split(" ")[0]
          .replaceAll(",", "")
          .trim());
    });
    //! Retrieves Profile overall statistics
    //? Retrieves total ganes
    tt.getElement(
        '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > div.stats > a:nth-child(4)',
        ['title']).forEach((element) {
      parsedData['games'] = int.parse(element['attributes']['title']
          .split(" ")[0]
          .replaceAll(",", "")
          .trim());
    });
    //? Retrieves complete ganes
    tt.getElement(
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
    tt.getElement(
        '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > div.badges > div > div > a',
        ['title']).forEach((element) {
      if (element['attributes']['title'] != null &&
          element['attributes']['title'].contains("Ratio:")) {
        parsedData['ratio'] =
            double.parse(element['title'].replaceAll(",", "").trim());
      }
    });
    //? Retrieves completion and how many trophies to increase it
    tt.getElement(
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
      }
    });
    //? Retrieves World Rank
    tt.getElement(
        '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > div.badges > div > div > a',
        ['title']).forEach((element) {
      if (element['attributes']['title'] != null &&
          element['attributes']['title'].contains("Rank:")) {
        parsedData['worldRank'] =
            int.parse(element['title'].replaceAll(",", "").trim());
      }
    });
    //? Retrieves TrueScore
    tt.getElement(
        '#frm > div.page.tt.limit > div.main.middle > main > div.panel-header.t.gamer > div.scores > span:first-child',
        []).forEach((element) {
      parsedData['trueScore'] =
          int.parse(element['title'].replaceAll(",", "").trim());
    });
  } catch (e) {
    parsedData = {};
    settings.put('trueTrophies', false);
  }
  // print(parsedData);
  settings.put('trueTrophiesDump', parsedData);
  return parsedData;
}

//? This function contains all translated strings to be used.
//? If a language isn't fully supported, it will use the english words instead. TODO translation text waypoint
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
      "incomplete": "Incomplete\nGames:",
      "completion": "Completion:",
      "hours": "Tracked\nHours:",
      "exp": "Exp\nEarned:",
      "unearned": "Unearned\nTrophies:",
      "countryRank": "Country\nRank:",
      "worldRank": "World\nRank:",
      "mimic":
          "Number of PSN Trophy Leaders tracked profiles that also share this avatar",
      "standard": "Standard\nRank:",
      "adjusted": "Adjusted\nRank:",
      "completist": "Completist\nRank:",
      "rarity": "Rarity\nRank:",
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
      "websitePicker": "Choose which sites to enable/disable:",
      "loadingPicker": "Choose what loading icon do you want to use:",
      "themePicker": "Change Yura's theme:",
      'refresh': "Refresh trophy data",
      "pink": "Wednesday",
      "orange": "Nature's Will",
      "blue": "Deep Ocean",
      "black": "Before Dawn",
      "white": "Death by Contrast",
      "boredom": "Death by Boredom",
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
    'bottomButtons': {
      'translationText':
          "Do you understand any language that Yura doesn't have a translation for? If your translation could help even just one other person, it will be added.\n\nFeel free to use the support Discord server to let us know that you are sending a translation sheet.",
      "translationButton": "Contribute!",
      "latestversion": "Most recent release:",
      "update": "Update now!",
      "updateGif":
          "Accurate representation of the coding process for this app.",
      'privacyText':
          "There is no privacy agreement for you to accept. Yura takes none of your information, everything you see on screen is exclusively processed on your device and belongs to no one else other than you.\n\nThis might change in the future if some sort of leaderboard gets to be implemented, but you will be prompted if you wish to share before any of your PSN data gets sent. Until then, enjoy your total anonymity."
    },
    //? Since this is just the version number, this doesn't get translated regardless of chosen language.
    "version": {"version": "v0.6.1"}
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
      "incomplete": "Jogos\nPendentes:",
      "completion": "Conclusão:",
      "hours": "Horas\nRegistradas:",
      "exp": "Exp\nAcumulada:",
      "unearned": "Troféus\nPendentes:",
      "countryRank": "Rank\nNacional:",
      "worldRank": "Rank\nMundial:",
      "mimic":
          "Número de jogadores rastreados em PSN Trophy Leaders que também usam esse avatar",
      "standard": "Rank\nPadrão",
      "adjusted": "Rank\nAjustado",
      "completist": "Rank\nConclusão:",
      "rarity": "Rank\nRaridade:",
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
      "websitePicker": "Escolha quais sites ativar/desativar:",
      "loadingPicker": "Escolha qual ícone de carregamento deseja usar:",
      "themePicker": "Mude o tema de Yura:",
      'refresh': "Atualizar informação de troféus",
      "pink": "Quarta-Feira",
      "orange": "Desejo da Natureza",
      "blue": "Oceano Profundo",
      "black": "Antes do Amanhecer",
      "white": "Morte por Contraste",
      "boredom": "Morte por Tédio",
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
    avaiableText['bottomButtons'] = {
      'translationText':
          "Você entende algum idioma para o qual Yura ainda não tem uma tradução? Se a sua tradução puder ajudar pelo menos uma pessoa, ela será adicionada.\n\nSinta-se livre para usar o servidor suporte de Discord para nos informar que você está mandando uma planilha de traduções.",
      "translationButton": "Contribua!",
      "latestversion": "Atualização mais recente:",
      "update": "Atualize agora!",
      "updateGif":
          "Representação precisa do processo de programar esse aplicativo.",
      "privacyText":
          "Não existe um contrato de privacidade que você precisa aceitar. Yura não envia nada da sua informação, tudo o que você vê na tela é processado no seu aparelho e não pertence a ninguém além de você.\n\nIsso pode mudar no futuro caso algum tipo de placar de líderes seja implementado, mas você será perguntado antes que qualquer informação da PSN seja enviada. Até lá, aproveite sua total anonimidade."
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
    "white": Colors.white,
    "boredom": Colors.blue
  },
  "secondary": {
    "pink": Colors.pink[50],
    "black": Colors.indigo[100],
    "blue": Colors.blue[100],
    "orange": Colors.red[50],
    "white": Colors.grey,
    "boredom": Colors.white
  }
};

//? This will return what is the textStyle to be used.
//? It had to become a function because it was not properly updating on language change.
TextStyle textSelection(String theme) {
  if (theme == "textLightBold") {
    //? Option for light bold text
    return TextStyle(
        color: themeSelector["secondary"][settings.get("theme")],
        fontSize: 20,
        fontWeight: FontWeight.bold);
  } else if (theme == "textDark") {
    //? Option for dark thin text
    return TextStyle(
      color: themeSelector["primary"][settings.get("theme")],
      fontSize: 16,
    );
  } else if (theme == "textDarkBold") {
//? Option for dark bold text
    return TextStyle(
        color: themeSelector["primary"][settings.get("theme")],
        fontSize: 20,
        fontWeight: FontWeight.bold);
  } else {
    //? Option for light thin text
    return TextStyle(
      color: themeSelector["secondary"][settings.get("theme")],
      fontSize: 16,
    );
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

//? This function will return a loading selector, you just need to provide the theme
Widget loadingSelector([String loader, String color = "light"]) {
  if (loader == null) {
    loader = settings.get('loading');
  }
  Color pickedColor = themeSelector['secondary'][settings.get('theme')];
  if (color == "dark") {
    pickedColor = themeSelector['primary'][settings.get('theme')];
  }
  if (loader == "fadingCircle") {
    return SpinKitFadingCircle(
      itemBuilder: (BuildContext context, int index) {
        return DecoratedBox(
          decoration: BoxDecoration(color: pickedColor),
        );
      },
    );
  } else if (loader == "fadingFour") {
    return SpinKitFadingFour(
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
  // MyHomePage({Key key, this.title}) : super(key: key);
  // final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //? These are the bits of information, they are processed by each individual function if there is no error and
  //? then stored on the database on the user's device. This is done to save resources and not request every time
  //? the user performs an update to the UI.
  Map psnpDump = settings.get('psnpDump');
  Map psntlDump = settings.get('psntlDump');
  Map trueTrophiesDump = settings.get('trueTrophiesDump');
  Map exophaseDump = settings.get('exophaseDump');

//? This function will update every enabled profile in order
  void updateProfiles() async {
    //? First it changes the information on every document to be as updating, so every block displays a spinning icon
    setState(() {
      psnpDump = {'update': true};
      psntlDump = {'update': true};
      exophaseDump = {'update': true};
      trueTrophiesDump = {'update': true};
    });
    //? then, if it's enabled, it updates PSNP first while waiting the result to not start the other websites yet.
    if (settings.get("psnp")) {
      psnpDump = await psnpInfo(settings.get("psnID"));
      setState(() {
        psnpDump = settings.get("psnpDump");
      });
    }
    //? then, if it's enabled, it updates PSN Trophy Leaders and waits the result.
    if (settings.get("psntl")) {
      psntlDump = await psntlInfo(settings.get("psnID"));
      setState(() {
        psntlDump = settings.get("psntlDump");
      });
    }
    //? then, if it's enabled, it updates Exophase and waits the result.
    if (settings.get("exophase")) {
      exophaseDump = await exophaseInfo(settings.get("psnID"));
      setState(() {
        exophaseDump = settings.get("exophaseDump");
      });
    }
    //? then, if it's enabled, it updates True Trophies and waits the result.
    if (settings.get("trueTrophies")) {
      trueTrophiesDump = await trueTrophiesInfo(settings.get("psnID"));
      setState(() {
        trueTrophiesDump = settings.get("trueTrophiesDump");
      });
    }
  }

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
            style: textSelection(""),
          ),
          backgroundColor: themeSelector["primary"][settings.get("theme")],
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
                      color: themeSelector["secondary"][settings.get("theme")],
                    ),
                    onPressed: () => Scaffold.of(context).openEndDrawer()),
              ),
            )
          ],
        ),
        endDrawer: Center(
          child: Container(
            decoration: BoxDecoration(
                color: themeSelector["secondary"][settings.get("theme")],
                borderRadius: BorderRadius.all(Radius.circular(25))),
            width: MediaQuery.of(context).size.width * 0.5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(25))),
                  title: Text(
                    regionalText["home"]["settings"],
                    style: textSelection(""),
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
                //? Permite que o usuário troque o tipo de troféus do aplicativo.
                //? O usuário não verá a opção de trocar para o tipo de troféu que estiver ativo
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Center(
                    child: Text(
                      regionalText["settings"]["trophyPicker"],
                      style: textSelection("textDark"),
                    ),
                  ),
                ),
                Wrap(
                  children: [
                    //? Option to use Yura's trophies as default display
                    if (settings.get('trophyType') != "yura")
                      Tooltip(
                        message: regionalText["settings"]["yuraTrophies"],
                        child: InkWell(
                            child: Image.asset(
                              img['platFill'],
                              height: 50,
                              width: 75,
                            ),
                            onTap: () => {
                                  setState(() {
                                    settings.put('trophyType', 'yura');
                                  }),
                                }),
                      ),
                    //? Option to use old PSN trophies as default display
                    if (settings.get('trophyType') != "old")
                      Tooltip(
                        message: regionalText["settings"]["oldTrophies"],
                        child: InkWell(
                            child: Image.asset(
                              img['oldPlatinum'],
                              height: 50,
                              width: 75,
                            ),
                            onTap: () => {
                                  setState(() {
                                    settings.put('trophyType', 'old');
                                  }),
                                }),
                      ),
                    //? Option to use new PSN trophies as default display
                    if (settings.get('trophyType') != "new")
                      Tooltip(
                        message: regionalText["settings"]["newTrophies"],
                        child: InkWell(
                            child: Image.asset(
                              img['newPlatinum'],
                              height: 50,
                              width: 75,
                            ),
                            onTap: () => {
                                  setState(() {
                                    settings.put('trophyType', 'new');
                                  }),
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
                      regionalText["settings"]["languagePicker"],
                      style: textSelection("textDark"),
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
                                MaterialTapTargetSize.shrinkWrap,
                            child: Image.network(
                              "https://raw.githubusercontent.com/hjnilsson/country-flags/master/png100px/br.png",
                              height: 50,
                              width: 75,
                            ),
                            onPressed: () {
                              setState(() {
                                settings.put('language', 'br');
                                regionalText = regionSelect();
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
                            child: Image.network(
                              "https://raw.githubusercontent.com/hjnilsson/country-flags/master/png100px/us.png",
                              height: 50,
                              width: 75,
                            ),
                            onPressed: () {
                              setState(() {
                                settings.put('language', 'us');
                                regionalText = regionSelect();
                              });
                            }),
                      ),
                  ],
                ),
                //? Permite que o usuário selecione quais sites vão ser carregados na aba principal
                //? Sites selecionados terão uma borda verde, sites desativados terão uma borda vermelha,
                //? sites problemáticos terão uma borda amarela, quando ativa.
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Center(
                    child: Text(
                      regionalText["settings"]["websitePicker"],
                      style: textSelection("textDark"),
                    ),
                  ),
                ),
                Wrap(
                  spacing: 5,
                  children: [
                    Tooltip(
                      message: 'PSNProfiles',
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
                            child: Image.network(
                              "https://psnprofiles.com/favicon.ico",
                              scale: 2,
                            ),
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
                      message: 'PSN Trophy Leaders (🐌)',
                      child: InkWell(
                          child: Container(
                            decoration: BoxDecoration(
                              //? To paint the border, we check the value of the settings for this website is true.
                              //? If it's false or null (never set), we will paint red.
                              border: Border.all(
                                  color: settings.get('psntl') != false
                                      ? Colors.orange
                                      : Colors.red,
                                  width: 5),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5)),
                            ),
                            child: Image.network(
                              "https://psntl.com/favicon.ico",
                              scale: 0.5,
                            ),
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
                            child: Image.network(
                              "https://www.exophase.com/assets/zeal/_icons/favicon.ico",
                              scale: 4,
                            ),
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
                                  color: settings.get('trueTrophies') != false
                                      ? Colors.green
                                      : Colors.red,
                                  width: 5),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5)),
                            ),
                            child: Image.network(
                              "https://truetrophies.com/favicon.ico",
                              scale: 0.5,
                            ),
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
                  ],
                ),
                //? Permite que o usuário selecione estilo de carregamento o usuário quer visualizar no aplicativo
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Center(
                    child: Text(
                      regionalText["settings"]["loadingPicker"],
                      style: textSelection("textDark"),
                    ),
                  ),
                ),
                Wrap(
                  spacing: 5,
                  children: [
                    InkWell(
                        child: Container(
                            padding: EdgeInsets.all(0),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              //? To paint the border, we check the value of the settings for this website is true.
                              //? If it's false or null (never set), we will paint red.
                              border: Border.all(
                                  color:
                                      settings.get('loading') == "fadingCircle"
                                          ? Colors.green
                                          : Colors.red,
                                  width: 5),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5)),
                            ),
                            child: loadingSelector("fadingCircle", "dark")),
                        onTap: () {
                          setState(() {
                            if (settings.get('loading') != "fadingCircle") {
                              settings.put('loading', "fadingCircle");
                            }
                          });
                        }),
                    InkWell(
                        child: Container(
                            padding: EdgeInsets.all(0),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              //? To paint the border, we check the value of the settings for this website is true.
                              //? If it's false or null (never set), we will paint red.
                              border: Border.all(
                                  color: settings.get('loading') == "fadingFour"
                                      ? Colors.green
                                      : Colors.red,
                                  width: 5),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5)),
                            ),
                            child: loadingSelector("fadingFour", "dark")),
                        onTap: () {
                          setState(() {
                            if (settings.get('loading') != "fadingFour") {
                              settings.put('loading', "fadingFour");
                            }
                          });
                        }),
                    InkWell(
                        child: Container(
                            padding: EdgeInsets.all(0),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              //? To paint the border, we check the value of the settings for this website is true.
                              //? If it's false or null (never set), we will paint red.
                              border: Border.all(
                                  color: settings.get('loading') == "fadingGrid"
                                      ? Colors.green
                                      : Colors.red,
                                  width: 5),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5)),
                            ),
                            child: loadingSelector("fadingGrid", "dark")),
                        onTap: () {
                          setState(() {
                            if (settings.get('loading') != "fadingGrid") {
                              settings.put('loading', "fadingGrid");
                            }
                          });
                        }),
                    InkWell(
                        child: Container(
                            padding: EdgeInsets.all(0),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              //? To paint the border, we check the value of the settings for this website is true.
                              //? If it's false or null (never set), we will paint red.
                              border: Border.all(
                                  color: settings.get('loading') == "cubeGrid"
                                      ? Colors.green
                                      : Colors.red,
                                  width: 5),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5)),
                            ),
                            child: loadingSelector("cubeGrid", "dark")),
                        onTap: () {
                          setState(() {
                            if (settings.get('loading') != "cubeGrid") {
                              settings.put('loading', "cubeGrid");
                            }
                          });
                        }),
                    InkWell(
                        child: Container(
                            padding: EdgeInsets.all(0),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              //? To paint the border, we check the value of the settings for this website is true.
                              //? If it's false or null (never set), we will paint red.
                              border: Border.all(
                                  color: settings.get('loading') ==
                                          "pouringHourglass"
                                      ? Colors.green
                                      : Colors.red,
                                  width: 5),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5)),
                            ),
                            child: loadingSelector("pouringHourglass", "dark")),
                        onTap: () {
                          setState(() {
                            if (settings.get('loading') != "pouringHourglass") {
                              settings.put('loading', "pouringHourglass");
                            }
                          });
                        }),
                  ],
                ),
                //? Permite que o usuário troque o tema do aplicativo.
                //? O usuário não verá a opção de trocar para o mesmo tema que estiver ativo
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Center(
                    child: Text(
                      regionalText["settings"]["themePicker"],
                      style: textSelection("textDark"),
                    ),
                  ),
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (settings.get('theme') != "pink")
                      Tooltip(
                        message: regionalText["settings"]["pink"],
                        child: InkWell(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 25,
                                  height: 50,
                                  color: themeSelector["primary"]["pink"],
                                ),
                                Container(
                                  width: 25,
                                  height: 50,
                                  color: themeSelector["secondary"]["pink"],
                                )
                              ],
                            ),
                            onTap: () => {
                                  setState(() {
                                    settings.put('theme', 'pink');
                                  }),
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
                                  width: 25,
                                  height: 50,
                                  color: themeSelector["primary"]["orange"],
                                ),
                                Container(
                                  width: 25,
                                  height: 50,
                                  color: themeSelector["secondary"]["orange"],
                                )
                              ],
                            ),
                            onTap: () => {
                                  setState(() {
                                    settings.put('theme', 'orange');
                                  }),
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
                                  width: 25,
                                  height: 50,
                                  color: themeSelector["primary"]["blue"],
                                ),
                                Container(
                                  width: 25,
                                  height: 50,
                                  color: themeSelector["secondary"]["blue"],
                                )
                              ],
                            ),
                            onTap: () => {
                                  setState(() {
                                    settings.put('theme', 'blue');
                                  }),
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
                                  width: 25,
                                  height: 50,
                                  color: themeSelector["primary"]["black"],
                                ),
                                Container(
                                  width: 25,
                                  height: 50,
                                  color: themeSelector["secondary"]["black"],
                                )
                              ],
                            ),
                            onTap: () => {
                                  setState(() {
                                    settings.put('theme', 'black');
                                  }),
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
                                  width: 25,
                                  height: 50,
                                  color: themeSelector["primary"]["white"],
                                ),
                                Container(
                                  width: 25,
                                  height: 50,
                                  color: themeSelector["secondary"]["white"],
                                )
                              ],
                            ),
                            onTap: () => {
                                  setState(() {
                                    settings.put('theme', 'white');
                                  }),
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
                                  width: 25,
                                  height: 50,
                                  color: themeSelector["primary"]["boredom"],
                                ),
                                Container(
                                  width: 25,
                                  height: 50,
                                  color: themeSelector["secondary"]["boredom"],
                                )
                              ],
                            ),
                            onTap: () => {
                                  setState(() {
                                    settings.put('theme', 'boredom');
                                  }),
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
                        style: textSelection("textDark"),
                      ),
                    ),
                  ),
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
                        SizedBox(width: 10),
                        Text(
                          settings.get('psnID'),
                          style: textSelection("textDark"),
                        )
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        settings.delete("psnID");
                        settings.delete('psnpDump');
                        psnpDump = null;
                        settings.delete('psntlDump');
                        psntlDump = null;
                        settings.delete('exophaseDump');
                        exophaseDump = null;
                        settings.delete('trueTrophiesDump');
                        trueTrophiesDump = null;
                      });
                    },
                  ),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
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
                          style: textSelection("textDarkBold")),
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
                                  settings.put('psnID', text);
                                  updateProfiles();
                                });
                              });
                            }),
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      Text(
                        regionalText['home']['supportedWebsites'],
                        style: textSelection("textDarkBold"),
                      ),
                      //? Spaces for PSNProfiles and PSN Trophy Leaders
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: "PSN Profiles",
                              child: Container(
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
                                        scale: 2,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Text(
                                        "PSNProfiles",
                                        style: textSelection(""),
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
                              message: 'PSN Trophy Leaders (🐌)',
                              child: Container(
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
                                        scale: 0.5,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Text(
                                        'PSN Trophy Leaders',
                                        style: textSelection(""),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      //? Spaces for True Trophies and Exophase
                      Tooltip(
                        message: "True Trophies",
                        child: Padding(
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
                                        scale: 0.5,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Text(
                                        "True Trophies",
                                        style: textSelection(""),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Tooltip(
                                message: "Exophase",
                                child: Container(
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
                                          scale: 0.5,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Text(
                                          "Exophase",
                                          style: textSelection(""),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                        // //! PSN Profiles card display
                        //TODO PSN Profiles waypoint
                        if (settings.get("psnp") != false)
                          Container(
                            margin: EdgeInsets.all(15),
                            padding: EdgeInsets.all(15),
                            width: MediaQuery.of(context).size.width,
                            //! Height undefined until all items are added to avoid overflow error.
                            // height: 220,
                            decoration: boxDeco(),
                            child: FutureBuilder(
                              future: Future(() => psnpDump),
                              builder: (context, snapshot) {
                                //? Display card info if all information is successfully fetched
                                if (snapshot.data != null &&
                                    snapshot.data['update'] != true) {
                                  return Column(
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
                                          Image.network(
                                            snapshot.data['avatar'] ??
                                                "https://i.psnprofiles.com/avatars/m/Gfba90ec21.png",
                                            height: 60,
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
                                                    //? Country flag
                                                    Image.network(
                                                        "https://raw.githubusercontent.com/hjnilsson/country-flags/master/png100px/${snapshot.data['country']}.png",
                                                        height: 20),
                                                    SizedBox(width: 5),
                                                    Tooltip(
                                                      message: snapshot
                                                              .data['about'] ??
                                                          snapshot
                                                              .data['psnID'],
                                                      child: Text(
                                                        snapshot.data["psnID"],
                                                        style: textSelection(
                                                            "textLightBold"),
                                                      ),
                                                    )
                                                  ]),
                                              //? Level, level progress and level icon
                                              //TODO Update this with the actual current icons and also add the formula for the old leveling system.
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(5.0),
                                                child: Row(
                                                  children: [
                                                    Image.asset(
                                                      img['oldLevel'],
                                                      height: 25,
                                                    ),
                                                    SizedBox(width: 5),
                                                    Text(
                                                        "${snapshot.data['level'].toString()} (${snapshot.data['levelProgress']})",
                                                        style:
                                                            textSelection("")),
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
                                                  SizedBox(width: 20),
                                                  trophyType('gold',
                                                      quantity: snapshot
                                                          .data['gold']),
                                                  SizedBox(width: 20),
                                                  trophyType('silver',
                                                      quantity: snapshot
                                                          .data['silver']),
                                                  SizedBox(width: 20),
                                                  trophyType('bronze',
                                                      quantity: snapshot
                                                          .data['bronze']),
                                                  SizedBox(width: 20),
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
                                                          SizedBox(width: 5),
                                                          Text(
                                                            snapshot.data[
                                                                    'ultraRare']
                                                                .toString(),
                                                            style:
                                                                textSelection(
                                                                    ""),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(width: 20),
                                                    Tooltip(
                                                      message:
                                                          regionalText['trophy']
                                                              ['veryRare'],
                                                      child: Row(
                                                        children: [
                                                          Image.asset(
                                                              img['rarity5'],
                                                              height: 15),
                                                          SizedBox(width: 5),
                                                          Text(
                                                            snapshot.data[
                                                                    'veryRare']
                                                                .toString(),
                                                            style:
                                                                textSelection(
                                                                    ""),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(width: 20),
                                                    Tooltip(
                                                      message:
                                                          regionalText['trophy']
                                                              ['rare'],
                                                      child: Row(
                                                        children: [
                                                          Image.asset(
                                                              img['rarity4'],
                                                              height: 15),
                                                          SizedBox(width: 5),
                                                          Text(
                                                            snapshot
                                                                .data['rare']
                                                                .toString(),
                                                            style:
                                                                textSelection(
                                                                    ""),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(width: 20),
                                                    Tooltip(
                                                      message:
                                                          regionalText['trophy']
                                                              ['uncommon'],
                                                      child: Row(
                                                        children: [
                                                          Image.asset(
                                                              img['rarity3'],
                                                              height: 15),
                                                          SizedBox(width: 5),
                                                          Text(
                                                            snapshot.data[
                                                                    'uncommon']
                                                                .toString(),
                                                            style:
                                                                textSelection(
                                                                    ""),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(width: 20),
                                                    Tooltip(
                                                      message:
                                                          regionalText['trophy']
                                                              ['common'],
                                                      child: Row(
                                                        children: [
                                                          Image.asset(
                                                              img['rarity1'],
                                                              height: 20),
                                                          SizedBox(width: 5),
                                                          Text(
                                                            snapshot
                                                                .data['common']
                                                                .toString(),
                                                            style:
                                                                textSelection(
                                                                    ""),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          InkWell(
                                            child: Tooltip(
                                              message: "PSN Profiles",
                                              child: Image.network(
                                                "https://psnprofiles.com/favicon.ico",
                                                height: 25,
                                              ),
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
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["games"]}\n${snapshot.data['games'].toString()}",
                                                style: textSelection(""),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["complete"]}\n${snapshot.data['complete'].toString()} (${snapshot.data['completePercentage']}%)",
                                                style: textSelection(""),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["incomplete"]}\n${snapshot.data['incomplete'].toString()} (${snapshot.data['incompletePercentage']}%)",
                                                style: textSelection(""),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["completion"]}\n${snapshot.data['completion']}",
                                                style: textSelection(""),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["unearned"]}\n${snapshot.data['unearned'].toString()} (${snapshot.data['unearnedPercentage']}%)",
                                                style: textSelection(""),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["countryRank"]}\n${snapshot.data['countryRank'] != null ? snapshot.data['countryRank'].toString() + " " : "❌"}${snapshot.data['countryUp'] ?? ""}",
                                                style: textSelection(""),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["worldRank"]}\n${snapshot.data['worldRank'] != null ? snapshot.data['worldRank'].toString() + " " : "❌"}${snapshot.data['worldUp'] ?? ""}",
                                                style: textSelection(""),
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
                                        SizedBox(width: 10),
                                        Text(
                                          "PSNProfiles",
                                          style: textSelection("textLightBold"),
                                        )
                                      ],
                                    ),
                                  );
                                } //? Display loading circle while Future is being processed
                                else {
                                  return Center(child: loadingSelector());
                                }
                              },
                            ),
                          ),
                        // ! PSN Trophy Leaders card display
                        //TODO PSN Trophy Leaders waypoint
                        if (settings.get("psntl") != false)
                          Container(
                            margin: EdgeInsets.all(15),
                            padding: EdgeInsets.all(15),
                            width: MediaQuery.of(context).size.width,
                            //! Height undefined until all items are added to avoid overflow error.
                            // height: 220,
                            decoration: boxDeco(),
                            child: FutureBuilder(
                              future: Future(() => psntlDump),
                              builder: (context, snapshot) {
                                //? Display card info if all information is successfully fetched
                                if (snapshot.data != null &&
                                    snapshot.data['update'] != true) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
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
                                              Image.network(
                                                snapshot.data['avatar'] ??
                                                    "https://i.psnprofiles.com/avatars/m/Gfba90ec21.png",
                                                height: 60,
                                              ),
                                              //? PSNTL Mimic feature
                                              Tooltip(
                                                message: regionalText['home']
                                                    ['mimic'],
                                                child: Text(
                                                  "+" +
                                                      snapshot
                                                          .data["sameAvatar"]
                                                          .toString(),
                                                  style: textSelection(
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
                                                    //? Country flag
                                                    Image.network(
                                                        "https://raw.githubusercontent.com/hjnilsson/country-flags/master/png100px/${snapshot.data['country']}.png",
                                                        height: 20),
                                                    SizedBox(width: 5),
                                                    Text(
                                                      snapshot.data["psnID"],
                                                      style: textSelection(
                                                          "textLightBold"),
                                                    )
                                                  ]),
                                              //? Level, level progress and level icon
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
                                                        style:
                                                            textSelection("")),
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
                                                  SizedBox(width: 20),
                                                  trophyType('gold',
                                                      quantity: snapshot
                                                          .data['gold']),
                                                  SizedBox(width: 20),
                                                  trophyType('silver',
                                                      quantity: snapshot
                                                          .data['silver']),
                                                  SizedBox(width: 20),
                                                  trophyType('bronze',
                                                      quantity: snapshot
                                                          .data['bronze']),
                                                  SizedBox(width: 20),
                                                  trophyType('total',
                                                      quantity:
                                                          "${snapshot.data['total'].toString()}"),
                                                ],
                                              ),
                                            ],
                                          ),
                                          InkWell(
                                            child: Tooltip(
                                              message:
                                                  'PSN Trophy Leaders (🐌)',
                                              child: Image.network(
                                                "https://psntl.com/favicon.ico",
                                                scale: 0.7,
                                              ),
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
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["games"]}\n${snapshot.data['games'].toString()}",
                                                style: textSelection(""),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["completion"]}\n${snapshot.data['completion']}",
                                                style: textSelection(""),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["standard"]}\n${snapshot.data['standard'].toString()} ${snapshot.data['standardChange']}",
                                                style: textSelection(""),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["adjusted"]}\n${snapshot.data['adjusted'].toString()} ${snapshot.data['adjustedChange']}",
                                                style: textSelection(""),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["completist"]}\n${snapshot.data['completist'].toString()} ${snapshot.data['completistChange']}",
                                                style: textSelection(""),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["rarity"]}\n${snapshot.data['rarity'].toString()} ${snapshot.data['rarityChange']}",
                                                style: textSelection(""),
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
                                        SizedBox(width: 10),
                                        Text(
                                          'PSN Trophy Leaders (🐌)',
                                          style: textSelection("textLightBold"),
                                        )
                                      ],
                                    ),
                                  );
                                }
                                //? Display loading circle while Future is being processed
                                else {
                                  return Center(child: loadingSelector());
                                }
                              },
                            ),
                          ),
                        //! Exophase card display
                        //TODO Exophase waypoint
                        if (settings.get("exophase") != false)
                          Container(
                            margin: EdgeInsets.all(15),
                            padding: EdgeInsets.all(15),
                            width: MediaQuery.of(context).size.width,
                            //! Height undefined until all items are added to avoid overflow error.
                            // height: 220,
                            decoration: boxDeco(),
                            child: FutureBuilder(
                              future: Future(() => exophaseDump),
                              builder: (context, snapshot) {
                                //? Display card info if all information is successfully fetched
                                if (snapshot.data != null &&
                                    snapshot.data['update'] != true) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
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
                                              Image.network(
                                                snapshot.data['avatar'] ??
                                                    "https://i.psnprofiles.com/avatars/m/Gfba90ec21.png",
                                                height: 60,
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
                                                    //? Country flag
                                                    Image.network(
                                                        "https://raw.githubusercontent.com/hjnilsson/country-flags/master/png100px/${snapshot.data['country']}.png",
                                                        height: 20),
                                                    SizedBox(width: 5),
                                                    Text(
                                                      snapshot.data["psnID"],
                                                      style: textSelection(
                                                          "textLightBold"),
                                                    )
                                                  ]),
                                              //? Level, level progress and level icon
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
                                                        style:
                                                            textSelection("")),
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
                                                  SizedBox(width: 20),
                                                  trophyType('gold',
                                                      quantity: snapshot
                                                          .data['gold']),
                                                  SizedBox(width: 20),
                                                  trophyType('silver',
                                                      quantity: snapshot
                                                          .data['silver']),
                                                  SizedBox(width: 20),
                                                  trophyType('bronze',
                                                      quantity: snapshot
                                                          .data['bronze']),
                                                  SizedBox(width: 20),
                                                  trophyType('total',
                                                      quantity:
                                                          "${snapshot.data['total'].toString()}"),
                                                ],
                                              ),
                                            ],
                                          ),
                                          InkWell(
                                            child: Tooltip(
                                              message: "Exophase",
                                              child: Image.network(
                                                "https://www.exophase.com/assets/zeal/_icons/favicon.ico",
                                                scale: 4,
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
                                      SizedBox(height: 15),
                                      Divider(
                                          color: themeSelector['secondary']
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
                                                  const EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["games"]}\n${snapshot.data['games'].toString()}",
                                                style: textSelection(""),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["complete"]}\n${snapshot.data['complete'].toString()} (${snapshot.data['completePercentage']}%)",
                                                style: textSelection(""),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["incomplete"]}\n${snapshot.data['incomplete'].toString()} (${snapshot.data['incompletePercentage']}%)",
                                                style: textSelection(""),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["completion"]}\n${snapshot.data['completion']}",
                                                style: textSelection(""),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Tooltip(
                                              message: "PS4/PS5",
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(10.0),
                                                child: Text(
                                                  "${regionalText["home"]["hours"]}\n${snapshot.data['hours']}",
                                                  style: textSelection(""),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["exp"]}\n${snapshot.data['exp']}",
                                                style: textSelection(""),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["countryRank"]}\n${snapshot.data['countryRank'] != null ? snapshot.data['countryRank'].toString() + " " : "❌"}${snapshot.data['countryUp'] ?? ""}",
                                                style: textSelection(""),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["worldRank"]}\n${snapshot.data['worldRank'] != null ? snapshot.data['worldRank'].toString() + " " : "❌"}${snapshot.data['worldUp'] ?? ""}",
                                                style: textSelection(""),
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
                                        SizedBox(width: 10),
                                        Text(
                                          "Exophase",
                                          style: textSelection("textLightBold"),
                                        )
                                      ],
                                    ),
                                  );
                                } //? Display loading circle while Future is being processed
                                else {
                                  return Center(child: loadingSelector());
                                }
                              },
                            ),
                          ),
                        //! True Trophies card display
                        //TODO True Trophies waypoint
                        if (settings.get("trueTrophies") != false)
                          Container(
                            margin: EdgeInsets.all(15),
                            padding: EdgeInsets.all(15),
                            width: MediaQuery.of(context).size.width,
                            //! Height undefined until all items are added to avoid overflow error.
                            // height: 220,
                            decoration: boxDeco(),
                            child: FutureBuilder(
                              future: Future(() => trueTrophiesDump),
                              builder: (context, snapshot) {
                                //? Display card info if all information is successfully fetched
                                if (snapshot.data != null &&
                                    snapshot.data['update'] != true) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
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
                                              Image.network(
                                                snapshot.data['avatar'] ??
                                                    "https://i.psnprofiles.com/avatars/m/Gfba90ec21.png",
                                                height: 60,
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
                                                    //? Country flag
                                                    if (snapshot
                                                            .data['country'] !=
                                                        null)
                                                      Image.network(
                                                          snapshot
                                                              .data['country'],
                                                          height: 20),
                                                    if (snapshot
                                                            .data['country'] !=
                                                        null)
                                                      SizedBox(width: 5),
                                                    Text(
                                                      snapshot.data["psnID"],
                                                      style: textSelection(
                                                          "textLightBold"),
                                                    )
                                                  ]),
                                              //? Level, level progress and level icon
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
                                                        "${snapshot.data['level'].toString()}",
                                                        style:
                                                            textSelection("")),
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
                                                  SizedBox(width: 20),
                                                  trophyType('gold',
                                                      quantity: snapshot
                                                          .data['gold']),
                                                  SizedBox(width: 20),
                                                  trophyType('silver',
                                                      quantity: snapshot
                                                          .data['silver']),
                                                  SizedBox(width: 20),
                                                  trophyType('bronze',
                                                      quantity: snapshot
                                                          .data['bronze']),
                                                  SizedBox(width: 20),
                                                  trophyType('total',
                                                      quantity:
                                                          "${snapshot.data['total'].toString()}"),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Tooltip(
                                                    message: "TrueScore",
                                                    child: Row(children: [
                                                      Image.network(
                                                          "https://www.truetrophies.com/images/badges/tt-emblem-mono.png",
                                                          color: themeSelector[
                                                                  "secondary"][
                                                              settings.get(
                                                                  "theme")],
                                                          height: 20),
                                                      SizedBox(width: 5),
                                                      Text(
                                                          snapshot
                                                              .data['trueScore']
                                                              .toString(),
                                                          style:
                                                              textSelection(""))
                                                    ]),
                                                  ),
                                                  SizedBox(width: 20),
                                                  Tooltip(
                                                    message: "TrueLevel",
                                                    child: Row(children: [
                                                      Icon(Icons.star,
                                                          color: themeSelector[
                                                                  "secondary"][
                                                              settings.get(
                                                                  "theme")],
                                                          size: 20),
                                                      SizedBox(width: 5),
                                                      Text(
                                                          snapshot.data[
                                                                  'trueTrophyLevel']
                                                              .toString(),
                                                          style:
                                                              textSelection(""))
                                                    ]),
                                                  ),
                                                  SizedBox(width: 20),
                                                  Tooltip(
                                                    message: "TrueRatio",
                                                    child: Row(children: [
                                                      Icon(Icons.donut_large,
                                                          color: themeSelector[
                                                                  "secondary"][
                                                              settings.get(
                                                                  "theme")],
                                                          size: 20),
                                                      SizedBox(width: 5),
                                                      Text(
                                                          snapshot.data['ratio']
                                                              .toString(),
                                                          style:
                                                              textSelection(""))
                                                    ]),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          InkWell(
                                            child: Tooltip(
                                              message: "True Trophies",
                                              child: Image.network(
                                                "https://truetrophies.com/favicon.ico",
                                                scale: 0.5,
                                              ),
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
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["games"]}\n${snapshot.data['games'].toString()}",
                                                style: textSelection(""),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["complete"]}\n${snapshot.data['complete'].toString()} (${snapshot.data['completePercentage']}%)",
                                                style: textSelection(""),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["incomplete"]}\n${snapshot.data['incomplete'].toString()} (${snapshot.data['incompletePercentage']}%)",
                                                style: textSelection(""),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["completion"]}\n${snapshot.data['completion'].toString()}%\n(+${snapshot.data['completionIncrease']} ➡️ ${snapshot.data['completion'].ceil().toString()}%)",
                                                style: textSelection(""),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal: 10.0),
                                              child: Text(
                                                "${regionalText["home"]["worldRank"]}\n${snapshot.data['worldRank'] != null ? snapshot.data['worldRank'].toString() + " " : "❌"}${snapshot.data['worldUp'] ?? ""}",
                                                style: textSelection(""),
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
                                        SizedBox(width: 10),
                                        Text(
                                          "True Trophies",
                                          style: textSelection("textLightBold"),
                                        )
                                      ],
                                    ),
                                  );
                                } //? Display loading circle while Future is being processed
                                else {
                                  return Center(child: loadingSelector());
                                }
                              },
                            ),
                          )
                      ],
                    ),
                  ),
                //? This is the bottom row with the buttons for Translation/Discord/Version/Privacy
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InkWell(
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
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
                                style: textSelection("textDark")),
                          ],
                        ),
                        onTap: () => showDialog(
                          context: context,
                          builder: (context) => Center(
                            child: Container(
                              decoration: BoxDecoration(
                                  color: themeSelector["secondary"]
                                      [settings.get("theme")],
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25))),
                              width: MediaQuery.of(context).size.width * 0.5,
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppBar(
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(25))),
                                      title: Text(
                                        regionalText["home"]["translation"],
                                        style: textSelection(""),
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
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        children: [
                                          Text(
                                            regionalText["bottomButtons"]
                                                ["translationText"],
                                            style: TextStyle(
                                                decoration: TextDecoration.none,
                                                color: themeSelector["primary"]
                                                    [settings.get("theme")],
                                                fontSize: 16,
                                                fontWeight: FontWeight.normal),
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
                                              style: textSelection(""),
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
                      InkWell(
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.network(
                                "https://discord.com/assets/2c21aeda16de354ba5334551a883b481.png",
                                height: 25),
                            Text("Discord", style: textSelection("textDark")),
                          ],
                        ),
                        onTap: () async {
                          String discordURL = "https://discord.gg/j55v7pD";
                          if (await canLaunch(discordURL)) {
                            await launch(discordURL);
                          }
                        },
                      ),
                      InkWell(
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
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
                                style: textSelection("textDark")),
                          ],
                        ),
                        onTap: () => showDialog(
                            context: context,
                            builder: (context) {
                              //TODO Versioning waypoint
                              //? The function that will fetch the latest GitHub update will be declared here
                              //? to be used on the FutureBuilder() below
                              Future<Map<String, dynamic>> yuraUpdate() async {
                                WebScraper github =
                                    WebScraper("https://github.com/");
                                Map<String, dynamic> update = {};
                                if (await github
                                    .loadWebPage("TheYuriG/Yura/releases")) {
                                  try {
                                    github.getElement(
                                        'body > div.application-main > div > main > div.container-xl.clearfix.new-discussion-timeline.px-3.px-md-4.px-lg-5 > div > div.position-relative.border-top.clearfix > div:nth-child(1) > div > div.col-12.col-md-9.col-lg-10.px-md-3.py-md-4.release-main-section.commit.open.float-left > div.release-header > div > div > a',
                                        []).forEach((element) {
                                      if (element['title'].contains('v')) {
                                        update['lastVersion'] = element['title']
                                            .split(' ')[1]
                                            .trim();
                                      }
                                    });
                                    //? Gets the 'datetime' attribute, converts it to UNIX
                                    //? then use that to retrieve the timestamp of the update
                                    //? I have not yet found a way to translate this to locale
                                    //! No easy way to do dd/mm/yyyy for the right countries and mm/dd/yyyy for the rest
                                    //! This was working before and now it isn't. I don't know why
                                    github.getElement(
                                        'div:nth-child(1) > div > div > div.release-header > p > relative-time',
                                        ['datetime']).forEach((element) {
                                      Intl.systemLocale = Platform.localeName;
                                      // print(DateFormat.yMd().format(
                                      //     DateTime.parse(element['attributes']
                                      //         ['datetime'])));
                                      update['when'] = element['title'];
                                      // DateFormat.yMMMd()
                                      //     .add_Hm()
                                      //     .format(DateTime.parse(
                                      //         element['attributes']['datetime']
                                      //             .split()));
                                    });
                                    github.getElement(
                                        'body > div.application-main > div > main > div.container-xl.clearfix.new-discussion-timeline.px-3.px-md-4.px-lg-5 > div > div.position-relative.border-top.clearfix > div:nth-child(1) > div > div.col-12.col-md-9.col-lg-10.px-md-3.py-md-4.release-main-section.commit.open.float-left > details > div > div > div.d-flex.flex-justify-between.flex-items-center.py-1.py-md-2.Box-body.px-2 > a',
                                        ['href']).forEach((element) {
                                      update['updateLink'] =
                                          "https://github.com" +
                                              element['attributes']['href']
                                                  .trim();
                                    });
                                    github.getElement(
                                        'body > div.application-main > div > main > div.container-xl.clearfix.new-discussion-timeline.px-3.px-md-4.px-lg-5 > div > div.position-relative.border-top.clearfix > div:nth-child(1) > div > div.col-12.col-md-9.col-lg-10.px-md-3.py-md-4.release-main-section.commit.open.float-left > div.markdown-body > ul > li',
                                        []).forEach((element) {
                                      if (update['updateNotes'] == null) {
                                        update['updateNotes'] =
                                            "\n⦿ " + element['title'].trim();
                                      } else {
                                        update['updateNotes'] += ("\n\n⦿ " +
                                            element['title'].trim());
                                      }
                                    });
                                    if (update['lastVersion'] == null) {
                                      throw Error;
                                    }
                                  } catch (e) {
                                    update['lastVersion'] = 'error';
                                    update['updateNotes'] = 'error';
                                  }
                                }
                                // print(update);
                                return update;
                              }

                              return StatefulBuilder(
                                  builder: (BuildContext context, setState) {
                                return Center(
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.7,
                                    decoration: BoxDecoration(
                                        color: themeSelector["secondary"]
                                            [settings.get("theme")],
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(25))),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AppBar(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                        top: Radius.circular(
                                                            25))),
                                            title: Text(
                                              "Yura ${regionalText['home']['version']} ${regionalText['version']['version']}",
                                              style: textSelection(""),
                                            ),
                                            centerTitle: true,
                                            automaticallyImplyLeading: false,
                                            backgroundColor:
                                                themeSelector["primary"]
                                                    [settings.get("theme")],
                                            actions: [
                                              IconButton(
                                                  splashColor:
                                                      Colors.transparent,
                                                  hoverColor:
                                                      Colors.transparent,
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
                                          FutureBuilder(
                                              future: yuraUpdate(),
                                              builder: (context, snapshot) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.all(20),
                                                  child: Column(
                                                    children: [
                                                      if (snapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting)
                                                        loadingSelector(
                                                            settings
                                                                .get('loading'),
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
                                                          style: TextStyle(
                                                              decoration:
                                                                  TextDecoration
                                                                      .none,
                                                              color: themeSelector[
                                                                      "primary"]
                                                                  [settings.get(
                                                                      "theme")],
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      if (snapshot.connectionState ==
                                                              ConnectionState
                                                                  .done &&
                                                          snapshot.data[
                                                                  'updateNotes'] !=
                                                              "error")
                                                        SizedBox(height: 5),
                                                      if (snapshot.connectionState ==
                                                              ConnectionState
                                                                  .done &&
                                                          snapshot.data[
                                                                  'updateNotes'] !=
                                                              "error")
                                                        Text(
                                                          snapshot.data[
                                                              'updateNotes'],
                                                          style: TextStyle(
                                                              decoration:
                                                                  TextDecoration
                                                                      .none,
                                                              color: themeSelector[
                                                                      "primary"]
                                                                  [settings.get(
                                                                      "theme")],
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal),
                                                        ),
                                                      if (snapshot.connectionState ==
                                                              ConnectionState
                                                                  .done &&
                                                          snapshot.data[
                                                                  'updateNotes'] !=
                                                              "error" &&
                                                          snapshot.data[
                                                                  'lastVersion'] !=
                                                              regionalText[
                                                                      "version"]
                                                                  ["version"])
                                                        SizedBox(height: 20),
                                                      if (snapshot.connectionState ==
                                                              ConnectionState
                                                                  .done &&
                                                          snapshot.data[
                                                                  'updateNotes'] !=
                                                              "error" &&
                                                          snapshot.data[
                                                                  'lastVersion'] !=
                                                              regionalText[
                                                                      "version"]
                                                                  ["version"])
                                                        MaterialButton(
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        7),
                                                          ),
                                                          child: Text(
                                                            regionalText[
                                                                    "bottomButtons"]
                                                                ["update"],
                                                            style:
                                                                textSelection(
                                                                    ""),
                                                          ),
                                                          color: themeSelector[
                                                                  "primary"][
                                                              settings.get(
                                                                  "theme")],
                                                          onPressed: () async {
                                                            final String
                                                                updateLink =
                                                                snapshot.data[
                                                                    'updateLink'];
                                                            if (await canLaunch(
                                                                updateLink)) {
                                                              launch(
                                                                  updateLink);
                                                            }
                                                          },
                                                        ),
                                                      if (snapshot
                                                              .connectionState ==
                                                          ConnectionState.done)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  top: 10),
                                                          child: Tooltip(
                                                            message: regionalText[
                                                                    "bottomButtons"]
                                                                ["updateGif"],
                                                            child:
                                                                Image.network(
                                                              "https://media1.giphy.com/media/l0MYOVCen1VP32oJW/giphy.gif?cid=ecf05e47df393f6ff6116685798d777331ca08f05afaacfc&rid=giphy.gif",
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.7,
                                                            ),
                                                          ),
                                                        )
                                                    ],
                                                  ),
                                                );
                                              })
                                        ]),
                                  ),
                                );
                              });
                            }),
                      ),
                      InkWell(
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.remove_red_eye,
                                size: 20,
                                color: themeSelector["primary"]
                                    [settings.get("theme")]),
                            SizedBox(width: 5),
                            Text(regionalText['home']['privacy'],
                                style: textSelection("textDark")),
                          ],
                        ),
                        onTap: () => showDialog(
                          context: context,
                          builder: (context) => Center(
                            child: Container(
                              decoration: BoxDecoration(
                                  color: themeSelector["secondary"]
                                      [settings.get("theme")],
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25))),
                              width: MediaQuery.of(context).size.width * 0.5,
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppBar(
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(25))),
                                      title: Text(
                                        regionalText["home"]["privacy"],
                                        style: textSelection(""),
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
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        children: [
                                          Text(
                                            regionalText["bottomButtons"]
                                                ["privacyText"],
                                            style: TextStyle(
                                                decoration: TextDecoration.none,
                                                color: themeSelector["primary"]
                                                    [settings.get("theme")],
                                                fontSize: 16,
                                                fontWeight: FontWeight.normal),
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
                )
              ],
            ),
          ),
        ),
        floatingActionButton: settings.get("psnID") == null
            ? null
            : FloatingActionButton(
                onPressed: () {
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
