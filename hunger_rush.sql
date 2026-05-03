-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 03, 2026 at 11:39 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `hunger_rush`
--

-- --------------------------------------------------------

--
-- Table structure for table `cache`
--

CREATE TABLE `cache` (
  `key` varchar(191) NOT NULL,
  `value` mediumtext NOT NULL,
  `expiration` bigint(20) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `cache_locks`
--

CREATE TABLE `cache_locks` (
  `key` varchar(191) NOT NULL,
  `owner` varchar(191) NOT NULL,
  `expiration` bigint(20) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `carts`
--

CREATE TABLE `carts` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `customer_id` bigint(20) UNSIGNED NOT NULL,
  `restaurant_id` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `carts`
--

INSERT INTO `carts` (`id`, `customer_id`, `restaurant_id`, `created_at`, `updated_at`) VALUES
(1, 2, 1, '2026-05-03 06:36:40', '2026-05-03 06:36:41');

-- --------------------------------------------------------

--
-- Table structure for table `cart_items`
--

CREATE TABLE `cart_items` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `cart_id` bigint(20) UNSIGNED NOT NULL,
  `menu_item_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `cart_items`
--

INSERT INTO `cart_items` (`id`, `cart_id`, `menu_item_id`, `quantity`, `notes`, `created_at`, `updated_at`) VALUES
(1, 1, 27, 2, NULL, '2026-05-03 06:36:41', '2026-05-03 06:36:47'),
(2, 1, 24, 3, NULL, '2026-05-03 06:36:42', '2026-05-03 06:36:42');

-- --------------------------------------------------------

--
-- Table structure for table `conversations`
--

CREATE TABLE `conversations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `restaurant_id` bigint(20) UNSIGNED NOT NULL,
  `customer_id` bigint(20) UNSIGNED NOT NULL,
  `order_id` bigint(20) UNSIGNED DEFAULT NULL,
  `subject` varchar(255) DEFAULT NULL,
  `status` enum('open','closed') NOT NULL DEFAULT 'open',
  `last_message_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `conversation_messages`
--

CREATE TABLE `conversation_messages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `conversation_id` bigint(20) UNSIGNED NOT NULL,
  `sender_id` bigint(20) UNSIGNED NOT NULL,
  `body` text NOT NULL,
  `read_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `delivery_tasks`
--

CREATE TABLE `delivery_tasks` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_id` bigint(20) UNSIGNED NOT NULL,
  `driver_id` bigint(20) UNSIGNED DEFAULT NULL,
  `status` enum('unassigned','assigned','accepted','picked_up','delivered','failed') NOT NULL DEFAULT 'unassigned',
  `assigned_at` timestamp NULL DEFAULT NULL,
  `picked_at` timestamp NULL DEFAULT NULL,
  `delivered_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `drivers`
--

CREATE TABLE `drivers` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `vehicle_type` varchar(255) DEFAULT NULL,
  `verification_status` enum('pending','verified','rejected') NOT NULL DEFAULT 'pending',
  `online_status` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `driver_locations`
--

CREATE TABLE `driver_locations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `driver_id` bigint(20) UNSIGNED NOT NULL,
  `lat` decimal(10,7) NOT NULL,
  `lng` decimal(10,7) NOT NULL,
  `recorded_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `uuid` varchar(191) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobs`
--

CREATE TABLE `jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `queue` varchar(191) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` tinyint(3) UNSIGNED NOT NULL,
  `reserved_at` int(10) UNSIGNED DEFAULT NULL,
  `available_at` int(10) UNSIGNED NOT NULL,
  `created_at` int(10) UNSIGNED NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `job_batches`
--

CREATE TABLE `job_batches` (
  `id` varchar(191) NOT NULL,
  `name` varchar(191) NOT NULL,
  `total_jobs` int(11) NOT NULL,
  `pending_jobs` int(11) NOT NULL,
  `failed_jobs` int(11) NOT NULL,
  `failed_job_ids` longtext NOT NULL,
  `options` mediumtext DEFAULT NULL,
  `cancelled_at` int(11) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `finished_at` int(11) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `loyalty_members`
--

CREATE TABLE `loyalty_members` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `restaurant_id` bigint(20) UNSIGNED NOT NULL,
  `customer_id` bigint(20) UNSIGNED NOT NULL,
  `points` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `orders_count` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `tier` varchar(255) NOT NULL DEFAULT 'bronze',
  `last_activity_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `loyalty_redemptions`
--

CREATE TABLE `loyalty_redemptions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `restaurant_id` bigint(20) UNSIGNED NOT NULL,
  `loyalty_member_id` bigint(20) UNSIGNED NOT NULL,
  `loyalty_reward_id` bigint(20) UNSIGNED DEFAULT NULL,
  `points_spent` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `loyalty_rewards`
--

CREATE TABLE `loyalty_rewards` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `restaurant_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `points_required` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `reward_type` enum('discount','free_item','free_delivery','cashback','custom') NOT NULL DEFAULT 'custom',
  `status` enum('active','draft','archived') NOT NULL DEFAULT 'draft',
  `usage_count` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `menu_categories`
--

CREATE TABLE `menu_categories` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `restaurant_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `sort_order` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `menu_categories`
--

INSERT INTO `menu_categories` (`id`, `restaurant_id`, `name`, `sort_order`, `created_at`, `updated_at`) VALUES
(21, 1, 'Desserts', 3, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(20, 1, 'Drinks', 2, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(19, 1, 'Burgers', 1, '2026-04-13 19:36:48', '2026-04-13 19:36:48');

-- --------------------------------------------------------

--
-- Table structure for table `menu_items`
--

CREATE TABLE `menu_items` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `category_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `image_urls` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`image_urls`)),
  `price` decimal(10,2) NOT NULL,
  `is_available` tinyint(1) NOT NULL DEFAULT 1,
  `prep_time` int(10) UNSIGNED NOT NULL DEFAULT 15,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `ingredients` text DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `menu_items`
--

INSERT INTO `menu_items` (`id`, `category_id`, `name`, `description`, `image_urls`, `price`, `is_available`, `prep_time`, `created_at`, `updated_at`, `ingredients`) VALUES
(27, 21, 'Lava Cake', 'Ea cupiditate nostrum illum reiciendis fugiat praesentium alias.', '[\"https:\\/\\/images.unsplash.com\\/photo-1617305855058-336d24456869?auto=format&fit=crop&w=900&q=80\",\"https:\\/\\/images.unsplash.com\\/photo-1602351447937-745cb720612f?auto=format&fit=crop&w=900&q=80\"]', 7.25, 1, 12, '2026-04-13 19:36:48', '2026-04-13 19:36:48', 'Chicken, garlic, lemon, olive oil, black pepper'),
(26, 20, 'Cola', 'Nihil qui laudantium ut velit.', '[\"https:\\/\\/images.unsplash.com\\/photo-1554866585-cd94860890b7?auto=format&fit=crop&w=900&q=80\"]', 3.50, 1, 5, '2026-04-13 19:36:48', '2026-04-13 19:36:48', 'Chicken, garlic, lemon, olive oil, black pepper'),
(25, 19, 'Double Cheese Blaze', 'Nihil non quia maxime commodi.', '[\"https:\\/\\/images.unsplash.com\\/photo-1550547660-d9450f859349?auto=format&fit=crop&w=900&q=80\",\"https:\\/\\/images.unsplash.com\\/photo-1572802419224-296b0aeee0d9?auto=format&fit=crop&w=900&q=80\"]', 15.75, 1, 22, '2026-04-13 19:36:48', '2026-04-13 19:36:48', 'Fresh vegetables, herbs, and house seasoning'),
(24, 19, 'Classic Burger', 'Dolores suscipit et repellat molestias maxime eum.', '[\"https:\\/\\/images.unsplash.com\\/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80\",\"https:\\/\\/images.unsplash.com\\/photo-1550317138-10000687a72b?auto=format&fit=crop&w=900&q=80\"]', 12.50, 1, 20, '2026-04-13 19:36:48', '2026-04-13 19:36:48', 'Beef, onion, tomato, lettuce, signature sauce');

-- --------------------------------------------------------

--
-- Table structure for table `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '0001_01_01_000000_create_users_table', 1),
(2, '0001_01_01_000001_create_cache_table', 1),
(3, '0001_01_01_000002_create_jobs_table', 1),
(4, '2026_03_24_061508_create_personal_access_tokens_table', 1),
(5, '2026_03_24_061529_create_restaurant_branches_table', 1),
(6, '2026_03_24_061529_create_restaurants_table', 1),
(7, '2026_03_24_061530_create_menu_categories_table', 1),
(8, '2026_03_24_061530_create_menu_items_table', 1),
(9, '2026_03_24_061530_create_orders_table', 1),
(10, '2026_03_24_061531_create_drivers_table', 1),
(11, '2026_03_24_061531_create_order_items_table', 1),
(12, '2026_03_24_061531_create_order_status_histories_table', 1),
(13, '2026_03_24_061532_create_delivery_tasks_table', 1),
(14, '2026_03_24_061532_create_driver_locations_table', 1),
(15, '2026_03_24_061532_create_videos_table', 1),
(16, '2026_03_24_061533_create_video_engagements_table', 1),
(17, '2026_03_24_063830_create_cart_items_table', 1),
(18, '2026_03_24_063830_create_carts_table', 1),
(19, '2026_04_05_000001_add_video_metadata_columns', 2),
(20, '2026_04_05_000002_create_reviews_table', 3),
(21, '2026_04_05_000003_add_settings_to_restaurants_table', 3),
(22, '2026_04_05_000004_create_loyalty_rewards_table', 3),
(23, '2026_04_05_000005_create_loyalty_members_table', 3),
(24, '2026_04_05_000006_create_loyalty_redemptions_table', 3),
(25, '2026_04_05_000007_add_image_urls_to_menu_items_table', 4),
(26, '2026_04_05_000008_add_is_quick_order_to_orders_table', 5),
(27, '2026_04_08_000001_add_phone_to_restaurant_branches_table', 6),
(28, '2026_04_08_000002_add_ingredients_to_menu_items_table', 7),
(29, '2026_04_08_000003_backfill_missing_menu_item_ingredients', 7),
(30, '2026_05_01_000001_add_social_auth_columns_to_users_table', 8),
(31, '2026_05_03_000001_repair_broken_reviews_and_loyalty_tables', 9),
(32, '2026_05_03_000002_create_conversations_tables', 9),
(33, '2026_05_03_000003_create_notifications_table', 9),
(34, '2026_05_03_000004_create_support_requests_and_reports_tables', 9);

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `type` varchar(255) NOT NULL DEFAULT 'general',
  `title` varchar(255) NOT NULL,
  `body` text DEFAULT NULL,
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`data`)),
  `read_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `customer_id` bigint(20) UNSIGNED NOT NULL,
  `restaurant_id` bigint(20) UNSIGNED NOT NULL,
  `branch_id` bigint(20) UNSIGNED DEFAULT NULL,
  `subtotal` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fees` decimal(10,2) NOT NULL DEFAULT 0.00,
  `total` decimal(10,2) NOT NULL DEFAULT 0.00,
  `status` enum('pending','accepted','rejected','preparing','ready_for_pickup','picked_up','on_the_way','delivered','cancelled') NOT NULL DEFAULT 'pending',
  `payment_status` enum('unpaid','authorized','paid','refunded','failed') NOT NULL DEFAULT 'unpaid',
  `is_quick_order` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`id`, `customer_id`, `restaurant_id`, `branch_id`, `subtotal`, `fees`, `total`, `status`, `payment_status`, `is_quick_order`, `created_at`, `updated_at`) VALUES
(2194, 56, 1, NULL, 50.75, 5.08, 55.83, 'delivered', 'paid', 0, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(2193, 55, 1, NULL, 32.25, 3.23, 35.48, 'delivered', 'paid', 0, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(2192, 54, 1, NULL, 19.25, 1.93, 21.18, 'delivered', 'paid', 0, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(2191, 2, 1, NULL, 44.75, 4.48, 49.23, 'delivered', 'paid', 0, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(2190, 57, 1, NULL, 35.00, 3.50, 38.50, 'delivered', 'paid', 0, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(2189, 56, 1, NULL, 19.75, 1.98, 21.73, 'on_the_way', 'unpaid', 0, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(2188, 55, 1, NULL, 50.75, 5.08, 55.83, 'ready_for_pickup', 'unpaid', 0, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(2187, 54, 1, NULL, 32.25, 3.23, 35.48, 'preparing', 'unpaid', 0, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(2186, 2, 1, NULL, 19.25, 1.93, 21.18, 'accepted', 'unpaid', 0, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(2185, 2, 1, NULL, 16.00, 1.60, 17.60, 'pending', 'unpaid', 0, '2026-04-13 19:36:48', '2026-04-13 19:36:48');

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

CREATE TABLE `order_items` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_id` bigint(20) UNSIGNED NOT NULL,
  `menu_item_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `unit_price` decimal(10,2) NOT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `order_items`
--

INSERT INTO `order_items` (`id`, `order_id`, `menu_item_id`, `quantity`, `unit_price`, `notes`, `created_at`, `updated_at`) VALUES
(4438, 2194, 26, 1, 3.50, NULL, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(4437, 2194, 25, 3, 15.75, NULL, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(4436, 2193, 27, 1, 7.25, NULL, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(4435, 2193, 24, 2, 12.50, NULL, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(4434, 2192, 26, 1, 3.50, NULL, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(4433, 2192, 25, 1, 15.75, NULL, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(4432, 2191, 27, 1, 7.25, NULL, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(4431, 2191, 24, 3, 12.50, NULL, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(4430, 2190, 26, 1, 3.50, NULL, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(4429, 2190, 25, 2, 15.75, NULL, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(4428, 2189, 27, 1, 7.25, NULL, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(4427, 2189, 24, 1, 12.50, NULL, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(4426, 2188, 26, 1, 3.50, NULL, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(4425, 2188, 25, 3, 15.75, NULL, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(4424, 2187, 27, 1, 7.25, NULL, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(4422, 2186, 26, 1, 3.50, NULL, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(4423, 2187, 24, 2, 12.50, NULL, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(4421, 2186, 25, 1, 15.75, NULL, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(4420, 2185, 26, 1, 3.50, NULL, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(4419, 2185, 24, 1, 12.50, NULL, '2026-04-13 19:36:48', '2026-04-13 19:36:48');

-- --------------------------------------------------------

--
-- Table structure for table `order_status_histories`
--

CREATE TABLE `order_status_histories` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_id` bigint(20) UNSIGNED NOT NULL,
  `status` varchar(255) NOT NULL,
  `changed_by` bigint(20) UNSIGNED DEFAULT NULL,
  `changed_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `order_status_histories`
--

INSERT INTO `order_status_histories` (`id`, `order_id`, `status`, `changed_by`, `changed_at`, `created_at`, `updated_at`) VALUES
(1, 1, 'accepted', 1, '2026-03-24 05:22:40', '2026-03-24 05:22:40', '2026-03-24 05:22:40'),
(2, 1, 'preparing', 1, '2026-03-24 05:22:44', '2026-03-24 05:22:44', '2026-03-24 05:22:44'),
(3, 1, 'ready_for_pickup', 1, '2026-03-24 05:22:46', '2026-03-24 05:22:46', '2026-03-24 05:22:46'),
(4, 1, 'picked_up', 1, '2026-03-24 05:22:48', '2026-03-24 05:22:48', '2026-03-24 05:22:48'),
(5, 1, 'on_the_way', 1, '2026-03-24 05:22:51', '2026-03-24 05:22:51', '2026-03-24 05:22:51'),
(6, 1, 'delivered', 1, '2026-03-24 05:22:53', '2026-03-24 05:22:53', '2026-03-24 05:22:53'),
(7, 7, 'accepted', 1, '2026-03-24 05:49:44', '2026-03-24 05:49:44', '2026-03-24 05:49:44'),
(8, 2, 'accepted', 1, '2026-03-24 05:50:27', '2026-03-24 05:50:27', '2026-03-24 05:50:27'),
(9, 2, 'preparing', 1, '2026-03-24 05:50:29', '2026-03-24 05:50:29', '2026-03-24 05:50:29'),
(10, 4, 'ready_for_pickup', 1, '2026-03-24 05:50:30', '2026-03-24 05:50:30', '2026-03-24 05:50:30'),
(11, 6, 'delivered', 1, '2026-03-24 05:50:31', '2026-03-24 05:50:31', '2026-03-24 05:50:31'),
(12, 10, 'picked_up', 1, '2026-03-24 06:00:34', '2026-03-24 06:00:34', '2026-03-24 06:00:34'),
(13, 4, 'picked_up', 1, '2026-03-24 06:00:52', '2026-03-24 06:00:52', '2026-03-24 06:00:52'),
(14, 4, 'on_the_way', 1, '2026-03-24 06:01:26', '2026-03-24 06:01:26', '2026-03-24 06:01:26'),
(15, 7, 'preparing', 1, '2026-04-02 19:06:12', '2026-04-02 19:06:12', '2026-04-02 19:06:12'),
(16, 7, 'ready_for_pickup', 1, '2026-04-02 19:06:16', '2026-04-02 19:06:16', '2026-04-02 19:06:16'),
(17, 11, 'delivered', 1, '2026-04-04 19:22:25', '2026-04-04 19:22:25', '2026-04-04 19:22:25'),
(18, 10, 'on_the_way', 1, '2026-04-04 19:22:26', '2026-04-04 19:22:26', '2026-04-04 19:22:26'),
(19, 10, 'delivered', 1, '2026-04-04 19:22:27', '2026-04-04 19:22:27', '2026-04-04 19:22:27'),
(20, 9, 'ready_for_pickup', 1, '2026-04-04 19:22:28', '2026-04-04 19:22:28', '2026-04-04 19:22:28'),
(21, 9, 'picked_up', 1, '2026-04-04 19:22:29', '2026-04-04 19:22:29', '2026-04-04 19:22:29'),
(22, 9, 'on_the_way', 1, '2026-04-04 19:22:30', '2026-04-04 19:22:30', '2026-04-04 19:22:30'),
(23, 9, 'delivered', 1, '2026-04-04 19:22:30', '2026-04-04 19:22:30', '2026-04-04 19:22:30'),
(24, 12, 'accepted', 1, '2026-04-04 19:30:00', '2026-04-04 19:30:00', '2026-04-04 19:30:00'),
(25, 12, 'preparing', 1, '2026-04-04 19:30:02', '2026-04-04 19:30:02', '2026-04-04 19:30:02'),
(26, 12, 'ready_for_pickup', 1, '2026-04-04 19:30:02', '2026-04-04 19:30:02', '2026-04-04 19:30:02'),
(27, 12, 'picked_up', 1, '2026-04-04 19:30:02', '2026-04-04 19:30:02', '2026-04-04 19:30:02'),
(28, 12, 'on_the_way', 1, '2026-04-04 19:30:03', '2026-04-04 19:30:03', '2026-04-04 19:30:03'),
(29, 12, 'delivered', 1, '2026-04-04 19:30:04', '2026-04-04 19:30:04', '2026-04-04 19:30:04'),
(30, 34, 'pending', 1, '2026-04-04 20:39:41', '2026-04-04 20:39:41', '2026-04-04 20:39:41'),
(31, 34, 'accepted', 1, '2026-04-04 20:39:57', '2026-04-04 20:39:57', '2026-04-04 20:39:57'),
(32, 34, 'preparing', 1, '2026-04-04 20:39:58', '2026-04-04 20:39:58', '2026-04-04 20:39:58'),
(33, 34, 'ready_for_pickup', 1, '2026-04-04 20:39:58', '2026-04-04 20:39:58', '2026-04-04 20:39:58'),
(34, 34, 'picked_up', 1, '2026-04-04 20:40:00', '2026-04-04 20:40:00', '2026-04-04 20:40:00'),
(35, 34, 'on_the_way', 1, '2026-04-04 20:40:01', '2026-04-04 20:40:01', '2026-04-04 20:40:01'),
(36, 34, 'delivered', 1, '2026-04-04 20:40:02', '2026-04-04 20:40:02', '2026-04-04 20:40:02'),
(37, 35, 'pending', 1, '2026-04-04 20:54:46', '2026-04-04 20:54:46', '2026-04-04 20:54:46'),
(38, 35, 'accepted', 1, '2026-04-05 08:02:52', '2026-04-05 08:02:52', '2026-04-05 08:02:52'),
(39, 35, 'preparing', 1, '2026-04-05 08:02:52', '2026-04-05 08:02:52', '2026-04-05 08:02:52'),
(40, 35, 'ready_for_pickup', 1, '2026-04-05 08:02:53', '2026-04-05 08:02:53', '2026-04-05 08:02:53'),
(41, 35, 'picked_up', 1, '2026-04-05 08:02:53', '2026-04-05 08:02:53', '2026-04-05 08:02:53'),
(42, 35, 'on_the_way', 1, '2026-04-05 08:02:54', '2026-04-05 08:02:54', '2026-04-05 08:02:54'),
(43, 35, 'delivered', 1, '2026-04-05 08:02:55', '2026-04-05 08:02:55', '2026-04-05 08:02:55'),
(44, 31, 'delivered', 1, '2026-04-05 08:04:06', '2026-04-05 08:04:06', '2026-04-05 08:04:06'),
(45, 27, 'accepted', 1, '2026-04-05 08:04:11', '2026-04-05 08:04:11', '2026-04-05 08:04:11'),
(46, 27, 'preparing', 1, '2026-04-05 08:04:13', '2026-04-05 08:04:13', '2026-04-05 08:04:13'),
(47, 27, 'ready_for_pickup', 1, '2026-04-05 08:04:15', '2026-04-05 08:04:15', '2026-04-05 08:04:15'),
(48, 27, 'picked_up', 1, '2026-04-05 08:04:20', '2026-04-05 08:04:20', '2026-04-05 08:04:20'),
(49, 27, 'on_the_way', 1, '2026-04-05 08:04:22', '2026-04-05 08:04:22', '2026-04-05 08:04:22'),
(50, 27, 'delivered', 1, '2026-04-05 08:04:26', '2026-04-05 08:04:26', '2026-04-05 08:04:26'),
(51, 2177, 'pending', 1, '2026-04-05 10:59:53', '2026-04-05 10:59:53', '2026-04-05 10:59:53'),
(52, 2178, 'pending', 1, '2026-04-06 14:16:00', '2026-04-06 14:16:00', '2026-04-06 14:16:00'),
(53, 2177, 'accepted', 1, '2026-04-07 18:10:57', '2026-04-07 18:10:57', '2026-04-07 18:10:57'),
(54, 2177, 'preparing', 1, '2026-04-07 18:10:58', '2026-04-07 18:10:58', '2026-04-07 18:10:58'),
(55, 2177, 'ready_for_pickup', 1, '2026-04-07 18:10:59', '2026-04-07 18:10:59', '2026-04-07 18:10:59'),
(56, 2177, 'picked_up', 1, '2026-04-07 18:10:59', '2026-04-07 18:10:59', '2026-04-07 18:10:59'),
(57, 2177, 'on_the_way', 1, '2026-04-07 18:10:59', '2026-04-07 18:10:59', '2026-04-07 18:10:59'),
(58, 2177, 'delivered', 1, '2026-04-07 18:11:00', '2026-04-07 18:11:00', '2026-04-07 18:11:00'),
(59, 2178, 'accepted', 1, '2026-04-07 18:11:01', '2026-04-07 18:11:01', '2026-04-07 18:11:01'),
(60, 2178, 'preparing', 1, '2026-04-07 18:11:01', '2026-04-07 18:11:01', '2026-04-07 18:11:01'),
(61, 2178, 'ready_for_pickup', 1, '2026-04-07 18:11:01', '2026-04-07 18:11:01', '2026-04-07 18:11:01'),
(62, 2178, 'picked_up', 1, '2026-04-07 18:11:02', '2026-04-07 18:11:02', '2026-04-07 18:11:02'),
(63, 2178, 'on_the_way', 1, '2026-04-07 18:11:02', '2026-04-07 18:11:02', '2026-04-07 18:11:02'),
(64, 2178, 'delivered', 1, '2026-04-07 18:11:03', '2026-04-07 18:11:03', '2026-04-07 18:11:03'),
(65, 2179, 'pending', 1, '2026-04-07 18:11:15', '2026-04-07 18:11:15', '2026-04-07 18:11:15'),
(66, 2179, 'accepted', 1, '2026-04-07 18:11:42', '2026-04-07 18:11:42', '2026-04-07 18:11:42'),
(67, 2179, 'preparing', 1, '2026-04-07 18:11:42', '2026-04-07 18:11:42', '2026-04-07 18:11:42'),
(68, 2179, 'ready_for_pickup', 1, '2026-04-07 18:11:43', '2026-04-07 18:11:43', '2026-04-07 18:11:43'),
(69, 2179, 'picked_up', 1, '2026-04-07 18:11:43', '2026-04-07 18:11:43', '2026-04-07 18:11:43'),
(70, 2179, 'on_the_way', 1, '2026-04-07 18:11:43', '2026-04-07 18:11:43', '2026-04-07 18:11:43'),
(71, 2179, 'delivered', 1, '2026-04-07 18:11:44', '2026-04-07 18:11:44', '2026-04-07 18:11:44'),
(72, 2180, 'pending', 1, '2026-04-07 18:13:33', '2026-04-07 18:13:33', '2026-04-07 18:13:33'),
(73, 2180, 'accepted', 1, '2026-04-07 18:13:35', '2026-04-07 18:13:35', '2026-04-07 18:13:35'),
(74, 2180, 'preparing', 1, '2026-04-07 18:13:35', '2026-04-07 18:13:35', '2026-04-07 18:13:35'),
(75, 2180, 'ready_for_pickup', 1, '2026-04-07 18:13:36', '2026-04-07 18:13:36', '2026-04-07 18:13:36'),
(76, 2180, 'picked_up', 1, '2026-04-07 18:13:37', '2026-04-07 18:13:37', '2026-04-07 18:13:37'),
(77, 2180, 'on_the_way', 1, '2026-04-07 18:13:38', '2026-04-07 18:13:38', '2026-04-07 18:13:38'),
(78, 2180, 'delivered', 1, '2026-04-07 18:13:39', '2026-04-07 18:13:39', '2026-04-07 18:13:39'),
(79, 2181, 'pending', 1, '2026-04-09 08:21:33', '2026-04-09 08:21:33', '2026-04-09 08:21:33'),
(80, 2181, 'cancelled', 1, '2026-04-09 08:21:43', '2026-04-09 08:21:43', '2026-04-09 08:21:43'),
(81, 2182, 'pending', 1, '2026-04-09 08:21:55', '2026-04-09 08:21:55', '2026-04-09 08:21:55'),
(82, 2182, 'accepted', 1, '2026-04-09 08:33:08', '2026-04-09 08:33:08', '2026-04-09 08:33:08'),
(83, 2183, 'pending', 1, '2026-04-09 08:33:52', '2026-04-09 08:33:52', '2026-04-09 08:33:52'),
(84, 2182, 'preparing', 1, '2026-04-09 08:34:19', '2026-04-09 08:34:19', '2026-04-09 08:34:19'),
(85, 2182, 'ready_for_pickup', 1, '2026-04-09 08:34:20', '2026-04-09 08:34:20', '2026-04-09 08:34:20'),
(86, 2182, 'picked_up', 1, '2026-04-09 08:34:20', '2026-04-09 08:34:20', '2026-04-09 08:34:20'),
(87, 2182, 'on_the_way', 1, '2026-04-09 08:34:20', '2026-04-09 08:34:20', '2026-04-09 08:34:20'),
(88, 2182, 'delivered', 1, '2026-04-09 08:34:20', '2026-04-09 08:34:20', '2026-04-09 08:34:20'),
(89, 2183, 'accepted', 1, '2026-04-09 08:34:22', '2026-04-09 08:34:22', '2026-04-09 08:34:22'),
(90, 2183, 'preparing', 1, '2026-04-09 08:34:22', '2026-04-09 08:34:22', '2026-04-09 08:34:22'),
(91, 2183, 'ready_for_pickup', 1, '2026-04-09 08:34:22', '2026-04-09 08:34:22', '2026-04-09 08:34:22'),
(92, 2183, 'picked_up', 1, '2026-04-09 08:34:22', '2026-04-09 08:34:22', '2026-04-09 08:34:22'),
(93, 2183, 'on_the_way', 1, '2026-04-09 08:34:23', '2026-04-09 08:34:23', '2026-04-09 08:34:23'),
(94, 2183, 'delivered', 1, '2026-04-09 08:34:23', '2026-04-09 08:34:23', '2026-04-09 08:34:23'),
(95, 2184, 'pending', 1, '2026-04-13 13:04:08', '2026-04-13 13:04:08', '2026-04-13 13:04:08'),
(96, 2184, 'accepted', 1, '2026-04-13 13:04:15', '2026-04-13 13:04:15', '2026-04-13 13:04:15'),
(97, 2184, 'preparing', 1, '2026-04-13 13:04:18', '2026-04-13 13:04:18', '2026-04-13 13:04:18'),
(98, 2184, 'ready_for_pickup', 1, '2026-04-13 13:04:20', '2026-04-13 13:04:20', '2026-04-13 13:04:20'),
(99, 2184, 'picked_up', 1, '2026-04-13 13:04:21', '2026-04-13 13:04:21', '2026-04-13 13:04:21'),
(100, 2184, 'on_the_way', 1, '2026-04-13 13:04:22', '2026-04-13 13:04:22', '2026-04-13 13:04:22'),
(101, 2184, 'delivered', 1, '2026-04-13 13:04:23', '2026-04-13 13:04:23', '2026-04-13 13:04:23');

-- --------------------------------------------------------

--
-- Table structure for table `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `email` varchar(191) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `personal_access_tokens`
--

CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tokenable_type` varchar(191) NOT NULL,
  `tokenable_id` bigint(20) UNSIGNED NOT NULL,
  `name` text NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `personal_access_tokens`
--

INSERT INTO `personal_access_tokens` (`id`, `tokenable_type`, `tokenable_id`, `name`, `token`, `abilities`, `last_used_at`, `expires_at`, `created_at`, `updated_at`) VALUES
(15, 'App\\Models\\User', 1, 'dashboard-web', '782690d0824e3e61c68ce6da654c744995291ebbf20eb5b681f0556f696673aa', '[\"*\"]', '2026-04-08 15:06:47', NULL, '2026-04-08 13:23:41', '2026-04-08 15:06:47'),
(14, 'App\\Models\\User', 1, 'dashboard-web', 'e8f08bce6b26d1ef33fda004ad81fc4f5ac032fe8d76ad9bb2aa977b0d3ce1ef', '[\"*\"]', '2026-04-07 19:47:55', NULL, '2026-04-07 18:02:25', '2026-04-07 19:47:55'),
(13, 'App\\Models\\User', 1, 'dashboard-web', '14459fe16228d0d661b6f5a2a2e9b90919964dc286a3d80264e4e359eba111d8', '[\"*\"]', '2026-04-06 14:23:07', NULL, '2026-04-06 14:15:25', '2026-04-06 14:23:07'),
(81, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'b188826c0adae24bc19aa486de680cb2f41e68d80615f15161a7484c338e804e', '[\"*\"]', NULL, NULL, '2026-04-27 14:19:53', '2026-04-27 14:19:53'),
(19, 'App\\Models\\User', 1, 'hunger-rush-mobile', '497879dbc8b2682171342ade7b549c706edc5bf724851312ccdd89558d419f86', '[\"*\"]', NULL, NULL, '2026-04-09 19:54:59', '2026-04-09 19:54:59'),
(20, 'App\\Models\\User', 53, 'hunger-rush-mobile', '6c54a4aa2f07626257d00299d3059cdc3f5f29c1190d08acfe06f5fd6ca51fff', '[\"*\"]', NULL, NULL, '2026-04-09 19:55:31', '2026-04-09 19:55:31'),
(21, 'App\\Models\\User', 53, 'hunger-rush-mobile', '8e743fae41dca22c6706f738471f035d185df2ec1181f74308398b10b6a54ab1', '[\"*\"]', NULL, NULL, '2026-04-09 19:56:03', '2026-04-09 19:56:03'),
(22, 'App\\Models\\User', 1, 'hunger-rush-mobile', '4b8e19339cb6bf1fe1085e82bae5595adf688b5da081fddfe31f93457d26c5a4', '[\"*\"]', NULL, NULL, '2026-04-13 12:27:52', '2026-04-13 12:27:52'),
(23, 'App\\Models\\User', 1, 'hunger-rush-mobile', '43c6c22eb2db824e0f122cb79f7e297417bf045cacf45d36d0bfc37ed8bdc6e7', '[\"*\"]', NULL, NULL, '2026-04-13 12:28:41', '2026-04-13 12:28:41'),
(24, 'App\\Models\\User', 1, 'hunger-rush-mobile', '96a5f9fdb922d7833c2ae2f76702cf8251b8af3b05f4a07a45cfe5e2d18d3331', '[\"*\"]', NULL, NULL, '2026-04-13 12:30:02', '2026-04-13 12:30:02'),
(25, 'App\\Models\\User', 1, 'hunger-rush-mobile', '778a7572710980fb1bcc7f538145dfd8f5fca0d6f34820d47550d0cbca2bc1ac', '[\"*\"]', NULL, NULL, '2026-04-13 12:42:57', '2026-04-13 12:42:57'),
(26, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'd2d2ead0d3a3982738145d9846e2090d8e8458383e97c27b19c88c2e476dd2f6', '[\"*\"]', NULL, NULL, '2026-04-13 12:46:15', '2026-04-13 12:46:15'),
(27, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'bf005c79993696e442308def69d51e65470ce1c2bd2949973cd07a37b132327f', '[\"*\"]', NULL, NULL, '2026-04-13 13:00:44', '2026-04-13 13:00:44'),
(29, 'App\\Models\\User', 1, 'hunger-rush-mobile', '0e7155b06f3da92fa5d9da1c68fabfb816d73c334850d33485e40e01acfe9a6a', '[\"*\"]', NULL, NULL, '2026-04-14 11:41:52', '2026-04-14 11:41:52'),
(30, 'App\\Models\\User', 1, 'hunger-rush-mobile', '340b7bb01aeb1ea3e975d59530faf608f64a6595be18772d23ebbfedb18c7444', '[\"*\"]', NULL, NULL, '2026-04-14 13:00:32', '2026-04-14 13:00:32'),
(31, 'App\\Models\\User', 1, 'hunger-rush-mobile', '6fb4c7c8d34ee1caab0d02252549bd9e63cdf809b3bcaf8b690b6ad3f4787642', '[\"*\"]', NULL, NULL, '2026-04-14 13:03:10', '2026-04-14 13:03:10'),
(32, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'ef3e859d3dd19ff11814c4ee0bc12109841361d075f389a91287400b6466c910', '[\"*\"]', NULL, NULL, '2026-04-14 13:17:19', '2026-04-14 13:17:19'),
(33, 'App\\Models\\User', 1, 'hunger-rush-mobile', '032bf38a857dc7ed0890ae0f9691d68253a76fb424990a7a962f7ffe6973c2e8', '[\"*\"]', NULL, NULL, '2026-04-14 13:22:46', '2026-04-14 13:22:46'),
(34, 'App\\Models\\User', 1, 'hunger-rush-mobile', '183aa5c551cf304b8879b9fd461cc5a349736e3448b578c6f8b0139cab8dfa0a', '[\"*\"]', NULL, NULL, '2026-04-14 13:25:39', '2026-04-14 13:25:39'),
(35, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'f1689caf13eff181db5e1173b28c1635f5ad4a7ca47dfffae54e5342ceed6af3', '[\"*\"]', NULL, NULL, '2026-04-14 13:26:00', '2026-04-14 13:26:00'),
(36, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'be39af174c5060ffa392f3b3dfc94823e65b1e934c274ded0f4137d1f9a4ed46', '[\"*\"]', NULL, NULL, '2026-04-14 13:30:47', '2026-04-14 13:30:47'),
(37, 'App\\Models\\User', 1, 'hunger-rush-mobile', '00903ad6c733a10d27a4544a0ded7cfa8a139ceb5b4f30436d0c09ba15170628', '[\"*\"]', NULL, NULL, '2026-04-14 13:32:03', '2026-04-14 13:32:03'),
(38, 'App\\Models\\User', 1, 'hunger-rush-mobile', '52b5a9b0b18347b3457ac86298b8a6969db46a69e3e8eea224b2f6d1afe9985e', '[\"*\"]', NULL, NULL, '2026-04-14 13:36:37', '2026-04-14 13:36:37'),
(39, 'App\\Models\\User', 1, 'hunger-rush-mobile', '99ba24f927d9d23b2c36860f35ba8ece17d1edd9819e7853c452ef288b8a66ad', '[\"*\"]', NULL, NULL, '2026-04-19 18:35:30', '2026-04-19 18:35:30'),
(40, 'App\\Models\\User', 9, 'hunger-rush-mobile', '615d417fb009ed15c22f458353eb118227a9362f431b35d74bbb1c4f2fc1036b', '[\"*\"]', NULL, NULL, '2026-04-19 18:38:52', '2026-04-19 18:38:52'),
(41, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'cdcbaa4ec1a59167e64e583d2aac8d168665492c969f434a55e1153550b7549d', '[\"*\"]', NULL, NULL, '2026-04-19 18:49:19', '2026-04-19 18:49:19'),
(42, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'a34f6774ea6fd7ad2b410984be8f57924832a881d10b5accbad299b3b35a15bb', '[\"*\"]', NULL, NULL, '2026-04-23 12:25:47', '2026-04-23 12:25:47'),
(43, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'cc84d7895e637d91cdb39845e8c5f328a2ef28087d7ed801ee7a982f22ce5cc7', '[\"*\"]', NULL, NULL, '2026-04-23 12:31:22', '2026-04-23 12:31:22'),
(44, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'cab6b7e17ca4f9e613718cff3fe2205b48c42d1a3dbbb04e9f3469e28e7a3a3f', '[\"*\"]', NULL, NULL, '2026-04-23 12:31:36', '2026-04-23 12:31:36'),
(45, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'cc140e4ecd5f539f85ac39906babb37bf4afbbba8efb433a09d78b9e0e33776c', '[\"*\"]', NULL, NULL, '2026-04-23 12:35:13', '2026-04-23 12:35:13'),
(46, 'App\\Models\\User', 1, 'hunger-rush-mobile', '94e3ff5b7c3f3c9a50e82e9ed0a181b72aef0912f1d70e584d883efbb6a6ef65', '[\"*\"]', NULL, NULL, '2026-04-23 12:35:51', '2026-04-23 12:35:51'),
(47, 'App\\Models\\User', 1, 'hunger-rush-mobile', '5cfe262f8403faab5119752ebdef6d758ff8e6f823473c28cb93f306185a91ba', '[\"*\"]', NULL, NULL, '2026-04-23 12:37:33', '2026-04-23 12:37:33'),
(48, 'App\\Models\\User', 1, 'hunger-rush-mobile', '6aab5a2d9297508ae4b268f1829c8ee390758752a81a0b90a265f8a67659a308', '[\"*\"]', NULL, NULL, '2026-04-23 12:49:10', '2026-04-23 12:49:10'),
(49, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'b3df8bce2d7613d2572a68f887be481521b50e4749369e333d46cc2418706c03', '[\"*\"]', NULL, NULL, '2026-04-23 17:24:59', '2026-04-23 17:24:59'),
(50, 'App\\Models\\User', 1, 'hunger-rush-mobile', '16bb9553965f28fc48ea6ad3dd4d236b0a557cca25a6e8896e05c6a391448fee', '[\"*\"]', NULL, NULL, '2026-04-23 17:28:46', '2026-04-23 17:28:46'),
(51, 'App\\Models\\User', 1, 'hunger-rush-mobile', '402b2fcff68dc7ac2f6e496cb6760537053d5de4d5f0f9584eadb055d65aafd8', '[\"*\"]', '2026-04-23 17:43:47', NULL, '2026-04-23 17:43:46', '2026-04-23 17:43:47'),
(52, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'e7c60527b757fa08e2b4e713ec911d7d6c2cd57e3832d064355a2d4c0ea9f00a', '[\"*\"]', '2026-04-23 17:45:09', NULL, '2026-04-23 17:45:08', '2026-04-23 17:45:09'),
(53, 'App\\Models\\User', 1, 'hunger-rush-mobile', '585723f4671e3926c18e91253345005b17d54492abebc4ceedfe694a04725e0c', '[\"*\"]', '2026-04-23 17:48:41', NULL, '2026-04-23 17:48:40', '2026-04-23 17:48:41'),
(54, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'b3633d0dbdee45e304cdf7b54243cfdf65172dd44d82368c42e21b9c5a1bc18e', '[\"*\"]', '2026-04-23 17:52:36', NULL, '2026-04-23 17:52:36', '2026-04-23 17:52:36'),
(55, 'App\\Models\\User', 1, 'hunger-rush-mobile', '67b06b9164d5a358f0b619bafc15518768c8af6bbe9660ae70d7555e069679bc', '[\"*\"]', '2026-04-23 18:12:08', NULL, '2026-04-23 18:12:07', '2026-04-23 18:12:08'),
(56, 'App\\Models\\User', 1, 'hunger-rush-mobile', '138fdc585d0aa10ce5df936ab83a23db3598032d569596f38540b6b35a82a810', '[\"*\"]', '2026-04-23 18:20:02', NULL, '2026-04-23 18:20:01', '2026-04-23 18:20:02'),
(57, 'App\\Models\\User', 1, 'hunger-rush-mobile', '0e7b2a66ac005bba319a475e7b6c982f86460d1bc10dcc00704b394115a47b12', '[\"*\"]', '2026-04-25 20:09:28', NULL, '2026-04-25 20:09:26', '2026-04-25 20:09:28'),
(58, 'App\\Models\\User', 2, 'hunger-rush-mobile', '2288804a82551419773a557cf8ecb0b9b4a27ab8f9365a72f8b897ce1cfed9bf', '[\"*\"]', NULL, NULL, '2026-04-25 20:10:44', '2026-04-25 20:10:44'),
(59, 'App\\Models\\User', 1, 'hunger-rush-mobile', '8379a9f127ee9b4ff6c7614f0a43efd1b4d7ed38f76f7811a968275867efde9e', '[\"*\"]', '2026-04-26 01:54:09', NULL, '2026-04-26 01:54:08', '2026-04-26 01:54:09'),
(60, 'App\\Models\\User', 1, 'hunger-rush-mobile', '5233a2c3f2c5ecf784ad8b26ddc7335d9c4989926f6f5bb473ddef68a364b25e', '[\"*\"]', '2026-04-26 02:16:03', NULL, '2026-04-26 02:16:02', '2026-04-26 02:16:03'),
(61, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'd0b4d2bd40d5b02c3c74ea454b5f30cb3c3f5e6ac1488b33fcc37f0be74001c8', '[\"*\"]', '2026-04-26 02:32:57', NULL, '2026-04-26 02:32:56', '2026-04-26 02:32:57'),
(62, 'App\\Models\\User', 1, 'hunger-rush-mobile', '86272c6dc4cbe1308d01d7a5aa8d11a428c864b17aeaa727f3311542f3d4866e', '[\"*\"]', '2026-04-26 02:38:11', NULL, '2026-04-26 02:38:10', '2026-04-26 02:38:11'),
(63, 'App\\Models\\User', 1, 'hunger-rush-mobile', '3eb347d5a4ac224237f12b9e4a919fdb43704769af7fb947aa2eb822cb57c46c', '[\"*\"]', '2026-04-26 02:45:41', NULL, '2026-04-26 02:45:41', '2026-04-26 02:45:41'),
(64, 'App\\Models\\User', 1, 'hunger-rush-mobile', '1285402fe9e124b4050a6cbd5d7d16f18cadbb371e98bdb509e680f71fd0ca67', '[\"*\"]', '2026-04-26 02:51:11', NULL, '2026-04-26 02:51:10', '2026-04-26 02:51:11'),
(65, 'App\\Models\\User', 1, 'hunger-rush-mobile', '026d8a102d4042318cd6140ec287d5341a523981dbe82704006f68e4732996a3', '[\"*\"]', '2026-04-26 03:19:48', NULL, '2026-04-26 03:19:48', '2026-04-26 03:19:48'),
(66, 'App\\Models\\User', 1, 'hunger-rush-mobile', '797f8dcae276919e18809240f8e78d05ee518fb04b6c461275c2b8fa4b7ba84b', '[\"*\"]', '2026-04-26 03:36:26', NULL, '2026-04-26 03:36:25', '2026-04-26 03:36:26'),
(67, 'App\\Models\\User', 1, 'hunger-rush-mobile', '637a3123c13304c25c359bef7c61e550dbcc645a2527b3b6f89ed5b14840ed87', '[\"*\"]', '2026-04-26 06:03:41', NULL, '2026-04-26 06:03:41', '2026-04-26 06:03:41'),
(68, 'App\\Models\\User', 1, 'hunger-rush-mobile', '949268701c176d09c03a405e25f0dc45d3bfb621d355a58b791ff990c9899fa7', '[\"*\"]', '2026-04-26 06:06:00', NULL, '2026-04-26 06:05:59', '2026-04-26 06:06:00'),
(69, 'App\\Models\\User', 1, 'hunger-rush-mobile', '9d91a0d0d82bc91a64d82b699f6fd072e19ac8c33374324c56cf10c6cecc79c5', '[\"*\"]', '2026-04-27 12:35:25', NULL, '2026-04-27 12:35:23', '2026-04-27 12:35:25'),
(70, 'App\\Models\\User', 1, 'hunger-rush-mobile', '1e99125b68e45a2a0b07353af43dc83f4eeafb83760432f36bfebc62384e167d', '[\"*\"]', '2026-04-27 12:44:42', NULL, '2026-04-27 12:44:42', '2026-04-27 12:44:42'),
(71, 'App\\Models\\User', 1, 'hunger-rush-mobile', '909513cd8de6bb284b8def01bf22aef3e5ab35dd564431887239f21f8ae4bf4d', '[\"*\"]', '2026-04-27 12:46:34', NULL, '2026-04-27 12:46:34', '2026-04-27 12:46:34'),
(72, 'App\\Models\\User', 1, 'hunger-rush-mobile', '0a2fdacbfb92297067cf4bcc65d68eb87d3e48c4e06debc4063b3e113fa9fd3d', '[\"*\"]', '2026-04-27 12:48:24', NULL, '2026-04-27 12:48:24', '2026-04-27 12:48:24'),
(73, 'App\\Models\\User', 2, 'hunger-rush-mobile', '7b4b6d4d51a2da9b9d05331a11b8ccda0d7164303561aae706482923974c4c24', '[\"*\"]', NULL, NULL, '2026-04-27 13:11:39', '2026-04-27 13:11:39'),
(74, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'efef5c3ad7910ed47cf19d0977730ed924359c3b3657d8d161074c5251350f93', '[\"*\"]', NULL, NULL, '2026-04-27 13:21:41', '2026-04-27 13:21:41'),
(75, 'App\\Models\\User', 1, 'hunger-rush-mobile', '094d6c413e52edb7adbccfe7b119a57d901ac0d414fc0a277559ca1664929ee3', '[\"*\"]', '2026-04-27 13:23:14', NULL, '2026-04-27 13:23:14', '2026-04-27 13:23:14'),
(76, 'App\\Models\\User', 2, 'hunger-rush-mobile', '2c041461674453f3ce52f470be914eca7c9c1c27ae9d03f64f169cc8eb43e19e', '[\"*\"]', NULL, NULL, '2026-04-27 13:26:05', '2026-04-27 13:26:05'),
(77, 'App\\Models\\User', 2, 'hunger-rush-mobile', '30f76f998bfaa12e33e4b32c396228b1ad0abf4c53cc051d5fe42dca5776bb89', '[\"*\"]', NULL, NULL, '2026-04-27 13:35:50', '2026-04-27 13:35:50'),
(78, 'App\\Models\\User', 2, 'hunger-rush-mobile', '49c0f0c6b6ac6006caf4fef3440a19e128817d16b80f1fe66dcb5523905a805a', '[\"*\"]', NULL, NULL, '2026-04-27 13:42:47', '2026-04-27 13:42:47'),
(82, 'App\\Models\\User', 2, 'hunger-rush-mobile', '8615ff7b6ed0af4838eee30285af208d63fce7dd3dc119f59d110eae672cee9f', '[\"*\"]', NULL, NULL, '2026-04-27 15:13:22', '2026-04-27 15:13:22'),
(83, 'App\\Models\\User', 2, 'hunger-rush-mobile', '50bfd70b62b518da0d811743616456707f95b9c72880b1b4c1f37b0ed284120d', '[\"*\"]', NULL, NULL, '2026-04-27 15:14:34', '2026-04-27 15:14:34'),
(84, 'App\\Models\\User', 1, 'hunger-rush-mobile', '78f5486cf4d6c242737d952461453402d9ed2f4b153710f883e1df9a6c26daef', '[\"*\"]', '2026-04-27 15:14:50', NULL, '2026-04-27 15:14:49', '2026-04-27 15:14:50'),
(85, 'App\\Models\\User', 1, 'hunger-rush-mobile', '5e63f5ee9a1d6f34c58c18a2227621b7be6498c483fc1b00845b97ff7a218bf7', '[\"*\"]', '2026-04-27 15:15:38', NULL, '2026-04-27 15:15:37', '2026-04-27 15:15:38'),
(86, 'App\\Models\\User', 2, 'hunger-rush-mobile', '79cd131721c52fe0671673ce34282aaabe25b78cdc3693af1727efd280b3fc57', '[\"*\"]', NULL, NULL, '2026-04-27 15:16:01', '2026-04-27 15:16:01'),
(87, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'c1fdbd54b73bd82517b427cb7eb5ad9cc35284e5c234eb758f12f080f55f71a3', '[\"*\"]', NULL, NULL, '2026-04-27 20:11:47', '2026-04-27 20:11:47'),
(88, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'f993490496e83a9db918c2b9e6b8f9de5eeafb91555168cf66f8d8b044c489b7', '[\"*\"]', NULL, NULL, '2026-04-27 20:12:14', '2026-04-27 20:12:14'),
(89, 'App\\Models\\User', 2, 'hunger-rush-mobile', '90968d0153fbe7011fe83b1fd344ea931e1ef0585fbb3de1fc01826419c35fca', '[\"*\"]', NULL, NULL, '2026-04-27 20:17:18', '2026-04-27 20:17:18'),
(90, 'App\\Models\\User', 2, 'hunger-rush-mobile', '14fd7353332a682a5ac35f3fe3b1249e57f22bc11d45f0fc40cbea20425b5bc1', '[\"*\"]', NULL, NULL, '2026-04-27 20:20:25', '2026-04-27 20:20:25'),
(91, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'b12a898dcca9358dc7e4119cf8b92c6d1341081c4ad0a9f415c7712c11ee1399', '[\"*\"]', NULL, NULL, '2026-04-27 20:27:08', '2026-04-27 20:27:08'),
(92, 'App\\Models\\User', 1, 'dashboard-web', '68d0210885d7207b4d2bf68baae1fe63ad47824e7e7219f52fc7e27209a3c255', '[\"*\"]', '2026-04-27 21:00:39', NULL, '2026-04-27 20:29:09', '2026-04-27 21:00:39'),
(93, 'App\\Models\\User', 2, 'hunger-rush-mobile', '80f3aef54b1145b5733c4372045ff71dc4aa49365219d04d719f6c9854599065', '[\"*\"]', NULL, NULL, '2026-04-27 20:36:05', '2026-04-27 20:36:05'),
(94, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'c8a9d0666cfaf7e7bcda0a1bda10ceffab56b348da621b972a982456e8fe7c7d', '[\"*\"]', NULL, NULL, '2026-04-30 18:36:25', '2026-04-30 18:36:25'),
(95, 'App\\Models\\User', 2, 'hunger-rush-mobile', '2733e48b2608e4bf02a2bfc85c3fd96cb4ff64dcb6d0d1e4b54205c6a1c124e7', '[\"*\"]', NULL, NULL, '2026-04-30 18:37:25', '2026-04-30 18:37:25'),
(96, 'App\\Models\\User', 2, 'hunger-rush-mobile', '6ed0e215a923ce24c1355df89778e3049487fc918174e1cd5f7f6ff3914f65fd', '[\"*\"]', NULL, NULL, '2026-04-30 18:38:42', '2026-04-30 18:38:42'),
(97, 'App\\Models\\User', 1, 'hunger-rush-mobile', '98ee9595976e31ffdb83824b8eed1a45291013c593e017001642cfbdf1e60005', '[\"*\"]', NULL, NULL, '2026-04-30 18:59:09', '2026-04-30 18:59:09'),
(98, 'App\\Models\\User', 2, 'hunger-rush-mobile', '4fd89c29267661f5cecab752b3a43291a634ba8aadeabb1c5d0bbcf062adb3ca', '[\"*\"]', NULL, NULL, '2026-04-30 19:01:46', '2026-04-30 19:01:46'),
(99, 'App\\Models\\User', 1, 'hunger-rush-mobile', '41c3a8d34515a3941c72ec3e308a963e38bce44dbfd1de6e41ef673e52221838', '[\"*\"]', '2026-04-30 19:02:27', NULL, '2026-04-30 19:02:26', '2026-04-30 19:02:27'),
(100, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'e2d727722b76d5fde9207cfabd49b258f7ddc30589105f0928691cd486e59c5a', '[\"*\"]', NULL, NULL, '2026-04-30 19:03:40', '2026-04-30 19:03:40'),
(101, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'c569907e6bc00c2d186620ba26acba9fc8e3b446c702a1dbfdadffefdd233525', '[\"*\"]', '2026-04-30 19:04:54', NULL, '2026-04-30 19:04:54', '2026-04-30 19:04:54'),
(102, 'App\\Models\\User', 2, 'hunger-rush-mobile', '765d123d120ecdbddf0241e4f7c3e27e103382dcfd7845884684f71525711104', '[\"*\"]', NULL, NULL, '2026-04-30 19:25:09', '2026-04-30 19:25:09'),
(103, 'App\\Models\\User', 2, 'hunger-rush-mobile', '9d43e87cb05bb3e2d48f04cc543f521685c6ea304d82580afb37c9215fed17ea', '[\"*\"]', NULL, NULL, '2026-04-30 19:25:36', '2026-04-30 19:25:36'),
(104, 'App\\Models\\User', 2, 'hunger-rush-mobile', '72d5def45b273b5c35f9a999ec3f019521662fe4580db329684dfb4f4de644e0', '[\"*\"]', NULL, NULL, '2026-04-30 19:25:54', '2026-04-30 19:25:54'),
(105, 'App\\Models\\User', 1, 'hunger-rush-mobile', '5a176a7dfbd55d4d4e01aeca5ac295e811858a047b5b07559ac9363887470ca3', '[\"*\"]', '2026-04-30 19:26:24', NULL, '2026-04-30 19:26:23', '2026-04-30 19:26:24'),
(106, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'e6ed73155efba0937d3f09f46b18920ac9a2932a7edea3cab9f4057b37ad44a8', '[\"*\"]', NULL, NULL, '2026-04-30 19:33:00', '2026-04-30 19:33:00'),
(107, 'App\\Models\\User', 1, 'hunger-rush-mobile', '8e3bd4df55d41cc54011ae7f5a81c0febfb922efd93d3dd3604160a551e20895', '[\"*\"]', '2026-04-30 19:34:16', NULL, '2026-04-30 19:34:16', '2026-04-30 19:34:16'),
(108, 'App\\Models\\User', 2, 'hunger-rush-mobile', '1b73cd9e42f9f81701d68dcb57c981e36fea47c885b2da46efaa4a8f48ad7b6e', '[\"*\"]', NULL, NULL, '2026-04-30 19:37:00', '2026-04-30 19:37:00'),
(109, 'App\\Models\\User', 1, 'hunger-rush-mobile', '22f746efe97c0b01b3332ffb282019554cda9ec82698f4fb6ea1af33ba3ef42c', '[\"*\"]', NULL, NULL, '2026-04-30 19:41:50', '2026-04-30 19:41:50'),
(110, 'App\\Models\\User', 1, 'hunger-rush-mobile', '5de07f0769221f79d937852c920587c1f76a55d37ef7f0669a1b06c5ed1553cb', '[\"*\"]', NULL, NULL, '2026-04-30 19:42:37', '2026-04-30 19:42:37'),
(111, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'cf897a45bdd79db2e82da08052a07d16aa5d97e547e0c942e76d15eeedd8d5c3', '[\"*\"]', NULL, NULL, '2026-04-30 19:48:16', '2026-04-30 19:48:16'),
(112, 'App\\Models\\User', 2, 'hunger-rush-mobile', '0acdcdfbba2d0b98445c1b32f4dca8fea526e86328fa85462cd94c650b9964f6', '[\"*\"]', NULL, NULL, '2026-04-30 19:50:28', '2026-04-30 19:50:28'),
(113, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'dbcb77ef70fcc4e893f26b1ebaec8f9ab233c18e54f64a32afc382c7d2541748', '[\"*\"]', NULL, NULL, '2026-04-30 19:56:01', '2026-04-30 19:56:01'),
(114, 'App\\Models\\User', 2, 'hunger-rush-mobile', '50cf33df03e34b430155155588a5ed7fc255622046ac8163a32f063fd9d117aa', '[\"*\"]', NULL, NULL, '2026-04-30 19:59:39', '2026-04-30 19:59:39'),
(115, 'App\\Models\\User', 2, 'hunger-rush-mobile', '4008f65960ea858645cc27f642c13cfb539881cb1f59b090c9ddb762e2aefcb7', '[\"*\"]', NULL, NULL, '2026-04-30 20:00:51', '2026-04-30 20:00:51'),
(116, 'App\\Models\\User', 2, 'hunger-rush-mobile', '8b250e1eca95dcef2647e0e163c675c8be549a5db7f08090f4eca14ff97bf5e5', '[\"*\"]', NULL, NULL, '2026-04-30 20:02:54', '2026-04-30 20:02:54'),
(117, 'App\\Models\\User', 2, 'hunger-rush-mobile', '5be9f2f14e25a4bbcb95f7de76f516f5a82ef304e3f7d15410ce19ec3eb4bdbf', '[\"*\"]', NULL, NULL, '2026-04-30 20:03:55', '2026-04-30 20:03:55'),
(118, 'App\\Models\\User', 2, 'hunger-rush-mobile', '59e75190f24bf7ea08e5690d40cd80c06e2c4d5da6860673fb31a1e0976a3769', '[\"*\"]', NULL, NULL, '2026-04-30 20:10:07', '2026-04-30 20:10:07'),
(119, 'App\\Models\\User', 2, 'hunger-rush-mobile', '41aebb38009777a3106351180f4671eb0502ea2e89091d9c88e1593d4ed96bd7', '[\"*\"]', NULL, NULL, '2026-04-30 20:15:17', '2026-04-30 20:15:17'),
(120, 'App\\Models\\User', 2, 'hunger-rush-mobile', '24a6a2f815a801cb7dc301e9da69df11833fab63de9188500d2a86a77f652c01', '[\"*\"]', NULL, NULL, '2026-04-30 20:18:08', '2026-04-30 20:18:08'),
(121, 'App\\Models\\User', 2, 'hunger-rush-mobile', '871d3211fee6e3555ecf02b5f0871028bf926c9107976a595f2f581f0a059a72', '[\"*\"]', NULL, NULL, '2026-04-30 20:18:27', '2026-04-30 20:18:27'),
(122, 'App\\Models\\User', 2, 'hunger-rush-mobile', '6a18b88c409847e1e2933dc04527af51d4c8bef52771433e19ca5bfe0779cf24', '[\"*\"]', NULL, NULL, '2026-04-30 20:22:54', '2026-04-30 20:22:54'),
(123, 'App\\Models\\User', 2, 'hunger-rush-mobile', '8bf9a43ec8d3c17db328b83fbc438cf8ae8de5946102b5d9ab75226bb86364c9', '[\"*\"]', NULL, NULL, '2026-04-30 20:27:50', '2026-04-30 20:27:50'),
(124, 'App\\Models\\User', 2, 'hunger-rush-mobile', '032235c130bbbc40c24b8479a85c0df2dde2a7139d44df272417a0e959044dd2', '[\"*\"]', NULL, NULL, '2026-04-30 20:32:05', '2026-04-30 20:32:05'),
(125, 'App\\Models\\User', 2, 'hunger-rush-mobile', '0e455f0e0ab081fe518c2b76e571d4ae40a449926b83024a2f31a5690af04e46', '[\"*\"]', NULL, NULL, '2026-04-30 20:37:17', '2026-04-30 20:37:17'),
(126, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'd8d3ae787cf31d23e1c482278354ea4ee0a5789bfe374b37c353567806581a1e', '[\"*\"]', NULL, NULL, '2026-04-30 20:44:57', '2026-04-30 20:44:57'),
(127, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'ade683228c8b40553e9a0ad4a31bb921f20517335c9e705de3bf2fe92e3cdc3c', '[\"*\"]', NULL, NULL, '2026-05-01 05:54:41', '2026-05-01 05:54:41'),
(128, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'f4433392f544326f039b8ad19bd5af95de752ddb7bcd28938bea2e0f68b508aa', '[\"*\"]', NULL, NULL, '2026-05-01 08:00:44', '2026-05-01 08:00:44'),
(129, 'App\\Models\\User', 2, 'hunger-rush-mobile', '29370609459e94d0a3a4744fa74aa6614980d9a0f98ba04a738aa8c642e2c90b', '[\"*\"]', NULL, NULL, '2026-05-01 08:01:20', '2026-05-01 08:01:20'),
(130, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'f50e91626cc10a9c7679419df9f18b0074e8216ed71a75694ab015762f0feca9', '[\"*\"]', NULL, NULL, '2026-05-01 08:09:08', '2026-05-01 08:09:08'),
(131, 'App\\Models\\User', 1, 'hunger-rush-mobile', '5aa3470f30c1308dab5e398eee0e36532938a4be50b9983e84b36a80f28298eb', '[\"*\"]', '2026-05-01 08:10:19', NULL, '2026-05-01 08:10:18', '2026-05-01 08:10:19'),
(132, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'f9a3e551bc6e2feb1ddfaea84273ecf30ee75f034885eb26d55229a16c02db8c', '[\"*\"]', NULL, NULL, '2026-05-01 08:12:17', '2026-05-01 08:12:17'),
(133, 'App\\Models\\User', 2, 'hunger-rush-mobile', '0d72e22d029fc4a23b3ef8c4a5e822a85444883e0aca346000dfb2a342ad9ba3', '[\"*\"]', NULL, NULL, '2026-05-01 10:31:52', '2026-05-01 10:31:52'),
(134, 'App\\Models\\User', 2, 'hunger-rush-mobile', '9cc6e1cfa2630ac739126a02e310809f1b022e634ed1e901b48b9c1229294ff8', '[\"*\"]', NULL, NULL, '2026-05-01 11:19:33', '2026-05-01 11:19:33'),
(135, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'd8716b932a2160c851bed4c541fb7a9d2bd73c3b63646307a4d65c17e7a5a20c', '[\"*\"]', NULL, NULL, '2026-05-01 11:54:08', '2026-05-01 11:54:08'),
(136, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'a308d43dee3e2976fff2c7e51ef18dbe94b1098c4f9f0ff934fbdb57d3ab2c79', '[\"*\"]', NULL, NULL, '2026-05-01 12:03:30', '2026-05-01 12:03:30'),
(137, 'App\\Models\\User', 2, 'hunger-rush-mobile', '2b9be3d5f31e25d42e2d255e1669c4f81fb064814198c2f249298dcf3e0c193b', '[\"*\"]', NULL, NULL, '2026-05-01 12:09:40', '2026-05-01 12:09:40'),
(138, 'App\\Models\\User', 2, 'hunger-rush-mobile', '9811cc5304dfd55c97eddd0beb953ffa31094db26cd50aeebe4a3ba0857c9526', '[\"*\"]', NULL, NULL, '2026-05-01 12:16:54', '2026-05-01 12:16:54'),
(139, 'App\\Models\\User', 2, 'hunger-rush-mobile', '39743772de7c44a5c0d0de895b25db48b99c70de2fc37f5b811e9d317d160eaa', '[\"*\"]', NULL, NULL, '2026-05-01 12:17:45', '2026-05-01 12:17:45'),
(140, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'e97338733bef9a452b2f5c9443be0af2601c54698e2d18aca45e9f5219a6521d', '[\"*\"]', NULL, NULL, '2026-05-01 12:22:23', '2026-05-01 12:22:23'),
(141, 'App\\Models\\User', 2, 'hunger-rush-mobile', '383074158682b99d8e08c02baa49e4f07ba83ce63ab5accd4bee9f7abf4c6f24', '[\"*\"]', NULL, NULL, '2026-05-01 12:23:21', '2026-05-01 12:23:21'),
(142, 'App\\Models\\User', 2, 'hunger-rush-mobile', '100f81bc745b287cfe73a7b5ecdab42fff80197883e61ef7cd93e45f7373bb34', '[\"*\"]', NULL, NULL, '2026-05-01 12:28:18', '2026-05-01 12:28:18'),
(143, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'f3ddd70241c705e39fb4fc94b943d646a3b0a0d5ccb58ff2c074948c4668dd8d', '[\"*\"]', NULL, NULL, '2026-05-01 12:40:55', '2026-05-01 12:40:55'),
(144, 'App\\Models\\User', 2, 'hunger-rush-mobile', '297eebe2d385da4c2c51c8041c869ab2c7113c93781c22a975f4d53c1ca7f28b', '[\"*\"]', NULL, NULL, '2026-05-01 12:47:29', '2026-05-01 12:47:29'),
(145, 'App\\Models\\User', 2, 'hunger-rush-mobile', '4bffff74bfdd4eeb6538a1a792a79dced6019d872c7ffa176be6db06a94cbc7a', '[\"*\"]', NULL, NULL, '2026-05-01 12:48:48', '2026-05-01 12:48:48'),
(146, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'c97e1c1c74d8ff86f463f2326a6b4c2d62eab031c3d679198c99d8e73b954966', '[\"*\"]', NULL, NULL, '2026-05-01 12:51:24', '2026-05-01 12:51:24'),
(147, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'e767853e44cdfd511af4bc4518555933169fd957ed2528c3a5d990702257cdf3', '[\"*\"]', '2026-05-01 12:53:37', NULL, '2026-05-01 12:53:36', '2026-05-01 12:53:37'),
(148, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'af0e52be8295999d3b148f9ff8e7c4dbf0847c057d3cb9466dd2c4a035cf985d', '[\"*\"]', NULL, NULL, '2026-05-01 12:53:56', '2026-05-01 12:53:56'),
(149, 'App\\Models\\User', 2, 'hunger-rush-mobile', '3dfed2e5a6d7cd6f4a95a323939d0bcdfcdcaf20193406e51c30d700ec1d7e49', '[\"*\"]', NULL, NULL, '2026-05-01 12:54:50', '2026-05-01 12:54:50'),
(150, 'App\\Models\\User', 2, 'hunger-rush-mobile', '265c377af96bccbfb14724c5111098ee592a4d3abe71914659adeeb28720ad25', '[\"*\"]', NULL, NULL, '2026-05-01 13:00:59', '2026-05-01 13:00:59'),
(151, 'App\\Models\\User', 2, 'hunger-rush-mobile', '70bc6e3f79a31ed3dca93a0f12353f026aed6b7df508a58fbf4f6bb242b10c61', '[\"*\"]', NULL, NULL, '2026-05-01 13:05:53', '2026-05-01 13:05:53'),
(152, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'fc80cb79b9ad6e0da8ff69940c749f2f313494e9d7c4b6780a064c45270f1aab', '[\"*\"]', NULL, NULL, '2026-05-01 13:08:38', '2026-05-01 13:08:38'),
(153, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'ded9f043a6b6f65496ae2a2708dbfc8e57e0b69b4415852fb38282f30d3bb6d2', '[\"*\"]', NULL, NULL, '2026-05-01 13:09:52', '2026-05-01 13:09:52'),
(154, 'App\\Models\\User', 2, 'hunger-rush-mobile', '773cdd96dd8140d76b22899377c5a85cce3fec9a05ddfc4b54b4c7286ef084d3', '[\"*\"]', NULL, NULL, '2026-05-01 13:10:13', '2026-05-01 13:10:13'),
(155, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'f979b690e934c4c0b31f02d735b95d4b632a907de2ee40403ad50059011420f6', '[\"*\"]', NULL, NULL, '2026-05-01 13:12:52', '2026-05-01 13:12:52'),
(156, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'd2c01a870adec77377e38bd016b230c7f59989e44f6fcd62654d5714505167d6', '[\"*\"]', NULL, NULL, '2026-05-01 13:16:44', '2026-05-01 13:16:44'),
(157, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'bb930b81c01dcc6cb2e6ee5cf2a7a75e957ddf238e6ba91e8c851cfa8b38f50c', '[\"*\"]', NULL, NULL, '2026-05-01 13:17:42', '2026-05-01 13:17:42'),
(158, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'b504d56b54aade9239b76b96b732f3bad70e96b6c8e0a2b88a874b9ad90498c7', '[\"*\"]', NULL, NULL, '2026-05-01 13:23:52', '2026-05-01 13:23:52'),
(159, 'App\\Models\\User', 2, 'hunger-rush-mobile', '0a3a91102802d38d0734a77d833645678b3d7ccb0d033fb25e030f48305b11fb', '[\"*\"]', NULL, NULL, '2026-05-01 13:29:50', '2026-05-01 13:29:50'),
(160, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'fe31c0539c656355db06b9cc07e7540a481c5b23e8da2203c78de4026010b95b', '[\"*\"]', NULL, NULL, '2026-05-01 13:42:58', '2026-05-01 13:42:58'),
(161, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'b23018e9b545b1c71f7099e8e7fc9b88261caf5b56456d04d67f5747f7cece68', '[\"*\"]', '2026-05-01 13:48:35', NULL, '2026-05-01 13:48:34', '2026-05-01 13:48:35'),
(162, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'a43f8bb390b4eb87c0a27290cf9a74923e5a471d85ee02b40ecb5a3b2aaaeb12', '[\"*\"]', NULL, NULL, '2026-05-01 15:15:38', '2026-05-01 15:15:38'),
(163, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'a5e3d0d28cf251d32343c8a62b5892f725f01fe34206791b78ea45d67d74393e', '[\"*\"]', NULL, NULL, '2026-05-01 15:15:59', '2026-05-01 15:15:59'),
(164, 'App\\Models\\User', 2, 'hunger-rush-mobile', '6e96fa5101d79cc74b11f37d2d7315693d56a073a4ab2c3fecb4124dd2ba4291', '[\"*\"]', NULL, NULL, '2026-05-01 15:28:57', '2026-05-01 15:28:57'),
(165, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'd63bb12a0600dc78a7d627ae059e9350b6e30e74ba79290a26a63c0f8db44502', '[\"*\"]', '2026-05-01 15:55:46', NULL, '2026-05-01 15:55:45', '2026-05-01 15:55:46'),
(166, 'App\\Models\\User', 2, 'hunger-rush-mobile', '2ba75aa52491846f5307a80c838bb2b865719dd368ff3da5a3bfaff777414de0', '[\"*\"]', NULL, NULL, '2026-05-01 15:57:59', '2026-05-01 15:57:59'),
(167, 'App\\Models\\User', 1, 'hunger-rush-mobile', '789e7e802442ff27deab75c6504889f882b5c9657316763c086c25a057bd9c43', '[\"*\"]', NULL, NULL, '2026-05-01 16:02:01', '2026-05-01 16:02:01'),
(168, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'b4efecdd52bf649f659ebbaac3113616c22c79b1f976040f0261f7c5d62e520d', '[\"*\"]', NULL, NULL, '2026-05-01 16:02:32', '2026-05-01 16:02:32'),
(169, 'App\\Models\\User', 2, 'hunger-rush-mobile', '0d99a65d8747a0dfc6dc08cf3d533bb7e1a1281d500a2fae79bca40b70cf091f', '[\"*\"]', NULL, NULL, '2026-05-01 16:05:53', '2026-05-01 16:05:53'),
(170, 'App\\Models\\User', 2, 'hunger-rush-mobile', '07398ade48148e3b5ad7e214b4297c64234a366c20187b54e227b216e7e58b9e', '[\"*\"]', NULL, NULL, '2026-05-01 16:10:31', '2026-05-01 16:10:31'),
(171, 'App\\Models\\User', 2, 'hunger-rush-mobile', '4791cc99a5599c3243f40a4d4f74228cd872e02c3b6ba6d13156512efb78fb49', '[\"*\"]', NULL, NULL, '2026-05-01 16:22:35', '2026-05-01 16:22:35'),
(172, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'e60059ac84d5f9773b6a300cacd3eb2934429e0956ed16f21b39cda6d3cb0ceb', '[\"*\"]', NULL, NULL, '2026-05-01 16:24:53', '2026-05-01 16:24:53'),
(173, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'ebca9a9f6d1fabf4df6cdb34e5e45c3a4e573d1c395a9c5657a9c460d1232932', '[\"*\"]', NULL, NULL, '2026-05-02 07:23:23', '2026-05-02 07:23:23'),
(174, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'df760db889bfa45015822a5f8f641e9b6a658aec5dee4ba5f31c97302ece8318', '[\"*\"]', NULL, NULL, '2026-05-02 07:23:47', '2026-05-02 07:23:47'),
(175, 'App\\Models\\User', 2, 'hunger-rush-mobile', '77660d62914e2ab198afbaf89d457dbe030689164da422faa0c49a644b213494', '[\"*\"]', NULL, NULL, '2026-05-02 07:28:17', '2026-05-02 07:28:17'),
(176, 'App\\Models\\User', 1, 'dashboard-web', '33e3e2556e94db75384b403787af10998601b86ed8d9bf7e09336c972bffaf0a', '[\"*\"]', '2026-05-02 10:18:06', NULL, '2026-05-02 07:30:09', '2026-05-02 10:18:06'),
(177, 'App\\Models\\User', 2, 'hunger-rush-mobile', '5df1b6bfbd7c967d144cbd72b3f659fbd5518136d7aefde6b6c699e537a557c5', '[\"*\"]', NULL, NULL, '2026-05-02 07:31:52', '2026-05-02 07:31:52'),
(178, 'App\\Models\\User', 2, 'hunger-rush-mobile', '6e2e8ba9e2cac28f7ad3b697230d5694b3dfc1656202e18a5a9a7f21b2e33aa1', '[\"*\"]', NULL, NULL, '2026-05-02 07:45:08', '2026-05-02 07:45:08'),
(179, 'App\\Models\\User', 2, 'hunger-rush-mobile', '5a5bf13a1d56a549d673d098eb9062b5fa4b55bc5a339caf3777d2c3de08ae95', '[\"*\"]', NULL, NULL, '2026-05-02 07:54:01', '2026-05-02 07:54:01'),
(180, 'App\\Models\\User', 2, 'hunger-rush-mobile', '75c4cd3da87774fe4f85aa8dc70092d3b51a5fce821d4a5793b0720e075a9026', '[\"*\"]', NULL, NULL, '2026-05-02 08:09:33', '2026-05-02 08:09:33'),
(181, 'App\\Models\\User', 2, 'hunger-rush-mobile', '8ebd53fbe80b84cbc3e1123dce08ec71167399e2ad658afda9db4c3d791b4e28', '[\"*\"]', NULL, NULL, '2026-05-02 08:57:37', '2026-05-02 08:57:37'),
(182, 'App\\Models\\User', 2, 'hunger-rush-mobile', '81640c93e5cec69127849b2b4fd4f6a8fdfe4cbbfe16265727a77e3a37986bea', '[\"*\"]', NULL, NULL, '2026-05-02 09:09:54', '2026-05-02 09:09:54'),
(183, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'b2d0c8264d3e28a062d158efa05400629fd1b3babc9e3ba75a36b69b55f29606', '[\"*\"]', NULL, NULL, '2026-05-02 09:17:38', '2026-05-02 09:17:38'),
(184, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'c56f92917efef3512e0f4c5649fae08b0b4891acce73c781800fa9c95f0b35c7', '[\"*\"]', NULL, NULL, '2026-05-02 09:21:36', '2026-05-02 09:21:36'),
(185, 'App\\Models\\User', 2, 'hunger-rush-mobile', '62ba6787817df2cb95cb9618778c916976562e500dd555580745f5cfe57315ad', '[\"*\"]', NULL, NULL, '2026-05-02 09:28:37', '2026-05-02 09:28:37'),
(186, 'App\\Models\\User', 2, 'hunger-rush-mobile', '2b7d21f45d6f1de18fb0d3d822492dea8b60ef0c7d38462d9359ee4ccde77980', '[\"*\"]', NULL, NULL, '2026-05-02 09:31:23', '2026-05-02 09:31:23'),
(187, 'App\\Models\\User', 2, 'hunger-rush-mobile', '9cebd2d6ef7ef2b43abc6eedf226ed4bda5533c53800b77b8751574ac6012f62', '[\"*\"]', NULL, NULL, '2026-05-02 09:41:00', '2026-05-02 09:41:00'),
(188, 'App\\Models\\User', 2, 'hunger-rush-mobile', '531d5c133cc870b8e49a3584be4874931dec4032211031914e0eb19592f16b4f', '[\"*\"]', NULL, NULL, '2026-05-02 09:44:29', '2026-05-02 09:44:29'),
(189, 'App\\Models\\User', 2, 'hunger-rush-mobile', '720f3b1a9c8109a063fabc0f75574ccfa5cc7d8955c500ea46b70bcd8d909156', '[\"*\"]', NULL, NULL, '2026-05-02 09:48:03', '2026-05-02 09:48:03'),
(190, 'App\\Models\\User', 2, 'hunger-rush-mobile', '81ba1deb9794318443ac740d093ec8f59f488eda18c8d8a675d39ec9240c444f', '[\"*\"]', NULL, NULL, '2026-05-02 09:49:10', '2026-05-02 09:49:10'),
(191, 'App\\Models\\User', 2, 'hunger-rush-mobile', '2ee3efb229b0cffbcd13da8fbbefb9a244e8326c53849bbf472aa9ba98fa29b5', '[\"*\"]', NULL, NULL, '2026-05-02 09:55:45', '2026-05-02 09:55:45'),
(192, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'ef3966ce0993157b7c2670a8ef39f5e15e9fcc023964c8d95b6100d4a51b08e1', '[\"*\"]', NULL, NULL, '2026-05-02 09:56:49', '2026-05-02 09:56:49'),
(193, 'App\\Models\\User', 2, 'hunger-rush-mobile', '4ece16c66f3d094325605254341c64d4bc4d809245d73ad38a6e5dfbf6bab5da', '[\"*\"]', NULL, NULL, '2026-05-02 09:59:15', '2026-05-02 09:59:15'),
(194, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'a64ab24dcf0bfd30b0464be02434ca23ad460045d475c588667a6041907e9982', '[\"*\"]', NULL, NULL, '2026-05-02 10:01:48', '2026-05-02 10:01:48'),
(195, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'e4af760a8c687abdd8a87235251d6d0e4052676047127c5b6fc3c003f1b2d968', '[\"*\"]', NULL, NULL, '2026-05-02 10:02:56', '2026-05-02 10:02:56'),
(196, 'App\\Models\\User', 2, 'hunger-rush-mobile', '526590004454459748bff026cdfe90a7f46841690c3a995d91e4dc5fe0e8718c', '[\"*\"]', NULL, NULL, '2026-05-02 10:03:36', '2026-05-02 10:03:36'),
(197, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'e6d9c956dc9b8aa3586a8bcf3696c419784119a498781a0d222e29ee04349038', '[\"*\"]', NULL, NULL, '2026-05-02 10:17:16', '2026-05-02 10:17:16'),
(198, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'ac4e4f3bec9f159fa8ebb8ee321dafe8f9ee7c9c996687ec53e10805bd952e0e', '[\"*\"]', NULL, NULL, '2026-05-02 12:31:03', '2026-05-02 12:31:03'),
(199, 'App\\Models\\User', 2, 'hunger-rush-mobile', '59f8006cf053f2a796295ecff95caf434f95d912a4ca465b8fde5b8953ac7776', '[\"*\"]', NULL, NULL, '2026-05-02 12:32:50', '2026-05-02 12:32:50'),
(200, 'App\\Models\\User', 2, 'hunger-rush-mobile', '3ef7a0a94fe1fc12aaa4fd18248c21a94f2c1a8023b2264b392d5cc7e710790e', '[\"*\"]', NULL, NULL, '2026-05-02 12:40:26', '2026-05-02 12:40:26'),
(201, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'ddcaf6e9a0da8f1d6c1aef0056e88a095d4d54496679ac051fe710ca12d146f8', '[\"*\"]', NULL, NULL, '2026-05-02 12:44:12', '2026-05-02 12:44:12'),
(202, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'b0e51625d521f703df3bb5d6cb1e0120c3f8e4c7393714863b597fc8e907d98c', '[\"*\"]', NULL, NULL, '2026-05-02 12:47:26', '2026-05-02 12:47:26'),
(203, 'App\\Models\\User', 2, 'hunger-rush-mobile', '630fae7c83a1a8e0bacc5826f8e4793bb023e299d9fc1a57f85b929a897440a5', '[\"*\"]', NULL, NULL, '2026-05-02 12:49:47', '2026-05-02 12:49:47'),
(204, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'fd785ac66e526bc4d9723ae426c5a66d27ace40defa12b27714cb673b3438268', '[\"*\"]', NULL, NULL, '2026-05-02 12:52:15', '2026-05-02 12:52:15'),
(205, 'App\\Models\\User', 1, 'hunger-rush-mobile', '7f8e4f97d045b8fdfb68c0eebfe1bcc000241b025c829e50e63ab5cb131137b4', '[\"*\"]', '2026-05-02 13:01:41', NULL, '2026-05-02 13:01:40', '2026-05-02 13:01:41'),
(206, 'App\\Models\\User', 2, 'hunger-rush-mobile', '0f703518b6b63d16e9d1297f2bf6c98f10eab7c40bd69fed5fa04e0980a8236a', '[\"*\"]', NULL, NULL, '2026-05-02 13:02:52', '2026-05-02 13:02:52'),
(207, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'fab14f8195a621958dfeedbd29e0207352836f122e3b3948a874f145ca0ef13d', '[\"*\"]', NULL, NULL, '2026-05-02 13:06:06', '2026-05-02 13:06:06'),
(208, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'a7a2537cb0044541fcbe187a488d98e80510c9c2a7f1de47e69fb06833b8b554', '[\"*\"]', '2026-05-02 18:17:18', NULL, '2026-05-02 18:17:16', '2026-05-02 18:17:18'),
(209, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'efdf891486b9b3aec99dc3bc1e67adcb0a509695259842dc007d752a484ab176', '[\"*\"]', NULL, NULL, '2026-05-02 18:19:12', '2026-05-02 18:19:12'),
(210, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'd83a1c82ac6403ad1fe96637318f3e8d1aec07b05ef45ff3fad2603dda79dad0', '[\"*\"]', '2026-05-02 18:23:37', NULL, '2026-05-02 18:23:36', '2026-05-02 18:23:37'),
(211, 'App\\Models\\User', 2, 'hunger-rush-mobile', '3a405580698ee6868632a875023f26b6ad5588b0ff2598458adbde5630a48c73', '[\"*\"]', NULL, NULL, '2026-05-02 18:28:22', '2026-05-02 18:28:22'),
(212, 'App\\Models\\User', 1, 'hunger-rush-mobile', '3a8a391b9b637b9c0e84161b44680d510f97c81a91cce750da5f3ab076c93ae7', '[\"*\"]', '2026-05-02 18:43:29', NULL, '2026-05-02 18:43:28', '2026-05-02 18:43:29'),
(213, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'b36e41341b760417e9af53c6752f48c4dd85d65aab41d225498fa0d0db8eb18a', '[\"*\"]', NULL, NULL, '2026-05-02 18:51:19', '2026-05-02 18:51:19'),
(214, 'App\\Models\\User', 1, 'hunger-rush-mobile', '2df2542b1f580dfcd40e1879996d1247f5aff4b586d027fc347d1c3df49d1df3', '[\"*\"]', '2026-05-02 19:00:14', NULL, '2026-05-02 19:00:14', '2026-05-02 19:00:14'),
(215, 'App\\Models\\User', 2, 'hunger-rush-mobile', '88f911b1f541fb22ad14f11c8aa34ca1c7d71946c1fbe5971525f875cba0f4d0', '[\"*\"]', NULL, NULL, '2026-05-02 19:02:12', '2026-05-02 19:02:12'),
(216, 'App\\Models\\User', 2, 'hunger-rush-mobile', '7642eec88a33391d3c7617b7703563e2a6556ab0b1da3bedaa37d8426799f211', '[\"*\"]', NULL, NULL, '2026-05-02 19:16:11', '2026-05-02 19:16:11'),
(217, 'App\\Models\\User', 1, 'hunger-rush-mobile', '6f708f8c4f9e6c6fe881ba7efca1d735d8d4c32eda72db6504e22c0f2fc6977c', '[\"*\"]', NULL, NULL, '2026-05-02 19:21:05', '2026-05-02 19:21:05'),
(218, 'App\\Models\\User', 2, 'hunger-rush-mobile', '53c64eb1b7fce69de12e243b0aa0f1226e0e1a2cbde59530cee2a6112271ad88', '[\"*\"]', NULL, NULL, '2026-05-02 19:31:29', '2026-05-02 19:31:29'),
(219, 'App\\Models\\User', 1, 'hunger-rush-mobile', 'df67e9ab698487d3c9c33d5655947130d5e531355bdf723d87ee52b94ae71e29', '[\"*\"]', '2026-05-02 19:33:35', NULL, '2026-05-02 19:33:34', '2026-05-02 19:33:35'),
(220, 'App\\Models\\User', 2, 'hunger-rush-mobile', 'c15fce1c44852d0049f101308a224cf7ba3b2dfe1b8245cd9786d2743a1617e3', '[\"*\"]', NULL, NULL, '2026-05-02 19:38:07', '2026-05-02 19:38:07'),
(221, 'App\\Models\\User', 1, 'hunger-rush-mobile', '16315eef4b7f20a343330d7f6ce21b6ad16fc967005ecafd1d5c7b540cf38ce6', '[\"*\"]', '2026-05-03 06:35:03', NULL, '2026-05-02 19:46:47', '2026-05-03 06:35:03'),
(222, 'App\\Models\\User', 2, 'hunger-rush-mobile', '6ae87e59a2094fbc3c9f2a2ebf99bdccbdfd3352c01cf5afcd3301f2506e3024', '[\"*\"]', '2026-05-03 06:36:57', NULL, '2026-05-03 06:35:37', '2026-05-03 06:36:57');

-- --------------------------------------------------------

--
-- Table structure for table `reports`
--

CREATE TABLE `reports` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `reporter_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `restaurant_id` bigint(20) UNSIGNED DEFAULT NULL,
  `order_id` bigint(20) UNSIGNED DEFAULT NULL,
  `subject` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `status` enum('open','reviewing','resolved','dismissed') NOT NULL DEFAULT 'open',
  `resolution` text DEFAULT NULL,
  `resolved_by` bigint(20) UNSIGNED DEFAULT NULL,
  `resolved_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `restaurants`
--

CREATE TABLE `restaurants` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `owner_user_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `settings` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`settings`)),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `restaurants`
--

INSERT INTO `restaurants` (`id`, `owner_user_id`, `name`, `description`, `status`, `settings`, `created_at`, `updated_at`) VALUES
(1, 1, 'HungerRush Demo Kitchen', 'Demo restaurant for frontend integration.', 'active', '{\"default_prep_time\":20,\"auto_accept_orders\":false,\"notifications_enabled\":true,\"currency\":\"USD\",\"timezone\":\"Asia\\/Beirut\"}', '2026-03-24 05:20:45', '2026-04-13 19:36:47'),
(2, 52, 'Test Restaurant', 'Restaurant account for testing', 'active', '{\"default_prep_time\":20,\"auto_accept_orders\":false,\"notifications_enabled\":true,\"currency\":\"USD\",\"timezone\":\"Asia\\/Beirut\"}', '2026-04-09 07:34:36', '2026-04-09 07:34:36');

-- --------------------------------------------------------

--
-- Table structure for table `restaurant_branches`
--

CREATE TABLE `restaurant_branches` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `restaurant_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `address` varchar(255) NOT NULL,
  `phone` varchar(32) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `open_hours` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`open_hours`)),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `restaurant_branches`
--

INSERT INTO `restaurant_branches` (`id`, `restaurant_id`, `name`, `address`, `phone`, `latitude`, `longitude`, `open_hours`, `created_at`, `updated_at`) VALUES
(4, 1, 'zaza', 'zaza', NULL, NULL, NULL, NULL, '2026-04-08 14:30:31', '2026-04-08 14:30:31');

-- --------------------------------------------------------

--
-- Table structure for table `reviews`
--

CREATE TABLE `reviews` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `restaurant_id` bigint(20) UNSIGNED NOT NULL,
  `customer_id` bigint(20) UNSIGNED NOT NULL,
  `order_id` bigint(20) UNSIGNED DEFAULT NULL,
  `rating` tinyint(3) UNSIGNED NOT NULL,
  `comment` text DEFAULT NULL,
  `reply` text DEFAULT NULL,
  `replied_by` bigint(20) UNSIGNED DEFAULT NULL,
  `replied_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sessions`
--

CREATE TABLE `sessions` (
  `id` varchar(191) NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `payload` longtext NOT NULL,
  `last_activity` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `support_requests`
--

CREATE TABLE `support_requests` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `channel` varchar(255) NOT NULL DEFAULT 'app',
  `subject` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `status` enum('open','in_progress','resolved','closed') NOT NULL DEFAULT 'open',
  `response` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(191) DEFAULT NULL,
  `phone` varchar(32) DEFAULT NULL,
  `role` enum('customer','restaurant_owner','restaurant_staff','driver','admin') NOT NULL DEFAULT 'customer',
  `status` enum('active','suspended') NOT NULL DEFAULT 'active',
  `last_login_at` timestamp NULL DEFAULT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `provider` varchar(255) DEFAULT NULL,
  `provider_id` varchar(255) DEFAULT NULL,
  `avatar` varchar(255) DEFAULT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `phone`, `role`, `status`, `last_login_at`, `email_verified_at`, `password`, `provider`, `provider_id`, `avatar`, `remember_token`, `created_at`, `updated_at`) VALUES
(1, 'Demo Restaurant Owner', 'owner@hungerrush.local', '01111111111', 'restaurant_owner', 'active', '2026-05-02 19:46:47', '2026-04-13 19:36:46', '$2y$12$jOSOOu.6oOC3cmmno7gK9OJNnmxGVYblDjU25/pg5XokN9NLZFCoi', NULL, NULL, NULL, 'PaechK5ubF', '2026-03-24 05:20:45', '2026-05-02 19:46:47'),
(2, 'Demo Customer', 'customer@hungerrush.local', '01999999999', 'customer', 'active', '2026-05-03 06:35:37', '2026-04-13 19:36:46', '$2y$12$5KXTSwhVnsk.5CCgqcda4Octphs7rxppKhlVK5JuxeUnL4e0J3vxu', NULL, NULL, NULL, 'uCBm3BQxqi', '2026-03-24 05:20:45', '2026-05-03 06:35:37'),
(3, 'Althea Schowalter', 'candelario43@example.net', '01094571392', 'customer', 'active', NULL, '2026-04-04 19:57:47', '$2y$12$Yzn6dLBlcD6G0jwb3RNZXuXrM.hYwLGka4yWv/2WX9BkYm2vrAJaO', NULL, NULL, NULL, 'xwRwwiP1VC', '2026-04-04 19:57:47', '2026-04-04 19:57:47'),
(4, 'Jovani Moore DVM', 'shanny.torphy@example.net', '01325611403', 'customer', 'active', NULL, '2026-04-04 19:57:47', '$2y$12$Yzn6dLBlcD6G0jwb3RNZXuXrM.hYwLGka4yWv/2WX9BkYm2vrAJaO', NULL, NULL, NULL, 'aWKYvASPLk', '2026-04-04 19:57:47', '2026-04-04 19:57:47'),
(5, 'Iliana Pfeffer', 'dbogan@example.com', '01363722414', 'customer', 'active', NULL, '2026-04-04 19:57:47', '$2y$12$Yzn6dLBlcD6G0jwb3RNZXuXrM.hYwLGka4yWv/2WX9BkYm2vrAJaO', NULL, NULL, NULL, 'UcNxqGiPtu', '2026-04-04 19:57:47', '2026-04-04 19:57:47'),
(6, 'Prof. Gladyce O\'Hara DDS', 'gjacobs@example.org', '01798963280', 'customer', 'active', NULL, '2026-04-04 19:57:47', '$2y$12$Yzn6dLBlcD6G0jwb3RNZXuXrM.hYwLGka4yWv/2WX9BkYm2vrAJaO', NULL, NULL, NULL, 'rP8dmAQkui', '2026-04-04 19:57:47', '2026-04-04 19:57:47'),
(7, 'Myrtice Huels', 'litzy.vonrueden@example.com', '01602068203', 'customer', 'active', NULL, '2026-04-04 20:17:09', '$2y$12$RsHUGqHD7eIC3io2N8WO4ezkDSpZcgXaBCssF9exMYc/Gl5xee3DG', NULL, NULL, NULL, 'K8oSW31Jd3', '2026-04-04 20:17:09', '2026-04-04 20:17:09'),
(8, 'Mateo Hoeger', 'dach.rickey@example.net', '01356752969', 'customer', 'active', NULL, '2026-04-04 20:17:09', '$2y$12$RsHUGqHD7eIC3io2N8WO4ezkDSpZcgXaBCssF9exMYc/Gl5xee3DG', NULL, NULL, NULL, 'J7ujxsMMYX', '2026-04-04 20:17:09', '2026-04-04 20:17:09'),
(9, 'Ayana Cole II', 'mitchell.michaela@example.com', '01429030495', 'customer', 'active', '2026-04-19 18:38:52', '2026-04-04 20:17:09', '$2y$12$RsHUGqHD7eIC3io2N8WO4ezkDSpZcgXaBCssF9exMYc/Gl5xee3DG', NULL, NULL, NULL, '7p9U33TOna', '2026-04-04 20:17:09', '2026-04-19 18:38:52'),
(10, 'Stephen Larson V', 'bryce46@example.net', '01101252614', 'customer', 'active', NULL, '2026-04-04 20:17:09', '$2y$12$RsHUGqHD7eIC3io2N8WO4ezkDSpZcgXaBCssF9exMYc/Gl5xee3DG', NULL, NULL, NULL, '1L4lxDqna9', '2026-04-04 20:17:09', '2026-04-04 20:17:09'),
(11, 'Flo Kemmer', 'stoltenberg.bertram@example.net', '01644845659', 'customer', 'active', NULL, '2026-04-04 20:28:44', '$2y$12$IQs78gTMuhmwNQdWo9WPyO6ApnDYeghBXam7VAkTbiLgBXDuj7EfG', NULL, NULL, NULL, 'QNgMCnt4ck', '2026-04-04 20:28:44', '2026-04-04 20:28:44'),
(12, 'Miss Ollie Schuppe', 'fernando.cruickshank@example.org', '01775333322', 'customer', 'active', NULL, '2026-04-04 20:28:44', '$2y$12$IQs78gTMuhmwNQdWo9WPyO6ApnDYeghBXam7VAkTbiLgBXDuj7EfG', NULL, NULL, NULL, '8vhtuSNfFC', '2026-04-04 20:28:44', '2026-04-04 20:28:44'),
(13, 'Dr. Frances Cartwright DDS', 'amaya07@example.org', '01493268511', 'customer', 'active', NULL, '2026-04-04 20:28:44', '$2y$12$IQs78gTMuhmwNQdWo9WPyO6ApnDYeghBXam7VAkTbiLgBXDuj7EfG', NULL, NULL, NULL, 'a5MkSrs2BW', '2026-04-04 20:28:44', '2026-04-04 20:28:44'),
(14, 'Robb Stoltenberg', 'calista.dooley@example.com', '01228507020', 'customer', 'active', NULL, '2026-04-04 20:28:44', '$2y$12$IQs78gTMuhmwNQdWo9WPyO6ApnDYeghBXam7VAkTbiLgBXDuj7EfG', NULL, NULL, NULL, '9IhZIc4H2y', '2026-04-04 20:28:44', '2026-04-04 20:28:44'),
(15, 'Quick Order Customer', 'quick-order-owner-1@hungerrush.local', NULL, 'customer', 'active', NULL, NULL, '$2y$12$9BG0qm3c4Nh0x6/3tKZlBu5lQEd7sOQkxjZxdYvnxw.D2rVKEHB7.', NULL, NULL, NULL, NULL, '2026-04-04 20:39:41', '2026-04-04 20:39:41'),
(16, 'Analytics Customer 1', 'analytics.customer1@hungerrush.local', '07000000001', 'customer', 'active', NULL, '2026-04-05 09:35:34', '$2y$12$i/jZuqPTCm6svIPUtRsc5e2nT23p3/QCmrwMmulc.LhVFBJLcKRi6', NULL, NULL, NULL, NULL, '2026-04-05 09:35:34', '2026-04-05 09:35:34'),
(17, 'Analytics Customer 2', 'analytics.customer2@hungerrush.local', '07000000002', 'customer', 'active', NULL, '2026-04-05 09:35:34', '$2y$12$UAIOFlZX2cb7OxZvxZEnxetYHMc4waQ/9aLeAiosdqtsUr..OtkBO', NULL, NULL, NULL, NULL, '2026-04-05 09:35:34', '2026-04-05 09:35:34'),
(18, 'Analytics Customer 3', 'analytics.customer3@hungerrush.local', '07000000003', 'customer', 'active', NULL, '2026-04-05 09:35:34', '$2y$12$Fnf/mv2mYw0ELB07bNT.luZ44HJu7k9zJr7Y1eAXdFtA5dvdRVe3K', NULL, NULL, NULL, NULL, '2026-04-05 09:35:34', '2026-04-05 09:35:34'),
(19, 'Analytics Customer 4', 'analytics.customer4@hungerrush.local', '07000000004', 'customer', 'active', NULL, '2026-04-05 09:35:34', '$2y$12$USIdf7Irbl3Lj9iBPE/uCeF/r9DitFi0ZREbzYr8xuGuPCy1e9tem', NULL, NULL, NULL, NULL, '2026-04-05 09:35:34', '2026-04-05 09:35:34'),
(20, 'Analytics Customer 5', 'analytics.customer5@hungerrush.local', '07000000005', 'customer', 'active', NULL, '2026-04-05 09:35:34', '$2y$12$EJAUQmkbwqRF2YZB5Y70S.q3Pvs6QXI6XaxFn7FsDM.9gZLDWJGn6', NULL, NULL, NULL, NULL, '2026-04-05 09:35:35', '2026-04-05 09:35:35'),
(21, 'Analytics Customer 6', 'analytics.customer6@hungerrush.local', '07000000006', 'customer', 'active', NULL, '2026-04-05 09:35:35', '$2y$12$WZk19yHn1bfh.6a0.LCXq.1QdtZpiqJtFcJaHbxvQP9JbWzmU9Eyu', NULL, NULL, NULL, NULL, '2026-04-05 09:35:35', '2026-04-05 09:35:35'),
(22, 'Analytics Customer 7', 'analytics.customer7@hungerrush.local', '07000000007', 'customer', 'active', NULL, '2026-04-05 09:35:35', '$2y$12$GET/S1tOIglXVm4LSepUUuFyDuyq9hXoDFtlEnZia2tD7rWeQJCEy', NULL, NULL, NULL, NULL, '2026-04-05 09:35:35', '2026-04-05 09:35:35'),
(23, 'Analytics Customer 8', 'analytics.customer8@hungerrush.local', '07000000008', 'customer', 'active', NULL, '2026-04-05 09:35:35', '$2y$12$94ufdUpXgZ/4Qw.hem/rO.TsgZ.IjhV0MMb4rpZ6G70uy7UAjfKRW', NULL, NULL, NULL, NULL, '2026-04-05 09:35:35', '2026-04-05 09:35:35'),
(24, 'Analytics Customer 9', 'analytics.customer9@hungerrush.local', '07000000009', 'customer', 'active', NULL, '2026-04-05 09:35:35', '$2y$12$IKXX17VZbhDhMbVhG4D1AuXQ/HBhFmlhf.JgOfun4vjFu3jeZ9G.G', NULL, NULL, NULL, NULL, '2026-04-05 09:35:35', '2026-04-05 09:35:35'),
(25, 'Analytics Customer 10', 'analytics.customer10@hungerrush.local', '07000000010', 'customer', 'active', NULL, '2026-04-05 09:35:35', '$2y$12$TeAUJLDwZfhuOBvRcKIUguUWHfZMoWnawcvLlB4bPTYl24OT8C7fK', NULL, NULL, NULL, NULL, '2026-04-05 09:35:36', '2026-04-05 09:35:36'),
(26, 'Analytics Customer 11', 'analytics.customer11@hungerrush.local', '07000000011', 'customer', 'active', NULL, '2026-04-05 09:35:36', '$2y$12$X/HTBfykCQ697e./5X9rLO4z0IPhyB6k6tivzguTmPxJENDX3P2ru', NULL, NULL, NULL, NULL, '2026-04-05 09:35:36', '2026-04-05 09:35:36'),
(27, 'Analytics Customer 12', 'analytics.customer12@hungerrush.local', '07000000012', 'customer', 'active', NULL, '2026-04-05 09:35:36', '$2y$12$rBdoeM0o723jhK74XUaQU.GIlXy1nzAPP2iI9ZWbb25AP2DAPl81O', NULL, NULL, NULL, NULL, '2026-04-05 09:35:36', '2026-04-05 09:35:36'),
(28, 'Analytics Customer 13', 'analytics.customer13@hungerrush.local', '07000000013', 'customer', 'active', NULL, '2026-04-05 09:35:36', '$2y$12$pIx6pXa3MvQttmSZG9ayLe3BBp/I0BvCJLTcv60uqEk09Ad72s0.C', NULL, NULL, NULL, NULL, '2026-04-05 09:35:36', '2026-04-05 09:35:36'),
(29, 'Analytics Customer 14', 'analytics.customer14@hungerrush.local', '07000000014', 'customer', 'active', NULL, '2026-04-05 09:35:36', '$2y$12$IxnXUWmI18Wu50yNleVVuudgQyATuaIIOQtMFHpzWI1jtWyeanpge', NULL, NULL, NULL, NULL, '2026-04-05 09:35:36', '2026-04-05 09:35:36'),
(30, 'Analytics Customer 15', 'analytics.customer15@hungerrush.local', '07000000015', 'customer', 'active', NULL, '2026-04-05 09:35:36', '$2y$12$TzJcTC.nJny1YEplsjul0.iEF8MdYGoDkl2/q.5vZlTcUQOFZYRmK', NULL, NULL, NULL, NULL, '2026-04-05 09:35:37', '2026-04-05 09:35:37'),
(31, 'Analytics Customer 16', 'analytics.customer16@hungerrush.local', '07000000016', 'customer', 'active', NULL, '2026-04-05 09:35:37', '$2y$12$Bx7UckiGLr9uvgZVkHlRHu8EHADvZkioNOYqNCoaWlFMowF814rdu', NULL, NULL, NULL, NULL, '2026-04-05 09:35:37', '2026-04-05 09:35:37'),
(32, 'Analytics Customer 17', 'analytics.customer17@hungerrush.local', '07000000017', 'customer', 'active', NULL, '2026-04-05 09:35:37', '$2y$12$BPEjeH79VgI8uygWa8Dl9u6k2yrZGS/Mqy/QjYZ6hdJFksKGuKmm6', NULL, NULL, NULL, NULL, '2026-04-05 09:35:37', '2026-04-05 09:35:37'),
(33, 'Analytics Customer 18', 'analytics.customer18@hungerrush.local', '07000000018', 'customer', 'active', NULL, '2026-04-05 09:35:37', '$2y$12$aabWdpnG.7MzzJrhtW/wregaw5KiNLZODrBhXkdxo4WZpIYxJpuoy', NULL, NULL, NULL, NULL, '2026-04-05 09:35:37', '2026-04-05 09:35:37'),
(34, 'Analytics Customer 19', 'analytics.customer19@hungerrush.local', '07000000019', 'customer', 'active', NULL, '2026-04-05 09:35:37', '$2y$12$VZmDRQkCdXSBma2yqIYDDe6gvlBbJ4F1Ofny7nnf9vzPYI/vAo0uW', NULL, NULL, NULL, NULL, '2026-04-05 09:35:38', '2026-04-05 09:35:38'),
(35, 'Analytics Customer 20', 'analytics.customer20@hungerrush.local', '07000000020', 'customer', 'active', NULL, '2026-04-05 09:35:38', '$2y$12$hIaJ1xwuJktiIfqQakz1cOuaa.w4HgZFr2Yhc3B5DJMYF14gtugpy', NULL, NULL, NULL, NULL, '2026-04-05 09:35:38', '2026-04-05 09:35:38'),
(36, 'Analytics Customer 21', 'analytics.customer21@hungerrush.local', '07000000021', 'customer', 'active', NULL, '2026-04-05 09:35:38', '$2y$12$K8vG42KYaJxyPgtLkvbE0u.GCR6wIWR1iRcqZGysL70w2D545wmSe', NULL, NULL, NULL, NULL, '2026-04-05 09:35:38', '2026-04-05 09:35:38'),
(37, 'Analytics Customer 22', 'analytics.customer22@hungerrush.local', '07000000022', 'customer', 'active', NULL, '2026-04-05 09:35:38', '$2y$12$oQamDutJL4fTjA54VVNq0eTzvs/2sfJwpzoh7K4BMhHKV8SXsi3xu', NULL, NULL, NULL, NULL, '2026-04-05 09:35:38', '2026-04-05 09:35:38'),
(38, 'Analytics Customer 23', 'analytics.customer23@hungerrush.local', '07000000023', 'customer', 'active', NULL, '2026-04-05 09:35:38', '$2y$12$opDKqps9N2HrevXZ7Mc/muQrFz7xf8hT9.ZgtW/pGzV/lQEVZDfOy', NULL, NULL, NULL, NULL, '2026-04-05 09:35:39', '2026-04-05 09:35:39'),
(39, 'Analytics Customer 24', 'analytics.customer24@hungerrush.local', '07000000024', 'customer', 'active', NULL, '2026-04-05 09:35:39', '$2y$12$9jIXGhGehWTYPGu5ZzpLveu50b29PQahbx/QA9q6ineoFR69phWRG', NULL, NULL, NULL, NULL, '2026-04-05 09:35:39', '2026-04-05 09:35:39'),
(40, 'Analytics Customer 25', 'analytics.customer25@hungerrush.local', '07000000025', 'customer', 'active', NULL, '2026-04-05 09:35:39', '$2y$12$P5mdFbA8rMUayuC7hsIVZOviU05aDo4FSRQfRG9Qe1IQMJZGQqFEy', NULL, NULL, NULL, NULL, '2026-04-05 09:35:39', '2026-04-05 09:35:39'),
(41, 'Analytics Customer 26', 'analytics.customer26@hungerrush.local', '07000000026', 'customer', 'active', NULL, '2026-04-05 09:35:39', '$2y$12$SEQ4F5TUdcj2dmrwPsNIZuiDdffzePowdJ5COgZIVELlf81ahaDeK', NULL, NULL, NULL, NULL, '2026-04-05 09:35:39', '2026-04-05 09:35:39'),
(42, 'Analytics Customer 27', 'analytics.customer27@hungerrush.local', '07000000027', 'customer', 'active', NULL, '2026-04-05 09:35:39', '$2y$12$BCjWIUtID7fRvTAif.OlWuP4pOzr5TiKPHgv5LMU5AKHYyYYZ4DoG', NULL, NULL, NULL, NULL, '2026-04-05 09:35:40', '2026-04-05 09:35:40'),
(43, 'Analytics Customer 28', 'analytics.customer28@hungerrush.local', '07000000028', 'customer', 'active', NULL, '2026-04-05 09:35:40', '$2y$12$gcbbCCzyo5oMrfqnEkqLh.hX1VOP4RkbncNocrUPhL46l0ymnWgB.', NULL, NULL, NULL, NULL, '2026-04-05 09:35:40', '2026-04-05 09:35:40'),
(44, 'Analytics Customer 29', 'analytics.customer29@hungerrush.local', '07000000029', 'customer', 'active', NULL, '2026-04-05 09:35:40', '$2y$12$I5g1lzCmssgcOZt21GuOcuAZG41gfAfWmcTQuwqtGSUPKDiaSXtGa', NULL, NULL, NULL, NULL, '2026-04-05 09:35:40', '2026-04-05 09:35:40'),
(45, 'Analytics Customer 30', 'analytics.customer30@hungerrush.local', '07000000030', 'customer', 'active', NULL, '2026-04-05 09:35:40', '$2y$12$IWtEz7wLpAvuzp5T4QM1y.qT1ehOISg71JkQtNNheczuUNK.V4Nia', NULL, NULL, NULL, NULL, '2026-04-05 09:35:40', '2026-04-05 09:35:40'),
(46, 'Analytics Customer 31', 'analytics.customer31@hungerrush.local', '07000000031', 'customer', 'active', NULL, '2026-04-05 09:35:40', '$2y$12$Z3pqCGIeJknlxFIzC8G9buEaTq5q1.M8L60ISHkJ.Y50.5OSxOh7G', NULL, NULL, NULL, NULL, '2026-04-05 09:35:40', '2026-04-05 09:35:40'),
(47, 'Analytics Customer 32', 'analytics.customer32@hungerrush.local', '07000000032', 'customer', 'active', NULL, '2026-04-05 09:35:40', '$2y$12$X.vlv33dEM90wswRNB5Uv.c8MW57./8VZ.Vyip38Rrt8OGwVL8G8i', NULL, NULL, NULL, NULL, '2026-04-05 09:35:41', '2026-04-05 09:35:41'),
(48, 'Analytics Customer 33', 'analytics.customer33@hungerrush.local', '07000000033', 'customer', 'active', NULL, '2026-04-05 09:35:41', '$2y$12$9.O6iRbHPqzhoxBzfSovk.2kUt2JvgmBiav9RvgKmKQ/dTL/oCIhy', NULL, NULL, NULL, NULL, '2026-04-05 09:35:41', '2026-04-05 09:35:41'),
(49, 'Analytics Customer 34', 'analytics.customer34@hungerrush.local', '07000000034', 'customer', 'active', NULL, '2026-04-05 09:35:41', '$2y$12$bHq6v7Q71GKIj4C6tJwyB.ZXhmr.tfZesPMlENErr5HD3efwKLZJu', NULL, NULL, NULL, NULL, '2026-04-05 09:35:41', '2026-04-05 09:35:41'),
(50, 'Analytics Customer 35', 'analytics.customer35@hungerrush.local', '07000000035', 'customer', 'active', NULL, '2026-04-05 09:35:41', '$2y$12$qBMinq.yILrD8d3Vol0CRuOvzZ2blX3kV1WflRTdaqRkC0J86ygZ.', NULL, NULL, NULL, NULL, '2026-04-05 09:35:41', '2026-04-05 09:35:41'),
(51, 'Analytics Customer 36', 'analytics.customer36@hungerrush.local', '07000000036', 'customer', 'active', NULL, '2026-04-05 09:35:41', '$2y$12$fizGXLezE27xhG2I/1TX6OEawhQMzk4cGcsjDyRC/eUCvslZxghqu', NULL, NULL, NULL, NULL, '2026-04-05 09:35:42', '2026-04-05 09:35:42'),
(54, 'Caitlyn Doyle', 'emoen@example.net', '01638511313', 'customer', 'active', NULL, '2026-04-13 19:36:47', '$2y$12$2BvhiOf7Okk.fAhSIdcPy.lqTt4/5y32poI.zmfeDZ0TiqRa7PNzS', NULL, NULL, NULL, '89Pxs4sgOW', '2026-04-13 19:36:47', '2026-04-13 19:36:47'),
(52, 'Test Restaurant User', 'test@gmail.com', NULL, 'restaurant_owner', 'active', '2026-04-09 07:37:06', NULL, '$2y$12$9bcdd8MPJpPFBYwdpz1aReilYoiqIf1TgI3SzkW9dxstot9GjutRS', NULL, NULL, NULL, NULL, '2026-04-09 07:34:36', '2026-04-09 07:37:06'),
(53, 'jamal', 'jamal2005arabi@gmail.com', '03 192 031', 'customer', 'active', '2026-04-09 19:56:03', NULL, '$2y$12$bi94ULCIEwXBbceWosTv1ecRU.dGxrogFUh5lZPbp30i0dFTMauYy', NULL, NULL, NULL, NULL, '2026-04-09 19:55:31', '2026-04-09 19:56:03'),
(55, 'Ms. Burnice Jakubowski MD', 'mozelle87@example.com', '01383138700', 'customer', 'active', NULL, '2026-04-13 19:36:47', '$2y$12$2BvhiOf7Okk.fAhSIdcPy.lqTt4/5y32poI.zmfeDZ0TiqRa7PNzS', NULL, NULL, NULL, 'z1o9k48XYE', '2026-04-13 19:36:47', '2026-04-13 19:36:47'),
(56, 'Prof. Brady Turcotte Sr.', 'macejkovic.diego@example.net', '01325404318', 'customer', 'active', NULL, '2026-04-13 19:36:47', '$2y$12$2BvhiOf7Okk.fAhSIdcPy.lqTt4/5y32poI.zmfeDZ0TiqRa7PNzS', NULL, NULL, NULL, 'nuhqjZJpDg', '2026-04-13 19:36:47', '2026-04-13 19:36:47'),
(57, 'Carey Weimann', 'arely49@example.net', '01729545680', 'customer', 'active', NULL, '2026-04-13 19:36:47', '$2y$12$2BvhiOf7Okk.fAhSIdcPy.lqTt4/5y32poI.zmfeDZ0TiqRa7PNzS', NULL, NULL, NULL, 'jys1l0uWe9', '2026-04-13 19:36:47', '2026-04-13 19:36:47');

-- --------------------------------------------------------

--
-- Table structure for table `videos`
--

CREATE TABLE `videos` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `restaurant_id` bigint(20) UNSIGNED NOT NULL,
  `menu_item_id` bigint(20) UNSIGNED DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `media_url` varchar(255) NOT NULL,
  `thumbnail_url` varchar(255) DEFAULT NULL,
  `status` enum('draft','published','archived') NOT NULL DEFAULT 'draft',
  `published_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `videos`
--

INSERT INTO `videos` (`id`, `restaurant_id`, `menu_item_id`, `title`, `description`, `media_url`, `thumbnail_url`, `status`, `published_at`, `created_at`, `updated_at`) VALUES
(15, 1, 27, 'Lava Cake Final Touch', 'Dusting cocoa right before serving.', 'https://example.com/videos/lava-cake.mp4', 'https://images.unsplash.com/photo-1617305855058-336d24456869?auto=format&fit=crop&w=900&q=80', 'draft', NULL, '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(14, 1, 25, 'Double Cheese Blaze Reveal', 'A cheesy pull guaranteed to make customers hungry.', 'https://example.com/videos/double-cheese-blaze.mp4', 'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=900&q=80', 'published', '2026-04-10 19:36:48', '2026-04-13 19:36:48', '2026-04-13 19:36:48'),
(13, 1, 24, 'Classic Burger Build', 'Layering the perfect burger in 20 seconds.', 'https://example.com/videos/classic-burger.mp4', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80', 'published', '2026-04-11 19:36:48', '2026-04-13 19:36:48', '2026-04-13 19:36:48');

-- --------------------------------------------------------

--
-- Table structure for table `video_engagements`
--

CREATE TABLE `video_engagements` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `video_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `type` enum('like','share','save','view') NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `video_engagements`
--

INSERT INTO `video_engagements` (`id`, `video_id`, `user_id`, `type`, `created_at`, `updated_at`) VALUES
(22014, 15, 1, 'view', '2026-04-09 19:36:48', '2026-04-13 19:36:48'),
(22013, 15, 57, 'view', '2026-04-12 19:36:48', '2026-04-11 19:36:48'),
(22012, 15, 56, 'like', '2026-04-13 19:36:48', '2026-04-09 19:36:48'),
(22011, 15, 56, 'view', '2026-04-09 19:36:48', '2026-04-08 19:36:48'),
(22010, 15, 55, 'view', '2026-04-09 19:36:48', '2026-04-12 19:36:48'),
(22009, 15, 54, 'view', '2026-04-10 19:36:48', '2026-04-07 19:36:48'),
(22008, 15, 2, 'like', '2026-04-08 19:36:48', '2026-04-07 19:36:48'),
(22007, 15, 2, 'view', '2026-04-12 19:36:48', '2026-04-09 19:36:48'),
(22006, 14, 1, 'like', '2026-04-08 19:36:48', '2026-04-09 19:36:48'),
(22005, 14, 1, 'view', '2026-04-12 19:36:48', '2026-04-13 19:36:48'),
(22004, 14, 57, 'view', '2026-04-09 19:36:48', '2026-04-07 19:36:48'),
(22003, 14, 56, 'view', '2026-04-12 19:36:48', '2026-04-10 19:36:48'),
(22002, 14, 55, 'view', '2026-04-11 19:36:48', '2026-04-08 19:36:48'),
(22001, 14, 54, 'like', '2026-04-11 19:36:48', '2026-04-10 19:36:48'),
(22000, 14, 54, 'view', '2026-04-09 19:36:48', '2026-04-13 19:36:48'),
(21999, 14, 2, 'like', '2026-04-10 19:36:48', '2026-04-10 19:36:48'),
(21998, 14, 2, 'view', '2026-04-13 19:36:48', '2026-04-11 19:36:48'),
(21997, 13, 1, 'view', '2026-04-12 19:36:48', '2026-04-11 19:36:48'),
(21996, 13, 57, 'view', '2026-04-10 19:36:48', '2026-04-13 19:36:48'),
(21995, 13, 56, 'like', '2026-04-12 19:36:48', '2026-04-11 19:36:48'),
(21994, 13, 56, 'view', '2026-04-11 19:36:48', '2026-04-13 19:36:48'),
(21993, 13, 55, 'view', '2026-04-12 19:36:48', '2026-04-12 19:36:48'),
(21992, 13, 54, 'view', '2026-04-12 19:36:48', '2026-04-11 19:36:48'),
(21991, 13, 2, 'like', '2026-04-09 19:36:48', '2026-04-08 19:36:48'),
(21990, 13, 2, 'view', '2026-04-11 19:36:48', '2026-04-13 19:36:48');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `cache`
--
ALTER TABLE `cache`
  ADD PRIMARY KEY (`key`),
  ADD KEY `cache_expiration_index` (`expiration`);

--
-- Indexes for table `cache_locks`
--
ALTER TABLE `cache_locks`
  ADD PRIMARY KEY (`key`),
  ADD KEY `cache_locks_expiration_index` (`expiration`);

--
-- Indexes for table `carts`
--
ALTER TABLE `carts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `carts_customer_id_unique` (`customer_id`),
  ADD KEY `carts_restaurant_id_foreign` (`restaurant_id`);

--
-- Indexes for table `cart_items`
--
ALTER TABLE `cart_items`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `cart_items_cart_id_menu_item_id_unique` (`cart_id`,`menu_item_id`),
  ADD KEY `cart_items_menu_item_id_foreign` (`menu_item_id`);

--
-- Indexes for table `conversations`
--
ALTER TABLE `conversations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `conversations_restaurant_id_updated_at_index` (`restaurant_id`,`updated_at`),
  ADD KEY `conversations_customer_id_updated_at_index` (`customer_id`,`updated_at`),
  ADD KEY `conversations_order_id_index` (`order_id`);

--
-- Indexes for table `conversation_messages`
--
ALTER TABLE `conversation_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `conversation_messages_conversation_id_created_at_index` (`conversation_id`,`created_at`),
  ADD KEY `conversation_messages_sender_id_index` (`sender_id`);

--
-- Indexes for table `delivery_tasks`
--
ALTER TABLE `delivery_tasks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `delivery_tasks_order_id_foreign` (`order_id`),
  ADD KEY `delivery_tasks_driver_id_foreign` (`driver_id`);

--
-- Indexes for table `drivers`
--
ALTER TABLE `drivers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `drivers_user_id_foreign` (`user_id`);

--
-- Indexes for table `driver_locations`
--
ALTER TABLE `driver_locations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `driver_locations_driver_id_foreign` (`driver_id`);

--
-- Indexes for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`);

--
-- Indexes for table `jobs`
--
ALTER TABLE `jobs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `jobs_queue_index` (`queue`);

--
-- Indexes for table `job_batches`
--
ALTER TABLE `job_batches`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `loyalty_members`
--
ALTER TABLE `loyalty_members`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `loyalty_members_restaurant_id_customer_id_unique` (`restaurant_id`,`customer_id`),
  ADD KEY `loyalty_members_restaurant_id_points_index` (`restaurant_id`,`points`);

--
-- Indexes for table `loyalty_redemptions`
--
ALTER TABLE `loyalty_redemptions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `loyalty_redemptions_restaurant_id_created_at_index` (`restaurant_id`,`created_at`),
  ADD KEY `loyalty_redemptions_loyalty_member_id_index` (`loyalty_member_id`),
  ADD KEY `loyalty_redemptions_loyalty_reward_id_index` (`loyalty_reward_id`);

--
-- Indexes for table `loyalty_rewards`
--
ALTER TABLE `loyalty_rewards`
  ADD PRIMARY KEY (`id`),
  ADD KEY `loyalty_rewards_restaurant_id_status_created_at_index` (`restaurant_id`,`status`,`created_at`);

--
-- Indexes for table `menu_categories`
--
ALTER TABLE `menu_categories`
  ADD PRIMARY KEY (`id`),
  ADD KEY `menu_categories_restaurant_id_foreign` (`restaurant_id`);

--
-- Indexes for table `menu_items`
--
ALTER TABLE `menu_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `menu_items_category_id_foreign` (`category_id`);

--
-- Indexes for table `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `notifications_user_id_read_at_created_at_index` (`user_id`,`read_at`,`created_at`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD KEY `orders_customer_id_foreign` (`customer_id`),
  ADD KEY `orders_restaurant_id_foreign` (`restaurant_id`),
  ADD KEY `orders_branch_id_foreign` (`branch_id`);

--
-- Indexes for table `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_items_order_id_foreign` (`order_id`),
  ADD KEY `order_items_menu_item_id_foreign` (`menu_item_id`);

--
-- Indexes for table `order_status_histories`
--
ALTER TABLE `order_status_histories`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_status_histories_order_id_foreign` (`order_id`),
  ADD KEY `order_status_histories_changed_by_foreign` (`changed_by`);

--
-- Indexes for table `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`email`);

--
-- Indexes for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  ADD KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`),
  ADD KEY `personal_access_tokens_expires_at_index` (`expires_at`);

--
-- Indexes for table `reports`
--
ALTER TABLE `reports`
  ADD PRIMARY KEY (`id`),
  ADD KEY `reports_reporter_user_id_created_at_index` (`reporter_user_id`,`created_at`),
  ADD KEY `reports_restaurant_id_created_at_index` (`restaurant_id`,`created_at`),
  ADD KEY `reports_status_created_at_index` (`status`,`created_at`),
  ADD KEY `reports_order_id_index` (`order_id`);

--
-- Indexes for table `restaurants`
--
ALTER TABLE `restaurants`
  ADD PRIMARY KEY (`id`),
  ADD KEY `restaurants_owner_user_id_foreign` (`owner_user_id`);

--
-- Indexes for table `restaurant_branches`
--
ALTER TABLE `restaurant_branches`
  ADD PRIMARY KEY (`id`),
  ADD KEY `restaurant_branches_restaurant_id_foreign` (`restaurant_id`);

--
-- Indexes for table `reviews`
--
ALTER TABLE `reviews`
  ADD PRIMARY KEY (`id`),
  ADD KEY `reviews_restaurant_id_rating_created_at_index` (`restaurant_id`,`rating`,`created_at`),
  ADD KEY `reviews_customer_id_index` (`customer_id`),
  ADD KEY `reviews_order_id_index` (`order_id`),
  ADD KEY `reviews_replied_by_index` (`replied_by`);

--
-- Indexes for table `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sessions_user_id_index` (`user_id`),
  ADD KEY `sessions_last_activity_index` (`last_activity`);

--
-- Indexes for table `support_requests`
--
ALTER TABLE `support_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `support_requests_user_id_created_at_index` (`user_id`,`created_at`),
  ADD KEY `support_requests_status_created_at_index` (`status`,`created_at`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_unique` (`email`),
  ADD UNIQUE KEY `users_phone_unique` (`phone`);

--
-- Indexes for table `videos`
--
ALTER TABLE `videos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `videos_restaurant_id_foreign` (`restaurant_id`),
  ADD KEY `videos_menu_item_id_foreign` (`menu_item_id`);

--
-- Indexes for table `video_engagements`
--
ALTER TABLE `video_engagements`
  ADD PRIMARY KEY (`id`),
  ADD KEY `video_engagements_video_id_foreign` (`video_id`),
  ADD KEY `video_engagements_user_id_foreign` (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `carts`
--
ALTER TABLE `carts`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `cart_items`
--
ALTER TABLE `cart_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `conversations`
--
ALTER TABLE `conversations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `conversation_messages`
--
ALTER TABLE `conversation_messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `delivery_tasks`
--
ALTER TABLE `delivery_tasks`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `drivers`
--
ALTER TABLE `drivers`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `driver_locations`
--
ALTER TABLE `driver_locations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobs`
--
ALTER TABLE `jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `loyalty_members`
--
ALTER TABLE `loyalty_members`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `loyalty_redemptions`
--
ALTER TABLE `loyalty_redemptions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `loyalty_rewards`
--
ALTER TABLE `loyalty_rewards`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `menu_categories`
--
ALTER TABLE `menu_categories`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT for table `menu_items`
--
ALTER TABLE `menu_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT for table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2195;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4439;

--
-- AUTO_INCREMENT for table `order_status_histories`
--
ALTER TABLE `order_status_histories`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=102;

--
-- AUTO_INCREMENT for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=223;

--
-- AUTO_INCREMENT for table `reports`
--
ALTER TABLE `reports`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `restaurants`
--
ALTER TABLE `restaurants`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `restaurant_branches`
--
ALTER TABLE `restaurant_branches`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `reviews`
--
ALTER TABLE `reviews`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `support_requests`
--
ALTER TABLE `support_requests`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=58;

--
-- AUTO_INCREMENT for table `videos`
--
ALTER TABLE `videos`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `video_engagements`
--
ALTER TABLE `video_engagements`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22015;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
