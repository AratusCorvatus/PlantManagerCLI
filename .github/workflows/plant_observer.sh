#!/bin/bash

# Script Name: plant_observer.sh
# Location: ~/scripts/plant_observer.sh
# Purpose: Track information about various plants in uniquely named data files.
# Data Storage: ~/Desktop/plant_tracker_data/
# Log File: ~/Desktop/plant_tracker_data/plant_tracker_log.txt

# --- Configuration Variables ---
SCRIPT_DIR="${HOME}/scripts"
DATA_DIR="${HOME}/Desktop/plant_tracker_data"
LOG_FILE="${DATA_DIR}/plant_tracker_log.txt"
DATE_FORMAT="%Y-%m-%d" # For display and consistent input
DATA_FILE_SUFFIX="_data.txt" # Suffix for all plant data files

# --- Color Definitions (using tput) ---
# Check if tput is available and terminal supports colors
if command -v tput >/dev/null && tput setaf 1 >/dev/null 2>&1; then
    BRIGHT_GREEN=$(tput setaf 10) # Headers, footers
    GREEN=$(tput setaf 2)         # Success messages, section headers
    YELLOW=$(tput setaf 3)        # Prompts, warnings
    BLUE=$(tput setaf 4)          # Informational text
    MAGENTA=$(tput setaf 5)       # Data keys
    CYAN=$(tput setaf 6)          # Data values
    WHITE=$(tput setaf 7)         # Default text
    BOLD=$(tput bold)
    RESET=$(tput sgr0)
else # Fallback if tput is not available or colors are not supported
    BRIGHT_GREEN=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    WHITE=""
    BOLD=""
    RESET=""
fi

# --- Utility Functions ---

# Function to log messages
# Args: $1 (string) Log message
log_event() {
    local message="$1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $message" >> "$LOG_FILE"
}

# Function to ensure setup (directories, log file)
setup_environment() {
    mkdir -p "$DATA_DIR"
    touch "$LOG_FILE"
    log_event "Script started. Data directory: $DATA_DIR"
}

# Function to get a value for a key from a data file
# Args: $1 (string) File path
# Args: $2 (string) Key
get_value() {
    local file_path="$1"
    local key="$2"
    if [[ -f "$file_path" ]]; then
        grep "^${key}=" "$file_path" | cut -d'=' -f2-
    fi
}

# Function to update or add a key-value pair in a data file
# Args: $1 (string) File path
# Args: $2 (string) Key
# Args: $3 (string) Value
update_or_add_value() {
    local file_path="$1"
    local key="$2"
    local value="$3"
    local temp_file
    temp_file=$(mktemp)

    touch "$file_path" # Ensure file exists

    # Remove existing key line (if any) and append new key=value
    grep -v "^${key}=" "$file_path" > "$temp_file" 2>/dev/null
    echo "${key}=${value}" >> "$temp_file"
    
    # Sort for consistent order (optional, but nice for readability)
    if [[ -s "$temp_file" ]]; then # only sort if file is not empty
        sort "$temp_file" -o "$temp_file"
    fi

    mv "$temp_file" "$file_path"
}

# Function to prompt user for a piece of information and update it
# Args: $1 (string) File path for the plant container's data
# Args: $2 (string) Key to update
# Args: $3 (string) Prompt message for the user
# Args: $4 (string, optional) Suggested default value if no current value exists
prompt_with_suggestion() {
    local file_path="$1"
    local key_name="$2"
    local prompt_message="$3"
    local suggestion_if_empty="${4:-}" 

    local existing_value
    existing_value=$(get_value "$file_path" "$key_name")

    local prompt_default="$existing_value"
    if [[ -z "$existing_value" && -n "$suggestion_if_empty" ]]; then
        prompt_default="$suggestion_if_empty"
    fi

    local user_input
    # Prompt for input
    echo -n -e "${YELLOW}${prompt_message} ${CYAN}[${prompt_default}]${YELLOW}: ${RESET}"
    read -r user_input

    # If user enters something, use it. Otherwise, use the prompt_default.
    local final_value="${user_input:-$prompt_default}"

    update_or_add_value "$file_path" "$key_name" "$final_value"
    echo -e "  ${MAGENTA}${key_name}${RESET} set to: ${CYAN}'${final_value}'${RESET}"
    log_event "Plant data: $file_path - $key_name changed to '$final_value'"
}

