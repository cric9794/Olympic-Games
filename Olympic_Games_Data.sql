CREATE DATABASE olympic_game;
USE olympic_game;
CREATE TABLE olympic_data
(
	ID INT,
    NAME varchar(255),
    Sex varchar(255),
    Age varchar(255),
    Height varchar(255),
    Weight varchar(255),
    Team varchar(255),
    NOC varchar(255),
    Games varchar(255),
    Year INT,
    Season varchar(255),
    City varchar(255),
    Sports varchar(255),
    Event varchar(255),
    Medal varchar(255)
);

/* Selecting all data from olympic_data table */ 
select *
from olympic_data;

/* Check Secure path from where we can load data from files */  
Show Variables LIKE "secure_file_priv";
/* Loading data from secure file path */

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/athlete_events.csv'
INTO TABLE olympic_data
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(ID, NAME, Sex,Age,Height,Weight,Team,NOC,Games,Year,Season,City,Sports,Event,Medal); 

SELECT *
FROM olympic_data;

/* ################################################################################### */
/* Duplicate records*/

CREATE TABLE new_table LIKE olympic_data;  /*Creating table having same structure of olympic_data's Colums */

INSERT INTO new_table                      /*Inserting rows into new_table */
SELECT DISTINCT * FROM olympic_data        /*Selecting unique rows*/
GROUP BY  NAME,Sex,Age,Height,Weight,Team,NOC,Games,Year,Season,City,Sports,Event,Medal;

SELECT *
FROM new_table;
DROP TABLE olympic_data;

ALTER TABLE new_table RENAME TO olympic_data;

/* ########################################################################################### */
/* Total rows in table */
 
SELECT count(*)  AS Total_rows
FROM olympic_data;

/*  ########################################################################################### */
/*  Recent & Old Olympic data */

SELECT Max(Year) AS Recent_yr,MIN(Year) AS Start_yr
From olympic_data;

/*  ########################################################################################### */
/* Total Olympic Games */

with tab1 AS
          (SELECT DISTINCT (Season), Year
          FROM olympic_data
          ORDER BY Year)
SELECT COUNT(*) AS Total_Olympic_Games
FROM tab1;  

/*  ########################################################################################### */
/* Total Summer Olympics & Total Winter Olympics & List of all Olympic games */   

SELECT
      (SELECT count(DISTINCT Games)
      From  olympic_data
      WHERE Season='Summer') AS Total_Summer_Olympic,
      
      (SELECT COUNT(DISTINCT Games)
       From  olympic_data
       WHERE Season='Winter')  AS Total_Winter_Olympic,
       
       (SELECT COUNT(DISTINCT Games)
		From  olympic_data) AS Total_Olympic;
        
/*  ########################################################################################### */
/*Maximum Participation count*/

SELECT DISTINCT(Name), NOC,COUNT(Name) AS Participation_count
FROM olympic_data
GROUP BY Name 
ORDER BY  Participation_count DESC;

/*  ########################################################################################### */
/*Total Participation of countries in each Olympic Games */

SELECT DISTINCT(Games),count(DISTINCT(NOC)) AS Total_Countries_Participation
FROM olympic_data
GROUP BY Games
ORDER BY Games;

/*  ########################################################################################### */
/* Maximum & minimum Participation of Countries in the Olympics*/

With tab as 
         (SELECT DISTINCT (Games),count(DISTINCT(NOC)) AS Num_of_countries
         FROM olympic_data
         GROUP BY Games
         ORDER BY  Num_of_countries DESC)
SELECT *
FROM tab
WHERE  Num_of_countries IN ((SELECT MIN( Num_of_countries) AS  Minimum_coubtry FROM tab), (SELECT MAX( Num_of_countries) FROM tab));          


/*  ########################################################################################### */
/*Country participated in all Olympic games */  

SELECT DISTINCT(NOC), COUNT(DISTINCT(Games)) AS Participation_Number
FROM olympic_data
GROUP BY NOC
HAVING Participation_Number= (WITH tab1 AS
										(SELECT DISTINCT(Season),Year 
                                        FROM olympic_data
                                        ORDER BY Year)
                               SELECT count(*) AS Total_Olympic_Games
                               FROM tab1)
ORDER BY Participation_Number; 

/*  ########################################################################################### */
/*INDIA MALE AND FEMALE PARTICIPATION */

SELECT count(DISTINCT(Name))as female_count,(SELECT COUNT(DISTINCT(Name))
                                            from olympic_data
                                            where Sex='M') AS Male_count
from olympic_data where Sex='F'; 

