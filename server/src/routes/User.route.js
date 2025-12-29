import express from "express";
import { deleteUser, getAllUser, getUser, updateUser } from "../controllers/User.controller.js";

// ✅ 1. Sửa dòng import này (đổi authMiddleware thành verifyToken)
import { verifyToken } from "../middleware/authMiddleware.js";

const router = express.Router();

// ✅ 2. Sửa tên middleware trong các dòng dưới đây
router.get("/", verifyToken, getAllUser);
router.get("/:id", verifyToken, getUser);
router.put("/:id", verifyToken, updateUser);
router.delete("/:id", verifyToken, deleteUser);

export default router;