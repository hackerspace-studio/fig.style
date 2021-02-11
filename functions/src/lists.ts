import * as functions from 'firebase-functions';
import { adminApp } from './adminApp';
import { checkUserIsSignedIn } from './utils';

const firestore = adminApp.firestore();

/**
 * Delete an user's quotes list.
 * Add a new document to `todelete` collection 
 * as the quote sub-collection `list/quotes/{quoteId}` will be delete later.
 */
export const deleteList = functions
  .region('europe-west3')
  .https
  .onCall(async (data: DeleteListParams, context) => {
    const userAuth = context.auth;
    const { listId, idToken } = data;

    if (!userAuth) {
      throw new functions.https.HttpsError(
        'unauthenticated', 
        `The function must be called from an authenticated user.`,
      );
    }

    await checkUserIsSignedIn(context, idToken);

    if (!listId) {
      throw new functions.https.HttpsError(
        'invalid-argument', 
        `The function must be called with one argument "listId" which is the list to delete.`
      );
    }

    const listSnapshot = await firestore
      .collection('users')
      .doc(userAuth.uid)
      .collection('lists')
      .doc(listId)
      .get();


    const listData = listSnapshot.data();

    if (!listSnapshot.exists || !listData) {
      return {
        success: false,
        error: {
          message: "This list doesn't exist anymore.",
        },
        uid: userAuth.uid,
        target: {
          type: 'list',
          id: listId,
          date: Date.now(),
        }
      }
    }

    await firestore
      .collection('todelete')
      .doc(listId)
      .set({
        doc: {
          id: listId,
          conceptualType: 'list',
          dataType: 'subcollection',
          hasChildren: true,
        },
        path: `users/${userAuth.uid}/lists/${listId}/quotes`,
        task: {
          createdAt: Date.now(),
          done: false,
          items: {
            deleted: 0,
            total: listData.itemsCount ?? 0,
          },
          updatedAt: Date.now(),
        },
        user: {
          id: userAuth.uid,
        },
      });

    await firestore
      .collection('users')
      .doc(userAuth.uid)
      .collection('lists')
      .doc(listId)
      .delete();

    return {
      user: {
        id: userAuth.uid,
      },
      target: {
        type: 'list',
        id: listId,
        date: Date.now(),
      }
    }
  });

/**
 * Increment user's list count on create list.
 */
export const onListAdded = functions
  .region('europe-west3')
  .firestore
  .document('users/{userId}/lists/{listId}')
  .onCreate(async ({}, context) => {
    const user = await firestore
      .collection('users')
      .doc(context.params.userId)
      .get();

    if (!user.exists) { return; }
    
    const userData = user.data();
    if (!userData) { return; }

    const userLists: number = userData.stats.lists ?? 0;
    
    return await user.ref
      .update('stats.lists', userLists + 1);
  });

/**
 * Decrement user's list count on create list.
 */
export const onListDeleted = functions
  .region('europe-west3')
  .firestore
  .document('users/{userId}/lists/{listId}')
  .onDelete(async ({}, context) => {
    const user = await firestore
      .collection('users')
      .doc(context.params.userId)
      .get();

    if (!user.exists) { return; }

    const userData = user.data();
    if (!userData) { return; }

    const userLists: number = userData.stats.lists ?? 0;

    return await user.ref
      .update('stats.lists', Math.max(0, userLists - 1));
  });

/**
 * Increment user's list `itemsCount` when a new quote is added.
 */
export const onQuoteAdded = functions
  .region('europe-west3')
  .firestore
  .document('users/{userId}/lists/{listId}/quotes/{quoteId}')
  .onCreate(async ({}, context) => {
    const { userId, listId } = context.params;

    const listSnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('lists')
      .doc(listId)
      .get();

    const listData = listSnapshot.data();

    if (!listSnapshot.exists || !listData) {
      return;
    }

    const itemsCount = listData.itemsCount ?? 0;

    await listSnapshot
      .ref
      .update({
        itemsCount: itemsCount + 1,
      })
  });

/**
 * Decrement user's list `itemsCount` when a new quote is added.
 */
export const onQuoteDeleted = functions
  .region('europe-west3')
  .firestore
  .document('users/{userId}/lists/{listId}/quotes/{quoteId}')
  .onDelete(async ({}, context) => {
    const { userId, listId } = context.params;

    const listSnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('lists')
      .doc(listId)
      .get();

    const listData = listSnapshot.data();

    if (!listSnapshot.exists || !listData) {
      return;
    }

    const itemsCount = listData.itemsCount ?? 0;

    await listSnapshot
      .ref
      .update({
        itemsCount: itemsCount - 1,
      })
  });
  