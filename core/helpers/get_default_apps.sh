#!/usr/bin/env bash

# Find all desktop directories
dirs=()
IFS=':' read -ra paths <<< "$XDG_DATA_DIRS"
for p in "${paths[@]}"; do
    if [ -d "$p/applications" ]; then
        dirs+=("$p/applications")
    fi
done
if [ -d "$HOME/.local/share/applications" ]; then
    dirs+=("$HOME/.local/share/applications")
fi

# Search desktop files
search_files=()
for dir in "${dirs[@]}"; do
    for f in "$dir"/*.desktop; do
        [ -f "$f" ] && search_files+=("$f")
    done
done

# --- 1000x PRECEDENCE-BASED MIMEAPPS.LIST RESOLVER (NO XDG-MIME PROCESS BOTTLE-NECK) ---
# Instead of spawning slow xdg-mime wrapper processes 40+ times, we read the mimeapps.list 
# and defaults.list files directly in order of specification precedence.
mimeapps_files=()
[ -f "$HOME/.config/mimeapps.list" ] && mimeapps_files+=("$HOME/.config/mimeapps.list")
[ -f "$HOME/.local/share/applications/mimeapps.list" ] && mimeapps_files+=("$HOME/.local/share/applications/mimeapps.list")
for dir in "${dirs[@]}"; do
    [ -f "$dir/mimeapps.list" ] && mimeapps_files+=("$dir/mimeapps.list")
    [ -f "$dir/defaults.list" ] && mimeapps_files+=("$dir/defaults.list")
done

get_default_for_mimes() {
    local mimes=($1)
    for mime in "${mimes[@]}"; do
        for f in "${mimeapps_files[@]}"; do
            # Quick check if file contains the mime type before parsing to save CPU
            if grep -q "^$mime=" "$f" 2>/dev/null; then
                local val
                val=$(awk -v m="$mime" '
                    BEGIN { in_def=0; val="" }
                    /^\[Default Applications\]/ { in_def=1; next }
                    /^\[/ { in_def=0 }
                    in_def && $0 ~ "^" m "=" {
                        split($0, parts, "=")
                        val = parts[2]
                        # Trim any whitespace
                        gsub(/[ \t\r\n]/, "", val)
                        exit
                    }
                    END { print val }
                ' "$f")
                if [ -n "$val" ]; then
                    echo -n "$val"
                    return
                fi
            fi
        done
    done
}

# Collect defaults for standard categories
def_browser=$(get_default_for_mimes "x-scheme-handler/http x-scheme-handler/https text/html")
def_editor=$(get_default_for_mimes "text/plain")
def_filemanager=$(get_default_for_mimes "inode/directory")
def_pdf=$(get_default_for_mimes "application/pdf")
def_image=$(get_default_for_mimes "image/png image/jpeg image/gif image/webp image/svg+xml")
def_video=$(get_default_for_mimes "video/mp4 video/x-matroska video/webm video/quicktime")
def_audio=$(get_default_for_mimes "audio/mpeg audio/mp3 audio/flac audio/ogg audio/wav")
def_email=$(get_default_for_mimes "x-scheme-handler/mailto")
def_archiver=$(get_default_for_mimes "application/zip application/x-tar application/x-gzip application/x-7z-compressed")
def_terminal=$(get_default_for_mimes "x-scheme-handler/terminal")

defaults_str="browser:$def_browser editor:$def_editor filemanager:$def_filemanager pdf:$def_pdf image:$def_image video:$def_video audio:$def_audio email:$def_email archiver:$def_archiver terminal:$def_terminal"

# Discover custom MIME types that the user has custom defaults for
custom_mimes_str=""
all_mimes=()
if [ -f "$HOME/.config/mimeapps.list" ]; then
    in_defaults=false
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ ^\[.*\] ]]; then
            if [[ "$line" == "[Default Applications]" ]]; then
                in_defaults=true
            else
                in_defaults=false
            fi
            continue
        fi
        if [ "$in_defaults" = true ] && [[ "$line" == *=* ]]; then
            mime=$(echo "$line" | cut -d'=' -f1 | tr -d '[:space:]')
            all_mimes+=("$mime")
        fi
    done < "$HOME/.config/mimeapps.list"
fi

for mime in "${all_mimes[@]}"; do
    if [[ " x-scheme-handler/http x-scheme-handler/https text/html text/plain inode/directory application/pdf image/png image/jpeg image/gif image/webp image/svg+xml video/mp4 video/x-matroska video/webm video/quicktime audio/mpeg audio/mp3 audio/flac audio/ogg audio/wav x-scheme-handler/mailto application/zip application/x-tar application/x-gzip application/x-7z-compressed x-scheme-handler/terminal " =~ " ${mime} " ]]; then
        continue
    fi
    
    label=""
    icon="󰏚"
    if [[ "$mime" == x-scheme-handler/* ]]; then
        scheme=${mime#x-scheme-handler/}
        label="${scheme^} Protocol"
        icon="󰇄"
    else
        subtype=${mime#*/}
        label=$(echo "$subtype" | sed 's/[-.]/ /g')
        label="${label^}"
    fi
    
    custom_mimes_str="$custom_mimes_str $mime|$label|$icon"
    
    def_custom=$(get_default_for_mimes "$mime")
    defaults_str="$defaults_str custom_${mime//\//_}:$def_custom"
done

