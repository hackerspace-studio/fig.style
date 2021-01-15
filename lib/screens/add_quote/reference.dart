import 'dart:async';

import 'package:figstyle/components/sheet_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:figstyle/components/fade_in_x.dart';
import 'package:figstyle/components/fade_in_y.dart';
import 'package:figstyle/components/data_quote_inputs.dart';
import 'package:figstyle/state/colors.dart';
import 'package:figstyle/types/reference_suggestion.dart';
import 'package:figstyle/utils/language.dart';
import 'package:figstyle/utils/search.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:supercharged/supercharged.dart';

class AddQuoteReference extends StatefulWidget {
  @override
  _AddQuoteReferenceState createState() => _AddQuoteReferenceState();
}

class _AddQuoteReferenceState extends State<AddQuoteReference> {
  bool prefilledInputs = false;
  bool isLoadingSuggestions = false;
  final beginY = 10.0;

  final nameFocusNode = FocusNode();
  final primaryTypeFocusNode = FocusNode();
  final secondaryTypeFocusNode = FocusNode();
  final summaryFocusNode = FocusNode();

  final affiliateUrlController = TextEditingController();
  final amazonUrlController = TextEditingController();
  final facebookUrlController = TextEditingController();
  final nameController = TextEditingController();
  final netflixUrlController = TextEditingController();
  final primaryTypeController = TextEditingController();
  final primeVideoUrlController = TextEditingController();
  final secondaryTypeController = TextEditingController();
  final summaryController = TextEditingController();
  final twitterUrlController = TextEditingController();
  final twitchUrlController = TextEditingController();
  final websiteUrlController = TextEditingController();
  final wikiUrlController = TextEditingController();
  final youtubeUrlController = TextEditingController();

  final linkInputController = TextEditingController();

  List<ReferenceSuggestion> referencesSuggestions = [];

  String tapToEditStr = 'Tap to edit';
  String tempImgUrl = '';

  Timer searchTimer;

