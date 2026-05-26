# -------------------------------------------------------------------------
# Title:    Data preparation - CRFT OpenSesame local
# Author:   Carla Czilczer
# Date:     26.05.2026
#
# Purpose:
# Prepare CRFT experiment output (.csv files) so that:
# - data_wide contains one row per participant
# - data_long contains five movement-time rows per trial
# - data_wide contains participant-level MIA scores
#
# OpenSesame experiment version:
# - OpenSesame 4.0.24
# - xpyriment backend
#
# R version: 4.5.2
#
# Usage:
# Place this script next to the folder "data".
# The folder "data" must contain the subject-*.csv files.
# The script writes data.rdata containing data_wide and data_long.
# -------------------------------------------------------------------------


# =========================================================================
# PREPARATIONS
# =========================================================================

rm(list = ls())


# -------------------------------------------------------------------------
# Determine the folder containing this script
# -------------------------------------------------------------------------

script_path <- NULL

# 1) Path when running with Rscript
args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)

if (length(file_arg) > 0L) {
  script_path <- sub("^--file=", "", file_arg[1])
}

# 2) Path when sourcing the script
if (is.null(script_path)) {
  of <- tryCatch(sys.frames()[[1]]$ofile, error = function(e) NULL)
  
  if (!is.null(of) && nzchar(of)) {
    script_path <- of
  }
}

# 3) Path when running from RStudio
if (is.null(script_path) &&
    requireNamespace("rstudioapi", quietly = TRUE) &&
    rstudioapi::isAvailable()) {
  
  p <- rstudioapi::getActiveDocumentContext()$path
  
  if (nzchar(p)) {
    script_path <- p
  }
}


# -------------------------------------------------------------------------
# Set working directory to the fixed "data" folder next to this script
# -------------------------------------------------------------------------

if (!is.null(script_path)) {
  script_dir <- dirname(normalizePath(script_path))
  data_dir <- file.path(script_dir, "data")
} else {
  message("Could not determine script location. Using current working directory + /data.")
  data_dir <- file.path(getwd(), "data")
}

if (!dir.exists(data_dir)) {
  stop(
    "Required folder 'data' was not found:\n  ",
    data_dir,
    "\nPlace this script next to the folder 'data'."
  )
}

setwd(data_dir)
message("Working directory set to: ", normalizePath(getwd()))


# =========================================================================
# IMPORT CSV FILES
# =========================================================================

csv_pattern <- "^subject-.*\\.csv$"
files <- list.files(pattern = csv_pattern, full.names = TRUE)

if (length(files) == 0L) {
  stop(
    "No subject CSV files found in:\n  ",
    normalizePath(getwd()),
    "\nExpected filenames such as subject-1.csv, subject-2.csv, ..."
  )
}


# -------------------------------------------------------------------------
# Helper: bind data frames even if columns differ between files
# -------------------------------------------------------------------------

bind_rows_base <- function(data_list) {
  
  all_names <- unique(unlist(lapply(data_list, names)))
  
  data_list <- lapply(data_list, function(d) {
    
    missing_names <- setdiff(all_names, names(d))
    
    for (nm in missing_names) {
      d[[nm]] <- NA
    }
    
    d[, all_names, drop = FALSE]
  })
  
  do.call(rbind, data_list)
}


# -------------------------------------------------------------------------
# Read all participant files
# -------------------------------------------------------------------------

