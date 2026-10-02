// seed_admin.js
// Secure server-side script to seed the initial Admin and Demo School.
// This script bypasses Firestore Security Rules because it uses the Admin SDK.
// Run this with Node.js using: node seed_admin.js

const admin = require('firebase-admin');

// IMPORTANT: For a production app, you would download your serviceAccountKey.json 
// from the Firebase Console -> Project Settings -> Service Accounts, 
// and initialize it like this:
// const serviceAccount = require('./serviceAccountKey.json');
// admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

// Since we may test via emulators or default credentials:
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';

// Initialize with a fake project ID for emulator testing
admin.initializeApp({
  projectId: 'sentinal-vision'
});

const db = admin.firestore();
const auth = admin.auth();

async function seedDatabase() {
  try {
    const schoolId = 'school_001';
    
    console.log('Creating demo school...');
    await db.collection('schools').doc(schoolId).set({
      schoolId: schoolId,
      name: 'E-School Demo Academy',
      address: '123 Education Lane, Learning City',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('Creating Admin user in Auth...');
    const adminEmail = 'admin@eschool.local';
    const adminPassword = 'password123';
    let adminRecord;
    
    try {
      adminRecord = await auth.getUserByEmail(adminEmail);
      console.log('Admin user already exists in Auth.');
    } catch (e) {
      if (e.code === 'auth/user-not-found') {
        adminRecord = await auth.createUser({
          email: adminEmail,
          password: adminPassword,
          displayName: 'System Admin',
        });
        console.log('Admin user created in Auth.');
      } else {
        throw e;
      }
    }

    console.log('Creating Admin profile in Firestore...');
    await db.collection('users').doc(adminRecord.uid).set({
      uid: adminRecord.uid,
      email: adminEmail,
      role: 'admin',
      schoolId: schoolId,
      status: 'active',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('Creating Teacher user in Auth...');
    const teacherEmail = 'teacher@eschool.local';
    let teacherRecord;
    
    try {
      teacherRecord = await auth.getUserByEmail(teacherEmail);
    } catch (e) {
      teacherRecord = await auth.createUser({
        email: teacherEmail,
        password: adminPassword,
        displayName: 'Demo Teacher',
      });
    }

    console.log('Creating Teacher profile in Firestore...');
    await db.collection('users').doc(teacherRecord.uid).set({
      uid: teacherRecord.uid,
      email: teacherEmail,
      role: 'teacher',
      schoolId: schoolId,
      status: 'active',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('teachers').doc(teacherRecord.uid).set({
      teacherId: teacherRecord.uid,
      uid: teacherRecord.uid,
      schoolId: schoolId,
      name: 'Mr. Teacher',
      assignedClasses: ['class_10_a'],
      subjects: ['Math', 'Science'],
      status: 'active',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('Database seeded successfully via Server-Side Script!');
  } catch (error) {
    console.error('Error seeding database:', error);
  }
}

seedDatabase();
