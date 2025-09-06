import { Hono } from 'hono';
import communityBlockService from '../services/communityBlockService';

const blockRoutes = new Hono();

// Block a user in a community
blockRoutes.post('/communities/:communityId/members/:userEmail/block', async (c) => {
  try {
    const { communityId, userEmail } = c.req.param();
    const adminEmail = c.req.header('admin-email'); // In real app, get from auth token
    
    if (!adminEmail) {
      return c.json({ success: false, message: 'Admin authentication required' }, 401);
    }

    const blockData = await c.req.json();
    
    // Validate required fields
    if (!blockData.blockType || !blockData.reason) {
      return c.json({ 
        success: false, 
        message: 'Block type and reason are required' 
      }, 400);
    }

    const result = await communityBlockService.blockUserInCommunity(
      adminEmail,
      communityId,
      userEmail,
      blockData
    );

    return c.json(result);
  } catch (error) {
    console.error('Error in block route:', error);
    return c.json({ 
      success: false, 
      message: 'Internal server error' 
    }, 500);
  }
});

// Unblock a user in a community
blockRoutes.delete('/communities/:communityId/members/:userEmail/block', async (c) => {
  try {
    const { communityId, userEmail } = c.req.param();
    const adminEmail = c.req.header('admin-email');
    
    if (!adminEmail) {
      return c.json({ success: false, message: 'Admin authentication required' }, 401);
    }

    const result = await communityBlockService.unblockUserInCommunity(
      adminEmail,
      communityId,
      userEmail
    );

    return c.json(result);
  } catch (error) {
    console.error('Error in unblock route:', error);
    return c.json({ 
      success: false, 
      message: 'Internal server error' 
    }, 500);
  }
});

// Remove user from community (without blocking)
blockRoutes.delete('/communities/:communityId/members/:userEmail', async (c) => {
  try {
    const { communityId, userEmail } = c.req.param();
    const adminEmail = c.req.header('admin-email');
    
    if (!adminEmail) {
      return c.json({ success: false, message: 'Admin authentication required' }, 401);
    }

    const result = await communityBlockService.removeUserFromCommunity(
      adminEmail,
      communityId,
      userEmail
    );

    return c.json(result);
  } catch (error) {
    console.error('Error in remove route:', error);
    return c.json({ 
      success: false, 
      message: 'Internal server error' 
    }, 500);
  }
});

// Check if user is blocked in a community
blockRoutes.get('/communities/:communityId/members/:userEmail/block-status', async (c) => {
  try {
    const { communityId, userEmail } = c.req.param();
    console.log(`Checking block status for ${userEmail} in ${communityId}`);

    const result = await communityBlockService.isUserBlockedInCommunity(
      userEmail,
      communityId
    );

    return c.json({ success: true, data: result });
  } catch (error) {
    console.error('Error checking block status:', error);
    return c.json({ 
      success: false, 
      message: 'Internal server error',
      error: error instanceof Error ? error.message : String(error)
    }, 500);
  }
});

// Get all active blocks for a community (admin only)
blockRoutes.get('/communities/:communityId/blocks', async (c) => {
  try {
    const { communityId } = c.req.param();
    const adminEmail = c.req.header('admin-email');
    
    if (!adminEmail) {
      return c.json({ success: false, message: 'Admin authentication required' }, 401);
    }

    const blocks = await communityBlockService.getCommunityBlocks(communityId);

    return c.json({ success: true, data: blocks });
  } catch (error) {
    console.error('Error fetching community blocks:', error);
    return c.json({ 
      success: false, 
      message: 'Internal server error' 
    }, 500);
  }
});

// Process expired blocks (can be called by cron job)
blockRoutes.post('/admin/process-expired-blocks', async (c) => {
  try {
    await communityBlockService.processExpiredBlocks();
    return c.json({ success: true, message: 'Expired blocks processed' });
  } catch (error) {
    console.error('Error processing expired blocks:', error);
    return c.json({ 
      success: false, 
      message: 'Internal server error' 
    }, 500);
  }
});

export default blockRoutes;
