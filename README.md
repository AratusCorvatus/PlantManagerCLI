# PlantManagerCLI - A Bash Plant Observation Logger

PlantManagerCLI is a command-line Bash script designed for easy tracking of plant care and observation data. It's perfect for hobbyist gardeners, hydroponics enthusiasts, or anyone wanting to keep simple, organized notes on their plants. All data is stored locally in human-readable text files.

## Features

* **Interactive Menu:** Easy-to-navigate, colorful (if `tput` is supported) menu system.
* **Dynamic Plant Containers:** Add, name, and manage an unlimited number of plant containers. No fixed limits!
* **Comprehensive Data Tracking:** Log various details for each plant, including:
    * Plant Species
    * Date Planted
    * Development Stage (Seed, Germination, Seedling, etc.)
    * Watering Information (Last Watered Date, Water Level Notes)
    * Nutrient Information (Last Application, Brand, Dosage, N-P-K notes, Micros)
    * Environment (Light Exposure, Substrate)
    * General Notes
* **CRUD Operations:**
    * **C**reate: Add new plant containers with custom names.
    * **R**ead: View detailed data for any plant container.
    * **U**pdate: Modify existing data for any plant container.
    * **D**elete: Remove plant container data (with confirmation).
* **Rename Containers:** Easily rename plant containers; the script handles file renaming and updates internal references.
* **Persistent Storage:** Data is saved in simple `key=value` text files in a dedicated directory.
* **Activity Logging:** All significant actions (script start/end, data changes, creations, deletions, renames) are logged to a central log file.
* **User-Friendly Prompts:** Suggestions for current values and date formats to streamline data entry.
* **Filename Sanitization:** Ensures container names are safe for use as filenames.
* **Color-Coded Output:** Uses `tput` for enhanced readability if available, with a graceful fallback for terminals without color support.

## Requirements

* **Bash:** The script is written for the Bash shell (common on Linux and macOS).
* **Standard Unix Utilities:** Uses common commands like `grep`, `cut`, `mv`, `rm`, `date`, `mkdir`, `touch`, `mktemp`, `sort`.
* **`tput` (Optional):** For colorized output. If not available, the script will run in monochrome.

## Setup

1.  **Download:** Place the `plant_observer.sh` (or your chosen name for it, e.g., `plantmanagercli.sh`) script in your desired directory (e.g., `~/scripts/`).
2.  **Make Executable:**
    ```bash
    chmod +x ~/scripts/plantmanagercli.sh
    ```
3.  **Run the Script:**
    ```bash
    ~/scripts/plantmanagercli.sh
    ```

Upon first run, the script will automatically create the necessary data directory (`~/Desktop/plant_tracker_data/`) and log file (`~/Desktop/plant_tracker_data/plant_tracker_log.txt`) if they don't already exist.

## Configuration

The script uses the following default paths:

* **Script Directory (assumed for alias):** `~/scripts/`
* **Data Directory:** `~/Desktop/plant_tracker_data/`
    * Individual plant data files are stored here (e.g., `My-Monstera_data.txt`).
* **Log File:** `~/Desktop/plant_tracker_data/plant_tracker_log.txt`

These paths are defined as variables at the beginning of the script and can be modified if needed:
* `DATA_DIR`
* `LOG_FILE`

## Usage

Run the script from your terminal. You will be presented with the main menu:



=== Plant Observation Script ===
Please choose an option:
View Data for a Plant Container
Update Data for a Plant Container
Add New Plant Container
Rename Plant Container
Delete Plant Container
Exit
Enter your choice (0-5):
Simply enter the number corresponding to your desired action.

* **View Data:** Select a plant container to display its current recorded data.
* **Update Data:** Select a plant container and go through the prompts to update its information. Press Enter to keep existing values.
* **Add New Plant Container:** Create a new data file for a new plant. You'll be asked to provide a name for the container.
* **Rename Plant Container:** Select an existing container and provide a new name. The script handles renaming the data file and updating the display name.
* **Delete Plant Container:** Select a container to delete. You will be asked for confirmation before the data file is permanently removed.
* **Exit:** Closes the script.

## Data File Format

Each plant container's data is stored in a separate text file (e.g., `Rose-Bush_data.txt`) within the `DATA_DIR`. The format is a simple `key=value` pair per line:



DATE_PLANTED=2025-05-01
DEVELOPMENT_STAGE=Vegetative Growth
GENERAL_NOTES=Looking healthy.
LAST_NUTRIENT_APPLICATION_DATE=2025-05-07
LAST_WATERED_DATE=2025-05-08
LIGHT_EXPOSURE=South-facing window
NUTRIENT_BRAND_NAME=BloomMax
PLANT_SPECIES=Miniature Rose
SUBSTRATE=Potting Mix
USER_GIVEN_NAME=Rose Bush
WATER_LEVEL_NOTES=Soil moist
The `USER_GIVEN_NAME` key stores the human-friendly name you provide, while the filename itself is a sanitized version of this name.

## Contributing

Suggestions and improvements are welcome! Feel free to fork the repository and submit a pull request. You can also open an issue if you find a bug or have an idea for a new feature.

## License

This project is open source.


