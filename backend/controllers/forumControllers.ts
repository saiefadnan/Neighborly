import { v2 as cloudinary } from 'cloudinary';
import { firestore } from 'firebase-admin';
import { FieldValue, Firestore, getFirestore } from 'firebase-admin/firestore';
import type { Context } from 'hono';
import { SignatureKind } from 'typescript';
import { v4 as uuidv4 } from 'uuid';


cloudinary.config({
  cloud_name: process.env.CLOUD_NAME,
  api_key: process.env.API_KEY,
  api_secret: process.env.API_SECRET,
});

export const generateUploadSignature = async(c:Context)=>{
    console.log('uploading content...');
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

export const storePosts = async(c: Context)=>{
 try {
      const {post} = await c.req.json();
      console.log('storing post: ', post);
      const docRef = getFirestore().collection('posts').doc();
      await docRef.set({...post, 'postID': docRef.id,'timestamp': FieldValue.serverTimestamp(),});
      console.log('Post stored with ID: ', docRef.id);
       return c.json({ success: true, postID: docRef.id}, 200);

    } catch (e) {
      console.log('Error storing posts: $e');
      return c.json({ success: false}, 500);
    }
}



export const loadComments = async(c: Context)=>{
try{
    console.log('loading comments...');
      const {postID} = await c.req.json();
      console.log(postID);
      const snapshot = await getFirestore().collection('posts').doc(postID).collection('comments').orderBy('createdAt', 'desc').get();
      const comments = snapshot.docs.map((doc)=> doc.data());
 return c.json({ success: true, commentData: comments }, 200);
      
  }catch (e){
      console.error('Error processing request:', e);
      return c.json({ success: false, commentData: [] }, 500);
  }
}


export const loadPosts = async(c: Context)=>{
  try{
    console.log('loading explore posts...');
      const {location} = await c.req.json();
      console.log(location);
      const snapshot = await getFirestore().collection('posts').where('location.name','!=',location).orderBy('timestamp', 'desc').get();
      const posts = snapshot.docs.map((doc)=> doc.data());
 return c.json({ success: true, postData: posts }, 200);
      
  }catch (e){
      console.error('Error processing request:', e);
      return c.json({ success: false, postData: [] }, 500);
  }
}


export const loadNearbyPosts = async(c: Context)=>{
  try{
    console.log('loading nearby posts...');
      const {location} = await c.req.json();
      console.log(location);
      const snapshot = await getFirestore().collection('posts').where('location.name','==',location).orderBy('timestamp', 'desc').get();
      const posts = snapshot.docs.map((doc)=> doc.data());
 return c.json({ success: true, postData: posts }, 200);
      
  }catch (e){
      console.error('Error processing request:', e);
      return c.json({ success: false, postData: [] }, 500);
  }
}

export const likePosts = async(c: Context)=>{
  try{
      console.log('like/unlike posts...');
  }catch(e){
    
  }
}

export const likeComments = async(c: Context)=>{
  try{
     console.log('like/unlike comments...');
  }catch(e){
    
  }
}

export const pollVote = async(c: Context)=>{
  try{
       console.log('poll votes...');
  }catch(e){
    
  }
}