import mongoose from 'mongoose';

const authSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            required: true,
            trim: true
        },
        email: {
            type: String,
            required: true,
            unique: true,
            lowercase: true,
            trim: true
        },
        password: {
            type: String,
            required: function () {
                return this.provider === 'local';
            }
        },
        isVerified: {
            type: Boolean,
            default: false
        },
        otp: {
            type: String
        },

        otpExpires: {
            type: Date
        },
        googleId: {
            type: String
        },

        avatar: {
            type: String
        },

        provider: {
            type: String,
            enum: ['local', 'google'],
            default: 'local'
        }

    },
    {
        timestamps: true
    }
);

const Auth = mongoose.model('Auth', authSchema);

export default Auth;
