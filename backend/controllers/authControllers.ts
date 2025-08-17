import type { Context } from "hono";
import { getAuth } from "firebase-admin/auth";

export const signin = async(c:Context)=>{
    try{
        const authHeader = await c.req.header('Authorization');
        const idToken = authHeader?.replace('Bearer ','');
        
        const decoded = await getAuth().verifyIdToken(idToken!);
        console.log(decoded.uid);
        return c.json({ success: true, message: "Access granted!" },200);
    }catch(err){
        console.error('Error in Test controller:', err);
        return c.json({ success: false, message: "Access denied!" },500);

    }
}