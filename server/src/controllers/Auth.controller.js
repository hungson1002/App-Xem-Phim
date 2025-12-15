
import bcrypt from 'bcryptjs';
import { OAuth2Client } from 'google-auth-library';
import jwt from 'jsonwebtoken';
import Auth from '../models/Auth.model.js';
import { sendOTPEmail } from '../utils/sendEmail.js';

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// Đăng ký
export const Register = async (req, res, next) => {
    try {
        // Lấy dữ liệu từ client gửi lên
        const { name, email, password } = req.body;

        // Kiểm tra email có tồn tại không
        const exitAuth = await Auth.findOne({ email });
        if (exitAuth) {
            return res.status(400).json({
                success: false,
                message: "Email already exists"
            })
        }

        // Mã hóa password
        const salt = await bcrypt.genSalt(10);
        const hashPassword = await bcrypt.hash(password, salt);

        // Tạo mã OTP
        const otp = Math.floor(100000 + Math.random() * 900000).toString();

        // Đặt thời gian hết hạn cho mã OTP
        const otpExpires = Date.now() + 5 * 60 * 1000;

        // Lưu dữ liệu vào mongo
        await Auth.create({
            name,
            email,
            password: hashPassword,
            otp,
            otpExpires,
            isVerified: false
        })

        // Gửi mã OTP qua email
        await sendOTPEmail(email, otp);

        // Trả kết quả cho client
        return res.status(200).json({
            success: true,
            message: "OTP has been sent to your email"
        })

    } catch (error) {
        next(error);
    }
};

// Đăng nhập
export const Login = async (req, res, next) => {
    try {
        //Lấy email và password từ client
        const { email, password } = req.body;

        // Kiểm tra email có tồn tại không
        const auth = await Auth.findOne({ email });
        if (!auth) {
            return res.status(401).json({
                success: false,
                message: "Invalid email or password"
            })
        }

        //So sánh mật khẩu từ client với mật khẩu đã mã hóa trong database
        const isMatch = await bcrypt.compare(password, auth.password);
        if (!isMatch) {
            return res.status(400).json({
                success: false,
                message: "Invalid email or password"
            })
        }

        // Kiểm tra email đã xác nhận chưa
        if (!auth.isVerified) {
            return res.status(400).json({
                success: false,
                message: "Please verify your email"
            })
        }

        // Tạo token
        const token = jwt.sign(
            {
                authID: auth._id
            },
            process.env.JWT_SECRET,
            {
                expiresIn: process.env.JWT_EXPIRE
            }
        )

        // Trả dữ liệu về cho client
        res.status(200).json({
            success: true,
            token,
            auth: {
                id: auth._id,
                name: auth.name,
                email: auth.email
            }
        })
    } catch (error) {
        next(error);
    }
}

// Xác nhận OTP
export const VerifyEmail = async (req, res, next) => {
    try {
        const { email, otp } = req.body;

        //kiểm tra email có tồn tại không
        const auth = await Auth.findOne({ email });
        if (!auth || auth.otp !== otp || auth.otpExpires < Date.now()) {
            return res.status(400).json({
                success: false,
                message: "Invalid or expired OTP"
            })
        }

        // Cập nhật isVerified
        auth.isVerified = true;
        auth.otp = null;
        auth.otpExpires = null;
        await auth.save();

        // Trả kết quả cho client
        return res.status(200).json({
            success: true,
            message: "Email verified successfully"
        })
    } catch (error) {
        next(error);
    }
}

export const GoogleLogin = async (req, res, next) => {
    try {
        // Lấy gg token từ fe
        const { googleToken } = req.body;

        console.log('Google Login - Received token:', googleToken ? 'Yes' : 'No');

        if (!googleToken) {
            return res.status(400).json({
                success: false,
                message: 'Google token is required'
            });
        }

        // Xác thực token với GG
        const ticket = await client.verifyIdToken({
            idToken: googleToken,
            audience: process.env.GOOGLE_CLIENT_ID
        });

        // Lấy dữ liệu người dùng từ GG
        const payload = ticket.getPayload();
        const { email, name, sub: googleId } = payload;

        console.log('Google Login - User info:', { email, name, googleId });

        // Tìm user trong database theo email
        let auth = await Auth.findOne({ email });

        // Kiểm tra email đã tồn tại chưa
        if (auth && auth.provider === 'local') {
            return res.status(400).json({
                success: false,
                message: "Email already registered with password"
            });
        }

        // Tạo user mới nếu chưa tồn tại
        if (!auth) {
            auth = await Auth.create({
                name,
                email,
                googleId,
                avatar: payload.picture,
                provider: 'google',
                isVerified: true
            });
            console.log('Google Login - Created new user:', auth._id);
        } else {
            // Cập nhật avatar nếu user đã tồn tại
            if (payload.picture && !auth.avatar) {
                auth.avatar = payload.picture;
                await auth.save();
            }
            console.log('Google Login - Existing user:', auth._id);
        }

        // Tạo jwt như đăng nhập thường
        const token = jwt.sign(
            {
                authID: auth._id
            },
            process.env.JWT_SECRET,
            {
                expiresIn: process.env.JWT_EXPIRE
            }
        )

        // Trả kết quả cho client
        return res.status(200).json({
            success: true,
            token,
            auth: {
                id: auth._id,
                name: auth.name,
                email: auth.email,
                provider: auth.provider,
                avatar: auth.avatar || payload.picture,
            }
        })
    } catch (error) {
        next(error);
    }
}
