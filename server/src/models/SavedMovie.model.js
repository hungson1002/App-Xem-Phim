import mongoose from 'mongoose';

const SavedMovieSchema = new mongoose.Schema(
    {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Auth',
            required: true
        },
        movie: {
            type: String,
            ref: 'Movie',
            required: true
        },
    },
    {
        timestamps: true
    }
);
SavedMovieSchema.index({ user: 1, movie: 1 }, { unique: true });

export default mongoose.model('SavedMovie', SavedMovieSchema);