import Bookmark from '../models/Bookmark.model.js';

// Get all bookmarks for the logged-in user
export const getBookmarks = async (req, res) => {
    try {
        const userId = req.authId;

        const bookmarks = await Bookmark.find({ userId })
            .sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            count: bookmarks.length,
            bookmarks
        });
    } catch (error) {
        console.error('Get bookmarks error:', error);
        res.status(500).json({
            success: false,
            message: 'Lỗi server khi lấy danh sách phim đã lưu'
        });
    }
};

// Add a movie to bookmarks
export const addBookmark = async (req, res) => {
    try {
        const userId = req.authId;
        const { movieId, movieSlug, movieName, posterUrl, year, category } = req.body;

        if (!movieId || !movieSlug || !movieName) {
            return res.status(400).json({
                success: false,
                message: 'Thiếu thông tin phim (movieId, movieSlug, movieName)'
            });
        }

        // Check if already bookmarked
        const existingBookmark = await Bookmark.findOne({ userId, movieId });
        if (existingBookmark) {
            return res.status(400).json({
                success: false,
                message: 'Phim đã có trong danh sách lưu'
            });
        }

        const bookmark = new Bookmark({
            userId,
            movieId,
            movieSlug,
            movieName,
            posterUrl: posterUrl || '',
            year: year || 0,
            category: category || []
        });

        await bookmark.save();

        res.status(201).json({
            success: true,
            message: 'Đã lưu phim thành công',
            bookmark
        });
    } catch (error) {
        console.error('Add bookmark error:', error);
        if (error.code === 11000) {
            return res.status(400).json({
                success: false,
                message: 'Phim đã có trong danh sách lưu'
            });
        }
        res.status(500).json({
            success: false,
            message: 'Lỗi server khi lưu phim'
        });
    }
};

// Remove a movie from bookmarks
export const removeBookmark = async (req, res) => {
    try {
        const userId = req.authId;
        const { movieId } = req.params;

        const bookmark = await Bookmark.findOneAndDelete({ userId, movieId });

        if (!bookmark) {
            return res.status(404).json({
                success: false,
                message: 'Không tìm thấy phim trong danh sách lưu'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Đã xóa phim khỏi danh sách lưu'
        });
    } catch (error) {
        console.error('Remove bookmark error:', error);
        res.status(500).json({
            success: false,
            message: 'Lỗi server khi xóa phim'
        });
    }
};

// Check if a movie is bookmarked
export const checkBookmark = async (req, res) => {
    try {
        const userId = req.authId;
        const { movieId } = req.params;

        const bookmark = await Bookmark.findOne({ userId, movieId });

        res.status(200).json({
            success: true,
            isBookmarked: !!bookmark
        });
    } catch (error) {
        console.error('Check bookmark error:', error);
        res.status(500).json({
            success: false,
            message: 'Lỗi server khi kiểm tra trạng thái lưu'
        });
    }
};
