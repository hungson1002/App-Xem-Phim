import express from 'express';
import {
    createWatchRoom,
    getWatchRooms,
    getWatchRoom,
    updateWatchRoom,
    deleteWatchRoom,
    getChatHistory,
    getMyWatchRooms
} from '../controllers/watchRoomController.js';
import { verifyToken } from '../middleware/authMiddleware.js';
import { body, param, query } from 'express-validator';
import { handleValidationErrors } from '../middleware/validation.middleware.js';

const router = express.Router();

// Validation rules
const createRoomValidation = [
    body('movieId').notEmpty().withMessage('Movie ID là bắt buộc'),
    body('episodeSlug').notEmpty().withMessage('Episode slug là bắt buộc'),
    body('title').optional().isLength({ min: 1, max: 100 }).withMessage('Tiêu đề phải từ 1-100 ký tự'),
    body('description').optional().isLength({ max: 500 }).withMessage('Mô tả không được quá 500 ký tự'),
    body('maxUsers').optional().isInt({ min: 2, max: 100 }).withMessage('Số người tối đa từ 2-100'),
    body('password').custom((value, { req }) => {
        if (req.body.isPrivate && (!value || value.length < 4 || value.length > 20)) {
            throw new Error('Mật khẩu từ 4-20 ký tự khi phòng riêng tư');
        }
        return true;
    })
];

const updateRoomValidation = [
    param('roomId').isUUID().withMessage('Room ID không hợp lệ'),
    body('title').optional().isLength({ min: 1, max: 100 }).withMessage('Tiêu đề phải từ 1-100 ký tự'),
    body('description').optional().isLength({ max: 500 }).withMessage('Mô tả không được quá 500 ký tự'),
    body('maxUsers').optional().isInt({ min: 2, max: 100 }).withMessage('Số người tối đa từ 2-100')
];

const roomIdValidation = [
    param('roomId').notEmpty().withMessage('Room ID là bắt buộc')
];

const paginationValidation = [
    query('page').optional().isInt({ min: 1 }).withMessage('Page phải là số nguyên dương'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit từ 1-100')
];

// Routes
// Tạo phòng xem mới
router.post('/',
    verifyToken,
    createRoomValidation,
    handleValidationErrors,
    createWatchRoom
);

// Lấy danh sách phòng xem công khai
router.get('/',
    paginationValidation,
    handleValidationErrors,
    getWatchRooms
);

// Lấy phòng xem của user hiện tại
router.get('/my-rooms',
    verifyToken,
    query('type').optional().isIn(['hosting', 'joined']).withMessage('Type phải là hosting hoặc joined'),
    handleValidationErrors,
    getMyWatchRooms
);

// Lấy thông tin chi tiết phòng xem
router.get('/:roomId',
    roomIdValidation,
    handleValidationErrors,
    getWatchRoom
);

// Cập nhật cài đặt phòng xem (chỉ host)
router.put('/:roomId',
    verifyToken,
    updateRoomValidation,
    handleValidationErrors,
    updateWatchRoom
);

// Xóa phòng xem (chỉ host)
router.delete('/:roomId',
    verifyToken,
    roomIdValidation,
    handleValidationErrors,
    deleteWatchRoom
);

// Lấy lịch sử chat của phòng
router.get('/:roomId/chat',
    verifyToken,
    roomIdValidation,
    paginationValidation,
    handleValidationErrors,
    getChatHistory
);

export default router;