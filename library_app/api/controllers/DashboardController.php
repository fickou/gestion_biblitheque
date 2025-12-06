<?php
// api/controllers/DashboardController.php
class DashboardController {
    private $conn;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function getStats() {
        $stats = [];
        
        // Total livres
        $query = "SELECT COUNT(*) as total FROM Books";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        $stats['totalBooks'] = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
        
        // Total étudiants
        $query = "SELECT COUNT(*) as total FROM Users WHERE roleId = '3'";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        $stats['totalStudents'] = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
        
        // Livres empruntés
        $query = "SELECT COUNT(*) as total FROM Emprunts WHERE status IN ('En cours', 'En retard')";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        $stats['borrowedBooks'] = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
        
        // Livres en retard
        $query = "SELECT COUNT(*) as total FROM Emprunts WHERE status = 'En retard'";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        $stats['lateBooks'] = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
        
        // Nouveaux livres ce mois
        $query = "SELECT COUNT(*) as total FROM Books 
                  WHERE YEAR(createdAt) = YEAR(CURRENT_DATE) 
                  AND MONTH(createdAt) = MONTH(CURRENT_DATE)";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        $stats['newBooksThisMonth'] = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
        
        // Réservations en attente
        $query = "SELECT COUNT(*) as total FROM Reservations WHERE status = 'En attente'";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        $stats['pendingReservations'] = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
        
        return $stats;
    }

    public function getTopBooks($limit = 5) {
        $query = "SELECT b.id, b.title, b.author, c.name as category,
                         COUNT(e.id) as loanCount, b.copies, b.available
                  FROM Books b
                  LEFT JOIN Categories c ON b.categoryId = c.id
                  LEFT JOIN Emprunts e ON b.id = e.bookId
                  GROUP BY b.id, b.title, b.author, c.name, b.copies, b.available
                  ORDER BY loanCount DESC, b.title
                  LIMIT ?";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $limit, PDO::PARAM_INT);
        $stmt->execute();
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getRecentActivities($limit = 10) {
        $query = "(
            SELECT 'emprunt' as type, 
                   CONCAT(u.name, ' a emprunté \'', b.title, '\'') as title,
                   e.createdAt as date,
                   u.id as userId,
                   b.id as bookId
            FROM Emprunts e
            JOIN Users u ON e.userId = u.id
            JOIN Books b ON e.bookId = b.id
            WHERE e.createdAt >= DATE_SUB(CURRENT_DATE, INTERVAL 7 DAY)
        )
        UNION ALL
        (
            SELECT 'reservation' as type,
                   CONCAT(u.name, ' a réservé \'', b.title, '\'') as title,
                   r.createdAt as date,
                   u.id as userId,
                   b.id as bookId
            FROM Reservations r
            JOIN Users u ON r.userId = u.id
            JOIN Books b ON r.bookId = b.id
            WHERE r.createdAt >= DATE_SUB(CURRENT_DATE, INTERVAL 7 DAY)
        )
        UNION ALL
        (
            SELECT 'retard' as type,
                   CONCAT('Livre en retard : \'', b.title, '\'') as title,
                   e.returnDate as date,
                   u.id as userId,
                   b.id as bookId
            FROM Emprunts e
            JOIN Users u ON e.userId = u.id
            JOIN Books b ON e.bookId = b.id
            WHERE e.status = 'En retard' 
            AND e.returnDate >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
        )
        ORDER BY date DESC
        LIMIT ?";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $limit, PDO::PARAM_INT);
        $stmt->execute();
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getCategoryStats() {
        $query = "SELECT c.id, c.name, 
                  COUNT(b.id) as totalBooks,
                  SUM(CASE WHEN b.available = 1 THEN 1 ELSE 0 END) as availableBooks,
                  COUNT(DISTINCT e.userId) as uniqueBorrowers
                  FROM Categories c
                  LEFT JOIN Books b ON c.id = b.categoryId
                  LEFT JOIN Emprunts e ON b.id = e.bookId 
                  AND e.borrowDate >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
                  GROUP BY c.id, c.name
                  ORDER BY totalBooks DESC";
        
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}