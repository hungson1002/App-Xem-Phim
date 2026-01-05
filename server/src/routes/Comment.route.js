import express from 'express';
import {
  addComment,
  getCommentsByMovie,
  deleteComment,
  updateComment
} from '../controllers/Comment.controller.js';
import { verifyToken } from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/:movieId', getCommentsByMovie);
router.post('/add', verifyToken, addComment);

router.delete('/:movieId/:commentId', verifyToken, deleteComment);
router.put('/:movieId/:commentId', verifyToken, updateComment);

export default router;