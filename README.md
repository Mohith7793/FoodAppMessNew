# 🍱 Student Mess Food Ordering Platform

A complete **Student Mess / Food Ordering Platform** with Flutter mobile app + Node.js backend.

---

## Tech Stack

| Layer      | Technology                        |
|------------|-----------------------------------|
| Mobile App | Flutter (Dart)                    |
| Backend    | Node.js + Express                 |
| Database   | PostgreSQL                        |
| ORM        | Sequelize                         |
| Auth       | JWT (JSON Web Tokens)             |
| Passwords  | bcryptjs                          |
| State Mgmt | Provider (Flutter)                |

---

## Project Structure

```
FoodAppMessNew/
├── backend/                  # Node.js Express API
│   ├── config/
│   │   └── database.js
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── productController.js
│   │   ├── cartController.js
│   │   └── orderController.js
│   ├── middleware/
│   │   └── authMiddleware.js
│   ├── models/
│   │   ├── User.js
│   │   ├── Product.js
│   │   ├── Cart.js
│   │   ├── CartItem.js
│   │   ├── Order.js
│   │   └── OrderItem.js
│   ├── routes/
│   │   ├── authRoutes.js
│   │   ├── productRoutes.js
│   │   ├── cartRoutes.js
│   │   └── orderRoutes.js
│   ├── migrations/           # Sequelize CLI migrations
│   ├── seeders/              # Sample data
│   ├── app.js
│   └── server.js
│
└── flutter_app/              # Flutter mobile app
    └── lib/
        ├── main.dart
        ├── models/
        ├── providers/
        ├── screens/
        ├── services/
        └── widgets/
```

---

## Step 1 — Backend Setup

### Prerequisites
- Node.js 18+
- PostgreSQL 14+

### Install Dependencies
```bash
cd backend
npm install
```

### Configure Environment
```bash
cp .env.example .env
# Edit .env with your PostgreSQL credentials
```

`.env` file:
```
PORT=5000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=food_mess_db
DB_USER=postgres
DB_PASSWORD=yourpassword
JWT_SECRET=your_super_secret_jwt_key
JWT_EXPIRES_IN=7d
NODE_ENV=development
```

---

## Step 2 — Database Migrations

### Create Database
```sql
-- In PostgreSQL:
CREATE DATABASE food_mess_db;
```

### Generate Migrations (already created, just run them)
```bash
cd backend

# Run all migrations
npx sequelize-cli db:migrate

# Seed sample food products
npx sequelize-cli db:seed:all
```

### Reset Database (if needed)
```bash
npm run db:reset
```

### Migration Commands Reference
```bash
# Generate new migration
npx sequelize-cli migration:generate --name create-users-table
npx sequelize-cli migration:generate --name create-products-table
npx sequelize-cli migration:generate --name create-carts-table
npx sequelize-cli migration:generate --name create-cart-items-table
npx sequelize-cli migration:generate --name create-orders-table
npx sequelize-cli migration:generate --name create-order-items-table
```

---

## Step 3 — Run Backend

```bash
cd backend

# Development (with auto-restart)
npm run dev

# Production
npm start
```

Backend runs at: `http://localhost:5000`

Health check: `GET http://localhost:5000/health`

---

## Step 4 — Flutter App Setup

### Prerequisites
- Flutter SDK 3.x
- Android Studio / Xcode

### Install Dependencies
```bash
cd flutter_app
flutter pub get
```

### Configure API URL

Edit `lib/services/api_service.dart`:
```dart
// Android Emulator:
static const String baseUrl = 'http://10.0.2.2:5000/api';

// iOS Simulator:
static const String baseUrl = 'http://localhost:5000/api';

// Physical Device (replace with your machine's IP):
static const String baseUrl = 'http://192.168.1.X:5000/api';
```

### Run App
```bash
cd flutter_app
flutter run
```

---

## Step 5 — API Endpoints

### Auth
| Method | Endpoint              | Description        | Auth |
|--------|-----------------------|--------------------|------|
| POST   | /api/auth/register    | Register customer  | No   |
| POST   | /api/auth/login       | Login              | No   |
| GET    | /api/auth/me          | Get profile        | Yes  |

### Products
| Method | Endpoint              | Description         | Auth  |
|--------|-----------------------|---------------------|-------|
| GET    | /api/products         | List all products   | No    |
| GET    | /api/products/:id     | Get product         | No    |
| POST   | /api/products         | Create (Admin)      | Admin |
| PUT    | /api/products/:id     | Update (Admin)      | Admin |
| DELETE | /api/products/:id     | Delete (Admin)      | Admin |

### Cart
| Method | Endpoint          | Description        | Auth |
|--------|-------------------|--------------------|------|
| GET    | /api/cart         | Get cart           | Yes  |
| POST   | /api/cart/add     | Add item           | Yes  |
| PUT    | /api/cart/update  | Update quantity    | Yes  |
| DELETE | /api/cart/remove  | Remove item        | Yes  |
| DELETE | /api/cart/clear   | Clear cart         | Yes  |

### Orders
| Method | Endpoint              | Description     | Auth |
|--------|-----------------------|-----------------|------|
| POST   | /api/orders/create    | Place order     | Yes  |
| GET    | /api/orders           | List my orders  | Yes  |
| GET    | /api/orders/:id       | Get order       | Yes  |

---

## Step 6 — Sample API Calls

### Register
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name": "Rahul Kumar", "email": "rahul@college.edu", "password": "password123"}'
```

### Login
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "rahul@college.edu", "password": "password123"}'
```

### Get Products
```bash
curl http://localhost:5000/api/products
```

### Add to Cart
```bash
curl -X POST http://localhost:5000/api/cart/add \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"product_id": 1, "quantity": 2}'
```

### Place Order
```bash
curl -X POST http://localhost:5000/api/orders/create \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"notes": "Less spicy please"}'
```

### Create Admin Product (Admin only)
```bash
# First create admin user directly in DB:
# UPDATE "Users" SET role='admin' WHERE email='admin@mess.com';

curl -X POST http://localhost:5000/api/products \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ADMIN_JWT_TOKEN" \
  -d '{
    "name": "Special Thali",
    "description": "Complete meal with rice, dal, sabzi, roti, and dessert.",
    "price": 150,
    "category": "Main Course",
    "stock": 50
  }'
```

---

## Flutter App Features

- **Login Screen** — Email/password login with validation
- **Register Screen** — Full registration with confirm password
- **Home Screen** — Product grid with category filter + search
- **Product Cards** — Image, name, price, quantity selector, add to cart
- **Cart Screen** — Item list, quantity controls, order summary, place order
- **Orders Screen** — Order history with status badges, tap for detail
- **Profile Screen** — User info and stats
- **Side Drawer** — Navigation: Home, Cart, Orders, Profile, Logout

---

## Database Schema

```
Users       → id, name, email, password, role, email_verified
Products    → id, name, description, price, image_url, stock, category
Carts       → id, user_id
CartItems   → id, cart_id, product_id, quantity
Orders      → id, user_id, total_price, status, notes
OrderItems  → id, order_id, product_id, quantity, price
```

---

## Notes

- Email verification is set to `true` by default (testing mode)
- Admin role must be set manually in DB for now
- Product images use Unsplash URLs (internet required)
- JWT tokens expire in 7 days
