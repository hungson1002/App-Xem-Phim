import express from 'express';
import {
    closeRoom,
    createRoom,
    getRoom,
    getRooms,
    joinRoom,
    leaveRoom
} from '../controllers/WatchRoom.controller.js';
import { verifyToken } from '../middleware/authMiddleware.js';

const router = express.Router();

// All routes require authentication
router.use(verifyToken);

// Create a new room
router.post('/', createRoom);

// Get all active rooms
router.get('/', getRooms);

// Get room by code
router.get('/:code', getRoom);

// Join a room
router.post('/:code/join', joinRoom);

// Leave a room
router.post('/:code/leave', leaveRoom);

// Close a room (host only)
router.delete('/:code', closeRoom);

export default router;