data_list <- lapply(files, function(f) {
  
  d <- read.csv(
    f,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  
  names(d) <- trimws(names(d))
  d$source_file <- basename(f)
  
  d
})

df <- bind_rows_base(data_list)

message(
  "Imported ", length(files), " file(s). ",
  "Combined rows: ", nrow(df),
  " | columns: ", ncol(df)
)

if (ncol(df) == 1L) {
  stop(
    "Only one column was imported. ",
    "Please check whether the CSV files use a separator other than a comma."
  )
}


# =========================================================================
# HELPER FUNCTIONS
# =========================================================================

# -------------------------------------------------------------------------
# Convert empty values to NA
# -------------------------------------------------------------------------

clean_character <- function(x) {
  
  x <- as.character(x)
  x <- trimws(x)
  x[x == "" | tolower(x) %in% c("na", "nan", "none")] <- NA_character_
  
  x
}


# -------------------------------------------------------------------------
# Return first non-empty value of a column
# -------------------------------------------------------------------------

first_value <- function(d, column_name) {
  
  if (!column_name %in% names(d)) {
    return(NA_character_)
  }
  
  values <- clean_character(d[[column_name]])
  values <- values[!is.na(values)]
  
  if (length(values) == 0L) {
    return(NA_character_)
  }
  
  values[1]
}


# -------------------------------------------------------------------------
# Return first non-empty numeric value of a column
# -------------------------------------------------------------------------

first_numeric_value <- function(d, column_name) {
  
  value <- first_value(d, column_name)
  
  if (is.na(value)) {
    return(NA_real_)
  }
  
  suppressWarnings(as.numeric(value))
}


# -------------------------------------------------------------------------
# Return maximum numeric value of a column
# -------------------------------------------------------------------------

max_numeric_value <- function(d, column_name) {
  
  if (!column_name %in% names(d)) {
    return(NA_real_)
  }
  
  values <- suppressWarnings(as.numeric(clean_character(d[[column_name]])))
  values <- values[!is.na(values)]
  
  if (length(values) == 0L) {
    return(NA_real_)
  }
  
  max(values)
}


# -------------------------------------------------------------------------
# Find the first available column among several possible names
# -------------------------------------------------------------------------

first_existing_column <- function(d, candidates) {
  
  available <- candidates[candidates %in% names(d)]
  
  if (length(available) == 0L) {
    return(NA_character_)
  }
  
  available[1]
}


# -------------------------------------------------------------------------
# Derive the condition that was presented first
#
# In the current experiment structure:
# - group A = execution first
# - group B = imagery first
#
# selected_order is used only as a fallback for older or incomplete files.
# -------------------------------------------------------------------------

derive_first_condition <- function(group_value, selected_order_value) {
  
  group_value <- toupper(clean_character(group_value))
  
  if (!is.na(group_value)) {
    
    if (group_value == "A") {
      return("exe")
    }
    
    if (group_value == "B") {
      return("img")
    }
  }
  
  selected_order_value <- tolower(clean_character(selected_order_value))
  
  if (!is.na(selected_order_value)) {
    
    if (selected_order_value == "start with execution") {
      return("exe")
    }
    
    if (selected_order_value == "start with imagery") {
      return("img")
    }
  }
  
  # Random order cannot be reconstructed without the realized group.
  NA_character_
}


# -------------------------------------------------------------------------
# Extract the first CC_attempt_n value within one condition
# -------------------------------------------------------------------------

first_cc_attempt <- function(d, condition_values) {
  
  if (!all(c("current_condition", "CC_attempt_n") %in% names(d))) {
    return(NA_real_)
  }
  
  condition <- tolower(clean_character(d$current_condition))
  condition_values <- tolower(condition_values)
  
  d_condition <- d[condition %in% condition_values, , drop = FALSE]
  
  first_numeric_value(d_condition, "CC_attempt_n")
}


# -------------------------------------------------------------------------
# Convert screen-touch values into logical values
#
# TRUE  = a touch was registered in the trial
# FALSE = no touch was registered in the trial
# NA    = value cannot be interpreted
# -------------------------------------------------------------------------

as_touch_logical <- function(x) {
  
  values <- tolower(clean_character(x))
  
  touched <- rep(NA, length(values))
  
  touched[values %in% c("true", "1", "yes", "y", "t")] <- TRUE
  touched[values %in% c("false", "0", "no", "n", "f")] <- FALSE
  
  touched
}


# -------------------------------------------------------------------------
# Calculate percentage of test-block trials with a registered screen touch
#
# Only test-block trial rows are included.
# Returned values range from 0 to 100.
# -------------------------------------------------------------------------

percent_screen_touched <- function(d, condition_values) {
  
  required_columns <- c(
    "current_condition",
    "block_kind",
    "current_trial_id",
    "screen_touched"
  )
  
  if (!all(required_columns %in% names(d))) {
    return(NA_real_)
  }
  
  condition <- tolower(clean_character(d$current_condition))
  block_kind <- tolower(clean_character(d$block_kind))
  trial_id <- clean_character(d$current_trial_id)
  condition_values <- tolower(condition_values)
  
  # Test blocks are identified by block_kind values beginning with "test".
  is_test_block <- !is.na(block_kind) & grepl("^test", block_kind)
  
  d_condition <- d[
    condition %in% condition_values &
      is_test_block &
      !is.na(trial_id),
    ,
    drop = FALSE
  ]
  
  if (nrow(d_condition) == 0L) {
    return(NA_real_)
  }
  
  touched <- as_touch_logical(d_condition$screen_touched)
  
  if (all(is.na(touched))) {
    return(NA_real_)
  }
  
  mean(touched, na.rm = TRUE) * 100
}


# -------------------------------------------------------------------------
# Calculate one condition-specific MIA regression slope
#
# The previous analysis used:
#   log(MT) ~ current_trial_id
#
# current_trial_id is used as the movement difficulty predictor.
# The returned beta is the standardized regression coefficient.
# -------------------------------------------------------------------------

calculate_mia_beta <- function(d, condition_values) {
  
  required_columns <- c(
    "current_condition",
    "block_kind",
    "current_trial_id",
    "MT"
  )
  
  if (!all(required_columns %in% names(d))) {
    return(NA_real_)
  }
  
  condition <- tolower(clean_character(d$current_condition))
  block_kind <- tolower(clean_character(d$block_kind))
  condition_values <- tolower(condition_values)
  
  is_test_block <- !is.na(block_kind) & grepl("^test", block_kind)
  
  d_condition <- d[
    condition %in% condition_values &
      is_test_block,
    ,
    drop = FALSE
  ]
  
  if (nrow(d_condition) == 0L) {
    return(NA_real_)
  }
  
  difficulty <- suppressWarnings(as.numeric(d_condition$current_trial_id))
  mt <- suppressWarnings(as.numeric(d_condition$MT))
  
  valid <- is.finite(difficulty) &
    is.finite(mt) &
    mt > 0
  
  difficulty <- difficulty[valid]
  mt_log <- log(mt[valid])
  
  # Regression cannot be estimated without sufficient usable variation.
  if (length(mt_log) < 3L ||
      length(unique(difficulty)) < 2L ||
      sd(difficulty) == 0 ||
      sd(mt_log) == 0) {
    return(NA_real_)
  }
  
  model <- lm(
    scale(mt_log) ~ scale(difficulty)
  )
  
  unname(coef(model)[2])
}


# -------------------------------------------------------------------------
# Calculate the participant-level MIA score
#
# Following the previous analysis logic:
# - MIA_exe and MIA_img are condition-specific standardized slopes.
# - MIA_score is the absolute deviation of the exe/img slope ratio from 1.
# - A smaller MIA_score means more similar execution and imagery slopes.
# - If the ratio is not positive, the score is set to NA.
# -------------------------------------------------------------------------

calculate_mia_score <- function(mia_exe, mia_img) {
  
  if (is.na(mia_exe) ||
      is.na(mia_img) ||
      mia_img == 0) {
    return(NA_real_)
  }
  
  mia_ratio <- mia_exe / mia_img
  
  if (!is.finite(mia_ratio) || mia_ratio <= 0) {
    return(NA_real_)
  }
  
  abs(mia_ratio - 1)
}


# =========================================================================
# PREPARE RAW COLUMN NAMES
# =========================================================================

if (!"subject_nr" %in% names(df)) {
  stop("Required column 'subject_nr' is missing from the imported CSV files.")
}


# -------------------------------------------------------------------------
# Rename variables for the final data objects
# -------------------------------------------------------------------------

if (!"current_testbl" %in% names(df) && "n_testbl" %in% names(df)) {
  df$current_testbl <- df$n_testbl
}

if (!"current_trial" %in% names(df) && "current_trial_nr" %in% names(df)) {
  df$current_trial <- df$current_trial_nr
}


# -------------------------------------------------------------------------
# Identify the screen-touch variable
#
# The value is used only to calculate participant-level percentages in
# data_wide. It is not included in data_long.
# -------------------------------------------------------------------------

screen_touch_source <- first_existing_column(
  df,
  c(
    "screen_touched",
    "screen_touch",
    "screen_touch_trial",
    "trial_screen_touched"
  )
)

if (is.na(screen_touch_source)) {
  df$screen_touched <- NA
  message(
    "No screen-touch column found. ",
    "Variables 'screen_touched_exe' and 'screen_touched_img' will contain NA. ",
    "Please check the exact raw CSV column name."
  )
} else {
  df$screen_touched <- df[[screen_touch_source]]
  message("Using screen-touch column: ", screen_touch_source)
}


# =========================================================================
# CREATE data_wide
# =========================================================================
# One row per subject:
# subject_nr, group, sex, age, handedness, language, fam_accuracy, IDs,
# n_reps, total_trial_nr, first_condition, CC_exe, CC_img,
# screen_touched_exe, screen_touched_img
#
# MIA variables are appended after data_long has been created.
# =========================================================================

subjects <- unique(clean_character(df$subject_nr))
subjects <- subjects[!is.na(subjects)]

data_wide_list <- lapply(subjects, function(subject) {
  
  d_subject <- df[clean_character(df$subject_nr) == subject, , drop = FALSE]
  
  group_value <- first_value(d_subject, "group")
  selected_order_value <- first_value(d_subject, "selected_order")
  
  data.frame(
    subject_nr      = subject,
    group           = group_value,
    sex             = first_value(d_subject, "sex"),
    age             = first_numeric_value(d_subject, "age"),
    handedness      = first_value(d_subject, "handedness"),
    language        = first_value(d_subject, "selected_language"),
    fam_accuracy    = first_numeric_value(d_subject, "fam_accuracy"),
    IDs             = first_value(d_subject, "selected_ids"),
    n_reps          = first_numeric_value(d_subject, "n_reps"),
    
    # The maximum gives the number of completed/logged trials per subject.
    total_trial_nr  = max_numeric_value(d_subject, "total_trial_nr"),
    
    first_condition = derive_first_condition(
      group_value,
      selected_order_value
    ),
    
    # First logged CC_attempt_n value within each condition.
    CC_exe          = first_cc_attempt(
      d_subject,
      c("execution", "exe")
    ),
    
    CC_img          = first_cc_attempt(
      d_subject,
      c("imagery", "img")
    ),
    
    # Percentage of test-block trials with a registered screen touch.
    screen_touched_exe = percent_screen_touched(
      d_subject,
      c("execution", "exe")
    ),
    
    screen_touched_img = percent_screen_touched(
      d_subject,
      c("imagery", "img")
    ),
    
    stringsAsFactors = FALSE
  )
})

data_wide <- do.call(rbind, data_wide_list)


# -------------------------------------------------------------------------
# Simple type adjustments for data_wide
# -------------------------------------------------------------------------

data_wide$subject_nr <- as.character(data_wide$subject_nr)
data_wide$group <- as.character(data_wide$group)
data_wide$sex <- tolower(as.character(data_wide$sex))
data_wide$handedness <- tolower(as.character(data_wide$handedness))
data_wide$language <- as.character(data_wide$language)
data_wide$IDs <- as.character(data_wide$IDs)
data_wide$first_condition <- as.character(data_wide$first_condition)

data_wide$age <- suppressWarnings(as.numeric(data_wide$age))
data_wide$fam_accuracy <- suppressWarnings(as.numeric(data_wide$fam_accuracy))
data_wide$n_reps <- suppressWarnings(as.numeric(data_wide$n_reps))
data_wide$total_trial_nr <- suppressWarnings(as.numeric(data_wide$total_trial_nr))
data_wide$CC_exe <- suppressWarnings(as.numeric(data_wide$CC_exe))
data_wide$CC_img <- suppressWarnings(as.numeric(data_wide$CC_img))
data_wide$screen_touched_exe <- suppressWarnings(as.numeric(data_wide$screen_touched_exe))
data_wide$screen_touched_img <- suppressWarnings(as.numeric(data_wide$screen_touched_img))

message("Created data_wide with ", nrow(data_wide), " participant row(s).")


# =========================================================================
# CREATE data_long
# =========================================================================
# Five rows per trial, corresponding to mt_1, mt_2, mt_3, mt_4 and mt_5.
#
# Columns:
# subject_nr, current_condition, block_kind, current_testbl, current_trial,
# current_trial_id, movement_nr, MT
# =========================================================================

required_long_columns <- c(
  "subject_nr",
  "current_condition",
  "block_kind",
  "current_testbl",
  "current_trial",
  "current_trial_id",
  "mt_1",
  "mt_2",
  "mt_3",
  "mt_4",
  "mt_5"
)

missing_long_columns <- setdiff(required_long_columns, names(df))

if (length(missing_long_columns) > 0L) {
  stop(
    "Cannot create data_long because the following required columns are missing:\n  ",
    paste(missing_long_columns, collapse = ", ")
  )
}


# -------------------------------------------------------------------------
# Keep rows that represent CRFT trials
#
# block_kind is retained so practice and test trials remain distinguishable.
# -------------------------------------------------------------------------

trial_rows <- df[
  !is.na(clean_character(df$block_kind)) &
    !is.na(clean_character(df$current_trial_id)),
  ,
  drop = FALSE
]

if (nrow(trial_rows) == 0L) {
  stop(
    "No trial rows found for data_long. ",
    "Please check the variables 'block_kind' and 'current_trial_id'."
  )
}


# -------------------------------------------------------------------------
# Convert mt_1 to mt_5 from wide trial columns into one MT column
# -------------------------------------------------------------------------

mt_columns <- paste0("mt_", 1:5)

mt_matrix <- as.data.frame(
  lapply(trial_rows[, mt_columns, drop = FALSE], function(x) {
    suppressWarnings(as.numeric(as.character(x)))
  })
)

long_base <- trial_rows[
  rep(seq_len(nrow(trial_rows)), each = length(mt_columns)),
  c(
    "subject_nr",
    "current_condition",
    "block_kind",
    "current_testbl",
    "current_trial",
    "current_trial_id"
  ),
  drop = FALSE
]

long_base$movement_nr <- rep(seq_along(mt_columns), times = nrow(trial_rows))
long_base$MT <- as.vector(t(as.matrix(mt_matrix)))

data_long <- long_base[, c(
  "subject_nr",
  "current_condition",
  "block_kind",
  "current_testbl",
  "current_trial",
  "current_trial_id",
  "movement_nr",
  "MT"
)]


# -------------------------------------------------------------------------
# Simple type adjustments for data_long
# -------------------------------------------------------------------------

data_long$subject_nr <- as.character(data_long$subject_nr)
data_long$current_condition <- as.character(data_long$current_condition)
data_long$block_kind <- as.character(data_long$block_kind)
data_long$current_testbl <- suppressWarnings(as.numeric(data_long$current_testbl))
data_long$current_trial <- suppressWarnings(as.numeric(data_long$current_trial))
data_long$current_trial_id <- suppressWarnings(as.numeric(data_long$current_trial_id))
data_long$movement_nr <- suppressWarnings(as.numeric(data_long$movement_nr))
data_long$MT <- suppressWarnings(as.numeric(data_long$MT))

message(
  "Created data_long with ", nrow(data_long), " row(s), corresponding to ",
  nrow(trial_rows), " trial row(s) x 5 movement times."
)


# =========================================================================
# DATA QUALITY AND OUTLIER ANALYSIS - PLACEHOLDER ONLY
# =========================================================================
#
# This section is intentionally not implemented yet.
# It documents checks that should be added once the final logging variables
# and exclusion criteria have been confirmed.
#
#
# -------------------------------------------------------------------------
# Data quality checks to be implemented
# -------------------------------------------------------------------------
#
# 1) Trial completeness
#    - Check whether each participant completed the expected number of
#      practice and test-block trials in both conditions.
#    - Check whether each valid trial contains five usable movement times.
#
# 2) Screen-touch behaviour
#    - In execution test-block trials, check whether the screen was touched
#      when a touch was required.
#    - In imagery test-block trials, check whether unexpected screen touches
#      occurred when no physical touch should be made.
#    - Use screen_touched_exe and screen_touched_img as participant-level
#      summary variables once the final raw touch variable is confirmed.
#
# 3) Comprehension checks
#    - Check how many CC attempts were needed in each condition.
#    - Decide whether a maximum acceptable number of attempts is required.
#    - Use CC_exe and CC_img for participant-level inspection.
#
# 4) Trial validity and technical errors
#    - Check whether aborted, invalid or timed-out trials were logged.
#    - Check whether missing MT values reflect true missing responses,
#      invalid trials or technical problems.
#
#
# -------------------------------------------------------------------------
# Outlier analysis to be implemented
# -------------------------------------------------------------------------
#
# 1) Define exclusions before the final MIA analysis is conducted.
#    Possible checks:
#    - non-positive MT values
#    - missing MT values
#    - implausibly short or long MT values
#    - trial-level outliers within participant and condition
#    - participants with insufficient usable trials per condition
#
# 2) Preserve transparency:
#    - keep the original data_long object unchanged
#    - create a filtered analysis data object for exclusion-based analyses
#    - document every exclusion rule and number of excluded observations
#
# 3) MIA scores below currently use all usable positive MT values from
#    test blocks only. Once exclusions are finalized, replace analysis_long
#    with the filtered analysis data object before calculating MIA scores.
#
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Analysis data object currently used for MIA calculation
#
# No outlier exclusion is applied at this stage.
# -------------------------------------------------------------------------

analysis_long <- data_long


# =========================================================================
# CALCULATE PARTICIPANT-LEVEL MIA SCORES
# =========================================================================
#
# The calculation follows the logic of the previous analysis:
#
# - The dependent variable is log-transformed movement time: log(MT).
# - Separate regressions are estimated for execution and imagery.
# - Only test-block trials are included.
# - current_trial_id is used as the current movement difficulty predictor,
#   corresponding to item_diff in the previous analysis.
# - MIA_exe and MIA_img are standardized regression slopes.
# - MIA_score is the absolute deviation of their ratio from 1:
#
#       MIA_score = abs(MIA_exe / MIA_img - 1)
#
#   provided that the ratio is positive.
#
# Lower MIA_score values indicate more similar slopes in execution and
# imagery. Higher values indicate stronger deviation between conditions.
# =========================================================================

mia_results_list <- lapply(subjects, function(subject) {
  
  d_subject <- analysis_long[
    analysis_long$subject_nr == subject,
    ,
    drop = FALSE
  ]
  
  mia_exe <- calculate_mia_beta(
    d_subject,
    c("execution", "exe")
  )
  
  mia_img <- calculate_mia_beta(
    d_subject,
    c("imagery", "img")
  )
  
  data.frame(
    subject_nr = subject,
    MIA_exe    = mia_exe,
    MIA_img    = mia_img,
    MIA_score  = calculate_mia_score(mia_exe, mia_img),
    stringsAsFactors = FALSE
  )
})

mia_results <- do.call(rbind, mia_results_list)


# -------------------------------------------------------------------------
# Append MIA variables to data_wide without changing participant order
# -------------------------------------------------------------------------

mia_match <- match(data_wide$subject_nr, mia_results$subject_nr)

data_wide$MIA_exe <- mia_results$MIA_exe[mia_match]
data_wide$MIA_img <- mia_results$MIA_img[mia_match]
data_wide$MIA_score <- mia_results$MIA_score[mia_match]

data_wide$MIA_exe <- suppressWarnings(as.numeric(data_wide$MIA_exe))
data_wide$MIA_img <- suppressWarnings(as.numeric(data_wide$MIA_img))
data_wide$MIA_score <- suppressWarnings(as.numeric(data_wide$MIA_score))

message("Calculated and appended participant-level MIA scores to data_wide.")


# =========================================================================
# VARIABLE DOCUMENTATION
# =========================================================================

# data_wide:
# - subject_nr         : participant number
# - group              : randomized/preset order group; A = exe first, B = img first
# - sex                : participant sex; m = male, f = female, d = diverse
# - age                : participant age
# - handedness         : participant handedness; l = left, r = right, b = both (ambidextrous)
# - language           : selected experiment language
# - fam_accuracy       : familiarization accuracy
# - IDs                : selected movement difficulty set, from selected_ids
# - n_reps             : selected number of repetitions per ID
# - total_trial_nr     : maximum logged trial number per participant
# - first_condition    : first CRFT condition; "exe" or "img"
# - CC_exe             : number of comprehension check attempts execution (1 = correct on first attempt)
# - CC_img             : number of comprehension check attempts imagery (1 = correct on first attempt)
# - screen_touched_exe : percentage of execution test-block trials with a touch
# - screen_touched_img : percentage of imagery test-block trials with a touch
# - MIA_exe            : standardized log(MT) ~ current_trial_id slope in execution
# - MIA_img            : standardized log(MT) ~ current_trial_id slope in imagery
# - MIA_score          : absolute positive-ratio deviation between MIA_exe and MIA_img
#
# data_long:
# - subject_nr        : participant number
# - current_condition : execution or imagery condition
# - block_kind        : practice or testblock indicator
# - current_testbl    : testblock number, from n_testbl
# - current_trial     : trial number, from current_trial_nr
# - current_trial_id  : movement difficulty ID of the trial
# - movement_nr       : movement-time position, 1 to 5
# - MT                : movement time, from mt_1 to mt_5
#
# Notes:
# - screen_touched is read internally from the raw CSV data only for the
#   participant-level summary variables in data_wide.
# - screen_touched is not retained in data_long.
# - The current MIA calculation uses positive test-block MT values only.
# - No final data-quality exclusion or outlier removal is applied yet.


# =========================================================================
# SAVE RESULTS
# =========================================================================

output_file <- "data.rdata"

save(
  data_wide,
  data_long,
  file = output_file
)

message(
  "Saved data_wide and data_long to: ",
  file.path(normalizePath(getwd()), output_file)
)