# Function to sanitize a string for use as a filename
# Replaces spaces with hyphens and removes most non-alphanumeric characters
# Args: $1 (string) Input string
sanitize_filename() {
    local name="$1"
    name="${name// /-}" # Replace spaces with hyphens
    name="${name//[^a-zA-Z0-9_-]/}" # Remove disallowed characters
    echo "$name"
}

# --- Core Logic Functions ---

# Function to add a new plant container
add_new_plant_container() {
    echo ""
    echo -e "${BRIGHT_GREEN}--- Add New Plant Container ---${RESET}"
    local container_name_raw
    local container_name_sanitized
    local container_file_path

    while true; do
        echo -n -e "${YELLOW}Enter a name for the new plant container (e.g., 'Monstera Window Pot', 'Test Tube Alpha'): ${RESET}"
        read -r container_name_raw

        if [[ -z "$container_name_raw" ]]; then
            echo -e "${YELLOW}Container name cannot be empty. Please try again.${RESET}" >&2
            continue
        fi

        container_name_sanitized=$(sanitize_filename "$container_name_raw")
        if [[ -z "$container_name_sanitized" ]]; then
            echo -e "${YELLOW}Invalid container name after sanitization. Please use letters, numbers, spaces, or hyphens.${RESET}" >&2
            continue
        fi
        
        container_file_path="${DATA_DIR}/${container_name_sanitized}${DATA_FILE_SUFFIX}"

        if [[ -f "$container_file_path" ]]; then
            echo -e "${YELLOW}A plant container data file named '${container_name_sanitized}${DATA_FILE_SUFFIX}' already exists.${RESET}" >&2
            echo -n -e "${YELLOW}Do you want to try a different name? (y/N): ${RESET}"
            read -r confirm_retry
            if [[ "${confirm_retry,,}" != "y" ]]; then
                echo -e "${BLUE}Add new plant container cancelled.${RESET}"
                return 1
            fi
        else
            break # Valid, non-existing name
        fi
    done

    touch "$container_file_path" # Create the empty file
    update_or_add_value "$container_file_path" "USER_GIVEN_NAME" "$container_name_raw" # Store original name
    log_event "Created new plant container data file: $container_file_path for name: $container_name_raw"
    echo -e "${GREEN}Successfully created data file for '${container_name_raw}' (filename: ${container_name_sanitized}${DATA_FILE_SUFFIX}).${RESET}"
    
    echo -n -e "${YELLOW}Do you want to add initial data for '${container_name_raw}' now? (Y/n): ${RESET}"
    read -r confirm_add_data
    if [[ "${confirm_add_data,,}" != "n" ]]; then
        manage_plant_container_data "$container_name_sanitized" # Pass basename
    fi
    return 0
}

