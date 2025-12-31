import express from 'express';
import { createCategory, deleteCategory, getAllCategories } from '../controllers/Category.controller.js';

const router = express.Router();

router.get('/', getAllCategories);
router.post('/', createCategory);
router.delete('/:id', deleteCategory);

export default router;
