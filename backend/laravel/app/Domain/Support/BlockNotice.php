<?php

/**
 * Same pause-card words as Python app.domain.blocks.
 * Used when this PHP BFF cannot reach middleware.
 */
namespace App\Domain\Support;

class BlockNotice
{
    public static function for(string $error, int $status = 502): array
    {
        $map = [
            'python_middleware_unreachable' => 'server_quiet',
            'missing_token' => 'session_ended',
            'invalid_token' => 'session_ended',
            'account_frozen' => 'account_paused',
        ];
        $code = $map[$error] ?? ($status >= 500 ? 'server_quiet' : 'generic');
        $copy = [
            'server_quiet' => [
                'title' => 'SaHayak could not answer',
                'line' => 'The helping-hand line is not reaching this computer. You stay on this page. Nothing was sent.',
                'ok' => 'OK',
            ],
            'session_ended' => [
                'title' => 'Please sign in again when you are ready',
                'line' => 'This session ended. You are still on this page. Nothing was posted.',
                'ok' => 'OK',
            ],
            'generic' => [
                'title' => 'A small pause',
                'line' => 'Something needed a moment. You stay on this page.',
                'ok' => 'OK',
            ],
        ];
        $row = $copy[$code] ?? $copy['generic'];
        return [
            'error' => $error,
            'human' => $row['line'],
            'block' => [
                'code' => $code,
                'title' => $row['title'],
                'line' => $row['line'],
                'ok' => $row['ok'],
                'stay' => true,
            ],
        ];
    }
}
