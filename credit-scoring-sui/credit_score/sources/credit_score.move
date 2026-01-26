module credit_score::scoring {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::clock::{Self, Clock};

    // === Structs ===
    
    /// User consent object
    public struct Consent has key, store {
        id: UID,
        user_address: address,
        granted: bool,
        timestamp: u64,
        expiry_date: u64,  // Unix timestamp
    }

    /// Credit score result object
    public struct ScoreResult has key, store {
        id: UID,
        user_address: address,
        score: u64,
        decision: vector<u8>,  // "approve", "review", or "reject"
        timestamp: u64,
        consent_id: address,  // Link to consent object
    }

    // === Events ===
    
    public struct ConsentGranted has copy, drop {
        consent_id: address,
        user_address: address,
        expiry_date: u64,
    }

    public struct ScoreRecorded has copy, drop {
        score_id: address,
        user_address: address,
        score: u64,
        decision: vector<u8>,
    }

    // === Public Functions ===

    /// User grants consent for credit scoring
    public entry fun grant_consent(
        expiry_days: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let current_time = clock::timestamp_ms(clock) / 1000;  // Convert to seconds
        let expiry_date = current_time + (expiry_days * 24 * 60 * 60);
        
        let consent = Consent {
            id: object::new(ctx),
            user_address: tx_context::sender(ctx),
            granted: true,
            timestamp: current_time,
            expiry_date,
        };

        let consent_id = object::uid_to_address(&consent.id);

        sui::event::emit(ConsentGranted {
            consent_id,
            user_address: tx_context::sender(ctx),
            expiry_date,
        });

        // Transfer consent object to user
        transfer::public_transfer(consent, tx_context::sender(ctx));
    }

    /// Admin records credit score result
    public entry fun record_score(
        consent: &Consent,
        score: u64,
        decision: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // Verify consent is still valid
        let current_time = clock::timestamp_ms(clock) / 1000;
        assert!(consent.granted, 1); // Error: Consent not granted
        assert!(current_time < consent.expiry_date, 2); // Error: Consent expired

        let score_result = ScoreResult {
            id: object::new(ctx),
            user_address: consent.user_address,
            score,
            decision,
            timestamp: current_time,
            consent_id: object::uid_to_address(&consent.id),
        };

        let score_id = object::uid_to_address(&score_result.id);

        sui::event::emit(ScoreRecorded {
            score_id,
            user_address: consent.user_address,
            score,
            decision,
        });

        // Transfer score result to user
        transfer::public_transfer(score_result, consent.user_address);
    }

    // === View Functions ===

    public fun get_consent_info(consent: &Consent): (address, bool, u64, u64) {
        (consent.user_address, consent.granted, consent.timestamp, consent.expiry_date)
    }

    public fun get_score_info(result: &ScoreResult): (address, u64, vector<u8>, u64) {
        (result.user_address, result.score, result.decision, result.timestamp)
    }

    public fun is_consent_valid(consent: &Consent, clock: &Clock): bool {
        let current_time = clock::timestamp_ms(clock) / 1000;
        consent.granted && current_time < consent.expiry_date
    }
}