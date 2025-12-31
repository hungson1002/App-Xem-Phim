import { Server } from 'socket.io';
import WatchRoom from '../models/WatchRoom.model.js';
import ChatMessage from '../models/ChatMessage.model.js';
import jwt from 'jsonwebtoken';

class SocketService {
    constructor() {
        this.io = null;
        this.rooms = new Map(); // Cache active rooms
    }

    initialize(server) {
        this.io = new Server(server, {
            cors: {
                origin: process.env.CLIENT_URL || "http://localhost:3000",
                methods: ["GET", "POST"],
                credentials: true
            }
        });

        // Middleware xác thực
        this.io.use(async (socket, next) => {
            try {
                const token = socket.handshake.auth.token;
                if (!token) {
                    return next(new Error('Authentication error'));
                }

                const decoded = jwt.verify(token, process.env.JWT_SECRET);
                socket.userId = decoded.id;
                socket.username = decoded.username;
                socket.avatar = decoded.avatar || '';

                next();
            } catch (err) {
                next(new Error('Authentication error'));
            }
        });

        this.io.on('connection', (socket) => {
            console.log(`User ${socket.username} connected: ${socket.id}`);

            this.handleConnection(socket);
        });

        return this.io;
    }

    handleConnection(socket) {
        // Join watch room
        socket.on('join-room', async (data) => {
            await this.handleJoinRoom(socket, data);
        });

        // Leave room
        socket.on('leave-room', async (data) => {
            await this.handleLeaveRoom(socket, data);
        });

        // Video control events
        socket.on('video-play', async (data) => {
            await this.handleVideoControl(socket, 'play', data);
        });

        socket.on('video-pause', async (data) => {
            await this.handleVideoControl(socket, 'pause', data);
        });

        socket.on('video-seek', async (data) => {
            await this.handleVideoSeek(socket, data);
        });

        // Chat events
        socket.on('send-message', async (data) => {
            await this.handleSendMessage(socket, data);
        });

        socket.on('add-reaction', async (data) => {
            await this.handleAddReaction(socket, data);
        });

        // Sync request
        socket.on('request-sync', async (data) => {
            await this.handleSyncRequest(socket, data);
        });

        // Disconnect
        socket.on('disconnect', () => {
            this.handleDisconnect(socket);
        });
    }

    async handleJoinRoom(socket, { roomId, password }) {
        try {
            const room = await WatchRoom.findOne({ roomId, status: 'active' })
                .populate('movieId', 'name poster_url')
                .populate('currentUsers.userId', 'username avatar');

            if (!room) {
                socket.emit('error', { message: 'Phòng không tồn tại' });
                return;
            }

            // Kiểm tra password nếu phòng private
            if (room.isPrivate && room.password !== password) {
                socket.emit('error', { message: 'Mật khẩu không đúng' });
                return;
            }

            // Kiểm tra số lượng user
            if (room.currentUsers.length >= room.maxUsers) {
                socket.emit('error', { message: 'Phòng đã đầy' });
                return;
            }

            // Kiểm tra user đã trong phòng chưa
            const existingUser = room.currentUsers.find(u => u.userId.toString() === socket.userId);

            if (!existingUser) {
                // Thêm user vào phòng
                room.currentUsers.push({
                    userId: socket.userId,
                    username: socket.username,
                    avatar: socket.avatar,
                    isHost: room.hostId.toString() === socket.userId
                });
                await room.save();
            }

            // Join socket room
            socket.join(roomId);
            socket.currentRoom = roomId;

            // Cache room info
            this.rooms.set(roomId, {
                ...room.toObject(),
                sockets: (this.rooms.get(roomId)?.sockets || new Set()).add(socket.id)
            });

            // Gửi thông tin phòng cho user
            socket.emit('room-joined', {
                room: room,
                videoState: room.videoState,
                userCount: room.currentUsers.length
            });

            // Thông báo cho các user khác
            socket.to(roomId).emit('user-joined', {
                user: {
                    userId: socket.userId,
                    username: socket.username,
                    avatar: socket.avatar
                },
                userCount: room.currentUsers.length
            });

            // Gửi tin nhắn hệ thống
            const systemMessage = new ChatMessage({
                roomId,
                userId: socket.userId,
                username: 'System',
                message: `${socket.username} đã tham gia phòng`,
                type: 'system'
            });
            await systemMessage.save();

            this.io.to(roomId).emit('new-message', systemMessage);

        } catch (error) {
            console.error('Join room error:', error);
            socket.emit('error', { message: 'Lỗi khi tham gia phòng' });
        }
    }

    async handleLeaveRoom(socket, { roomId }) {
        try {
            await this.removeUserFromRoom(socket, roomId);
        } catch (error) {
            console.error('Leave room error:', error);
        }
    }

    async handleVideoControl(socket, action, { roomId, currentTime }) {
        try {
            const room = await WatchRoom.findOne({ roomId });
            if (!room) return;

            // Kiểm tra quyền điều khiển
            const user = room.currentUsers.find(u => u.userId.toString() === socket.userId);
            if (!user || (!user.isHost && !room.settings.allowUserControl)) {
                socket.emit('error', { message: 'Bạn không có quyền điều khiển video' });
                return;
            }

            // Cập nhật trạng thái video
            room.videoState = {
                currentTime: currentTime || room.videoState.currentTime,
                isPlaying: action === 'play',
                lastUpdated: new Date(),
                updatedBy: socket.userId
            };
            await room.save();

            // Broadcast cho tất cả users trong phòng
            this.io.to(roomId).emit('video-state-changed', {
                action,
                currentTime: room.videoState.currentTime,
                isPlaying: room.videoState.isPlaying,
                updatedBy: socket.username,
                timestamp: Date.now()
            });

        } catch (error) {
            console.error('Video control error:', error);
        }
    }

