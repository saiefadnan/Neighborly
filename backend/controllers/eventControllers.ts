import { getFirestore } from "firebase-admin/firestore";
import type { Context } from "hono";

export const loadevents = async(c: Context)=>{
   try{
    console.log('loading events...');
      const snapshot = await getFirestore().collection('events').orderBy('timestamp', 'desc').get();
      const events = snapshot.docs.map((doc)=> doc.data());
 return c.json({ success: true, eventData: events }, 200);
      
  }catch (e){
      console.error('Error processing request:', e);
      return c.json({ success: false, post: [] }, 500);
  }
}

export const storevents = async(c: Context)=>{
  try{
 console.log('storing events...');
  }catch (e){
    
  }
}