import express from 'express';
import { createMovie, deleteMovie, getAllMovies, getMovieBySlug, updateMovie, getMoviesByCategory, getMoviesByCountry, getMoviesByYear, getMoviesLimit, searchMovies } from '../controllers/Movie.controller.js';

const router = express.Router();

router.get('/', getAllMovies);
router.get('/search', searchMovies);
router.get('/category/:slug', getMoviesByCategory);
router.get('/country/:slug', getMoviesByCountry);
router.get('/year/:year', getMoviesByYear);
router.get('/limit/:limit', getMoviesLimit);
router.get('/:slug', getMovieBySlug);
router.post('/', createMovie);
router.put('/:id', updateMovie);
router.delete('/:id', deleteMovie);

export default router;
