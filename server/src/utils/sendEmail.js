import dotenv from "dotenv";
import nodemailer from "nodemailer";
dotenv.config();

const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
    }
})

export const sendOTPEmail = async (to, otp) => {
    await transporter.sendMail({
        from: `"App Xem Phim" <${process.env.EMAIL_USER}>`,
        to,
        subject: 'Mã xác nhận đăng ký',
        html: `
        <h2 style = "color: #333;">Mã xác nhận của bạn là</h2>
        <h1 style = "color: #333;">${otp}</h1>
        <p style = "color: #333;">Mã có hiệu lực trong 5 phút</p>
        <p style = "color: #333;">Nếu bạn không yêu cầu mã xác nhận này, vui lòng bỏ qua email này</p>
        `
    });
}