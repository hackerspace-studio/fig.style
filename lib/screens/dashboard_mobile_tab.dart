import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:figstyle/router/app_router.gr.dart';
import 'package:figstyle/screens/notifications_center.dart';
import 'package:figstyle/types/enums.dart';
import 'package:figstyle/utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash/flash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:figstyle/components/base_page_app_bar.dart';
import 'package:figstyle/components/app_icon.dart';
import 'package:figstyle/components/data_quote_inputs.dart';
import 'package:figstyle/screens/about.dart';
import 'package:figstyle/screens/settings.dart';
import 'package:figstyle/screens/admin_temp_quotes.dart';
import 'package:figstyle/screens/drafts.dart';
import 'package:figstyle/screens/my_published_quotes.dart';
import 'package:figstyle/screens/quotes_lists.dart';
import 'package:figstyle/screens/quotidians.dart';
import 'package:figstyle/screens/signin.dart';
import 'package:figstyle/screens/signup.dart';
import 'package:figstyle/screens/my_temp_quotes.dart';
import 'package:figstyle/screens/favourites.dart';
import 'package:figstyle/state/colors.dart';
import 'package:figstyle/state/user.dart';
import 'package:figstyle/utils/app_storage.dart';
import 'package:figstyle/utils/snack.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:supercharged/supercharged.dart';

class DashboardMobileTab extends StatefulWidget {
  @override
  _DashboardMobileTabState createState() => _DashboardMobileTabState();
}

class _DashboardMobileTabState extends State<DashboardMobileTab> {
  bool canManage = false;
  bool prevIsAuthenticated = false;
  bool isAccountAdvVisible = false;
  bool showNotifiBadge = false;

  double beginY = 20.0;

  final scrollController = ScrollController();