/*  ########################################################################################### */
/*  TOTAL Medal HOCKEY */
 
SELECT * 
FROM  olympic_data
WHERE (Medal="Gold"  OR  Medal="Silver" OR  Medal="Bronze") AND NOC="IND" AND Sports="Hockey"
order by Year desc;



/*  ########################################################################################### */
/* FEMALE EVENT FOR WRESTLING
   
select distinct(event)as event_names,sex
from olympic_data
where Sports = "Wrestling" and 
      Sex = "F";
      
/*  ########################################################################################### */
/*  MALE EVENT FOR WRESTLING
         
select distinct(event)as event_names, Sex
from olympic_data
where Sports = "Wrestling" and 
      Sex = "M";  
 
/*  ########################################################################################### */
/*Maximum medals won by country in every Olympic game*/

WITH tab0 as
           (SELECT Games,NOC,COUNT(Medal) AS TOTAL_MEDALS
           FROM olympic_data
           WHERE Medal!='NA'
           GROUP BY Games,NOC
           ORDER BY Games,TOTAL_MEDALS desc)
SELECT Games,NOC,MAX(TOTAL_MEDALS) AS max_medals
FROM tab0
GROUP BY Games; 

/*  ########################################################################################### */
/*  Sport/event, India has won highest medals.*/          
    
WITH INDIA AS    
           (SELECT Sports, count(Medal) AS MEDALS
           FROM olympic_data
           WHERE NOC= 'IND' AND Medal !='NA'
           GROUP BY Sports)
SELECT Sports,MAX(MEDALS)
FROM INDIA
HAVING MAX(MEDALS);


/*  ############################################################################################################ */
/*  Break down all olympic games where India won medal for Hockey and how many medals in each olympic games */

SELECT Games, Team,Sports, COUNT(Medal) AS Medals
FROM olympic_data
WHERE Noc='IND' AND Medal <> 'NA' AND Sports='Hockey'
GROUP BY Games
ORDER BY Medals DESC;

/*  ############################################################################################################ */
/*  hosting city */

with ESC1 AS
		(select games,city 
		from olympic_data
		group by games, city
		order by games)
select city,count(city) as TOTAL_HOSTED
FROM ESC1
GROUP BY city
order by TOTAL_HOSTED desc;


/*  ############################################################################################################ */
/*  SUCCESS RATIO */

SELECT 
		(WITH TAB1 AS
				(SELECT COUNT(*)
                FROM olympic_data
                WHERE MEDAL = "NA")
         SELECT *
         FROM TAB1) NO_MEDALS,
         
         (WITH TAB2 AS
				(SELECT COUNT(*)
                FROM olympic_data
                WHERE MEDAL <> "NA")
         SELECT *
         FROM TAB2) MEDALS,
         
         (SELECT MEDALS/NO_MEDALS) AS success_ratio;
         
 /* ************************************************************************************************************************************** */
/*Which countries have never won gold medal but have won silver/bronze medals?*/

SELECT tab4.Noc , tab4.Total_Silver, tab4.Total_Bronze
FROM
       (SELECT tab3.Noc,
						COALESCE(MAX(Gold),0) AS 'Total_Gold',
						COALESCE(MAX(Silver),0) AS 'Total_Silver',
						COALESCE(MAX(Bronze),0) AS 'Total_Bronze'
        FROM
           (SELECT tab2.Noc,
						CASE WHEN tab2.Medal='Gold' THEN tab2.total_medals END AS 'Gold',
						CASE WHEN tab2.Medal='Silver' THEN tab2.total_medals END AS 'Silver',
						CASE WHEN tab2.Medal='Bronze' THEN tab2.total_medals END AS 'Bronze'
            FROM
                 (WITH tab1 AS
						(SELECT Noc,Medal,COUNT(Medal) AS total_medals
						FROM olympic_data
						WHERE Medal!= 'NA'
						GROUP BY Noc,Medal
						ORDER BY Noc)
					SELECT *
					FROM tab1
					GROUP BY Noc,Medal
                    
					ORDER BY Noc) AS tab2
			GROUP BY Noc,Medal
			ORDER BY Noc) AS tab3
		GROUP BY Noc
		ORDER BY Total_Gold, Total_Silver,Total_Bronze) AS tab4
WHERE Total_Gold =0
ORDER BY Total_Silver DESC;        
 
