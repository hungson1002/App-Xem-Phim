import mongoose from 'mongoose';

const CommentSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Auth',
    required: true
  },
  movieId: {
    type: String, 
    required: true
  },
  content: {
    type: String,
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Populate user info automatically when finding comments
CommentSchema.pre(/^find/, function(next) {
  this.populate({
    path: 'userId',
    select: 'name avatar'
  });
  next();
});

const Comment = mongoose.model('Comment', CommentSchema);

export default Comment;
