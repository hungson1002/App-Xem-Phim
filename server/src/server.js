import cors from 'cors';
import dotenv from 'dotenv';
import express from 'express';
import { createServer } from 'http';
import mongoose from 'mongoose';
import AuthRoute from './routes/Auth.route.js';
import CategoryRoute from './routes/Category.routes.js';
import CommentRoute from './routes/Comment.route.js';
import CountryRoute from './routes/Country.routes.js';
import MovieRoute from './routes/Movie.routes.js';
import SavedMovieRoute from './routes/SavedMovie.route.js';
import UserRoute from './routes/User.route.js';
import WatchRoomRoute from './routes/WatchRoom.route.js';
import socketService from './services/socketService.js';
dotenv.config();

const app = express();
const server = createServer(app);

app.use(cors({
  origin: true, // Allow all origins in development
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Database connection
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('MongoDB connected successfully');
  } catch (error) {
    console.error('MongoDB connection error:', error.message);
    process.exit(1);
  }
};

connectDB();

// Routes
app.use('/api/auth', AuthRoute);
app.use('/api/user', UserRoute);
app.use('/api/comments', CommentRoute);
app.use('/api/categories', CategoryRoute);
app.use('/api/countries', CountryRoute);
app.use('/api/movies', MovieRoute);
app.use('/api/watch-rooms', WatchRoomRoute);
app.use('/api/saved-movies', SavedMovieRoute);

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

const PORT = process.env.PORT || 4000;

// Initialize Socket.IO
socketService.initialize(server);

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log('Socket.IO initialized successfully');
});