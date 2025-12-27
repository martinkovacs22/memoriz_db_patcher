-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Gép: localhost
-- Létrehozás ideje: 2025. Dec 24. 12:36
-- Kiszolgáló verziója: 10.4.32-MariaDB
-- PHP verzió: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Adatbázis: `memoriz`
--

DELIMITER $$
--
-- Eljárások
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `userCreate` (IN `p_firstname` VARCHAR(255), IN `p_lastname` VARCHAR(255), IN `p_email` VARCHAR(255), IN `p_phone_number` VARCHAR(255), IN `p_password` VARCHAR(255), IN `p_country` VARCHAR(255), IN `p_zip` VARCHAR(255), IN `p_city` VARCHAR(255), IN `p_street` VARCHAR(255), IN `p_house_number` VARCHAR(255))   BEGIN
    DECLARE v_address_id INT;
    DECLARE v_user_count INT;

    -- 1. Ellenőrizzük az emailt
    IF EXISTS(SELECT 1 FROM User WHERE email = p_email) THEN
        SELECT 'Email already exists' AS msg;
    ELSE
        -- 2. Ellenőrizzük, hogy van-e már ilyen cím
        SELECT id INTO v_address_id
        FROM Address
        WHERE country = p_country
          AND zip = p_zip
          AND city = p_city
          AND street = p_street
          AND house_number = p_house_number
        LIMIT 1;

        IF v_address_id IS NOT NULL THEN
            SELECT COUNT(*) INTO v_user_count
            FROM User
            WHERE id_address = v_address_id;

            IF v_user_count >= 3 THEN
                SELECT 'Address already has 3 users, cannot add more' AS msg;
            ELSE
                -- 3. Beszúrjuk a user-t
                INSERT INTO User (firstname, lastname, email, phone_number, password, id_address)
                VALUES (p_firstname, p_lastname, p_email, p_phone_number, SHA2(p_password, 256), v_address_id);
                SELECT 'User created successfully' AS msg;
            END IF;

        ELSE
            -- Ha nincs ilyen cím, létrehozzuk
            INSERT INTO Address (country, zip, city, street, house_number)
            VALUES (p_country, p_zip, p_city, p_street, p_house_number);

            SET v_address_id = LAST_INSERT_ID();

            -- 3. Beszúrjuk a user-t
            INSERT INTO User (firstname, lastname, email, phone_number, password, id_address)
            VALUES (p_firstname, p_lastname, p_email, p_phone_number, SHA2(p_password, 256), v_address_id);

            SELECT 'User created successfully' AS msg;
        END IF;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `userLoginEmail` (IN `p_email` VARCHAR(255), IN `p_password` VARCHAR(255))   BEGIN
    -- Ellenőrizzük, hogy létezik-e a user
    IF EXISTS(
        SELECT 1
        FROM User
        WHERE email = p_email
          AND password = SHA2(p_password, 256)
          AND user_role NOT IN ("Banned", "NEED_AUTH")
    ) THEN
        -- 1️⃣ Frissítjük a time_last_login mezőt az aktuális időre
        UPDATE User
        SET time_last_login = NOW()
        WHERE email = p_email
          AND password = SHA2(p_password, 256);

        -- 2️⃣ Lekérjük a user adatait
        SELECT 
            User.id,
            User.user_role,
            User.firstname,
            User.lastname,
            File.file_path,
            User.time_last_login
        FROM User
        LEFT JOIN File ON File.id = User.id_file_icon
        WHERE User.email = p_email
          AND User.password = SHA2(p_password, 256)
          AND User.user_role NOT IN ("Banned", "NEED_AUTH");
    ELSE
        -- Ha nincs ilyen user, NULL-okkal térünk vissza
        SELECT 
            NULL AS id, 
            NULL AS user_role, 
            NULL AS firstname, 
            NULL AS lastname, 
            NULL AS file_path, 
            NULL AS time_last_login;
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `Address`
--

