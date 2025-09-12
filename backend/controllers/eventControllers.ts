import { FieldValue, getFirestore } from "firebase-admin/firestore";
import type { Context } from "hono";

export const loadevents = async(c: Context)=>{
   try{
    console.log('loading events...');
      const {uid} = await c.req.json();
      const snapshot = await getFirestore().collection('events').orderBy('createdAt', 'desc').get();
      const joinedSnapshot =
          await getFirestore()
              .collectionGroup('participants')
              .where(
                'memberId',
                '==',uid
              )
              .get();
      const events = snapshot.docs.map((doc)=> doc.data());
      const joinedEventIds = joinedSnapshot.docs.map((doc)=> doc.data());
      console.log(events);
      console.log(joinedEventIds);
 return c.json({ success: true, eventData: events ,joinedIds:  joinedEventIds}, 200);
      
  }catch (e){
      console.error('Error processing request:', e);
      return c.json({ success: false, eventData: [] }, 500);
  }
}

export const storevents = async(c: Context)=>{
  try {
      const {event}= await c.req.json();
      console.log('storing event...',event);
      const docRef = getFirestore().collection('events').doc();
      await docRef.set({...event, 'id': docRef.id, 'createdAt': new Date(event.createdAt), 'date':new Date(event.date) });
       return c.json({ success: true, eventId: docRef.id}, 200);
    } catch (e) {
       console.error('Error processing request:', e);
      return c.json({ success: false}, 500);
    }
}