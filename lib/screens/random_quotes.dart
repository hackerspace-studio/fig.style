import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:figstyle/components/desktop_app_bar.dart';
import 'package:figstyle/components/empty_content.dart';
import 'package:figstyle/components/error_container.dart';
import 'package:figstyle/components/fade_in_x.dart';
import 'package:figstyle/components/fade_in_y.dart';
import 'package:figstyle/components/page_app_bar.dart';
import 'package:figstyle/components/quote_row_with_actions.dart';
import 'package:figstyle/components/sliver_loading_view.dart';
import 'package:figstyle/state/colors.dart';
import 'package:figstyle/state/user.dart';
import 'package:figstyle/types/enums.dart';
import 'package:figstyle/types/quote.dart';
import 'package:figstyle/utils/app_logger.dart';
import 'package:figstyle/utils/constants.dart';
import 'package:figstyle/utils/language.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:mobx/mobx.dart';
import 'package:supercharged/supercharged.dart';
import 'package:unicons/unicons.dart';

class RandomQuotes extends StatefulWidget {
  @override
  _RandomQuotesState createState() => _RandomQuotesState();
}

class _RandomQuotesState extends State<RandomQuotes> {
  bool isLoading = false;
  bool hasErrors = false;

  DateTime lastGeneratedAt;

  final double maxWidth = 600.0;

  final scrollController = ScrollController();

  /// How many documents can be fetched.
  final int documentsLimit = 20;

  /// Specifies the maximum random quotes to display.
  final int maxRandomQuotes = 2;

  /// Maximum tries allowed if not quotes are found in a fetch.
  final int maxFetchAttempts = 5;

  /// Current fetch attempt.
  int currentFetchAttempts = 0;

  int layoutIndex = 0;
  ReactionDisposer langReaction;

  /// Useful to change layout appropriately.
  ScreenLayout _screenLayout = ScreenLayout.small;

  String lang = Language.en;

  var quotes = <Quote>[];

  var paddingListView = const EdgeInsets.only(
    top: 60.0,
    left: 60.0,
    right: 60.0,
    bottom: 15.0,
  );

  @override
  void initState() {
    super.initState();
    initProps();
    fetch();
  }

  void initProps() {
    currentFetchAttempts = 0;
    lang = stateUser.lang;

    langReaction = reaction((_) => stateUser.lang, (newLang) {
      lang = newLang;
      currentFetchAttempts = 0;
      fetch();
    });
  }

