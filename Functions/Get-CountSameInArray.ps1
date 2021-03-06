Function Get-CountSameInArray {

    param (

        [Parameter( Mandatory = $true )]
        [array]
        $Array

    )

    # Count number of matching objects in the array
    # $e = @(2,2,3,4,4)
    # Will produce Item: 2 Count:2, Item: 3 Count:1, Item:4 Count:2
 
    $Unique = $Array | Select -Unique
 
    $Count = $Array.Count

    $H = @{}

    $global:A = @()

    $Unique | % {

        $c = 0

        $n = 0

        While ( $n -lt $Count ) {

            If ( $_ -eq $Array[$n] ) {

                $c = $c + 1

            }

            $n ++

        }

        $H.Item = $_
        $H.Count = $c

        $A += New-Object PSObject -Property $H

    }

    return $A

 }
