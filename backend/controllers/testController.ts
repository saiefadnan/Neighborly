import type { Context } from "hono";
import { Firestore, getFirestore } from "firebase-admin/firestore";

export const Test = async(c:Context)=>{
    try{
        const {email} = await c.req.json();
        const db = getFirestore();

        await db.collection('test').add({  
            data: email,
            timestamp: new Date().toISOString()
         });
         console.log("Message stored:", email);
         return c.json({ success: true, message: "Stored in Firebase!" });
    }catch(err){
        console.error('Error in Test controller:', err);
        return c.json({ error: "Something went wrong" }, 500);
    }
}