  @override
  dispose() {
    langReaction?.reaction?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    refreshScreenLayout();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          currentFetchAttempts = 0;
          fetch();
        },
        backgroundColor: stateColors.accent,
        foregroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Icon(UniconsLine.arrow_random),
        ),
      ),
      body: Overlay(initialEntries: [
        OverlayEntry(builder: (_) => body()),
      ]),
    );
  }

  Widget body() {
    return CustomScrollView(
      controller: scrollController,
      slivers: <Widget>[
        appBar(),
        bodyTitle(),
        bodyContent(),
        bodyFooter(),
        SliverPadding(
          padding: const EdgeInsets.only(
            bottom: 300.0,
          ),
        ),
      ],
    );
  }

  Widget appBar() {
    if (MediaQuery.of(context).size.width < Constants.maxMobileWidth) {
      return PageAppBar(
        textTitle: "Dice roll",
        expandedHeight: 70.0,
        titlePadding: EdgeInsets.only(
          left: 16.0,
        ),
      );
    }

    return DesktopAppBar(
      title: 'References',
      automaticallyImplyLeading: true,
    );
  }

  Widget bodyContent() {
    if (isLoading) {
      return SliverLoadingView();
    }

    if (!isLoading && hasErrors) {
      return errorView();
    }

    if (quotes.isEmpty) {
      return emptyView();
    }

    return layoutSelector();
  }

  Widget bodyFooter() {
    return SliverList(
      delegate: SliverChildListDelegate.fixed([
        if (quotes.isNotEmpty)
          FadeInY(
            beginY: 10.0,
            delay: 500.milliseconds,
            child: Center(
              child: Container(
                width: maxWidth,
                padding: EdgeInsets.symmetric(
                  horizontal: _screenLayout == ScreenLayout.small ? 16.0 : 60.0,
                ),
                child: Opacity(
                  opacity: 0.6,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(
                          Icons.timelapse,
                          color: stateColors.primary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "Last generated on ${Jiffy(lastGeneratedAt).yMMMMEEEEdjm}",
                          style: TextStyle(
                            color: stateColors.primary,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget bodyTitle() {
    final showIconButton = _screenLayout == ScreenLayout.wide;
    final horPadding = _screenLayout == ScreenLayout.small ? 24.0 : 60.0;

    return SliverPadding(
      padding: EdgeInsets.only(
        top: showIconButton ? 60.0 : 8.0,
        bottom: 40.0,
        left: horPadding,
        right: horPadding,
      ),
      sliver: SliverList(
        delegate: SliverChildListDelegate.fixed([
          Center(
            child: SizedBox(
              width: maxWidth,
              child: Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Opacity(
                    opacity: 0.8,
                    child: Text(
                      'Random quotes',
                      style: TextStyle(fontSize: 50.0),
                    ),
                  ),
                  if (showIconButton)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 40.0,
                        top: 12.0,
                      ),
                      child: IconButton(
                        color: stateColors.accent,
                        tooltip: "Get new random quotes",
                        onPressed: () {
                          currentFetchAttempts = 0;
                          fetch();
                        },
                        icon: Icon(UniconsLine.arrow_random),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: maxWidth,
              child: Padding(
                padding: EdgeInsets.only(
                  top: showIconButton ? 20.0 : 0.0,
                ),
                child: Opacity(
                  opacity: 0.4,
                  child: Text(
                    "We picked two random quotes for you. "
                    "You can roll the dices again with the random button above.",
                    style: TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget emptyView() {
    return SliverList(
      delegate: SliverChildListDelegate([
        FadeInY(
          delay: 200.milliseconds,
          beginY: 50.0,
          child: EmptyContent(
            icon: Opacity(
              opacity: .8,
              child: Icon(
                Icons.sentiment_neutral,
                size: 120.0,
                color: Color(0xFFFF005C),
              ),
            ),
            title: "It seems that there're no random quotes found.",
            subtitle:
                "Please try to reload the page again, we're sure we can find someting ;)",
            onRefresh: () {
              currentFetchAttempts = 0;
              fetch();
            },
          ),
        ),
      ]),
    );
  }

  Widget errorView() {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.only(top: 150.0),
          child: ErrorContainer(
            onRefresh: () {
              currentFetchAttempts = 0;
              fetch();
            },
          ),
        ),
      ]),
    );
  }

  Widget hQuotesListView() {
    final cardWidth = 250.0;

    return SliverPadding(
      padding: paddingListView,
      sliver: SliverList(
        delegate: SliverChildListDelegate.fixed([
          Wrap(
            alignment: WrapAlignment.center,
            children: quotes.mapIndexed((quote, index) {
              return FadeInX(
                beginX: 10.0,
                delay: index.milliseconds * 100,
                child: Center(
                  child: SizedBox(
                    width: cardWidth,
                    child: QuoteRowWithActions(
                      quote: quote,
                      elevation: 2.0,
                      cardHeight: 400.0,
                      cardWidth: cardWidth,
                      showAuthor: true,
                      showBorder: true,
                      canManage: stateUser.canManageQuotes,
                      isConnected: stateUser.isUserConnected,
                      componentType: ItemComponentType.card,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 35.0,
                        vertical: 20.0,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ]),
      ),
    );
  }

  Widget layoutSelector() {
    switch (layoutIndex) {
      case 0:
        return vQuotesListView();
      case 1:
        return hQuotesListView();
      default:
        return vQuotesListView();
    }
  }

  Widget vQuotesListView() {
    final width = MediaQuery.of(context).size.width;
    final horizontal = width < Constants.maxMobileWidth ? 20.0 : 70.0;

    return SliverPadding(
      padding: paddingListView,
      sliver: SliverList(
        delegate: SliverChildListDelegate.fixed(quotes.mapIndexed(
          (quote, index) {
            return Center(
              child: FadeInY(
                beginY: 10.0,
                delay: index.milliseconds * 100,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: SizedBox(
                    width: maxWidth,
                    child: QuoteRowWithActions(
                      quote: quote,
                      elevation: 2.0,
                      showAuthor: true,
                      showBorder: true,
                      canManage: stateUser.canManageQuotes,
                      isConnected: stateUser.isUserConnected,
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontal,
                        vertical: 40.0,
                      ),
                      componentType: ItemComponentType.card,
                    ),
                  ),
                ),
              ),
            );
          },
        ).toList()),
      ),
    );
  }

  void chooseLayoutIndex() {
    if (_screenLayout == ScreenLayout.small) {
      layoutIndex = 0;
      return;
    }

    layoutIndex = Random().nextInt(2);
  }

  void fetch() async {
    if (currentFetchAttempts >= maxFetchAttempts) {
      return;
    }

    setState(() {
      isLoading = true;
      quotes.clear();
    });

    currentFetchAttempts++;
    lastGeneratedAt = DateTime.now();

    final date = DateTime.now();
    final createdAt = date.subtract(Duration(days: Random().nextInt(360)));

    chooseLayoutIndex();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quotes')
          .where('lang', isEqualTo: lang)
          .where('createdAt', isGreaterThanOrEqualTo: createdAt)
          .limit(documentsLimit)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() => isLoading = false);
        fetch();
        return;
      }

      final boxQuotes = <Quote>[];

      snapshot.docs.forEach((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        boxQuotes.add(Quote.fromJSON(data));
      });

      boxQuotes.shuffle();
      quotes.addAll(boxQuotes.take(maxRandomQuotes));

      setState(() => isLoading = false);
    } catch (err) {
      appLogger.e(err);
      setState(() {
        isLoading = false;
      });
    }
  }

  void refreshScreenLayout() {
    _screenLayout = MediaQuery.of(context).size.width < Constants.maxMobileWidth
        ? ScreenLayout.small
        : ScreenLayout.wide;

    if (_screenLayout == ScreenLayout.small) {
      paddingListView = const EdgeInsets.only(
        top: 40.0,
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
      );
    }
  }
}
