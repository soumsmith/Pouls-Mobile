<?php
/**
 * ══════════════════════════════════════════════════════════════════════════════
 * Script de journalisation globale — Pouls Scolaire / Univers Écoles
 * ══════════════════════════════════════════════════════════════════════════════
 *
 * Ce script reçoit et enregistre TOUS les logs envoyés depuis l'application mobile :
 *  1. Clics & actions sur les boutons (boutons de paiement, navigation, ajouts, etc.)
 *  2. Appels API de l'application (GET, POST, PUT, DELETE, codes HTTP, latence)
 *  3. Événements d'ajout d'enfant (succès, doublon, erreur)
 *  4. Écrans visités (navigation)
 *  5. Authentification (connexion, déconnexion, OTP)
 *
 * Chaque log consigne précisément :
 *  - L'heure exacte (serveur et appareil)
 *  - L'utilisateur (Nom, ID, Téléphone, Email, Rôle) ou 'Non connecté (Invité)'
 *  - Le pays de l'utilisateur (drapeau, nom et code ISO détectés)
 *  - L'adresse IP publique et la plateforme (Android / iOS / Web)
 *  - La nature exacte de l'action ou de la requête API et ses détails
 *
 * Formats de stockage :
 *  - `logs/app_actions_YYYY-MM-DD.log`   : Texte clair, lisible, structuré
 *  - `logs/app_actions_YYYY-MM-DD.jsonl` : Lignes JSON pour import BD / Elasticsearch
 *  - `logs/child_add_YYYY-MM-DD.log`   : Historique spécifique pour les enfants
 */

// ─── 1. EN-TÊTES HTTP & GESTION CORS ──────────────────────────────────────────
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

// Répondre immédiatement aux requêtes OPTIONS (preflight CORS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Réponse informative si consultation via navigateur (GET)
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    echo json_encode([
        'status'  => 'online',
        'service' => 'Pouls Scolaire - Système central de journalisation (Logs)',
        'time'    => date('Y-m-d H:i:s'),
        'version' => '2.0.0',
        'message' => 'Ce point d\'accès enregistre les actions, appels API et événements mobiles en POST JSON.'
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    exit();
}

// Rejeter toute méthode autre que POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'error'   => 'Méthode non autorisée. Seul POST est accepté.'
    ]);
    exit();
}

// ─── 2. LECTURE ET PARSING DU PAYLOAD ─────────────────────────────────────────
$rawInput = file_get_contents('php://input');
$data = json_decode($rawInput, true);

if (!is_array($data) || empty($data)) {
    $data = $_POST;
}

if (empty($data)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error'   => 'Corps de requête vide ou format JSON invalide.'
    ]);
    exit();
}

// ─── 3. RÉCUPÉRATION DE L'IP & HORODATAGE ──────────────────────────────────────
function getClientIp() {
    $keys = [
        'HTTP_CLIENT_IP',
        'HTTP_X_FORWARDED_FOR',
        'HTTP_X_REAL_IP',
        'HTTP_X_FORWARDED',
        'HTTP_FORWARDED_FOR',
        'HTTP_FORWARDED',
        'REMOTE_ADDR'
    ];
    foreach ($keys as $key) {
        if (!empty($_SERVER[$key])) {
            $ips = explode(',', $_SERVER[$key]);
            $ip = trim($ips[0]);
            if (filter_var($ip, FILTER_VALIDATE_IP)) {
                return $ip;
            }
        }
    }
    return $_SERVER['REMOTE_ADDR'] ?? 'UNKNOWN';
}

$clientIp  = getClientIp();
$userAgent = $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown Agent';
$nowDate   = date('Y-m-d');
$nowTime   = date('Y-m-d H:i:s');

// ─── 4. DOSSIER DES LOGS ET SÉCURISATION ───────────────────────────────────────
$logDir = __DIR__ . '/logs';
if (!is_dir($logDir)) {
    @mkdir($logDir, 0755, true);
}

