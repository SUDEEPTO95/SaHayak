<?php

/**
 * Laravel-folder PHP BFF: forwards every /v1 and /console call to the Python middleware.
 * One contract. Domain classes in app/Domain stay the source of matching/saga rules in PHP.
 */
require dirname(__DIR__) . '/autoload.php';

use App\Domain\Support\BlockNotice;

$target = rtrim(getenv('SAHAYAK_PYTHON') ?: 'http://127.0.0.1:8080', '/');
$uri = $_SERVER['REQUEST_URI'] ?? '/';
$url = $target . $uri;
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$body = file_get_contents('php://input') ?: '';

$headers = [];
foreach (function_exists('getallheaders') ? getallheaders() : [] as $k => $v) {
    if (strtolower((string) $k) === 'host') {
        continue;
    }
    $headers[] = $k . ': ' . $v;
}
if ($body !== '' && !preg_grep('/^content-type:/i', $headers)) {
    $headers[] = 'Content-Type: application/json';
}

$ch = curl_init($url);
curl_setopt_array($ch, [
    CURLOPT_CUSTOMREQUEST => $method,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HEADER => true,
    CURLOPT_HTTPHEADER => $headers,
    CURLOPT_POSTFIELDS => in_array($method, ['POST', 'PUT', 'PATCH'], true) ? $body : null,
    CURLOPT_TIMEOUT => 30,
]);
$raw = curl_exec($ch);
if ($raw === false) {
    http_response_code(502);
    header('Content-Type: application/json');
    echo json_encode(BlockNotice::for('python_middleware_unreachable', 502));
    exit;
}
$status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$headerSize = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
curl_close($ch);
$respHeaders = substr($raw, 0, $headerSize);
$respBody = substr($raw, $headerSize);
http_response_code((int) $status);
foreach (explode("\r\n", $respHeaders) as $line) {
    if ($line === '' || str_starts_with(strtolower($line), 'http/')) {
        continue;
    }
    if (str_starts_with(strtolower($line), 'transfer-encoding:')) {
        continue;
    }
    header($line, false);
}
echo $respBody;
