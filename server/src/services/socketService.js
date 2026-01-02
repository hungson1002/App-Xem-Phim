import { Server } from 'socket.io';
import WatchRoom from '../models/WatchRoom.model.js';
import ChatMessage from '../models/ChatMessage.model.js';
import Auth from '../models/Auth.model.js'; // Import Auth model
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

                // Fetch user info based on authID from token
                const user = await Auth.findById(decoded.authID);
                if (user) {
                    socket.user = user;
                    socket.userId = user._id.toString();
                    socket.username = user.name;
                    socket.avatar = user.avatar || '';
                    next();
                } else {
                    next(new Error('User not found'));
                }
            } catch (err) {
                next(new Error('Authentication error'));
            }
        });

        this.io.on('connection', (socket) => {


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
            // Find room first without populate to check existence
            let room = await WatchRoom.findOne({ roomId, status: 'active' });

            if (!room) {
                socket.emit('error', { message: 'Phòng không tồn tại' });
                return;
            }

            try {
                // Populate separately to catch specific errors
                room = await room.populate('movieId', 'name poster_url');
                room = await room.populate('currentUsers.userId', 'name avatar');
            } catch (popError) {

                // Continue even if populate fails (might show partial data)
            }

            // Check if user is the host
            const userIdStr = socket.user._id.toString();
            const hostIdStr = room.hostId.toString();
            const isHost = hostIdStr === userIdStr;

            // Validate password if private (but skip for host)
            if (room.isPrivate && room.password && !isHost && room.password !== password) {
                socket.emit('error', { message: 'Mật khẩu không đúng' });
                return;
            }

            // Check max users
            if (room.currentUsers.length >= room.maxUsers) {
                socket.emit('error', { message: 'Phòng đã đầy' });
                return;
            }

            // Add user to room (using isHost from above)
            const roomUser = {
                userId: socket.user._id,
                username: socket.user.name,
                avatar: socket.user.avatar,
                isHost: isHost
            };

            // Check if user already in room
            const existingUserIndex = room.currentUsers.findIndex(u => {
                if (!u.userId) return false;
                // Handle populated vs unpopulated userId
                const uId = u.userId._id ? u.userId._id.toString() : u.userId.toString();
                return uId === userIdStr;
            });

            if (existingUserIndex !== -1) {
                room.currentUsers[existingUserIndex] = roomUser;
            } else {
                room.currentUsers.push(roomUser);
            }

            await room.save();

            // Join socket.io room
            socket.join(roomId);
            socket.currentRoom = roomId;

            // Add to active rooms cache
            this.rooms.set(roomId, {
                ...room.toObject(),
                sockets: (this.rooms.get(roomId)?.sockets || new Set()).add(socket.id)
            });

            // Send room info to user
            socket.emit('room-joined', {
                room: room,
                videoState: room.videoState,
                userCount: room.currentUsers.length
            });

            // Notify other users
            socket.to(roomId).emit('user-joined', {
                user: {
                    userId: socket.userId,
                    username: socket.username,
                    avatar: socket.avatar
                },
                userCount: room.currentUsers.length
            });

        } catch (error) {
            socket.emit('error', { message: 'Lỗi khi tham gia phòng' });
        }
    }

    async handleLeaveRoom(socket, { roomId }) {
        try {
            await this.removeUserFromRoom(socket, roomId);
        } catch (error) {
        }
    }

    async handleVideoControl(socket, action, { roomId, currentTime }) {
        try {
            const room = await WatchRoom.findOne({ roomId });
            if (!room) return;

            // Check control permissions
            const user = room.currentUsers.find(u => u.userId.toString() === socket.userId);
            if (!user || (!user.isHost && !room.settings.allowUserControl)) {
                socket.emit('error', { message: 'Bạn không có quyền điều khiển video' });
                return;
            }

            // Update video state
            room.videoState = {
                currentTime: currentTime || room.videoState.currentTime,
                isPlaying: action === 'play',
                lastUpdated: new Date(),
                updatedBy: socket.userId
            };
            await room.save();

            // Broadcast to all users in the room
            this.io.to(roomId).emit('video-state-changed', {
                action,
                currentTime: room.videoState.currentTime,
                isPlaying: room.videoState.isPlaying,
                updatedBy: socket.username,
                timestamp: Date.now()
            });

        } catch (error) {
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
        }
    }

    async handleSendMessage(socket, { roomId, message, videoTimestamp, replyTo }) {
        try {


            const room = await WatchRoom.findOne({ roomId });
            if (!room) {
                return;
            }

            if (!room.settings.allowChat) {
                return;
            }

            const chatMessage = new ChatMessage({
                roomId,
                userId: socket.userId,
                username: socket.username,
                avatar: socket.avatar,
                message: message.trim(),
                videoTimestamp: videoTimestamp || 0,
                replyTo: replyTo || null
            });

            await chatMessage.save();
            this.io.to(roomId).emit('new-message', chatMessage);
        } catch (error) {
        }
    }

    async handleAddReaction(socket, { messageId, emoji }) {
        try {
            const message = await ChatMessage.findById(messageId);
            if (!message) return;

            // Check if user has already reacted
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


        if (socket.currentRoom) {
            await this.removeUserFromRoom(socket, socket.currentRoom);
        }
    }

    async removeUserFromRoom(socket, roomId) {
        try {
            const room = await WatchRoom.findOne({ roomId });
            if (!room) return;

            // Remove user from room (with safe null check)
            room.currentUsers = room.currentUsers.filter(u => {
                if (!u || !u.userId) return false;
                return u.userId.toString() !== socket.userId;
            });

            // If host leaves and there are other users, transfer host
            if (room.hostId && socket.userId && room.hostId.toString() === socket.userId && room.currentUsers.length > 0) {
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

            // Delete room if no users left
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

            // Notify other users in the room
            socket.to(roomId).emit('user-left', {
                userId: socket.userId,
                username: socket.username,
                userCount: room.currentUsers.length
            });

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