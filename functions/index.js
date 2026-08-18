const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');
const { logger } = require('firebase-functions');

initializeApp();
setGlobalOptions({ region: 'asia-south1', maxInstances: 3 });

const db = getFirestore();
const messaging = getMessaging();

exports.sendNotificationPush = onDocumentCreated(
  'notifications/{notificationId}',
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    const userId = typeof data.userId === 'string' ? data.userId : '';
    if (!userId) return;

    const userSnapshot = await db.collection('users').doc(userId).get();
    const tokens = Array.isArray(userSnapshot.data()?.fcmTokens)
      ? userSnapshot.data().fcmTokens.filter(
          (token) => typeof token === 'string' && token.length > 0,
        )
      : [];

    if (tokens.length === 0) {
      logger.info('No FCM tokens registered', { userId });
      return;
    }

    const title = typeof data.title === 'string' ? data.title : 'EventEase';
    const body = typeof data.message === 'string' ? data.message : '';
    const eventId = typeof data.eventId === 'string' ? data.eventId : '';
    const type = typeof data.type === 'string' ? data.type : '';

    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: {
        notificationId: snapshot.id,
        eventId,
        type,
      },
      android: {
        priority: 'high',
        notification: {
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    });

    const invalidTokens = [];
    response.responses.forEach((result, index) => {
      const code = result.error?.code;
      if (
        code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token'
      ) {
        invalidTokens.push(tokens[index]);
      }
    });

    if (invalidTokens.length > 0) {
      await userSnapshot.ref.update({
        fcmTokens: FieldValue.arrayRemove(...invalidTokens),
      });
    }

    logger.info('FCM notification sent', {
      notificationId: snapshot.id,
      userId,
      successCount: response.successCount,
      failureCount: response.failureCount,
    });
  },
);
