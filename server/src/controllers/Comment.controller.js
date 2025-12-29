import Comment from '../models/Comment.model.js';

// 1. Lấy tất cả bình luận của một bộ phim
export const getCommentsByMovie = async (req, res) => {
  try {
    const { movieId } = req.params;

    // Tìm document của phim này
    // populate 'comments.userId' để lấy tên và avatar người dùng bên trong mảng
    const movieData = await Comment.findOne({ movieId })
      .populate({
        path: 'comments.userId',
        select: 'name avatar' // Chỉ lấy field cần thiết
      });

    // Nếu phim chưa có trong collection comments -> Trả về mảng rỗng
    if (!movieData) {
      return res.status(200).json({ success: true, data: [] });
    }

    // Sắp xếp bình luận mới nhất lên đầu (Client thường thích mới nhất ở trên)
    // Lưu ý: data trả về là mảng `comments` bên trong, không phải cả object phim
    const sortedComments = movieData.comments.sort((a, b) => b.createdAt - a.createdAt);

    res.status(200).json({ success: true, data: sortedComments });
  } catch (error) {
    console.error("Get comments error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// 2. Thêm bình luận mới (Dùng $push thay vì save)
export const addComment = async (req, res) => {
  console.log("=== Add Comment Request (Embed Mode) ===");
  try {
    const { movieId, content } = req.body;

    // Lấy userId (giữ nguyên logic của bạn)
    const userId = req.authId || req.userId;

    if (!content) {
      return res.status(400).json({ success: false, message: 'Nội dung không được để trống' });
    }
    if (!userId) {
       return res.status(401).json({ success: false, message: 'Không tìm thấy User ID' });
    }

    // Tạo object bình luận con
    const newCommentItem = {
      userId: userId,
      content: content,
      createdAt: new Date()
    };

    // LOGIC MỚI:
    // Tìm phim theo movieId.
    // - Nếu thấy: $push (đẩy) comment mới vào mảng comments.
    // - Nếu chưa thấy: Tự tạo document mới cho phim này (nhờ upsert: true).
    const updatedMovie = await Comment.findOneAndUpdate(
      { movieId: movieId },
      { $push: { comments: newCommentItem } },
      {
        new: true,    // Trả về dữ liệu mới sau khi update
        upsert: true  // Nếu chưa có phim này thì tạo mới
      }
    ).populate('comments.userId', 'name avatar');

    // Lấy đúng cái comment vừa thêm vào để trả về cho App (là cái cuối cùng trong mảng)
    const justAdded = updatedMovie.comments[updatedMovie.comments.length - 1];

    console.log("Comment pushed successfully to movie:", movieId);

    // App Flutter chỉ cần nhận lại 1 object comment vừa thêm để hiện lên màn hình
    res.status(201).json({ success: true, data: justAdded });

  } catch (error) {
    console.error("Add comment error details:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};