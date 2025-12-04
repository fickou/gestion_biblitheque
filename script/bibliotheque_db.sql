-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Hôte : 127.0.0.1
-- Généré le : ven. 05 déc. 2025 à 00:19
-- Version du serveur : 10.4.32-MariaDB
-- Version de PHP : 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `bibliotheque_db`
--

DELIMITER $$
--
-- Procédures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `BorrowBook` (IN `p_bookId` VARCHAR(50), IN `p_userId` VARCHAR(50), IN `p_borrowDate` DATE, IN `p_days` INT)   BEGIN
    DECLARE bookAvailable BOOLEAN;
    DECLARE userRole VARCHAR(50);
    DECLARE loanPeriod INT;
    
    -- Vérifier la disponibilité du livre
    SELECT available INTO bookAvailable FROM Books WHERE id = p_bookId;
    
    -- Obtenir le rôle de l'utilisateur pour déterminer la période d'emprunt
    SELECT roleId INTO userRole FROM Users WHERE id = p_userId;
    
    -- Déterminer la période d'emprunt selon le rôle
    IF userRole = '4' THEN -- Professeur
        SET loanPeriod = 60; -- 60 jours pour les professeurs
    ELSE
        SET loanPeriod = 30; -- 30 jours pour les autres
    END IF;
    
    IF bookAvailable = TRUE THEN
        -- Mettre à jour la disponibilité du livre
        UPDATE Books 
        SET available = FALSE, copies = copies - 1 
        WHERE id = p_bookId AND copies > 0;
        
        -- Créer l'emprunt
        INSERT INTO Emprunts (id, bookId, userId, borrowDate, returnDate, status)
        VALUES (
            UUID(),
            p_bookId,
            p_userId,
            p_borrowDate,
            DATE_ADD(p_borrowDate, INTERVAL loanPeriod DAY),
            'En cours'
        );
        
        SELECT 'SUCCESS' as status, 'Livre emprunté avec succès' as message;
    ELSE
        SELECT 'ERROR' as status, 'Livre non disponible' as message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ReturnBook` (IN `p_empruntId` VARCHAR(50))   BEGIN
    DECLARE v_bookId VARCHAR(50);
    DECLARE v_status VARCHAR(50);
    
    -- Récupérer les informations de l'emprunt
    SELECT bookId, status INTO v_bookId, v_status
    FROM Emprunts WHERE id = p_empruntId;
    
    IF v_status = 'En cours' OR v_status = 'En retard' THEN
        -- Mettre à jour le statut de l'emprunt
        UPDATE Emprunts 
        SET status = 'Retourné' 
        WHERE id = p_empruntId;
        
        -- Réincrémenter les copies disponibles
        UPDATE Books 
        SET copies = copies + 1,
            available = CASE 
                WHEN copies + 1 > 0 THEN TRUE 
                ELSE FALSE 
            END
        WHERE id = v_bookId;
        
        SELECT 'SUCCESS' as status, 'Livre retourné avec succès' as message;
    ELSE
        SELECT 'ERROR' as status, 'Emprunt déjà retourné ou annulé' as message;
    END IF;
END$$

--
-- Fonctions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `CheckLateLoans` (`p_userId` VARCHAR(50)) RETURNS INT(11) DETERMINISTIC BEGIN
    DECLARE lateCount INT;
    
    SELECT COUNT(*) INTO lateCount
    FROM Emprunts
    WHERE userId = p_userId 
      AND status = 'En retard';
    
    RETURN lateCount;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `books`
--

CREATE TABLE `books` (
  `id` varchar(50) NOT NULL,
  `title` varchar(200) NOT NULL,
  `author` varchar(100) NOT NULL,
  `available` tinyint(1) DEFAULT 1,
  `categoryId` varchar(50) NOT NULL,
  `year` varchar(10) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `copies` int(11) DEFAULT 1,
  `isbn` varchar(20) DEFAULT NULL,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `books`
--

INSERT INTO `books` (`id`, `title`, `author`, `available`, `categoryId`, `year`, `description`, `copies`, `isbn`, `createdAt`, `updatedAt`) VALUES
('1', 'Introduction à Python', 'J. Dupont', 1, '1', '2023', 'Un guide complet pour apprendre les bases de la programmation Python.', 2, '978-1234567890', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('10', 'Data Mining et Machine Learning', 'K. Lee', 1, '1', '2024', 'Data Mining et Machine Learning avancés.', 2, '978-1234567899', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('11', 'Python pour la Data Science', 'S. Chen', 1, '1', '2023', 'Python appliqué à la data science.', 1, '978-1234567900', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('12', 'Bases de données avancées', 'L. Rossi', 0, '1', '2024', 'Concepts avancés de bases de données.', 1, '978-1234567901', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('13', 'Deep Learning avec TensorFlow', 'M. Kim', 1, '1', '2024', 'Deep Learning avec TensorFlow 2.x.', 2, '978-1234567902', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('14', 'Systèmes Distribués', 'P. Müller', 1, '1', '2023', 'Conception de systèmes distribués.', 1, '978-1234567903', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('15', 'Histoire de l\'Informatique', 'J. Watson', 1, '7', '2023', 'Histoire de l\'évolution de l\'informatique.', 1, '978-1234567904', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('16', 'Économie Numérique', 'A. Smith', 1, '8', '2024', 'Les principes de l\'économie numérique.', 2, '978-1234567905', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('2', 'Mathématiques Appliquées', 'M. Martin', 1, '2', '2022', 'Mathématiques pour les sciences appliquées.', 1, '978-1234567891', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('3', 'Physique Quantique', 'A. Bernard', 0, '3', '2021', 'Introduction à la physique quantique moderne.', 0, '978-1234567892', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('4', 'Chimie Organique', 'L. Petit', 1, '4', '2023', 'Fondamentaux de la chimie organique.', 3, '978-1234567893', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('5', 'Algorithmique Avancée', 'P. Dubois', 1, '1', '2023', 'Algorithmes avancés et structures de données.', 2, '978-1234567894', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('6', 'Base de Données', 'S. Laurent', 0, '1', '2022', 'Conception et gestion de bases de données.', 0, '978-1234567895', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('7', 'Intelligence Artificielle', 'R. Thomas', 1, '1', '2024', 'Introduction à l\'intelligence artificielle moderne.', 1, '978-1234567896', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('8', 'Biologie Moléculaire', 'C. Moreau', 1, '5', '2023', 'Introduction à la biologie moléculaire.', 1, '978-1234567897', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('9', 'Introduction à l\'Algorithmique', 'T. Blanc', 0, '1', '2023', 'Bases de l\'algorithmique.', 1, '978-1234567898', '2025-12-04 23:13:33', '2025-12-04 23:13:33');

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `booksbycategory`
-- (Voir ci-dessous la vue réelle)
--
CREATE TABLE `booksbycategory` (
`categoryId` varchar(50)
,`categoryName` varchar(100)
,`totalBooks` bigint(21)
,`availableBooks` decimal(22,0)
,`totalCopies` decimal(32,0)
,`activeBorrowers` bigint(21)
);

-- --------------------------------------------------------

--
-- Structure de la table `categories`
--

CREATE TABLE `categories` (
  `id` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `categories`
--

INSERT INTO `categories` (`id`, `name`, `description`, `createdAt`, `updatedAt`) VALUES
('1', 'Informatique', 'Livres sur la programmation, les bases de données, l\'intelligence artificielle', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('2', 'Mathématiques', 'Livres sur les mathématiques pures et appliquées', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('3', 'Physique', 'Livres sur la physique classique et moderne', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('4', 'Chimie', 'Livres sur la chimie organique, inorganique et analytique', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('5', 'Biologie', 'Livres sur la biologie moléculaire, cellulaire et évolutive', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('6', 'Littérature', 'Romans, poésie, théâtre et autres œuvres littéraires', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('7', 'Histoire', 'Livres sur l\'histoire mondiale et régionale', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('8', 'Économie', 'Livres sur l\'économie, la finance et le commerce', '2025-12-04 23:13:33', '2025-12-04 23:13:33');

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `dashboardstats`
-- (Voir ci-dessous la vue réelle)
--
CREATE TABLE `dashboardstats` (
`totalBooks` bigint(21)
,`totalStudents` bigint(21)
,`borrowedBooks` bigint(21)
,`lateBooks` bigint(21)
,`newBooksThisMonth` bigint(21)
,`pendingReservations` bigint(21)
,`activeUsersThisMonth` bigint(21)
,`totalProfessors` bigint(21)
);

-- --------------------------------------------------------

--
-- Structure de la table `emprunthistory`
--

CREATE TABLE `emprunthistory` (
  `id` varchar(50) NOT NULL,
  `empruntId` varchar(50) NOT NULL,
  `action` varchar(50) NOT NULL,
  `oldStatus` varchar(50) DEFAULT NULL,
  `newStatus` varchar(50) DEFAULT NULL,
  `changedBy` varchar(50) DEFAULT NULL,
  `changeDate` timestamp NOT NULL DEFAULT current_timestamp(),
  `notes` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `emprunts`
--

CREATE TABLE `emprunts` (
  `id` varchar(50) NOT NULL,
  `bookId` varchar(50) NOT NULL,
  `userId` varchar(50) NOT NULL,
  `borrowDate` date NOT NULL,
  `returnDate` date NOT NULL,
  `status` varchar(50) NOT NULL,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `emprunts`
--

INSERT INTO `emprunts` (`id`, `bookId`, `userId`, `borrowDate`, `returnDate`, `status`, `createdAt`) VALUES
('1', '1', '1', '2025-01-05', '2025-02-05', 'En cours', '2025-12-04 23:13:33'),
('2', '6', '2', '2024-12-20', '2025-01-10', 'En retard', '2025-12-04 23:13:33'),
('3', '7', '1', '2025-01-08', '2025-02-08', 'En cours', '2025-12-04 23:13:33'),
('4', '9', '2', '2025-01-02', '2025-02-02', 'En retard', '2025-12-04 23:13:33'),
('5', '12', '6', '2024-12-15', '2025-01-15', 'En retard', '2025-12-04 23:13:33'),
('6', '13', '8', '2025-01-05', '2025-02-05', 'En cours', '2025-12-04 23:13:33'),
('7', '15', '11', '2025-01-10', '2025-03-10', 'En cours', '2025-12-04 23:13:33');

-- --------------------------------------------------------

--
-- Structure de la table `notifications`
--

CREATE TABLE `notifications` (
  `id` varchar(50) NOT NULL,
  `type` varchar(50) NOT NULL,
  `title` varchar(200) NOT NULL,
  `message` text NOT NULL,
  `time` varchar(100) DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `iconName` varchar(50) DEFAULT NULL,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `userId` varchar(50) DEFAULT NULL,
  `relatedBookId` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `notifications`
--

INSERT INTO `notifications` (`id`, `type`, `title`, `message`, `time`, `is_read`, `iconName`, `createdAt`, `userId`, `relatedBookId`) VALUES
('1', 'late', 'Livre en retard', 'Le livre \'Introduction à l\'Algorithmique\' emprunté par Amadou Diallo est en retard de 3 jours.', 'Il y a 5 minutes', 0, 'AlertCircle', '2025-12-04 23:13:33', '2', '9'),
('2', 'loan', 'Nouvel emprunt', 'Fatou Sall a emprunté \'Data Mining et Machine Learning\'.', 'Il y a 15 minutes', 0, 'BookOpen', '2025-12-04 23:13:33', '3', '10'),
('3', 'return', 'Retour de livre', 'Moussa Ndiaye a retourné \'Python pour la Data Science\'.', 'Il y a 1 heure', 1, 'CheckCircle', '2025-12-04 23:13:33', '4', '11'),
('4', 'user', 'Nouvel utilisateur', 'Aïssatou Ba s\'est inscrite dans le système.', 'Il y a 2 heures', 1, 'User', '2025-12-04 23:13:33', '5', NULL),
('5', 'late', 'Livre en retard', 'Le livre \'Bases de données avancées\' emprunté par Ibrahima Sarr est en retard de 7 jours.', 'Il y a 3 heures', 0, 'AlertCircle', '2025-12-04 23:13:33', '6', '12'),
('6', 'reservation', 'Nouvelle réservation', 'Mariama Sy a réservé \'Deep Learning avec TensorFlow\'.', 'Il y a 4 heures', 1, 'Clock', '2025-12-04 23:13:33', '7', '13'),
('7', 'return', 'Retour de livre', 'Cheikh Fall a retourné \'Intelligence Artificielle\'.', 'Hier', 1, 'CheckCircle', '2025-12-04 23:13:33', '8', '7'),
('8', 'loan', 'Nouvel emprunt', 'Amadou Diallo a emprunté \'Systèmes Distribués\'.', 'Hier', 1, 'BookOpen', '2025-12-04 23:13:33', '2', '14'),
('9', 'reservation', 'Nouvelle réservation', 'Un nouvel utilisateur a réservé \'Base de Données\'.', 'Il y a 30 minutes', 0, 'Clock', '2025-12-04 23:13:33', '5', '6');

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `recentactivities`
-- (Voir ci-dessous la vue réelle)
--
CREATE TABLE `recentactivities` (
`activityType` varchar(11)
,`title` varchar(314)
,`activityDate` datetime
,`iconName` varchar(11)
,`color` varchar(6)
,`userId` varchar(50)
,`bookId` varchar(50)
);

-- --------------------------------------------------------

--
-- Structure de la table `reservations`
--

CREATE TABLE `reservations` (
  `id` varchar(50) NOT NULL,
  `bookId` varchar(50) NOT NULL,
  `userId` varchar(50) NOT NULL,
  `reserveDate` date NOT NULL,
  `status` varchar(50) NOT NULL,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `reservations`
--

INSERT INTO `reservations` (`id`, `bookId`, `userId`, `reserveDate`, `status`, `createdAt`) VALUES
('1', '3', '3', '2025-01-10', 'En attente', '2025-12-04 23:13:33'),
('2', '4', '4', '2025-01-08', 'Disponible', '2025-12-04 23:13:33'),
('3', '13', '7', '2025-01-09', 'En attente', '2025-12-04 23:13:33'),
('4', '6', '5', '2025-01-12', 'En attente', '2025-12-04 23:13:33');

-- --------------------------------------------------------

--
-- Structure de la table `roles`
--

CREATE TABLE `roles` (
  `id` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `permissions` text DEFAULT NULL,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `roles`
--

INSERT INTO `roles` (`id`, `name`, `permissions`, `createdAt`, `updatedAt`) VALUES
('1', 'Administrateur', '{\"manage_users\": true, \"manage_books\": true, \"manage_loans\": true, \"view_reports\": true}', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('2', 'Bibliothécaire', '{\"manage_books\": true, \"manage_loans\": true, \"view_reports\": true}', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('3', 'Étudiant', '{\"borrow_books\": true, \"reserve_books\": true, \"view_own_loans\": true}', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('4', 'Professeur', '{\"borrow_books\": true, \"reserve_books\": true, \"extended_loan_period\": true, \"view_own_loans\": true}', '2025-12-04 23:13:33', '2025-12-04 23:13:33');

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `topbooks`
-- (Voir ci-dessous la vue réelle)
--
CREATE TABLE `topbooks` (
`id` varchar(50)
,`title` varchar(200)
,`author` varchar(100)
,`category` varchar(100)
,`loanCount` bigint(21)
,`copies` int(11)
,`available` tinyint(1)
);

-- --------------------------------------------------------

--
-- Structure de la table `users`
--

CREATE TABLE `users` (
  `id` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `matricule` varchar(50) NOT NULL,
  `roleId` varchar(50) NOT NULL,
  `avatarText` varchar(10) DEFAULT NULL,
  `status` varchar(50) DEFAULT 'actif',
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `matricule`, `roleId`, `avatarText`, `status`, `createdAt`, `updatedAt`) VALUES
('1', 'Jean Dupont', 'jean.dupont@univ.edu', '2024-UFR-001', '3', 'JD', 'actif', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('10', 'Librarian One', 'librarian@library.edu', 'LIB-001', '2', 'L1', 'actif', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('11', 'Prof. Martin', 'prof.martin@univ.edu', 'PROF-001', '4', 'PM', 'actif', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('2', 'Amadou Diallo', 'amadou.diallo@univ.edu', '2024-UFR-002', '3', 'AD', 'actif', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('3', 'Fatou Sall', 'fatou.sall@univ.edu', '2024-UFR-003', '3', 'FS', 'actif', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('4', 'Moussa Ndiaye', 'moussa.ndiaye@univ.edu', '2024-UFR-004', '3', 'MN', 'actif', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('5', 'Aïssatou Ba', 'aissatou.ba@univ.edu', '2024-UFR-005', '3', 'AB', 'actif', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('6', 'Ibrahima Sarr', 'ibrahima.sarr@univ.edu', '2024-UFR-006', '3', 'IS', 'actif', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('7', 'Mariama Sy', 'mariama.sy@univ.edu', '2024-UFR-007', '3', 'MS', 'actif', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('8', 'Cheikh Fall', 'cheikh.fall@univ.edu', '2024-UFR-008', '3', 'CF', 'actif', '2025-12-04 23:13:33', '2025-12-04 23:13:33'),
('9', 'Admin System', 'admin@library.edu', 'ADMIN-001', '1', 'AS', 'actif', '2025-12-04 23:13:33', '2025-12-04 23:13:33');

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `userswithroles`
-- (Voir ci-dessous la vue réelle)
--
CREATE TABLE `userswithroles` (
`id` varchar(50)
,`name` varchar(100)
,`email` varchar(100)
,`matricule` varchar(50)
,`roleName` varchar(100)
,`avatarText` varchar(10)
,`status` varchar(50)
,`createdAt` timestamp
,`activeLoans` bigint(21)
,`pendingReservations` bigint(21)
);

-- --------------------------------------------------------

--
-- Structure de la vue `booksbycategory`
--
DROP TABLE IF EXISTS `booksbycategory`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `booksbycategory`  AS SELECT `c`.`id` AS `categoryId`, `c`.`name` AS `categoryName`, count(`b`.`id`) AS `totalBooks`, sum(case when `b`.`available` = 1 then 1 else 0 end) AS `availableBooks`, sum(`b`.`copies`) AS `totalCopies`, (select count(distinct `e`.`userId`) from (`emprunts` `e` join `books` `b2` on(`e`.`bookId` = `b2`.`id`)) where `b2`.`categoryId` = `c`.`id` and `e`.`borrowDate` >= curdate() - interval 30 day) AS `activeBorrowers` FROM (`categories` `c` left join `books` `b` on(`c`.`id` = `b`.`categoryId`)) GROUP BY `c`.`id`, `c`.`name` ORDER BY count(`b`.`id`) DESC ;

-- --------------------------------------------------------

--
-- Structure de la vue `dashboardstats`
--
DROP TABLE IF EXISTS `dashboardstats`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `dashboardstats`  AS SELECT (select count(0) from `books`) AS `totalBooks`, (select count(0) from `users` where `users`.`roleId` = '3') AS `totalStudents`, (select count(0) from `emprunts` where `emprunts`.`status` in ('En cours','En retard')) AS `borrowedBooks`, (select count(0) from `emprunts` where `emprunts`.`status` = 'En retard') AS `lateBooks`, (select count(0) from `books` where year(`books`.`createdAt`) = year(curdate()) and month(`books`.`createdAt`) = month(curdate())) AS `newBooksThisMonth`, (select count(0) from `reservations` where `reservations`.`status` = 'En attente') AS `pendingReservations`, (select count(distinct `emprunts`.`userId`) from `emprunts` where month(`emprunts`.`borrowDate`) = month(curdate())) AS `activeUsersThisMonth`, (select count(0) from `users` where `users`.`roleId` = '4') AS `totalProfessors` ;

-- --------------------------------------------------------

--
-- Structure de la vue `recentactivities`
--
DROP TABLE IF EXISTS `recentactivities`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `recentactivities`  AS SELECT 'emprunt' AS `activityType`, concat(`u`.`name`,' a emprunté \'',`b`.`title`,'\'') AS `title`, `e`.`createdAt` AS `activityDate`, 'BookOpen' AS `iconName`, 'blue' AS `color`, `u`.`id` AS `userId`, `b`.`id` AS `bookId` FROM ((`emprunts` `e` join `users` `u` on(`e`.`userId` = `u`.`id`)) join `books` `b` on(`e`.`bookId` = `b`.`id`)) WHERE `e`.`createdAt` >= curdate() - interval 7 dayunion allselect 'retour' AS `activityType`,concat(`u`.`name`,' a retourné \'',`b`.`title`,'\'') AS `title`,`e`.`createdAt` AS `activityDate`,'CheckCircle' AS `iconName`,'green' AS `color`,`u`.`id` AS `userId`,`b`.`id` AS `bookId` from ((`emprunts` `e` join `users` `u` on(`e`.`userId` = `u`.`id`)) join `books` `b` on(`e`.`bookId` = `b`.`id`)) where `e`.`returnDate` <= curdate() and `e`.`createdAt` >= curdate() - interval 7 day union all select 'reservation' AS `activityType`,concat(`u`.`name`,' a réservé \'',`b`.`title`,'\'') AS `title`,`r`.`createdAt` AS `activityDate`,'Clock' AS `iconName`,'orange' AS `color`,`u`.`id` AS `userId`,`b`.`id` AS `bookId` from ((`reservations` `r` join `users` `u` on(`r`.`userId` = `u`.`id`)) join `books` `b` on(`r`.`bookId` = `b`.`id`)) where `r`.`createdAt` >= curdate() - interval 7 day union all select 'retard' AS `activityType`,concat('Livre en retard : \'',`b`.`title`,'\'') AS `title`,`e`.`returnDate` AS `activityDate`,'AlertCircle' AS `iconName`,'red' AS `color`,`u`.`id` AS `userId`,`b`.`id` AS `bookId` from ((`emprunts` `e` join `users` `u` on(`e`.`userId` = `u`.`id`)) join `books` `b` on(`e`.`bookId` = `b`.`id`)) where `e`.`status` = 'En retard' and `e`.`returnDate` >= curdate() - interval 30 day order by `activityDate` desc limit 20  ;

-- --------------------------------------------------------

--
-- Structure de la vue `topbooks`
--
DROP TABLE IF EXISTS `topbooks`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `topbooks`  AS SELECT `b`.`id` AS `id`, `b`.`title` AS `title`, `b`.`author` AS `author`, `c`.`name` AS `category`, count(`e`.`id`) AS `loanCount`, `b`.`copies` AS `copies`, `b`.`available` AS `available` FROM ((`books` `b` join `categories` `c` on(`b`.`categoryId` = `c`.`id`)) left join `emprunts` `e` on(`b`.`id` = `e`.`bookId`)) GROUP BY `b`.`id`, `b`.`title`, `b`.`author`, `c`.`name`, `b`.`copies`, `b`.`available` ORDER BY count(`e`.`id`) DESC, `b`.`title` ASC LIMIT 0, 10 ;

-- --------------------------------------------------------

--
-- Structure de la vue `userswithroles`
--
DROP TABLE IF EXISTS `userswithroles`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `userswithroles`  AS SELECT `u`.`id` AS `id`, `u`.`name` AS `name`, `u`.`email` AS `email`, `u`.`matricule` AS `matricule`, `r`.`name` AS `roleName`, `u`.`avatarText` AS `avatarText`, `u`.`status` AS `status`, `u`.`createdAt` AS `createdAt`, (select count(0) from `emprunts` where `emprunts`.`userId` = `u`.`id` and `emprunts`.`status` in ('En cours','En retard')) AS `activeLoans`, (select count(0) from `reservations` where `reservations`.`userId` = `u`.`id` and `reservations`.`status` = 'En attente') AS `pendingReservations` FROM (`users` `u` join `roles` `r` on(`u`.`roleId` = `r`.`id`)) ORDER BY `u`.`createdAt` DESC ;

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `books`
--
ALTER TABLE `books`
  ADD PRIMARY KEY (`id`),
  ADD KEY `categoryId` (`categoryId`);

--
-- Index pour la table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Index pour la table `emprunthistory`
--
ALTER TABLE `emprunthistory`
  ADD PRIMARY KEY (`id`),
  ADD KEY `empruntId` (`empruntId`),
  ADD KEY `changedBy` (`changedBy`);

--
-- Index pour la table `emprunts`
--
ALTER TABLE `emprunts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `bookId` (`bookId`),
  ADD KEY `userId` (`userId`);

