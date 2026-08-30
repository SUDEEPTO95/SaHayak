<?php

/**
 * OrchestrateBloodRequest — same saga steps as Python SAGA_STEPS.
 */
namespace App\Domain\Requests;

class OrchestrateBloodRequest
{
    public const STEPS = [
        'merge_twins',
        'notify_family_ring',
        'notify_society_ring',
        'match_nearest_compatible',
        'notify_public_ping_rest',
        'wait_or_last_unit',
        'first_accept_lock',
        'units_progress',
        'thank_quietly',
    ];

    public function __construct(private array $config = []) {}

    public function nextStep(?string $current): ?string
    {
        if ($current === null) {
            return self::STEPS[0];
        }
        $i = array_search($current, self::STEPS, true);
        if ($i === false || $i + 1 >= count(self::STEPS)) {
            return null;
        }
        return self::STEPS[$i + 1];
    }

    public function escalateWaitMinutes(string $urgency): int
    {
        $m = $this->config['matching'] ?? [];
        if ($urgency === 'critical') {
            return (int) ($m['wait_before_escalate_minutes_critical'] ?? 15);
        }
        return (int) ($m['wait_before_escalate_minutes_scheduled'] ?? 120);
    }

    /**
     * @return list<string>
     */
    public function startLog(): array
    {
        return [self::STEPS[0]];
    }
}
