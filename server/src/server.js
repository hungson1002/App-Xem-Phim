import cors from 'cors';
import dotenv from 'dotenv';
import express from 'express';
import { createServer } from 'http';
import mongoose from 'mongoose';
import { Server } from 'socket.io';
import AuthRoute from './routes/Auth.route.js';
import BookmarkRoute from './routes/Bookmark.route.js';
import CategoryRoute from './routes/Category.routes.js';
import CommentRoute from './routes/Comment.route.js';
import CountryRoute from './routes/Country.routes.js';
import MovieRoute from './routes/Movie.routes.js';
import SavedMovieRoute from './routes/SavedMovie.route.js';
import UserRoute from './routes/User.route.js';
import WatchRoomRoute from './routes/WatchRoom.route.js';
import { initializeSocket } from './services/socketService.js';
dotenv.config();

const app = express();
const httpServer = createServer(app);

// Initialize Socket.IO
const io = new Server(httpServer, {
  cors: {
    origin: process.env.CLIENT_URL || '*',
    methods: ['GET', 'POST'],
    credentials: true
  }
});

// Initialize socket handlers
initializeSocket(io);

app.use(cors({
  origin: process.env.CLIENT_URL || '*',
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
app.use('/api/bookmarks', BookmarkRoute);
app.use('/api/saved-movies', SavedMovieRoute);
app.use('/api/watch-rooms', WatchRoomRoute);

import https from 'https';
app.get('/api/proxy/image', (req, res) => {
  const { url } = req.query;
  if (!url) return res.status(400).send('URL is required');

  https.get(url, (response) => {
    res.set('Content-Type', response.headers['content-type']);
    response.pipe(res);
  }).on('error', (err) => {
    console.error('Proxy error:', err);
    res.status(500).send('Error fetching image');
  });
});

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

const PORT = process.env.PORT;
httpServer.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Socket.IO enabled`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});
