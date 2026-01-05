import mongoose from 'mongoose';

const CommentSchema = new mongoose.Schema({
  // movieId là khóa chính để tìm document
  movieId: {
    type: String,
    required: true,
    unique: true // QUAN TRỌNG: Đảm bảo 1 phim chỉ có 1 document chứa list comment
  },
  // Đây là mảng chứa danh sách các bình luận con
  comments: [
    {
      userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Auth', // (Lưu ý: Bạn kiểm tra lại model User của bạn tên là 'Auth' hay 'User' nhé)
        required: true
      },
      content: {
        type: String,
        required: true
      },
      createdAt: {
        type: Date,
        default: Date.now
      }
    }
  ]
}, {
  timestamps: true // Cái này để lưu thời gian tạo/sửa của cái document cha (Movie)
});

const Comment = mongoose.model('Comment', CommentSchema);

export default Comment;