--
-- Index pour la table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `userId` (`userId`),
  ADD KEY `relatedBookId` (`relatedBookId`);

--
-- Index pour la table `reservations`
--
ALTER TABLE `reservations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `bookId` (`bookId`),
  ADD KEY `userId` (`userId`);

--
-- Index pour la table `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Index pour la table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `matricule` (`matricule`),
  ADD KEY `roleId` (`roleId`);

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `books`
--
ALTER TABLE `books`
  ADD CONSTRAINT `books_ibfk_1` FOREIGN KEY (`categoryId`) REFERENCES `categories` (`id`);

--
-- Contraintes pour la table `emprunthistory`
--
ALTER TABLE `emprunthistory`
  ADD CONSTRAINT `emprunthistory_ibfk_1` FOREIGN KEY (`empruntId`) REFERENCES `emprunts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `emprunthistory_ibfk_2` FOREIGN KEY (`changedBy`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Contraintes pour la table `emprunts`
--
ALTER TABLE `emprunts`
  ADD CONSTRAINT `emprunts_ibfk_1` FOREIGN KEY (`bookId`) REFERENCES `books` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `emprunts_ibfk_2` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `notifications_ibfk_2` FOREIGN KEY (`relatedBookId`) REFERENCES `books` (`id`) ON DELETE SET NULL;

--
-- Contraintes pour la table `reservations`
--
ALTER TABLE `reservations`
  ADD CONSTRAINT `reservations_ibfk_1` FOREIGN KEY (`bookId`) REFERENCES `books` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reservations_ibfk_2` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `users_ibfk_1` FOREIGN KEY (`roleId`) REFERENCES `roles` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
