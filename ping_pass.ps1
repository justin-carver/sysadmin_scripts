# Define the output CSV file (including day below)
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-date?view=powershell-7.4
$outputCsv = "$(get-date -f yyyy-MM-dd)_workstation_ping.csv"

# Create a header for the CSV file
"ComputerName,IPAddress,Status" | Out-File $outputCsv

# Read endpoints from a text file (each name on a new line)
$baseComputerNames = Get-Content "endpoint_input.txt"

foreach ($baseName in $baseComputerNames) {
    # Specify any number of endpoint naming variabnts to validate
    $computerNames = @("ID_NUMBER-$baseName", "PREFIX$baseName-SUFFIX")

    foreach ($computer in $computerNames) {
        try {
            # Ping the computer
            $pingResult = Test-Connection -ComputerName $computer.Trim() -Count 1 -ErrorAction Stop

            # If ping is successful, write the hostname and IP with SUCCESS
            $line = "$computer, $($pingResult.IPV4Address), SUCCESS"
        } catch {
            # If ping fails, write the computer name with FAIL
            $line = "$computer, , FAIL"
        }

        # Append the result to the CSV file and output to the screen
        $line | Out-File $outputCsv -Append
        $line | Write-Host
    }
}

Write-Host "Ping results have been saved to $outputCsv"