  @override
  initState() {
    setState(() {
      affiliateUrlController.text = DataQuoteInputs.reference.urls.affiliate;
      amazonUrlController.text = DataQuoteInputs.reference.urls.amazon;
      facebookUrlController.text = DataQuoteInputs.reference.urls.facebook;
      nameController.text = DataQuoteInputs.reference.name;
      netflixUrlController.text = DataQuoteInputs.reference.urls.netflix;
      primeVideoUrlController.text = DataQuoteInputs.reference.urls.primeVideo;
      primaryTypeController.text = DataQuoteInputs.reference.type.primary;
      secondaryTypeController.text = DataQuoteInputs.reference.type.secondary;
      summaryController.text = DataQuoteInputs.reference.summary;
      twitterUrlController.text = DataQuoteInputs.reference.urls.twitter;
      twitchUrlController.text = DataQuoteInputs.reference.urls.twitch;
      websiteUrlController.text = DataQuoteInputs.reference.urls.website;
      wikiUrlController.text = DataQuoteInputs.reference.urls.wikipedia;
      youtubeUrlController.text = DataQuoteInputs.reference.urls.youtube;
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 600.0,
      child: Column(
        children: <Widget>[
          avatar(),
          nameCardInput(),
          primaryTypeCardInput(),
          secondaryTypeCardInput(),
          releaseDate(),
          clearButton(),
          langSelector(),
          summaryCardInput(),
          FadeInY(
            delay: 0.milliseconds,
            beginY: beginY,
            child: links(),
          ),
        ],
      ),
    );
  }

  Widget actionsInput({
    VoidCallback onClearInput,
    VoidCallback onSaveInput,
    String clearInputText = 'Clear input',
  }) {
    double left = 40.0;
    double spacing = 20.0;

    if (MediaQuery.of(context).size.width < 600.0) {
      spacing = 5.0;
      left = 0.0;
    }

    return Padding(
      padding: EdgeInsets.only(
        top: 20.0,
        left: left,
      ),
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          OutlinedButton.icon(
            onPressed: onClearInput,
            icon: Opacity(
              opacity: 0.6,
              child: Icon(Icons.clear),
            ),
            label: Opacity(
              opacity: 0.6,
              child: Text(
                clearInputText,
              ),
            ),
            style: OutlinedButton.styleFrom(
              primary: stateColors.foreground,
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              if (onSaveInput != null) {
                onSaveInput();
              }

              Navigator.of(context).pop();
            },
            icon: Opacity(
              opacity: 0.6,
              child: Icon(Icons.check),
            ),
            label: Opacity(
              opacity: 0.6,
              child: Text(
                'Save',
              ),
            ),
            style: OutlinedButton.styleFrom(
              primary: stateColors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget avatar() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 30.0,
      ),
      child: Card(
        color: Colors.black12,
        elevation: 0.0,
        child: DataQuoteInputs.reference.urls.image.length > 0
            ? Ink.image(
                width: 150.0,
                height: 200.0,
                fit: BoxFit.cover,
                image: NetworkImage(DataQuoteInputs.reference.urls.image),
                child: InkWell(
                  onTap: prefilledInputs
                      ? showPrefilledAlert
                      : () => showAvatarDialog(),
                ),
              )
            : SizedBox(
                width: 150.0,
                height: 200.0,
                child: InkWell(
                  child: Opacity(
                      opacity: .6,
                      child: Icon(
                        Icons.add,
                        size: 50.0,
                        color: stateColors.primary,
                      )),
                  onTap: prefilledInputs
                      ? showPrefilledAlert
                      : () => showAvatarDialog(),
                ),
              ),
      ),
    );
  }

  Widget clearButton() {
    return FlatButton.icon(
      onPressed: () {
        DataQuoteInputs.clearReference();

        amazonUrlController.clear();
        facebookUrlController.clear();
        nameController.clear();
        netflixUrlController.clear();
        primaryTypeController.clear();
        primeVideoUrlController.clear();
        secondaryTypeController.clear();
        summaryController.clear();
        twitchUrlController.clear();
        twitterUrlController.clear();
        websiteUrlController.clear();
        wikiUrlController.clear();
        youtubeUrlController.clear();

        referencesSuggestions.clear();

        prefilledInputs = false;
        tapToEditStr = 'Tap to edit';
        isLoadingSuggestions = false;

        setState(() {});

        nameFocusNode.requestFocus();
      },
      icon: Opacity(
        opacity: 0.6,
        child: Icon(Icons.delete_sweep),
      ),
      label: Opacity(
        opacity: 0.6,
        child: Text(
          'Clear all inputs',
        ),
      ),
    );
  }

  Widget langSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 40.0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Opacity(
            opacity: 0.6,
            child: Text(
              'Reference language: ',
              style: TextStyle(
                fontSize: 18.0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 20.0,
            ),
          ),
          DropdownButton<String>(
            value: DataQuoteInputs.reference.lang,
            iconEnabledColor: stateColors.primary,
            icon: Icon(Icons.language),
            style: TextStyle(
              color: stateColors.primary,
              fontSize: 20.0,
            ),
            onChanged: prefilledInputs
                ? null
                : (newValue) {
                    setState(() {
                      DataQuoteInputs.reference.lang = newValue;
                    });
                  },
            items: Language.available().map<DropdownMenuItem<String>>((value) {
              return DropdownMenuItem(
                value: value,
                child: Text(value.toUpperCase()),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget links() {
    double spacing = 20.0;

    if (MediaQuery.of(context).size.width < 600.0) {
      spacing = 5.0;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 80.0),
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: <Widget>[
          linkSquareButton(
            delay: 100,
            name: 'Website',
            active: DataQuoteInputs.reference.urls.website.isNotEmpty,
            imageUrl: 'assets/images/world-globe.png',
            onTap: () {
              showLinkInputSheet(
                labelText: 'Website',
                initialValue: DataQuoteInputs.reference.urls.website,
                onSave: (String inputUrl) {
                  setState(() {
                    DataQuoteInputs.reference.urls.website = inputUrl;
                  });
                },
              );
            },
          ),
          Observer(
            builder: (_) {
              return linkSquareButton(
                delay: 200,
                name: 'Wikipedia',
                active: DataQuoteInputs.reference.urls.wikipedia.isNotEmpty,
                imageUrl: 'assets/images/wikipedia-${stateColors.iconExt}.png',
                onTap: () {
                  showLinkInputSheet(
                    labelText: 'Wikipedia',
                    initialValue: DataQuoteInputs.reference.urls.wikipedia,
                    onSave: (String inputUrl) {
                      setState(() {
                        DataQuoteInputs.reference.urls.wikipedia = inputUrl;
                      });
                    },
                  );
                },
              );
            },
          ),
          linkSquareButton(
            delay: 300,
            name: 'Amazon',
            imageUrl: 'assets/images/amazon.png',
            active: DataQuoteInputs.reference.urls.amazon.isNotEmpty,
            onTap: () {
              showLinkInputSheet(
                labelText: 'Amazon',
                initialValue: DataQuoteInputs.reference.urls.amazon,
                onSave: (String inputUrl) {
                  setState(() {
                    DataQuoteInputs.reference.urls.amazon = inputUrl;
                  });
                },
              );
            },
          ),
          linkSquareButton(
            delay: 400,
            name: 'Facebook',
            imageUrl: 'assets/images/facebook.png',
            active: DataQuoteInputs.reference.urls.facebook.isNotEmpty,
            onTap: () {
              showLinkInputSheet(
                labelText: 'Facebook',
                initialValue: DataQuoteInputs.reference.urls.facebook,
                onSave: (String inputUrl) {
                  setState(() {
                    DataQuoteInputs.reference.urls.facebook = inputUrl;
                  });
                },
              );
            },
          ),
          linkSquareButton(
            delay: 500,
            name: 'Instagram',
            imageUrl: 'assets/images/instagram.png',
            active: DataQuoteInputs.reference.urls.instagram.isNotEmpty,
            onTap: () {
              showLinkInputSheet(
                labelText: 'Instagram',
                initialValue: DataQuoteInputs.reference.urls.instagram,
                onSave: (String inputUrl) {
                  setState(() {
                    DataQuoteInputs.reference.urls.instagram = inputUrl;
                  });
                },
              );
            },
          ),
          linkSquareButton(
            delay: 600,
            name: 'Netflix',
            imageUrl: 'assets/images/netflix.png',
            active: DataQuoteInputs.reference.urls.netflix.isNotEmpty,
            onTap: () {
              showLinkInputSheet(
                labelText: 'Netflix',
                initialValue: DataQuoteInputs.reference.urls.netflix,
                onSave: (String inputUrl) {
                  setState(() {
                    DataQuoteInputs.reference.urls.netflix = inputUrl;
                  });
                },
              );
            },
          ),
          linkSquareButton(
            delay: 700,
            name: 'Prime Video',
            imageUrl: 'assets/images/prime-video.png',
            active: DataQuoteInputs.reference.urls.primeVideo.isNotEmpty,
            onTap: () {
              showLinkInputSheet(
                labelText: 'Prime Video',
                initialValue: DataQuoteInputs.reference.urls.primeVideo,
                onSave: (String inputUrl) {
                  setState(() {
                    DataQuoteInputs.reference.urls.primeVideo = inputUrl;
                  });
                },
              );
            },
          ),
          linkSquareButton(
            delay: 700,
            name: 'Twitch',
            imageUrl: 'assets/images/twitch.png',
            active: DataQuoteInputs.reference.urls.twitch.isNotEmpty,
            onTap: () {
              showLinkInputSheet(
                labelText: 'Twitch',
                initialValue: DataQuoteInputs.reference.urls.twitch,
                onSave: (String inputUrl) {
                  setState(() {
                    DataQuoteInputs.reference.urls.twitch = inputUrl;
                  });
                },
              );
            },
          ),
          linkSquareButton(
            delay: 800,
            name: 'Twitter',
            imageUrl: 'assets/images/twitter.png',
            active: DataQuoteInputs.reference.urls.twitter.isNotEmpty,
            onTap: () {
              showLinkInputSheet(
                labelText: 'Twitter',
                initialValue: DataQuoteInputs.reference.urls.twitter,
                onSave: (String inputUrl) {
                  setState(() {
                    DataQuoteInputs.reference.urls.twitter = inputUrl;
                  });
                },
              );
            },
          ),
          linkSquareButton(
            delay: 900,
            name: 'YouTube',
            imageUrl: 'assets/images/youtube.png',
            active: DataQuoteInputs.reference.urls.youtube.isNotEmpty,
            onTap: () {
              showLinkInputSheet(
                labelText: 'YouTube',
                initialValue: DataQuoteInputs.reference.urls.youtube,
                onSave: (String inputUrl) {
                  setState(() {
                    DataQuoteInputs.reference.urls.youtube = inputUrl;
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget linkSquareButton({
    bool active = false,
    int delay = 0,
    String imageUrl,
    String name,
    Function onTap,
  }) {
    return FadeInX(
      beginX: 10.0,
      delay: Duration(milliseconds: delay),
      child: Tooltip(
        message: name,
        child: SizedBox(
          height: 80.0,
          width: 80.0,
          child: Card(
            elevation: active ? 4.0 : 0.0,
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: prefilledInputs ? showPrefilledAlert : onTap,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Image.asset(
                  imageUrl,
                  width: 30.0,
                  color:
                      active ? stateColors.secondary : stateColors.foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget nameCardInput() {
    final referenceName = DataQuoteInputs.reference.name;

    return Container(
      width: 250.0,
      padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
      child: Card(
        elevation: 2.0,
        child: InkWell(
          onTap: () async {
            await showCupertinoModalBottomSheet(
                context: context,
                builder: (context) {
                  return nameInput();
                });

            setState(() {});
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: 0.6,
                      child: Text(
                        'Name',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      referenceName != null && referenceName.isNotEmpty
                          ? referenceName
                          : tapToEditStr,
                    ),
                  ],
                ),
              ),
              Icon(Icons.account_box),
            ]),
          ),
        ),
      ),
    );
  }

  Widget nameInput({ScrollController scrollController}) {
    return Scaffold(
      body: ListView(
        physics: ClampingScrollPhysics(),
        controller: scrollController,
        children: [
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SheetHeader(
                  title: "Name",
                  subTitle: "Suggestions will show when you'll start typing",
                ),
                StatefulBuilder(builder: (context, childSetState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 60.0),
                        child: TextField(
                          autofocus: true,
                          controller: nameController,
                          focusNode: nameFocusNode,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            icon: Icon(Icons.person_outline),
                            labelText: "e.g. 1984, Interstellar",
                            alignLabelWithHint: true,
                          ),
                          minLines: 1,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 20.0,
                          ),
                          onChanged: (newValue) =>
                              onChanged(newValue, childSetState),
                        ),
                      ),
                      if (isLoadingSuggestions)
                        Padding(
                          padding: const EdgeInsets.only(left: 40.0),
                          child: LinearProgressIndicator(),
                        ),
                      actionsInput(
                        onClearInput: () {
                          DataQuoteInputs.reference.name = '';
                          nameController.clear();
                          nameFocusNode.requestFocus();
                        },
                      ),
                      suggestions(),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget primaryTypeCardInput() {
    final primaryType = DataQuoteInputs.reference.type.primary;

    return Container(
      width: 300.0,
      padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
      child: Card(
        elevation: 2.0,
        child: InkWell(
          onTap: prefilledInputs
              ? showPrefilledAlert
              : () async {
                  await showCupertinoModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return primaryTypeInput();
                      });

                  setState(() {});
                },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: 0.6,
                      child: Text(
                        'Primary type (e.g. TV series)',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      primaryType != null && primaryType.isNotEmpty
                          ? primaryType
                          : tapToEditStr,
                    ),
                  ],
                ),
              ),
              Icon(Icons.filter_1),
            ]),
          ),
        ),
      ),
    );
  }

  Widget primaryTypeInput({ScrollController scrollController}) {
    return Scaffold(
      body: ListView(
        physics: ClampingScrollPhysics(),
        controller: scrollController,
        children: [
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SheetHeader(
                  title: "Primary type",
                  subTitle: "Main category",
                ),
                Padding(
                  padding: EdgeInsets.only(top: 60.0),
                  child: TextField(
                    autofocus: true,
                    controller: primaryTypeController,
                    focusNode: primaryTypeFocusNode,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      icon: Icon(Icons.filter_1),
                      labelText: "e.g. TV series, Book",
                      alignLabelWithHint: true,
                    ),
                    minLines: 1,
                    style: TextStyle(
                      fontSize: 20.0,
                    ),
                    onChanged: (newValue) {
                      DataQuoteInputs.reference.type.primary = newValue;
                    },
                  ),
                ),
                actionsInput(
                  onClearInput: () {
                    DataQuoteInputs.reference.type.primary = '';
                    primaryTypeController.clear();
                    primaryTypeFocusNode.requestFocus();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget releaseDate() {
    final selectedDate = DataQuoteInputs.reference.release.original;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: prefilledInputs
                ? showPrefilledAlert
                : () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialEntryMode: DatePickerEntryMode.input,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(0),
                      lastDate: DateTime.now(),
                    );

                    setState(() =>
                        DataQuoteInputs.reference.release.original = picked);
                  },
            icon: Icon(Icons.calendar_today),
            label: Text(selectedDate != null
                ? selectedDate.toLocal().toString().split(' ')[0]
                : 'Select a new date'),
          ),
          SizedBox(
            width: 300.0,
            child: CheckboxListTile(
              title: Text('Before J-C (Jesus Christ)',
                  style: TextStyle(fontSize: 16)),
              subtitle:
                  Text('(e.g. year -500)', style: TextStyle(fontSize: 13)),
              value: DataQuoteInputs.reference.release.beforeJC,
              onChanged: prefilledInputs
                  ? null
                  : (newValue) {
                      setState(() => DataQuoteInputs
                          .reference.release.beforeJC = newValue);
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget secondaryTypeCardInput() {
    final secondaryType = DataQuoteInputs.reference.type.secondary;

    return Container(
      width: 300.0,
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Card(
        elevation: 2.0,
        child: InkWell(
          onTap: prefilledInputs
              ? showPrefilledAlert
              : () async {
                  await showCupertinoModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return secondaryTypeInput();
                      });

                  setState(() {});
                },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: 0.6,
                      child: Text(
                        'Secondary type (e.g. Thriller)',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      secondaryType != null && secondaryType.isNotEmpty
                          ? secondaryType
                          : tapToEditStr,
                    ),
                  ],
                ),
              ),
              Icon(Icons.filter_2),
            ]),
          ),
        ),
      ),
    );
  }

  Widget secondaryTypeInput({ScrollController scrollController}) {
    return Scaffold(
      body: ListView(
        physics: ClampingScrollPhysics(),
        controller: scrollController,
        children: [
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SheetHeader(
                  title: "Secondary type",
                  subTitle: "Sub-category bringing more precision",
                ),
                Padding(
                  padding: EdgeInsets.only(top: 60.0),
                  child: TextField(
                    autofocus: true,
                    controller: secondaryTypeController,
                    focusNode: secondaryTypeFocusNode,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      icon: Icon(Icons.filter_2),
                      labelText: "e.g. Thriller, Drama",
                      alignLabelWithHint: true,
                    ),
                    minLines: 1,
                    style: TextStyle(
                      fontSize: 20.0,
                    ),
                    onChanged: (newValue) {
                      DataQuoteInputs.reference.type.secondary = newValue;
                    },
                  ),
                ),
                actionsInput(
                  onClearInput: () {
                    DataQuoteInputs.reference.type.secondary = '';
                    secondaryTypeController.clear();
                    secondaryTypeFocusNode.requestFocus();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget suggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: referencesSuggestions.map((referenceSuggestion) {
        ImageProvider image;
        final imageUrl = referenceSuggestion.reference.urls.image;

        if (imageUrl != null && imageUrl.isNotEmpty) {
          image = NetworkImage(imageUrl);
        } else {
          image = AssetImage('assets/images/reference.png');
        }

        return ListTile(
          onTap: () {
            DataQuoteInputs.reference = referenceSuggestion.reference;
            prefilledInputs = true;
            tapToEditStr = '-';
            Navigator.of(context).pop();
          },
          title: Text(referenceSuggestion.getTitle()),
          contentPadding: const EdgeInsets.all(8.0),
          leading: Card(
            child: Image(
              image: image,
              width: 50.0,
              height: 50.0,
              fit: BoxFit.cover,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget summaryCardInput() {
    final summary = DataQuoteInputs.reference.summary;

    return Container(
      width: 300.0,
      padding: const EdgeInsets.only(top: 10.0, bottom: 40.0),
      child: Card(
        elevation: 2.0,
        child: InkWell(
          onTap: prefilledInputs
              ? showPrefilledAlert
              : () async {
                  await showMaterialModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return summaryInput();
                      });

                  setState(() {});
                },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: 0.6,
                      child: Text(
                        'Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      summary != null && summary.isNotEmpty
                          ? summary
                          : tapToEditStr,
                    ),
                  ],
                ),
              ),
              Icon(Icons.short_text),
            ]),
          ),
        ),
      ),
    );
  }

  Widget summaryInput({ScrollController scrollController}) {
    return Scaffold(
      body: ListView(
        physics: ClampingScrollPhysics(),
        controller: scrollController,
        children: [
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SheetHeader(
                  title: "Summary",
                  subTitle: "It can be the first Wikipedia paragraph",
                ),
                Padding(
                  padding: EdgeInsets.only(top: 60.0),
                  child: TextField(
                    autofocus: true,
                    controller: summaryController,
                    focusNode: summaryFocusNode,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      icon: Icon(Icons.edit),
                      labelText: "Once upon a time...",
                      alignLabelWithHint: true,
                    ),
                    minLines: 1,
                    maxLines: null,
                    style: TextStyle(
                      fontSize: 20.0,
                    ),
                    onChanged: (newValue) {
                      DataQuoteInputs.reference.summary = newValue;
                    },
                  ),
                ),
                actionsInput(onClearInput: () {
                  DataQuoteInputs.reference.summary = '';
                  summaryController.clear();
                  summaryFocusNode.requestFocus();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onChanged(String newValue, childSetState) {
    DataQuoteInputs.reference.name = newValue;
    prefilledInputs = false;
    tapToEditStr = 'Tap to edit';

    if (searchTimer != null && searchTimer.isActive) {
      searchTimer.cancel();
    }

    searchTimer = Timer(1.seconds, () async {
      setState(() {
        isLoadingSuggestions = true;
        referencesSuggestions.clear();
      });

      final query = algolia.index('references').search(newValue);

      final snapshot = await query.getObjects();

      if (snapshot.empty) {
        childSetState(() => isLoadingSuggestions = false);
        return;
      }

      for (final hit in snapshot.hits) {
        final data = hit.data;
        data['id'] = hit.objectID;

        final referenceSuggestion = ReferenceSuggestion.fromJSON(data);

        referencesSuggestions.add(referenceSuggestion);
      }

      childSetState(() => isLoadingSuggestions = false);
    });
  }

  void showAvatarDialog() {
    showMaterialModalBottomSheet(
      context: context,
      builder: (context) {
        return Scaffold(
          body: ListView(
            physics: ClampingScrollPhysics(),
            controller: ModalScrollController.of(context),
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 40.0,
                  right: 40.0,
                  top: 40.0,
                  bottom: 20.0,
                ),
                child: SizedBox(
                  width: 250.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SheetHeader(
                        title: "Reference illustration",
                        subTitle: "Enter a http link",
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                      ),
                      TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText:
                              DataQuoteInputs.reference.urls.image.length > 0
                                  ? DataQuoteInputs.reference.urls.image
                                  : 'URL',
                        ),
                        onChanged: (newValue) {
                          tempImgUrl = newValue;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Wrap(
                  spacing: 10.0,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        primary: stateColors.foreground,
                      ),
                      icon: Opacity(
                        opacity: 0.6,
                        child: Icon(Icons.clear),
                      ),
                      label: Opacity(
                        opacity: 0.6,
                        child: Text(
                          'Cancel',
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        primary: stateColors.foreground,
                      ),
                      icon: Opacity(
                        opacity: 0.6,
                        child: Icon(Icons.check),
                      ),
                      label: Opacity(
                        opacity: 0.6,
                        child: Text(
                          'Save',
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          DataQuoteInputs.reference.urls.image = tempImgUrl;
                        });

                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void showLinkInputSheet({
    String labelText = '',
    String initialValue = '',
    Function onSave,
  }) {
    linkInputController.clear();

    showCupertinoModalBottomSheet(
      context: context,
      builder: (context) {
        if (linkInputController.text.isEmpty) {
          linkInputController.text = initialValue;
        }

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SheetHeader(
                  title: "Link",
                  subTitle: "Enter a http link",
                ),
                Padding(
                  padding: EdgeInsets.only(top: 60.0),
                  child: TextField(
                    autofocus: true,
                    controller: linkInputController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: labelText,
                      icon: Icon(Icons.link),
                    ),
                    onChanged: (newValue) {
                      initialValue = newValue;
                    },
                  ),
                ),
                actionsInput(
                  onClearInput: () {
                    linkInputController.clear();
                    initialValue = '';
                  },
                  onSaveInput: () {
                    onSave(initialValue);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showPrefilledAlert() {
    showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: Text(
              "Reference's fields have been filled out for you.",
              style: TextStyle(
                fontSize: 16.0,
              ),
            ),
            titlePadding: const EdgeInsets.all(20.0),
          );
        });
  }
}
