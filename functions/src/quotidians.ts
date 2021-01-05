import * as functions from 'firebase-functions';
import { adminApp } from './adminApp';
import { sendNotification } from './utils';

const env = functions.config();
const firestore = adminApp.firestore();

export const notificationEN = functions
  .region('europe-west3')
  .pubsub
  .schedule('every day 00:01')
  .onRun(async (context) => {
    const date = new Date(context.timestamp);
    date.setDate(date.getDate() + 1); // -> get next day

    const afterDate = new Date(context.timestamp);
    afterDate.setDate(afterDate.getDate() + 1);
    afterDate.setHours(0, 0, 0, 0);
    afterDate.setSeconds(-1);

    const sendAfter = afterDate.toUTCString();

    const monthNumber = date.getMonth() + 1;
    const month = monthNumber < 10 ? `0${monthNumber}` : monthNumber;
    const day = date.getDate() < 10 ? `0${date.getDate()}` : date.getDate();

    // Get next day quotidian.
    const dateId = `${date.getFullYear()}:${month}:${day}:en`;

    console.log(`quotidians EN - ${dateId}`);

    const quotidian = await firestore
      .collection('quotidians')
      .doc(dateId)
      .get();

    if (!quotidian.exists) { return; }

    const qData = quotidian.data();
    if (!qData) { return; }

    const quoteName: string = qData['quote']['name'];
    const authorName: string = qData['quote']['author']['name'];

    let contents = quoteName;

    if (authorName) {
      contents += `― ${authorName}`;
    }

    sendNotification({
      adm_group: 'quotidians', // Amazon notification grouping
      android_group: 'quotidians', // Android notification grouping
      app_id: env.onesignal.appid,
      headings: { en: 'Quotidian', fr: 'Quotidian' },
      contents: { en: contents, fr: contents },
      data: {
        quoteid: qData['quote']['id'],
        type: 'quotidians',
      },
      delayed_option: 'timezone',
      delivery_time_of_day: '8:00AM',
      send_after: sendAfter,
      filters: [{ field: "tag", key: "quotidian", relation: "=", value: "en" }],
      ios_attachments: { id1: '' },
      big_picture: '',
      ios_badgeType: "Increase",
      ios_badgeCount: 1,
      thread_id: 'quotidians', // iOS 12+ notification grouping
    });

    return true;
  });

export const notificationFR = functions
  .region('europe-west3')
  .pubsub
  .schedule('every day 00:01')
  .onRun(async (context) => {
    const date = new Date(context.timestamp);
    date.setDate(date.getDate() + 1); // -> get next day

    const afterDate = new Date(context.timestamp);
    afterDate.setDate(afterDate.getDate() + 1);
    afterDate.setHours(0, 0, 0, 0);
    afterDate.setSeconds(-1);

    const sendAfter = afterDate.toUTCString();

    const monthNumber = date.getMonth() + 1;
    const month = monthNumber < 10 ? `0${monthNumber}` : monthNumber;
    const day = date.getDate() < 10 ? `0${date.getDate()}` : date.getDate();

    // Get next day quotidian.
    const dateId = `${date.getFullYear()}:${month}:${day}:fr`;

    console.log(`quotidians FR - ${dateId}`);

    const quotidian = await firestore
      .collection('quotidians')
      .doc(dateId)
      .get();

    if (!quotidian.exists) { return; }

    const qData = quotidian.data();
    if (!qData) { return; }

    const quoteName = qData['quote']['name'];
    const authorName = qData['quote']['author']['name'];

    let contents = quoteName;

    if (authorName) {
      contents += `― ${authorName}`;
    }

    sendNotification({
      adm_group: 'quotidians', // Amazon notification grouping
      android_group: 'quotidians', // Android notification grouping
      app_id: env.onesignal.appid,
      headings: { en: 'Quotidian', fr: 'Quotidian' },
      contents: { en: contents, fr: contents },
      data: {
        quoteid: qData['quote']['id'],
      },
      delayed_option: 'timezone',
      delivery_time_of_day: '8:00AM',
      send_after: sendAfter,
      filters: [{ field: "tag", key: "quotidian", relation: "=", value: "fr" }],
      ios_attachments: { id1: '' },
      big_picture: '',
      ios_badgeType: "Increase",
      ios_badgeCount: 1,
      thread_id: 'quotidians', // iOS 12+ notification grouping
    });

    return true;
  });
