import { v2 as cloudinary } from 'cloudinary';
import { firestore } from 'firebase-admin';
import { Firestore, getFirestore } from 'firebase-admin/firestore';
import type { Context } from 'hono';
import { SignatureKind } from 'typescript';
import { v4 as uuidv4 } from 'uuid';


cloudinary.config({
  cloud_name: process.env.CLOUD_NAME,
  api_key: process.env.API_KEY,
  api_secret: process.env.API_SECRET,
});

export const generateUploadSignature = async(c:Context)=>{
    console.log('hello');
    try{
    const publicId = `posts/media_${uuidv4()}`;
    const timestamp = Math.floor(Date.now()/1000);
    const signature = cloudinary.utils.api_sign_request({
        timestamp,
        public_id: publicId
    },
        process.env.API_SECRET!
    );
    console.log(signature);
    return c.json({
        signature: signature,
        timestamp: timestamp,
        public_id: publicId,
        apiKey: process.env.API_KEY,
        cloudName: process.env.CLOUD_NAME
    });}catch(e){
        return c.json({message: 'error occured!'});
    }
}

export const storeComments = async(c:Context)=>{
    try {
        const commentData = await c.req.json();
        const { postID, authorID, content, commentID} = commentData;
        if (!postID || !authorID || !content || !commentID) {
          return c.json({ success: false, message: 'Invalid data' }, 400);
        }
        const data ={
            ...commentData,
            'createdAt': new Date().toISOString()
        }
        console.log('Received comment:', data);
        getFirestore().collection('posts').doc(postID).collection('comments').doc(commentID).set(data);
        return c.json({ success: true, message: 'Comment stored successfully' });
      } catch (error) {
        // Handle errors (e.g., invalid JSON)
        console.error('Error processing request:', error);
        return c.json({ success: false, message: 'Failed to process request' }, 500);
      }
}