import Comment from '../models/Comment.model.js';

// Lấy tất cả bình luận cho một bộ phim
export const getCommentsByMovie = async (req, res) => {
  try {
    const { movieId } = req.params;
    const comments = await Comment.find({ movieId }).sort({ createdAt: -1 });
    res.status(200).json({ success: true, data: comments });
  } catch (error) {
    console.error("Get comments error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// Thêm bình luận mới
export const addComment = async (req, res) => {
  console.log("=== Add Comment Request ===");
  try {
    const { movieId, content } = req.body;
    
    // Lấy userId từ req.authId (do middleware gán)
    const userId = req.authId; 
    
    console.log("User ID:", userId);
    console.log("Body:", req.body);

    if (!content) {
      return res.status(400).json({ success: false, message: 'Nội dung bình luận không được để trống' });
    }
    
    if (!userId) {
       return res.status(401).json({ success: false, message: 'Không tìm thấy thông tin người dùng từ token' });
    }

    const newComment = new Comment({ userId, movieId, content });
    await newComment.save();
    console.log("Comment saved:", newComment._id);

    // Populate lại thông tin user sau khi lưu
    const populatedComment = await Comment.findById(newComment._id);
    console.log("Comment populated successfully");

    res.status(201).json({ success: true, data: populatedComment });
  } catch (error) {
    console.error("Add comment error details:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};
