-- 0002_rls.sql
-- Row Level Security su tutte le tabelle applicative

alter table teams enable row level security;
alter table tournaments enable row level security;
alter table tournament_teams enable row level security;
alter table matches enable row level security;
alter table match_bonuses enable row level security;
alter table point_events enable row level security;
alter table profiles enable row level security;

-- ==========================================================
-- teams: lettura per utenti autenticati, nessuna scrittura da client
-- ==========================================================
create policy teams_select_authenticated
	on teams for select
	to authenticated
	using (is_active = true);

-- nessuna policy insert/update/delete: solo service role puo' modificarle

-- ==========================================================
-- tournaments: proprietario esclusivo
-- ==========================================================
create policy tournaments_select_own
	on tournaments for select
	to authenticated
	using (user_id = auth.uid());

create policy tournaments_insert_own
	on tournaments for insert
	to authenticated
	with check (user_id = auth.uid());

create policy tournaments_update_own
	on tournaments for update
	to authenticated
	using (user_id = auth.uid())
	with check (user_id = auth.uid());

create policy tournaments_delete_own
	on tournaments for delete
	to authenticated
	using (user_id = auth.uid());

-- ==========================================================
-- tabelle figlie: accesso solo se il torneo appartiene all'utente
-- ==========================================================
create policy tournament_teams_owner
	on tournament_teams for all
	to authenticated
	using (
		exists (
			select 1 from tournaments t
			where t.id = tournament_teams.tournament_id
			and t.user_id = auth.uid()
		)
	)
	with check (
		exists (
			select 1 from tournaments t
			where t.id = tournament_teams.tournament_id
			and t.user_id = auth.uid()
		)
	);

create policy matches_owner
	on matches for all
	to authenticated
	using (
		exists (
			select 1 from tournaments t
			where t.id = matches.tournament_id
			and t.user_id = auth.uid()
		)
	)
	with check (
		exists (
			select 1 from tournaments t
			where t.id = matches.tournament_id
			and t.user_id = auth.uid()
		)
	);

create policy match_bonuses_owner
	on match_bonuses for all
	to authenticated
	using (
		exists (
			select 1 from matches m
			join tournaments t on t.id = m.tournament_id
			where m.id = match_bonuses.match_id
			and t.user_id = auth.uid()
		)
	)
	with check (
		exists (
			select 1 from matches m
			join tournaments t on t.id = m.tournament_id
			where m.id = match_bonuses.match_id
			and t.user_id = auth.uid()
		)
	);

create policy point_events_owner
	on point_events for all
	to authenticated
	using (user_id = auth.uid())
	with check (user_id = auth.uid());

-- ==========================================================
-- profiles: ognuno vede e modifica solo il proprio profilo
-- ==========================================================
create policy profiles_select_own
	on profiles for select
	to authenticated
	using (id = auth.uid());

create policy profiles_insert_own
	on profiles for insert
	to authenticated
	with check (id = auth.uid());

create policy profiles_update_own
	on profiles for update
	to authenticated
	using (id = auth.uid())
	with check (id = auth.uid());
