-- Phase 3: Store -> POS -> KOT/KDS/Billing -> Payment -> Delivery; Reservation -> POS
-- Applied to live Supabase as 078_phase3_pos_reservation_payment_delivery.
-- See live migration for canonical SQL; generated package preserves migration marker.

-- NOTE: live function requires an actual rider assignment through an available rider workflow; UI dispatch should call ana​​ira_phase1_delivery_transition with p_next_status=assigned and p_rider_id.
