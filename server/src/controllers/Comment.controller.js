import Comment from '../models/Comment.model.js';

// 1. Lấy tất cả bình luận của một bộ phim
export const getCommentsByMovie = async (req, res) => {
  try {
    const { movieId } = req.params;

    const movieData = await Comment.findOne({ movieId })
      .populate({
        path: 'comments.userId',
        select: 'name avatar'
      });

    if (!movieData) {
      return res.status(200).json({ success: true, data: [] });
    }

    const sortedComments = movieData.comments.sort((a, b) => b.createdAt - a.createdAt);

    res.status(200).json({ success: true, data: sortedComments });
  } catch (error) {
    console.error("Get comments error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// 2. Thêm bình luận mới
export const addComment = async (req, res) => {
  try {
    const { movieId, content } = req.body;

    const userId = req.authID || req.userId;

    if (!content) {
      return res.status(400).json({ success: false, message: 'Nội dung không được để trống' });
    }
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Không tìm thấy User ID' });
    }

    const newCommentItem = {
      userId: userId,
      content: content,
      createdAt: new Date()
    };

    const updatedMovie = await Comment.findOneAndUpdate(
      { movieId: movieId },
      { $push: { comments: newCommentItem } },
      {
        new: true,
        upsert: true
      }
    ).populate('comments.userId', 'name avatar');

    const justAdded = updatedMovie.comments[updatedMovie.comments.length - 1];

    res.status(201).json({ success: true, data: justAdded });

  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// 3. Xóa bình luận
export const deleteComment = async (req, res) => {
  try {
    const { movieId, commentId } = req.params;
    const userId = req.authID || req.userId;

    const updatedMovie = await Comment.findOneAndUpdate(
      { movieId: movieId },
      {
        $pull: {
          comments: { _id: commentId, userId: userId }
        }
      },
      { new: true }
    );

    if (!updatedMovie) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy bình luận hoặc bạn không có quyền xóa' });
    }

    res.status(200).json({ success: true, message: 'Đã xóa bình luận' });

  } catch (error) {
    console.error("Delete error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// 4. Sửa bình luận
export const updateComment = async (req, res) => {
  try {
    const { movieId, commentId } = req.params;
    const { content } = req.body;
    const userId = req.authID || req.userId;

    if (!content) return res.status(400).json({ success: false, message: 'Nội dung trống' });

    const updatedMovie = await Comment.findOneAndUpdate(
      {
        movieId: movieId,
        "comments._id": commentId,
        "comments.userId": userId
      },
      {
        $set: {
          "comments.$.content": content,
          "comments.$.updatedAt": new Date()
        }
      },
      { new: true }
    );

    if (!updatedMovie) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy hoặc không có quyền sửa' });
    }

    const editedComment = updatedMovie.comments.find(c => c._id.toString() === commentId);

    res.status(200).json({ success: true, data: editedComment });

  } catch (error) {
    console.error("Update error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};