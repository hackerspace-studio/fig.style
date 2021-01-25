import * as functions from 'firebase-functions';
import { adminApp } from './adminApp';

const firestore = adminApp.firestore();


export const onAuthorUpdated = functions
  .region('europe-west3')
  .firestore
  .document('authors/{authorId}')
  .onUpdate(async (snapshot) => {
    const beforeData = snapshot.before.data();
    const afterData = snapshot.after.data();
    const authorId = snapshot.after.id;

    const beforeName: string = beforeData.name;
    const afterName: string = afterData.name;

    if (beforeName === afterName) {
      return;
    }

    const allQuotesWithAuthorName = await firestore
      .collection('quotes')
      .where('author.id', '==', authorId)
      .get();

    if (allQuotesWithAuthorName.empty) {
      return;
    }

    for await (const quoteDoc of allQuotesWithAuthorName.docs) {
      await quoteDoc.ref
        .update('author.name', afterName);
    }

    return true;
  });

export const onQuoteAdded = functions
  .region('europe-west3')
  .firestore
  .document('quotes/{quoteId}')
  .onCreate(async (snapshot) => {
    const quoteData = snapshot.data();
    if (!quoteData) { return; }

    const user = await firestore
      .collection('users')
      .doc(quoteData.user.id)
      .get();

    if (!user.exists) { return; }
    
    const userData = user.data();
    if (!userData) { return; }

    const userPub: number = userData.stats.published ?? 0;
    
    return await user.ref
      .update('stats.published', userPub + 1);
  });

export const onQuoteDeleted = functions
  .region('europe-west3')
  .firestore
  .document('quotes/{quoteId}')
  .onDelete(async (snapshot) => {
    const quoteData = snapshot.data();
    if (!quoteData) { return; }

    const user = await firestore
      .collection('users')
      .doc(quoteData.user.id)
      .get();

    if (!user.exists) { return; }

    const userData = user.data();
    if (!userData) { return; }

    const userPub: number = userData.stats.published ?? 0;
    
    return await user.ref
      .update('stats.published', Math.max(0, userPub - 1));
  });
