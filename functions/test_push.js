// Use default Firebase credentials (from firebase login)
process.env.GOOGLE_APPLICATION_CREDENTIALS = '';
process.env.FIREBASE_CONFIG = JSON.stringify({
  projectId: 'hush-7bab0',
});
process.env.GCLOUD_PROJECT = 'hush-7bab0';

const admin = require('firebase-admin');

admin.initializeApp({
  projectId: 'hush-7bab0',
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();
const targetUserId = 'RT7v5ZYu9xQXtkZnLCas57jHwXL2';

async function testDirectPush() {
  try {
    const userDoc = await db.collection('users').doc(targetUserId).get();
    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    console.log('User exists:', userDoc.exists);
    console.log('FCM Token:', fcmToken ? fcmToken.substring(0, 30) + '...' : 'NONE');

    if (!fcmToken) {
      console.log('ERROR: No FCM token found!');
      process.exit(1);
    }

    const messageId = await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: '🔔 Test from Script',
        body: 'If you see this on iPhone, push works!',
      },
      data: { type: 'test' },
      apns: {
        headers: {
          'apns-priority': '10',
        },
        payload: {
          aps: {
            alert: {
              title: '🔔 Test from Script',
              body: 'If you see this on iPhone, push works!',
            },
            sound: 'default',
            badge: 1,
          },
        },
      },
    });
    console.log('SUCCESS! Message ID:', messageId);
  } catch (error) {
    console.error('FAILED!');
    console.error('Error code:', error.code);
    console.error('Error message:', error.message);
  }

  process.exit(0);
}

testDirectPush();
