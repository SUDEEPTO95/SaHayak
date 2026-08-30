<?php

/**
 * MatchCompatibleDonors — nearest compatible ranking. Port of Python domain.matching.
 * Blood group is a parameter, never MapsActivityForB_POSITIVE.
 */
namespace App\Domain\Matching;

class MatchCompatibleDonors
{
    public function __construct(private array $config) {}

    public function donorsForRecipient(string $recipientGroup): array
    {
        $table = $this->config['compatibility_recipient_to_donors'] ?? [];
        return $table[$recipientGroup] ?? [];
    }

    public function isCompatible(string $recipientGroup, string $donorGroup): bool
    {
        return in_array($donorGroup, $this->donorsForRecipient($recipientGroup), true);
    }

    public static function haversineKm(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $r = 6371.0;
        $p1 = deg2rad($lat1);
        $p2 = deg2rad($lat2);
        $dphi = deg2rad($lat2 - $lat1);
        $dlmb = deg2rad($lon2 - $lon1);
        $a = sin($dphi / 2) ** 2 + cos($p1) * cos($p2) * sin($dlmb / 2) ** 2;
        return 2 * $r * asin(sqrt($a));
    }

    /**
     * @param list<array<string,mixed>> $donors
     * @return list<array<string,mixed>>
     */
    public function rank(
        string $recipientGroup,
        float $originLat,
        float $originLng,
        array $donors,
        float $radiusKm,
        array $daysSinceDonation = [],
    ): array {
        $cooling = (float) ($this->config['cooling']['days_after_whole_blood'] ?? 90);
        $ranked = [];
        foreach ($donors as $d) {
            if (!empty($d['self_hold'])) {
                continue;
            }
            if (($d['available'] ?? true) !== true) {
                continue;
            }
            if (!$this->isCompatible($recipientGroup, (string) $d['blood_group'])) {
                continue;
            }
            $last = $daysSinceDonation[$d['id'] ?? ''] ?? 999;
            if ($last < $cooling) {
                continue;
            }
            $dist = self::haversineKm(
                $originLat,
                $originLng,
                (float) $d['lat'],
                (float) $d['lng'],
            );
            if ($dist > $radiusKm) {
                continue;
            }
            $item = $d;
            $item['distance_km'] = round($dist, 2);
            unset($item['phone']);
            $ranked[] = $item;
        }
        usort($ranked, fn ($a, $b) => $a['distance_km'] <=> $b['distance_km']);
        return $ranked;
    }
}
