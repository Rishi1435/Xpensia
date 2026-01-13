# Backend Implementation Guide (Node.js + MongoDB + Firebase)

## Overview
This architectural change replaces AWS with:
1.  **Authentication**: Firebase Authentication (Client Side).
2.  **Database**: MongoDB (Atlas) for storing transactions.
3.  **Backend API**: Node.js (Express) hosting the REST API, secured by Firebase Admin SDK.

## 1. Firebase Setup (Client Side)
1.  Go to **Firebase Console** -> Add Project.
2.  Add **Android/iOS** apps (download `google-services.json` / `GoogleService-Info.plist`).
3.  Enable **Authentication** -> **Email/Password** and **Google**.
4.  (Flutter) The app uses `firebase_auth` to sign in.
5.  **Token**: The app gets a JWT via `user.getIdToken()` and sends it to the Node.js backend.

## 2. MongoDB Setup (Data Layer)
1.  Create a **MongoDB Atlas** Cluster (Free Tier).
2.  Create a Database user (username/password).
3.  Get the **Connection String** (e.g., `mongodb+srv://...`).
4.  Create a Database: `XpensiaDB`.
5.  Create a Collection: `transactions` (or `expenses`).
    *   **Schema**:
        ```json
        {
          "userId": "String (Index)",
          "expenseID": "String (Unique)",
          "title": "String",
          "amount": "Number",
          "date": "Date/String",
          "category": "String",
          "type": "String (CREDIT/DEBIT)"
        }
        ```

## 3. Node.js Backend API
Build a simple Express server to handle API calls.

### Dependencies
`npm install express mongoose firebase-admin cors dotenv`

### Logic Flow
1.  **Middleware**:
    *   Intercepts requests.
    *   Reads `Authorization: Bearer <token>`.
    *   Verifies token using `admin.auth().verifyIdToken(token)`.
    *   Extracts `uid` (User ID) and attaches it to `req.user.uid`.
    *   *If invalid, return 401 Unauthorized.*

2.  **Endpoints**:
    *   `POST /addExpense`:
        *   Create new Mongoose Document.
        *   Set `userId` = `req.user.uid`.
        *   Save.
    *   `GET /getExpenses`:
        *   `Transaction.find({ userId: req.user.uid })`.
    *   `PUT /updateExpense`:
        *   `Transaction.findOneAndUpdate({ expenseID: ..., userId: req.user.uid }, ...)`
    *   `DELETE /deleteExpense`:
        *   `Transaction.findOneAndDelete({ expenseID: ..., userId: req.user.uid })`

## 4. Flutter Integration
1.  **Dependencies**: `firebase_auth`, `firebase_core`.
2.  **Auth Flow**:
    *   Login Screen -> `FirebaseAuth.instance.signIn...`
3.  **API Calls**:
    *   Get Token: `await FirebaseAuth.instance.currentUser?.getIdToken()`.
    *   Headers: `Authorization: Bearer <token>`.

## 5. Deployment
*   **Backend**: Deploy Node.js app to **Render**, **Heroku**, or **Vercel** (all have free tiers).
*   **Database**: MongoDB Atlas (Free Tier).
*   **Auth**: Firebase (Free Tier).

This stack is entirely **Free Tier friendly**.
