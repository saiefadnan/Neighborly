import type { Context } from "hono";

let count = 1;
export const Test = async(c:Context)=>{
    try{
        const {message} = await c.req.json();
        console.log(message);
        const data = {message: `Hello from bun+huno! ${count}`};
        count++;
        return c.json(data, 200);
    }catch(err){
        console.error('Error in Test controller:', err);
        return c.json({ error: "Something went wrong" }, 500);
    }
}