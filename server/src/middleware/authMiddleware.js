import jwt from 'jsonwebtoken';

export const verifyToken = (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ success: false, message: "No token provided" });
        }

        const token = authHeader.split(' ')[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // --- QUAN TRỌNG: In ra để kiểm tra xem Token chứa key gì ---
        console.log("🔥 Check Token Decoded:", decoded);

        // Thử lấy ID từ các key phổ biến (id, _id, userId, authID)
        // Dù lúc Login bạn lưu tên gì thì dòng này cũng bắt được hết
        req.authId = decoded.id || decoded._id || decoded.userId || decoded.authID;

        if (!req.authId) {
            console.log("❌ Lỗi: Token hợp lệ nhưng không tìm thấy ID user bên trong!");
            return res.status(403).json({ success: false, message: "Token malformed: Missing ID" });
        }

        next();
    } catch (error) {
        console.log("❌ Lỗi Middleware:", error.message);
        return res.status(401).json({ success: false, message: "Invalid token" });
    }
}