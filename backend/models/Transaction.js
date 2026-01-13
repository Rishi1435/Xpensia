const mongoose = require('mongoose');

const TransactionSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
    index: true // Index for faster queries by user
  },
  expenseID: {
    type: String,
    required: true,
    unique: true
  },
  title: {
    type: String,
    required: true
  },
  amount: {
    type: Number,
    required: true
  },
  category: {
    type: String,
    required: true
  },
  description: {
    type: String, // Stores original SMS or user notes
    default: ''
  },
  date: {
    type: String, // Storing as ISO Date String from Flutter
    required: true
  },
  type: {
    type: String,
    enum: ['CREDIT', 'DEBIT'],
    default: 'DEBIT'
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Transaction', TransactionSchema);