# Function to manage data for a selected plant container
# Args: $1 (string) Base name of the plant container data file (without suffix)
manage_plant_container_data() {
    local container_basename="$1"
    local container_file="${DATA_DIR}/${container_basename}${DATA_FILE_SUFFIX}"
    local user_given_name
    user_given_name=$(get_value "$container_file" "USER_GIVEN_NAME")
    if [[ -z "$user_given_name" ]]; then # Fallback if USER_GIVEN_NAME is not set
        user_given_name="$container_basename" 
    fi

    local current_date
    current_date=$(date +"$DATE_FORMAT")

    echo ""
    echo -e "${BRIGHT_GREEN}--- Updating Data for: ${CYAN}${user_given_name}${RESET} ---${RESET}"
    echo -e "${BLUE}Data file: ${WHITE}${container_file}${RESET}"
    echo -e "${BLUE}Press Enter to keep the current value (shown in brackets).${RESET}"
    
    echo ""
    echo -e "${GREEN}--- Basic Information ---${RESET}"
    prompt_with_suggestion "$container_file" "PLANT_SPECIES" "Plant Species"
    prompt_with_suggestion "$container_file" "DATE_PLANTED" "Date Planted ($DATE_FORMAT)" "$current_date"

    # Development Stage selection
    local stages=("Seed" "Germination" "Seedling/Sprout" "Vegetative Growth" "Budding" "Flowering" "Fruiting" "Dormant" "Other" "Clear Value")
    local current_stage
    current_stage=$(get_value "$container_file" "DEVELOPMENT_STAGE")
    echo -e "\n${YELLOW}Select Development Stage (current: '${CYAN}${current_stage}${YELLOW}'):${RESET}"
    
    PS3="${YELLOW}Enter number for stage: ${RESET}" 
    select stage_choice in "${stages[@]}"; do
        if [[ "$stage_choice" == "Clear Value" ]]; then
            update_or_add_value "$container_file" "DEVELOPMENT_STAGE" ""
            echo -e "  ${MAGENTA}DEVELOPMENT_STAGE${RESET} cleared."
            log_event "Plant data: $container_file - DEVELOPMENT_STAGE cleared"
            break
        elif [[ -n "$stage_choice" ]]; then
            update_or_add_value "$container_file" "DEVELOPMENT_STAGE" "$stage_choice"
            echo -e "  ${MAGENTA}DEVELOPMENT_STAGE${RESET} set to: ${CYAN}'${stage_choice}'${RESET}"
            log_event "Plant data: $container_file - DEVELOPMENT_STAGE changed to '$stage_choice'"
            break
        else
            echo -e "${YELLOW}Invalid selection. Please enter a number from the list.${RESET}" >&2
        fi
    done
    PS3="" # Reset PS3 prompt
    echo -e "${GREEN}--- End Basic Information ---${RESET}"

    echo "" 
    echo -e "${GREEN}--- Watering Information ---${RESET}"
    prompt_with_suggestion "$container_file" "LAST_WATERED_DATE" "Last Watered Date ($DATE_FORMAT)" "$current_date"
    prompt_with_suggestion "$container_file" "WATER_LEVEL_NOTES" "Water Level/Moisture Notes (e.g., 'topped up', 'soil dry 1 inch')"
    echo -e "${GREEN}--- End Watering Information ---${RESET}"
    
    echo "" 
    echo -e "${GREEN}--- Nutrient Information ---${RESET}"
    prompt_with_suggestion "$container_file" "LAST_NUTRIENT_APPLICATION_DATE" "Last Nutrient Application Date ($DATE_FORMAT)" "$current_date"
    prompt_with_suggestion "$container_file" "NUTRIENT_BRAND_NAME" "Nutrient Brand/Product Name (e.g., 'General Hydroponics Flora Series')"
    prompt_with_suggestion "$container_file" "NUTRIENT_DOSE_GENERAL" "General Dosage Used (e.g., '1 tsp/gallon', '0.5ml/L of each part')"
    
    echo "" 
    echo -e "${BLUE}Macronutrient Details (optional, enter amounts or concentrations if known):${RESET}"
    prompt_with_suggestion "$container_file" "NUTRIENT_NITROGEN_N_NOTES" "Nitrogen (N) details (e.g., 'Part A - 1ml', 'High N ratio')"
    prompt_with_suggestion "$container_file" "NUTRIENT_PHOSPHORUS_P_NOTES" "Phosphorus (P) details (e.g., 'Part B - 0.5ml', 'Bloom booster')"
    prompt_with_suggestion "$container_file" "NUTRIENT_POTASSIUM_K_NOTES" "Potassium (K) details (e.g., 'Part C - 0.5ml')"
    prompt_with_suggestion "$container_file" "NUTRIENT_MICROS_OTHER_NOTES" "Other Micronutrients/Additives (e.g., 'CalMag 0.25ml/L')"
    echo -e "${GREEN}--- End Nutrient Information ---${RESET}"

    echo "" 
    echo -e "${GREEN}--- Environment & Notes ---${RESET}"
    prompt_with_suggestion "$container_file" "LIGHT_EXPOSURE" "Light Exposure (e.g., 'South window, direct')"
    prompt_with_suggestion "$container_file" "SUBSTRATE" "Substrate (e.g., 'Water', 'LECA', 'Potting Mix')" "Water"
    prompt_with_suggestion "$container_file" "GENERAL_NOTES" "General Notes"
    echo -e "${GREEN}--- End Environment & Notes ---${RESET}"
    
    echo ""
    echo -e "${BRIGHT_GREEN}--- Data for ${CYAN}${user_given_name}${RESET} Updated ---${RESET}"
}

