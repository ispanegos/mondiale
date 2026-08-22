-- 0014_two_bonus_types.sql
-- Sostituisce il bonus unico da +1 con due bonus indipendenti per
-- squadra/partita: uno da 3 punti ("bonus_3") e uno da 2 punti ("bonus_2").
-- Entrambi possono essere attivi insieme sulla stessa squadra nella stessa
-- partita (sono due interruttori separati, non alternativi).

-- ==========================================================
-- match_bonuses: da "un bonus da 1pt per squadra/partita" a "due tipi
-- indipendenti, ciascuno con i suoi punti fissi"
-- ==========================================================
alter table match_bonuses drop constraint if exists match_bonuses_points_check;
alter table match_bonuses drop constraint if exists match_bonuses_match_id_team_id_key;

alter table match_bonuses add column bonus_type text not null default 'bonus_3' check (bonus_type in ('bonus_3', 'bonus_2'));

-- prima si sistemano i dati esistenti (vecchio schema, 1 punto -> 3 punti),
-- POI si aggiunge il vincolo: altrimenti il vincolo si scontra con le righe
-- vecchie che hanno ancora points=1
update match_bonuses set points = 3, bonus_type = 'bonus_3' where points = 1;

alter table match_bonuses add constraint match_bonuses_points_check check (
	(bonus_type = 'bonus_3' and points = 3) or (bonus_type = 'bonus_2' and points = 2)
);
alter table match_bonuses add constraint match_bonuses_match_team_type_key unique (match_id, team_id, bonus_type);

-- ==========================================================
-- point_events: stessa logica, con bonus_type per distinguere i due tipi
-- ==========================================================
drop index if exists point_events_unique_match_bonus;

alter table point_events add column bonus_type text null check (bonus_type in ('bonus_3', 'bonus_2'));

update point_events set points = 3, bonus_type = 'bonus_3' where event_type = 'match_bonus' and points = 1;

create unique index point_events_unique_match_bonus
	on point_events(match_id, team_id, bonus_type)
	where event_type = 'match_bonus';

-- ==========================================================
-- toggle_match_bonus: ora richiede anche il tipo di bonus
-- ==========================================================
drop function if exists toggle_match_bonus(uuid, uuid, boolean);

create or replace function toggle_match_bonus(p_match_id uuid, p_team_id uuid, p_bonus_type text, p_enabled boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	v_user_id uuid := auth.uid();
	m matches%rowtype;
	v_points integer;
begin
	if v_user_id is null then
		raise exception 'AUTH_REQUIRED' using errcode = '28000';
	end if;

	if p_bonus_type not in ('bonus_3', 'bonus_2') then
		raise exception 'INVALID_BONUS_TYPE';
	end if;

	v_points := case when p_bonus_type = 'bonus_3' then 3 else 2 end;

	select m.* into m
	from matches m
	join tournaments t on t.id = m.tournament_id
	where m.id = p_match_id and t.user_id = v_user_id;

	if not found then
		raise exception 'MATCH_NOT_FOUND_OR_FORBIDDEN';
	end if;

	if p_team_id is distinct from m.team_a_id and p_team_id is distinct from m.team_b_id then
		raise exception 'TEAM_NOT_IN_MATCH';
	end if;

	if p_enabled then
		insert into match_bonuses (match_id, team_id, bonus_type, points)
		values (p_match_id, p_team_id, p_bonus_type, v_points)
		on conflict (match_id, team_id, bonus_type) do nothing;

		insert into point_events (user_id, tournament_id, team_id, match_id, event_type, points, bonus_type)
		values (v_user_id, m.tournament_id, p_team_id, p_match_id, 'match_bonus', v_points, p_bonus_type)
		on conflict (match_id, team_id, bonus_type) where event_type = 'match_bonus' do nothing;
	else
		delete from match_bonuses where match_id = p_match_id and team_id = p_team_id and bonus_type = p_bonus_type;
		delete from point_events
		where match_id = p_match_id and team_id = p_team_id and event_type = 'match_bonus' and bonus_type = p_bonus_type;
	end if;
end;
$$;
