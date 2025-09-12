import { Hono } from 'hono';
import admin from 'firebase-admin';

const bloodDonorController = new Hono();

// Get Firestore instance (lazy initialization)
const getDb = () => admin.firestore();

// Test route to debug user lookup
bloodDonorController.get('/debug/user/:email', async (c) => {
  try {
    const email = c.req.param('email');
    console.log(`🔍 DEBUG: Looking for user with email: ${email}`);
    
    // Try document ID approach
    const userDocById = await getDb().collection('users').doc(email).get();
    console.log(`🔍 DEBUG: User found by doc ID: ${userDocById.exists}`);
    
    // Try query approach
    const userQuery = await getDb().collection('users')
      .where('email', '==', email)
      .get();
    console.log(`🔍 DEBUG: Query results: ${userQuery.docs.length} documents`);
    
    // List all users (limited to 5 for debugging)
    const allUsers = await getDb().collection('users').limit(5).get();
    console.log(`🔍 DEBUG: Total users in collection: ${allUsers.docs.length}`);
    
    const userList = allUsers.docs.map(doc => ({
      id: doc.id,
      email: doc.data()?.email,
      username: doc.data()?.username
    }));
    
    return c.json({
      success: true,
      debug: {
        searchEmail: email,
        foundByDocId: userDocById.exists,
        foundByQuery: userQuery.docs.length > 0,
        totalUsers: allUsers.docs.length,
        sampleUsers: userList
      }
    });
  } catch (e) {
    console.error('DEBUG error:', e);
    return c.json({ 
      success: false, 
      error: e instanceof Error ? e.message : 'Unknown error' 
    }, 500);
  }
});

// Check if user is registered as a donor
bloodDonorController.get('/check/:email', async (c) => {
  try {
    const email = c.req.param('email');
    
    if (!email) {
      return c.json({ success: false, message: 'Email is required' }, 400);
    }

    // Query blood_donors collection for this email
    const donorSnapshot = await getDb().collection('blood_donors')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (donorSnapshot.empty) {
      return c.json({
        success: true,
        isRegistered: false,
        donorData: null
      });
    }

    const donorDoc = donorSnapshot.docs[0];
    if (!donorDoc) {
      return c.json({
        success: true,
        isRegistered: false,
        donorData: null
      });
    }

    const donorData = {
      id: donorDoc.id,
      ...donorDoc.data()
    };

    return c.json({
      success: true,
      isRegistered: true,
      donorData: donorData
    });

  } catch (error) {
    console.error('Error checking donor registration:', error);
    return c.json({
      success: false,
      message: 'Internal server error'
    }, 500);
  }
});

