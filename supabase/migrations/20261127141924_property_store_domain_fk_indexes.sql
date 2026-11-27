-- Cover the new domain table's actor foreign keys for deletion/update lookups.
create index if not exists ana_prop_store_domains_created_by_idx
  on public.anaira_property_store_domains(created_by) where created_by is not null;
create index if not exists ana_prop_store_domains_updated_by_idx
  on public.anaira_property_store_domains(updated_by) where updated_by is not null;
