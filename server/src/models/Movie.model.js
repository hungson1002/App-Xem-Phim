import mongoose from 'mongoose';

const MovieSchema = new mongoose.Schema({
    // Thông tin cơ bản
    _id: { type: String, required: true },
    name: { type: String, required: true },
    slug: { type: String, required: true, unique: true },
    origin_name: { type: String },
    content: { type: String },
    type: { type: String },
    status: { type: String },
    year: { type: Number },

    // Media URLs
    poster_url: { type: String },
    thumb_url: { type: String },
    trailer_url: { type: String },

    // Chi tiết kỹ thuật
    time: { type: String },
    episode_current: { type: String },
    episode_total: { type: String },
    quality: { type: String },
    lang: { type: String },

    // Thông báo/Lịch chiếu
    notify: { type: String },
    showtimes: { type: String },

    // Lượt xem
    view: { type: Number, default: 0 },

    // Các cờ Boolean
    is_copyright: { type: Boolean, default: false },
    sub_docquyen: { type: Boolean, default: false },
    chieurap: { type: Boolean, default: false },

    // Nested Objects matching JSON
    tmdb: {
        type: { type: String },
        id: { type: String },
        season: { type: Number },
        vote_average: { type: Number },
        vote_count: { type: Number }
    },

    imdb: {
        id: { type: String }
    },

    created: {
        time: { type: Date }
    },

    modified: {
        time: { type: Date }
    },

    actor: [{ type: String }],
    director: [{ type: String }],

    category: [{
        id: { type: String },
        name: { type: String },
        slug: { type: String }
    }],

    country: [{
        id: { type: String },
        name: { type: String },
        slug: { type: String }
    }],

    episodes: [{
        server_name: { type: String },
        server_data: [{
            name: { type: String },
            slug: { type: String },
            filename: { type: String },
            link_embed: { type: String },
            link_m3u8: { type: String }
        }]
    }]

}, {
    timestamps: true
});

// Index text search
MovieSchema.index({ name: 'text', origin_name: 'text' });

const Movie = mongoose.model('Movie', MovieSchema);
export default Movie;
