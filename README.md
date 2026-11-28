# Forecasting U.S. Monthly Retail and Food-Service Sales

ADS-506 Final Team Project (Team 5), University of San Diego  
Team: Imogen Ronde, Ryan Salas, Christopher Guillen

## Project Overview
This project forecasts monthly U.S. retail and food-service sales using time series methods in R. We compared seasonal ARIMA, exponential smoothing (ETS), and time series linear regression (TSLM) models against a seasonal naïve benchmark to find the most accurate approach for business planning.

## Data
- **Source:** U.S. Census Bureau, retail trade and food services sales (FRED series [MRTSSM44X72USN](https://fred.stlouisfed.org/series/MRTSSM44X72USN))
- **Period:** January 1992 – August 2026 (monthly, not seasonally adjusted, millions of US dollars)
- **Snapshot:** `MRTSSM44X72USN_snapshot.csv`, downloaded November 28, 2026, so results are reproducible
- **Train/test split:** Training Jan 1992 – Aug 2025; testing Sep 2025 – Aug 2026

## Repository Contents
| File | Description |
|---|---|
| `retail_forecasting_analysis.qmd` | Combined analysis (EDA, all models, results, final forecast) — Appendix 1 of the report |
| `MRTSSM44X72USN_snapshot.csv` | Data snapshot used for all results |
| `ADS506_Retail_Sales_ARIMA_Analysis.R` | Original ARIMA analysis |
| `ETS.Rmd` | Original ETS analysis |
| `eda_tslm_analysis.qmd` | Original EDA and TSLM analysis |

## How to Run
1. Install R and the required packages:
   ```r
   install.packages(c("tidyverse", "fpp3", "gt"))
   ```
2. Clone or download this repository.
3. Open `retail_forecasting_analysis.qmd` in RStudio and click **Render**.

The script reads the data snapshot from the same folder. If the snapshot is missing, it downloads the latest data from FRED (values may differ slightly due to Census revisions).

## Key Results
| Model | RMSE | MAPE |
|---|---|---|
| Manual ARIMA(1,1,1)(0,1,1)[12] | 12,153 | 1.55% |
| Auto ARIMA(1,1,2)(0,1,1)[12] | 12,702 | 1.65% |
| ETS(M,A,M) | 17,061 | 1.94% |
| Log TSLM | 18,301 | 2.32% |
| Seasonal naïve (benchmark) | 30,220 | 3.88% |

The manual seasonal ARIMA produced the most accurate forecasts on the test year.