// Bloquer tout accès public direct aux fichiers de logs (.htaccess)
$htaccessFile = $logDir . '/.htaccess';
if (!file_exists($htaccessFile)) {
    @file_put_contents($htaccessFile, "# Protection des fichiers de logs\nDeny from all\n");
}

// ─── 5. EXTRACTION UNIVERSELLE DES INFORMATIONS ────────────────────────────────
$category   = $data['category'] ?? $data['event'] ?? 'action'; // api, button, child, screen, auth
$status     = strtoupper($data['status'] ?? 'INFO');
$timestamp  = $data['timestamp'] ?? $nowTime;
$clientHour = substr($timestamp, 11, 8) ?: date('H:i:s');

// Extraction de l'utilisateur (supporte 'user' ou 'parent')
$userObj = is_array($data['user'] ?? null) 
    ? $data['user'] 
    : (is_array($data['parent'] ?? null) ? $data['parent'] : []);

$userId    = $userObj['id'] ?? null;
$userName  = trim(($userObj['name'] ?? '') ?: (($userObj['firstName'] ?? '') . ' ' . ($userObj['lastName'] ?? '')));
$userPhone = $userObj['phone'] ?? $userObj['mobile'] ?? null;
$userEmail = $userObj['email'] ?? null;
$userRole  = $userObj['role'] ?? null;

if (!empty($userName) || !empty($userPhone) || !empty($userId)) {
    $userSummary = sprintf(
        "%s (ID: %s | Tél: %s%s)",
        $userName ?: 'Utilisateur',
        $userId ?: '-',
        $userPhone ?: '-',
        $userRole ? " | Rôle: $userRole" : ""
    );
} else {
    $userSummary = "Non connecté (Invité)";
}

// Extraction du pays (supporte 'context' ou champs directs)
$context     = is_array($data['context'] ?? null) ? $data['context'] : [];
$countryName = $context['country_name'] ?? $data['country_name'] ?? null;
$countryCode = $context['country_code'] ?? $data['country_code'] ?? null;
$countryFlag = $context['country_flag'] ?? $data['country_flag'] ?? '';
$platform    = $context['platform'] ?? $data['platform'] ?? 'Mobile';

if (!empty($countryName) || !empty($countryCode)) {
    $countryDisplay = trim("$countryFlag " . ($countryName ?: '') . ($countryCode ? " ($countryCode)" : ""));
} else {
    $countryDisplay = "Non spécifié";
}

// ─── 6. MISE EN FORME SELON LE TYPE D'ÉVÉNEMENT ────────────────────────────────
$detailString = '';
$tag = strtoupper($category);

switch ($category) {
    case 'api':
    case 'api_call':
    case 'api_request':
        $method     = strtoupper($data['method'] ?? 'GET');
        $url        = $data['url'] ?? '-';
        $httpCode   = $data['status_code'] ?? $data['http_code'] ?? '-';
        $duration   = isset($data['duration_ms']) ? "{$data['duration_ms']}ms" : '-';
        $error      = $data['error'] ?? null;
        $tag        = "API:$method";
        $detailString = "URL: $url | Code: $httpCode | Durée: $duration" . ($error ? " | Erreur: $error" : "");
        break;

    case 'button':
    case 'button_action':
        $btnName = $data['button_name'] ?? $data['action'] ?? 'Bouton';
        $screen  = $data['screen'] ?? $data['screen_name'] ?? 'Inconnu';
        $tag     = "BOUTON";
        $extras  = isset($data['details']) && is_array($data['details']) ? json_encode($data['details'], JSON_UNESCAPED_UNICODE) : '';
        $detailString = "Action: Clic sur '$btnName' | Écran: $screen" . ($extras ? " | Données: $extras" : "");
        break;

    case 'screen':
    case 'screen_view':
    case 'navigation':
        $screen = $data['screen_name'] ?? $data['screen'] ?? '-';
        $prev   = $data['previous_screen'] ?? null;
        $tag    = "PAGE";
        $detailString = "Ouverture écran: $screen" . ($prev ? " (Depuis: $prev)" : "");
        break;

    case 'child_added':
    case 'child_add_failed':
    case 'child_action':
        $child         = is_array($data['child'] ?? null) ? $data['child'] : [];
        $matricule     = $child['matricule'] ?? '-';
        $childFullName = trim(($child['nom'] ?? '') . ' ' . ($child['prenoms'] ?? ''));
        $classe        = $child['classe'] ?? '-';
        $ecoleNom      = $child['school_name'] ?? '-';
        $ecoleCode     = $child['school_code'] ?? '-';
        $errMsg        = $data['error_message'] ?? null;
        $tag           = "ENFANT:" . ($status === 'SUCCESS' ? 'AJOUT' : $status);
        $detailString  = sprintf(
            "Enfant: %s (Matr: %s, Classe: %s) | École: %s (%s)%s",
            $childFullName ?: '-',
            $matricule,
            $classe,
            $ecoleNom,
            $ecoleCode,
            $errMsg ? " | Erreur: $errMsg" : ""
        );
        break;

    default:
        $actionName = $data['action'] ?? $data['name'] ?? $data['event'] ?? 'action';
        $extras     = isset($data['details']) && is_array($data['details']) ? json_encode($data['details'], JSON_UNESCAPED_UNICODE) : '';
        $detailString = "Action: $actionName" . ($extras ? " | Données: $extras" : "");
        if (!empty($data['error_message'])) {
            $detailString .= " | Erreur: " . $data['error_message'];
        }
        break;
}

