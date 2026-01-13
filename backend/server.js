const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const admin = require('firebase-admin');
const path = require('path');
// Load .env from the same directory as server.js
require('dotenv').config({ path: path.join(__dirname, '.env') });

const Transaction = require('./models/Transaction');

// --- 1. Firebase Admin Setup ---
// You must provide your service account credentials here or via env variables
// For local dev, you can point GOOGLE_APPLICATION_CREDENTIALS to your json file.
// Or initialize with default credentials if running on Google Cloud.
const serviceAccount = require('./service-account.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const app = express();
app.use(cors());
app.use(express.json());

// --- 2. Middleware: Validate Firebase Token ---
const verifyToken = async (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Unauthorized: No token provided' });
    }

    const token = authHeader.split(' ')[1];
    try {
        const decodedToken = await admin.auth().verifyIdToken(token);
        req.user = decodedToken; // Attach user info (uid, email) to request
        next();
    } catch (error) {
        console.error("Token verification failed:", error);
        return res.status(401).json({ error: 'Unauthorized: Invalid token' });
    }
};

// --- 3. MongoDB Connection ---
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/xpensia';
console.log('Connecting to MongoDB:', MONGO_URI.replace(/:([^:@]+)@/, ':****@')); // Log masked URI for debugging

mongoose.connect(MONGO_URI)
    .then(() => console.log('MongoDB Connected Successfully'))
    .catch(err => console.error('MongoDB Connection Error:', err));

// --- 4. API Endpoints ---

// GET /getExpenses - Fetch all transactions for the logged-in user
app.get('/getExpenses', verifyToken, async (req, res) => {
    try {
        console.log(`Fetching expenses for user: ${req.user.uid}`);
        const expenses = await Transaction.find({ userId: req.user.uid }).sort({ date: -1 });
        console.log(`Found ${expenses.length} transactions.`);
        res.json({ success: true, expenses });
    } catch (err) {
        console.error("Error fetching expenses:", err);
        res.status(500).json({ success: false, error: err.message });
    }
});

// POST /addExpense - Add a new transaction
app.post('/addExpense', verifyToken, async (req, res) => {
    try {
        const { expenseID, title, amount, category, description, date, type } = req.body;

        const newTransaction = new Transaction({
            userId: req.user.uid, // Securely set userId from token
            expenseID,
            title,
            amount,
            category,
            description,
            date,
            type
        });

        await newTransaction.save();
        res.json({ success: true, message: 'Transaction added', data: newTransaction });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// PUT /updateExpense - Update a transaction (must belong to user)
app.put('/updateExpense', verifyToken, async (req, res) => {
    try {
        const { expenseID, ...updates } = req.body;

        const updatedTransaction = await Transaction.findOneAndUpdate(
            { expenseID: expenseID, userId: req.user.uid }, // Ensure user owns it
            { $set: updates },
            { new: true }
        );

        if (!updatedTransaction) {
            return res.status(404).json({ success: false, message: 'Transaction not found or unauthorized' });
        }

        res.json({ success: true, message: 'Transaction updated', data: updatedTransaction });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// DELETE /deleteExpense - Delete a transaction
app.delete('/deleteExpense', verifyToken, async (req, res) => {
    try {
        const { expenseID } = req.body;

        const deletedTransaction = await Transaction.findOneAndDelete({
            expenseID: expenseID,
            userId: req.user.uid
        });

        if (!deletedTransaction) {
            return res.status(404).json({ success: false, message: 'Transaction not found or unauthorized' });
        }

        res.json({ success: true, message: 'Transaction deleted' });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