# Function to display data for a selected plant container
# Args: $1 (string) Base name of the plant container data file (without suffix)
display_plant_container_data() {
    local container_basename="$1"
    local container_file="${DATA_DIR}/${container_basename}${DATA_FILE_SUFFIX}"
    local user_given_name
    user_given_name=$(get_value "$container_file" "USER_GIVEN_NAME")
     if [[ -z "$user_given_name" ]]; then # Fallback if USER_GIVEN_NAME is not set
        user_given_name="$container_basename"
    fi

    echo ""
    echo -e "${BRIGHT_GREEN}--- Data for Plant Container: ${CYAN}${user_given_name}${RESET} ---${RESET}"
    if [[ -f "$container_file" ]]; then
        if [[ -s "$container_file" ]]; then # Check if file is not empty
            # Pretty print: replace '=' with ': ' and colorize
            while IFS='=' read -r key value; do
                # Ensure key is not empty before printing
                if [[ -n "$key" ]]; then
                     # Skip printing the internal USER_GIVEN_NAME key here for cleaner display
                     if [[ "$key" == "USER_GIVEN_NAME" ]]; then
                        continue
                     fi
                     echo -e "  ${MAGENTA}${key}${RESET}: ${CYAN}${value}${RESET}"
                fi
            done < "$container_file"
        else
            echo -e "${YELLOW}No data recorded for ${CYAN}${user_given_name}${YELLOW} yet.${RESET}"
        fi
    else
        echo -e "${YELLOW}No data file found for ${CYAN}${user_given_name}${YELLOW}. Use 'Update Data' or 'Add New Plant' to create it.${RESET}"
    fi
    echo -e "${BRIGHT_GREEN}-------------------------------------${RESET}"
    log_event "Viewed data for plant container: $user_given_name (file: $container_file)"
}

