import mongoose from 'mongoose';

const participantSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    name: {
        type: String,
        required: true
    },
    avatar: {
        type: String,
        default: null
    },
    joinedAt: {
        type: Date,
        default: Date.now
    }
});

const watchRoomSchema = new mongoose.Schema({
    roomCode: {
        type: String,
        required: true,
        unique: true,
        minlength: 6,
        maxlength: 6
    },
    movieSlug: {
        type: String,
        required: true
    },
    movieName: {
        type: String,
        required: true
    },
    moviePoster: {
        type: String,
        default: ''
    },
    host: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    hostName: {
        type: String,
        required: true
    },
    participants: [participantSchema],
    maxParticipants: {
        type: Number,
        default: 30,
        min: 2,
        max: 50
    },
    isActive: {
        type: Boolean,
        default: true
    },
    // Video sync state
    currentTime: {
        type: Number,
        default: 0
    },
    isPlaying: {
        type: Boolean,
        default: false
    },
    currentServer: {
        type: Number,
        default: 0
    },
    currentEpisode: {
        type: Number,
        default: 0
    }
}, {
    timestamps: true
});

// Index for faster queries
watchRoomSchema.index({ roomCode: 1 });
watchRoomSchema.index({ isActive: 1 });
watchRoomSchema.index({ host: 1 });

// Generate unique room code
watchRoomSchema.statics.generateRoomCode = async function () {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code;
    let exists = true;

    while (exists) {
        code = '';
        for (let i = 0; i < 6; i++) {
            code += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        exists = await this.findOne({ roomCode: code, isActive: true });
    }

    return code;
};

const WatchRoom = mongoose.model('WatchRoom', watchRoomSchema);

// Drop stale roomId index if exists (fix for duplicate key error)
WatchRoom.collection.dropIndex('roomId_1').catch(() => {
    // Index doesn't exist, ignore error
});

export default WatchRoom;
