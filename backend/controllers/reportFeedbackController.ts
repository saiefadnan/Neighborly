import { Hono } from "hono";
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

const reportFeedbackController = new Hono();

interface ReportData {
  id: string;
  reporterId: string;
  reportedUserEmail: string;
  reportedContentId?: string;
  reportType: string;
  severity: string;
  description: string;
  textEvidence?: string;
  imageEvidenceUrls?: string[];
  createdAt: string;
  status: string;
  isAnonymous: boolean;
}

interface FeedbackData {
  id: string;
  userId: string;
  targetUserEmail: string;
  helpRequestId?: string;
  feedbackType: string;
  rating: number;
  description: string;
  improvementSuggestion?: string;
  wouldRecommend: boolean;
  createdAt: string;
  isVerified: boolean;
}

// Submit a report
reportFeedbackController.post('/report', async (c) => {
  try {
    const db = getFirestore();
    const auth = getAuth();
    
    const authHeader = c.req.header('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return c.json({ error: 'Authorization header missing or invalid' }, 401);
    }

    const token = authHeader.substring(7);
    const decodedToken = await auth.verifyIdToken(token);
    const reporterId = decodedToken.uid;

    const reportData: ReportData = await c.req.json();
    
    // Validate required fields
    if (!reportData.reportedUserEmail || !reportData.reportType || !reportData.severity || !reportData.description) {
      return c.json({ error: 'Missing required fields' }, 400);
    }

    // Validate email format
    const emailRegex = /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/;
    if (!emailRegex.test(reportData.reportedUserEmail)) {
      return c.json({ error: 'Invalid email format' }, 400);
    }

    // Validate image evidence URLs if provided
    if (reportData.imageEvidenceUrls && reportData.imageEvidenceUrls.length > 5) {
      return c.json({ error: 'Maximum 5 images allowed' }, 400);
    }

    // Create report document
    const report: ReportData = {
      ...reportData,
      id: db.collection('reports').doc().id,
      reporterId: reporterId,
      createdAt: new Date().toISOString(),
      status: 'pending'
    };

    // Save report to Firestore
    await db.collection('reports').doc(report.id).set(report);

    // Check if this user should be auto-blocked based on report count
    await checkAndAutoBlockUser(db, reportData.reportedUserEmail, reportData.severity);

    return c.json({ 
      success: true, 
      message: 'Report submitted successfully',
      reportId: report.id 
    });

  } catch (error) {
    console.error('Error submitting report:', error);
    return c.json({ error: 'Failed to submit report' }, 500);
  }
});

// Submit feedback
reportFeedbackController.post('/feedback', async (c) => {
  try {
    const db = getFirestore();
    const auth = getAuth();
    
    const authHeader = c.req.header('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return c.json({ error: 'Authorization header missing or invalid' }, 401);
    }

    const token = authHeader.substring(7);
    const decodedToken = await auth.verifyIdToken(token);
    const userId = decodedToken.uid;

    const feedbackData: FeedbackData = await c.req.json();
    
    // Validate required fields
    if (!feedbackData.targetUserEmail || !feedbackData.feedbackType || feedbackData.rating === undefined || !feedbackData.description) {
      return c.json({ error: 'Missing required fields' }, 400);
    }

    // Validate email format if provided and not the default value
    if (feedbackData.targetUserEmail !== 'unknown@example.com') {
      const emailRegex = /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/;
      if (!emailRegex.test(feedbackData.targetUserEmail)) {
        return c.json({ error: 'Invalid email format' }, 400);
      }
    }

    // Validate rating range
    if (feedbackData.rating < 1 || feedbackData.rating > 5) {
      return c.json({ error: 'Rating must be between 1 and 5' }, 400);
    }

    // Create feedback document
    const feedback: FeedbackData = {
      ...feedbackData,
      id: db.collection('feedback').doc().id,
      userId: userId,
      createdAt: new Date().toISOString(),
      isVerified: true
    };

    // Save feedback to Firestore
    await db.collection('feedback').doc(feedback.id).set(feedback);

    // Update user rating if targeting specific user
    if (feedbackData.targetUserEmail !== 'unknown@example.com') {
      await updateUserRating(db, feedbackData.targetUserEmail, feedbackData.rating);
    }

    return c.json({ 
      success: true, 
      message: 'Feedback submitted successfully',
      feedbackId: feedback.id 
    });

  } catch (error) {
    console.error('Error submitting feedback:', error);
    return c.json({ error: 'Failed to submit feedback' }, 500);
  }
});

