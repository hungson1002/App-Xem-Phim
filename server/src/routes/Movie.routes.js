import express from 'express';
import { createMovie, deleteMovie, getAllMovies, getMovieBySlug, updateMovie, getMoviesByCategory, getMoviesByCountry, getMoviesByYear } from '../controllers/Movie.controller.js';

const router = express.Router();

router.get('/', getAllMovies);
router.get('/category/:slug', getMoviesByCategory);
router.get('/country/:slug', getMoviesByCountry);
router.get('/year/:year', getMoviesByYear);
router.get('/:slug', getMovieBySlug);
router.post('/', createMovie);
router.put('/:id', updateMovie);
router.delete('/:id', deleteMovie);

export default router;
