import { Hono } from 'hono';
import { generateUploadSignature, likeComments, likePosts, loadComments, loadNearbyPosts, loadExplorePosts, pollVote, storeComments, storePosts } from '../controllers/forumControllers';

const forumRouter = new Hono();

forumRouter.get('/upload/signature', generateUploadSignature);
forumRouter.post('/store/comments', storeComments);
forumRouter.post('/store/posts', storePosts);
forumRouter.post('/load/comments', loadComments);
forumRouter.post('/load/explore/posts', loadExplorePosts);
forumRouter.post('/load/nearby/posts', loadNearbyPosts);
forumRouter.post('/like/comments', likeComments);
forumRouter.post('/like/posts', likePosts);
forumRouter.post('/poll/vote', pollVote);
export default forumRouter;