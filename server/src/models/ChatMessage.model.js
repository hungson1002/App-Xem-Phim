import mongoose from 'mongoose';

const ChatMessageSchema = new mongoose.Schema({
    roomId: {
        type: String,
        required: true,
        ref: 'WatchRoom'
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        ref: 'Auth'
    },
    username: {
        type: String,
        required: true
    },
    avatar: {
        type: String,
        default: ''
    },
    message: {
        type: String,
        required: true,
        maxlength: 500
    },
    type: {
        type: String,
        enum: ['message', 'system', 'emoji', 'sticker'],
        default: 'message'
    },
    // Timestamp của video khi gửi tin nhắn
    videoTimestamp: {
        type: Number,
        default: 0
    },
    // Phản ứng của users khác
    reactions: [{
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Auth'
        },
        emoji: String,
        createdAt: {
            type: Date,
            default: Date.now
        }
    }],
    // Tin nhắn có bị xóa không
    isDeleted: {
        type: Boolean,
        default: false
    },
    deletedAt: {
        type: Date,
        default: null
    }
}, {
    timestamps: true
});

// Index để query nhanh
ChatMessageSchema.index({ roomId: 1, createdAt: -1 });
ChatMessageSchema.index({ userId: 1 });

const ChatMessage = mongoose.model('ChatMessage', ChatMessageSchema);
export default ChatMessage;