# Function to select a plant container from existing data files
# Returns the selected plant container's base filename (e.g., "My_Rose_Bush") or empty if selection is cancelled.
# The actual base filename is echoed to STDOUT for capture by command substitution.
# Prompts and menus are sent to STDERR to avoid being captured.
select_plant_container() {
    local prompt_message="$1"
    local plant_files=()
    local display_names=() # User-friendly names for selection

    # Find all data files and populate arrays
    # Using nullglob to prevent errors if no files match
    shopt -s nullglob
    for file_path in "${DATA_DIR}/"*${DATA_FILE_SUFFIX}; do
        local basename
        basename=$(basename "$file_path" "$DATA_FILE_SUFFIX")
        plant_files+=("$basename") # Store the base filename

        local user_given_name
        user_given_name=$(get_value "$file_path" "USER_GIVEN_NAME")
        if [[ -n "$user_given_name" ]]; then
            display_names+=("$user_given_name (File: $basename)")
        else
            display_names+=("$basename") # Fallback to basename if no user-given name
        fi
    done
    shopt -u nullglob # Reset nullglob

    if [[ ${#plant_files[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No plant data files found in ${DATA_DIR}.${RESET}" >&2
        echo -e "${BLUE}Use 'Add New Plant Container' to create one.${RESET}" >&2
        echo "" # Return empty to signify no selection possible
        return
    fi

    display_names+=("Cancel")

    echo -e "${YELLOW}${prompt_message}${RESET}" >&2 

    PS3="${YELLOW}Enter number for plant container (or 'Cancel'): ${RESET}"
    local chosen_basename="" # Variable to hold the result (base filename)

    select choice_str in "${display_names[@]}"; do
        if [[ "$choice_str" == "Cancel" ]]; then
            chosen_basename="" 
            break
        elif [[ -n "$choice_str" ]]; then
            # Find the index of the chosen display name
            for i in "${!display_names[@]}"; do
                if [[ "${display_names[$i]}" == "$choice_str" ]]; then
                    # Get the corresponding base filename from plant_files array
                    chosen_basename="${plant_files[$i]}"
                    break
                fi
            done
            break 
        else
            echo -e "${YELLOW}Invalid selection. Please enter a number from the list.${RESET}" >&2
        fi
    done
    PS3="" 
    
    echo "$chosen_basename" # Echo the chosen base filename
}

# Function to rename a plant container
rename_plant_container() {
    echo ""
    echo -e "${BRIGHT_GREEN}--- Rename Plant Container ---${RESET}"
    
    local old_basename
    old_basename=$(select_plant_container "Which plant container do you want to rename?")

    if [[ -z "$old_basename" ]]; then
        echo -e "${BLUE}Rename operation cancelled or no plant selected.${RESET}" >&2
        return 1
    fi

    local old_filepath="${DATA_DIR}/${old_basename}${DATA_FILE_SUFFIX}"
    local old_user_given_name
    old_user_given_name=$(get_value "$old_filepath" "USER_GIVEN_NAME")
    if [[ -z "$old_user_given_name" ]]; then
        old_user_given_name="$old_basename" # Fallback to basename
    fi

    echo -e "${BLUE}Selected container to rename: ${CYAN}${old_user_given_name}${RESET} (File: ${WHITE}${old_basename}${DATA_FILE_SUFFIX}${RESET})"

    local new_container_name_raw
    local new_container_name_sanitized
    local new_filepath

    while true; do
        echo -n -e "${YELLOW}Enter the new name for this plant container: ${RESET}"
        read -r new_container_name_raw

        if [[ -z "$new_container_name_raw" ]]; then
            echo -e "${YELLOW}New container name cannot be empty. Please try again.${RESET}" >&2
            continue
        fi

        new_container_name_sanitized=$(sanitize_filename "$new_container_name_raw")
        if [[ -z "$new_container_name_sanitized" ]]; then
            echo -e "${YELLOW}Invalid new container name after sanitization. Please use letters, numbers, spaces, or hyphens.${RESET}" >&2
            continue
        fi
        
        new_filepath="${DATA_DIR}/${new_container_name_sanitized}${DATA_FILE_SUFFIX}"

        if [[ "$new_container_name_sanitized" == "$old_basename" ]]; then
             echo -e "${YELLOW}The new name is the same as the old name. No changes made.${RESET}" >&2
             return 1 
        fi

        if [[ -f "$new_filepath" ]]; then
            echo -e "${YELLOW}A plant container data file named '${new_container_name_sanitized}${DATA_FILE_SUFFIX}' already exists.${RESET}" >&2
            echo -n -e "${YELLOW}Do you want to try a different name? (y/N): ${RESET}"
            read -r confirm_retry
            if [[ "${confirm_retry,,}" != "y" ]]; then
                echo -e "${BLUE}Rename operation cancelled.${RESET}"
                return 1
            fi
        else
            break # Valid, non-existing new name
        fi
    done

    # Perform the rename
    if mv "$old_filepath" "$new_filepath"; then
        # Update USER_GIVEN_NAME inside the newly renamed file
        update_or_add_value "$new_filepath" "USER_GIVEN_NAME" "$new_container_name_raw"
        log_event "Renamed plant container from '$old_basename' (user name: '$old_user_given_name') to '$new_container_name_sanitized' (user name: '$new_container_name_raw'). Old file: $old_filepath, New file: $new_filepath"
        echo -e "${GREEN}Successfully renamed '${old_user_given_name}' to '${new_container_name_raw}'.${RESET}"
        echo -e "${GREEN}Old filename: ${WHITE}${old_basename}${DATA_FILE_SUFFIX}${RESET} -> New filename: ${WHITE}${new_container_name_sanitized}${DATA_FILE_SUFFIX}${RESET}"
    else
        echo -e "${YELLOW}Error: Failed to rename the data file. Check permissions or logs.${RESET}" >&2
        log_event "Error: Failed to rename '$old_filepath' to '$new_filepath'."
        return 1
    fi
    return 0
}

# Function to delete a plant container
delete_plant_container() {
    echo ""
    echo -e "${BRIGHT_GREEN}--- Delete Plant Container ---${RESET}"
    
    local container_basename_to_delete
    container_basename_to_delete=$(select_plant_container "Which plant container do you want to DELETE?")

    if [[ -z "$container_basename_to_delete" ]]; then
        echo -e "${BLUE}Delete operation cancelled or no plant selected.${RESET}" >&2
        return 1
    fi

    local filepath_to_delete="${DATA_DIR}/${container_basename_to_delete}${DATA_FILE_SUFFIX}"
    local user_given_name_to_delete
    user_given_name_to_delete=$(get_value "$filepath_to_delete" "USER_GIVEN_NAME")
     if [[ -z "$user_given_name_to_delete" ]]; then # Fallback if USER_GIVEN_NAME is not set
        user_given_name_to_delete="$container_basename_to_delete"
    fi

    echo -e "${YELLOW}${BOLD}WARNING: You are about to delete all data for plant container:${RESET}"
    echo -e "${YELLOW}${BOLD}  Name: ${CYAN}${user_given_name_to_delete}${RESET}"
    echo -e "${YELLOW}${BOLD}  File: ${WHITE}${filepath_to_delete}${RESET}"
    echo -n -e "${YELLOW}${BOLD}This action cannot be undone. Are you sure you want to delete? (yes/NO): ${RESET}"
    read -r confirm_delete

    if [[ "${confirm_delete,,}" == "yes" ]]; then
        if rm "$filepath_to_delete"; then
            log_event "Deleted plant container: '$user_given_name_to_delete' (File: $filepath_to_delete)"
            echo -e "${GREEN}Successfully deleted plant container '${user_given_name_to_delete}'.${RESET}"
        else
            log_event "Error: Failed to delete file: $filepath_to_delete"
            echo -e "${YELLOW}Error: Could not delete file '${filepath_to_delete}'. Check permissions or logs.${RESET}" >&2
            return 1
        fi
    else
        echo -e "${BLUE}Deletion cancelled by user.${RESET}"
        log_event "Deletion cancelled for plant container: '$user_given_name_to_delete' (File: $filepath_to_delete)"
        return 1
    fi
    return 0
}


# --- Main Menu Function ---
main_menu() {
    local plant_container_basename # Declare here

    while true; do
        echo "" 
        echo -e "${BRIGHT_GREEN}=== Plant Observation Script ===${RESET}"
        # Options for the main menu
        local main_options=(
            "View Data for a Plant Container"
            "Update Data for a Plant Container"
            "Add New Plant Container"
            "Rename Plant Container"
            "Delete Plant Container" # New option
        )
        
        # Display options with numbers
        echo -e "${YELLOW}Please choose an option:${RESET}"
        for i in "${!main_options[@]}"; do
            echo -e "${CYAN}$((i+1))) ${main_options[$i]}${RESET}"
        done
        echo -e "${CYAN}0) Exit${RESET}"
        
        echo -n -e "${YELLOW}Enter your choice (0-${#main_options[@]}): ${RESET}"
        read -r user_choice

        case $user_choice in
            0) # Exit
                echo -e "${BLUE}Exiting Plant Observation Script.${RESET}"
                log_event "Script finished."
                exit 0
                ;;
            1) # View Data
                plant_container_basename=$(select_plant_container "Which plant container do you want to view?")
                if [[ -n "$plant_container_basename" ]]; then
                    display_plant_container_data "$plant_container_basename"
                else
                    echo -e "${BLUE}View operation cancelled or no plant selected.${RESET}" >&2
                fi
                ;;
            2) # Update Data
                plant_container_basename=$(select_plant_container "Which plant container do you want to update?")
                if [[ -n "$plant_container_basename" ]]; then
                    manage_plant_container_data "$plant_container_basename"
                else
                    echo -e "${BLUE}Update operation cancelled or no plant selected.${RESET}" >&2
                fi
                ;;
            3) # Add New Plant Container
                add_new_plant_container
                ;;
            4) # Rename Plant Container
                rename_plant_container
                ;;
            5) # Delete Plant Container
                delete_plant_container
                ;;
            *) 
                echo -e "${YELLOW}Invalid option '$user_choice'. Please select a number from the list.${RESET}" >&2
                ;;
        esac
        
        # Prompt "Press any key" only if not exiting (already handled)
        if [[ "$user_choice" != "0" ]]; then
            echo "" 
            echo -n -e "${BLUE}Press any key to return to the menu... ${RESET}"
            read -r -n 1 -s 
            echo "" 
            clear 
        fi
    done 
}

# --- Main Script Execution ---
clear 
setup_environment
main_menu

exit 0
