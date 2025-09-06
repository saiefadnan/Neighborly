import { Hono } from 'hono';
import admin from 'firebase-admin';

const bloodDonorController = new Hono();

// Get Firestore instance (lazy initialization)
const getDb = () => admin.firestore();

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
    const { email, bloodGroup, isAvailable, emergencyContact, medicalNotes } = body;

    if (!email || !bloodGroup) {
      return c.json({
        success: false,
        message: 'Email and blood group are required'
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

    // Check if user exists in users collection
    const userDoc = await getDb().collection('users').doc(email).get();
    if (!userDoc.exists) {
      return c.json({
        success: false,
        message: 'User not found in system'
      }, 404);
    }

    // Create new donor record
    const donorData = {
      email,
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
    const { bloodGroup, isAvailable, lastDonationDate, totalDonations, emergencyContact, medicalNotes } = body;

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
    
    // Get all donor data with user details
    const donorsWithUserData = await Promise.all(
      donorSnapshot.docs.map(async (donorDoc) => {
        const donorData = donorDoc.data();
        // Get user details from users collection
        let userData = null;
        try {
          const userDoc = await getDb().collection('users').doc(donorData.email).get();
          if (userDoc.exists) {
            userData = userDoc.data();
          }
        } catch (userError) {
          console.error(`Error fetching user data for ${donorData.email}:`, userError);
        }
        return {
          id: donorDoc.id,
          ...donorData,
          isAvailable: donorData.isAvailable ?? true,
          // User details
          name: userData?.username || 'Anonymous',
          phone: userData?.contactNumber || userData?.contact || '',
          location: userData?.address || '',
          // Format dates
          registrationDate: donorData.registrationDate?.toDate?.()?.toISOString?.() || null,
          updatedAt: donorData.updatedAt?.toDate?.()?.toISOString?.() || null,
          lastDonation: donorData.lastDonationDate || 'Never'
        };
      })
    );

    // Apply location filter if provided (after fetching user data)
    let filteredDonors = donorsWithUserData;
    if (location && location.trim() !== '') {
      filteredDonors = donorsWithUserData.filter((donor: any) => 
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
