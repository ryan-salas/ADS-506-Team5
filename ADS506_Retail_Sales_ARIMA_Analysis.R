# ADS-506: Manual vs automatically selected seasonal ARIMA
# FRED series: MRTSSM44X72USN, monthly, not seasonally adjusted
# Run in RStudio with an internet connection.
# install.packages(c('tidyverse','fpp3','scales'))

library(tidyverse)
library(fpp3)
library(scales)

out_dir <- 'ADS506_ARIMA_outputs'
dir.create(out_dir, showWarnings = FALSE)

# Reproducible cutoff: use only data available as of November 6, 2026.
# FRED's latest published month at that date was August 2026.
url <- 'https://fred.stlouisfed.org/graph/fredgraph.csv?id=MRTSSM44X72USN'
raw <- readr::read_csv(url, show_col_types = FALSE)
names(raw)[1:2] <- c('DATE', 'Sales')
retail <- raw |>
  mutate(DATE = as.Date(DATE), Month = yearmonth(DATE),
         Sales = readr::parse_number(as.character(Sales))) |>
  select(Month, Sales) |>
  filter(Month <= yearmonth('2026 Aug')) |>
  filter(!is.na(Sales)) |>
  as_tsibble(index = Month)
stopifnot(nrow(retail) >= 60)
stopifnot(!any(is.na(retail$Sales)))
stopifnot(nrow(retail) == length(seq(min(retail$Month), max(retail$Month), by = 1)))

# Hold out the final 12 reported months (Sep 2025–Aug 2026 if data is complete).
last_month <- max(retail$Month)
test_start <- last_month - 11
training <- retail |> filter(Month < test_start)
testing <- retail |> filter(Month >= test_start)
stopifnot(nrow(testing) == 12)

# Manual seasonal ARIMA(1,1,1)(0,1,1)[12].
# d=1 removes linear-level nonstationarity; D=1 removes annual seasonality;
# p=1, q=1 and Q=1 allow short-term and seasonal innovation dynamics.
# Explicitly exclude intercept to fully specify manual model.
fits <- training |>
  model(
    Manual_ARIMA = ARIMA(Sales ~ 0 + pdq(1, 1, 1) + PDQ(0, 1, 1, period = 12)),
    Auto_ARIMA = ARIMA(Sales)
  )

# Forecast exactly the held-out 12 months without leakage.
forecasts <- fits |> forecast(new_data = testing)
accuracy_tbl <- forecasts |> accuracy(retail) |>
  select(.model, .type, RMSE, MAE, MAPE, MASE, RMSSE)
print(fits |> report())
print(accuracy_tbl)
write.csv(as_tibble(accuracy_tbl), file.path(out_dir, 'test_accuracy.csv'), row.names = FALSE)
write.csv(as_tibble(forecasts) |> select(.model, Month, .mean),
          file.path(out_dir, 'forecast_values.csv'), row.names = FALSE)

# For readable graphs, show January 2021 onward but train on all earlier data.
plot_start <- yearmonth('2021 Jan')
plot_data <- retail |> filter(Month >= plot_start)
plot_fc <- function(model_label, plot_title, filename) {
  p <- forecasts |>
    filter(.model == model_label) |>
    autoplot(plot_data, level = c(80, 95)) +
    labs(title = plot_title,
         subtitle = 'Last 12 months are held out for testing',
         x = 'Month', y = 'Sales (millions of US dollars)',
         caption = 'Source: U.S. Census Bureau via FRED, series MRTSSM44X72USN') +
    scale_y_continuous(labels = comma) +
    theme_minimal(base_size = 12)
  print(p)
  ggsave(file.path(out_dir, filename), plot = p,
         width = 11, height = 6, dpi = 200)
}
plot_fc('Manual_ARIMA', 'Manual seasonal ARIMA forecast vs actual sales',
        'manual_arima_forecast.png')
plot_fc('Auto_ARIMA', 'Automatically selected ARIMA forecast vs actual sales',
        'auto_arima_forecast.png')

# Interpretation helper: output the model with the lower test RMSE.
best <- as_tibble(accuracy_tbl) |> arrange(RMSE) |> slice(1)
cat('\nTRAINING:', as.character(min(training$Month)), 'to',
    as.character(max(training$Month)), '\n')
cat('TESTING:', as.character(min(testing$Month)), 'to',
    as.character(max(testing$Month)), '\n')
cat('TEST RMSE WINNER:', best$.model, ' | RMSE:', round(best$RMSE, 1), '\n')
cat('Plots and test metrics are saved in:', out_dir, '\n')
