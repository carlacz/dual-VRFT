# -------------------------------------------------------------------------
# Title:    Data preparation - CRFT PsychoPy local
# Author:   Carla Czilczer
# Date:     07.09.2026
#
# Purpose:
# - data_wide: one row per PsychoPy output file / participant run
# - data_long: five movement-time rows per CRFT trial
# - distinguish practice/test and execution/imagery
# - calculate participant-level MIA scores from test trials
#
# Expected experiment structure:
# - Block 1: practice, first condition, 5 trials
# - Block 2: test,     first condition, 20 trials
# - Block 3: practice, second condition, 5 trials
# - Block 4: test,     second condition, 20 trials
# - 50 CRFT trials total; 40 test trials total
# -------------------------------------------------------------------------


# =========================================================================
# PREPARATIONS
# =========================================================================

rm(list = ls())


# =========================================================================
# IMPORT CSV FILES
# =========================================================================

files <- list.files(pattern = ".*csv", full.names = TRUE)

data_list <- lapply(files, function(f) {
  
  d <- read.csv(
    f,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  
  if (nrow(d) == 0) {
    return(NULL)
  }
  
  d$source_file <- basename(f)
  d$participant <- as.character(d$participant)
  d
})

df <- dplyr::bind_rows(data_list)


# =========================================================================
# PREPARE BLOCK AND CONDITION VARIABLES
# =========================================================================

# PsychoPy counts blocks from 0 to 3.
df$current_block <- as.numeric(df$blocks_loop.thisN) + 1

# Blocks 1 and 3 are practice; blocks 2 and 4 are test.
df$block_kind <- NA_character_
df$block_kind[df$current_block %in% c(1, 3)] <- "practice"
df$block_kind[df$current_block %in% c(2, 4)] <- "test"

# order 0 = execution first
# order 1 = imagery first
df$current_condition <- NA_character_

df$current_condition[
  df$order == 0 & df$current_block %in% c(1, 2)
] <- "execution"

df$current_condition[
  df$order == 0 & df$current_block %in% c(3, 4)
] <- "imagery"

df$current_condition[
  df$order == 1 & df$current_block %in% c(1, 2)
] <- "imagery"

df$current_condition[
  df$order == 1 & df$current_block %in% c(3, 4)
] <- "execution"


# =========================================================================
# CREATE data_long
# =========================================================================

# One row in the raw PsychoPy file per completed CRFT trial.
trial_rows <- df[
  !is.na(df$difficulty_index) &
    !is.na(df$move_durations) &
    !is.na(df$current_block),
]

# Split the five movement times stored in move_durations.
data_long_list <- lapply(seq_len(nrow(trial_rows)), function(i) {
  
  mt <- gsub("\\[|\\]", "", trial_rows$move_durations[i])
  mt <- as.numeric(trimws(strsplit(mt, ",", fixed = TRUE)[[1]]))
  
  data.frame(
    source_file = trial_rows$source_file[i],
    subject_nr = as.character(trial_rows$participant[i]),
    current_condition = trial_rows$current_condition[i],
    block_kind = trial_rows$block_kind[i],
    current_block = trial_rows$current_block[i],
    current_trial = as.numeric(trial_rows$trials_loop.thisN[i]) + 1,
    ID = as.numeric(trial_rows$difficulty_index[i]),
    movement_nr = 1:5,
    MT = mt,
    stringsAsFactors = FALSE
  )
})

data_long <- do.call(rbind, data_long_list)


# =========================================================================
# CREATE data_wide
# =========================================================================

# Use the source file as run identifier so separate test runs with the same
# participant number are not merged.
runs <- unique(df$source_file)

data_wide_list <- lapply(runs, function(run) {
  
  d_run <- df[df$source_file == run, ]
  d_long <- data_long[data_long$source_file == run, ]
  
  
  # Participant number
  x <- d_run$participant[!is.na(d_run$participant)]
  subject_nr <- if (length(x) > 0) as.character(x[1]) else NA_character_
  
  
  # Counterbalance group
  x <- d_run$counterbalance.group[!is.na(d_run$counterbalance.group)]
  group <- if (length(x) > 0) as.character(x[1]) else NA_character_
  
  
  # Handedness
  x <- d_run$handedness[!is.na(d_run$handedness)]
  handedness <- if (length(x) > 0) as.character(x[1]) else NA_character_
  
  
  # Language
  x <- d_run$language_code[!is.na(d_run$language_code)]
  language <- if (length(x) > 0) as.character(x[1]) else NA_character_
  
  
  # Order
  x <- d_run$order[!is.na(d_run$order)]
  order <- if (length(x) > 0) as.numeric(x[1]) else NA_real_
  
  if (!is.na(order) && order == 0) {
    first_condition <- "exe"
  } else if (!is.na(order) && order == 1) {
    first_condition <- "img"
  } else {
    first_condition <- NA_character_
  }
  
  
  # -----------------------------------------------------------------------
  # Comprehension checks
  #
  # PsychoPy stores the final repetition index:
  # thisRepN = 0 -> 1 attempt
  # thisRepN = 1 -> 2 attempts
  # etc.
  # -----------------------------------------------------------------------
  
  cc_exe <- d_run$comp_check_loop.thisRepN[
    !is.na(d_run$comp_check_loop.thisRepN) &
      d_run$current_condition == "execution"
  ]
  
  cc_img <- d_run$comp_check_loop.thisRepN[
    !is.na(d_run$comp_check_loop.thisRepN) &
      d_run$current_condition == "imagery"
  ]
  
  CC_exe <- if (length(cc_exe) > 0) max(cc_exe) + 1 else NA_real_
  CC_img <- if (length(cc_img) > 0) max(cc_img) + 1 else NA_real_
  
  
  # -----------------------------------------------------------------------
  # Trial counts
  # -----------------------------------------------------------------------
  
  n_practice_exe <- nrow(d_long[
    d_long$current_condition == "execution" &
      d_long$block_kind == "practice",
  ]) / 5
  
  n_test_exe <- nrow(d_long[
    d_long$current_condition == "execution" &
      d_long$block_kind == "test",
  ]) / 5
  
  n_practice_img <- nrow(d_long[
    d_long$current_condition == "imagery" &
      d_long$block_kind == "practice",
  ]) / 5
  
  n_test_img <- nrow(d_long[
    d_long$current_condition == "imagery" &
      d_long$block_kind == "test",
  ]) / 5
  
  
  # -----------------------------------------------------------------------
  # MIA scores
  #
  # Same analysis logic as in the previous CRFT data-prep:
  # standardized log(MT) ~ ID slope, test trials only.
  # ID is taken directly from difficulty_index (0-4).
  # -----------------------------------------------------------------------
  
  exe <- d_long[
    d_long$current_condition == "execution" &
      d_long$block_kind == "test" &
      !is.na(d_long$MT) &
      d_long$MT > 0,
  ]
  
  img <- d_long[
    d_long$current_condition == "imagery" &
      d_long$block_kind == "test" &
      !is.na(d_long$MT) &
      d_long$MT > 0,
  ]
  
  if (nrow(exe) > 0 && length(unique(exe$ID)) > 1) {
    MIA_exe <- unname(coef(
      lm(scale(log(MT)) ~ scale(ID), data = exe)
    )[2])
  } else {
    MIA_exe <- NA_real_
  }
  
  if (nrow(img) > 0 && length(unique(img$ID)) > 1) {
    MIA_img <- unname(coef(
      lm(scale(log(MT)) ~ scale(ID), data = img)
    )[2])
  } else {
    MIA_img <- NA_real_
  }
  
  if (
    !is.na(MIA_exe) &&
    !is.na(MIA_img) &&
    MIA_img != 0 &&
    MIA_exe / MIA_img > 0
  ) {
    MIA_score <- abs(MIA_exe / MIA_img - 1)
  } else {
    MIA_score <- NA_real_
  }
  
  
  # -----------------------------------------------------------------------
  # Participant/run row
  # -----------------------------------------------------------------------
  
  data.frame(
    source_file = run,
    subject_nr = subject_nr,
    group = group,
    handedness = handedness,
    language = language,
    order = order,
    first_condition = first_condition,
    CC_exe = CC_exe,
    CC_img = CC_img,
    n_practice_exe = n_practice_exe,
    n_test_exe = n_test_exe,
    n_practice_img = n_practice_img,
    n_test_img = n_test_img,
    total_crft_trials =
      n_practice_exe +
      n_test_exe +
      n_practice_img +
      n_test_img,
    complete =
      n_practice_exe == 5 &
      n_test_exe == 20 &
      n_practice_img == 5 &
      n_test_img == 20,
    MIA_exe = MIA_exe,
    MIA_img = MIA_img,
    MIA_score = MIA_score,
    stringsAsFactors = FALSE
  )
})

data_wide <- do.call(rbind, data_wide_list)


# =========================================================================
# VARIABLE DOCUMENTATION
# =========================================================================

# data_wide:
# - source_file         : PsychoPy output file / run
# - subject_nr          : participant number
# - group               : counterbalance.group from PsychoPy
# - handedness          : selected handedness
# - language            : selected language
# - order               : 0 = execution first; 1 = imagery first
# - first_condition     : exe or img
# - CC_exe              : comprehension-check attempts in execution
# - CC_img              : comprehension-check attempts in imagery
# - n_practice_exe      : completed execution practice trials
# - n_test_exe          : completed execution test trials
# - n_practice_img      : completed imagery practice trials
# - n_test_img          : completed imagery test trials
# - total_crft_trials   : total completed CRFT trials
# - complete            : TRUE if all 50 CRFT trials were completed
# - MIA_exe             : standardized log(MT) ~ ID slope in execution
# - MIA_img             : standardized log(MT) ~ ID slope in imagery
# - MIA_score           : abs(MIA_exe / MIA_img - 1), if ratio > 0
#
# data_long:
# - source_file         : PsychoPy output file / run
# - subject_nr          : participant number
# - current_condition   : execution or imagery
# - block_kind          : practice or test
# - current_block       : block number 1-4
# - current_trial       : trial number within block
# - ID                  : difficulty_index from conditions file, 0-4
# - movement_nr         : movement 1-5
# - MT                  : movement time in seconds


# =========================================================================
# SAVE RESULTS
# =========================================================================

save(
  data_wide,
  data_long,
  file = "data.rdata"
)
