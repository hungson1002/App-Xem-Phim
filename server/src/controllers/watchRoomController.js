import WatchRoom from '../models/WatchRoom.model.js';
import ChatMessage from '../models/ChatMessage.model.js';
import Movie from '../models/Movie.model.js';
import Auth from '../models/Auth.model.js';
import { v4 as uuidv4 } from 'uuid';

// Tạo phòng xem mới
export const createWatchRoom = async (req, res) => {
    try {
        const { movieId, episodeSlug, title, description, isPrivate, password, maxUsers } = req.body;
        const hostId = req.authID;

        console.log('🔥 Create room request:', {
            movieId,
            episodeSlug,
            title,
            description,
            isPrivate,
            password: password ? '***' : null,
            maxUsers,
            hostId
        });

        // Kiểm tra movie tồn tại
        const movie = await Movie.findOne({ _id: movieId });
        if (!movie) {
            console.log('❌ Movie not found:', movieId);
            return res.status(404).json({
                success: false,
                message: 'Phim không tồn tại'
            });
        }

        console.log('✅ Movie found:', movie.name);

        // Skip episode validation vì có thể không có episodes data
        // const episode = movie.episodes[0]?.server_data?.find(ep => ep.slug === episodeSlug);
        // if (!episode) {
        //     return res.status(404).json({
        //         success: false,
        //         message: 'Tập phim không tồn tại'
        //     });
        // }

        // Tạo roomId unique
        const roomId = uuidv4();
        console.log('🆔 Generated roomId:', roomId);

        const watchRoom = new WatchRoom({
            roomId,
            movieId,
            episodeSlug,
            hostId,
            title: title || `${movie.name} - Xem cùng nhau`,
            description: description || '',
            isPrivate: isPrivate || false,
            password: isPrivate ? password : null,
            maxUsers: maxUsers || 50,
            currentUsers: [{
                userId: hostId,
                username: req.user?.name || 'Unknown',
                avatar: req.user?.avatar || '',
                isHost: true
            }]
        });

        console.log('💾 Saving room...');
        await watchRoom.save();

        // Populate movie info
        await watchRoom.populate('movieId', 'name poster_url origin_name episodes');

        // Tìm episode thật từ movie data
        const movieData = await Movie.findOne({ _id: movieId });
        let episodeData = null;

        if (movieData && movieData.episodes && movieData.episodes.length > 0) {
            // Tìm episode trong server_data
            for (const episodeGroup of movieData.episodes) {
                if (episodeGroup.server_data) {
                    const foundEpisode = episodeGroup.server_data.find(ep => ep.slug === episodeSlug);
                    if (foundEpisode) {
                        episodeData = foundEpisode;
                        break;
                    }
                }
            }
        }

        // Nếu không tìm thấy episode, tạo mock data
        if (!episodeData) {
            episodeData = {
                name: episodeSlug,
                slug: episodeSlug,
                filename: '',
                link_embed: '',
                link_m3u8: ''
            };
        }

        console.log('✅ Room created successfully:', watchRoom.roomId);
        console.log('📺 Episode data:', episodeData);

        res.status(201).json({
            success: true,
            message: 'Tạo phòng xem thành công',
            data: {
                room: watchRoom,
                episode: episodeData
            }
        });

    } catch (error) {
        console.error('❌ Create watch room error:', error);
        res.status(500).json({
            success: false,
            message: 'Lỗi server khi tạo phòng xem',
            error: error.message
        });
    }
};

// Lấy danh sách phòng xem
export const getWatchRooms = async (req, res) => {
    try {
        const { page = 1, limit = 20, movieId, search } = req.query;
        const skip = (page - 1) * limit;

        // Show all rooms (active and ended), but only public ones
        let query = { isPrivate: false };

        if (movieId) {
            query.movieId = movieId;
        }

        if (search) {
            query.title = { $regex: search, $options: 'i' };
        }

        const rooms = await WatchRoom.find(query)
            .populate('movieId', 'name poster_url origin_name')
            .populate('hostId', 'name avatar')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(parseInt(limit));

        const total = await WatchRoom.countDocuments(query);

        // Thêm thông tin episode cho mỗi room
        const roomsWithEpisodes = await Promise.all(rooms.map(async (room) => {
            const movie = await Movie.findOne({ _id: room.movieId });
            const episode = movie?.episodes[0]?.server_data?.find(ep => ep.slug === room.episodeSlug);

            return {
                ...room.toObject(),
                episode: episode || null,
                userCount: room.currentUsers.length
            };
        }));

        res.json({
            success: true,
            data: {
                rooms: roomsWithEpisodes,
                pagination: {
                    current: parseInt(page),
                    total: Math.ceil(total / limit),
                    count: total
                }
            }
        });

    } catch (error) {
        console.error('Get watch rooms error:', error);
        res.status(500).json({
            success: false,
            message: 'Lỗi server khi lấy danh sách phòng xem'
        });
    }
};

