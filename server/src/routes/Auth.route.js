import express from 'express';
import { GoogleLogin, Login, Register, VerifyEmail } from '../controllers/Auth.controller.js';
const router = express.Router();

router.post('/register', Register);
router.post('/login', Login);
router.post('/verify-email', VerifyEmail);
router.post('/google-login', GoogleLogin);

export default router;