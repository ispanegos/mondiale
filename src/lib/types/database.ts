export type TournamentStatus = 'draft' | 'active' | 'completed';
export type TournamentFormat = 'knockout' | 'swiss';
export type DrawMode = 'random' | 'manual';
export type BracketType = 'main' | 'third_place' | 'swiss';
export type MatchStatus = 'pending' | 'ready' | 'completed';
export type NextMatchSlot = 'A' | 'B';
export type PointEventType = 'match_win' | 'match_bonus' | 'placement_bonus';

export interface TeamRow {
	id: string;
	name: string;
	slug: string;
	iso_code: string;
	flag_emoji: string;
	flag_url: string | null;
	seed_strength: number;
	is_active: boolean;
	created_at: string;
}

export interface TournamentRow {
	id: string;
	user_id: string;
	name: string;
	size: 8 | 16 | 32 | 64;
	status: TournamentStatus;
	draw_mode: DrawMode;
	format: TournamentFormat;
	champion_team_id: string | null;
	runner_up_team_id: string | null;
	third_team_id: string | null;
	fourth_team_id: string | null;
	created_at: string;
	started_at: string | null;
	completed_at: string | null;
	updated_at: string;
}

export interface TournamentTeamRow {
	id: string;
	tournament_id: string;
	team_id: string;
	seed_position: number;
	final_position: number | null;
	placement_points: number;
	swiss_wins: number;
	swiss_losses: number;
	swiss_eliminated: boolean;
	swiss_eliminated_round: number | null;
	swiss_bye: boolean;
	created_at: string;
}

export interface MatchRow {
	id: string;
	tournament_id: string;
	round_number: number;
	round_name: string;
	match_number: number;
	bracket_type: BracketType;
	team_a_id: string | null;
	team_b_id: string | null;
	winner_team_id: string | null;
	loser_team_id: string | null;
	next_match_id: string | null;
	next_match_slot: NextMatchSlot | null;
	status: MatchStatus;
	score_group: string | null;
	played_at: string | null;
	created_at: string;
	updated_at: string;
}

export interface MatchBonusRow {
	id: string;
	match_id: string;
	team_id: string;
	points: 1;
	created_at: string;
}

export interface PointEventRow {
	id: string;
	user_id: string;
	tournament_id: string;
	team_id: string;
	match_id: string | null;
	event_type: PointEventType;
	points: number;
	metadata: Record<string, unknown>;
	created_at: string;
}

export interface ProfileRow {
	id: string;
	display_name: string | null;
	created_at: string;
	updated_at: string;
}

export interface TeamGlobalStatsRow {
	user_id: string;
	team_id: string;
	total_points: number;
	win_points: number;
	bonus_points: number;
	placement_points: number;
	matches_played: number;
	matches_won: number;
	matches_lost: number;
	tournaments_played: number;
	first_places: number;
	second_places: number;
	third_places: number;
	fourth_places: number;
	podiums: number;
	win_rate: number;
}

export interface Database {
	public: {
		Tables: {
			teams: {
				Row: TeamRow;
				Insert: Partial<TeamRow>;
				Update: Partial<TeamRow>;
				Relationships: [];
			};
			tournaments: {
				Row: TournamentRow;
				Insert: Partial<TournamentRow>;
				Update: Partial<TournamentRow>;
				Relationships: [];
			};
			tournament_teams: {
				Row: TournamentTeamRow;
				Insert: Partial<TournamentTeamRow>;
				Update: Partial<TournamentTeamRow>;
				Relationships: [];
			};
			matches: {
				Row: MatchRow;
				Insert: Partial<MatchRow>;
				Update: Partial<MatchRow>;
				Relationships: [];
			};
			match_bonuses: {
				Row: MatchBonusRow;
				Insert: Partial<MatchBonusRow>;
				Update: Partial<MatchBonusRow>;
				Relationships: [];
			};
			point_events: {
				Row: PointEventRow;
				Insert: Partial<PointEventRow>;
				Update: Partial<PointEventRow>;
				Relationships: [];
			};
			profiles: {
				Row: ProfileRow;
				Insert: Partial<ProfileRow>;
				Update: Partial<ProfileRow>;
				Relationships: [];
			};
		};
		Views: {
			team_global_stats: { Row: TeamGlobalStatsRow; Relationships: [] };
		};
		Functions: {
			create_tournament: {
				Args: {
					p_size: number;
					p_draw_mode: DrawMode;
					p_team_ids: string[];
				};
				Returns: string;
			};
			create_swiss_tournament: {
				Args: {
					p_team_ids: string[];
				};
				Returns: string;
			};
			select_match_winner: {
				Args: { p_match_id: string; p_winner_team_id: string };
				Returns: undefined;
			};
			select_swiss_match_winner: {
				Args: { p_match_id: string; p_winner_team_id: string };
				Returns: undefined;
			};
			toggle_match_bonus: {
				Args: { p_match_id: string; p_team_id: string; p_enabled: boolean };
				Returns: undefined;
			};
			complete_tournament: {
				Args: { p_tournament_id: string };
				Returns: undefined;
			};
			reopen_tournament: {
				Args: { p_tournament_id: string };
				Returns: undefined;
			};
		};
		Enums: Record<string, never>;
		CompositeTypes: Record<string, never>;
	};
}
