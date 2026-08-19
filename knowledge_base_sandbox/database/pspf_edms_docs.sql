-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Aug 19, 2026 at 09:45 PM
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
-- Database: `pspf_edms_docs`
--

-- --------------------------------------------------------

--
-- Table structure for table `api_keys`
--

CREATE TABLE `api_keys` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `label` varchar(100) NOT NULL DEFAULT 'Sandbox key',
  `key_prefix` char(8) NOT NULL COMMENT 'First 8 chars, shown in the UI so a key is identifiable without re-exposing it',
  `key_hash` char(64) NOT NULL COMMENT 'sha256 of the full key',
  `issued_by` int(10) UNSIGNED NOT NULL,
  `last_used_at` datetime DEFAULT NULL,
  `revoked_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `api_keys`
--

INSERT INTO `api_keys` (`id`, `user_id`, `label`, `key_prefix`, `key_hash`, `issued_by`, `last_used_at`, `revoked_at`, `created_at`) VALUES
(1, 2, 'Sandbox key', 'pdk_234c', '4d9bfaf2a5e5bedee8140e557daef4ad82604a6049be8ce07fc267eaf544b2c5', 1, '2026-08-18 07:34:55', NULL, '2026-08-16 23:06:19');

-- --------------------------------------------------------

--
-- Table structure for table `audit_log`
--

CREATE TABLE `audit_log` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `actor_user_id` int(10) UNSIGNED DEFAULT NULL,
  `action` varchar(60) NOT NULL,
  `record_type` varchar(60) DEFAULT NULL,
  `record_id` varchar(60) DEFAULT NULL,
  `detail` varchar(500) DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `audit_log`
--

INSERT INTO `audit_log` (`id`, `actor_user_id`, `action`, `record_type`, `record_id`, `detail`, `ip_address`, `created_at`) VALUES
(1, 1, 'Login', 'user', '1', NULL, '::1', '2026-08-16 23:03:13'),
(2, 1, 'Upload media', 'media_asset', '1', 'Advice on Testing and Demonstration (PSPF_RFP_03_2026).pdf', '::1', '2026-08-16 23:04:06'),
(3, 1, 'Delete media', 'media_asset', '1', NULL, '::1', '2026-08-16 23:04:29'),
(4, 2, 'Register', 'user', '2', NULL, '::1', '2026-08-16 23:05:56'),
(5, 1, 'Approve', 'user', '2', NULL, '::1', '2026-08-16 23:06:08'),
(6, 1, 'Issue API key', 'api_key', '1', 'For user 2', '::1', '2026-08-16 23:06:19'),
(7, 2, 'Login', 'user', '2', NULL, '::1', '2026-08-16 23:07:24'),
(8, 1, 'Suspend', 'user', '2', NULL, '::1', '2026-08-17 00:33:14'),
(9, 2, 'Login', 'user', '2', NULL, '::1', '2026-08-17 00:34:27'),
(10, 1, 'Create', 'sandbox_environment', '2', 'development -> http://localhost:4000/api/v1', '::1', '2026-08-17 00:50:09'),
(11, 2, 'Login', 'user', '2', NULL, '::1', '2026-08-17 22:29:39'),
(12, 2, 'Login', 'user', '2', NULL, '::1', '2026-08-17 22:29:41'),
(13, 2, 'Login', 'user', '2', NULL, '::1', '2026-08-17 22:29:43'),
(14, 2, 'Login', 'user', '2', NULL, '::1', '2026-08-17 22:29:46');

-- --------------------------------------------------------

--
-- Table structure for table `media_assets`
--

CREATE TABLE `media_assets` (
  `id` int(10) UNSIGNED NOT NULL,
  `original_name` varchar(255) NOT NULL,
  `stored_name` varchar(255) NOT NULL COMMENT 'UUID-based filename on disk, under backend/uploads/',
  `mime_type` varchar(120) NOT NULL,
  `kind` enum('image','video','document','other') NOT NULL,
  `size_bytes` bigint(20) UNSIGNED NOT NULL,
  `alt_text` varchar(255) DEFAULT NULL,
  `uploaded_by` int(10) UNSIGNED NOT NULL,
  `uploaded_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sandbox_environments`
--

CREATE TABLE `sandbox_environments` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL,
  `base_url` varchar(255) NOT NULL COMMENT 'e.g. http://localhost:4000/api — the ONLY thing that decides where a sandbox call actually goes; never taken from the client, so this can''t become an open proxy',
  `is_default` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sandbox_environments`
--

INSERT INTO `sandbox_environments` (`id`, `name`, `base_url`, `is_default`, `created_at`) VALUES
(1, 'Local (XAMPP)', 'http://localhost:4000/api', 1, '2026-08-16 22:57:59'),
(2, 'development', 'http://localhost:4000/api/v1', 0, '2026-08-17 00:50:09');

-- --------------------------------------------------------

--
-- Table structure for table `sandbox_folders`
--

CREATE TABLE `sandbox_folders` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(150) NOT NULL,
  `description` text DEFAULT NULL,
  `sort_order` int(10) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sandbox_folders`
--

INSERT INTO `sandbox_folders` (`id`, `name`, `description`, `sort_order`) VALUES
(1, 'Auth', 'Registration, password login, refresh/logout, Google & Microsoft sign-in, password reset.', 0),
(2, 'MFA', 'Run order depends on the Login response\'s `mfaEnrollmentRequired` flag (auto-saved as a collection variable by Login\'s Test script — check the Postman Console after calling Login to see it logged):\n\n• mfaEnrollmentRequired = true  → \'Enroll TOTP (login) — Start\' then \'— Confirm\'\n• mfaEnrollmentRequired = false → \'Verify TOTP (login)\', or Send SMS/Email Challenge then Verify SMS/Email OTP, or Verify Backup Code\n\n\'TOTP is not enrolled for this account\' from Verify TOTP means you skipped enrolment — this account has never confirmed an authenticator. SMS/Email challenges need the backend\'s SMTP/Twilio configured and reachable; TOTP enroll/verify need no external network call at all, which is the one to use if you\'re working offline.', 1),
(3, 'Users & Groups', 'Administration of accounts and groups (System Administrator / Records Manager).', 2),
(4, 'Folders', 'Folder tree (e.g. Pension Claims / 2026 / Retirement).', 3),
(5, 'Documents', 'Repository: register, search, view metadata, read decrypted content, declare final.', 4),
(6, 'Versions', 'Version history, new-version upload (also encrypted), and restore (writes a new current version).', 5),
(7, 'Permissions', 'Folder/document ACLs (inheritable) and the role x module permission matrix.', 6),
(8, 'Approvals', 'Awaiting-my-approval inbox and decisions that advance the workflow instance.', 7),
(9, 'Workflow', 'Workflow Designer: named workflows with ordered role-based steps + SLA.', 8),
(10, 'Audit', 'Audit trail viewing, CSV export, and tamper-evidence hash-chain verification.', 9),
(11, 'Retention', 'Retention schedules and the disposal queue.', 10),
(12, 'Notifications', NULL, 11),
(13, 'Integrations & Capture', 'Active Directory / HRIS / SMTP / SMS / cloud storage status, and scan/intake batch stats.', 12),
(14, 'Reports', NULL, 13),
(15, 'Health', NULL, 14);

-- --------------------------------------------------------

--
-- Table structure for table `sandbox_requests`
--

CREATE TABLE `sandbox_requests` (
  `id` int(10) UNSIGNED NOT NULL,
  `folder_id` int(10) UNSIGNED NOT NULL,
  `name` varchar(150) NOT NULL,
  `method` enum('GET','POST','PUT','PATCH','DELETE') NOT NULL,
  `path` varchar(255) NOT NULL COMMENT 'Relative to the chosen environment''s base_url, e.g. /auth/login',
  `description` text DEFAULT NULL,
  `auth_type` enum('none','bearer','mfa_token') NOT NULL DEFAULT 'none',
  `default_headers_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`default_headers_json`)),
  `default_query_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`default_query_json`)),
  `default_body_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`default_body_json`)),
  `has_file_upload` tinyint(1) NOT NULL DEFAULT 0,
  `doc_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Structured API reference: { summary, parameters:[{name,in,type,required,description}], requestBody:{fields:[{name,type,required,description}]}, responses:[{status,description,example}] }' CHECK (json_valid(`doc_json`)),
  `sort_order` int(10) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sandbox_requests`
--

