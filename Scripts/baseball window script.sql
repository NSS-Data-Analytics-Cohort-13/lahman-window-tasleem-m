--q1 a. Write a query which retrieves each teamid and number of wins (w) for the 2016 season. Apply three window functions to the number of wins (ordered in descending order) - ROW_NUMBER, RANK, AND DENSE_RANK. Compare the output from these three functions. What do you notice?
SELECT teamid, w,
		RANK() OVER(ORDER BY w DESC),
		DENSE_RANK() OVER(ORDER BY w DESC),
		ROW_NUMBER() OVER(ORDER BY w DESC)
FROM teams
WHERE yearid = 2016

--b. Which team has finished in last place in its division (i.e. with the least number of wins) the most number of times? A team's division is indicated by the divid column in the teams table.
SELECT teamid, divid, COUNT (rank) AS num_last_place
FROM	(SELECT yearid, teamid, divid, divwin, w,
			RANK() OVER(PARTITION BY divid, yearid ORDER BY w)
		FROM teams
		WHERE divid IS NOT NULL) AS teams
WHERE rank = 1
GROUP BY divid, teamid
ORDER BY num_last_place DESC
--answer: W - SDN, E - TBA, C - PIT

--q2 a. Barry Bonds has the record for the highest career home runs, with 762. Write a query which returns, for each season of Bonds' career the total number of seasons he had played and his total career home runs at the end of that season. (Barry Bonds' playerid is bondsba01.)
SELECT playerid, yearid, hr,
		COUNT (yearid) OVER() AS total_seasons_num,
		SUM (hr) OVER() AS career_hrs
FROM batting
WHERE playerid = 'bondsba01'

--b. How many players at the end of the 2016 season were on pace to beat Barry Bonds' record? For this question, we will consider a player to be on pace to beat Bonds' record if they have more home runs than Barry Bonds had the same number of seasons into his career.
WITH bonds AS (SELECT playerid, yearid, hr,
					ROW_NUMBER() OVER(ORDER BY yearid) AS b_season_num,
					SUM (hr) OVER(ORDER BY yearid) AS b_season_total
				FROM batting
				WHERE playerid = 'bondsba01')
,
players AS (SELECT playerid, yearid, hr,
				ROW_NUMBER() OVER(PARTITION BY playerid ORDER BY yearid) AS season_num,
				SUM (hr) OVER(PARTITION BY playerid ORDER BY yearid) AS season_total
			FROM batting)

SELECT players.playerid, players.yearid, season_num, season_total, b_season_num, b_season_total
FROM bonds
CROSS JOIN players
WHERE bonds.b_season_num = players.season_num 
	AND players.season_total > bonds.b_season_total
	AND players.yearid = 2016
--answer: 18 players

--c. Were there any players who 20 years into their career who had hit more home runs at that point into their career than Barry Bonds had hit 20 years into his career?
WITH bonds AS (SELECT playerid, yearid, hr,
					ROW_NUMBER() OVER(ORDER BY yearid) AS b_season_num,
					SUM (hr) OVER(ORDER BY yearid) AS b_season_total
				FROM batting
				WHERE playerid = 'bondsba01')
,
players AS (SELECT playerid, yearid, hr,
				ROW_NUMBER() OVER(PARTITION BY playerid ORDER BY yearid) AS season_num,
				SUM (hr) OVER(PARTITION BY playerid ORDER BY yearid) AS season_total
			FROM batting)

SELECT players.playerid, players.yearid, season_num, season_total, b_season_num, b_season_total
FROM bonds
CROSS JOIN players
WHERE bonds.b_season_num = 20 AND players.season_num = 20
	AND players.season_total > bonds.b_season_total
--answer: 1 player

--q3 Find the player who had the most anomalous season in terms of number of home runs hit. To do this, find the player who has the largest gap between the number of home runs hit in a season and the 5-year moving average number of home runs if we consider the 5-year window centered at that year (the window should include that year, the two years prior and the two years after).
SELECT playerid, yearid, teamid, hr,
		AVG(hr) OVER(PARTITION BY playerid ORDER BY yearid ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING)
FROM batting
