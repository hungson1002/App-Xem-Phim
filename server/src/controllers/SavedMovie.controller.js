import mongoose from "mongoose";
import SavedMovie from "../models/SavedMovie.model.js";

// Lưu phim
export const saveMovie = async (req, res) => {
    try {
        const { movieID } = req.body;

        if (!movieID) {
            return res.status(400).json({
                success: false,
                message: "movieID is required"
            });
        }

        const savedMovie = await SavedMovie.create({
            user: req.authID,
            movie: movieID
        });

        return res.status(201).json({
            success: true,
            message: "Movie saved successfully",
            data: savedMovie
        })

    } catch (error) {
        if (error.code === 11000) {
            return res.status(400).json({
                success: false,
                message: "Movie already saved"
            })
        }

        return res.status(500).json({ success: false, message: "Internal server error" });
    }
}

// Bỏ lưu phim
export const removeMovie = async (req, res) => {
    try {
        const { movieID } = req.params;

        if (!movieID) {
            return res.status(400).json({
                success: false,
                message: "movieID is required"
            });
        }

        const removedMovie = await SavedMovie.findOneAndDelete({
            user: req.authID,
            movie: movieID
        })

        return res.status(200).json({
            success: true,
            message: "Movie removed from saved list",
            data: removedMovie
        })
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: "Internal server error"
        });
    }
}

// Lấy danh sách phim đã lưu (dùng aggregate để join by slug)
export const getSavedMovies = async (req, res) => {
    try {
        const savedMovies = await SavedMovie.aggregate([
            {
                $match: {
                    user: new mongoose.Types.ObjectId(req.authID)
                }
            },
            {
                $lookup: {
                    from: 'movies',
                    localField: 'movie',
                    foreignField: 'slug',
                    as: 'movieDetails'
                }
            },
            { $unwind: { path: '$movieDetails', preserveNullAndEmptyArrays: true } },
            {
                $project: {
                    _id: 1,
                    user: 1,
                    movieSlug: '$movie',
                    movie: { $ifNull: ['$movieDetails', null] },
                    createdAt: 1
                }
            },
            { $sort: { createdAt: -1 } }
        ]);

        return res.status(200).json({
            success: true,
            data: savedMovies
        })
    } catch (error) {
        console.error('getSavedMovies error:', error);
        return res.status(500).json({
            success: false,
            message: "Internal server error"
        })
    }
}