// Lấy thông tin chi tiết phòng xem
export const getWatchRoom = async (req, res) => {
    try {
        const { roomId } = req.params;

        const room = await WatchRoom.findOne({ roomId, status: 'active' })
            .populate('movieId', 'name poster_url origin_name episodes')
            .populate('hostId', 'name avatar')
            .populate('currentUsers.userId', 'name avatar');

        if (!room) {
            return res.status(404).json({
                success: false,
                message: 'Phòng xem không tồn tại'
            });
        }

        // Lấy thông tin episode
        const movie = await Movie.findOne({ _id: room.movieId });
        let episode = null;
        if (movie && movie.episodes && movie.episodes.length > 0) {
            for (const episodeGroup of movie.episodes) {
                if (episodeGroup.server_data) {
                    const foundEpisode = episodeGroup.server_data.find(ep => ep.slug === room.episodeSlug);
                    if (foundEpisode) {
                        episode = foundEpisode;
                        break;
                    }
                }
            }
        }

        if (!episode) {
            episode = {
                name: room.episodeSlug,
                slug: room.episodeSlug,
                filename: '',
                link_embed: '',
                link_m3u8: ''
            };
        }

        res.json({
            success: true,
            data: {
                room,
                episode: episode,
                userCount: room.currentUsers.length
            }
        });

    } catch (error) {
        console.error('Get watch room error:', error);
        res.status(500).json({
            success: false,
            message: 'Lỗi server khi lấy thông tin phòng xem'
        });
    }
};

// Cập nhật cài đặt phòng xem (chỉ host)
export const updateWatchRoom = async (req, res) => {
    try {
        const { roomId } = req.params;
        const { title, description, maxUsers, settings } = req.body;
        const userId = req.authId;

        const room = await WatchRoom.findOne({ roomId, status: 'active' });
        if (!room) {
            return res.status(404).json({
                success: false,
                message: 'Phòng xem không tồn tại'
            });
        }

        // Kiểm tra quyền host
        if (room.hostId.toString() !== userId) {
            return res.status(403).json({
                success: false,
                message: 'Chỉ host mới có thể cập nhật cài đặt phòng'
            });
        }

        // Cập nhật thông tin
        if (title) room.title = title;
        if (description !== undefined) room.description = description;
        if (maxUsers) room.maxUsers = maxUsers;
        if (settings) {
            room.settings = { ...room.settings, ...settings };
        }

        await room.save();

        res.json({
            success: true,
            message: 'Cập nhật phòng xem thành công',
            data: room
        });

    } catch (error) {
        console.error('Update watch room error:', error);
        res.status(500).json({
            success: false,
            message: 'Lỗi server khi cập nhật phòng xem'
        });
    }
};

// Xóa phòng xem (chỉ host)
export const deleteWatchRoom = async (req, res) => {
    try {
        const { roomId } = req.params;
        const userId = req.authId;

        const room = await WatchRoom.findOne({ roomId });
        if (!room) {
            return res.status(404).json({
                success: false,
                message: 'Phòng xem không tồn tại'
            });
        }

        // Kiểm tra quyền host
        if (room.hostId.toString() !== userId) {
            return res.status(403).json({
                success: false,
                message: 'Chỉ host mới có thể xóa phòng'
            });
        }

        // Cập nhật status thay vì xóa hoàn toàn
        room.status = 'ended';
        await room.save();

        res.json({
            success: true,
            message: 'Xóa phòng xem thành công'
        });

    } catch (error) {
        console.error('Delete watch room error:', error);
        res.status(500).json({
            success: false,
            message: 'Lỗi server khi xóa phòng xem'
        });
    }
};

// Lấy lịch sử chat của phòng
export const getChatHistory = async (req, res) => {
    try {
        const { roomId } = req.params;
        const { page = 1, limit = 50 } = req.query;
        const skip = (page - 1) * limit;

        // Kiểm tra user có trong phòng không
        const room = await WatchRoom.findOne({ roomId, status: 'active' });
        if (!room) {
            return res.status(404).json({
                success: false,
                message: 'Phòng xem không tồn tại'
            });
        }

        // User authentication is already handled by JWT middleware
        // Socket will handle room access control

        const messages = await ChatMessage.find({
            roomId,
            isDeleted: false
        })
            .populate('userId', 'name avatar')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(parseInt(limit));

        const total = await ChatMessage.countDocuments({ roomId, isDeleted: false });

        res.json({
            success: true,
            data: {
                messages: messages.reverse(), // Reverse để hiển thị từ cũ đến mới
                pagination: {
                    current: parseInt(page),
                    total: Math.ceil(total / limit),
                    count: total
                }
            }
        });

    } catch (error) {
        console.error('Get chat history error:', error);
        res.status(500).json({
            success: false,
            message: 'Lỗi server khi lấy lịch sử chat'
        });
    }
};

// Lấy phòng xem của user hiện tại
export const getMyWatchRooms = async (req, res) => {
    try {
        const userId = req.authId;
        const { type = 'hosting' } = req.query; // hosting | joined

        let query = { status: 'active' };

        if (type === 'hosting') {
            query.hostId = userId;
        } else {
            query['currentUsers.userId'] = userId;
        }

        const rooms = await WatchRoom.find(query)
            .populate('movieId', 'name poster_url origin_name')
            .populate('hostId', 'name avatar')
            .sort({ createdAt: -1 });

        const roomsWithEpisodes = await Promise.all(rooms.map(async (room) => {
            const movie = await Movie.findOne({ _id: room.movieId });
            const episode = movie?.episodes[0]?.server_data?.find(ep => ep.slug === room.episodeSlug);

            return {
                ...room.toObject(),
                episode: episode || null,
                userCount: room.currentUsers.length
            };
        }));

        res.json({
            success: true,
            data: {
                rooms: roomsWithEpisodes
            }
        });

    } catch (error) {
        console.error('Get my watch rooms error:', error);
        res.status(500).json({
            success: false,
            message: 'Lỗi server khi lấy phòng xem của bạn'
        });
    }
};