import Auth from '../models/Auth.model.js';
import WatchRoom from '../models/WatchRoom.model.js';

// Generate unique room code helper
const generateRoomCode = async () => {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code;
    let exists = true;

    while (exists) {
        code = '';
        for (let i = 0; i < 6; i++) {
            code += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        exists = await WatchRoom.findOne({ roomCode: code, isActive: true });
    }

    return code;
};

// Helper to get user info from authId
const getUserInfo = async (authId) => {
    const user = await Auth.findById(authId).select('name email avatar');
    if (!user) return null;
    return {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        avatar: user.avatar || null
    };
};

// Create a new watch room
export const createRoom = async (req, res) => {
    try {
        const { movieSlug, movieName, moviePoster } = req.body;
        const authId = req.authId;

        // Get user info from database
        const user = await getUserInfo(authId);
        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'User not found'
            });
        }

        if (!movieSlug || !movieName) {
            return res.status(400).json({
                success: false,
                message: 'Movie slug and name are required'
            });
        }

        // Generate unique room code
        const roomCode = await generateRoomCode();

        // Create room with host as first participant
        const room = new WatchRoom({
            roomCode,
            movieSlug,
            movieName,
            moviePoster: moviePoster || '',
            host: user.id,
            hostName: user.name || user.email,
            participants: [{
                user: user.id,
                name: user.name || user.email,
                avatar: user.avatar
            }]
        });

        await room.save();

        res.status(201).json({
            success: true,
            message: 'Room created successfully',
            data: room
        });
    } catch (error) {
        console.error('Create room error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create room'
        });
    }
};

// Get all active rooms
export const getRooms = async (req, res) => {
    try {
        const rooms = await WatchRoom.find({ isActive: true })
            .sort({ createdAt: -1 })
            .select('-__v');

        res.json({
            success: true,
            data: rooms
        });
    } catch (error) {
        console.error('Get rooms error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get rooms'
        });
    }
};

// Get room by code
export const getRoom = async (req, res) => {
    try {
        const { code } = req.params;

        const room = await WatchRoom.findOne({
            roomCode: code.toUpperCase(),
            isActive: true
        });

        if (!room) {
            return res.status(404).json({
                success: false,
                message: 'Room not found'
            });
        }

        res.json({
            success: true,
            data: room
        });
    } catch (error) {
        console.error('Get room error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get room'
        });
    }
};

// Join a room
export const joinRoom = async (req, res) => {
    try {
        const { code } = req.params;
        const authId = req.authId;

        // Get user info from database
        const user = await getUserInfo(authId);
        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'User not found'
            });
        }

        const room = await WatchRoom.findOne({
            roomCode: code.toUpperCase(),
            isActive: true
        });

        if (!room) {
            return res.status(404).json({
                success: false,
                message: 'Room not found'
            });
        }

        // Check if already in room
        const alreadyJoined = room.participants.some(
            p => p.user.toString() === user.id
        );

        if (alreadyJoined) {
            return res.json({
                success: true,
                message: 'Already in room',
                data: room
            });
        }

        // Check max participants
        if (room.participants.length >= room.maxParticipants) {
            return res.status(400).json({
                success: false,
                message: 'Room is full'
            });
        }

        // Add participant
        room.participants.push({
            user: user.id,
            name: user.name || user.email,
            avatar: user.avatar
        });

        await room.save();

        res.json({
            success: true,
            message: 'Joined room successfully',
            data: room
        });
    } catch (error) {
        console.error('Join room error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to join room'
        });
    }
};

// Leave a room
export const leaveRoom = async (req, res) => {
    try {
        const { code } = req.params;
        const authId = req.authId;

        const room = await WatchRoom.findOne({
            roomCode: code.toUpperCase(),
            isActive: true
        });

        if (!room) {
            return res.status(404).json({
                success: false,
                message: 'Room not found'
            });
        }

        // Remove participant
        room.participants = room.participants.filter(
            p => p.user.toString() !== authId
        );

        // If host leaves, close room
        if (room.host.toString() === authId) {
            room.isActive = false;
        }

        await room.save();

        res.json({
            success: true,
            message: room.isActive ? 'Left room successfully' : 'Room closed'
        });
    } catch (error) {
        console.error('Leave room error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to leave room'
        });
    }
};

// Close a room (host only)
export const closeRoom = async (req, res) => {
    try {
        const { code } = req.params;
        const authId = req.authId;

        const room = await WatchRoom.findOne({
            roomCode: code.toUpperCase(),
            isActive: true
        });

        if (!room) {
            return res.status(404).json({
                success: false,
                message: 'Room not found'
            });
        }

        // Check if user is host
        if (room.host.toString() !== authId) {
            return res.status(403).json({
                success: false,
                message: 'Only host can close the room'
            });
        }

        room.isActive = false;
        await room.save();

        res.json({
            success: true,
            message: 'Room closed successfully'
        });
    } catch (error) {
        console.error('Close room error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to close room'
        });
    }
};

// Update video sync state (internal use by socket)
export const updateSyncState = async (roomCode, syncData) => {
    try {
        await WatchRoom.findOneAndUpdate(
            { roomCode: roomCode.toUpperCase(), isActive: true },
            {
                currentTime: syncData.currentTime,
                isPlaying: syncData.isPlaying,
                currentServer: syncData.currentServer || 0,
                currentEpisode: syncData.currentEpisode || 0
            }
        );
    } catch (error) {
        console.error('Update sync state error:', error);
    }
};
