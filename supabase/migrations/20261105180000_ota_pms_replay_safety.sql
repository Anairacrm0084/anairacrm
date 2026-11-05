-- Replay-safe guardrails for the OTA -> PMS reservation RPC.
-- The inbox row is locked FOR UPDATE by the canonical function before these guards.
do $migration$
declare
  v_definition text;
  v_anchor text := $anchor$
  if p_action='cancel' then
$anchor$;
  v_replacement text := $replacement$
  -- Import retries must return the already-created PMS reservation rather
  -- than inserting a second reservation/folio for the same OTA reference.
  if p_action='import' and v_inbox.hms_reservation_id is not null then
    return jsonb_build_object(
      'ok',true,'duplicate',true,'action','import',
      'hms_reservation_id',v_inbox.hms_reservation_id,
      'external_reference',v_inbox.external_reference
    );
  end if;

  -- A completed cancellation is terminal and must not re-run inventory work.
  -- Failed cancellations remain retryable because the RPC only marks the
  -- inbox cancelled after the PMS reservation/inventory updates succeed.
  if p_action='cancel' and v_inbox.import_status='cancelled' then
    return jsonb_build_object(
      'ok',true,'duplicate',true,'action','cancel',
      'hms_reservation_id',v_inbox.hms_reservation_id,
      'external_reference',v_inbox.external_reference
    );
  end if;

  if p_action='cancel' then
$replacement$;
begin
  v_definition := pg_get_functiondef('public.anaira_process_ota_reservation(uuid,uuid,text)'::regprocedure);
  if position(v_anchor in v_definition)=0 then
    raise exception 'Expected OTA lifecycle anchor was not found; refusing to patch RPC';
  end if;
  if position('Import retries must return' in v_definition)>0 then
    raise notice 'OTA replay guards already present; no change needed';
    return;
  end if;
  v_definition := replace(v_definition,v_anchor,v_replacement);
  execute v_definition;
end
$migration$;