# Run awk to parse and categorize all desktop files in one single pass
if [ ${#search_files[@]} -gt 0 ]; then
    awk -v defaults="$defaults_str" -v custom_mimes="$custom_mimes_str" '
    BEGIN {
        # Standard Categories Setup
        category_keys[1] = "browser"; category_labels[1] = "Web Browser"; category_icons[1] = "󰈹"; category_mimes[1] = "x-scheme-handler/http x-scheme-handler/https text/html"
        category_keys[2] = "editor"; category_labels[2] = "Text Editor"; category_icons[2] = "󰆍"; category_mimes[2] = "text/plain"
        category_keys[3] = "filemanager"; category_labels[3] = "File Manager"; category_icons[3] = "󰉋"; category_mimes[3] = "inode/directory"
        category_keys[4] = "pdf"; category_labels[4] = "PDF Viewer"; category_icons[4] = "󰈞"; category_mimes[4] = "application/pdf"
        category_keys[5] = "image"; category_labels[5] = "Image Viewer"; category_icons[5] = "󰸉"; category_mimes[5] = "image/png image/jpeg image/gif image/webp image/svg+xml"
        category_keys[6] = "video"; category_labels[6] = "Video Player"; category_icons[6] = "󰕼"; category_mimes[6] = "video/mp4 video/x-matroska video/webm video/quicktime"
        category_keys[7] = "audio"; category_labels[7] = "Audio Player"; category_icons[7] = "󰎈"; category_mimes[7] = "audio/mpeg audio/mp3 audio/flac audio/ogg audio/wav"
        category_keys[8] = "email"; category_labels[8] = "Email Client"; category_icons[8] = "󰇰"; category_mimes[8] = "x-scheme-handler/mailto"
        category_keys[9] = "archiver"; category_labels[9] = "Archiver / Zip"; category_icons[9] = "󰿖"; category_mimes[9] = "application/zip application/x-tar application/x-gzip application/x-7z-compressed"
        category_keys[10] = "terminal"; category_labels[10] = "Terminal Emulator"; category_icons[10] = "󰆍"; category_mimes[10] = "x-scheme-handler/terminal"
        
        num_categories = 10
        
        # Append Custom categories
        split(custom_mimes, custom_arr, " ")
        for (i = 1; i <= length(custom_arr); i++) {
            if (custom_arr[i] != "") {
                split(custom_arr[i], parts, "|")
                num_categories++
                category_keys[num_categories] = "custom_" parts[1]
                gsub(/\//, "_", category_keys[num_categories]) # replace / with _ in keys
                category_labels[num_categories] = parts[2]
                category_icons[num_categories] = parts[3]
                category_mimes[num_categories] = parts[1]
            }
        }
        
        # Build MIME mapping lookup table
        for (c = 1; c <= num_categories; c++) {
            n_m = split(category_mimes[c], cat_m_arr, " ")
            for (cm_idx = 1; cm_idx <= n_m; cm_idx++) {
                cat_mimes[c, cat_m_arr[cm_idx]] = 1
            }
        }
    }
    
    BEGINFILE {
        in_entry = 0
        name = ""
        icon = ""
        mimes = ""
    }
    /^\[Desktop Entry\]/ {
        in_entry = 1
        next
    }
    /^\[/ {
        in_entry = 0
    }
    in_entry {
        if ($0 ~ /^Name=/) {
            name = substr($0, 6)
        } else if ($0 ~ /^Icon=/) {
            icon = substr($0, 6)
        } else if ($0 ~ /^MimeType=/) {
            mimes = substr($0, 10)
        }
    }
    ENDFILE {
        n = split(FILENAME, parts, "/")
        base = parts[n]
        
        if (!(base in app_names)) {
            gsub(/\\/, "\\\\", name)
            gsub(/"/, "\\\"", name)
            if (!name) {
                name = base
                sub(/\.desktop$/, "", name)
            }
            if (!icon) icon = "application-x-desktop"
            
            app_names[base] = name
            app_icons[base] = icon
            app_mimes[base] = mimes
            
            # Match categories using lookup table (O(1) lookups)
            n_m = split(mimes, mime_arr, ";")
            for (m_idx = 1; m_idx <= n_m; m_idx++) {
                m = mime_arr[m_idx]
                if (m == "") continue
                
                for (c = 1; c <= num_categories; c++) {
                    if ((c, m) in cat_mimes) {
                        category_apps[c, base] = 1
                    }
                }
            }
        }
    }
    
    END {
        printf "["
        first_cat = 1
        for (c = 1; c <= num_categories; c++) {
            apps_json = ""
            first_app = 1
            has_apps = 0
            
            for (base in app_names) {
                if ((c, base) in category_apps) {
                    has_apps = 1
                    if (first_app) {
                        first_app = 0
                    } else {
                        apps_json = apps_json ","
                    }
                    apps_json = apps_json "{\"name\":\"" app_names[base] "\",\"desktop\":\"" base "\",\"icon\":\"" app_icons[base] "\"}"
                }
            }
            
            if (has_apps == 0) continue
            
            if (first_cat) {
                first_cat = 0
            } else {
                printf ","
            }
            
            # Match default from defaults variable
            default_app = ""
            split(defaults, def_arr, " ")
            for (d_idx in def_arr) {
                split(def_arr[d_idx], d_parts, ":")
                if (d_parts[1] == category_keys[c]) {
                    default_app = d_parts[2]
                    break
                }
            }
            
            if (default_app == "") {
                for (base in app_names) {
                    if ((c, base) in category_apps) {
                        default_app = base
                        break
                    }
                }
            }
            
            printf "{\"key\":\"%s\",\"label\":\"%s\",\"icon\":\"%s\",\"mimes\":\"%s\",\"default\":\"%s\",\"apps\":[%s]}", category_keys[c], category_labels[c], category_icons[c], category_mimes[c], default_app, apps_json
        }
        printf "]\n"
    }
    ' "${search_files[@]}" 2>/dev/null
else
    echo "[]"
fi
