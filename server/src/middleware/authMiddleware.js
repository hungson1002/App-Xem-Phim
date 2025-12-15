import jwt from 'jsonwebtoken';

// Midleware kiểm tra đăng nhập
export const authMiddleware = (req, res, next) => {
    try {
        // Lấy header Authorization
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                success: false,
                message: "No token provided"
            })
        }

        // Tách token ra khỏi chuổi Bearer
        const token = authHeader.split(' ')[1];

        // Giải mã token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // Gắn authId vào req để controller khác dùng
        req.authId = decoded.authID;

        // Tiếp tục xử lý request
        next();
    } catch (error) {
        return res.status(401).json({
            success: false,
            message: "Invalid token"
        })
    }
}