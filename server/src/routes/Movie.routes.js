import express from 'express';
import { createMovie, deleteMovie, getAllMovies, getMovieBySlug, updateMovie } from '../controllers/Movie.controller.js';

const router = express.Router();

router.get('/', getAllMovies);
router.get('/:slug', getMovieBySlug);
router.post('/', createMovie);
router.put('/:id', updateMovie);
router.delete('/:id', deleteMovie);

export default router;
