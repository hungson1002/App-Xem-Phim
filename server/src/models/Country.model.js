import mongoose from 'mongoose';

const CountrySchema = new mongoose.Schema({
    id: {
        type: String,
        alias: '_id',
        required: true,
        unique: true
    },
    name: {
        type: String,
        required: true
    },
    slug: {
        type: String,
        required: true,
        unique: true
    }
}, {
    timestamps: true
});

const Country = mongoose.model('Country', CountrySchema);
export default Country;
