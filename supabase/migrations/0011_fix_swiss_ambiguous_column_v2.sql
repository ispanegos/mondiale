-- 0011_fix_swiss_ambiguous_column_v2.sql
-- Se l'errore "column reference m.tournament_id is ambiguous" persiste dopo
-- la 0010, significa che quella migrazione non e' ancora stata eseguita sul
-- database (la 0008 con il bug e' ancora quella attiva). Questa versione
-- rimpiazza di nuovo la funzione, stavolta senza usare per niente l'alias
-- "m" nella query iniziale (usa "mt"), per eliminare ogni possibile
-- ambiguita' alla radice.
--
-- Dopo averla eseguita, verifica con:
--   select prosrc from pg_proc where proname = 'select_swiss_match_winner';
-- e controlla che nel testo compaia "from matches mt" (non "from matches m").

create or replace function select_swiss_match_winner(p_match_id uuid, p_winner_team_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	v_user_id uuid := auth.uid();
	v_tournament_id uuid;
	v_round_number integer;
	v_round_name text;
	v_match_id uuid;
	v_team_a uuid;
	v_team_b uuid;
	v_status text;
	v_loser uuid;
	v_remaining integer;
	v_loser_losses integer;
begin
	if v_user_id is null then
		raise exception 'AUTH_REQUIRED' using errcode = '28000';
	end if;

	select mt.tournament_id, mt.round_number, mt.round_name, mt.id, mt.team_a_id, mt.team_b_id, mt.status
	into v_tournament_id, v_round_number, v_round_name, v_match_id, v_team_a, v_team_b, v_status
	from matches mt
	join tournaments tr on tr.id = mt.tournament_id
	where mt.id = p_match_id and tr.user_id = v_user_id and mt.bracket_type = 'swiss'
	for update of mt;

	if not found then
		raise exception 'MATCH_NOT_FOUND_OR_FORBIDDEN';
	end if;

	if p_winner_team_id is distinct from v_team_a and p_winner_team_id is distinct from v_team_b then
		raise exception 'WINNER_NOT_IN_MATCH';
	end if;

	if v_status = 'completed' then
		raise exception 'MATCH_ALREADY_COMPLETED';
	end if;

	v_loser := case when p_winner_team_id = v_team_a then v_team_b else v_team_a end;

	update matches
	set winner_team_id = p_winner_team_id, loser_team_id = v_loser, status = 'completed', played_at = now()
	where id = v_match_id;

	update tournament_teams set swiss_wins = swiss_wins + 1
	where tournament_id = v_tournament_id and team_id = p_winner_team_id;

	update tournament_teams
	set swiss_losses = swiss_losses + 1
	where tournament_id = v_tournament_id and team_id = v_loser
	returning swiss_losses into v_loser_losses;

	if v_loser_losses >= 2 then
		update tournament_teams
		set swiss_eliminated = true, swiss_eliminated_round = v_round_number
		where tournament_id = v_tournament_id and team_id = v_loser;
	end if;

	insert into point_events (user_id, tournament_id, team_id, match_id, event_type, points, metadata)
	values (v_user_id, v_tournament_id, p_winner_team_id, v_match_id, 'match_win', 3, jsonb_build_object('round_name', v_round_name))
	on conflict (match_id, team_id) where event_type = 'match_win' do nothing;

	select count(*) into v_remaining
	from matches
	where tournament_id = v_tournament_id and bracket_type = 'swiss' and round_number = v_round_number and status <> 'completed';

	if v_remaining = 0 then
		perform advance_swiss_stage(v_tournament_id, v_round_number);
	end if;
end;
$$;
