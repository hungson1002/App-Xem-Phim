import express from 'express';
import { verifyToken } from '../middleware/authMiddleware.js';
import {
    getBookmarks,
    addBookmark,
    removeBookmark,
    checkBookmark
} from '../controllers/Bookmark.controller.js';

const router = express.Router();

// All routes require authentication
router.get('/', verifyToken, getBookmarks);
router.post('/', verifyToken, addBookmark);
router.delete('/:movieId', verifyToken, removeBookmark);
router.get('/check/:movieId', verifyToken, checkBookmark);

export default router;
