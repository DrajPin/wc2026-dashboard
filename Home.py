import streamlit as st
import pandas as pd
import altair as alt

# Page Configuration
st.set_page_config(
    page_title="World Cup 2026 Analytics",
    page_icon="trophy-image.png",  # Path to your local image file
    layout="wide",
)

conn = st.connection("postgresql", type="sql")

col_img, col_title = st.columns([0.1, 0.9])

with col_img:
    # Updated to the new filename and extension
    st.image("trophy-image.png", width=60)

with col_title:
    st.title("World Cup 2026 Analytics Dashboard")
st.divider()

# ==========================================
# SECTION 1: GROUP STAGE BLUEPRINT
# ==========================================
st.header("Group Stage Blueprint")
df_groups = conn.query("""
    SELECT group_name, team_name, wc_appearances, modern_win_rate_pct, 
           modern_draw_rate_pct, modern_clean_sheet_pct, 
           group_avg_modern_win_rate, group_accumulated_wc_appearances 
    FROM marts.agg_group_scout 
    ORDER BY group_name, modern_win_rate_pct DESC
""")

st.info(
    "Note: 'Modern' metrics evaluate performance in competitive international matches played since January 1, 2018."
)

selected_group = st.selectbox("Select Group:", df_groups["group_name"].unique())
group_slice = df_groups[df_groups["group_name"] == selected_group].copy()

col1, col2 = st.columns(2)
col1.metric(
    "Combined World Cup Experience",
    f"{int(group_slice['group_accumulated_wc_appearances'].iloc[0])} Apps",
)
col2.metric(
    "Group Average Modern Win Rate",
    f"{float(group_slice['group_avg_modern_win_rate'].iloc[0]):.1f}%",
)

st.markdown("### Group Team Breakdown Table")
st.dataframe(
    group_slice[
        [
            "team_name",
            "wc_appearances",
            "modern_win_rate_pct",
            "modern_draw_rate_pct",
            "modern_clean_sheet_pct",
        ]
    ],
    hide_index=True,
    use_container_width=True,
    column_config={
        "team_name": "National Team",
        "wc_appearances": st.column_config.NumberColumn(
            "Total World Cups", format="%d"
        ),
        "modern_win_rate_pct": "Recent Win Rate %",
        "modern_draw_rate_pct": "Recent Draw Rate %",
        "modern_clean_sheet_pct": "Clean Sheet % (Defense)",
    },
)

st.divider()

# ==========================================
# SECTION 2: HEAD-TO-HEAD DREAM MATCH SIMULATOR
# ==========================================
st.header("Head-to-Head Dream Match Simulator")
all_competitor_teams = conn.query(
    "SELECT DISTINCT team_name FROM marts.fact_matches ORDER BY team_name;"
)["team_name"].tolist()

col_a, col_b = st.columns(2)
team_a = col_a.selectbox(
    "Select Team A:",
    all_competitor_teams,
    index=all_competitor_teams.index("Argentina")
    if "Argentina" in all_competitor_teams
    else 0,
)
team_b = col_b.selectbox(
    "Select Team B:",
    all_competitor_teams,
    index=all_competitor_teams.index("Brazil")
    if "Brazil" in all_competitor_teams
    else 1,
)

if team_a == team_b:
    st.warning("Please choose two different countries to simulate a matchup.")
else:
    match_slice = conn.query(
        """SELECT match_date, tournament, team_name, opponent_name, goals_scored, goals_conceded, match_outcome 
           FROM marts.fact_matches 
           WHERE team_name = :t_a AND opponent_name = :t_b
           ORDER BY match_date DESC;""",
        params={"t_a": team_a, "t_b": team_b},
    )

    if len(match_slice) == 0:
        st.info("No historical matches found for this pair.")
    else:
        wins_a = len(match_slice[match_slice["match_outcome"] == "Win"])
        wins_b = len(match_slice[match_slice["match_outcome"] == "Loss"])
        draws = len(match_slice[match_slice["match_outcome"] == "Draw"])

        st.markdown(
            f"### Historical Records Summary ({len(match_slice)} Total Matches)"
        )
        m1, m2, m3 = st.columns(3)
        m1.metric(f"{team_a} Wins", wins_a)
        m2.metric("Draws", draws)
        m3.metric(f"{team_b} Wins", wins_b)

        st.markdown("### Individual Match History Logs")
        st.dataframe(
            match_slice,
            use_container_width=True,
            hide_index=True,
            column_config={
                "match_date": "Date",
                "tournament": "Tournament",
                "team_name": "Team A",
                "opponent_name": "Team B",
                "goals_scored": "Team A Goals",
                "goals_conceded": "Team B Goals",
                "match_outcome": "Outcome for Team A",
            },
        )

