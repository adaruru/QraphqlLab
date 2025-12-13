package model

import "time"

// User 使用者資料模型
type User struct {
	ID        int       `json:"id" db:"id"`
	Name      string    `json:"name" db:"name"`
	Email     string    `json:"email" db:"email"`
	Age       int       `json:"age" db:"age"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

// Salary 薪資明細模型
type Salary struct {
	ID     int     `json:"id" db:"id"`
	UserID int     `json:"user_id" db:"user_id"`
	Amount float64 `json:"amount" db:"amount"`
	Month  string  `json:"month" db:"month"`
}

// EmploymentStatus 到職狀態模型
type EmploymentStatus struct {
	ID         int       `json:"id" db:"id"`
	UserID     int       `json:"user_id" db:"user_id"`
	Status     string    `json:"status" db:"status"`
	StartDate  time.Time `json:"start_date" db:"start_date"`
	Department string    `json:"department" db:"department"`
}
