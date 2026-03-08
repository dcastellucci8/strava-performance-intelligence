# Strava Performance Intelligence
### A Data Analysis Capstone — UChicago Booth School of Business (BUSN 32120)

## Project Thesis

Strava has built the world's leading platform for endurance athletes, but today it functions primarily as a GPS tracker and social feed. This analysis argues that Strava is sitting on a performance intelligence layer that remains largely untapped.

Using 7 years of personal Strava activity data (4,945 activities, 2018–2026) combined with matched historical weather data, this project demonstrates three product opportunities:

1. **Injury Prevention** — Applying the Acute:Chronic Workload Ratio (ACWR) framework to flag dangerous training load spikes before they result in injury
2. **Engagement Intelligence** — Modeling the drivers of kudos and social engagement to surface actionable prompts at the point of upload
3. **Conditions Intelligence** — Exploring weather patterns across training history as a proof of concept for Strava's Year in Sport feature

---

## Repository Structure

```
strava-performance-intelligence/
│
├── strava_weather_final.ipynb        # Main narrative notebook — EDA, feature engineering, models
├── strava_data_pipeline.ipynb        # Data pipeline — Strava API pull, weather data, Snowflake load
├── strava_weather_queries.sql        # All SQL queries (11 total) with comments and outputs
└── README.md                         # This file
```

---

## Data Sources

| Source | Description |
|---|---|
| Strava API | Personal activity data — 4,945 activities across running, cycling, and other sports |
| Open-Meteo Historical Archive API | Hourly weather data matched to each outdoor activity by start time and GPS coordinates |

Weather data covers temperature, feels-like temperature, humidity, wind speed, and precipitation. VirtualRide activities were excluded from weather pulls due to GPS coordinates originating from Zwift's virtual environment.

---

## Setup Instructions

### Prerequisites

- Python 3.9+
- A Strava account with API access ([Strava API docs](https://developers.strava.com/))
- A Snowflake account (free trial works)
- An Open-Meteo API key (free tier available at [open-meteo.com](https://open-meteo.com/))

### Installation

Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/strava-performance-intelligence.git
cd strava-performance-intelligence
```

Install required packages:
```bash
pip install pandas numpy matplotlib seaborn scikit-learn statsmodels snowflake-connector-python python-dotenv requests
```

### Environment Variables

Create a `.env` file in the root directory with the following variables. **Never commit this file to GitHub.**

```
SNOWFLAKE_ACCOUNT=your_account
SNOWFLAKE_USER=your_username
SNOWFLAKE_PASSWORD=your_password
STRAVA_CLIENT_ID=your_client_id
STRAVA_CLIENT_SECRET=your_client_secret
STRAVA_REFRESH_TOKEN=your_refresh_token
```

### Running the Project

Run notebooks in this order:

1. **`strava_data_pipeline.ipynb`** — Pulls data from the Strava API, fetches matched weather data from Open-Meteo, and loads both tables into Snowflake
2. **`strava_weather_final.ipynb`** — Main analysis notebook. Connects to Snowflake, runs all cleaning, EDA, feature engineering, and modeling

---

## Key Findings

- **ACWR Dashboard** — A rolling 4-week training load baseline successfully identifies high-risk weeks. The July 2025 injury and aggressive post-injury rebuild in September–October 2025 are clearly visible as flagged periods
- **Kudos Model (R² = 0.51)** — Distance, photos, and custom titles are the strongest controllable drivers of engagement. Two of the top three levers require minimal athlete effort at upload
- **Heart Rate Model (R² = 0.30)** — Pace, distance, and elevation explain ~30% of HR variation. The remaining 70% — likely driven by sleep, HRV, and recovery — represents the core argument for Strava as a full intelligence layer
- **Conditions Intelligence** — 7 years of weather data reveals consistent seasonal training patterns and identifiable extreme condition runs, a direct proof of concept for personalized Year in Sport features

---

## Limitations & Future State

This analysis is a single-athlete proof of concept. Three data sources were identified but not fully incorporated:

- **Stryd power meter data** — Per-second running power CSVs would add a more precise effort metric than pace or HR alone
- **Garmin sleep and HRV data** — Likely accounts for the unexplained 70% of the heart rate model
- **Multi-athlete data** — Platform-scale data would allow the kudos model to separate individual social network effects from true engagement drivers

---

## Author

Donald Castellucci — MBA Candidate, UChicago Booth School of Business  
BUSN 32120: Data Analysis with Python and SQL, Winter 2026
