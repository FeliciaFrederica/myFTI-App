# myFTI - Digital Wallet & Transaction Management

**myFTI** is a mobile-based digital wallet application developed for the Faculty of Information Technology (FTI), Tarumanagara University. The application provides separate interfaces for two user roles: **Students** and **Merchants**.

Students can manage their wallet balance and perform various digital transactions, while merchants can monitor their wallet balance and incoming payment transactions through a dedicated dashboard.

## Features

### Student Features
- **Home** - View wallet balance, recent transactions, and quick access to features.
- **My Wallet** - View wallet information and balance.
- **Top Up** - Add balance to the digital wallet.
- **Transfer** - Transfer balance to other users.
- **Withdraw** - Withdraw balance from the wallet.
- **Payment** - Make payments to registered merchants.
- **Transaction History** - View transaction records.
- **Transaction Detail** - View detailed transaction information.
- **Financial Summary** - Review financial activity and summaries.
- **Notifications** - Receive application notifications.
- **Profile & Settings** - Manage account information and application settings.

### Merchant Features
- **Home** - View merchant dashboard and incoming payment summaries.
- **My Wallet** - View merchant wallet balance and wallet information.
- **Transaction History** - View incoming payment transaction records.
- **Transaction Filters** - Filter transaction records by All Time, This Week, and This Month.
- **Auto Refresh** - Automatically update wallet balance and transaction information.
- **Automatic Withdrawal** - Automatically withdraw received payment balances according to the application's configured process.
- **Profile** - View merchant account information.

**Note**: Merchant accounts are pre-configured and seeded by the developer. Merchant users have read-only access to their wallet and transaction information and cannot perform student transactions such as top-ups, transfers, or payments.

## Technologies Used
- **Flutter** - Mobile application development.
- **Dart** - Programming language.
- **Node.js & Express.js** - Backend development.
- **Prisma ORM** - Database management.
- **PostgreSQL** - Database.
- **REST API** - Communication between frontend and backend.

## Getting Started

### Prerequisites

Make sure you have installed:
- Flutter SDK
- Dart SDK
- Node.js and npm
- Android Studio or Visual Studio Code
- Git
- PostgreSQL

### 1. Clone Repository

  ```bash
   git clone https://github.com/FeliciaFrederica/myFTI-App.git
   ```

### 2. Backend Setup

Navigate to the backend directory:
   
   ```bash
   cd myfti_backend
   ```

Install dependencies:

   ```bash
   npm install
   ```

Create your environment configuration file by copying the example:

   ```bash
   cp .env.example .env
   ```

For Windows PowerShell:

   ```bash
   Copy-Item .env.example .env
   ```

Update the .env file with your own PostgreSQL database credentials and JWT secret.

#### Database Setup

Generate the Prisma Client:

   ```bash
   npx prisma generate
   ```

Apply database migrations:

   ```bash
   npx prisma migrate deploy
   ```

Run database seeding to initialize the required data, including merchant accounts:

   ```bash
   npx prisma db seed
   ```

Make sure your PostgreSQL database is running and properly configured before proceeding.

#### Start Backend Server

   ```bash
   npm run dev
   ```

Keep the backend server running while using the application.

### 3. Flutter Application Setup

Open another terminal and navigate to the Flutter application directory:

   ```bash
   cd myfti_app
   ```

Install Flutter dependencies:

   ```bash
   flutter pub get
   ```

Configure the API base URL to connect to the backend server.
Run the application:

   ```bash
   flutter run
   ```

**Note:** The backend server must be running before launching the Flutter application. Make sure the database and API configuration are properly set up.

## Project Information

This project was developed by Group A01 as the final project for the **Mobile Programming** course at the Faculty of Information Technology, Tarumanagara University.

| Nama Lengkap                | NIM       |
| -----------------------     | --------- |
| Vianlienra Hung             | 535250012 |
| Muhamad Airlangga Khairudin | 535250022 |
| Felicia Marmara Putri       | 535250025 |
| Felicia Frederica           | 535250027 |
| Charly                      | 535250039 |

---