    async handleVideoSeek(socket, { roomId, currentTime }) {
        try {
            const room = await WatchRoom.findOne({ roomId });
            if (!room) return;

            const user = room.currentUsers.find(u => u.userId.toString() === socket.userId);
            if (!user || (!user.isHost && !room.settings.allowUserControl)) {
                socket.emit('error', { message: 'Bạn không có quyền điều khiển video' });
                return;
            }

            room.videoState.currentTime = currentTime;
            room.videoState.lastUpdated = new Date();
            room.videoState.updatedBy = socket.userId;
            await room.save();

            socket.to(roomId).emit('video-seeked', {
                currentTime,
                updatedBy: socket.username,
                timestamp: Date.now()
            });

        } catch (error) {
            console.error('Video seek error:', error);
        }
    }

    async handleSendMessage(socket, { roomId, message, videoTimestamp }) {
        try {
            const room = await WatchRoom.findOne({ roomId });
            if (!room || !room.settings.allowChat) return;

            const chatMessage = new ChatMessage({
                roomId,
                userId: socket.userId,
                username: socket.username,
                avatar: socket.avatar,
                message: message.trim(),
                videoTimestamp: videoTimestamp || 0
            });

            await chatMessage.save();

            this.io.to(roomId).emit('new-message', chatMessage);

        } catch (error) {
            console.error('Send message error:', error);
        }
    }

    async handleAddReaction(socket, { messageId, emoji }) {
        try {
            const message = await ChatMessage.findById(messageId);
            if (!message) return;

            // Kiểm tra user đã react chưa
            const existingReaction = message.reactions.find(r => r.userId.toString() === socket.userId);

            if (existingReaction) {
                if (existingReaction.emoji === emoji) {
                    // Remove reaction
                    message.reactions = message.reactions.filter(r => r.userId.toString() !== socket.userId);
                } else {
                    // Update reaction
                    existingReaction.emoji = emoji;
                    existingReaction.createdAt = new Date();
                }
            } else {
                // Add new reaction
                message.reactions.push({
                    userId: socket.userId,
                    emoji,
                    createdAt: new Date()
                });
            }

            await message.save();

            this.io.to(message.roomId).emit('reaction-updated', {
                messageId,
                reactions: message.reactions
            });

        } catch (error) {
            console.error('Add reaction error:', error);
        }
    }

    async handleSyncRequest(socket, { roomId }) {
        try {
            const room = await WatchRoom.findOne({ roomId });
            if (!room) return;

            socket.emit('sync-response', {
                videoState: room.videoState,
                serverTime: Date.now()
            });

        } catch (error) {
            console.error('Sync request error:', error);
        }
    }

    async handleDisconnect(socket) {
        console.log(`User ${socket.username} disconnected: ${socket.id}`);

        if (socket.currentRoom) {
            await this.removeUserFromRoom(socket, socket.currentRoom);
        }
    }

    async removeUserFromRoom(socket, roomId) {
        try {
            const room = await WatchRoom.findOne({ roomId });
            if (!room) return;

            // Remove user from room
            room.currentUsers = room.currentUsers.filter(u => u.userId.toString() !== socket.userId);

            // Nếu host rời phòng và còn user khác, chuyển host
            if (room.hostId.toString() === socket.userId && room.currentUsers.length > 0) {
                const newHost = room.currentUsers[0];
                room.hostId = newHost.userId;
                newHost.isHost = true;

                this.io.to(roomId).emit('host-changed', {
                    newHost: {
                        userId: newHost.userId,
                        username: newHost.username
                    }
                });
            }

            // Nếu không còn ai, xóa phòng
            if (room.currentUsers.length === 0) {
                room.status = 'ended';
                this.rooms.delete(roomId);
            }

            await room.save();

            // Leave socket room
            socket.leave(roomId);

            // Update cache
            const cachedRoom = this.rooms.get(roomId);
            if (cachedRoom) {
                cachedRoom.sockets.delete(socket.id);
            }

            // Thông báo user rời phòng
            socket.to(roomId).emit('user-left', {
                userId: socket.userId,
                username: socket.username,
                userCount: room.currentUsers.length
            });

            // System message
            if (room.currentUsers.length > 0) {
                const systemMessage = new ChatMessage({
                    roomId,
                    userId: socket.userId,
                    username: 'System',
                    message: `${socket.username} đã rời phòng`,
                    type: 'system'
                });
                await systemMessage.save();
                this.io.to(roomId).emit('new-message', systemMessage);
            }

        } catch (error) {
            console.error('Remove user from room error:', error);
        }
    }

    // Utility methods
    getRoomUsers(roomId) {
        const room = this.rooms.get(roomId);
        return room ? room.currentUsers : [];
    }

    isUserInRoom(userId, roomId) {
        const room = this.rooms.get(roomId);
        return room ? room.currentUsers.some(u => u.userId === userId) : false;
    }
}

export default new SocketService();