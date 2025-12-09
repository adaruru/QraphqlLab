# Database Initialization

This directory contains SQL scripts to initialize the GraphQL Lab database.

## Database Schema

### Tables

1. **users** - Core user information
   - id, username, email, full_name, department, position, hire_date

2. **employment_status** - Employment status history
   - id, user_id, status (active/on_leave/probation/resigned/terminated), start_date, end_date, notes

3. **salaries** - Salary information and history
   - id, user_id, base_salary, bonus, currency, effective_date, end_date, payment_frequency

### Relationships

- `employment_status.user_id` → `users.id` (Foreign Key)
- `salaries.user_id` → `users.id` (Foreign Key)

These relationships enable GraphQL join operations between users, their employment status, and salary information.

## Setup Instructions

### 1. Create Database

```bash
mysql -u root -p
```

```sql
CREATE DATABASE graphqllab CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 2. Initialize Schema

```bash
mysql -u root -p graphqllab < schema.sql
```

### 3. Load Test Data

```bash
mysql -u root -p graphqllab < seed.sql
```

### Quick Setup (All-in-One)

```bash
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS graphqllab CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p graphqllab < schema.sql
mysql -u root -p graphqllab < seed.sql
```

## Test Data Overview

The seed data includes:
- 10 test users across different departments (Engineering, Product, Sales, Marketing, HR, Finance)
- Employment status records (active, on_leave, probation)
- Current and historical salary records
- Relationships demonstrating GraphQL join capabilities

## Verification

After setup, verify the data:

```sql
-- Check users
SELECT * FROM users;

-- Check employment status
SELECT u.username, u.full_name, es.status, es.start_date
FROM users u
LEFT JOIN employment_status es ON u.id = es.user_id
WHERE es.end_date IS NULL;

-- Check current salaries
SELECT u.username, u.full_name, s.base_salary, s.bonus
FROM users u
LEFT JOIN salaries s ON u.id = s.user_id
WHERE s.end_date IS NULL;

-- Complex join (users with status and salary)
SELECT
    u.username,
    u.full_name,
    u.department,
    es.status,
    s.base_salary,
    s.bonus
FROM users u
LEFT JOIN employment_status es ON u.id = es.user_id AND es.end_date IS NULL
LEFT JOIN salaries s ON u.id = s.user_id AND s.end_date IS NULL;
```

## Notes

- All monetary values are in TWD (New Taiwan Dollar)
- Salary records support historical tracking (effective_date and end_date)
- Employment status supports status change history
- Foreign key constraints ensure referential integrity
