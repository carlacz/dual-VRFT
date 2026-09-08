# CHRONOMETRIC RADIAL FITTS' TASK (CRFT)

**Author:** Carla Czilczer, 07/09/2026  
**Software used:** PsychoPy 2025.1.1
**Experiment Type:** Local  
**Input device:** Touchscreen with active stylus only  
**Languages supported:** English (EN) = default, German (DE), Spanish (ES), and French (FR). Further languages can be added, which requires updating the `.xlsx` files (see [language localization](#language-localization)).  

---------------------------------------
## GENERAL INSTRUCTIONS

This experiment is built using [PsychoPy](https://www.psychopy.org/) (Builder) 2025.1.1 and is intended for **local execution**. Participants run the experiment directly on the experiment computer. No internet connection is required. Please check the version you are using, as older PsychoPy versions might crash or behave unexpectedly.  

If you are unfamiliar with PsychoPy, please refer to the [documentation](https://www.psychopy.org/documentation.html) on their website. This README specifically details the structure and customization of this **MBRT** implementation.

---------------------------------------
## SETUP INSTRUCTIONS

To edit or run this task, you need to have **PsychoPy** installed.  

PsychoPy exports results directly as `.csv` plus `.log` / `.psydat` (depending on run mode).
A script for data preparation in [R](https://www.r-project.org/) (4.5.2) is provided.

**Step-by-step instructions:**
1. **Download** and unzip the repository to a dedicated folder.
2. **Open PsychoPy**, then open the experiment file `MBRT_local.psyexp` in Builder.
3. Click the green **Run** button to start the experiment.
4. Participants **complete** the experiment locally.
5. Data is automatically **saved** into the `data/` folder.
6. **Process the data** using the provided `data-prep.R` script.


The movement difficulty values in this implementation are, differing from the implementation used by [Czilczer et al. (2026)](https://doi.org/10.3758/s13428-026-03124-8):

`2.47, 3.38, 4.30, 5.35, 6.34`

---------------------------------------
## LANGUAGE LOCALIZATION

This experiment uses external spreadsheet files to manage text and translations. This makes adding new languages relatively easy, but strict formatting rules apply.

The language can be selected via the PsychoPy startup dialog (Experiment Info). The experiment then uses the corresponding _ISO_code_ (e.g., `EN`, `DE`) to retrieve the corresponding text from columns in the external message sheet.

Available options: 
**English** (Default)<br>• German<br>• French<br>• Spanish

### Adding a new language

#### 1. Open the relevant files
- `language_localiser.xlsx`
- `messages.xlsx`
- `instructions_execution.xlsx`
- `instructions_imagery.xlsx`

#### 2. Extend `language_localiser.xlsx` by adding a new row

The file must contain the columns:
- `language`
- `ISO_code`

Example:

| language | ISO_code |
| :--- | :--- |
| English | EN |
| German | DE |

Add your new language (e.g., Italian) in a **new row**:

| language | ISO_code |
| :--- | :--- |
| English | EN |
| German | DE |
| Italian | IT |

#### 3. Extend `messages.xlsx`, `instructions_execution.xlsx`, `instructions_imagery.xlsx` by adding a new column

Example  `messages.xlsx`: The file must contain a `message` column (variable names used inside PsychoPy), and one column per language (named by _ISO_code_)

| message | EN | DE |
| :--- | :--- | :--- |
| welcome_msg | Welcome to the task! | Willkommen zur Aufgabe! |
| adv_msg | Press SPACE to continue | Drücken Sie SPACE zum Fortfahren |

Add a **new column** using the ISO code (`IT`) and enter translations:

| message | EN | DE | IT |
| :--- | :--- | :--- | :--- |
| welcome_msg | Welcome to the task! | Willkommen zur Aufgabe! | Benvenuti al compito! |
| adv_msg | Press SPACE to continue | Drücken Sie die LEERTASTE | Premi SPAZIO per continuare |

⚠️ Do this consistently for **all** message keys used by the experiment!

### 4. Update the experiment
1. Open `CRFT_local.psyexp`
2. Go to **Experiment Settings** (cogwheel icon) → Basic → Experiment info
3. Update the `language` entry by adding your new language name (e.g., `Italian`). It must exactly match the entry in `Language_localiser.xlsx`.
4. Save the experiment.

---

> ⚠️ **Important:** Do **not** change folder or file names. Do not rename variables. Do not move files after decompressing the repository. The experiment depends on exact paths and identifiers. Moving or renaming files may cause crashes.

---------------------------------------
## TECHNICAL DETAILS

The decompressed repository includes the following files and subfolders:

* `CRFT_local.psyexp`: The main experiment file; needed to run the task and change experiment settings.
* `language_localiser.xlsx`: Configuration file for language selection (language + ISO code).
* `messages.xlsx`: Task messages, comprehension-check text, questions and translations for the demographics forms, ...
* `instructions_execution.xlsx`: Condition-specific task-instructions including formatting
* `instructions_imagery.xlsx`: Condition-specific task-instructions including formatting
* **Folder** `images`: Image files used in the experiment (visual materials for instructions and task-related displays).
* **ZIP-file** `crft_images.zip`: `.png` files for all visual stimuli.
* **Folder** `data`: 
	* Folder designated for storing the `.csv` files (one per participant/run).
	* `data-prep.R`: R script that reads all `*.csv` files automatically, generates `data.rdata`, and stores it in the `data` folder. 
	* `data.rdata` contains `data_long` and `data_wide`.

### Stylus response collection

The current CRFT implementation is designed for a touchscreen with active stylus:

* The stylus is handled as a touchscreen/mouse-like primary click response.
* The timing measure is defined by space-bar events, while screen contact (during execution and imagery) is available as a trial-level control variable (e.g., data quality check).

### Disable demographic questions

The experiment includes Age, Gender, and Handedness questions by default. These support normative data collection.

If you do not want to collect demographics:

1. Click `demographics` routine
2. Open **Routine settings**
3. In **Testing** tab → click **Disable Routine**
4. Save the experiment

---------------------------------------
## PARTICIPANT WORKFLOW:

The participant workflow starts after the experiment settings have been selected.
1. **Experiment settings:** Language, task settings, condition order, and related options are selected.
2. **Demographics:** Participants complete a basic form (age, sex, handedness).
3. **Stylus instructions:** Participants are informed about how to use the touchscreen and active stylus.
4. **Familiarization task:** Participants tap targets of varying sizes that appear successively on the screen and receive feedback on their tapping accuracy (~2 minutes including instructions).
5. **First condition:** Instructions, multiple-choice comprehension check (repeats until correct response is given), practice block (five trials), testblock (20 trials) for either execution or imagery.
6. **Second condition:** Instructions, multiple-choice comprehension check (repeats until correct response is given), practice block (five trials), testblock (20 trials) for the remaining condition.
7. **Completion:** Final completion screen.

#### CRFT trial procedure
The sequence of a single CRFT trial is as follows:
1. **Trial start display:**  
   * In the execution condition, the participant taps the orange central start circle with the stylus.  
   * In the imagery condition, the participant presses the space bar.
2. **Countdown:** A three-second countdown is presented.
3. **Movement sequence:** The participant marks the sequence using 11 space-bar presses.  
   * In execution, participants physically tap the displayed circles with the stylus while simultaneously pressing the space bar.
   * In imagery, participants imagine the tapping sequence while pressing the space bar.
4. **Trial completion:** The active sequence ends after the 11th space-bar press.

---------------------------------------
## OUTPUT

All data is saved locally inside the `data/` folder.

Each run generates:

- `.csv` data file
- `.log`
- `.psydat`

---------------------------------------

The provided `data-prep.R` script is designed to read all `.csv` files in the the `data` folder, extract relevant observations from the CRFT test blocks, and save the processed data as `data.rdata` in the `data` folder.

**To run the data preparation**, open `data-prep.R` and **source** the script.

The script will generate `data.rdata`, which contains two dataframes: `data_long_tbl` (trial-level CRFT test data) and `data_wide` (demographics and summary data).

> **Note:** This script relies on the specified output structure. If modifications were made beyond the configurable experiment settings, the code may need adaptation. Raw data should always be inspected and cleaned of outliers or errors prior to statistical analysis.


### Variable Documentation

#### 1. Movement Time Data (`data_long`)
*Contains five movement time rows per completed CRFT trial; practice and test trials remain distinguishable through `block_kind`.*

| Variable Name | Type | Description |
| :--- | :--- | :--- |
| `source_file` | character | PsychoPy output file/run. |
| `subject_nr` | character | Participant ID. |
| `current_condition` | character | Current condition (`execution` or `imagery`). |
| `block_kind` | character | Practice or test block indicator. |
| `current_block` | numeric | CRFT block number (`1` to `4`). |
| `current_trial` | numeric | Trial number within the current block. |
| `ID` | numeric | Movement difficulty index from the conditions file (`0` to `4`). |
| `movement_nr` | numeric | Movement time position within the trial (`1` to `5`). |
| `MT` | numeric | Movement time in seconds. |

#### 2. Participant-Level Data (`data_wide`)
*Contains one row per participant/run.*

| Variable Name | Type | Description |
| :--- | :--- | :--- |
| `source_file` | character | PsychoPy output file/run. |
| `subject_nr` | character | Participant ID. |
| `group` | character | Counterbalancing group (`counterbalance.group` in PsychoPy). |
| `handedness` | character | Selected participant handedness. |
| `language` | character | Selected experiment language. |
| `order` | numeric | Condition order (`0` = execution first; `1` = imagery first). |
| `first_condition` | character | First CRFT condition (`exe` or `img`). |
| `CC_exe` | numeric | Comprehension-check attempt number for execution. |
| `CC_img` | numeric | Comprehension-check attempt number for imagery. |
| `n_practice_exe` | numeric | Number of completed execution practice trials. |
| `n_test_exe` | numeric | Number of completed execution test trials. |
| `n_practice_img` | numeric | Number of completed imagery practice trials. |
| `n_test_img` | numeric | Number of completed imagery test trials. |
| `total_crft_trials` | numeric | Total number of completed CRFT trials. |
| `complete` | logical | Indicates whether all 50 CRFT trials were completed (`TRUE` or `FALSE`). |
| `MIA_exe` | numeric | Standardized `log(MT) ~ ID` slope for execution. |
| `MIA_img` | numeric | Standardized `log(MT) ~ ID` slope for imagery. |
| `MIA_score` | numeric | Absolute positive-ratio deviation between `MIA_exe` and `MIA_img` (`abs(MIA_exe / MIA_img - 1)`), calculated if the ratio is positive. |


#### MIA-score calculation

The current data-preparation script calculates separate standardized slopes for execution and imagery from positive movement times in test blocks only:

```text
MIA_exe: standardized slope of log(MT) ~ current_trial_id in execution
MIA_img: standardized slope of log(MT) ~ current_trial_id in imagery

MIA_score = abs(MIA_exe / MIA_img - 1)
```

The score is calculated only when both slopes can be estimated and the ratio is positive. Lower values indicate more similar execution and imagery slopes.

-----

PsychoPy version updates may require adjustments.  Developers are not responsible for adapting the task to every use case.  
Before collecting data, always test the experiment and check the data output.
Contributions are welcome.

---------------------------------------
## REFERENCE

Please cite [Czilczer et al. (2026)](https://doi.org/10.31234/osf.io/9xjfb_v1) when using this resource.


## ACKNOWLEDGEMENT

Files included in this PsychoPy repository have been adapted from https://github.com/mmorenoverdu/CRFT.

