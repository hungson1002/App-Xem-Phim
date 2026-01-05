import mongoose from 'mongoose';

const bookmarkSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Auth',
            required: true
        },
        movieId: {
            type: String,
            required: true
        },
        movieSlug: {
            type: String,
            required: true
        },
        movieName: {
            type: String,
            required: true
        },
        posterUrl: {
            type: String,
            default: ''
        },
        year: {
            type: Number,
            default: 0
        },
        category: {
            type: [String],
            default: []
        }
    },
    {
        timestamps: true
    }
);

// Compound index to ensure a user can't bookmark the same movie twice
bookmarkSchema.index({ userId: 1, movieId: 1 }, { unique: true });

const Bookmark = mongoose.model('Bookmark', bookmarkSchema);

export default Bookmark;
