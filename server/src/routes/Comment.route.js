import express from 'express';
import { addComment, getCommentsByMovie } from '../controllers/Comment.controller.js';
// Nhớ import đúng tên verifyToken mới sửa
import { verifyToken } from '../middleware/authMiddleware.js';

// ✅ QUAN TRỌNG: Phải khai báo router ngay dòng này, trước khi dùng nó
const router = express.Router();

// Sau đó mới được định nghĩa routes
router.get('/:movieId', getCommentsByMovie);
router.post('/add', verifyToken, addComment); // Dòng này lúc nãy bị lỗi do router chưa có

export default router;