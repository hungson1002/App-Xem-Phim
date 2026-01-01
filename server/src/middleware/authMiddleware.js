import jwt from 'jsonwebtoken';

export const verifyToken = (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ success: false, message: "No token provided" });
        }

        const token = authHeader.split(' ')[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        console.log("Check Token Decoded:", decoded);

        req.authID = decoded.id || decoded._id || decoded.userId || decoded.authID;

        if (!req.authID) {
            console.log("Lỗi: Token hợp lệ nhưng không tìm thấy ID user bên trong!");
            return res.status(403).json({ success: false, message: "Token malformed: Missing ID" });
        }

        next();
    } catch (error) {
        console.log("Lỗi Middleware:", error.message);
        return res.status(401).json({ success: false, message: "Invalid token" });
    }
}