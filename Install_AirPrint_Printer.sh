#!/bin/bash

# Use the built-in ipp2ppd tool to create a PPD file for AirPrint
# Add icon to PPD (if we can get one) and install the printer

# Required printer info
readonly PRINTER_IP='XXX.XXX.XXX.XXX'
readonly PRINTER_NAME='PRINTER_NAME'
readonly PRINTER_DISPLAY_NAME='PRINTER NAME'
readonly PRINTER_LOCATION='PRINTER LOCATION'
# Requiring icon will prevent install if we can't get it
readonly REQUIRE_ICON=true
#readonly REQUIRE_ICON=false
# Number of seconds to wait for TCP verification before exiting
readonly CHECK_TIMEOUT=2
# Custom PPD info
readonly PPD_PATH='/tmp'
readonly PPD="${PPD_PATH}/${PRINTER_NAME}.ppd"
# Base info
readonly AIR_PPD='/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/PrintCore.framework/Versions/A/Resources/AirPrint.ppd'
readonly EXE='/System/Library/Printers/Libraries/ipp2ppd'
readonly ICON_PATH='/Library/Printers/Icons'
readonly ICON="${ICON_PATH}/${PRINTER_NAME}.icns"

AppendPPDIcon() {
  # Verify we have a file
  if [ ! -f "$ICON" ] && [ "$ICON_AVAILABLE" != "false" ]; then
    /bin/echo "Don't have an icon. Exiting..."
    exit 1
  fi

  /bin/echo "Appending ${ICON} to ${PPD}..."
  # Append the icon to the PPD
  /bin/echo "*APPrinterIconPath: \"${ICON}\"" >> "${PPD}"
}

CheckPrinter() {
  # Verify we can communicate with the printer via the AirPrint port via TCP
  local CHECK=$(/usr/bin/nc -G ${CHECK_TIMEOUT} -z ${PRINTER_IP} 631 2&> /dev/null; /bin/echo $?)

  if [ "$CHECK" != 0 ]; then
    /bin/echo "Cannot communicate with ${PRINTER_IP} on port 631/tcp. Exiting..."
    exit 1
  fi
}

CheckIcon() {
  # Query & parse printer icon, largest usually last?
  readonly PRINTER_ICON=$(/usr/bin/ipptool -tv ipp://${PRINTER_IP}/ipp/print get-printer-attributes.test \
  | /usr/bin/awk -F, '/printer-icons/ {print $NF}')

  # Verify we have an icon to download
  if [ -z "$PRINTER_ICON" ] && [ "$REQUIRE_ICON" = "true" ]; then
    /bin/echo "Did not successfully query a printer icon. Will not install printer. Exiting..."
    exit 1
  elif [ -z "$PRINTER_ICON" ]; then
    /bin/echo "Did not successfully query printer icon. Will continue with printer install..."
    readonly ICON_AVAILABLE=false
  fi

  /bin/echo "Downloading printer icon from ${PRINTER_ICON} to ${ICON}..."
  # Download the PNG icon and make it an .icns file
  /usr/bin/curl -skL "$PRINTER_ICON" -o "$ICON"
  
  # Did we actually write an icon successfully?
  STATUS=$(echo $?)
  if [[ "${STATUS}" != 0 ]]; then
    /bin/echo ""
    /bin/echo "Was not able to write the file ${ICON}..."
    /bin/echo "Does the user running this script have the ability to write to ${ICON_PATH}?"
    /bin/echo "If not, either run with 'sudo' or choose a different location to write the icon file."
    exit 1 
  fi
}

CreatePPD() {
  # Create the PPD file
  /bin/echo "Creating the .ppd file at ${PPD}..."
  $EXE ipp://${PRINTER_IP} "$AIR_PPD" > "$PPD"
}

InstallPrinter() {
  /bin/echo "Installing printer..."
  /usr/sbin/lpadmin -p ${PRINTER_NAME} -D "${PRINTER_DISPLAY_NAME}" -L "${PRINTER_LOCATION}" -E -v ipp://${PRINTER_IP} -P ${PPD} -o printer-is-shared=false
}

main() {
  CheckPrinter
  CreatePPD
  CheckIcon
  AppendPPDIcon
  InstallPrinter
}

main "@"
