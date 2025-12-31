import mongoose from 'mongoose';

const CategorySchema = new mongoose.Schema({
  _id: {
    type: String,
    required: true
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

const Category = mongoose.model('Category', CategorySchema);
export default Category;
