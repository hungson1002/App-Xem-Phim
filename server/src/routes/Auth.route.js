import express from 'express';
import { ForgotPassword, GoogleLogin, Login, Register, ResendVerifyOTP, ResetPassword, VerifyEmail } from '../controllers/Auth.controller.js';
const router = express.Router();

router.post('/register', Register);
router.post('/login', Login);
router.post('/verify-email', VerifyEmail);
router.post('/google-login', GoogleLogin);
router.post('/resend-verify-otp', ResendVerifyOTP);
router.post('/forgot-password', ForgotPassword);
router.post('/reset-password', ResetPassword);

export default router;