/* ************************************************************************************************************************************** */
/* Male-Female Ratio*/

   WITH tab AS
			(SELECT COUNT(Name) AS Male_count
			FROM olympic_data
			WHERE Sex ='M')
   SELECT *,
          (WITH tab2 AS
					(SELECT COUNT(Name)
					FROM olympic_data
					WHERE Sex ='F')
		   SELECT *
		   FROM tab2) AS Female_count ,
                        (SELECT Male_count/Female_count )AS Male_Female_Ratio
    FROM tab; 
    
/* ************************************************************************************************************************************** */
/* Athletes who have won the most Gold medals*/

SELECT Name, Team, COUNT(Medal) AS Gold_count
FROM olympic_data
WHERE Medal='Gold'
GROUP BY Name
ORDER BY Gold_count DESC;

/* ************************************************************************************************************************************** */
/*Countries with total medals*/

SELECT Noc,Team, COUNT(Medal) AS Total_medals
FROM olympic_data
WHERE Medal IN ('Gold', 'Silver', 'Bronze')
GROUP BY Noc
ORDER BY Total_medals DESC;

/* ************************************************************************************************************************************** */
/* Total Gold, Silver and Bronze medals won by each country.*/

SELECT Noc, COALESCE(SUM(Gold), 0) as 'Gold',
			COALESCE(SUM(Silver), 0) as 'Silver',
			COALESCE(SUM(Bronze), 0) as 'Bronze'
FROM
	(SELECT Noc, CASE WHEN tab2.Medal='Gold' THEN tab2.Total END AS 'Gold',
				 CASE WHEN tab2.Medal='Silver' THEN tab2.Total END AS 'Silver',
				 CASE WHEN tab2.Medal='Bronze' THEN tab2.Total END AS 'Bronze'
    FROM (WITH tab1 AS
                   (SELECT *,COUNT(*)
                    FROM olympic_data
                    GROUP BY Games, Noc, Medal,Event)
          SELECT * , COUNT(Medal) AS Total
          FROM tab1
		  GROUP BY Games,Noc,Medal,Event
		  ORDER BY Noc) AS tab2) AS tab3
GROUP BY Noc
ORDER BY Gold DESC;

/* ************************************************************************************************************************************** */
/*Total gold, silver and bronze medals won by each country corresponding to each olympic games.*/

SELECT Games,Noc, COALESCE(SUM(Gold),0) AS 'Gold',
				  COALESCE(SUM(Silver),0) AS 'Silver',
				  COALESCE(SUM(Bronze),0) AS 'Bronze'
FROM
    (SELECT Games, Noc,
						CASE WHEN tab2.Medal='Gold' THEN tab2.Total END AS 'Gold',
						CASE WHEN tab2.Medal='Silver' THEN tab2.Total END AS 'Silver',
						CASE WHEN tab2.Medal='Bronze' THEN tab2.Total END AS 'Bronze'
     FROM
         (WITH tab1 AS
					(SELECT Games,Noc, Medal
					FROM olympic_data
					WHERE Medal in ('Gold','Silver','Bronze'))
                    
		  SELECT * , COUNT(Medal) AS Total
		  FROM tab1
		  WHERE Medal='Gold' or Medal='Silver' or Medal='Bronze'
		  GROUP BY Games,Noc,Medal
		  ORDER BY Games) AS tab2) AS tab3
GROUP BY Games, Noc;

/* ************************************************************************************************************************************** */
 
SELECT tab3.Games,
							COALESCE(MAX(Total_Gold),0) AS 'Total_Gold',
							COALESCE(MAX(Total_Silver),0) AS 'Total_Silver',
							COALESCE(MAX(Total_Bronze),0) AS 'Total_Bronze'
FROM
     (SELECT tab2.Games,
					CASE WHEN tab2.Medal ='Gold' THEN CONCAT(tab2.Noc,'-', tab2.Total_medals) END AS 'Total_Gold',
					CASE WHEN tab2.Medal ='Silver' THEN CONCAT(tab2.Noc,'-', tab2.Total_medals) END AS 'Total_Silver',
					CASE WHEN tab2.Medal ='Bronze' THEN CONCAT(tab2.Noc,'-', tab2.Total_medals) END AS 'Total_Bronze'
	  FROM
          (WITH tab1 AS
					(SELECT Games, Medal,Noc,COUNT(Medal) AS num_counts
					FROM olympic_data
					WHERE Medal!= 'NA'
					GROUP BY Games, Medal,Noc
					ORDER BY Games,Medal, num_counts DESC)
          SELECT Games,Medal,Noc, MAX(num_counts) AS Total_medals
		  FROM tab1
          GROUP BY Games,Medal) AS tab2) AS tab3
GROUP BY Games ;

        