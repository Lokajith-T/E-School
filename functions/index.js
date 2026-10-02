const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.verifySimLogin = functions.https.onCall(async (data, context) => {
    const mobileNumber = data.mobileNumber;
    if (!mobileNumber) {
        throw new functions.https.HttpsError('invalid-argument', 'Mobile number is required.');
    }

    // Query the users collection for this exact mobile number
    const usersRef = admin.firestore().collection('users');
    const snapshot = await usersRef.where('mobileNumber', '==', mobileNumber).where('status', '==', 'active').get();

    if (snapshot.empty) {
        // We throw a generic error to prevent attackers from enumerating phone numbers
        throw new functions.https.HttpsError('not-found', 'Profile not found or inactive.');
    }

    // Assuming mobile numbers are unique per active user
    const userDoc = snapshot.docs[0]; 
    const uid = userDoc.id;

    try {
        // Mint a custom token for the verified UID
        const customToken = await admin.auth().createCustomToken(uid);
        return { token: customToken };
    } catch (error) {
        console.error("Error creating custom token:", error);
        throw new functions.https.HttpsError('internal', 'Error generating token.');
    }
});
