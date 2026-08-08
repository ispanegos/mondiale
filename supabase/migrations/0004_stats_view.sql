-- 0004_stats_view.sql
-- Classifica calcolata da dati storici verificabili (point_events, matches, tournament_teams)

create or replace view team_global_stats as
with wins as (
	select m.tournament_id, m.winner_team_id as team_id, t.user_id, count(*) as matches_won
	from matches m
	join tournaments t on t.id = m.tournament_id
	where m.status = 'completed' and m.winner_team_id is not null
	group by m.tournament_id, m.winner_team_id, t.user_id
),
losses as (
	select m.tournament_id, m.loser_team_id as team_id, t.user_id, count(*) as matches_lost
	from matches m
	join tournaments t on t.id = m.tournament_id
	where m.status = 'completed' and m.loser_team_id is not null
	group by m.tournament_id, m.loser_team_id, t.user_id
),
points_agg as (
	select
		pe.user_id,
		pe.team_id,
		sum(pe.points) filter (where pe.event_type = 'match_win') as win_points,
		sum(pe.points) filter (where pe.event_type = 'match_bonus') as bonus_points,
		sum(pe.points) filter (where pe.event_type = 'placement_bonus') as placement_points,
		sum(pe.points) as total_points
	from point_events pe
	group by pe.user_id, pe.team_id
),
placements as (
	select
		t.user_id,
		tt.team_id,
		count(*) filter (where tt.final_position = 1) as first_places,
		count(*) filter (where tt.final_position = 2) as second_places,
		count(*) filter (where tt.final_position = 3) as third_places,
		count(*) filter (where tt.final_position = 4) as fourth_places,
		count(*) filter (where tt.final_position between 1 and 3) as podiums,
		count(distinct tt.tournament_id) as tournaments_played
	from tournament_teams tt
	join tournaments t on t.id = tt.tournament_id
	group by t.user_id, tt.team_id
),
match_totals as (
	select user_id, team_id, sum(matches_won) as matches_won from wins group by user_id, team_id
),
loss_totals as (
	select user_id, team_id, sum(matches_lost) as matches_lost from losses group by user_id, team_id
)
select
	coalesce(p.user_id, pl.user_id, mt.user_id, lt.user_id) as user_id,
	coalesce(p.team_id, pl.team_id, mt.team_id, lt.team_id) as team_id,
	coalesce(p.total_points, 0)::integer as total_points,
	coalesce(p.win_points, 0)::integer as win_points,
	coalesce(p.bonus_points, 0)::integer as bonus_points,
	coalesce(p.placement_points, 0)::integer as placement_points,
	(coalesce(mt.matches_won, 0) + coalesce(lt.matches_lost, 0))::integer as matches_played,
	coalesce(mt.matches_won, 0)::integer as matches_won,
	coalesce(lt.matches_lost, 0)::integer as matches_lost,
	coalesce(pl.tournaments_played, 0)::integer as tournaments_played,
	coalesce(pl.first_places, 0)::integer as first_places,
	coalesce(pl.second_places, 0)::integer as second_places,
	coalesce(pl.third_places, 0)::integer as third_places,
	coalesce(pl.fourth_places, 0)::integer as fourth_places,
	coalesce(pl.podiums, 0)::integer as podiums,
	case when (coalesce(mt.matches_won, 0) + coalesce(lt.matches_lost, 0)) > 0
		then round(coalesce(mt.matches_won, 0)::numeric / (coalesce(mt.matches_won, 0) + coalesce(lt.matches_lost, 0)) * 100, 1)
		else 0
	end as win_rate
from points_agg p
full outer join placements pl on pl.user_id = p.user_id and pl.team_id = p.team_id
full outer join match_totals mt on mt.user_id = coalesce(p.user_id, pl.user_id) and mt.team_id = coalesce(p.team_id, pl.team_id)
full outer join loss_totals lt on lt.user_id = coalesce(p.user_id, pl.user_id, mt.user_id) and lt.team_id = coalesce(p.team_id, pl.team_id, mt.team_id);

-- RLS: la view eredita le policy delle tabelle sottostanti solo se create con
-- security_invoker; impostiamo esplicitamente per rispettare RLS per-utente.
alter view team_global_stats set (security_invoker = true);