// ─── 7. COMPOSITION DE LA LIGNE LISIBLE DANS LE FICHIER .log ──────────────────
// Format : [YYYY-MM-DD HH:MM:SS] [CATÉGORIE] [STATUT] [Utilisateur: ...] [Pays: ...] Détails... | OS: ... | IP: ...
$logLine = sprintf(
    "[%s] [%-10s] [%-7s] [User: %s] [Pays: %s] %s | OS: %s | IP: %s\n",
    $nowTime,
    $tag,
    $status,
    $userSummary,
    $countryDisplay,
    $detailString,
    $platform,
    $clientIp
);

// ─── 8. ÉCRITURE DANS LES FICHIERS DE LOGS ────────────────────────────────────
// 8.1. Journal texte général journalier
$logFileText = $logDir . "/app_actions_{$nowDate}.log";
@file_put_contents($logFileText, $logLine, FILE_APPEND | LOCK_EX);

// 8.2. Journal JSON structuré (1 ligne = 1 JSON valide pour requêtes/analyse)
$fullRecord = array_merge($data, [
    'server_received_at' => $nowTime,
    'server_client_ip'   => $clientIp,
    'server_user_agent'  => $userAgent,
    'parsed_user'        => $userSummary,
    'parsed_country'     => $countryDisplay,
]);
$logFileJson = $logDir . "/app_actions_{$nowDate}.jsonl";
@file_put_contents($logFileJson, json_encode($fullRecord, JSON_UNESCAPED_UNICODE) . "\n", FILE_APPEND | LOCK_EX);

// 8.3. Compatibilité : si c'est un log d'ajout d'enfant, conserver également le log spécifique
if (strpos($category, 'child') !== false || isset($data['child'])) {
    $childLogFile = $logDir . "/child_add_{$nowDate}.log";
    @file_put_contents($childLogFile, $logLine, FILE_APPEND | LOCK_EX);
    $childJsonFile = $logDir . "/child_add_{$nowDate}.jsonl";
    @file_put_contents($childJsonFile, json_encode($fullRecord, JSON_UNESCAPED_UNICODE) . "\n", FILE_APPEND | LOCK_EX);
}

// ─── 9. RÉPONSE JSON DE SUCCÈS ────────────────────────────────────────────────
http_response_code(200);
echo json_encode([
    'success'   => true,
    'message'   => 'Log enregistré avec succès.',
    'category'  => $category,
    'status'    => $status,
    'timestamp' => $nowTime,
    'user'      => $userSummary,
    'country'   => $countryDisplay,
    'ip'        => $clientIp
], JSON_UNESCAPED_UNICODE);