// Register a new blood donor
bloodDonorController.post('/register', async (c) => {
  try {
    const body = await c.req.json();
    const { email, bloodGroup, isAvailable, emergencyContact, medicalNotes, name, phone, location } = body;

    if (!email || !bloodGroup || !name || !phone || !location) {
      return c.json({
        success: false,
        message: 'Email, blood group, name, phone, and location are required'
      }, 400);
    }

    // Check if user already exists as donor
    const existingDonor = await getDb().collection('blood_donors')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (!existingDonor.empty) {
      return c.json({
        success: false,
        message: 'User is already registered as a donor'
      }, 409);
    }

    console.log(`✅ Registering donor: ${email} - ${name}`);

    // Create new donor record with all user info
    const donorData = {
      email,
      name,
      phone,
      location,
      bloodGroup,
      isAvailable: isAvailable ?? true,
      emergencyContact: emergencyContact || null,
      medicalNotes: medicalNotes || null,
      lastDonationDate: null,
      totalDonations: 0,
      registrationDate: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const donorRef = await getDb().collection('blood_donors').add(donorData);

    // Get the created document with the server timestamp
    const createdDoc = await donorRef.get();
    const responseData = {
      id: createdDoc.id,
      ...createdDoc.data(),
      registrationDate: createdDoc.data()?.registrationDate?.toDate?.()?.toISOString?.() || new Date().toISOString(),
      updatedAt: createdDoc.data()?.updatedAt?.toDate?.()?.toISOString?.() || new Date().toISOString()
    };

    return c.json({
      success: true,
      message: 'Successfully registered as blood donor',
      donorData: responseData
    }, 201);

  } catch (error) {
    console.error('Error registering donor:', error);
    return c.json({
      success: false,
      message: 'Internal server error'
    }, 500);
  }
});

// Update donor profile
bloodDonorController.put('/update/:email', async (c) => {
  try {
    const email = c.req.param('email');
    const body = await c.req.json();
    const { name, phone, location, bloodGroup, isAvailable, lastDonationDate, totalDonations, emergencyContact, medicalNotes } = body;

    if (!email) {
      return c.json({ success: false, message: 'Email is required' }, 400);
    }

    // Find donor document
    const donorSnapshot = await getDb().collection('blood_donors')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (donorSnapshot.empty) {
      return c.json({
        success: false,
        message: 'Donor not found'
      }, 404);
    }

    const donorDoc = donorSnapshot.docs[0];
    if (!donorDoc) {
      return c.json({
        success: false,
        message: 'Donor not found'
      }, 404);
    }

    const updateData: any = {
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    // Only update provided fields
    if (name !== undefined) updateData.name = name;
    if (phone !== undefined) updateData.phone = phone;
    if (location !== undefined) updateData.location = location;
    if (bloodGroup !== undefined) updateData.bloodGroup = bloodGroup;
    if (isAvailable !== undefined) updateData.isAvailable = isAvailable;
    if (lastDonationDate !== undefined) updateData.lastDonationDate = lastDonationDate;
    if (totalDonations !== undefined) updateData.totalDonations = totalDonations;
    if (emergencyContact !== undefined) updateData.emergencyContact = emergencyContact;
    if (medicalNotes !== undefined) updateData.medicalNotes = medicalNotes;

    await donorDoc.ref.update(updateData);

    // Get updated document
    const updatedDoc = await donorDoc.ref.get();
    const responseData = {
      id: updatedDoc.id,
      ...updatedDoc.data(),
      updatedAt: updatedDoc.data()?.updatedAt?.toDate?.()?.toISOString?.() || new Date().toISOString()
    };

    return c.json({
      success: true,
      message: 'Profile updated successfully',
      donorData: responseData
    });

  } catch (error) {
    console.error('Error updating donor:', error);
    return c.json({
      success: false,
      message: 'Internal server error'
    }, 500);
  }
});

// Get all donors with optional filters
bloodDonorController.get('/', async (c) => {
  try {
    const { bloodGroup, location, isAvailable, userEmail } = c.req.query();

    let query: admin.firestore.Query | admin.firestore.CollectionReference = getDb().collection('blood_donors');

    // Apply filters
    if (bloodGroup && bloodGroup !== 'All') {
      query = (query as admin.firestore.CollectionReference).where('bloodGroup', '==', bloodGroup);
    }
    if (isAvailable !== undefined) {
      query = (query as admin.firestore.CollectionReference).where('isAvailable', '==', isAvailable === 'true');
    }

    const donorSnapshot = await query.get();
    
    // Get all donor data directly from blood_donors collection - no need for user lookup
    const donorsData = donorSnapshot.docs.map((donorDoc) => {
      const donorData = donorDoc.data();
      return {
        id: donorDoc.id,
        email: donorData.email,
        name: donorData.name || 'Anonymous',
        phone: donorData.phone || '',
        location: donorData.location || '',
        bloodGroup: donorData.bloodGroup,
        isAvailable: donorData.isAvailable ?? true,
        emergencyContact: donorData.emergencyContact,
        medicalNotes: donorData.medicalNotes,
        totalDonations: donorData.totalDonations || 0,
        // Format dates
        registrationDate: donorData.registrationDate?.toDate?.()?.toISOString?.() || null,
        updatedAt: donorData.updatedAt?.toDate?.()?.toISOString?.() || null,
        lastDonation: donorData.lastDonationDate || 'Never'
      };
    });

    // Apply location filter if provided (after fetching donor data)
    let filteredDonors = donorsData;
    if (location && location.trim() !== '') {
      filteredDonors = donorsData.filter((donor: any) => 
        donor.location.toLowerCase().includes(location.toLowerCase())
      );
    }

    // Sort by availability first, then by registration date
    filteredDonors.sort((a: any, b: any) => {
      if (a.isAvailable && !b.isAvailable) return -1;
      if (!a.isAvailable && b.isAvailable) return 1;
      // If same availability, sort by registration date (newest first)
      const aDate = new Date(a.registrationDate || 0);
      const bDate = new Date(b.registrationDate || 0);
      return bDate.getTime() - aDate.getTime();
    });

    return c.json({
      success: true,
      donors: filteredDonors
    });

  } catch (error) {
    console.error('Error fetching donors:', error);
    return c.json({
      success: false,
      message: 'Internal server error',
      donors: []
    }, 500);
  }
});

// Update availability status
bloodDonorController.patch('/:email/availability', async (c) => {
  try {
    const email = c.req.param('email');
    const body = await c.req.json();
    const { isAvailable } = body;

    if (!email) {
      return c.json({ success: false, message: 'Email is required' }, 400);
    }

    if (isAvailable === undefined) {
      return c.json({ success: false, message: 'isAvailable field is required' }, 400);
    }

    // Find and update donor
    const donorSnapshot = await getDb().collection('blood_donors')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (donorSnapshot.empty) {
      return c.json({
        success: false,
        message: 'Donor not found'
      }, 404);
    }

    const donorDoc = donorSnapshot.docs[0];
    if (!donorDoc) {
      return c.json({
        success: false,
        message: 'Donor not found'
      }, 404);
    }
    await donorDoc.ref.update({
      isAvailable,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return c.json({
      success: true,
      message: 'Availability updated successfully'
    });

  } catch (error) {
    console.error('Error updating availability:', error);
    return c.json({
      success: false,
      message: 'Internal server error'
    }, 500);
  }
});

// Update last donation date
bloodDonorController.patch('/:email/donation', async (c) => {
  try {
    const email = c.req.param('email');
    const body = await c.req.json();
    const { lastDonationDate, totalDonations } = body;

    if (!email) {
      return c.json({ success: false, message: 'Email is required' }, 400);
    }

    if (!lastDonationDate) {
      return c.json({ success: false, message: 'lastDonationDate is required' }, 400);
    }

    // Find and update donor
    const donorSnapshot = await getDb().collection('blood_donors')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (donorSnapshot.empty) {
      return c.json({
        success: false,
        message: 'Donor not found'
      }, 404);
    }

    const donorDoc = donorSnapshot.docs[0];
    if (!donorDoc) {
      return c.json({
        success: false,
        message: 'Donor not found'
      }, 404);
    }
    const updateData: any = {
      lastDonationDate,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    if (totalDonations !== undefined) {
      updateData.totalDonations = totalDonations;
    }

    await donorDoc.ref.update(updateData);

    return c.json({
      success: true,
      message: 'Donation record updated successfully'
    });

  } catch (error) {
    console.error('Error updating donation record:', error);
    return c.json({
      success: false,
      message: 'Internal server error'
    }, 500);
  }
});

export default bloodDonorController;