st.divider()

# ==========================================
# SECTION 3: UNDERDOG FINDER
# ==========================================
st.header("World Cup Underdog Finder")
df_ud = conn.query("SELECT * FROM marts.agg_dark_horse;")

chart_df = df_ud.rename(
    columns={
        "team_name": "Nation",
        "group_name": "Group",
        "wc_appearances": "WC Appearances",
        "modern_era_win_rate_pct": "Win Rate (%)",
        "dark_horse_classification": "Category",
        "dark_horse_index_score": "Score",
    }
)
chart_df["display_size"] = chart_df["Score"].apply(lambda x: max(x, 1.0))

scatter = (
    alt.Chart(chart_df)
    .mark_circle(opacity=0.7, stroke="white", strokeWidth=1)
    .encode(
        x=alt.X("WC Appearances:Q", title="World Cup Appearances"),
        y=alt.Y("Win Rate (%):Q", title="Recent Win Rate (%)"),
        color="Category:N",
        size=alt.Size("display_size:Q", legend=None),
        tooltip=["Nation", "WC Appearances", "Win Rate (%)", "Score"],
    )
    .properties(height=400)
    .configure_axis(grid=False)
)

st.altair_chart(scatter, use_container_width=True)

st.dataframe(
    df_ud.sort_values(by="dark_horse_index_score", ascending=False),
    use_container_width=True,
    hide_index=True,
    column_config={
        "team_name": "National Team",
        "group_name": "2026 Group",
        "wc_appearances": st.column_config.NumberColumn(
            "Total World Cups", format="%d"
        ),
        "modern_era_win_rate_pct": "Recent Win %",
        # THIS IS THE UPDATED PART:
        "dark_horse_index_score": st.column_config.ProgressColumn(
            "Calculated Underdog Score",
            help="Higher scores indicate higher underdog potential",
            format="%d",
            min_value=0,
            max_value=100,
        ),
        "dark_horse_classification": "Category",
    },
)

st.divider()

# ==========================================
# SECTION 4: GLOBAL FOOTBALL HISTORY (DYNAMIC & INTERACTIVE)
# ==========================================
st.header("Global Football History")
df_score = conn.query(
    "SELECT match_year, total_games, avg_goals_per_game FROM marts.agg_yearly_scoring_trends;"
)

st.subheader("Filter by Era")
min_year = int(df_score["match_year"].min())
max_year = int(df_score["match_year"].max())

# 1. Slider filters the dataframe
year_range = st.slider(
    "Drag the slider to choose a time period:",
    min_value=min_year,
    max_value=max_year,
    value=(1970, max_year),
)

filtered_df = df_score[
    df_score["match_year"].between(year_range[0], year_range[1])
].copy()

# 2. Display metrics for the filtered data
col1, col2 = st.columns(2)
col1.metric(
    label="Total Games Evaluated", value=f"{filtered_df['total_games'].sum():,}"
)
col2.metric(
    label="Average Goals per Game in Era",
    value=f"{filtered_df['avg_goals_per_game'].mean():.2f}",
)

st.markdown("### Average Goals Scored per Game Over Time")

# 3. Dynamic Chart
# We use 'Q' (Quantitative) for year to allow continuous zoom/pan,
# but set an axis format to prevent commas (e.g., 'd' or 'f' format).
# Final Chart
# 'nice=True' forces the Y-axis to dynamically snap to reasonable bounds
# based on the current filtered dataset.
chart = (
    alt.Chart(filtered_df)
    .mark_line(point=True)
    .encode(
        x=alt.X("match_year:Q", title="Year", axis=alt.Axis(format="d", grid=False)),
        y=alt.Y(
            "avg_goals_per_game:Q",
            title="Average Goals per Match",
            scale=alt.Scale(zero=False, nice=True),
        ),
        tooltip=["match_year", "avg_goals_per_game"],
    )
    .properties(height=400)
    .interactive(bind_y=False)
)

st.altair_chart(chart, use_container_width=True)
