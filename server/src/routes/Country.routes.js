import express from 'express';
import { createCountry, deleteCountry, getAllCountries } from '../controllers/Country.controller.js';

const router = express.Router();

router.get('/', getAllCountries);
router.post('/', createCountry);
router.delete('/:id', deleteCountry);

export default router;