  int unreadNotifiCount = 0;
  StreamSubscription<DocumentSnapshot> userSubscription;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  @override
  void dispose() {
    userSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Observer(builder: (context) {
        if (!stateUser.isUserConnected) {
          return Container();
        }

        return FloatingActionButton.extended(
          backgroundColor: stateColors.accent,
          foregroundColor: Colors.white,
          label: Text(
            "Add quote",
            style: TextStyle(
              fontSize: 17.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: Icon(Icons.add),
          onPressed: () {
            DataQuoteInputs.clearAll();

            context.router.root
                .navigate(DashboardPageRoute(children: [AddQuoteStepsRoute()]));
          },
        );
      }),
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          appBar(),
          body(),
        ],
      ),
    );
  }

  Widget aboutButton() {
    return tileButton(
      iconData: Icons.help,
      textTitle: 'About',
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => About())),
    );
  }

  List<Widget> adminWidgets(BuildContext context) {
    return [
      CustomAnimation(
        duration: 250.milliseconds,
        tween: Tween(begin: 0.0, end: MediaQuery.of(context).size.width),
        child: Divider(
          thickness: 1.0,
          height: 30.0,
        ),
        builder: (_, child, value) {
          return SizedBox(
            width: value,
            child: child,
          );
        },
      ),
      tileButton(
        iconData: Icons.timelapse,
        textTitle: 'Admin validation',
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => AdminTempQuotes())),
      ),
      tileButton(
        iconData: Icons.wb_sunny,
        textTitle: 'Quotidians',
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => Quotidians())),
      ),
    ];
  }

  Widget appBar() {
    final width = MediaQuery.of(context).size.width;
    double horizontal = width < Constants.maxMobileWidth ? 0.0 : 70.0;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontal),
      sliver: BasePageAppBar(
        pinned: true,
        collapsedHeight: 70.0,
        expandedHeight: 90.0,
        title: Padding(
          padding: const EdgeInsets.only(
            top: 24.0,
            left: 16.0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      scrollController.animateTo(
                        0,
                        duration: 250.milliseconds,
                        curve: Curves.easeIn,
                      );
                    },
                    icon: AppIcon(
                      padding: EdgeInsets.zero,
                      size: 30.0,
                    ),
                    label: Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 22.0,
                      ),
                    ),
                  ),
                ),
              ),
              notificationsIconButton(),
            ],
          ),
        ),
        showNavBackIcon: false,
      ),
    );
  }

  List<Widget> authWidgets(BuildContext context) {
    return [
      Column(
        children: <Widget>[
          draftsButton(),
          listsButton(),
          tempQuotesButton(),
          favButton(),
          pubQuotesButton(),
          settingsButton(),
          signOutButton(),
          aboutButton(),
        ],
      ),
    ];
  }

  Widget body() {
    final width = MediaQuery.of(context).size.width;
    double horizontal = width < Constants.maxMobileWidth ? 0.0 : 70.0;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontal),
      sliver: Observer(builder: (context) {
        List<Widget> children = [];

        if (stateUser.isUserConnected) {
          children.addAll(authWidgets(context));

          if (canManage) {
            children.addAll(adminWidgets(context));
          }
        } else {
          userSubscription?.cancel();
          children.add(whyAccountBlock());
          children.addAll(guestWidgets(context));
        }

        return SliverPadding(
          padding: const EdgeInsets.only(
            bottom: 150.0,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              )
            ]),
          ),
        );
      }),
    );
  }

  Widget bulletPoint({String text}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.green,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
          ),
          Expanded(
            child: Opacity(
              opacity: 0.6,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget draftsButton() {
    return tileButton(
      iconData: Icons.edit,
      textTitle: 'Drafts',
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => Drafts())),
    );
  }

  Widget favButton() {
    return tileButton(
      iconData: Icons.favorite,
      textTitle: 'Favourites',
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => Favourites())),
    );
  }

  List<Widget> guestWidgets(BuildContext context) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 40.0,
        ),
        child: Column(
          children: [
            signinButton(),
            signupButton(),
          ],
        ),
      ),
      Divider(
        height: 100.0,
        thickness: 1.0,
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          settingsButton(),
          aboutButton(),
        ],
      ),
    ];
  }

  Widget signOutButton() {
    return tileButton(
      iconData: Icons.exit_to_app,
      textTitle: 'Sign out',
      onTap: () async {
        await appStorage.clearUserAuthData();
        await stateUser.signOut();

        setState(() {
          canManage = false;
        });

        showSnack(
          context: context,
          message: 'You have been successfully disconnected.',
          type: SnackType.success,
        );
      },
    );
  }

  Widget listsButton() {
    return tileButton(
      iconData: Icons.list,
      textTitle: 'Lists',
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => QuotesLists())),
    );
  }

  Widget notificationsIconButton() {
    return Observer(
      builder: (context) {
        if (!stateUser.isUserConnected) {
          return Container();
        }

        return Badge(
          badgeContent: Text(
            "$unreadNotifiCount",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          showBadge: showNotifiBadge,
          child: IconButton(
            onPressed: () async {
              final size = MediaQuery.of(context).size;

              if (size.width > Constants.maxMobileWidth &&
                  size.height > Constants.maxMobileWidth) {
                await showFlash(
                  context: context,
                  persistent: false,
                  builder: (context, controller) {
                    return Flash.dialog(
                      controller: controller,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      enableDrag: true,
                      margin: const EdgeInsets.only(
                        left: 120.0,
                        right: 120.0,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(8.0),
                      ),
                      child: FlashBar(
                        message: Container(
                          height: MediaQuery.of(context).size.height - 100.0,
                          padding: const EdgeInsets.all(60.0),
                          child: NotificationsCenter(),
                        ),
                      ),
                    );
                  },
                );
              } else {
                await showCupertinoModalBottomSheet(
                  context: context,
                  builder: (_) => NotificationsCenter(
                    scrollController: scrollController,
                  ),
                );
              }
            },
            color: stateColors.foreground,
            tooltip: "My notifications",
            icon: Icon(Icons.notifications),
          ),
        );
      },
    );
  }

  Widget pubQuotesButton() {
    return tileButton(
      iconData: Icons.check,
      textTitle: 'Published',
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => MyPublishedQuotes())),
    );
  }

  Widget settingsButton() {
    return tileButton(
      iconData: Icons.settings,
      textTitle: 'Settings',
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => Settings())),
    );
  }

  Widget signinButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30.0),
      child: FlatButton(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => Signin()));
        },
        textColor: stateColors.primary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7.0),
            side: BorderSide(
              color: stateColors.primary,
            )),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 220.0,
            minHeight: 60.0,
          ),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'SIGN IN',
                  style: TextStyle(
                    fontSize: 17.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Icon(Icons.login),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget signupButton() {
    return FlatButton(
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => Signup()));
      },
      textColor: stateColors.secondary,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7.0),
          side: BorderSide(
            color: Colors.orange.shade600,
          )),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 220.0,
          minHeight: 60.0,
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'SIGN UP',
                style: TextStyle(
                  fontSize: 17.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Icon(Icons.person_add),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget tempQuotesButton() {
    return tileButton(
      iconData: Icons.timelapse,
      textTitle: 'In validation',
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => MyTempQuotes())),
    );
  }

  Widget tileButton({
    @required IconData iconData,
    @required String textTitle,
    @required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 40.0),
      leading: Icon(
        iconData,
        size: 30.0,
      ),
      title: Text(
        textTitle,
        style: TextStyle(fontSize: 20.0),
      ),
      onTap: onTap,
    );
  }

  Widget whyAccountBlock() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 30.0,
        bottom: 30.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlatButton(
            onPressed: () =>
                setState(() => isAccountAdvVisible = !isAccountAdvVisible),
            child: Opacity(
              opacity: 0.8,
              child: Text(
                'WHY AN ACCOUNT?',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (isAccountAdvVisible)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.only(top: 10.0)),
                  bulletPoint(text: 'Favourites quotes'),
                  bulletPoint(text: 'Create thematic lists'),
                  bulletPoint(text: 'Propose new quotes'),
                  bulletPoint(text: '& more...'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future fetchUserData() async {
    try {
      final userAuth = FirebaseAuth.instance.currentUser;

      if (userAuth == null) {
        return;
      }

      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userAuth.uid)
          .get();

      if (!userSnapshot.exists) {
        debugPrint("The user with the id ${userAuth.uid}"
            " doesn't exist anymore.");

        return;
      }

      userSubscription = userSnapshot.reference.snapshots().listen(
        (documentSnapshot) {
          final data = documentSnapshot.data();
          if (data == null) {
            userSubscription.cancel();
            return;
          }

          setState(() {
            canManage = data['rights']['user:managequote'] ?? false;
            unreadNotifiCount = data['stats']['notifications']['unread'];
            showNotifiBadge = unreadNotifiCount > 0;
          });
        },
        onError: (error, stacktrace) {
          debugPrint(error.toString());

          if (stacktrace != null) {
            debugPrint(stacktrace.toString());
          }
        },
      );
    } on Exception catch (error) {
      debugPrint(error.toString());
    }
  }
}
