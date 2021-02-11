import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:figstyle/types/quote.dart';

Future<bool> deleteQuote({Quote quote}) async {
  try {
    await FirebaseFirestore.instance
        .collection('quotes')
        .doc(quote.id)
        .delete();

    return true;
  } catch (error) {
    debugPrint(error.toString());
    return false;
  }
}