// Get user ratings and feedback
reportFeedbackController.get('/user-ratings/:email', async (c) => {
  try {
    const db = getFirestore();
    const auth = getAuth();
    
    const authHeader = c.req.header('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return c.json({ error: 'Authorization header missing or invalid' }, 401);
    }

    const token = authHeader.substring(7);
    await auth.verifyIdToken(token);

    const userEmail = c.req.param('email');
    
    // Validate email format
    const emailRegex = /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/;
    if (!emailRegex.test(userEmail)) {
      return c.json({ error: 'Invalid email format' }, 400);
    }

    // Get feedback for this user
    const feedbackQuery = await db.collection('feedback')
      .where('targetUserEmail', '==', userEmail)
      .orderBy('createdAt', 'desc')
      .limit(50)
      .get();

    const feedbacks = feedbackQuery.docs.map((doc: any) => doc.data());
    
    // Calculate statistics
    let totalRating = 0;
    let ratingCount = 0;
    let recommendationCount = 0;

    feedbacks.forEach((feedback: any) => {
      totalRating += feedback.rating;
      ratingCount++;
      if (feedback.wouldRecommend) recommendationCount++;
    });

    const averageRating = ratingCount > 0 ? totalRating / ratingCount : 0;
    const recommendationPercentage = ratingCount > 0 ? (recommendationCount / ratingCount) * 100 : 0;

    // Check for pending reports
    const reportsQuery = await db.collection('reports')
      .where('reportedUserEmail', '==', userEmail)
      .where('status', '==', 'pending')
      .get();

    const hasPendingReports = !reportsQuery.empty;

    // Calculate trust score
    const trustScore = calculateTrustScore(averageRating, ratingCount, hasPendingReports);

    return c.json({
      userEmail,
      averageRating: Number(averageRating.toFixed(2)),
      totalFeedbacks: ratingCount,
      recommendationPercentage: Number(recommendationPercentage.toFixed(1)),
      trustScore: Number(trustScore.toFixed(1)),
      hasPendingReports,
      recentFeedbacks: feedbacks.slice(0, 5)
    });

  } catch (error) {
    console.error('Error getting user ratings:', error);
    return c.json({ error: 'Failed to get user ratings' }, 500);
  }
});

// Auto-moderation function to check and block users based on reports
async function checkAndAutoBlockUser(db: any, reportedUserEmail: string, severity: string): Promise<void> {
  try {
    // Get all pending reports for this user
    const reportsQuery = await db.collection('reports')
      .where('reportedUserEmail', '==', reportedUserEmail)
      .where('status', '==', 'pending')
      .get();

    const reports = reportsQuery.docs.map((doc: any) => doc.data());
    
    // Calculate severity scores
    let severityScore = 0;
    reports.forEach((report: any) => {
      switch (report.severity) {
        case 'Low': severityScore += 1; break;
        case 'Medium': severityScore += 2; break;
        case 'High': severityScore += 4; break;
        case 'Critical': severityScore += 8; break;
      }
    });

    // Auto-block thresholds
    const CRITICAL_THRESHOLD = 8; // 1 critical report
    const HIGH_THRESHOLD = 12; // 3 high reports or mix
    const MEDIUM_THRESHOLD = 10; // 5 medium reports

    let shouldBlock = false;
    let blockReason = '';

    if (severityScore >= CRITICAL_THRESHOLD) {
      // Check if there's at least one critical report
      const hasCritical = reports.some((report: any) => report.severity === 'Critical');
      if (hasCritical) {
        shouldBlock = true;
        blockReason = 'Critical safety violation reported';
      } else if (severityScore >= HIGH_THRESHOLD) {
        shouldBlock = true;
        blockReason = 'Multiple high-severity reports';
      }
    } else if (severityScore >= MEDIUM_THRESHOLD) {
      shouldBlock = true;
      blockReason = 'Multiple reports received';
    }

    if (shouldBlock) {
      // Find user by email and block them
      const usersQuery = await db.collection('users')
        .where('email', '==', reportedUserEmail)
        .limit(1)
        .get();

      if (!usersQuery.empty) {
        const userDoc = usersQuery.docs[0];
        if (userDoc) {
          await userDoc.ref.update({
            blocked: true,
            blockedAt: new Date().toISOString(),
            blockReason: blockReason
          });

          // Update all related reports to 'auto-resolved'
          const batch = db.batch();
          reports.forEach((_: any, index: number) => {
            const reportDoc = reportsQuery.docs[index];
            if (reportDoc) {
              batch.update(reportDoc.ref, {
                status: 'auto-resolved',
                resolvedAt: new Date().toISOString(),
                resolution: `User auto-blocked due to ${blockReason.toLowerCase()}`
              });
            }
          });
          await batch.commit();

          console.log(`User ${reportedUserEmail} auto-blocked due to: ${blockReason}`);
        }
      }
    }
  } catch (error) {
    console.error('Error in auto-moderation check:', error);
  }
}

// Update user rating function
async function updateUserRating(db: any, userEmail: string, newRating: number): Promise<void> {
  try {
    const userRatingsRef = db.collection('userRatings').doc(userEmail);
    const userRatingDoc = await userRatingsRef.get();

    if (userRatingDoc.exists) {
      // Update existing rating
      const data = userRatingDoc.data()!;
      const currentTotal = data.totalRating || 0;
      const currentCount = data.ratingCount || 0;
      const newTotal = currentTotal + newRating;
      const newCount = currentCount + 1;

      await userRatingsRef.update({
        totalRating: newTotal,
        ratingCount: newCount,
        averageRating: newTotal / newCount,
        lastUpdated: new Date().toISOString()
      });
    } else {
      // Create new rating record
      await userRatingsRef.set({
        userEmail,
        totalRating: newRating,
        ratingCount: 1,
        averageRating: newRating,
        createdAt: new Date().toISOString(),
        lastUpdated: new Date().toISOString()
      });
    }
  } catch (error) {
    console.error('Error updating user rating:', error);
  }
}

// Calculate trust score
function calculateTrustScore(averageRating: number, feedbackCount: number, hasPendingReports: boolean): number {
  // Base score from rating (0-100 scale)
  let score = averageRating * 20; // Convert 5-star to 100-point scale

  // Boost for having more feedback (social proof)
  if (feedbackCount >= 10) {
    score += 5;
  } else if (feedbackCount >= 5) {
    score += 3;
  } else if (feedbackCount >= 1) {
    score += 1;
  }

  // Penalty for pending reports
  if (hasPendingReports) {
    score -= 15;
  }

  // Ensure score is between 0-100
  return Math.max(0, Math.min(100, score));
}

export { reportFeedbackController };
