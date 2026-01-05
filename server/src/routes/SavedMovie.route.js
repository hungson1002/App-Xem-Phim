import express from "express";
import { getSavedMovies, removeMovie, saveMovie } from "../controllers/SavedMovie.controller.js";
import { verifyToken } from "../middleware/authMiddleware.js";

const router = express.Router();

router.post('/', verifyToken, saveMovie);
router.delete('/:movieID', verifyToken, removeMovie);
router.get('/', verifyToken, getSavedMovies);

export default router;