INSERT INTO `sandbox_requests` (`id`, `folder_id`, `name`, `method`, `path`, `description`, `auth_type`, `default_headers_json`, `default_query_json`, `default_body_json`, `has_file_upload`, `doc_json`, `sort_order`) VALUES
(1, 1, 'Register', 'POST', '/auth/register', 'Creates an account directly. In production this is normally disabled/admin-only — kept for a working dev flow.', 'none', '{}', '{}', '{\"fullName\":\"Test Officer\",\"email\":\"test.officer@pspf.co.sz\",\"password\":\"ChangeMe123!Strong\",\"roleId\":1,\"departmentId\":1,\"phoneNumber\":\"+26876000000\"}', 0, '{\"summary\":\"Create a password-based account.\",\"parameters\":[],\"requestBody\":{\"fields\":[{\"name\":\"fullName\",\"type\":\"string\",\"required\":true,\"description\":\"Full display name.\"},{\"name\":\"email\",\"type\":\"string\",\"required\":true,\"description\":\"Must be unique across all accounts.\"},{\"name\":\"password\",\"type\":\"string\",\"required\":true,\"description\":\"Minimum 10 characters.\"},{\"name\":\"roleId\",\"type\":\"integer\",\"required\":true,\"description\":\"FK to roles.id — see the roles seeded in the EDMS schema (Records Officer, Approving Manager, etc.).\"},{\"name\":\"departmentId\",\"type\":\"integer\",\"required\":false,\"description\":\"FK to departments.id.\"},{\"name\":\"phoneNumber\",\"type\":\"string\",\"required\":false,\"description\":\"E.164 format, e.g. +26876000000. Needed later for SMS MFA.\"}]},\"responses\":[{\"status\":201,\"description\":\"Account created.\",\"example\":{\"success\":true,\"message\":\"Account created\",\"data\":{\"userId\":7}}},{\"status\":409,\"description\":\"Email already registered.\",\"example\":{\"success\":false,\"message\":\"An account with this email already exists\",\"errors\":null}},{\"status\":422,\"description\":\"Request body failed validation.\",\"example\":{\"success\":false,\"message\":\"Validation failed\",\"errors\":[{\"type\":\"field\",\"msg\":\"Invalid value\",\"path\":\"email\",\"location\":\"body\"}]}}]}', 0),
(2, 1, 'Login', 'POST', '/auth/login', 'Use a seeded account (see database/pspf_edms_seed_test_data.sql) or one you registered. If the role requires MFA, response contains mfaRequired, mfaEnrollmentRequired, availableMethods, and mfaToken — check the Postman Console (View > Show Postman Console) after sending this for a printed instruction on exactly which MFA request to run next.', 'none', '{}', '{}', '{\"email\":\"admin@pspf.co.sz\",\"password\":\"ChangeMe123!\"}', 0, '{\"summary\":\"Password sign-in. Returns tokens directly, or an MFA challenge if the role requires a second factor.\",\"parameters\":[],\"requestBody\":{\"fields\":[{\"name\":\"email\",\"type\":\"string\",\"required\":true,\"description\":\"\"},{\"name\":\"password\",\"type\":\"string\",\"required\":true,\"description\":\"\"}]},\"responses\":[{\"status\":200,\"description\":\"Signed in — no MFA required for this account.\",\"example\":{\"success\":true,\"message\":\"Logged in\",\"data\":{\"accessToken\":\"<jwt>\",\"refreshToken\":\"<jwt>\",\"user\":{\"id\":3,\"fullName\":\"Thabo Simelane\",\"email\":\"records.officer@pspf.co.sz\",\"role\":\"Records Officer\"}}}},{\"status\":200,\"description\":\"MFA required — continue with the MFA folder, not this response\'s tokens (there are none yet).\",\"example\":{\"success\":true,\"message\":\"MFA verification required\",\"data\":{\"mfaRequired\":true,\"mfaEnrollmentRequired\":false,\"availableMethods\":[\"totp\",\"email\"],\"mfaToken\":\"<short-lived jwt>\"}}},{\"status\":401,\"description\":\"Wrong email or password.\",\"example\":{\"success\":false,\"message\":\"Invalid email or password\",\"errors\":null}},{\"status\":423,\"description\":\"Account is locked.\",\"example\":{\"success\":false,\"message\":\"Account is locked — contact your System Administrator\",\"errors\":null}}]}', 1),
(3, 1, 'Refresh Token', 'POST', '/auth/refresh', NULL, 'none', '{}', '{}', '{\"refreshToken\":\"{{refreshToken}}\"}', 0, '{\"summary\":\"Exchange a refresh token for a new access token.\",\"parameters\":[],\"requestBody\":{\"fields\":[{\"name\":\"refreshToken\",\"type\":\"string\",\"required\":true,\"description\":\"From a prior login/MFA response.\"}]},\"responses\":[{\"status\":200,\"description\":\"New access token issued.\",\"example\":{\"success\":true,\"message\":\"Token refreshed\",\"data\":{\"accessToken\":\"<jwt>\"}}},{\"status\":401,\"description\":\"Refresh token invalid, expired, or the session was revoked (e.g. by logout).\",\"example\":{\"success\":false,\"message\":\"Session not found or revoked\",\"errors\":null}}]}', 2),
(4, 1, 'Get Current User (me)', 'GET', '/auth/me', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"The currently signed-in user\'s profile.\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":{\"id\":3,\"fullName\":\"Thabo Simelane\",\"email\":\"records.officer@pspf.co.sz\",\"role\":\"Records Officer\",\"roleId\":1,\"mfaSatisfied\":false}}},{\"status\":401,\"description\":\"Missing, invalid, or expired token.\",\"example\":{\"success\":false,\"message\":\"Invalid or expired token\",\"errors\":null}}]}', 3),
(5, 1, 'Logout', 'POST', '/auth/logout', NULL, 'none', '{}', '{}', '{\"refreshToken\":\"{{refreshToken}}\"}', 0, '{\"summary\":\"Revoke the refresh session tied to the given refresh token.\",\"parameters\":[],\"requestBody\":{\"fields\":[{\"name\":\"refreshToken\",\"type\":\"string\",\"required\":false,\"description\":\"If omitted, nothing is revoked but the call still succeeds — clear tokens client-side regardless.\"}]},\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Logged out\",\"data\":null}}]}', 4),
(6, 1, 'Google Sign-In', 'POST', '/auth/google', 'idToken must come from Google Identity Services on the frontend — a hand-typed value will fail verification.', 'none', '{}', '{}', '{\"idToken\":\"<google-id-token-from-frontend-sdk>\"}', 0, '{\"summary\":\"Sign in with a Google-issued ID token. The account must already exist (created by an admin) and be matched by email on first use — this endpoint never auto-creates an account.\",\"parameters\":[],\"requestBody\":{\"fields\":[{\"name\":\"idToken\",\"type\":\"string\",\"required\":true,\"description\":\"A real ID token from Google Identity Services on a frontend — cannot be hand-typed or faked; the backend verifies it against Google.\"}]},\"responses\":[{\"status\":200,\"description\":\"Same shape as POST /auth/login (tokens, or an MFA challenge).\",\"example\":{\"success\":true,\"message\":\"Logged in\",\"data\":{\"accessToken\":\"<jwt>\",\"refreshToken\":\"<jwt>\",\"user\":{\"id\":3,\"fullName\":\"Thabo Simelane\",\"email\":\"records.officer@pspf.co.sz\",\"role\":\"Records Officer\"}}}},{\"status\":403,\"description\":\"No EDMS account exists for this Google identity yet.\",\"example\":{\"success\":false,\"message\":\"No PSPF EDMS account exists for this identity. Ask a System Administrator to provision one.\",\"errors\":null}},{\"status\":401,\"description\":\"Google could not verify the token, or its email is unverified.\",\"example\":{\"success\":false,\"message\":\"Email on the identity provider is not verified\",\"errors\":null}}]}', 5),
(7, 1, 'Microsoft Sign-In', 'POST', '/auth/microsoft', 'idToken must come from MSAL.js / Microsoft Entra ID on the frontend.', 'none', '{}', '{}', '{\"idToken\":\"<microsoft-id-token-from-msal-js>\"}', 0, '{\"summary\":\"Sign in with a Microsoft/Entra ID-issued ID token. Same account-provisioning rule as Google Sign-In.\",\"parameters\":[],\"requestBody\":{\"fields\":[{\"name\":\"idToken\",\"type\":\"string\",\"required\":true,\"description\":\"A real ID token from MSAL.js on a frontend.\"}]},\"responses\":[{\"status\":200,\"description\":\"Same shape as POST /auth/login.\",\"example\":{\"success\":true,\"message\":\"Logged in\",\"data\":{\"accessToken\":\"<jwt>\",\"refreshToken\":\"<jwt>\",\"user\":{\"id\":3,\"fullName\":\"Thabo Simelane\",\"email\":\"records.officer@pspf.co.sz\",\"role\":\"Records Officer\"}}}},{\"status\":403,\"description\":\"No EDMS account exists for this Microsoft identity yet.\",\"example\":{\"success\":false,\"message\":\"No PSPF EDMS account exists for this identity. Ask a System Administrator to provision one.\",\"errors\":null}}]}', 6),
(8, 1, 'Active Directory Sign-In', 'POST', '/auth/active-directory', 'Intentionally returns 501 until a real LDAPS bind (services/ad.service.js) is implemented server-side — matches the prototype\'s Active Directory / Kerberos reference. This confirms the route and request shape are correct; it will not complete a sign-in yet.', 'none', '{}', '{}', '{\"username\":\"PSPF\\\\\\\\s.nkambo\",\"password\":\"<domain-password>\"}', 0, '{\"summary\":\"On-prem SSO via LDAPS bind. Currently a documented stub — see the response below.\",\"parameters\":[],\"requestBody\":{\"fields\":[{\"name\":\"username\",\"type\":\"string\",\"required\":true,\"description\":\"Domain\\\\username, e.g. PSPF\\\\s.nkambo.\"},{\"name\":\"password\",\"type\":\"string\",\"required\":true,\"description\":\"\"}]},\"responses\":[{\"status\":501,\"description\":\"Not implemented on this server — this is the real, current response, not a placeholder you need to work around.\",\"example\":{\"success\":false,\"message\":\"Active Directory sign-in is not configured on this server. Implement services/ad.service.js (LDAPS bind) and wire it in here.\",\"errors\":null}}]}', 7),
(9, 1, 'Request Password Reset', 'POST', '/auth/password-reset/request', NULL, 'none', '{}', '{}', '{\"email\":\"admin@pspf.co.sz\"}', 0, '{\"summary\":\"Request a password reset email. Always returns 200 regardless of whether the email exists, to avoid leaking which accounts are registered.\",\"parameters\":[],\"requestBody\":{\"fields\":[{\"name\":\"email\",\"type\":\"string\",\"required\":true,\"description\":\"\"}]},\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"If that account exists, a reset link has been sent\",\"data\":null}}]}', 8),
(10, 1, 'Confirm Password Reset', 'POST', '/auth/password-reset/confirm', NULL, 'none', '{}', '{}', '{\"token\":\"<token-from-email-link>\",\"newPassword\":\"AnotherStrongPass123!\"}', 0, '{\"summary\":\"Complete a password reset using the token from the emailed link.\",\"parameters\":[],\"requestBody\":{\"fields\":[{\"name\":\"token\",\"type\":\"string\",\"required\":true,\"description\":\"From the reset email link, valid 30 minutes.\"},{\"name\":\"newPassword\",\"type\":\"string\",\"required\":true,\"description\":\"Minimum 10 characters.\"}]},\"responses\":[{\"status\":200,\"description\":\"Password changed — all existing sessions for this account are revoked.\",\"example\":{\"success\":true,\"message\":\"Password updated — please sign in again\",\"data\":null}},{\"status\":400,\"description\":\"Token invalid, expired, or already used.\",\"example\":{\"success\":false,\"message\":\"Reset link is invalid or expired\",\"errors\":null}}]}', 9),
(11, 2, 'Enroll TOTP (login) — Start', 'POST', '/mfa/enroll/totp/start', 'FIRST STEP for an account with no authenticator enrolled yet (login response had mfaEnrollmentRequired: true). Uses the interim mfaToken from Login — not a full accessToken, because the account can\'t get one until MFA is satisfied. Returns { qrDataUrl, base32Secret }. Scan qrDataUrl (base64 PNG) in any TOTP app (Google Authenticator, Authy, 1Password, etc.), or type base32Secret in manually.', 'none', '{}', '{}', 'null', 0, '{\"summary\":\"First-time TOTP enrolment, step 1 of 2 — generates a secret and returns a QR code to scan. Uses the interim mfaToken from Login, not a full accessToken (the account can\'t have one yet).\",\"parameters\":[{\"name\":\"Authorization\",\"in\":\"header\",\"type\":\"string\",\"required\":true,\"description\":\"Bearer {{mfaToken}} — from a Login response with mfaRequired: true.\"}],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Scan the QR code in your authenticator app, then confirm with the 6-digit code\",\"data\":{\"qrDataUrl\":\"data:image/png;base64,iVBORw0KG...\",\"base32Secret\":\"JBSWY3DPEHPK3PXP\"}}},{\"status\":401,\"description\":\"Missing, invalid, or expired token.\",\"example\":{\"success\":false,\"message\":\"Invalid or expired token\",\"errors\":null}}]}', 0),
(12, 2, 'Enroll TOTP (login) — Confirm', 'POST', '/mfa/enroll/totp/confirm', 'SECOND STEP: enter the current 6-digit code your authenticator app is showing for the secret from \'Enroll TOTP (login) — Start\'. On success this ALSO completes sign-in (returns accessToken/refreshToken), same as Verify TOTP does — no separate verify call needed.', 'none', '{}', '{}', '{\"token\":\"123456\"}', 0, '{\"summary\":\"First-time TOTP enrolment, step 2 of 2 — confirms the 6-digit code and, on success, completes sign-in (returns full tokens).\",\"parameters\":[{\"name\":\"Authorization\",\"in\":\"header\",\"type\":\"string\",\"required\":true,\"description\":\"Bearer {{mfaToken}}\"}],\"requestBody\":{\"fields\":[{\"name\":\"token\",\"type\":\"string\",\"required\":true,\"description\":\"Current 6-digit code from the authenticator app.\"}]},\"responses\":[{\"status\":200,\"description\":\"Enrolled and signed in.\",\"example\":{\"success\":true,\"message\":\"Logged in\",\"data\":{\"accessToken\":\"<jwt>\",\"refreshToken\":\"<jwt>\",\"user\":{\"id\":1,\"fullName\":\"Sipho Nkambo\",\"email\":\"admin@pspf.co.sz\",\"role\":\"System Administrator\"}}}},{\"status\":400,\"description\":\"Wrong code, or Start was never called.\",\"example\":{\"success\":false,\"message\":\"Incorrect code\",\"errors\":null}}]}', 1),
(13, 2, 'Enroll TOTP (already signed in)', 'POST', '/mfa/totp/enroll', 'For a user who is ALREADY fully signed in and wants to add/replace an authenticator (e.g. new phone). Different from the pair above: this needs a real accessToken, which only exists after MFA is already satisfied once.', 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Add/replace an authenticator for an account that\'s ALREADY signed in (e.g. a new phone). Different from the pair above: needs a full accessToken.\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Scan the QR code, then confirm with /api/mfa/totp/confirm\",\"data\":{\"qrDataUrl\":\"data:image/png;base64,...\",\"base32Secret\":\"JBSWY3DPEHPK3PXP\"}}},{\"status\":401,\"description\":\"Missing, invalid, or expired token.\",\"example\":{\"success\":false,\"message\":\"Invalid or expired token\",\"errors\":null}}]}', 2),
(14, 2, 'Confirm TOTP (already signed in)', 'POST', '/mfa/totp/confirm', NULL, 'bearer', '{}', '{}', '{\"token\":\"123456\"}', 0, '{\"summary\":\"Confirms the authenticated re-enrolment started by POST /mfa/totp/enroll.\",\"parameters\":[],\"requestBody\":{\"fields\":[{\"name\":\"token\",\"type\":\"string\",\"required\":true,\"description\":\"\"}]},\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Authenticator app confirmed\",\"data\":null}},{\"status\":400,\"description\":\"Wrong code.\",\"example\":{\"success\":false,\"message\":\"Incorrect code\",\"errors\":null}}]}', 3),
(15, 2, 'Generate Backup Codes', 'POST', '/mfa/backup-codes/generate', 'Requires a full accessToken (already signed in) — backup codes are a recovery mechanism generated from within Security & Access, not something you can create before your first successful sign-in.', 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Generates 8 one-time backup codes, replacing any existing set. Plaintext codes are returned exactly once.\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Store these codes securely — they will not be shown again\",\"data\":{\"codes\":[\"a1b2c3d4e5\",\"f6a7b8c9d0\",\"...6 more\"]}}},{\"status\":401,\"description\":\"Missing, invalid, or expired token.\",\"example\":{\"success\":false,\"message\":\"Invalid or expired token\",\"errors\":null}}]}', 4),
(16, 2, 'Send SMS Challenge', 'POST', '/mfa/challenge/sms/send', 'Only works if the backend\'s SMS_PROVIDER/Twilio credentials are configured and reachable. If you\'re offline or those aren\'t set up, use the TOTP enroll/verify requests instead — they need no external network call at all.', 'none', '{}', '{}', 'null', 0, '{\"summary\":\"Sends a 6-digit OTP by SMS to the phone number on file. Requires the backend\'s Twilio credentials configured and reachable.\",\"parameters\":[{\"name\":\"Authorization\",\"in\":\"header\",\"type\":\"string\",\"required\":true,\"description\":\"Bearer {{mfaToken}}\"}],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Code sent by SMS\",\"data\":null}},{\"status\":400,\"description\":\"No phone number on file for this account.\",\"example\":{\"success\":false,\"message\":\"No phone number on file for SMS MFA\",\"errors\":null}}]}', 5),
(17, 2, 'Send Email Challenge', 'POST', '/mfa/challenge/email/send', 'Only works if the backend\'s SMTP credentials are configured and reachable. Same offline caveat as Send SMS Challenge.', 'none', '{}', '{}', 'null', 0, '{\"summary\":\"Sends a 6-digit OTP by email. Requires the backend\'s SMTP configured and reachable.\",\"parameters\":[{\"name\":\"Authorization\",\"in\":\"header\",\"type\":\"string\",\"required\":true,\"description\":\"Bearer {{mfaToken}}\"}],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Code sent by email\",\"data\":null}}]}', 6),
(18, 2, 'Verify TOTP (login)', 'POST', '/mfa/verify/totp', 'Only call this if mfaEnrollmentRequired was FALSE at login (an authenticator is already enrolled and verified). If you get \'TOTP is not enrolled for this account\', that means mfaEnrollmentRequired was actually true — go run \'Enroll TOTP (login) — Start\' and \'— Confirm\' instead, this account has never completed enrolment.', 'none', '{}', '{}', '{\"token\":\"123456\"}', 0, '{\"summary\":\"Verifies a TOTP code from an ALREADY-enrolled authenticator and completes sign-in. If nothing is enrolled yet, use the Enroll TOTP (login) pair instead — this endpoint cannot enrol one.\",\"parameters\":[{\"name\":\"Authorization\",\"in\":\"header\",\"type\":\"string\",\"required\":true,\"description\":\"Bearer {{mfaToken}}\"}],\"requestBody\":{\"fields\":[{\"name\":\"token\",\"type\":\"string\",\"required\":true,\"description\":\"\"}]},\"responses\":[{\"status\":200,\"description\":\"Signed in.\",\"example\":{\"success\":true,\"message\":\"Logged in\",\"data\":{\"accessToken\":\"<jwt>\",\"refreshToken\":\"<jwt>\",\"user\":{\"id\":1,\"fullName\":\"Sipho Nkambo\",\"email\":\"admin@pspf.co.sz\",\"role\":\"System Administrator\"}}}},{\"status\":400,\"description\":\"No verified TOTP method exists for this account yet — enrol first.\",\"example\":{\"success\":false,\"message\":\"TOTP is not enrolled for this account\",\"errors\":null}}]}', 7),
(19, 2, 'Verify SMS/Email OTP (login)', 'POST', '/mfa/verify/otp', NULL, 'none', '{}', '{}', '{\"code\":\"123456\"}', 0, '{\"summary\":\"Verifies an SMS or email OTP (same endpoint for both — the code lookup doesn\'t care which channel it was sent on) and completes sign-in.\",\"parameters\":[{\"name\":\"Authorization\",\"in\":\"header\",\"type\":\"string\",\"required\":true,\"description\":\"Bearer {{mfaToken}}\"}],\"requestBody\":{\"fields\":[{\"name\":\"code\",\"type\":\"string\",\"required\":true,\"description\":\"6-digit code from SMS or email.\"}]},\"responses\":[{\"status\":200,\"description\":\"Signed in.\",\"example\":{\"success\":true,\"message\":\"Logged in\",\"data\":{\"accessToken\":\"<jwt>\",\"refreshToken\":\"<jwt>\",\"user\":{\"id\":1,\"fullName\":\"Sipho Nkambo\",\"email\":\"admin@pspf.co.sz\",\"role\":\"System Administrator\"}}}},{\"status\":400,\"description\":\"Wrong code, or it expired (5 minute window).\",\"example\":{\"success\":false,\"message\":\"Code is incorrect or has expired\",\"errors\":null}}]}', 8),
(20, 2, 'Verify Backup Code (login)', 'POST', '/mfa/verify/backup-code', NULL, 'none', '{}', '{}', '{\"code\":\"ab12cd34ef\"}', 0, '{\"summary\":\"Verifies a one-time backup code and completes sign-in. The code is consumed and can\'t be reused.\",\"parameters\":[{\"name\":\"Authorization\",\"in\":\"header\",\"type\":\"string\",\"required\":true,\"description\":\"Bearer {{mfaToken}}\"}],\"requestBody\":{\"fields\":[{\"name\":\"code\",\"type\":\"string\",\"required\":true,\"description\":\"\"}]},\"responses\":[{\"status\":200,\"description\":\"Signed in.\",\"example\":{\"success\":true,\"message\":\"Logged in\",\"data\":{\"accessToken\":\"<jwt>\",\"refreshToken\":\"<jwt>\",\"user\":{\"id\":1,\"fullName\":\"Sipho Nkambo\",\"email\":\"admin@pspf.co.sz\",\"role\":\"System Administrator\"}}}},{\"status\":400,\"description\":\"Code invalid or already used.\",\"example\":{\"success\":false,\"message\":\"Backup code is invalid or already used\",\"errors\":null}}]}', 9),
(21, 3, 'List Users', 'GET', '/users', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"List all users — System Administrator / Records Manager only.\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":[{\"id\":3,\"full_name\":\"Thabo Simelane\",\"email\":\"records.officer@pspf.co.sz\",\"role_name\":\"Records Officer\",\"department_name\":\"Benefits\",\"is_active\":1,\"is_locked\":0,\"mfa_enabled\":0}]}},{\"status\":403,\"description\":\"Signed in, but the account\'s role does not permit this action.\",\"example\":{\"success\":false,\"message\":\"You do not have permission to perform this action\",\"errors\":null}}]}', 0),
(22, 3, 'Change User Role', 'PUT', '/users/{{userId}}/role', NULL, 'bearer', '{}', '{}', '{\"roleId\":2}', 0, '{\"summary\":\"Change a user\'s role — System Administrator only.\",\"parameters\":[{\"name\":\"userId\",\"in\":\"path\",\"type\":\"integer\",\"required\":true,\"description\":\"\"}],\"requestBody\":{\"fields\":[{\"name\":\"roleId\",\"type\":\"integer\",\"required\":true,\"description\":\"FK to roles.id.\"}]},\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Role updated\",\"data\":null}},{\"status\":403,\"description\":\"Signed in, but the account\'s role does not permit this action.\",\"example\":{\"success\":false,\"message\":\"You do not have permission to perform this action\",\"errors\":null}}]}', 1),
(23, 3, 'Lock / Unlock User', 'PUT', '/users/{{userId}}/lock', NULL, 'bearer', '{}', '{}', '{\"locked\":true}', 0, '{\"summary\":\"Lock or unlock a user\'s account — System Administrator only.\",\"parameters\":[{\"name\":\"userId\",\"in\":\"path\",\"type\":\"integer\",\"required\":true,\"description\":\"\"}],\"requestBody\":{\"fields\":[{\"name\":\"locked\",\"type\":\"boolean\",\"required\":true,\"description\":\"\"}]},\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Account updated\",\"data\":null}}]}', 2),
(24, 3, 'List Groups', 'GET', '/users/groups/all', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"List groups with their members.\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":[{\"id\":1,\"name\":\"Benefits Team\",\"description\":\"All Benefits department staff\",\"members\":[{\"id\":3,\"full_name\":\"Thabo Simelane\"}]}]}}]}', 3),
(25, 3, 'Add Group Member', 'POST', '/users/groups/{{groupId}}/members', NULL, 'bearer', '{}', '{}', '{\"userId\":\"{{userId}}\"}', 0, '{\"summary\":\"Add a user to a group.\",\"parameters\":[{\"name\":\"groupId\",\"in\":\"path\",\"type\":\"integer\",\"required\":true,\"description\":\"\"}],\"requestBody\":{\"fields\":[{\"name\":\"userId\",\"type\":\"integer\",\"required\":true,\"description\":\"\"}]},\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Member added\",\"data\":null}}]}', 4),
(26, 3, 'Update My Profile', 'PUT', '/users/me', NULL, 'bearer', '{}', '{}', '{\"fullName\":\"Updated Name\",\"phoneNumber\":\"+26876000001\"}', 0, '{\"summary\":\"Self-service profile update (name, phone) for the signed-in user.\",\"parameters\":[],\"requestBody\":{\"fields\":[{\"name\":\"fullName\",\"type\":\"string\",\"required\":false,\"description\":\"\"},{\"name\":\"phoneNumber\",\"type\":\"string\",\"required\":false,\"description\":\"\"}]},\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Profile updated\",\"data\":null}}]}', 5),
(27, 3, 'Change My Password', 'PUT', '/users/me/password', NULL, 'bearer', '{}', '{}', '{\"currentPassword\":\"ChangeMe123!\",\"newPassword\":\"EvenStrongerPass456!\"}', 0, '{\"summary\":\"Self-service password change — requires the current password.\",\"parameters\":[],\"requestBody\":{\"fields\":[{\"name\":\"currentPassword\",\"type\":\"string\",\"required\":true,\"description\":\"\"},{\"name\":\"newPassword\",\"type\":\"string\",\"required\":true,\"description\":\"Minimum 10 characters.\"}]},\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Password changed\",\"data\":null}},{\"status\":401,\"description\":\"currentPassword is wrong.\",\"example\":{\"success\":false,\"message\":\"Current password is incorrect\",\"errors\":null}}]}', 6),
(28, 4, 'List Folders', 'GET', '/folders', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Flat list of every folder — the client builds the tree from parent_id.\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":[{\"id\":1,\"parent_id\":null,\"name\":\"Pension Claims\",\"path\":\"Pension Claims\",\"retention_class_name\":\"Pension claim records\"}]}}]}', 0),
(29, 4, 'Create Folder', 'POST', '/folders', NULL, 'bearer', '{}', '{}', '{\"name\":\"Retirement\",\"parentId\":null,\"departmentId\":\"{{departmentId}}\",\"retentionClassId\":\"{{retentionClassId}}\"}', 0, '{\"summary\":\"Create a folder, optionally nested under a parent.\",\"parameters\":[],\"requestBody\":{\"fields\":[{\"name\":\"name\",\"type\":\"string\",\"required\":true,\"description\":\"\"},{\"name\":\"parentId\",\"type\":\"integer\",\"required\":false,\"description\":\"Omit or null for a top-level folder.\"},{\"name\":\"departmentId\",\"type\":\"integer\",\"required\":false,\"description\":\"\"},{\"name\":\"retentionClassId\",\"type\":\"integer\",\"required\":false,\"description\":\"Inherited by every document placed in this folder unless overridden.\"}]},\"responses\":[{\"status\":201,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Folder created\",\"data\":{\"id\":5,\"path\":\"Pension Claims / 2026 / Retirement\"}}}]}', 1),
(30, 5, 'List / Search Documents', 'GET', '/documents', NULL, 'bearer', '{}', '{\"q\":\"\"}', 'null', 0, '{\"summary\":\"Search/list records. Full-text on title plus exact/partial match on record number and member number.\",\"parameters\":[{\"name\":\"q\",\"in\":\"query\",\"type\":\"string\",\"required\":false,\"description\":\"Free text — title, record number, or member number.\"},{\"name\":\"folderId\",\"in\":\"query\",\"type\":\"integer\",\"required\":false,\"description\":\"\"},{\"name\":\"departmentId\",\"in\":\"query\",\"type\":\"integer\",\"required\":false,\"description\":\"\"},{\"name\":\"status\",\"in\":\"query\",\"type\":\"string\",\"required\":false,\"description\":\"draft | pending_approval | approved | rejected | declared_final | archived | disposed\"},{\"name\":\"documentTypeId\",\"in\":\"query\",\"type\":\"integer\",\"required\":false,\"description\":\"\"}],\"responses\":[{\"status\":200,\"description\":\"Up to 200 results, newest first.\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":[{\"id\":1,\"record_no\":\"PC-2026-0433\",\"title\":\"Application for Retirement Benefit — DLAMINI T.M.\",\"status\":\"draft\",\"document_type\":\"Claim — Retirement\",\"department\":\"Benefits\",\"folder_path\":\"Pension Claims\",\"current_version_no\":1,\"owner_name\":\"Thabo Simelane\"}]}}]}', 0),
(31, 5, 'Get Document by ID', 'GET', '/documents/{{documentId}}', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Full metadata for one record (not its file content — see Get Decrypted Content for that).\",\"parameters\":[{\"name\":\"documentId\",\"in\":\"path\",\"type\":\"integer\",\"required\":true,\"description\":\"\"}],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":{\"id\":1,\"record_no\":\"PC-2026-0433\",\"title\":\"Application for Retirement Benefit\",\"status\":\"draft\",\"classification\":\"restricted\",\"document_type\":\"Claim — Retirement\",\"folder_path\":\"Pension Claims\",\"owner_name\":\"Thabo Simelane\"}}},{\"status\":404,\"description\":\"Record not found.\",\"example\":{\"success\":false,\"message\":\"Record not found\",\"errors\":null}}]}', 1),
(32, 5, 'Register Document (upload + encrypt)', 'POST', '/documents', 'In the \'file\' field\'s Value column, click \'Select Files\' and choose any PDF/image to upload — Postman cannot pre-fill a file path. The file is encrypted server-side (AES-256-GCM) before it is written to the active cloud storage provider.', 'bearer', '{}', '{}', '{\"recordNo\":\"{{recordNo}}\",\"title\":\"Application for Retirement Benefit — DLAMINI T.M.\",\"documentTypeId\":\"{{documentTypeId}}\",\"folderId\":\"{{folderId}}\",\"departmentId\":\"{{departmentId}}\",\"memberNumber\":\"41-882-6117\",\"memberName\":\"DLAMINI, Themba Musa\",\"classification\":\"restricted\",\"retentionClassId\":\"{{retentionClassId}}\"}', 1, '{\"summary\":\"Register a new record: encrypts the uploaded file (AES-256-GCM, fresh key per version) and uploads it to the active cloud storage provider before writing any database rows.\",\"parameters\":[],\"requestBody\":{\"fields\":[{\"name\":\"file\",\"type\":\"file\",\"required\":true,\"description\":\"multipart/form-data field.\"},{\"name\":\"recordNo\",\"type\":\"string\",\"required\":true,\"description\":\"Must be unique, e.g. PC-2026-0433.\"},{\"name\":\"title\",\"type\":\"string\",\"required\":true,\"description\":\"\"},{\"name\":\"documentTypeId\",\"type\":\"integer\",\"required\":true,\"description\":\"\"},{\"name\":\"folderId\",\"type\":\"integer\",\"required\":true,\"description\":\"\"},{\"name\":\"departmentId\",\"type\":\"integer\",\"required\":false,\"description\":\"\"},{\"name\":\"memberNumber\",\"type\":\"string\",\"required\":false,\"description\":\"\"},{\"name\":\"memberName\",\"type\":\"string\",\"required\":false,\"description\":\"\"},{\"name\":\"classification\",\"type\":\"string\",\"required\":false,\"description\":\"public | internal | restricted | confidential — defaults to internal.\"},{\"name\":\"retentionClassId\",\"type\":\"integer\",\"required\":false,\"description\":\"Overrides the folder\'s retention class for this record specifically.\"}]},\"responses\":[{\"status\":201,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Record registered\",\"data\":{\"id\":12,\"recordNo\":\"PC-2026-0433\",\"versionId\":1}}},{\"status\":409,\"description\":\"recordNo already exists.\",\"example\":{\"success\":false,\"message\":\"A record with this number already exists\",\"errors\":null}},{\"status\":422,\"description\":\"Request body failed validation.\",\"example\":{\"success\":false,\"message\":\"Validation failed\",\"errors\":[{\"type\":\"field\",\"msg\":\"Invalid value\",\"path\":\"email\",\"location\":\"body\"}]}}]}', 2),
(33, 5, 'Get Decrypted Content', 'GET', '/documents/{{documentId}}/content', 'Streams the decrypted file. Add ?reason=... if the document\'s classification is \'confidential\'.', 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Streams the DECRYPTED current version. The server fetches ciphertext from cloud storage, unwraps the stored key, decrypts in memory, verifies the checksum, and streams the result — plaintext never touches server disk.\",\"parameters\":[{\"name\":\"documentId\",\"in\":\"path\",\"type\":\"integer\",\"required\":true,\"description\":\"\"},{\"name\":\"reason\",\"in\":\"query\",\"type\":\"string\",\"required\":false,\"description\":\"Required if the record\'s classification is \\\"confidential\\\" — omitting it on a confidential record returns 400.\"}],\"responses\":[{\"status\":200,\"description\":\"The decrypted file, with the correct Content-Type and Content-Disposition.\",\"example\":\"<binary file content>\"},{\"status\":400,\"description\":\"Confidential record opened without ?reason=.\",\"example\":{\"success\":false,\"message\":\"Confidential records require a stated reason to open (pass ?reason=...)\",\"errors\":null}},{\"status\":500,\"description\":\"Decrypted bytes don\'t match the stored checksum — a genuine integrity failure, not something to retry blindly.\",\"example\":{\"success\":false,\"message\":\"Integrity check failed — decrypted content does not match the stored checksum\",\"errors\":null}}]}', 3),
(34, 5, 'Declare Record Final', 'POST', '/documents/{{documentId}}/declare-final', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Marks a record Declared Final and starts its retention clock (retention_due_at = now + the record\'s retention class period).\",\"parameters\":[{\"name\":\"documentId\",\"in\":\"path\",\"type\":\"integer\",\"required\":true,\"description\":\"\"}],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Record declared final — retention clock started\",\"data\":null}},{\"status\":404,\"description\":\"Record not found.\",\"example\":{\"success\":false,\"message\":\"Record not found\",\"errors\":null}}]}', 4),
(35, 6, 'List Versions for Document', 'GET', '/versions/document/{{documentId}}', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Version history for a record, newest first.\",\"parameters\":[{\"name\":\"documentId\",\"in\":\"path\",\"type\":\"integer\",\"required\":true,\"description\":\"\"}],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":[{\"id\":1,\"version_no\":1,\"file_name\":\"claim.pdf\",\"size_bytes\":204800,\"is_current\":1,\"created_by\":\"Thabo Simelane\",\"created_at\":\"2026-06-01 09:12:00\"}]}}]}', 0),
(36, 6, 'Upload New Version', 'POST', '/versions/document/{{documentId}}', NULL, 'bearer', '{}', '{}', '{}', 1, '{\"summary\":\"Upload a new version. The previous version is kept, never overwritten — this just adds a new one and marks it current.\",\"parameters\":[{\"name\":\"documentId\",\"in\":\"path\",\"type\":\"integer\",\"required\":true,\"description\":\"\"}],\"requestBody\":{\"fields\":[{\"name\":\"file\",\"type\":\"file\",\"required\":true,\"description\":\"multipart/form-data field.\"}]},\"responses\":[{\"status\":201,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"New version uploaded\",\"data\":{\"versionId\":2,\"versionNo\":2}}},{\"status\":404,\"description\":\"Record not found.\",\"example\":{\"success\":false,\"message\":\"Record not found\",\"errors\":null}}]}', 1),
(37, 6, 'Restore Version', 'POST', '/versions/{{versionId}}/restore', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Promotes an older version to current. This writes a pointer update, not a new file — nothing is deleted.\",\"parameters\":[{\"name\":\"versionId\",\"in\":\"path\",\"type\":\"integer\",\"required\":true,\"description\":\"\"}],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Version 1 promoted to current\",\"data\":null}},{\"status\":404,\"description\":\"Version not found.\",\"example\":{\"success\":false,\"message\":\"Version not found\",\"errors\":null}}]}', 2),
(38, 7, 'Get ACL for Folder', 'GET', '/permissions/folder/{{folderId}}', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"ACL entries on a folder — own grants only (folders have nothing to inherit from).\",\"parameters\":[{\"name\":\"folderId\",\"in\":\"path\",\"type\":\"integer\",\"required\":true,\"description\":\"\"}],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":{\"own\":[{\"id\":1,\"principal_type\":\"user\",\"principal_name\":\"Thabo Simelane\",\"permission_level\":\"edit\"}],\"inherited\":[]}}}]}', 0),
(39, 7, 'Get ACL for Document', 'GET', '/permissions/document/{{documentId}}', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"ACL entries on a document — its own grants plus what it inherits from its parent folder.\",\"parameters\":[{\"name\":\"documentId\",\"in\":\"path\",\"type\":\"integer\",\"required\":true,\"description\":\"\"}],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":{\"own\":[],\"inherited\":[{\"id\":1,\"principal_type\":\"group\",\"principal_name\":\"Benefits Team\",\"permission_level\":\"view\"}]}}}]}', 1),
(40, 7, 'Grant ACL on Folder', 'POST', '/permissions/folder/{{folderId}}', NULL, 'bearer', '{}', '{}', '{\"principalType\":\"user\",\"principalId\":\"{{userId}}\",\"permissionLevel\":\"edit\"}', 0, '{\"summary\":\"Grant access on a folder — inherited by every document inside it.\",\"parameters\":[{\"name\":\"folderId\",\"in\":\"path\",\"type\":\"integer\",\"required\":true,\"description\":\"\"}],\"requestBody\":{\"fields\":[{\"name\":\"principalType\",\"type\":\"string\",\"required\":true,\"description\":\"user | group\"},{\"name\":\"principalId\",\"type\":\"integer\",\"required\":true,\"description\":\"\"},{\"name\":\"permissionLevel\",\"type\":\"string\",\"required\":true,\"description\":\"view | comment | edit | approve | full_control\"}]},\"responses\":[{\"status\":201,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Access granted\",\"data\":{\"id\":4}}}]}', 2),
(41, 7, 'Revoke ACL Entry', 'DELETE', '/permissions/{{aclId}}', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Revoke one ACL entry, by its own id (not the folder/document id).\",\"parameters\":[{\"name\":\"aclId\",\"in\":\"path\",\"type\":\"integer\",\"required\":true,\"description\":\"The id returned when the grant was created.\"}],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Access revoked\",\"data\":null}},{\"status\":404,\"description\":\"ACL entry not found.\",\"example\":{\"success\":false,\"message\":\"ACL entry not found\",\"errors\":null}}]}', 3),
(42, 7, 'Get Role x Module Matrix', 'GET', '/permissions/matrix/all', 'System Administrator only.', 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"The full role × module permission matrix — System Administrator only.\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":[{\"role_id\":5,\"role_name\":\"System Administrator\",\"module\":\"repository\",\"can_view\":1,\"can_edit\":1}]}},{\"status\":403,\"description\":\"Signed in, but the account\'s role does not permit this action.\",\"example\":{\"success\":false,\"message\":\"You do not have permission to perform this action\",\"errors\":null}}]}', 4),
(43, 7, 'Update Role x Module Matrix Cell', 'PUT', '/permissions/matrix', 'System Administrator only.', 'bearer', '{}', '{}', '{\"roleId\":\"{{roleId}}\",\"module\":\"repository\",\"canView\":true,\"canEdit\":false}', 0, '{\"summary\":\"Upsert one role/module permission cell — System Administrator only.\",\"parameters\":[],\"requestBody\":{\"fields\":[{\"name\":\"roleId\",\"type\":\"integer\",\"required\":true,\"description\":\"\"},{\"name\":\"module\",\"type\":\"string\",\"required\":true,\"description\":\"e.g. repository, viewer, capture, versions, permissions, workflow, audit, retention, integrations, reports, approvals.\"},{\"name\":\"canView\",\"type\":\"boolean\",\"required\":false,\"description\":\"\"},{\"name\":\"canEdit\",\"type\":\"boolean\",\"required\":false,\"description\":\"\"}]},\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Permission matrix updated\",\"data\":null}},{\"status\":403,\"description\":\"Signed in, but the account\'s role does not permit this action.\",\"example\":{\"success\":false,\"message\":\"You do not have permission to perform this action\",\"errors\":null}}]}', 5),
(44, 8, 'My Approval Inbox', 'GET', '/approvals', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Items currently awaiting approval by the signed-in user\'s role.\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":[{\"approval_id\":1,\"instance_id\":1,\"document_id\":12,\"record_no\":\"PC-2026-0433\",\"title\":\"Application for Retirement Benefit\",\"step_name\":\"Manager authorisation\",\"sla_days\":3}]}}]}', 0),
(45, 8, 'Approve', 'POST', '/approvals/{{approvalId}}/approve', NULL, 'bearer', '{}', '{}', '{\"comment\":\"Looks correct.\"}', 0, '{\"summary\":\"Approve — advances the workflow to its next step, or to Approved if this was the last one.\",\"parameters\":[{\"name\":\"approvalId\",\"in\":\"path\",\"type\":\"integer\",\"required\":true,\"description\":\"\"}],\"requestBody\":{\"fields\":[{\"name\":\"comment\",\"type\":\"string\",\"required\":false,\"description\":\"\"}]},\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Item approved\",\"data\":null}},{\"status\":409,\"description\":\"Already decided.\",\"example\":{\"success\":false,\"message\":\"This item has already been decided\",\"errors\":null}}]}', 1),
(46, 8, 'Reject', 'POST', '/approvals/{{approvalId}}/reject', NULL, 'bearer', '{}', '{}', '{\"comment\":\"Missing certified HR stamp.\"}', 0, '{\"summary\":\"Reject — ends the workflow instance. Does not move to any other step.\",\"parameters\":[{\"name\":\"approvalId\",\"in\":\"path\",\"type\":\"integer\",\"required\":true,\"description\":\"\"}],\"requestBody\":{\"fields\":[{\"name\":\"comment\",\"type\":\"string\",\"required\":false,\"description\":\"Required in practice even though technically optional.\"}]},\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Item rejected\",\"data\":null}}]}', 2),
(47, 9, 'List Workflows', 'GET', '/workflow', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"List all configured workflows with their ordered steps.\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":[{\"id\":1,\"name\":\"Retirement Claim Assessment\",\"is_active\":1,\"steps\":[{\"step_order\":1,\"step_name\":\"Records check\",\"role_name\":\"Records Officer\",\"sla_days\":2}]}]}}]}', 0),
(48, 9, 'Create Workflow', 'POST', '/workflow', NULL, 'bearer', '{}', '{}', '{\"name\":\"Retirement Claim Assessment\",\"triggerDocTypeId\":\"{{documentTypeId}}\",\"triggerFolderId\":\"{{folderId}}\",\"steps\":[{\"stepName\":\"Records check\",\"roleId\":1,\"slaDays\":2},{\"stepName\":\"Manager authorisation\",\"roleId\":2,\"slaDays\":3}]}', 0, '{\"summary\":\"Create a workflow: a name plus an ordered array of role-based steps with SLAs.\",\"parameters\":[],\"requestBody\":{\"fields\":[{\"name\":\"name\",\"type\":\"string\",\"required\":true,\"description\":\"\"},{\"name\":\"triggerDocTypeId\",\"type\":\"integer\",\"required\":false,\"description\":\"\"},{\"name\":\"triggerFolderId\",\"type\":\"integer\",\"required\":false,\"description\":\"\"},{\"name\":\"steps\",\"type\":\"array\",\"required\":true,\"description\":\"Array of { stepName, roleId, slaDays } — at least one required, in the order they should run.\"}]},\"responses\":[{\"status\":201,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Workflow saved\",\"data\":{\"id\":1}}},{\"status\":422,\"description\":\"Request body failed validation.\",\"example\":{\"success\":false,\"message\":\"Validation failed\",\"errors\":[{\"type\":\"field\",\"msg\":\"Invalid value\",\"path\":\"email\",\"location\":\"body\"}]}}]}', 1),
(49, 9, 'Start Workflow on Document', 'POST', '/workflow/{{workflowId}}/start/{{documentId}}', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Start an instance of a workflow against a specific record, at step 1.\",\"parameters\":[{\"name\":\"workflowId\",\"in\":\"path\",\"type\":\"integer\",\"required\":true,\"description\":\"\"},{\"name\":\"documentId\",\"in\":\"path\",\"type\":\"integer\",\"required\":true,\"description\":\"\"}],\"responses\":[{\"status\":201,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Workflow started\",\"data\":{\"instanceId\":1}}},{\"status\":400,\"description\":\"The workflow has no steps configured.\",\"example\":{\"success\":false,\"message\":\"Workflow has no steps configured\",\"errors\":null}}]}', 2),
(50, 10, 'List Audit Entries', 'GET', '/audit', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Filterable audit trail — up to 500 most recent entries.\",\"parameters\":[{\"name\":\"action\",\"in\":\"query\",\"type\":\"string\",\"required\":false,\"description\":\"e.g. View, Edit, Approve, Capture, Download, Permission, Login, \\\"Login failed\\\", Integration, \\\"Declare record\\\", Disposal, Create, Delete, MFA, Logout.\"},{\"name\":\"q\",\"in\":\"query\",\"type\":\"string\",\"required\":false,\"description\":\"Matches user name, record id, detail text, or IP address.\"},{\"name\":\"from\",\"in\":\"query\",\"type\":\"string\",\"required\":false,\"description\":\"ISO date/datetime, inclusive.\"},{\"name\":\"to\",\"in\":\"query\",\"type\":\"string\",\"required\":false,\"description\":\"ISO date/datetime, inclusive.\"}],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":[{\"id\":401,\"created_at\":\"2026-06-01 09:12:00\",\"user_name\":\"Thabo Simelane\",\"action\":\"Capture\",\"record_type\":\"document\",\"record_id\":\"12\",\"detail\":\"PC-2026-0433 registered (local)\",\"ip_address\":\"10.0.0.5\"}]}},{\"status\":403,\"description\":\"Signed in, but the account\'s role does not permit this action.\",\"example\":{\"success\":false,\"message\":\"You do not have permission to perform this action\",\"errors\":null}}]}', 0),
(51, 10, 'Export Audit CSV', 'GET', '/audit/export.csv', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Downloads up to 50,000 recent entries as CSV. This download is itself logged (auditing the audit log is intentional).\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"text/csv attachment.\",\"example\":\"id,created_at,user_name,action,record_type,record_id,detail,ip_address\\\\n401,\\\"2026-06-01 09:12:00\\\",\\\"Thabo Simelane\\\",\\\"Capture\\\",...\"}]}', 1),
(52, 10, 'Verify Hash Chain', 'GET', '/audit/verify-chain', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Walks the entire hash-chained audit log and confirms no entry has been tampered with or deleted.\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"Chain intact.\",\"example\":{\"success\":true,\"message\":\"Hash chain verified — no gaps\",\"data\":{\"valid\":true,\"brokenAtId\":null,\"entries\":4021}}},{\"status\":200,\"description\":\"Chain broken — investigate starting at brokenAtId.\",\"example\":{\"success\":true,\"message\":\"Hash chain broken\",\"data\":{\"valid\":false,\"brokenAtId\":1774,\"entries\":4021}}}]}', 2),
(53, 11, 'List Retention Classes', 'GET', '/retention/classes', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"List retention classes (e.g. \\\"Pension claim records — 7 years\\\").\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":[{\"id\":1,\"code\":\"RC-CLAIM-7\",\"name\":\"Pension claim records\",\"retention_years\":7,\"disposal_action\":\"transfer_to_national_archives\"}]}}]}', 0),
(54, 11, 'Update Retention Class', 'PUT', '/retention/classes/{{retentionClassId}}', NULL, 'bearer', '{}', '{}', '{\"retentionYears\":7,\"disposalAction\":\"archive\"}', 0, '{\"summary\":\"Update a retention class — Records Manager / System Administrator only.\",\"parameters\":[{\"name\":\"retentionClassId\",\"in\":\"path\",\"type\":\"integer\",\"required\":true,\"description\":\"\"}],\"requestBody\":{\"fields\":[{\"name\":\"retentionYears\",\"type\":\"integer\",\"required\":false,\"description\":\"\"},{\"name\":\"disposalAction\",\"type\":\"string\",\"required\":false,\"description\":\"destroy | archive | transfer_to_national_archives | review\"},{\"name\":\"name\",\"type\":\"string\",\"required\":false,\"description\":\"\"}]},\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Retention schedule updated\",\"data\":null}},{\"status\":403,\"description\":\"Signed in, but the account\'s role does not permit this action.\",\"example\":{\"success\":false,\"message\":\"You do not have permission to perform this action\",\"errors\":null}}]}', 1),
(55, 11, 'List Records Due for Disposal', 'GET', '/retention/due', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Records whose retention_due_at has passed and are eligible for disposal review.\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":[{\"id\":12,\"record_no\":\"PC-2019-0091\",\"title\":\"Retirement claim — archived member\",\"retention_due_at\":\"2026-05-01 00:00:00\",\"disposal_action\":\"transfer_to_national_archives\",\"retention_class_name\":\"Pension claim records\"}]}}]}', 2);
INSERT INTO `sandbox_requests` (`id`, `folder_id`, `name`, `method`, `path`, `description`, `auth_type`, `default_headers_json`, `default_query_json`, `default_body_json`, `has_file_upload`, `doc_json`, `sort_order`) VALUES
(56, 11, 'Dispose Record', 'POST', '/retention/{{documentId}}/dispose', 'Records Manager / System Administrator only.', 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Confirm disposal of a due record — Records Manager / System Administrator only.\",\"parameters\":[{\"name\":\"documentId\",\"in\":\"path\",\"type\":\"integer\",\"required\":true,\"description\":\"\"}],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Record marked disposed\",\"data\":null}},{\"status\":403,\"description\":\"Signed in, but the account\'s role does not permit this action.\",\"example\":{\"success\":false,\"message\":\"You do not have permission to perform this action\",\"errors\":null}}]}', 3),
(57, 12, 'List Notifications', 'GET', '/notifications', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"The signed-in user\'s notifications, newest first (up to 100).\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":[{\"id\":9,\"type\":\"approval_pending\",\"title\":\"Approval required: PC-2026-0433\",\"is_read\":0,\"created_at\":\"2026-06-01 09:13:00\"}]}}]}', 0),
(58, 12, 'Mark One Read', 'PUT', '/notifications/1/read', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Mark one notification read. The \\\"1\\\" in this sample request is a literal id — replace it with a real notification id from GET /notifications.\",\"parameters\":[{\"name\":\"id\",\"in\":\"path\",\"type\":\"integer\",\"required\":true,\"description\":\"Shown as a literal \\\"1\\\" in this catalog entry — edit the path to a real id before sending.\"}],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Marked read\",\"data\":null}}]}', 1),
(59, 12, 'Mark All Read', 'PUT', '/notifications/read-all', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Mark every unread notification for the signed-in user as read.\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"All notifications marked read\",\"data\":null}}]}', 2),
(60, 13, 'List Integrations', 'GET', '/integrations', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Status of every configured integration (Active Directory, HRIS, SMTP, SMS, and the three cloud storage providers).\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":[{\"id\":\"aws_s3\",\"name\":\"AWS S3\",\"status\":\"disconnected\",\"last_sync_at\":null},{\"id\":\"smtp\",\"name\":\"E-mail & notifications\",\"status\":\"connected\",\"endpoint\":\"smtp.pspf.co.sz:587\"}]}}]}', 0),
(61, 13, 'Update Integration', 'PUT', '/integrations/aws_s3', 'System Administrator only. Path param is the integration id, e.g. ad, hris, smtp, sms, aws_s3, azure_blob, gcp_storage.', 'bearer', '{}', '{}', '{\"status\":\"connected\",\"endpoint\":\"s3.af-south-1.amazonaws.com\"}', 0, '{\"summary\":\"Update an integration\'s status/config — System Administrator only. Path segment is the integration id (ad, hris, smtp, sms, aws_s3, azure_blob, gcp_storage) — this sample targets aws_s3, edit it to target another.\",\"parameters\":[{\"name\":\"id\",\"in\":\"path\",\"type\":\"string\",\"required\":true,\"description\":\"One of: ad, hris, smtp, sms, aws_s3, azure_blob, gcp_storage.\"}],\"requestBody\":{\"fields\":[{\"name\":\"status\",\"type\":\"string\",\"required\":false,\"description\":\"connected | disconnected | error\"},{\"name\":\"endpoint\",\"type\":\"string\",\"required\":false,\"description\":\"\"},{\"name\":\"configJson\",\"type\":\"object\",\"required\":false,\"description\":\"Non-secret config only — actual credentials stay in .env, never in this table.\"}]},\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Integration updated\",\"data\":null}},{\"status\":403,\"description\":\"Signed in, but the account\'s role does not permit this action.\",\"example\":{\"success\":false,\"message\":\"You do not have permission to perform this action\",\"errors\":null}}]}', 1),
(62, 13, 'Capture Batch Summary', 'GET', '/integrations/capture-batches/summary', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Throughput per intake source (scanner, watched folder, email intake, device upload).\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":[{\"source\":\"watched_folder\",\"batches\":14,\"total_pages\":1880,\"total_documents\":610,\"avg_success_rate\":98.1}]}}]}', 2),
(63, 13, 'Record Capture Batch', 'POST', '/integrations/capture-batches', NULL, 'bearer', '{}', '{}', '{\"batchNo\":\"B-2026-0044\",\"source\":\"watched_folder\",\"pages\":188,\"documents\":61,\"successRate\":98.1}', 0, '{\"summary\":\"Record a completed capture batch\'s stats.\",\"parameters\":[],\"requestBody\":{\"fields\":[{\"name\":\"batchNo\",\"type\":\"string\",\"required\":true,\"description\":\"Must be unique, e.g. B-2026-0044.\"},{\"name\":\"source\",\"type\":\"string\",\"required\":true,\"description\":\"network_scanner | watched_folder | email_intake | device_upload\"},{\"name\":\"pages\",\"type\":\"integer\",\"required\":false,\"description\":\"\"},{\"name\":\"documents\",\"type\":\"integer\",\"required\":false,\"description\":\"\"},{\"name\":\"successRate\",\"type\":\"number\",\"required\":false,\"description\":\"Percentage, e.g. 98.1.\"}]},\"responses\":[{\"status\":201,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"Batch recorded\",\"data\":{\"id\":15}}}]}', 3),
(64, 14, 'Records by Status', 'GET', '/reports/by-status', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Record counts grouped by status.\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":[{\"status\":\"approved\",\"total\":214},{\"status\":\"pending_approval\",\"total\":18}]}},{\"status\":403,\"description\":\"Signed in, but the account\'s role does not permit this action.\",\"example\":{\"success\":false,\"message\":\"You do not have permission to perform this action\",\"errors\":null}}]}', 0),
(65, 14, 'Records by Department', 'GET', '/reports/by-department', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Record counts grouped by owning department.\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":[{\"department\":\"Benefits\",\"total\":340},{\"department\":\"Finance\",\"total\":92}]}}]}', 1),
(66, 14, 'Claim Turnaround', 'GET', '/reports/claim-turnaround', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Average days from a workflow starting to its first decision, grouped by month.\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":[{\"month\":\"2026-05\",\"avg_days_to_first_decision\":3.2},{\"month\":\"2026-06\",\"avg_days_to_first_decision\":2.8}]}}]}', 2),
(67, 14, 'Audit Action Counts', 'GET', '/reports/audit-actions', NULL, 'bearer', '{}', '{}', 'null', 0, '{\"summary\":\"Count of audit log entries per action type, most frequent first.\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"success\":true,\"message\":\"OK\",\"data\":[{\"action\":\"View\",\"total\":5210},{\"action\":\"Download\",\"total\":890}]}}]}', 3),
(68, 15, 'Health Check', 'GET', 'http://localhost:4000/health', 'Note: this hits {{baseUrl}} minus /api — override the URL to {{baseUrlRoot}}/health, or just call http://localhost:4000/health directly.', 'none', '{}', '{}', 'null', 0, '{\"summary\":\"Liveness check — deliberately unversioned and un-authenticated, so a load balancer or uptime monitor never needs API credentials or to know the current API version.\",\"parameters\":[],\"responses\":[{\"status\":200,\"description\":\"\",\"example\":{\"status\":\"ok\",\"service\":\"pspf-edms-api\",\"apiPrefix\":\"/api/v1\",\"time\":\"2026-08-16T21:13:27.000Z\"}}]}', 0);

-- --------------------------------------------------------

--
-- Table structure for table `sandbox_request_logs`
--

CREATE TABLE `sandbox_request_logs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `api_key_id` int(10) UNSIGNED NOT NULL,
  `environment_id` int(10) UNSIGNED DEFAULT NULL,
  `sandbox_request_id` int(10) UNSIGNED DEFAULT NULL,
  `method` varchar(10) NOT NULL,
  `path` varchar(255) NOT NULL,
  `status_code` smallint(6) DEFAULT NULL,
  `duration_ms` int(10) UNSIGNED DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sandbox_request_logs`
--

INSERT INTO `sandbox_request_logs` (`id`, `user_id`, `api_key_id`, `environment_id`, `sandbox_request_id`, `method`, `path`, `status_code`, `duration_ms`, `created_at`) VALUES
(1, 2, 1, 2, 57, 'GET', '/notifications', 401, 194, '2026-08-17 00:57:25'),
(2, 2, 1, 2, 60, 'GET', '/integrations', 401, 9, '2026-08-17 00:57:39'),
(3, 2, 1, 2, 11, 'POST', '/mfa/enroll/totp/start', 401, 28, '2026-08-17 00:57:49'),
(4, 2, 1, 2, 12, 'POST', '/mfa/enroll/totp/confirm', 401, 19, '2026-08-17 00:57:55'),
(5, 2, 1, 2, 15, 'POST', '/mfa/backup-codes/generate', 401, 5, '2026-08-17 00:58:03'),
(6, 2, 1, 2, 7, 'POST', '/auth/microsoft', 500, 34, '2026-08-17 00:58:30'),
(7, 2, 1, 2, 8, 'POST', '/auth/active-directory', 501, 32, '2026-08-17 00:58:41'),
(8, 2, 1, 2, 49, 'POST', '/workflow/{{workflowId}}/start/{{documentId}}', 401, 6, '2026-08-17 00:59:04'),
(9, 2, 1, 2, 47, 'GET', '/workflow', 401, 6, '2026-08-17 00:59:09'),
(10, 2, 1, 2, 60, 'GET', '/integrations', 401, 6, '2026-08-17 01:02:14'),
(11, 2, 1, 2, 60, 'GET', '/integrations', 401, 4, '2026-08-17 01:03:53'),
(12, 2, 1, 2, 2, 'POST', '/auth/login', 200, 322, '2026-08-17 01:04:27'),
(13, 2, 1, 2, 4, 'GET', '/auth/me', 401, 4, '2026-08-17 01:04:46'),
(14, 2, 1, 2, 2, 'POST', '/auth/login', NULL, 74, '2026-08-18 07:21:14'),
(15, 2, 1, 2, 2, 'POST', '/auth/login', NULL, 21, '2026-08-18 07:34:55');

-- --------------------------------------------------------

--
-- Table structure for table `sandbox_user_variables`
--

CREATE TABLE `sandbox_user_variables` (
  `user_id` int(10) UNSIGNED NOT NULL,
  `var_key` varchar(80) NOT NULL,
  `var_value` varchar(1000) DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sandbox_user_variables`
--

INSERT INTO `sandbox_user_variables` (`user_id`, `var_key`, `var_value`, `updated_at`) VALUES
(2, '{{accessToken}}', NULL, '2026-08-17 01:04:32'),
(2, 'mfaToken', NULL, '2026-08-17 01:04:52');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(10) UNSIGNED NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `email` varchar(190) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('admin','developer') NOT NULL DEFAULT 'developer',
  `status` enum('pending','approved','rejected','suspended') NOT NULL DEFAULT 'pending',
  `company` varchar(150) DEFAULT NULL,
  `reason` varchar(500) DEFAULT NULL COMMENT 'Why they want sandbox access — shown to admin at approval time',
  `approved_by` int(10) UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `full_name`, `email`, `password_hash`, `role`, `status`, `company`, `reason`, `approved_by`, `approved_at`, `created_at`) VALUES
(1, 'Docs Portal Admin', 'admin@docsecure.com', '$2a$12$uMbWVrL//8J08gkS9ITFh..zQTlIqNcrM4sA.OSy1ukVH2XI/ngJK', 'admin', 'approved', NULL, NULL, NULL, '2026-08-16 22:57:59', '2026-08-16 22:57:59'),
(2, 'Siwakhile Masilela', 'wakhiwakhi1@gmail.com', '$2a$12$xnDyGUjbzKeK0kgWmkDXCuCRQJB4pG103mCAsDn0LGYGZEUV8BSKW', 'developer', 'approved', 'PSPF', NULL, 1, '2026-08-16 23:06:08', '2026-08-16 23:05:56');

-- --------------------------------------------------------

--
-- Table structure for table `user_sessions`
--

CREATE TABLE `user_sessions` (
  `id` char(36) NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `refresh_token_hash` char(64) NOT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `expires_at` datetime NOT NULL,
  `revoked_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_sessions`
--

INSERT INTO `user_sessions` (`id`, `user_id`, `refresh_token_hash`, `user_agent`, `ip_address`, `expires_at`, `revoked_at`, `created_at`) VALUES
('1920be00-d519-4e2c-ba51-9d5382e663eb', 2, '9d56b30ef2dfc8ff90222590c6602b9caa3877eec4360bd36f72dea13cbbf0ab', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '::1', '2026-08-31 22:29:39', NULL, '2026-08-17 22:29:39'),
('1c40cbf7-b803-4736-bcba-460b3c81105f', 2, 'afb86245b819c15ed7a867472b1815a751c3c6f7c11e7e31f9a830456e8a8455', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '::1', '2026-08-31 22:29:43', NULL, '2026-08-17 22:29:43'),
('3a65c291-dd82-47dc-8efd-9947153f59dd', 2, '80f97b17d88fc41fdde65ab0abefcc051d6435433fdefe2f1368352bc9ed5fb2', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '::1', '2026-08-31 22:29:41', NULL, '2026-08-17 22:29:41'),
('4e7ff776-3e49-403a-9e66-069977bf11fe', 1, '2c77a45178a20adc1a9d2ff66317c286eeccf4fb5864f28d85868af744a5d90d', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '::1', '2026-08-30 23:03:13', '2026-08-17 01:06:38', '2026-08-16 23:03:13'),
('5174f3c3-fe03-4833-9cfd-da5ec0ca2139', 2, 'b1a180fa2e2fb03d976a2cf452080b5c4668a3a12064ec22b56f370ce485bcbe', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '::1', '2026-08-31 00:34:27', '2026-08-17 01:04:56', '2026-08-17 00:34:27'),
('c037a1e8-11ab-4466-ad73-5232334cb6bd', 2, '4a4abb2f54d989fc2c0fadf36185d77c116f78400126179d33277adc6dacc67d', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '::1', '2026-08-30 23:07:24', NULL, '2026-08-16 23:07:24'),
('c0438f59-8d47-449f-8ee2-c7af150cdf94', 2, 'eb20fb23db62d0b4ef0fabac8d147b040dd9ad6ff6829dbff6b29b9851808fda', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '::1', '2026-08-31 22:29:46', NULL, '2026-08-17 22:29:46');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `api_keys`
--
ALTER TABLE `api_keys`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_key_hash` (`key_hash`),
  ADD KEY `fk_key_user` (`user_id`),
  ADD KEY `fk_key_issuer` (`issued_by`);

--
-- Indexes for table `audit_log`
--
ALTER TABLE `audit_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_audit_actor` (`actor_user_id`);

--
-- Indexes for table `media_assets`
--
ALTER TABLE `media_assets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `stored_name` (`stored_name`),
  ADD KEY `fk_media_uploader` (`uploaded_by`);

--
-- Indexes for table `sandbox_environments`
--
ALTER TABLE `sandbox_environments`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `sandbox_folders`
--
ALTER TABLE `sandbox_folders`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `sandbox_requests`
--
ALTER TABLE `sandbox_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_req_folder` (`folder_id`);

--
-- Indexes for table `sandbox_request_logs`
--
ALTER TABLE `sandbox_request_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_log_key` (`api_key_id`),
  ADD KEY `fk_log_env` (`environment_id`),
  ADD KEY `fk_log_req` (`sandbox_request_id`),
  ADD KEY `ix_log_user_time` (`user_id`,`created_at`);

--
-- Indexes for table `sandbox_user_variables`
--
ALTER TABLE `sandbox_user_variables`
  ADD PRIMARY KEY (`user_id`,`var_key`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `fk_users_approver` (`approved_by`);

--
-- Indexes for table `user_sessions`
--
ALTER TABLE `user_sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_session_user` (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `api_keys`
--
ALTER TABLE `api_keys`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `audit_log`
--
ALTER TABLE `audit_log`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `media_assets`
--
ALTER TABLE `media_assets`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `sandbox_environments`
--
ALTER TABLE `sandbox_environments`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `sandbox_folders`
--
ALTER TABLE `sandbox_folders`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `sandbox_requests`
--
ALTER TABLE `sandbox_requests`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=69;

--
-- AUTO_INCREMENT for table `sandbox_request_logs`
--
ALTER TABLE `sandbox_request_logs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `api_keys`
--
ALTER TABLE `api_keys`
  ADD CONSTRAINT `fk_key_issuer` FOREIGN KEY (`issued_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_key_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `audit_log`
--
ALTER TABLE `audit_log`
  ADD CONSTRAINT `fk_audit_actor` FOREIGN KEY (`actor_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `media_assets`
--
ALTER TABLE `media_assets`
  ADD CONSTRAINT `fk_media_uploader` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `sandbox_requests`
--
ALTER TABLE `sandbox_requests`
  ADD CONSTRAINT `fk_req_folder` FOREIGN KEY (`folder_id`) REFERENCES `sandbox_folders` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `sandbox_request_logs`
--
ALTER TABLE `sandbox_request_logs`
  ADD CONSTRAINT `fk_log_env` FOREIGN KEY (`environment_id`) REFERENCES `sandbox_environments` (`id`),
  ADD CONSTRAINT `fk_log_key` FOREIGN KEY (`api_key_id`) REFERENCES `api_keys` (`id`),
  ADD CONSTRAINT `fk_log_req` FOREIGN KEY (`sandbox_request_id`) REFERENCES `sandbox_requests` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_log_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `sandbox_user_variables`
--
ALTER TABLE `sandbox_user_variables`
  ADD CONSTRAINT `fk_var_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_users_approver` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `user_sessions`
--
ALTER TABLE `user_sessions`
  ADD CONSTRAINT `fk_session_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
