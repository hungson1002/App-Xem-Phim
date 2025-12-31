import mongoose from 'mongoose';

const WatchRoomSchema = new mongoose.Schema({
    roomId: {
        type: String,
        required: true,
        unique: true
    },
    movieId: {
        type: String,
        required: true,
        ref: 'Movie'
    },
    episodeSlug: {
        type: String,
        required: true
    },
    hostId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        ref: 'Auth'
    },
    title: {
        type: String,
        required: true
    },
    description: {
        type: String,
        default: ''
    },
    isPrivate: {
        type: Boolean,
        default: false
    },
    password: {
        type: String,
        default: null
    },
    maxUsers: {
        type: Number,
        default: 50
    },
    currentUsers: [{
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Auth'
        },
        username: String,
        avatar: String,
        joinedAt: {
            type: Date,
            default: Date.now
        },
        isHost: {
            type: Boolean,
            default: false
        }
    }],
    // Trạng thái phát video
    videoState: {
        currentTime: {
            type: Number,
            default: 0
        },
        isPlaying: {
            type: Boolean,
            default: false
        },
        lastUpdated: {
            type: Date,
            default: Date.now
        },
        updatedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Auth'
        }
    },
    // Cài đặt phòng
    settings: {
        allowChat: {
            type: Boolean,
            default: true
        },
        allowUserControl: {
            type: Boolean,
            default: false // Chỉ host mới điều khiển
        },
        syncTolerance: {
            type: Number,
            default: 2 // Sai lệch tối đa 2 giây
        }
    },
    status: {
        type: String,
        enum: ['active', 'paused', 'ended'],
        default: 'active'
    }
}, {
    timestamps: true
});

// Index để tìm kiếm nhanh
WatchRoomSchema.index({ roomId: 1 });
WatchRoomSchema.index({ movieId: 1 });
WatchRoomSchema.index({ hostId: 1 });
WatchRoomSchema.index({ status: 1 });

const WatchRoom = mongoose.model('WatchRoom', WatchRoomSchema);
export default WatchRoom;