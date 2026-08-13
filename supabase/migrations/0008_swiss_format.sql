-- 0008_swiss_format.sql
-- Formato Svizzero (solo 64 squadre, eliminazione a 2 sconfitte).
-- Turni 1-6: puro svizzero a gruppi di punteggio (mai bye, verificato
-- matematicamente: il gruppo "0 sconfitte" si dimezza sempre esattamente).
-- Turno 7: l'unica 6-0 rimasta passa alle finali con un bye di merito, le
-- sei 5-1 giocano l'ultimo turno tra loro (3 avanzano, 3 eliminate).
-- Le 4 finaliste chiudono il torneo come un classico tabellone a
-- eliminazione diretta (bracket_type = 'main'/'third_place', riusando le
-- funzioni gia' esistenti select_match_winner e complete_tournament).

alter table tournaments
	add column format text not null default 'knockout' check (format in ('knockout', 'swiss'));

alter table tournament_teams
	add column swiss_wins integer not null default 0,
	add column swiss_losses integer not null default 0,
	add column swiss_eliminated boolean not null default false,
	add column swiss_eliminated_round integer null,
	add column swiss_bye boolean not null default false;

alter table matches drop constraint if exists matches_bracket_type_check;
alter table matches add constraint matches_bracket_type_check check (bracket_type in ('main', 'third_place', 'swiss'));
alter table matches add column score_group text null;

-- ==========================================================
-- create_swiss_tournament: crea il torneo e il turno 1 (32 coppie casuali)
-- ==========================================================
create or replace function create_swiss_tournament(
	p_name text,
	p_team_ids uuid[]
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
	v_user_id uuid := auth.uid();
	v_tournament_id uuid;
	v_ordered_ids uuid[];
	v_distinct_count integer;
	v_match_number integer;
begin
	if v_user_id is null then
		raise exception 'AUTH_REQUIRED' using errcode = '28000';
	end if;

	if p_team_ids is null or array_length(p_team_ids, 1) <> 64 then
		raise exception 'INVALID_TEAM_COUNT: il formato svizzero richiede esattamente 64 squadre, ricevute %', coalesce(array_length(p_team_ids, 1), 0);
	end if;

	select count(distinct t) into v_distinct_count from unnest(p_team_ids) as t;
	if v_distinct_count <> 64 then
		raise exception 'DUPLICATE_TEAMS';
	end if;

	select array_agg(t order by random()) into v_ordered_ids from unnest(p_team_ids) as t;

	insert into tournaments (user_id, name, size, status, draw_mode, format, started_at)
	values (v_user_id, p_name, 64, 'active', 'random', 'swiss', now())
	returning id into v_tournament_id;

	insert into tournament_teams (tournament_id, team_id, seed_position)
	select v_tournament_id, team_id, ord
	from unnest(v_ordered_ids) with ordinality as u(team_id, ord);

	for v_match_number in 1..32 loop
		insert into matches (
			tournament_id, round_number, round_name, match_number, bracket_type,
			team_a_id, team_b_id, status, score_group
		) values (
			v_tournament_id, 1, 'Turno 1', v_match_number, 'swiss',
			v_ordered_ids[(v_match_number - 1) * 2 + 1], v_ordered_ids[(v_match_number - 1) * 2 + 2],
			'ready', '0-0'
		);
	end loop;

	return v_tournament_id;
end;
$$;

-- ==========================================================
-- generate_swiss_round: raggruppa le squadre attive per record (V-P),
-- le abbina a caso dentro ogni gruppo (una squadra sola in un gruppo,
-- come la 6-0 al turno 7, resta semplicemente senza partita: e' il bye).
-- ==========================================================
create or replace function generate_swiss_round(p_tournament_id uuid, p_round integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	v_match_number integer := 0;
	rec record;
begin
	for rec in
		with ranked as (
			select
				tt.team_id,
				tt.swiss_wins,
				tt.swiss_losses,
				row_number() over (partition by tt.swiss_wins, tt.swiss_losses order by random()) as rn
			from tournament_teams tt
			where tt.tournament_id = p_tournament_id and tt.swiss_eliminated = false
		)
		select
			a.swiss_wins,
			a.swiss_losses,
			a.team_id as team_a_id,
			b.team_id as team_b_id
		from ranked a
		join ranked b
			on a.swiss_wins = b.swiss_wins and a.swiss_losses = b.swiss_losses and b.rn = a.rn + 1
		where a.rn % 2 = 1
		order by a.swiss_wins desc, a.swiss_losses asc, a.rn
	loop
		v_match_number := v_match_number + 1;
		insert into matches (
			tournament_id, round_number, round_name, match_number, bracket_type,
			team_a_id, team_b_id, status, score_group
		) values (
			p_tournament_id, p_round, 'Turno ' || p_round, v_match_number, 'swiss',
			rec.team_a_id, rec.team_b_id, 'ready', rec.swiss_wins || '-' || rec.swiss_losses
		);
	end loop;
end;
$$;

-- ==========================================================
-- generate_swiss_bye_round: assegna il bye all'unica squadra 0 sconfitte
-- rimasta e abbina le sei squadre a 1 sconfitta (turno 7).
-- ==========================================================
create or replace function generate_swiss_bye_round(p_tournament_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	v_active_count integer;
	v_zero_loss_count integer;
	v_bye_team uuid;
begin
	select count(*) into v_active_count from tournament_teams where tournament_id = p_tournament_id and swiss_eliminated = false;
	select count(*) into v_zero_loss_count from tournament_teams where tournament_id = p_tournament_id and swiss_eliminated = false and swiss_losses = 0;

	if v_active_count <> 7 or v_zero_loss_count <> 1 then
		raise exception 'SWISS_STATE_UNEXPECTED: attese 7 squadre attive con 1 imbattuta, trovate % attive e % imbattute', v_active_count, v_zero_loss_count;
	end if;

	select team_id into v_bye_team from tournament_teams where tournament_id = p_tournament_id and swiss_eliminated = false and swiss_losses = 0;
	update tournament_teams set swiss_bye = true where tournament_id = p_tournament_id and team_id = v_bye_team;

	-- la squadra col bye e' sola nel suo gruppo di punteggio: generate_swiss_round
	-- non le crea nessuna partita, abbina solo le sei rimanenti (1 sconfitta)
	perform generate_swiss_round(p_tournament_id, 7);
end;
$$;

-- ==========================================================
-- generate_swiss_final_four: le 4 finaliste (bye + 3 vincitrici del turno 7)
-- chiudono il torneo come un tabellone knockout standard (riusa
-- select_match_winner / complete_tournament gia' esistenti).
-- ==========================================================
create or replace function generate_swiss_final_four(p_tournament_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	v_final_four uuid[];
	v_count integer;
	v_semi1 uuid;
	v_semi2 uuid;
	v_final_id uuid;
begin
	select array_agg(team_id order by random()) into v_final_four
	from tournament_teams
	where tournament_id = p_tournament_id and swiss_eliminated = false;

	v_count := coalesce(array_length(v_final_four, 1), 0);
	if v_count <> 4 then
		raise exception 'SWISS_FINAL_FOUR_UNEXPECTED: attese 4 finaliste, trovate %', v_count;
	end if;

	insert into matches (tournament_id, round_number, round_name, match_number, bracket_type, team_a_id, team_b_id, status)
	values (p_tournament_id, 8, round_name_for(2), 1, 'main', v_final_four[1], v_final_four[2], 'ready')
	returning id into v_semi1;

	insert into matches (tournament_id, round_number, round_name, match_number, bracket_type, team_a_id, team_b_id, status)
	values (p_tournament_id, 8, round_name_for(2), 2, 'main', v_final_four[3], v_final_four[4], 'ready')
	returning id into v_semi2;

	insert into matches (tournament_id, round_number, round_name, match_number, bracket_type, status)
	values (p_tournament_id, 9, round_name_for(1), 1, 'main', 'pending')
	returning id into v_final_id;

	insert into matches (tournament_id, round_number, round_name, match_number, bracket_type, status)
	values (p_tournament_id, 9, 'Finale 3°/4° posto', 1, 'third_place', 'pending');

	update matches set next_match_id = v_final_id, next_match_slot = 'A' where id = v_semi1;
	update matches set next_match_id = v_final_id, next_match_slot = 'B' where id = v_semi2;
end;
$$;

-- ==========================================================
-- advance_swiss_stage: dispatcher chiamato quando un turno svizzero e'
-- completo, decide cosa generare in base al turno appena concluso.
-- ==========================================================
create or replace function advance_swiss_stage(p_tournament_id uuid, p_completed_round integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
	if p_completed_round between 1 and 5 then
		perform generate_swiss_round(p_tournament_id, p_completed_round + 1);
	elsif p_completed_round = 6 then
		perform generate_swiss_bye_round(p_tournament_id);
	elsif p_completed_round = 7 then
		perform generate_swiss_final_four(p_tournament_id);
	end if;
end;
$$;

-- ==========================================================
-- select_swiss_match_winner: registra il risultato di una partita svizzera
-- e, se il turno e' completo, genera il turno successivo.
-- ==========================================================
create or replace function select_swiss_match_winner(p_match_id uuid, p_winner_team_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	v_user_id uuid := auth.uid();
	m matches%rowtype;
	v_loser uuid;
	v_remaining integer;
	v_loser_losses integer;
begin
	if v_user_id is null then
		raise exception 'AUTH_REQUIRED' using errcode = '28000';
	end if;

	select m.* into m
	from matches m
	join tournaments t on t.id = m.tournament_id
	where m.id = p_match_id and t.user_id = v_user_id and m.bracket_type = 'swiss'
	for update;

	if not found then
		raise exception 'MATCH_NOT_FOUND_OR_FORBIDDEN';
	end if;

	if p_winner_team_id is distinct from m.team_a_id and p_winner_team_id is distinct from m.team_b_id then
		raise exception 'WINNER_NOT_IN_MATCH';
	end if;

	if m.status = 'completed' then
		raise exception 'MATCH_ALREADY_COMPLETED';
	end if;

	v_loser := case when p_winner_team_id = m.team_a_id then m.team_b_id else m.team_a_id end;

	update matches
	set winner_team_id = p_winner_team_id, loser_team_id = v_loser, status = 'completed', played_at = now()
	where id = m.id;

	update tournament_teams set swiss_wins = swiss_wins + 1
	where tournament_id = m.tournament_id and team_id = p_winner_team_id;

	update tournament_teams
	set swiss_losses = swiss_losses + 1
	where tournament_id = m.tournament_id and team_id = v_loser
	returning swiss_losses into v_loser_losses;

	if v_loser_losses >= 2 then
		update tournament_teams
		set swiss_eliminated = true, swiss_eliminated_round = m.round_number
		where tournament_id = m.tournament_id and team_id = v_loser;
	end if;

	insert into point_events (user_id, tournament_id, team_id, match_id, event_type, points, metadata)
	values (v_user_id, m.tournament_id, p_winner_team_id, m.id, 'match_win', 3, jsonb_build_object('round_name', m.round_name))
	on conflict (match_id, team_id) where event_type = 'match_win' do nothing;

	select count(*) into v_remaining
	from matches
	where tournament_id = m.tournament_id and bracket_type = 'swiss' and round_number = m.round_number and status <> 'completed';

	if v_remaining = 0 then
		perform advance_swiss_stage(m.tournament_id, m.round_number);
	end if;
end;
$$;
