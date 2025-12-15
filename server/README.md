# Movie App Backend - Hướng dẫn thiết lập

## Yêu cầu hệ thống
- Node.js (phiên bản 16 trở lên)
- MongoDB (local hoặc MongoDB Atlas)
- npm hoặc yarn

## Các bước thiết lập

### 1. Cài đặt Node.js
Tải và cài đặt từ: https://nodejs.org/
```bash
# Kiểm tra phiên bản
node --version
npm --version
```

### 2. Cài đặt MongoDB

**Cách 1: MongoDB Local**
- Tải MongoDB Community Server: https://www.mongodb.com/try/download/community
- Cài đặt và chạy MongoDB service

**Cách 2: MongoDB Atlas (Cloud - Khuyến nghị cho người mới)**
- Đăng ký tài khoản miễn phí tại: https://www.mongodb.com/cloud/atlas
- Tạo cluster mới (chọn free tier)
- Lấy connection string (dạng: mongodb+srv://...)

### 3. Cài đặt dependencies

```bash
# Di chuyển vào thư mục be
cd be

# Cài đặt các package
npm install
```

### 4. Cấu hình môi trường

```bash
# Copy file .env.example thành .env
copy .env.example .env

# Mở file .env và chỉnh sửa:
# - MONGODB_URI: Thay bằng connection string của bạn
# - JWT_SECRET: Đổi thành chuỗi bí mật ngẫu nhiên
# - PORT: Cổng server (mặc định 5000)
```

### 5. Chạy server

```bash
# Development mode (tự động restart khi có thay đổi)
npm run dev

# Production mode
npm start
```

Server sẽ chạy tại: http://localhost:5000

## Cấu trúc thư mục

```
be/
├── src/
│   ├── config/          # Cấu hình database, JWT
│   ├── controllers/     # Xử lý logic nghiệp vụ
│   ├── models/          # Schema database (User, Movie, Comment, etc.)
│   ├── routes/          # Định nghĩa API endpoints
│   ├── middleware/      # Authentication, validation, error handling
│   ├── utils/           # Helper functions
│   └── server.js        # Entry point
├── uploads/             # Thư mục lưu file upload (nếu có)
├── .env                 # Biến môi trường (không commit lên git)
├── .env.example         # Template cho .env
├── .gitignore
├── package.json
└── README.md
```

## API Endpoints (sẽ được tạo)

### Authentication
- POST `/api/auth/register` - Đăng ký
- POST `/api/auth/login` - Đăng nhập
- GET `/api/auth/profile` - Lấy thông tin user (cần token)

### Movies
- GET `/api/movies` - Lấy danh sách phim
- GET `/api/movies/:id` - Lấy chi tiết phim
- POST `/api/movies` - Thêm phim (admin)
- PUT `/api/movies/:id` - Cập nhật phim (admin)
- DELETE `/api/movies/:id` - Xóa phim (admin)

### Comments
- GET `/api/comments/:movieId` - Lấy bình luận của phim
- POST `/api/comments` - Thêm bình luận (cần token)
- DELETE `/api/comments/:id` - Xóa bình luận (cần token)

### Bookmarks
- GET `/api/bookmarks` - Lấy danh sách phim đã lưu (cần token)
- POST `/api/bookmarks` - Thêm phim vào danh sách (cần token)
- DELETE `/api/bookmarks/:movieId` - Xóa khỏi danh sách (cần token)

## Test API
Dùng Postman hoặc Thunder Client (VS Code extension) để test các API endpoints

## Lưu ý
- File .env không được commit lên git (đã có trong .gitignore)
- Đổi JWT_SECRET thành chuỗi phức tạp trước khi deploy production
- Cài thêm package nếu cần: `npm install package-name`
