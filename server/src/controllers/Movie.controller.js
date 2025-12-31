import Movie from '../models/Movie.model.js';

// 1. Get All Movies 
export const getAllMovies = async (req, res) => {
    try {
        const { page = 1, limit = 20, search } = req.query;
        const skip = (page - 1) * limit;

        let query = {};
        if (search) {
            query = {
                $or: [
                    { name: { $regex: search, $options: 'i' } },
                    { origin_name: { $regex: search, $options: 'i' } },
                    { slug: { $regex: search, $options: 'i' } }
                ]
            };
        }

        const movies = await Movie.find(query)
            .sort({ 'modified.time': -1 })
            .skip(parseInt(skip))
            .limit(parseInt(limit));

        const total = await Movie.countDocuments(query);

        res.status(200).json({
            success: true,
            data: movies,
            pagination: {
                total,
                page: parseInt(page),
                limit: parseInt(limit),
                totalPages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// 2. Get Movie Detail by Slug
export const getMovieBySlug = async (req, res) => {
    try {
        const { slug } = req.params;
        const movie = await Movie.findOne({ slug });

        if (!movie) {
            return res.status(404).json({ success: false, message: 'Movie not found' });
        }

        res.status(200).json({ success: true, data: movie });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// 3. Create Movie
export const createMovie = async (req, res) => {
    try {
        const movieData = req.body;

        // Check if slug exists
        const existingMovie = await Movie.findOne({ slug: movieData.slug });
        if (existingMovie) {
            return res.status(400).json({ success: false, message: 'Movie with this slug already exists' });
        }

        const newMovie = new Movie(movieData);
        const savedMovie = await newMovie.save();

        res.status(201).json({ success: true, data: savedMovie });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// 4. Update Movie
export const updateMovie = async (req, res) => {
    try {
        const { id } = req.params;
        const updatedMovie = await Movie.findByIdAndUpdate(id, req.body, {
            new: true,
            runValidators: true
        });

        if (!updatedMovie) {
            return res.status(404).json({ success: false, message: 'Movie not found' });
        }

        res.status(200).json({ success: true, data: updatedMovie });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// 5. Delete Movie
export const deleteMovie = async (req, res) => {
    try {
        const { id } = req.params;
        const deletedMovie = await Movie.findByIdAndDelete(id);

        if (!deletedMovie) {
            return res.status(404).json({ success: false, message: 'Movie not found' });
        }

        res.status(200).json({ success: true, message: 'Movie deleted successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// 6. Get Movies by Category
export const getMoviesByCategory = async (req, res) => {
    try {
        const { page = 1, limit = 20 } = req.query;
        const { slug } = req.params;
        const skip = (page - 1) * limit;

        const query = { "category.slug": slug };

        const movies = await Movie.find(query)
            .sort({ 'modified.time': -1 })
            .skip(parseInt(skip))
            .limit(parseInt(limit));

        const total = await Movie.countDocuments(query);

        res.status(200).json({
            success: true,
            data: movies,
            pagination: {
                total,
                page: parseInt(page),
                limit: parseInt(limit),
                totalPages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// 7. Get Movies by Country
export const getMoviesByCountry = async (req, res) => {
    try {
        const { page = 1, limit = 20 } = req.query;
        const { slug } = req.params;
        const skip = (page - 1) * limit;

        const query = { "country.slug": slug };

        const movies = await Movie.find(query)
            .sort({ 'modified.time': -1 })
            .skip(parseInt(skip))
            .limit(parseInt(limit));

        const total = await Movie.countDocuments(query);

        res.status(200).json({
            success: true,
            data: movies,
            pagination: {
                total,
                page: parseInt(page),
                limit: parseInt(limit),
                totalPages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// 8. Get Movies by Year
export const getMoviesByYear = async (req, res) => {
    try {
        const { page = 1, limit = 20 } = req.query;
        const { year } = req.params;
        const skip = (page - 1) * limit;

        const query = { year: parseInt(year) };

        const movies = await Movie.find(query)
            .sort({ 'modified.time': -1 })
            .skip(parseInt(skip))
            .limit(parseInt(limit));

        const total = await Movie.countDocuments(query);

        res.status(200).json({
            success: true,
            data: movies,
            pagination: {
                total,
                page: parseInt(page),
                limit: parseInt(limit),
                totalPages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// 9. Get Movies by Limit
export const getMoviesLimit = async (req, res) => {
    try {
        const { limit } = req.params;
        const movies = await Movie.find({})
            .sort({ 'modified.time': -1 })
            .limit(parseInt(limit));

        res.status(200).json({ success: true, data: movies });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