CREATE TABLE `Address` (
  `id` int(11) NOT NULL,
  `country` varchar(255) NOT NULL,
  `zip` varchar(255) NOT NULL,
  `city` varchar(255) NOT NULL,
  `street` varchar(255) NOT NULL,
  `house_number` varchar(255) NOT NULL,
  `time_upload` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- A tábla adatainak kiíratása `Address`
--

INSERT INTO `Address` (`id`, `country`, `zip`, `city`, `street`, `house_number`, `time_upload`) VALUES
(1, 'Magyar', '7634', 'Pécs', 'Forrás dülö', '4', '2025-12-05 13:35:11'),
(2, 'Magyar', '7620', 'Pécs', 'Forrás', '4', '2025-12-05 13:50:58');

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `Comment`
--

CREATE TABLE `Comment` (
  `id` int(11) DEFAULT NULL,
  `id_subject` int(11) NOT NULL,
  `id_group` int(11) NOT NULL,
  `id_comment` int(11) DEFAULT NULL,
  `id_user` int(11) NOT NULL,
  `comment` text NOT NULL,
  `time_upload` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `CommentReaction`
--

CREATE TABLE `CommentReaction` (
  `id` int(11) NOT NULL,
  `id_comment` int(11) NOT NULL,
  `id_user` int(11) NOT NULL,
  `id_reaction` int(11) NOT NULL,
  `time_upload` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `CommentXFile`
--

CREATE TABLE `CommentXFile` (
  `id` int(11) NOT NULL,
  `id_comment` int(11) NOT NULL,
  `id_file` int(11) NOT NULL,
  `time_upload` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `File`
--

CREATE TABLE `File` (
  `id` int(11) NOT NULL,
  `id_user` int(11) NOT NULL,
  `file_name` varchar(255) NOT NULL,
  `file_extension` varchar(255) NOT NULL,
  `file_path` varchar(255) NOT NULL,
  `time_upload` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `Group`
--

CREATE TABLE `Group` (
  `id` int(11) NOT NULL,
  `group_name` varchar(255) NOT NULL,
  `id_user_group_leader` int(11) NOT NULL,
  `time_upload` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `GroupXUser`
--

CREATE TABLE `GroupXUser` (
  `id` int(11) NOT NULL,
  `id_user` int(11) NOT NULL,
  `id_group` int(11) NOT NULL,
  `time_upload` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `Reaction`
--

CREATE TABLE `Reaction` (
  `id` int(11) NOT NULL,
  `id_file` int(11) NOT NULL,
  `reaction_name` varchar(255) NOT NULL,
  `time_upload` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `Style`
--

CREATE TABLE `Style` (
  `id` int(11) NOT NULL,
  `style_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT '{}' CHECK (json_valid(`style_json`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `StyleXAble`
--

CREATE TABLE `StyleXAble` (
  `id` int(11) NOT NULL,
  `id_style` int(11) DEFAULT NULL,
  `id_able` int(11) DEFAULT NULL,
  `style_type` enum('Group','Subject','Comment') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `Subject`
--

CREATE TABLE `Subject` (
  `id` int(11) NOT NULL,
  `subject_name` varchar(255) NOT NULL,
  `time_upload` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `SubjectXFile`
--

CREATE TABLE `SubjectXFile` (
  `id` int(11) NOT NULL,
  `id_subject` int(11) NOT NULL,
  `id_file` int(11) NOT NULL,
  `time_upload` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `SubjectXGroup`
--

CREATE TABLE `SubjectXGroup` (
  `id` int(11) NOT NULL,
  `id_subject` int(11) NOT NULL,
  `id_group` int(11) NOT NULL,
  `time_upload` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `SubjectXGroupXUser`
--

CREATE TABLE `SubjectXGroupXUser` (
  `id` int(11) NOT NULL,
  `id_subjectxgroup` int(11) NOT NULL,
  `id_user` int(11) NOT NULL,
  `group_role` enum('NEED_AUTH','USER','ADMIN','PREMIUM_USER','BANNED') NOT NULL DEFAULT 'USER',
  `time_upload` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `User`
--

CREATE TABLE `User` (
  `id` int(11) NOT NULL,
  `user_role` enum('NEED_AUTH','USER','ADMIN','PREMIUM_USER','BANNED') NOT NULL DEFAULT 'NEED_AUTH',
  `firstname` varchar(255) NOT NULL,
  `lastname` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `phone_number` varchar(60) NOT NULL,
  `password` char(64) NOT NULL,
  `id_address` int(11) NOT NULL,
  `id_file_icon` int(11) DEFAULT NULL,
  `time_upload` timestamp NOT NULL DEFAULT current_timestamp(),
  `time_last_login` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- A tábla adatainak kiíratása `User`
--

INSERT INTO `User` (`id`, `user_role`, `firstname`, `lastname`, `email`, `phone_number`, `password`, `id_address`, `id_file_icon`, `time_upload`, `time_last_login`) VALUES
(1, 'ADMIN', 'Martin', 'Kovacs', 'martinkovacs22@gmail.com', '06703698058', 'ef797c8118f02dfb649607dd5d3f8c7623048c9c063d532cc95c5ed7a898a64f', 1, NULL, '2025-12-05 13:35:11', '2025-12-24 09:33:34'),
(2, 'NEED_AUTH', 'Szabina', 'Beres', 'szabinaberes35@gmail.com', '06703698585', 'ef797c8118f02dfb649607dd5d3f8c7623048c9c063d532cc95c5ed7a898a64f', 2, NULL, '2025-12-05 13:50:58', '0000-00-00 00:00:00'),
(3, 'NEED_AUTH', 'Szabina', 'Beres', 'szabinaberes@gmail.com', '06703698585', 'ef797c8118f02dfb649607dd5d3f8c7623048c9c063d532cc95c5ed7a898a64f', 2, NULL, '2025-12-05 15:13:14', '0000-00-00 00:00:00');

--
-- Indexek a kiírt táblákhoz
--

--
-- A tábla indexei `Address`
--
ALTER TABLE `Address`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `CommentReaction`
--
ALTER TABLE `CommentReaction`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `CommentXFile`
--
ALTER TABLE `CommentXFile`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `File`
--
ALTER TABLE `File`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `Group`
--
ALTER TABLE `Group`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `GroupXUser`
--
ALTER TABLE `GroupXUser`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `Reaction`
--
ALTER TABLE `Reaction`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `Style`
--
ALTER TABLE `Style`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `StyleXAble`
--
ALTER TABLE `StyleXAble`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `Subject`
--
ALTER TABLE `Subject`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `SubjectXFile`
--
ALTER TABLE `SubjectXFile`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `SubjectXGroup`
--
ALTER TABLE `SubjectXGroup`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `SubjectXGroupXUser`
--
ALTER TABLE `SubjectXGroupXUser`
  ADD PRIMARY KEY (`id`);

--
-- A kiírt táblák AUTO_INCREMENT értéke
--

--
-- AUTO_INCREMENT a táblához `Address`
--
ALTER TABLE `Address`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT a táblához `CommentReaction`
--
ALTER TABLE `CommentReaction`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `CommentXFile`
--
ALTER TABLE `CommentXFile`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `File`
--
ALTER TABLE `File`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `Group`
--
ALTER TABLE `Group`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `GroupXUser`
--
ALTER TABLE `GroupXUser`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `Reaction`
--
ALTER TABLE `Reaction`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `Style`
--
ALTER TABLE `Style`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `StyleXAble`
--
ALTER TABLE `StyleXAble`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `Subject`
--
ALTER TABLE `Subject`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `SubjectXFile`
--
ALTER TABLE `SubjectXFile`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `SubjectXGroup`
--
ALTER TABLE `SubjectXGroup`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT a táblához `SubjectXGroupXUser`
--
ALTER TABLE `SubjectXGroupXUser`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
